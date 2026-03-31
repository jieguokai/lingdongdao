#!/usr/bin/env python3
from __future__ import annotations

import argparse
import html
from pathlib import Path


def render_markdown(markdown: str) -> str:
    lines = markdown.splitlines()
    blocks: list[str] = []
    list_items: list[str] = []
    paragraph: list[str] = []

    def flush_paragraph() -> None:
        nonlocal paragraph
        if paragraph:
            text = " ".join(part.strip() for part in paragraph if part.strip())
            if text:
                blocks.append(f"<p>{html.escape(text)}</p>")
        paragraph = []

    def flush_list() -> None:
        nonlocal list_items
        if list_items:
            items = "".join(f"<li>{item}</li>" for item in list_items)
            blocks.append(f"<ul>{items}</ul>")
        list_items = []

    for raw_line in lines:
        line = raw_line.rstrip()
        stripped = line.strip()

        if not stripped:
            flush_paragraph()
            flush_list()
            continue

        if stripped.startswith("# "):
            flush_paragraph()
            flush_list()
            blocks.append(f"<h1>{html.escape(stripped[2:].strip())}</h1>")
            continue
        if stripped.startswith("## "):
            flush_paragraph()
            flush_list()
            blocks.append(f"<h2>{html.escape(stripped[3:].strip())}</h2>")
            continue
        if stripped.startswith("### "):
            flush_paragraph()
            flush_list()
            blocks.append(f"<h3>{html.escape(stripped[4:].strip())}</h3>")
            continue
        if stripped.startswith("- "):
            flush_paragraph()
            list_items.append(html.escape(stripped[2:].strip()))
            continue

        flush_list()
        paragraph.append(stripped)

    flush_paragraph()
    flush_list()
    return "\n".join(blocks)


def build_html(title: str, body: str) -> str:
    escaped_title = html.escape(title)
    return f"""<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>{escaped_title}</title>
  <style>
    :root {{
      color-scheme: light dark;
      --bg: #0f1222;
      --card: rgba(255,255,255,0.08);
      --text: #f6f7fb;
      --muted: rgba(246,247,251,0.72);
      --accent: #ff7b54;
    }}
    body {{
      margin: 0;
      font-family: -apple-system, BlinkMacSystemFont, "SF Pro Text", sans-serif;
      background:
        radial-gradient(circle at top left, rgba(255,123,84,0.18), transparent 32%),
        linear-gradient(180deg, #13172d, #0b0d18);
      color: var(--text);
      line-height: 1.6;
      padding: 32px 20px;
    }}
    main {{
      max-width: 760px;
      margin: 0 auto;
      background: var(--card);
      border: 1px solid rgba(255,255,255,0.1);
      border-radius: 24px;
      padding: 28px;
      backdrop-filter: blur(20px);
    }}
    h1, h2, h3 {{
      line-height: 1.15;
      margin: 0 0 16px;
    }}
    h1 {{
      font-size: 2rem;
    }}
    h2 {{
      color: var(--accent);
      margin-top: 28px;
    }}
    p, ul {{
      margin: 0 0 16px;
      color: var(--muted);
    }}
    ul {{
      padding-left: 20px;
    }}
  </style>
</head>
<body>
  <main>
{body}
  </main>
</body>
</html>
"""


def main() -> None:
    parser = argparse.ArgumentParser(description="Render markdown release notes to HTML")
    parser.add_argument("--input", required=True)
    parser.add_argument("--output", required=True)
    parser.add_argument("--title")
    args = parser.parse_args()

    input_path = Path(args.input)
    output_path = Path(args.output)
    output_path.parent.mkdir(parents=True, exist_ok=True)

    markdown = input_path.read_text(encoding="utf-8")
    title = args.title or input_path.stem
    body = render_markdown(markdown)
    output_path.write_text(build_html(title, body), encoding="utf-8")


if __name__ == "__main__":
    main()
