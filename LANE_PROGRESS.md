# Tier 2 desktop app — Progress

LANE.md is the contract; this tracks where we are in it — if they disagree, LANE.md wins for scope.

## Current position

- **Status:** Round 2 (v1: every ATB 3I screen plus the installer), sessions S1 and S2 done. S2 built the Vehicle Motion list with its four editors and the General FDF, Joint Stiffness and Wind Force editors. macOS tests pass (1262); the full Windows robot run 34928182696 passed 45 of 45 scenarios, and the app's Run of 2479_2 matched a direct solver run in all 9 output files. The lane acceptance review (`.claude/dev-team/lane-acceptance-report-r2-s2.md`) found both S2 items meet their own checks, but S2 falls short of "everything ATB 3I does" (below).
- **Next:** S3 — Run Control, Output Control, HIC/CSI (`docs/HANDOFF-PLAN.md`). First fix S2's gaps against ATB 3I: an empty function list can't create its first function, so wind and joint functions can't be added to any client deck; the Editing Function list shows one line and hides F2; Vehicle Motion's Insert/Copy/Delete/Replace Vehicle and adding or deleting grid rows are disabled; the force-deflection plot lacks 3I's second curve; the wind segment columns are text boxes where 3I has dropdowns; non-numeric input shows the wrong message; the vehicle Title can't be edited; the 6-DOF editor's "Speed" label is cut off to "Spee". Carry forward S1's Minor fixes: a copied body must line up with body boundaries before it pastes; the robot's 10 s late-dialog wait; mixed line endings in the delete warning; the robot never answers Yes on Insert/Replace Copied Body; STANDARDS' copied-refs line should name Replace with Copied Body too.
- **Blockers:** none. Decisions for Nate: the robot tests vehicle types 0, 2 and 3 and the wind and joint functions on decks built from client decks, because no client deck has them; whether the disabled Vehicle Motion actions wait past v1 (the plan says v1 is everything 3I does). From S1: Body Summary's delete check used 2495_2 because 2638 has only one body; the Maximum Value List shows Value and Name and is read-only (3I shows FileID and lets you edit and save); the segment delete warning drops "Delete it anyway?" in favour of 3I's single cascade question; GEBOD Replace of body 1 in a multi-body deck keeps the next body's root joint where 3I drops it; the Body Summary buttons follow 3I's on-screen order, copied bodies' references point at the copy, and a copied body's surplus joints become -1 before removal.
- **Last updated:** 2026-09-14

## Round 2 — v1: full ATB 3I parity + installer

| Item | Status |
|------|--------|
| GEBOD Replace follows ATB 3I | done (2026-09-14) — GEBOD's Replace now points every card that used the old body's segments and joints at the new body's, in order, as ATB 3I does; only the extra positions of a larger old body are removed. |
| Segment and joint insert/delete warning | done (2026-09-14) — Adding, pasting or deleting segments and joints now asks ATB 3I's cascade question first; No leaves the deck untouched, and a segment is inserted on its own as in ATB 3I. |
| Body Summary screen | done (2026-09-14) — Model > Body Summary lists the deck's bodies with ATB 3I's buttons to copy, insert, replace or delete a whole body (or build one with GEBOD), and every card that points at the moved segments and joints follows. |
| Maximum Value List screen | done (2026-09-14) — File > Setting opens ATB 3I's Maximum Value List, showing the solver's 21 limits in 3I's order; it is read-only, where 3I let you edit and save them. |
| Vehicle Motion list and sub-editors | done (2026-09-14) — Model > Vehicle Motion lists the deck's vehicles and opens each in ATB 3I's half-sine, deceleration, 6-DOF or spline editor with its data plot; editing a row changes only that deck line. Insert/Copy/Delete/Replace Vehicle and adding or deleting grid rows are not built yet (disabled). |
| Function editors | done (2026-09-14) — Model > Function > General FDF, Joint Stiffness and Wind Force open ATB 3I's editors (force-deflection as constant, polynomial or tabular) with a Data Plot drawn from the solver's own function math; saving an unedited function changes no bytes. Wind functions have no plot (3I has none), and no client deck has wind or joint functions, so those were tested on decks built from 2479_2. |
| Run Control form | skipped — below stop marker |
| Output Control Parameters | skipped — below stop marker |
| HIC and CSI Definition | skipped — below stop marker |
| Weight Balancing probe | skipped — below stop marker |
| Weight Balancing screens | skipped — below stop marker |
| Installer | skipped — below stop marker |
| Robot sweep | skipped — below stop marker |

