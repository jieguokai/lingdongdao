#!/usr/bin/env python3
import argparse
import json
import socket
from datetime import datetime, timezone


def main() -> None:
    parser = argparse.ArgumentParser(description="Send a Codex Lobster Island socket event")
    parser.add_argument("--host", default="127.0.0.1")
    parser.add_argument("--port", type=int, default=45540)
    parser.add_argument("--state", required=True, choices=["idle", "running", "success", "error"])
    parser.add_argument("--title", required=True)
    parser.add_argument("--detail", required=True)
    parser.add_argument("--timestamp", default=datetime.now(timezone.utc).isoformat().replace("+00:00", "Z"))
    args = parser.parse_args()

    payload = json.dumps(
        {
            "state": args.state,
            "title": args.title,
            "detail": args.detail,
            "timestamp": args.timestamp,
        }
    ) + "\n"

    with socket.create_connection((args.host, args.port), timeout=5) as sock:
        sock.sendall(payload.encode("utf-8"))


if __name__ == "__main__":
    main()
