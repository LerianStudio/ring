#!/usr/bin/env python3
"""
Mermaid Live Encoder

Reads Mermaid diagram code from stdin and outputs a mermaid.live URL.
Uses the same pako encoding as mermaid-live-editor's serde.ts.

Encoding algorithm:
  1. Build JSON state object with diagram code and options
  2. JSON.stringify the state (compact, no extra whitespace)
  3. UTF-8 encode to bytes
  4. zlib compress at level 9 (standard zlib format, wbits=15)
  5. URL-safe base64 encode (+ -> -, / -> _, strip = padding)
  6. Prefix with "pako:"
  7. Build URL: https://mermaid.live/{mode}#pako:{encoded}

Uses ONLY Python standard library -- no pip install needed.
"""

import argparse
import base64
import json
import sys
import zlib


def encode_pako(data: str) -> str:
    """Encode a string using pako-compatible compression (zlib + URL-safe base64)."""
    data_bytes = data.encode("utf-8")
    # zlib compress at max level, standard format (wbits=15 is the default)
    compressed = zlib.compress(data_bytes, level=9)
    # URL-safe base64 encode and strip padding
    b64 = base64.urlsafe_b64encode(compressed).decode("ascii").rstrip("=")
    return b64


def build_state(code: str, theme: str = "default", rough: bool = False) -> str:
    """Build the mermaid.live JSON state object."""
    state = {
        "code": code,
        "mermaid": json.dumps({"theme": theme}, separators=(",", ":")),
        "updateDiagram": True,
        "rough": rough,
        "panZoom": True,
        "grid": True,
    }
    # Compact JSON -- no extra whitespace, matches JSON.stringify default
    return json.dumps(state, separators=(",", ":"))


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Encode Mermaid diagram code and output a mermaid.live URL."
    )
    parser.add_argument(
        "--theme",
        choices=["default", "dark", "forest", "neutral"],
        default="default",
        help="Mermaid theme (default: default)",
    )
    mode_group = parser.add_mutually_exclusive_group()
    mode_group.add_argument(
        "--edit",
        action="store_const",
        const="edit",
        dest="mode",
        help="Open in edit mode (default)",
    )
    mode_group.add_argument(
        "--view",
        action="store_const",
        const="view",
        dest="mode",
        help="Open in view-only mode",
    )
    parser.add_argument(
        "--rough",
        action="store_true",
        default=False,
        help="Enable hand-drawn/sketchy style",
    )

    args = parser.parse_args()
    mode = args.mode or "edit"

    # Read mermaid code from stdin (bounded to 1 MB - well beyond any practical diagram)
    MAX_INPUT = 1_048_576
    code = sys.stdin.read(MAX_INPUT)
    if not code.strip():
        print("Error: no mermaid code provided on stdin", file=sys.stderr)
        sys.exit(1)

    # Build state JSON, encode, and construct URL
    state_json = build_state(code.strip(), theme=args.theme, rough=args.rough)
    encoded = encode_pako(state_json)
    url = f"https://mermaid.live/{mode}#pako:{encoded}"

    print(url)


if __name__ == "__main__":
    main()
