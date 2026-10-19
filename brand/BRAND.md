# Temida brand kit and design system

A private place to build a legal claim. The brand should feel like a well-kept brief: white paper, dark ink,
one calm colour, a serif for the headline and nothing that shouts.

## The mark
Temida's scales resting on a Greek column: a fluted shaft with a capital and a stepped base, one beam, fine
hangers and two flat pans. White on a slate gradient tile. No text, no outline, no emblem, nothing round
hanging off a shaft. It also reads as a T.

- `../Temida.icon` is the source of truth (Icon Composer), used by iOS and macOS (`ASSETCATALOG_COMPILER_APPICON_NAME: Temida`).
- `../icon.svg` is the flat copy for READMEs (80 px) and the web. `icon-1024.png` is the App Store icon, no alpha.
- `mark.svg` is the glyph alone in `currentColor`, for the nav and footer.
- One glyph source drives every copy (tiles, marks, favicons, launch logo, `Temida.icon/Assets/glyph.png`). It must read at 29 px.

## Colour
| Role | Light | Dark |
|---|---|---|
| Accent (actions, links, icon, focus) | `#2b3550` slate | `#9fb0d6` |
| Gradient top (icon) | `#5c6b8a` | |
| Background | `#ffffff` | `#000000` |
| Surface (cards, grouped rows) | `#f5f5f7` | `#1c1c1e` |
| Text | `#1d1d1f` | `#f5f5f7` |
| Secondary text | text at 72% | text at 72% |
| Hairline | `#e5e5ea` | `#2c2c2e` |

Status colours carry legal meaning and appear only on data, never on chrome: red for deadlines and risk,
amber for "soon", green for money gained and steps done. Never cream, sand, yellow, brown, purple or teal.
On the accent, text is white in light mode and near-black (`#0b0f1a`) in dark mode.

## Type
- **Headlines:** Temida Serif (Newsreader, OFL, renamed by `scripts/gen_font.py`; Regular and Semibold in
  `web/fonts/`). A brief is set in a serif. Track at -0.015em.
- **Everything else:** the system font, `-apple-system, BlinkMacSystemFont, "SF Pro Text", "Helvetica Neue", Helvetica, Arial, sans-serif`.
- Scale 34/41, 22/28, 17/24, 15/20, 13/18. Labels are sentence case at 13, never spaced-out capitals.

## Space and shape
- 8 point grid: 4, 8, 12, 16, 24, 32, 48. Side margin 20 (16 on phones). Reading column 680.
- Radii: cards 28, grouped lists 20, fields 12, controls fully round, icon 22 percent.
- Controls are 48 point capsules. Focus is a 4 point ring at 30 percent accent.

## Structure
The same five places on every platform, in this order:

| | Web | iPhone | Mac |
|---|---|---|---|
| Case: what happened, the clock | section I | tab | sidebar |
| Tasks: open steps, Reminders, Calendar | section III | tab | sidebar |
| Money: projection and scenarios | section II | tab | sidebar |
| Files: documents and case law | section IV | tab | sidebar |
| Profile: account, case picker, settings | header | tab | sidebar |

Native apps use the system tab bar and sidebar with a label under every icon; no custom floating bars.

## Voice
Short sentences, plain words, no em dashes, no hype. Say what to do next and why now.
Temida is a planning aid, not legal advice, and says so once where it matters.
