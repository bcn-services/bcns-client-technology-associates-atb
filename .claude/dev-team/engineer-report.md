# Engineer Report
**Task:** HIC and CSI Definition (§2 #36) — H.12 form + grid copying 3I HIC.cs, enabled by NPRT(4)
**Branch:** r2-s3c
**Date:** 2026-09-28

Outcome: DONE — fixture-deck probe 0 of 139 client decks enable HIC, so a synthetic fixture (2479_2 + NPRT(4)=1 + 3I's default H.12 line) carries the unit test and the robot, with vendor ejection.lin as a second enabling deck. No conflict with the lane objective.
macOS: 1306 passed, 0 failed, 0 skipped (baseline 1292, +14)
Windows filtered (HicEditSave): https://github.com/bcn-services/bcns-client-technology-associates-atb/actions/runs/36502657236 — 1/1 green, 11 shots, 03-hic-form / 02 enabled menu / 11 disabled menu checked by eye
Windows full: https://github.com/bcn-services/bcns-client-technology-associates-atb/actions/runs/36503146585 — success, trx 51/51 passed, 11 HIC shots (07, 10, 11 viewed)
Mutation: EnablesHic `!= 4` -> `== 4` turned 13 tests red (HicTests x10, OutputControlTests.Nprt4KeepsH12InStep, LabelerTests x2 vendor, CardGridTests.EveryDeckColumn_HasSchemaHeader), which shows the menu, the Output Control H.12 add/remove, and Labeler all go through the one predicate. Restored with cp, cmp identical.

## Design Decisions
- The shared NPRT(4) rule is `OutputControl.EnablesHic(int)` (`!= 0 && != 4`), plus `HicEnabled(Deck)`. The menu, `OutputControl.Set`'s H.12 add/remove and Labeler's H.12 read all call it. Before this change Labeler.cs:176 held a second copy of the test, which is now removed.
- 3I's gates differ in one way: the H.12 read/write (FileManager.cs:1031/:2238) also requires NSEG > 0. That extra check stays in Labeler (`num5 > 0 &&`). The menu gate (MainMenu.cs:4719, StdTable.cs:249) is the bare rule.
- The menu's enabled state is recomputed on Output DropDownOpening. 3I recomputes it on file open and on A5 OK. Both give the same visible state.
- The H.12 layout was checked against 3I's writer: the line is NHIC, Span, then BodyID/HIC Source/CSI Source for each set, all on one line. With sets, 3I labels the line `CARD H.12`. Its default line is labelled `Card H.12.a`. Vendor ejection.lin `1 0.036 1 1 2` agrees. `Hic.Rows` reads the head line's triples plus any H.12.B lines. The H.12.B wrap guess is kept and flagged in a ponytail comment, not extended.
- The form edits a fixed set of rows: no add or delete. 3I's own reader takes only one set (FileManager.cs:1033), and no deck has NHIC > 1. This is recorded in STANDARDS.md as a call for Nate.

## Files Changed
- `app/Atb.Core/Cards/OutputControl.cs` — adds the EnablesHic/HicEnabled predicate; `Set` uses it and also removes 3I `CARD H.12` lines.
- `app/Atb.Core/Cards/Hic.cs` — new: Span, Rows, Cell, Set, and Choices (H.1 rows 1..N plus the values the deck holds).
- `app/Atb.Core/Lin/Labeler.cs` — H.12 gate now calls OutputControl.EnablesHic.
- `app/Atb.App/HicForm.cs` — new: 3I HIC.cs layout (360x253, Span box, BodyID locked cyan, 2 Source combos, OK/Cancel).
- `app/Atb.App/MainForm.cs` — adds Output > HIC... (last item, as 3I) and HicDialog.
- `app/Atb.App.UiTests/Scenarios.cs` — new HicEditSave robot scenario covering: enabled menu, form, unedited save byte-identical, Span edit, NPRT(4)=4 then disabled menu.
- `app/Atb.Core.Tests/HicTests.cs` — new: rule truth table, on/off decks, zero-byte save over every enabling deck (count asserted >= 2 and must include the fixture), edits, refusals, 3I one-line sets.
- `app/Atb.Core.Tests/fixtures/hic/2479_2_hic.LIN` — new synthetic fixture.
- `STANDARDS.md` — records the HIC divergences and the synthetic fixture.

## Deferred / Out of Scope
- Adding or deleting HIC sets (multi-HIC): the layout is unverified and 3I cannot re-read it.
- 3I's multi-column Source drop-down (Ref Segment/Segment/Point Loc): ours shows bare H.1 row numbers.

## Flags for Reviewer
- Finding: after an HIC edit, 3I writes `CARD H.12`. CardSchema has no "H.12" entry, so `Deck.Validate` would flag such a deck, and Labeler.Apply would relabel it and truncate it to 5 tokens. No deck has that label, so this was not fixed. `Hic` reads the label.
- HicDialog guards on HicEnabled as well as on the menu state, so a stale menu can't open the form on a deck without H.12.
