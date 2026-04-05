#!/usr/bin/env python3
import json
import os
import shutil
import socket
import string
import subprocess
import sys
import threading
import time
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
    latest_error_summary: Optional[str] = None
    latest_approval_reason: Optional[str] = None
    latest_approval_actions: Optional[List[Dict[str, Any]]] = None


@dataclass
class ActionPumpState:
    session_id: str


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
    working_directory = resolve_safe_working_directory()
    child_environment = build_codex_environment(working_directory)
    command_name, title_label, detail = command_context(args)
    emit_event(
        state="typing",
        title="Codex 正在听指令",
        detail=detail,
        command_name=command_name,
        arguments=args,
        session_id=session_id,
        phase="typing",
    )
    emit_event(
        state="running",
        title=f"Codex 正在{title_label}",
        detail=detail,
        command_name=command_name,
        arguments=args,
        session_id=session_id,
        phase="started",
    )

    if supports_native_json(command_name):
        return run_native_json_bridge(
            command=command,
            args=args,
            session_id=session_id,
            command_name=command_name,
            title_label=title_label,
            detail=detail,
            working_directory=working_directory,
            child_environment=child_environment,
        )

    try:
        completed = subprocess.run(
            [command, "-C", str(working_directory), *args],
            check=False,
            cwd=str(working_directory),
            env=child_environment,
        )
    except OSError as error:
        emit_event(
            state="error",
            title=f"Codex {title_label}启动失败",
            detail=str(error),
            command_name=command_name,
            arguments=args,
            session_id=session_id,
            phase="failed",
            error_summary=str(error),
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
            phase="completed",
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
            phase="failed",
            error_summary=f"exit {completed.returncode}",
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
    working_directory: Path,
    child_environment: Dict[str, str],
) -> int:
    invocation = build_native_json_command(command, args, working_directory)
    bridge_state = NativeBridgeState(session_id=session_id)
    action_pump_state = ActionPumpState(session_id=session_id)

    try:
        process = subprocess.Popen(
            invocation,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            stdin=subprocess.PIPE,
            cwd=str(working_directory),
            env=child_environment,
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
            phase="failed",
            error_summary=str(error),
        )
        print(f"codex-bridge: {error}", file=sys.stderr)
        return 1

    assert process.stdout is not None
    action_thread: Optional[threading.Thread] = None
    action_stop = threading.Event()
    if process.stdin is not None:
        action_thread = threading.Thread(
            target=pump_approval_actions,
            args=(action_pump_state, process.stdin, action_stop),
            daemon=True,
        )
        action_thread.start()

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
            action_pump_state.session_id = mapped.session_id
        if mapped.agent_message is not None:
            bridge_state.latest_agent_message = mapped.agent_message
        if mapped.usage_summary is not None:
            bridge_state.latest_usage_summary = mapped.usage_summary
        if mapped.error_summary is not None:
            bridge_state.latest_error_summary = mapped.error_summary
        if mapped.approval_reason is not None:
            bridge_state.latest_approval_reason = mapped.approval_reason
        if mapped.approval_actions is not None:
            bridge_state.latest_approval_actions = mapped.approval_actions
        if mapped.bridge_event is not None:
            emit_event(**mapped.bridge_event)

    return_code = process.wait()
    action_stop.set()
    if action_thread is not None:
        action_thread.join(timeout=0.5)
    final_detail = compose_final_detail(
        fallback_detail=detail,
        bridge_state=bridge_state,
        exit_code=return_code if return_code != 0 else None,
    )

    if return_code == 0:
        emit_event(
            state="success",
            title=f"Codex {title_label}已完成",
            detail=final_detail,
            command_name=command_name,
            arguments=args,
            exit_code=return_code,
            session_id=bridge_state.session_id,
            response_preview=bridge_state.latest_agent_message,
            usage_summary=bridge_state.latest_usage_summary,
            phase="completed",
            error_summary=bridge_state.latest_error_summary,
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
            response_preview=bridge_state.latest_agent_message,
            usage_summary=bridge_state.latest_usage_summary,
            phase="failed",
            error_summary=bridge_state.latest_error_summary or f"exit {return_code}",
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
    response_preview: Optional[str] = None,
    usage_summary: Optional[str] = None,
    phase: Optional[str] = None,
    error_summary: Optional[str] = None,
    approval_reason: Optional[str] = None,
    approval_actions: Optional[List[Dict[str, Any]]] = None,
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
    if response_preview is not None:
        event["responsePreview"] = response_preview
    if usage_summary is not None:
        event["usageSummary"] = usage_summary
    if phase is not None:
        event["phase"] = phase
    if error_summary is not None:
        event["errorSummary"] = error_summary
    if approval_reason is not None:
        event["approvalReason"] = approval_reason
    if approval_actions is not None:
        event["approvalActions"] = approval_actions
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


def bridge_state_root() -> Path:
    return Path.home() / ".codex-lobster-island"


def resolve_safe_working_directory() -> Path:
    current_directory = Path.cwd()
    if is_ascii_path(current_directory):
        return current_directory

    bridge_workspace_root = bridge_state_root() / "workspaces"
    bridge_workspace_root.mkdir(parents=True, exist_ok=True)

    slug = ascii_slug(current_directory.name) or "workspace"
    candidate = bridge_workspace_root / slug
    suffix = 1
    while candidate.exists() and not is_same_path(candidate, current_directory):
        candidate = bridge_workspace_root / f"{slug}-{suffix}"
        suffix += 1

    if candidate.exists():
        return candidate

    candidate.symlink_to(current_directory, target_is_directory=True)
    return candidate


def build_codex_environment(working_directory: Path) -> Dict[str, str]:
    child_environment = dict(os.environ)
    child_environment["PWD"] = str(working_directory)
    child_environment.pop("OLDPWD", None)
    child_environment.pop("CODEX_THREAD_ID", None)
    child_environment.pop("CODEX_INTERNAL_ORIGINATOR_OVERRIDE", None)
    child_environment.pop("CODEX_SHELL", None)
    return child_environment


def is_ascii_path(path: Path) -> bool:
    try:
        str(path).encode("ascii")
    except UnicodeEncodeError:
        return False
    return True


def ascii_slug(value: str) -> str:
    allowed = set(string.ascii_letters + string.digits + "-_.")
    slug = "".join(character if character in allowed else "-" for character in value)
    slug = slug.strip("-._")
    while "--" in slug:
        slug = slug.replace("--", "-")
    return slug


def is_same_path(lhs: Path, rhs: Path) -> bool:
    try:
        return lhs.resolve() == rhs.resolve()
    except OSError:
        return False


def supports_native_json(command_name: str) -> bool:
    return command_name in {"exec", "resume", "review"}


def build_native_json_command(command: str, args: List[str], working_directory: Path) -> List[str]:
    if not args:
        return [command, "-C", str(working_directory)]

    command_name = args[0]
    rest = args[1:]
    if command_name == "review":
        if "--json" in rest:
            return [command, "-C", str(working_directory), "exec", "review", *rest]
        return [command, "-C", str(working_directory), "exec", "review", "--json", *rest]
    if "--json" in rest:
        return [command, "-C", str(working_directory), *args]
    return [command, "-C", str(working_directory), command_name, "--json", *rest]


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
    error_summary: Optional[str] = None
    approval_reason: Optional[str] = None
    approval_actions: Optional[List[Dict[str, Any]]] = None


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
        thread_detail = summarize_thread_detail(session_id=session_id, fallback_detail=fallback_detail)
        return MappedNativeEvent(
            bridge_event=dict(
                state="running",
                title="Codex 会话已建立",
                detail=thread_detail,
                command_name=command_name,
                arguments=original_args,
                session_id=session_id,
                phase="thread_started",
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
                phase="turn_started",
            ),
            session_id=session_id,
        )

    approval_payload = extract_approval_payload(native_event)
    if approval_payload is not None:
        reason, actions = approval_payload
        return MappedNativeEvent(
            bridge_event=dict(
                state="awaiting_approval",
                title="Codex 等待确认",
                detail=reason,
                command_name=command_name,
                arguments=original_args,
                session_id=session_id,
                phase="awaiting_approval",
                approval_reason=reason,
                approval_actions=actions,
            ),
            session_id=session_id,
            approval_reason=reason,
            approval_actions=actions,
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
                        phase="response_ready",
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
                    phase="turn_completed",
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
                    phase="reconnecting" if reconnecting else "error",
                    error_summary=message.strip(),
                ),
                session_id=session_id,
                error_summary=message.strip(),
            )

    return MappedNativeEvent(bridge_event=None, session_id=session_id)


