"""Temida Serif: Newsreader (productiontype/Newsreader, SIL Open Font License 1.1, no reserved name), renamed.

A legal brief is set in a serif, and so is the brand. Newsreader is a text serif built for screens, close to the
book faces law firms and Anthropic use, so headlines read as considered rather than loud. Interface text stays on
the system font. Same method as coda's Quip Sans: pinned release, renamed, OFL shipped beside the fonts, original
copyright kept in the name table. Two weights, Latin only, every build the same bytes.

    python3 scripts/gen_font.py            # writes web/fonts/TemidaSerif-{Regular,Semibold}.woff2 + .ttf + OFL.txt
    python3 scripts/gen_font.py --check    # named Temida Serif, OFL present, original copyright kept
Needs fonttools and brotli (uv run --with fonttools --with brotli python scripts/gen_font.py).
"""
import io
import os
import sys
import urllib.request

from fontTools.ttLib import TTFont

FAMILY = "Temida Serif"   # ponytail: follows the app name; change here and rerun on a rename
PS = FAMILY.replace(" ", "")
HERE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(HERE, "web", "fonts")
SOURCE = "https://cdn.jsdelivr.net/npm/@fontsource/newsreader@5.2.5/"
WEIGHTS = {"Regular": 400, "Semibold": 600}


def fetch(path):
    """Bytes of one file from the pinned Newsreader release."""
    with urllib.request.urlopen(SOURCE + path, timeout=60) as r:
        return r.read()


def rename(font, style):
    """Give the outlines the brand name; copyright (0) and license (13, 14) stay as the authors wrote them."""
    names = {1: FAMILY, 2: style, 3: f"{PS}-{style}", 4: f"{FAMILY} {style}", 5: "Version 1.000",
             6: f"{PS}-{style}", 16: FAMILY, 17: style}
    table = font["name"]
    table.names = [n for n in table.names if n.nameID in (0, 13, 14)]
    for nid, text in names.items():
        table.setName(text, nid, 3, 1, 0x409)
        table.setName(text, nid, 1, 0, 0)
    font["head"].created = font["head"].modified = 3_700_000_000   # fixed, so every build is the same bytes


def save(font, flavor, path):
    font.flavor = flavor
    buf = io.BytesIO()
    font.save(buf, reorderTables=False)
    with open(path, "wb") as f:
        f.write(buf.getvalue())


def check():
    """Self-check of the shipped files."""
    assert os.path.exists(os.path.join(OUT, "OFL.txt")), "the OFL must ship with the fonts"
    for style in WEIGHTS:
        for ext in ("ttf", "woff2"):
            f = TTFont(os.path.join(OUT, f"{PS}-{style}.{ext}"))
            assert f["name"].getDebugName(1) == FAMILY and f["name"].getDebugName(6) == f"{PS}-{style}"
            assert "Newsreader" in f["name"].getDebugName(0), "the original copyright must stay in the name table"
            cmap = f.getBestCmap()
            assert all(ord(c) in cmap for c in "Aa0§¶—’"), "missing a glyph a brief needs"
    print(f"font ok: {FAMILY} (Newsreader, OFL), {len(WEIGHTS)} weights")


def main():
    if "--check" in sys.argv:
        return check()
    os.makedirs(OUT, exist_ok=True)
    with open(os.path.join(OUT, "OFL.txt"), "wb") as f:
        f.write(fetch("LICENSE"))
    for style, weight in WEIGHTS.items():
        font = TTFont(io.BytesIO(fetch(f"files/newsreader-latin-{weight}-normal.woff2")))
        rename(font, style)
        save(font, None, os.path.join(OUT, f"{PS}-{style}.ttf"))
        save(font, "woff2", os.path.join(OUT, f"{PS}-{style}.woff2"))
    check()


if __name__ == "__main__":
    main()
