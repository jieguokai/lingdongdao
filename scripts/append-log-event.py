#!/usr/bin/env python3
import argparse
import json
from datetime import datetime, timezone
from pathlib import Path


def main() -> None:
    parser = argparse.ArgumentParser(description="Append a Codex Lobster Island log event")
    parser.add_argument("--path", default=str(default_log_path()))
    parser.add_argument("--state", required=True, choices=["idle", "running", "success", "error"])
    parser.add_argument("--title", required=True)
    parser.add_argument("--detail", required=True)
    parser.add_argument("--timestamp", default=datetime.now(timezone.utc).isoformat().replace("+00:00", "Z"))
    args = parser.parse_args()

    event = {
        "state": args.state,
        "title": args.title,
        "detail": args.detail,
        "timestamp": args.timestamp,
    }

    path = Path(args.path).expanduser()
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("a", encoding="utf-8") as handle:
        handle.write(json.dumps(event) + "\n")


def default_log_path() -> Path:
    return Path.home() / "Library" / "Logs" / "Codex" / "codex-status.log"


if __name__ == "__main__":
    main()
