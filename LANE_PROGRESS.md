# Tier 2 desktop app — Progress

LANE.md is the contract; this tracks where we are in it — if they disagree, LANE.md wins for scope.

## Current position

- **Status:** Round 1b finished — all 6 items done, none blocked; 262 tests pass on macOS, and the Windows robot passes every scenario on GitHub's Windows machines (run 34735611144, 165 screenshots checked).
- **Lane acceptance (2026-09-12, `.claude/dev-team/lane-acceptance-report-r1b.md`):**
  - Goal 1, open → edit → save: met.
  - Goal 2, the app's Run matches the reference outputs: partly met. The app's run matches a direct solver run exactly, but the outputs drift from the reference files after about 0.4 s, and `cmp.py` never fails, so this goal can't fail as written.
  - Goal 3, the viewer plays every `.sa1`: met.
  - Goal 4, macOS tests and a Windows build: partly met. macOS passes. The Windows build hasn't run on this round's code, and it runs when `tier2-app` is pushed to the PR.
- **Next:** Nate's Windows VM click-through (checklist below), then the decisions listed under Blockers.
- **Blockers:** Decisions for Nate. (1) A deck made with File > New has 0 time steps, as in ATB 3I, so New → GEBOD → Run writes no animation file; keep 3I's default or give File > New a runnable step count. (2) Inserting a segment on its own passes the app's check but the solver stops (STOP 24); make Insert-segment add a joint too, or make the check reject it. (3) GEBOD Replace drops references into the old body where ATB 3I points them at the new one. (4) GEBOD needs `C:\ATBFIG.SYS`, which a normal Windows user may not be able to write; the VM pass checks this as a standard user. (5) The follow camera rides the torso as in ATB 3I, so a wall or floor can hide the body in 3 frames. (6) Lane goal 2 compares against reference outputs, but the solver's numbers vary by computer, so the robot compares the app's run with a direct run instead; the goal's wording should say that. (7) Still open from round 1: the labeler item says three mislabelled `H.1.a` rows but there is one; confirm what "Z up on screen" meant; D.4 holds no segment reference, so nothing there shifts.
- **Last updated:** 2026-09-12

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

## Round 1b — acceptance-review fixes

| Item | Status |
|------|--------|
| Run and Convert never overwrite existing files silently | done — Run and Convert now ask where to save the results, warn before replacing a file, and never copy a failed run's partial results over good ones. |
| Close the renumbering gaps | done — Pasting rows, deleting an actuator, and editing airbag, belt, water and constraint cards now keep every numbered reference correct, and Save and Run now check the deck first. |
| Validate the deck before Save and Run | done — Save and Run now list any problems in the deck by line number and let you cancel or continue; Continue saves exactly what Save always did. |
| Windows UI test robot | done — A robot on GitHub's Windows machines now opens, edits, saves, runs and animates every client deck in the real app and screenshots each step; the app's run matches a direct solver run exactly. |
| Merge GEBOD output into the open deck | done — Tools > GEBOD now adds its body to the open deck (as a new body, before or after a body, or replacing one), File > New makes an empty deck to start from, and every merged deck runs in the solver. |
| Full Windows end-to-end pass | done — Every scenario, including File > New → GEBOD → Save → Run, now passes on GitHub's Windows machines, and all 165 screenshots were checked; the viewer's follow-the-body camera now appears in each animation check. |

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
