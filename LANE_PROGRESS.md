# Tier 2 desktop app — Progress

LANE.md is the contract; this tracks where we are in it — if they disagree, LANE.md wins for scope.

## Current position

- **Status:** round 1 autonomous run in progress
- **Next:** Run action
- **Blockers:** none. The labeler item's done-when says three mislabelled `H.1.a` rows, but the client decks contain only one (`2479_2.LIN` line 321), which is fixed. Nate should amend that line in LANE.md to say one.
- **Last updated:** 2026-09-12

## Round 1 — core model, generic editor, run, viewer

| Item | Status |
|------|--------|
| Card schema for every `.LIN` card | done — Every card in the 12 client decks now has named, typed fields, and the app can check a deck line by line and point to any line that doesn't fit. |
| Deck labeler for unlabelled or mislabelled decks | done — Bare vendor decks now get their card labels filled in automatically, and the one wrongly labelled empty row in the client decks is fixed; client decks are otherwise untouched. |
| Generic card grid screen | done — Each card now opens as a spreadsheet-style grid with named columns, and rows can be added, deleted, copied, and pasted from Excel; editing a value changes only that line of the deck. |
| Run action | not started |
| Animation viewer | not started |
| ID renumbering | not started |
| GEBOD body generator | not started |
| Body Summary screen | skipped — below stop marker |
| Vehicle Motion list and sub-editors | skipped — below stop marker |
| Function editors | skipped — below stop marker |
| HIC/CSI, Run Control, Output Control screens | skipped — below stop marker |
| Installer | skipped — below stop marker |
