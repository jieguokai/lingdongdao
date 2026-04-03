#!/usr/bin/env python3
import json
import os
import shutil
import socket
import subprocess
import sys
import uuid
from dataclasses import dataclass
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Dict, List, Optional, Tuple


@dataclass
class NativeBridgeState:
    session_id: str
    latest_agent_message: Optional[str] = None
    latest_usage_summary: Optional[str] = None


def main() -> int:
    command = resolve_codex_command()
    if command is None:
        emit_event(
            state="error",
            title="Codex CLI 不可用",
            detail="未找到 codex 可执行文件，请设置 CODEX_LOBSTER_CODEX_BIN",
            command_name="unavailable",
        )
        print("codex-bridge: codex binary not found", file=sys.stderr)
        return 127

    args = sys.argv[1:]
    if not args:
        print("usage: codex-bridge.py <codex args...>", file=sys.stderr)
        return 2

    session_id = os.environ.get("CODEX_LOBSTER_SESSION_ID", uuid.uuid4().hex[:12])
    command_name, title_label, detail = command_context(args)
    emit_event(
        state="running",
        title=f"Codex 正在{title_label}",
        detail=detail,
        command_name=command_name,
        arguments=args,
        session_id=session_id,
    )

    if supports_native_json(command_name):
        return run_native_json_bridge(
            command=command,
            args=args,
            session_id=session_id,
            command_name=command_name,
            title_label=title_label,
            detail=detail,
        )

    try:
        completed = subprocess.run([command, *args], check=False)
    except OSError as error:
        emit_event(
            state="error",
            title=f"Codex {title_label}启动失败",
            detail=str(error),
            command_name=command_name,
            arguments=args,
            session_id=session_id,
        )
        print(f"codex-bridge: {error}", file=sys.stderr)
        return 1

    if completed.returncode == 0:
        emit_event(
            state="success",
            title=f"Codex {title_label}已完成",
            detail=detail,
            command_name=command_name,
            arguments=args,
            exit_code=completed.returncode,
            session_id=session_id,
        )
    else:
        emit_event(
            state="error",
            title=f"Codex {title_label}失败",
            detail=f"{detail} (exit {completed.returncode})",
            command_name=command_name,
            arguments=args,
            exit_code=completed.returncode,
            session_id=session_id,
        )

    return completed.returncode


def run_native_json_bridge(
    *,
    command: str,
    args: List[str],
    session_id: str,
    command_name: str,
    title_label: str,
    detail: str,
) -> int:
    invocation = build_native_json_command(command, args)
    bridge_state = NativeBridgeState(session_id=session_id)

    try:
        process = subprocess.Popen(
            invocation,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            stdin=None,
            text=True,
            encoding="utf-8",
            errors="replace",
            bufsize=1,
        )
    except OSError as error:
        emit_event(
            state="error",
            title=f"Codex {title_label}启动失败",
            detail=str(error),
            command_name=command_name,
            arguments=args,
            session_id=session_id,
        )
        print(f"codex-bridge: {error}", file=sys.stderr)
        return 1

    assert process.stdout is not None

    for raw_line in process.stdout:
        sys.stdout.write(raw_line)
        sys.stdout.flush()

        native_event = parse_native_json_line(raw_line)
        if native_event is None:
            continue

        mapped = map_native_event(
            native_event=native_event,
            command_name=command_name,
            title_label=title_label,
            fallback_detail=detail,
            current_session_id=bridge_state.session_id,
            original_args=args,
        )
        if mapped.session_id is not None:
            bridge_state.session_id = mapped.session_id
        if mapped.agent_message is not None:
            bridge_state.latest_agent_message = mapped.agent_message
        if mapped.usage_summary is not None:
            bridge_state.latest_usage_summary = mapped.usage_summary
        if mapped.bridge_event is not None:
            emit_event(**mapped.bridge_event)

    return_code = process.wait()
    final_detail = compose_final_detail(detail, bridge_state)

    if return_code == 0:
        emit_event(
            state="success",
            title=f"Codex {title_label}已完成",
            detail=final_detail,
            command_name=command_name,
            arguments=args,
            exit_code=return_code,
            session_id=bridge_state.session_id,
        )
    else:
        emit_event(
            state="error",
            title=f"Codex {title_label}失败",
            detail=final_detail,
            command_name=command_name,
            arguments=args,
            exit_code=return_code,
            session_id=bridge_state.session_id,
        )

    return return_code


