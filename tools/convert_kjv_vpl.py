#!/usr/bin/env python3
"""Convert an eBible/CrossWire verse-per-line KJV archive to the app JSON asset.

Usage:
    python convert_kjv_vpl.py eng-kjv_vpl.zip ../assets/data/kjv.json
"""

from __future__ import annotations

import json
import re
import sys
import zipfile
from pathlib import Path

BOOK_ALIASES = {
    "Genesis": ["Genesis", "Gen", "GEN"], "Exodus": ["Exodus", "Exod", "Ex", "EXO"],
    "Leviticus": ["Leviticus", "Lev", "LEV"], "Numbers": ["Numbers", "Num", "NUM"],
    "Deuteronomy": ["Deuteronomy", "Deut", "DEU"], "Joshua": ["Joshua", "Josh", "JOS"],
    "Judges": ["Judges", "Judg", "JDG"], "Ruth": ["Ruth", "RUT"],
    "1 Samuel": ["1 Samuel", "1Sam", "1SA", "I Samuel"], "2 Samuel": ["2 Samuel", "2Sam", "2SA", "II Samuel"],
    "1 Kings": ["1 Kings", "1Kgs", "1KI", "I Kings"], "2 Kings": ["2 Kings", "2Kgs", "2KI", "II Kings"],
    "1 Chronicles": ["1 Chronicles", "1Chr", "1CH"], "2 Chronicles": ["2 Chronicles", "2Chr", "2CH"],
    "Ezra": ["Ezra", "EZR"], "Nehemiah": ["Nehemiah", "Neh", "NEH"], "Esther": ["Esther", "Esth", "EST"],
    "Job": ["Job", "JOB"], "Psalms": ["Psalms", "Psalm", "Ps", "PSA"], "Proverbs": ["Proverbs", "Prov", "PRO"],
    "Ecclesiastes": ["Ecclesiastes", "Eccl", "ECC"], "Song of Solomon": ["Song of Solomon", "Song of Songs", "Song", "SNG"],
    "Isaiah": ["Isaiah", "Isa", "ISA"], "Jeremiah": ["Jeremiah", "Jer", "JER"],
    "Lamentations": ["Lamentations", "Lam", "LAM"], "Ezekiel": ["Ezekiel", "Ezek", "EZK"],
    "Daniel": ["Daniel", "Dan", "DAN"], "Hosea": ["Hosea", "Hos", "HOS"], "Joel": ["Joel", "JOL"],
    "Amos": ["Amos", "AMO"], "Obadiah": ["Obadiah", "Obad", "OBA"], "Jonah": ["Jonah", "JON"],
    "Micah": ["Micah", "MIC"], "Nahum": ["Nahum", "NAM"], "Habakkuk": ["Habakkuk", "Hab", "HAB"],
    "Zephaniah": ["Zephaniah", "Zeph", "ZEP"], "Haggai": ["Haggai", "Hag", "HAG"],
    "Zechariah": ["Zechariah", "Zech", "ZEC"], "Malachi": ["Malachi", "Mal", "MAL"],
    "Matthew": ["Matthew", "Matt", "MAT"], "Mark": ["Mark", "MRK"], "Luke": ["Luke", "LUK"], "John": ["John", "JHN"],
    "Acts": ["Acts", "ACT"], "Romans": ["Romans", "Rom", "ROM"],
    "1 Corinthians": ["1 Corinthians", "1Cor", "1CO"], "2 Corinthians": ["2 Corinthians", "2Cor", "2CO"],
    "Galatians": ["Galatians", "Gal", "GAL"], "Ephesians": ["Ephesians", "Eph", "EPH"],
    "Philippians": ["Philippians", "Phil", "PHP"], "Colossians": ["Colossians", "Col", "COL"],
    "1 Thessalonians": ["1 Thessalonians", "1Thess", "1TH"], "2 Thessalonians": ["2 Thessalonians", "2Thess", "2TH"],
    "1 Timothy": ["1 Timothy", "1Tim", "1TI"], "2 Timothy": ["2 Timothy", "2Tim", "2TI"],
    "Titus": ["Titus", "TIT"], "Philemon": ["Philemon", "Philem", "PHM"], "Hebrews": ["Hebrews", "Heb", "HEB"],
    "James": ["James", "JAS"], "1 Peter": ["1 Peter", "1Pet", "1PE"], "2 Peter": ["2 Peter", "2Pet", "2PE"],
    "1 John": ["1 John", "1John", "1JN"], "2 John": ["2 John", "2John", "2JN"], "3 John": ["3 John", "3John", "3JN"],
    "Jude": ["Jude", "JUD"], "Revelation": ["Revelation", "Rev", "REV"],
}

ALIASES = sorted(
    ((alias.lower(), canonical) for canonical, aliases in BOOK_ALIASES.items() for alias in aliases),
    key=lambda item: len(item[0]),
    reverse=True,
)


def parse_line(line: str):
    stripped = line.strip()
    lower = stripped.lower()
    for alias, canonical in ALIASES:
        if not lower.startswith(alias):
            continue
        rest = stripped[len(alias):].lstrip()
        match = re.match(r"^(\d+):(\d+)\s+(.+)$", rest)
        if match:
            return canonical, int(match.group(1)), int(match.group(2)), match.group(3).strip()
    return None


def main() -> int:
    if len(sys.argv) != 3:
        print("Usage: convert_kjv_vpl.py INPUT.zip OUTPUT.json", file=sys.stderr)
        return 2

    source = Path(sys.argv[1])
    destination = Path(sys.argv[2])
    if not source.exists():
        print(f"Input not found: {source}", file=sys.stderr)
        return 2

    books: dict[str, dict[str, dict[str, str]]] = {}
    parsed_count = 0

    with zipfile.ZipFile(source) as archive:
        candidates = [
            name for name in archive.namelist()
            if name.lower().endswith((".txt", ".vpl"))
            and "copyright" not in name.lower()
            and "readme" not in name.lower()
        ]
        if not candidates:
            raise RuntimeError("No TXT or VPL file was found in the archive.")

        for name in candidates:
            text = archive.read(name).decode("utf-8-sig", errors="replace")
            for line in text.splitlines():
                parsed = parse_line(line)
                if parsed is None:
                    continue
                book, chapter, verse, verse_text = parsed
                books.setdefault(book, {}).setdefault(str(chapter), {})[str(verse)] = verse_text
                parsed_count += 1

    if parsed_count < 30_000:
        raise RuntimeError(
            f"Only {parsed_count} verses were parsed. The archive may use an unsupported VPL format."
        )

    payload = {
        "metadata": {
            "translation": "King James Version",
            "source": "eBible.org standardized 1769 KJV",
            "complete": True,
            "verseCount": parsed_count,
        },
        "books": books,
    }
    destination.parent.mkdir(parents=True, exist_ok=True)
    destination.write_text(json.dumps(payload, ensure_ascii=False), encoding="utf-8")
    print(f"Wrote {parsed_count} verses to {destination}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
