# Tier 2 desktop app — Progress

LANE.md is the contract; this tracks where we are in it — if they disagree, LANE.md wins for scope.

## Current position

- **Status:** round 1 autonomous run in progress
- **Next:** Deck labeler for unlabelled or mislabelled decks
- **Blockers:** none. The labeler item expects three mislabelled `H.1.a` rows, but the client decks contain only one (`2479_2.LIN` line 321). Nate needs to settle this in LANE.md.
- **Last updated:** 2026-09-12

## Round 1 — core model, generic editor, run, viewer

| Item | Status |
|------|--------|
| Card schema for every `.LIN` card | done — Every card in the 12 client decks now has named, typed fields, and the app can check a deck line by line and point to any line that doesn't fit. |
| Deck labeler for unlabelled or mislabelled decks | not started |
| Generic card grid screen | not started |
| Run action | not started |
| Animation viewer | not started |
| ID renumbering | not started |
| GEBOD body generator | not started |
| Body Summary screen | skipped — below stop marker |
| Vehicle Motion list and sub-editors | skipped — below stop marker |
| Function editors | skipped — below stop marker |
| HIC/CSI, Run Control, Output Control screens | skipped — below stop marker |
| Installer | skipped — below stop marker |