def emit_event(
    *,
    state: str,
    title: str,
    detail: str,
    command_name: str,
    arguments: Optional[List[str]] = None,
    exit_code: Optional[int] = None,
    session_id: Optional[str] = None,
) -> None:
    event = {
        "state": state,
        "title": title,
        "detail": detail,
        "timestamp": datetime.now(timezone.utc).isoformat().replace("+00:00", "Z"),
        "source": "codex-cli-bridge",
        "command": command_name,
    }
    if session_id is not None:
        event["sessionId"] = session_id
    if arguments is not None:
        event["arguments"] = arguments
    if exit_code is not None:
        event["exitCode"] = exit_code
    payload = json.dumps(event, ensure_ascii=False, separators=(",", ":"))
    append_log_line(payload)
    send_socket_line(payload)


def append_log_line(payload: str) -> None:
    path = bridge_log_path()
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("a", encoding="utf-8") as handle:
        handle.write(payload)
        handle.write("\n")


def send_socket_line(payload: str) -> None:
    host = os.environ.get("CODEX_LOBSTER_BRIDGE_HOST", "127.0.0.1")
    port = int(os.environ.get("CODEX_LOBSTER_BRIDGE_PORT", "45541"))

    try:
        with socket.create_connection((host, port), timeout=1.5) as sock:
            sock.sendall((payload + "\n").encode("utf-8"))
    except OSError:
        pass


def resolve_codex_command() -> Optional[str]:
    override = os.environ.get("CODEX_LOBSTER_CODEX_BIN")
    if override:
        return override

    discovered = shutil.which("codex")
    if discovered:
        return discovered

    bundled = Path("/Applications/Codex.app/Contents/Resources/codex")
    if bundled.exists():
        return str(bundled)

    return None


def bridge_log_path() -> Path:
    override = os.environ.get("CODEX_LOBSTER_BRIDGE_LOG_PATH")
    if override:
        return Path(override).expanduser()
    return Path.home() / ".codex-lobster-island" / "codex-events.jsonl"


def supports_native_json(command_name: str) -> bool:
    return command_name in {"exec", "resume", "review"}


def build_native_json_command(command: str, args: List[str]) -> List[str]:
    if not args:
        return [command]

    command_name = args[0]
    rest = args[1:]
    if command_name == "review":
        if "--json" in rest:
            return [command, "exec", "review", *rest]
        return [command, "exec", "review", "--json", *rest]
    if "--json" in rest:
        return [command, *args]
    return [command, command_name, "--json", *rest]


def parse_native_json_line(raw_line: str) -> Optional[Dict[str, Any]]:
    line = raw_line.strip()
    if not line.startswith("{"):
        return None
    try:
        payload = json.loads(line)
    except json.JSONDecodeError:
        return None
    if not isinstance(payload, dict) or "type" not in payload:
        return None
    return payload


@dataclass
class MappedNativeEvent:
    bridge_event: Optional[Dict[str, Any]]
    session_id: Optional[str]
    agent_message: Optional[str] = None
    usage_summary: Optional[str] = None


