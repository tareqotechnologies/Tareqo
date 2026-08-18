#!/usr/bin/env python3
"""Remove emoji characters from the repository.

Scope: markdown docs (pt/en/fr), README, CHANGELOG, Dart comments
(lib/test/tool) and CI workflow comments. Keeps the typographic symbols
(✓ ✗) already used in tables; the warning emoji in callouts becomes a
localized bold marker (Atenção:/Warning:/Attention :).

Usage:  python tool/strip_emojis.py
"""
from __future__ import annotations

import pathlib
import re

ROOT = pathlib.Path(__file__).resolve().parent.parent

WARN = {"en": "Warning:", "pt": "Atenção:", "fr": "Attention :"}

# Typographic symbols that are deliberately kept.
KEPT = {0x2713, 0x2717}  # ✓ ✗

GLOB = [
    "docs/**/*.md",
    "*.md",
    "lib/**/*.dart",
    "test/**/*.dart",
    "tool/**/*.dart",
    ".github/workflows/*.yml",
]


def is_emoji(ch: str) -> bool:
    cp = ord(ch)
    if 0x1F1E6 <= cp <= 0x1F1FF:  # regional indicators (flags)
        return True
    if 0x1F300 <= cp <= 0x1FAFF:  # pictographs
        return True
    if 0x2600 <= cp <= 0x27BF:  # dingbats / misc symbols
        return cp not in KEPT
    if cp == 0xFE0F:  # variation selector
        return True
    return False


def lang_of(path: pathlib.Path) -> str:
    rel = str(path).replace("\\", "/")
    if "/docs/fr/" in rel:
        return "fr"
    if "/docs/pt/" in rel:
        return "pt"
    if "/docs/en/" in rel:
        return "en"
    return "pt"


def clean(text: str, lang: str) -> str:
    warn = WARN.get(lang, "Warning:")
    # Callout prefix: "> ⚠️ **text" → "> **Warn** **text**" — the lookahead
    # keeps the opening ** of the bold phrase so its closing ** stays balanced.
    text = re.sub(r"(>\s*)⚠️\s*(?=\*\*)", r"\1**" + warn + r"** ", text)
    # Callout prefix with plain text: "> ⚠️ text" → "> **Warn** text"
    text = re.sub(r"(>\s*)⚠️\s*", r"\1**" + warn + r"** ", text)
    # Repair callouts converted by older runs (the bold opening was consumed,
    # leaving an orphan closing **): "> **Warn:** X** Y" → "> **Warn:** **X** Y".
    # Only lines with an ODD number of ** carry an orphan; the first ** is it.
    def _fix_callout(match: re.Match) -> str:
        prefix, rest = match.group(1), match.group(2)
        if rest.count("**") % 2 == 1:
            head, sep, tail = rest.partition("**")
            return prefix + "**" + head + "**" + tail
        return prefix + rest

    text = re.sub(
        r"(^> \*\*(?:Atenção:|Warning:|Attention :)\*\* )(.*)$",
        _fix_callout,
        text,
        flags=re.M,
    )
    # Remaining warning signs become the inline word.
    text = text.replace("⚠️", warn).replace("⚠", warn)
    # Status symbols → typographic equivalents.
    text = (
        text.replace("✅", "✓")
        .replace("❌", "✗")
        .replace("🟢", "✓")
        .replace("🔴", "●")
        .replace("🟡", "◔")
        .replace("🔄", "◐")
        .replace("⏳", "○")
        .replace("❓", "?")
    )
    # Strip every remaining emoji codepoint.
    text = "".join(ch for ch in text if not is_emoji(ch))
    # Tidy whitespace left behind.
    text = re.sub(r" {2,}", " ", text)
    return text


def main() -> None:
    changed: list[pathlib.Path] = []
    for pattern in GLOB:
        for path in sorted(ROOT.glob(pattern)):
            if not path.is_file():
                continue
            original = path.read_text(encoding="utf-8")
            cleaned = clean(original, lang_of(path))
            if cleaned != original:
                path.write_text(cleaned, encoding="utf-8")
                changed.append(path)
    print(f"Cleaned {len(changed)} files.")
    for path in changed:
        print(" -", path.relative_to(ROOT))


if __name__ == "__main__":
    main()