## Windows VM click-through (Nate, before anything goes to the client)

The cloud robot proves the paths it scripts. This pass covers what it can't: dialogs a person answers, drag and paste from Excel, feel and speed, and a normal (non-admin) Windows user.

**Setup (one time, ~1 hr)**
1. `brew install --cask utm crystalfetch`; in CrystalFetch download Windows 11 ARM.
2. UTM → New → Virtualize → Windows, 4 cores, 8 GB RAM, 64 GB disk; install (skip activation).
3. In Windows, create a second **standard** (non-admin) user; do every step below as that user.
4. On the Mac: `GITHUB_TOKEN= gh run download 34735611144 -n app-e2e -D ~/atb-vm` (about 190 MB; the app is in `~/atb-vm/app/`, next to `atb-win32.exe`). Copy `app/` into the UTM shared folder, then to `C:\Users\<user>\ATB`, with `cases/` and `example/` beside it.
   The app is x64 and the solver 32-bit; Windows on ARM emulates both. The viewer uses software rendering in UTM (slow, correct).

**Checks** (tick each; screenshot anything odd)
- [ ] Open each of the 12 `cases/*.LIN`; every scope-table screen opens.
- [ ] Edit one value, Save, reopen: the value is there and nothing else moved.
- [ ] Copy 3 rows from Excel (or Notepad, tab-separated) into a grid: they land as rows; on a segment screen, the B.1 count grows.
- [ ] Break a card on purpose (delete a token), Save: a warning lists the line; Cancel keeps the file unchanged, OK saves.
- [ ] Run `2479_2.LIN`: the Save dialog asks where to put results; pick an existing name → Windows asks to replace. Results appear; the progress window closes.
- [ ] Run again and press Cancel: the solver stops within ~2 s and the old results are untouched.
- [ ] Convert `example/Sled.ain`: the resulting `.lin` opens in the grid.
- [ ] Viewer: open three `.sa1` files (incl. `2495_2`, `example/sledout.sa1`); play start to end, step, change speed; belts drawn on frame 0; toggle a segment off/on restores its colour; segment camera stays centred on the segment.
- [ ] Insert a segment and a joint in `2479_2.LIN`, Save, Run: it finishes.
- [ ] File > New → Tools > GEBOD → 50th-percentile adult male → Add as new body → Save → Run: it finishes. **As the standard user:** note whether GEBOD errors writing `C:\ATBFIG.SYS`.
- [ ] Open `2479_2.LIN` → GEBOD → Replace body 1: one confirmation lists what will be removed; No leaves the deck unchanged; Yes merges and the deck runs.

## Round 1b — acceptance-review fixes (shipped 2026-09-12)

Lane acceptance (`.claude/dev-team/lane-acceptance-report-r1b.md`): open → edit → save met; the app's Run matches a direct solver run exactly, though outputs drift from the reference files after about 0.4 s (partly met as worded); viewer met; macOS tests pass. 262 tests; Windows robot run 34735611144, 165 screenshots checked.

| Item | Status |
|------|--------|
| Run and Convert never overwrite existing files silently | done — Run and Convert now ask where to save the results, warn before replacing a file, and never copy a failed run's partial results over good ones. |
| Close the renumbering gaps | done — Pasting rows, deleting an actuator, and editing airbag, belt, water and constraint cards now keep every numbered reference correct, and Save and Run now check the deck first. |
| Validate the deck before Save and Run | done — Save and Run now list any problems in the deck by line number and let you cancel or continue; Continue saves exactly what Save always did. |
| Windows UI test robot | done — A robot on GitHub's Windows machines now opens, edits, saves, runs and animates every client deck in the real app and screenshots each step; the app's run matches a direct solver run exactly. |
| Merge GEBOD output into the open deck | done — Tools > GEBOD now adds its body to the open deck (as a new body, before or after a body, or replacing one), File > New makes an empty deck to start from, and every merged deck runs in the solver. |
| Full Windows end-to-end pass | done — Every scenario, including File > New → GEBOD → Save → Run, now passes on GitHub's Windows machines, and all 165 screenshots were checked; the viewer's follow-the-body camera now appears in each animation check. |

## Round 1 — core model, generic editor, run, viewer (shipped 2026-09-12)

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