def map_native_event(
    *,
    native_event: Dict[str, Any],
    command_name: str,
    title_label: str,
    fallback_detail: str,
    current_session_id: str,
    original_args: List[str],
) -> MappedNativeEvent:
    event_type = str(native_event.get("type", ""))
    session_id = current_session_id

    if event_type == "thread.started":
        thread_id = native_event.get("thread_id")
        if isinstance(thread_id, str) and thread_id:
            session_id = thread_id
        return MappedNativeEvent(
            bridge_event=dict(
                state="running",
                title="Codex 会话已建立",
                detail=fallback_detail,
                command_name=command_name,
                arguments=original_args,
                session_id=session_id,
                ),
            session_id=session_id,
        )

    if event_type == "turn.started":
        return MappedNativeEvent(
            bridge_event=dict(
                state="running",
                title=f"Codex 正在{title_label}",
                detail=fallback_detail,
                command_name=command_name,
                arguments=original_args,
                session_id=session_id,
            ),
            session_id=session_id,
        )

    if event_type == "item.completed":
        item = native_event.get("item")
        if isinstance(item, dict) and item.get("type") == "agent_message":
            text = item.get("text")
            if isinstance(text, str) and text.strip():
                message = summarize_detail(text)
                return MappedNativeEvent(
                    bridge_event=dict(
                        state="running",
                        title="Codex 已生成回复",
                        detail=message,
                        command_name=command_name,
                        arguments=original_args,
                        session_id=session_id,
                    ),
                    session_id=session_id,
                    agent_message=message,
                )

    if event_type == "turn.completed":
        usage = native_event.get("usage")
        usage_summary = summarize_usage(usage)
        if usage_summary is not None:
            return MappedNativeEvent(
                bridge_event=dict(
                    state="running",
                    title="Codex 回合已完成",
                    detail=usage_summary,
                    command_name=command_name,
                    arguments=original_args,
                    session_id=session_id,
                ),
                session_id=session_id,
                usage_summary=usage_summary,
            )

    if event_type == "error":
        message = native_event.get("message")
        if isinstance(message, str) and message.strip():
            reconnecting = "reconnecting" in message.lower()
            return MappedNativeEvent(
                bridge_event=dict(
                    state="running" if reconnecting else "error",
                    title="Codex 正在重连" if reconnecting else "Codex 报告错误",
                    detail=message.strip(),
                    command_name=command_name,
                    arguments=original_args,
                    session_id=session_id,
                ),
                session_id=session_id,
            )

    return MappedNativeEvent(bridge_event=None, session_id=session_id)


def compose_final_detail(fallback_detail: str, bridge_state: NativeBridgeState) -> str:
    parts: List[str] = []
    base = summarize_detail(fallback_detail)
    if base:
        parts.append(base)
    if bridge_state.latest_agent_message and bridge_state.latest_agent_message not in parts:
        parts.append(bridge_state.latest_agent_message)
    if bridge_state.latest_usage_summary and bridge_state.latest_usage_summary not in parts:
        parts.append(bridge_state.latest_usage_summary)
    return " · ".join(parts) if parts else "Codex CLI 会话已结束"


def summarize_detail(value: str, limit: int = 160) -> str:
    normalized = " ".join(value.split())
    if len(normalized) <= limit:
        return normalized
    return normalized[: limit - 3] + "..."


def summarize_usage(usage: Any) -> Optional[str]:
    if not isinstance(usage, dict):
        return None

    input_tokens = usage.get("input_tokens")
    output_tokens = usage.get("output_tokens")
    cached_input_tokens = usage.get("cached_input_tokens")

    token_parts: List[str] = []
    if isinstance(input_tokens, int):
        token_parts.append(f"in {input_tokens}")
    if isinstance(output_tokens, int):
        token_parts.append(f"out {output_tokens}")
    if isinstance(cached_input_tokens, int) and cached_input_tokens > 0:
        token_parts.append(f"cached {cached_input_tokens}")

    if not token_parts:
        return None

    return "tokens " + " · ".join(token_parts)


def command_context(args: List[str]) -> Tuple[str, str, str]:
    if not args:
        return ("command", "执行", "等待 Codex CLI 命令")

    command_name = args[0]
    title_label = command_title_label(command_name)
    detail = command_detail(command_name, args[1:])

    if len(detail) > 96:
        detail = detail[:93] + "..."
    return (command_name, title_label, detail)


def command_title_label(command_name: str) -> str:
    labels = {
        "exec": "执行",
        "resume": "恢复",
        "review": "审查",
    }
    return labels.get(command_name, command_name)


def command_detail(command_name: str, args: List[str]) -> str:
    positional = [value for value in args if not value.startswith("-")]

    if command_name == "exec":
        if positional:
            return " · ".join(positional[:2])
        return "执行 Codex CLI 命令"

    if command_name == "resume":
        if positional:
            session = positional[0]
            if len(positional) > 1:
                return f"恢复会话 {session} · {positional[1]}"
            return f"恢复会话 {session}"
        return "恢复最近会话"

    if command_name == "review":
        if positional:
            return f"审查 {' · '.join(positional[:2])}"
        return "运行代码审查"

    if positional:
        return positional[0]
    if args:
        return " ".join(([command_name] + args)[:3])
    return f"运行 {command_name}"


if __name__ == "__main__":
    raise SystemExit(main())
