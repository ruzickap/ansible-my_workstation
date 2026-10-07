#!/usr/bin/env python3
"""Claude Code PostToolUse hook: substitute unicode chars for ASCII in files.

Ported from opencode-ascii (https://github.com/d3vv3/opencode-ascii).
Reads the hook JSON from stdin, rewrites the edited file in place, and always
exits 0 so it never blocks Claude. Binary / non-UTF-8 files are left untouched.

Categories: punctuation, arrows, math (enabled). emoji (disabled by default).
"""

import json
import re
import sys

# --- Substitution tables -----------------------------------------------------

PUNCTUATION = {
    "\u2014": "--",  # - em dash
    "\u2013": "-",  # - en dash
    "\u2026": "...",  # ... ellipsis
    "\u201c": '"',  # " left double quote
    "\u201d": '"',  # " right double quote
    "\u2018": "'",  # ' left single quote
    "\u2019": "'",  # ' right single quote
    "\u00ab": '"',  # " left guillemet
    "\u00bb": '"',  # " right guillemet
    "\u2022": "-",  # - bullet
}

ARROWS = {
    "\u2192": "->",  # -> rightwards arrow
    "\u2190": "<-",  # <- leftwards arrow
    "\u2191": "^",  # ^ upwards arrow
    "\u2193": "v",  # v downwards arrow
    "\u21d2": "=>",  # => double rightwards arrow
    "\u21d0": "<=",  # <= double leftwards arrow
    "\u21d4": "<=>",  # <=> double left-right arrow
    "\u2194": "<->",  # <-> left-right arrow
}

MATH = {
    "\u2260": "!=",  # != not equal
    "\u2264": "<=",  # <= less-or-equal
    "\u2265": ">=",  # >= greater-or-equal
    "\u00d7": "*",  # * multiplication
    "\u00f7": "/",  # / division
    "\u00b1": "+/-",  # +/- plus-minus
    "\u2212": "-",  # - minus
    "\u221e": "inf",  # inf infinity
    "\u2248": "~=",  # ~= approximately
    "\u221a": "sqrt",  # sqrt square root
}

EMOJI = {
    "\u2713": ":white_check_mark:",  # ✓
    "\u274c": ":x:",  # ❌
    "\u26a0": ":warning:",  # ⚠
    "\u2139": ":information_source:",  # ℹ
    "\u2b50": ":star:",  # ⭐
    "\U0001f525": ":fire:",  # 🔥
    "\U0001f680": ":rocket:",  # 🚀
    "\U0001f41b": ":bug:",  # 🐛
    "\U0001f4dd": ":memo:",  # 📝
    "\U0001f512": ":lock:",  # 🔒
    "\U0001f513": ":unlock:",  # 🔓
    "\U0001f4c1": ":file_folder:",  # 📁
    "\U0001f4c4": ":page_facing_up:",  # 📄
    "\U0001f44d": ":+1:",  # 👍
    "\U0001f44e": ":-1:",  # 👎
}

# Toggle categories here.
ENABLE_PUNCTUATION = True
ENABLE_ARROWS = True
ENABLE_MATH = True
ENABLE_EMOJI = False


def build_table():
    table = {}
    if ENABLE_PUNCTUATION:
        table.update(PUNCTUATION)
    if ENABLE_ARROWS:
        table.update(ARROWS)
    if ENABLE_MATH:
        table.update(MATH)
    if ENABLE_EMOJI:
        table.update(EMOJI)
    return table


def main():
    try:
        payload = json.load(sys.stdin)
    except Exception:
        return 0

    file_path = (payload.get("tool_input") or {}).get("file_path")
    if not file_path:
        return 0

    table = build_table()
    if not table:
        return 0

    pattern = re.compile("|".join(re.escape(k) for k in table))

    def substitute(text):
        return pattern.sub(lambda m: table[m.group(0)], text)

    try:
        with open(file_path, "r", encoding="utf-8", newline="") as fh:
            original = fh.read()
    except (FileNotFoundError, IsADirectoryError, UnicodeDecodeError, OSError):
        return 0

    # Only touch text Claude wrote: the whole file for Write, the new_string
    # fragments for Edit/MultiEdit, so pre-existing unicode is preserved.
    tool_input = payload.get("tool_input") or {}
    if payload.get("tool_name") == "Write":
        fixed = substitute(original)
    else:
        edits = tool_input.get("edits") or [tool_input]
        fixed = original
        for edit in edits:
            new_string = edit.get("new_string") or ""
            fixed_string = substitute(new_string)
            if fixed_string != new_string:
                fixed = fixed.replace(new_string, fixed_string)

    if fixed != original:
        try:
            with open(file_path, "w", encoding="utf-8", newline="") as fh:
                fh.write(fixed)
        except OSError:
            return 0

    return 0


if __name__ == "__main__":
    sys.exit(main())