def compose_final_detail(
    *,
    fallback_detail: str,
    bridge_state: NativeBridgeState,
    exit_code: Optional[int] = None,
) -> str:
    parts: List[str] = []
    base = summarize_detail(fallback_detail)
    if base:
        parts.append(base)
    if bridge_state.latest_agent_message and bridge_state.latest_agent_message not in parts:
        parts.append(bridge_state.latest_agent_message)
    if bridge_state.latest_usage_summary and bridge_state.latest_usage_summary not in parts:
        parts.append(bridge_state.latest_usage_summary)
    if exit_code is not None:
        parts.append(f"exit {exit_code}")
    return " · ".join(parts) if parts else "Codex CLI 会话已结束"


def extract_approval_payload(native_event: Dict[str, Any]) -> Optional[Tuple[str, List[Dict[str, Any]]]]:
    event_type = str(native_event.get("type", "")).lower()
    item = native_event.get("item")

    candidate_payload: Optional[Dict[str, Any]] = None
    if event_type in {
        "approval.requested",
        "approval.required",
        "turn.awaiting_approval",
        "session.awaiting_approval",
    }:
        candidate_payload = native_event
    elif isinstance(item, dict) and str(item.get("type", "")).lower() in {
        "approval_request",
        "confirmation_request",
    }:
        candidate_payload = item

    if candidate_payload is None:
        return None

    reason = (
        candidate_payload.get("approvalReason")
        or candidate_payload.get("reason")
        or candidate_payload.get("message")
        or candidate_payload.get("detail")
    )
    if not isinstance(reason, str) or not reason.strip():
        reason = "Codex 请求继续执行前确认。"

    actions = normalize_approval_actions(candidate_payload.get("approvalActions") or candidate_payload.get("actions") or candidate_payload.get("options"))
    return (reason.strip(), actions)


