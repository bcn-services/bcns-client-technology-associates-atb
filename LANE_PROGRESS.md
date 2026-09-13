# Tier 2 desktop app — Progress

LANE.md is the contract; this tracks where we are in it — if they disagree, LANE.md wins for scope.

## Current position

- **Status:** round 1 autonomous run finished — all 7 items before the stop marker are done, none blocked; 200 tests pass on macOS. None of the four lane goals is fully proven yet, because the app has not been run on Windows.
- **Next:** Round 1b — full Windows end-to-end pass.
- **Blockers:** Running the solver on a deck inside `cases/` overwrites that case's reference outputs, so copy the deck out first. A body made with GEBOD holds only the body cards and has to be merged into a full deck before it will run; Nate needs to say how. GEBOD also writes a settings file to the root of `C:\`, which a normal Windows user may not be allowed to do. The labeler item's done-when says three mislabelled `H.1.a` rows, but the client decks contain only one (`2479_2.LIN` line 321), which is fixed. Nate should amend that line in LANE.md to say one. The viewer keeps ATB 3I's screen axes, where the solver's +Z points down on screen; Nate should confirm that is what "Z up on screen" meant.
- **Last updated:** 2026-09-12

## Round 1b — acceptance-review fixes

| Item | Status |
|------|--------|
| Run and Convert never overwrite existing files silently | done — Run and Convert now ask where to save the results, warn before replacing a file, and never copy a failed run's partial results over good ones. |
| Close the renumbering gaps | done — Pasting rows, deleting an actuator, and editing airbag, belt, water and constraint cards now keep every numbered reference correct, and Save and Run now check the deck first. |
| Validate the deck before Save and Run | done — Save and Run now list any problems in the deck by line number and let you cancel or continue; Continue saves exactly what Save always did. |
| Windows UI test robot | done — A robot on GitHub's Windows machines now opens, edits, saves, runs and animates every client deck in the real app and screenshots each step; the app's run matches a direct solver run exactly. |
| Merge GEBOD output into the open deck | done — Tools > GEBOD now adds its body to the open deck (as a new body, before or after a body, or replacing one), File > New makes an empty deck to start from, and every merged deck runs in the solver. |
| Full Windows end-to-end pass | not started |

## Round 1 — core model, generic editor, run, viewer

| Item | Status |
|------|--------|
| Card schema for every `.LIN` card | done — Every card in the 12 client decks now has named, typed fields, and the app can check a deck line by line and point to any line that doesn't fit. |
| Deck labeler for unlabelled or mislabelled decks | done — Bare vendor decks now get their card labels filled in automatically, and the one wrongly labelled empty row in the client decks is fixed; client decks are otherwise untouched. |
| Generic card grid screen | done — Each card now opens as a spreadsheet-style grid with named columns, and rows can be added, deleted, copied, and pasted from Excel; editing a value changes only that line of the deck. |
| Run action | done — File > Run and File > Convert now run the solver in the background with a progress window and a Cancel button, then put the results next to the deck; both still need a first try on Windows. |
| Animation viewer | done — The viewer now plays results with ATB 3I's colours, belts, step and speed controls, and a camera that rides with a chosen segment; it still needs a first look on Windows. |
| ID renumbering | done — Inserting or deleting a segment, joint, plane, or vehicle now renumbers every card that points to it and updates the counts, and deleting something still in use asks first and lists what uses it. |
| GEBOD body generator | done — Tools > GEBOD opens a copy of ATB 3I's body generator form and runs the original GEBOD program behind it; the body it makes holds only the body cards, so turning it into a full runnable deck still needs a step Nate has to specify, and it still needs a first try on Windows. |
| Body Summary screen | skipped — below stop marker |
| Vehicle Motion list and sub-editors | skipped — below stop marker |
| Function editors | skipped — below stop marker |
| HIC/CSI, Run Control, Output Control screens | skipped — below stop marker |
| Installer | skipped — below stop marker |
