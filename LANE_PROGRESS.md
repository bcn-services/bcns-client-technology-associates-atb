# Tier 2 desktop app — Progress

LANE.md is the contract; this tracks where we are in it — if they disagree, LANE.md wins for scope.

## Current position

- **Status:** Round 2 (v1: every ATB 3I screen plus the installer), sessions S1, S2 and S3 done. S3 finished all four of its items. The robot's wind dropdown step now passes, and the dropdown always worked in the app; the robot had been looking for the open list in the wrong place. Three screens were added: Run Control (Analysis > Run Control...), the General and Diagnostic output settings (Output > Control Parameter), and HIC and CSI (Output > HIC...). Each saves only what you change, and leaves the deck byte-for-byte untouched when nothing is edited. A final review found that switching the HIC output flag off and back on in one visit dropped the deck's HIC settings; that is fixed, and the HIC settings are now updated once on OK, as 3I does. The Windows robot run is fully green: 51 of 51 screens, plus the GEBOD check (run 36505513328), and every new screenshot was checked. The macOS tests pass: 1307 of 1307.
- **Next:** S4, Weight Balancing (`docs/HANDOFF-PLAN.md`): move the stop marker below its items, then the Weight Balancing probe and screens. Still open for the lane: every screen opened from the menu in one run, and the installer (S5).
- **Blockers:** none. Decisions for Nate, from S3:
  - No client deck turns HIC on, so the HIC screen was tested on a copy of 2479_2 with HIC switched on. Is that acceptable?
  - Decks saved by 3I carry a "CARD H.12" line the app's deck check doesn't know yet, so Save and Run shows a harmless warning on them.
  - A deck whose Run Control or output lines are too short shows a crash message instead of a plain error.
  - Recorded differences from 3I in STANDARDS.md:
    - Run Control's whole-number boxes refuse decimals.
    - Run Control refuses vendor decks with the alternate A.1 layout.
    - The Run Control, Output and HIC menus stay enabled with no deck open.
    - The output settings screens can't add or delete rows, accept whole numbers only, and open as a separate window that must be closed first.
    - The HIC screen can't add or delete sets, and its Source dropdowns show plain row numbers.

  Earlier decisions are unchanged:
  - The robot tests vehicle types 0/2/3 and wind and joint functions on decks built from client decks.
  - Inserting a vehicle shifts references that 3I leaves alone. On 2480_4/5 this moves references to segment 19 and up.
  - All the S1 decisions: the Body Summary delete check deck, the read-only Maximum Value List, the single cascade question, the GEBOD Replace root joint, button order, copied-body references, and surplus joints set to -1.
- **Last updated:** 2026-09-28

## Round 2 — v1: full ATB 3I parity + installer

| Item | Status |
|------|--------|
| GEBOD Replace follows ATB 3I | done (2026-09-14) — GEBOD's Replace now points every card that used the old body's segments and joints at the new body's, in order, as ATB 3I does; only the extra positions of a larger old body are removed. |
| Segment and joint insert/delete warning | done (2026-09-14) — Adding, pasting or deleting segments and joints now asks ATB 3I's cascade question first; No leaves the deck untouched, and a segment is inserted on its own as in ATB 3I. |
| Body Summary screen | done (2026-09-14) — Model > Body Summary lists the deck's bodies with ATB 3I's buttons to copy, insert, replace or delete a whole body (or build one with GEBOD), and every card that points at the moved segments and joints follows. |
| Maximum Value List screen | done (2026-09-14) — File > Setting opens ATB 3I's Maximum Value List, showing the solver's 21 limits in 3I's order; it is read-only, where 3I let you edit and save them. |
| Vehicle Motion list and sub-editors | done (2026-09-14) — Model > Vehicle Motion lists the deck's vehicles and opens each in ATB 3I's half-sine, deceleration, 6-DOF or spline editor with its data plot; editing a row changes only that deck line. Insert/Copy/Delete/Replace Vehicle and adding or deleting grid rows are not built yet (disabled). |
| Function editors | done (2026-09-14) — Model > Function > General FDF, Joint Stiffness and Wind Force open ATB 3I's editors (force-deflection as constant, polynomial or tabular) with a Data Plot drawn from the solver's own function math; saving an unedited function changes no bytes. Wind functions have no plot (3I has none), and no client deck has wind or joint functions, so those were tested on decks built from 2479_2. |
| S2 parity fixes | done (2026-09-28) — Vehicle Motion can insert, copy, delete and replace vehicles and add or delete grid rows; the first wind or joint function can be created; the force-deflection plot shows 3I's second curve; wind segments are dropdowns listing the deck's segments; the vehicle Title is editable; and bad input shows 3I's message. The Windows robot run is now fully green (48 of 48). The dropdown always worked in the app. The robot was looking for the open list in the wrong place. |
| Run Control form | done (2026-09-28) — The Run Control screen (Analysis > Run Control...) shows 3I's 16 settings for units, gravity, integrator and output, saves only the value you change, and leaves every deck untouched when nothing is edited. |
| Output Control Parameters | done (2026-09-28) — The General and Diagnostic output settings screens (Output > Control Parameter) list 3I's flags by name and in 3I's two groups, and saving changes only the flag you switch. |
| HIC and CSI Definition | done (2026-09-28) — The HIC and CSI screen (Output > HIC...) opens only when the deck's output settings ask for HIC, as in 3I, and saving without edits changes nothing; no client deck uses HIC, so it was checked on a test copy. |
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