def normalize_approval_actions(raw_actions: Any) -> List[Dict[str, Any]]:
    if not isinstance(raw_actions, list):
        return []

    actions: List[Dict[str, Any]] = []
    for index, item in enumerate(raw_actions):
        if isinstance(item, str):
            label = item.strip()
            if not label:
                continue
            actions.append(
                {
                    "id": f"approval-{index}",
                    "label": label,
                    "role": infer_approval_role(label),
                    "actionPayload": label,
                }
            )
            continue

        if not isinstance(item, dict):
            continue

        label = item.get("label") or item.get("title") or item.get("name")
        if not isinstance(label, str) or not label.strip():
            continue

        role = item.get("role")
        if not isinstance(role, str):
            role = infer_approval_role(label)
        payload = item.get("actionPayload", item.get("payload", item.get("value", label)))
        actions.append(
            {
                "id": item.get("id", f"approval-{index}"),
                "label": label.strip(),
                "role": role,
                "actionPayload": payload_to_string(payload),
            }
        )

    return actions


def infer_approval_role(label: str) -> str:
    normalized = label.strip().lower()
    if any(token in normalized for token in ["approve", "accept", "continue", "yes", "允许", "继续", "确认"]):
        return "approve"
    if any(token in normalized for token in ["reject", "deny", "abort", "cancel", "no", "拒绝", "取消", "终止"]):
        return "reject"
    return "neutral"


def payload_to_string(payload: Any) -> str:
    if isinstance(payload, str):
        return payload
    return json.dumps(payload, ensure_ascii=False, separators=(",", ":"))


def bridge_action_directory() -> Path:
    override = os.environ.get("CODEX_LOBSTER_BRIDGE_ACTION_DIR")
    if override:
        return Path(override).expanduser()
    return Path.home() / ".codex-lobster-island" / "actions"


def pump_approval_actions(state: ActionPumpState, stdin: Any, stop_event: threading.Event) -> None:
    offsets: Dict[Path, int] = {}

    while not stop_event.is_set():
        action_path = bridge_action_directory() / f"{state.session_id}.jsonl"
        if action_path.exists():
            offset = offsets.get(action_path, 0)
            try:
                with action_path.open("r", encoding="utf-8") as handle:
                    handle.seek(offset)
                    while not stop_event.is_set():
                        line = handle.readline()
                        if not line:
                            offset = handle.tell()
                            break
                        line = line.strip()
                        if not line:
                            continue
                        try:
                            command = json.loads(line)
                        except json.JSONDecodeError:
                            continue
                        payload = command.get("actionPayload")
                        if not isinstance(payload, str) or not payload:
                            continue
                        stdin.write(payload if payload.endswith("\n") else payload + "\n")
                        stdin.flush()
                offsets[action_path] = offset
            except OSError:
                pass

        stop_event.wait(0.2)


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


def summarize_thread_detail(*, session_id: str, fallback_detail: str) -> str:
    base = summarize_detail(fallback_detail)
    if base:
        return f"线程 {session_id} · {base}"
    return f"线程 {session_id}"


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
