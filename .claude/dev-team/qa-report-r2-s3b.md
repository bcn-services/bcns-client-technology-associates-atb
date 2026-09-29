# QA Report — S2 parity fixes (DELTA, r2-s3b)
## VERDICT: PASS

**Branch:** r2-s3b · **Date:** 2026-09-15 · **Gate mode:** tests · **Scope:** `git diff 3618cf2..HEAD`

## Gate
- `PATH=$HOME/atb-work/dotnet:$PATH dotnet test app/Atb.sln` → Passed 1276, Failed 0 (baseline run), and 1276/0 again after all mutants restored; no test deleted (roster grew by 3: VehicleConfirmationTextsAre3IsLiterals, VehicleInsertAndDeleteOn2480_4KeepBodySegmentRefs, TrimRowsDropsTheCancelledNewRow, FdfTwoSeriesFixtureHasBothSubFunctions).

## Criteria re-confirmed by execution (Atb.Core entry points)
- First wind + joint function on a no-E.6/E.7 deck → FirstWindAndJointFunctionCreateTheirSectionsAndTerminator — PASS.
- Insert/copy/delete/replace vehicle via Renumber, deck validates → VehicleInsertGoesThroughRenumber, VehicleCopyReplaceKeepsTheSegmentNumber, VehicleInsertAndDeleteOn2480_4KeepBodySegmentRefs (F.1.b/G.3.a refs shift, byte-identical round trip) — PASS.
- Primary delete refused with 3I's text → VehicleDeleteRefusesThePrimaryAndRenumbersOtherwise asserts the written-out literal (line 69), not the constant — PASS.
- Sub-editor row add/delete rewrites C.2.A token 8 / C.2.B token 2 → Spline/SixDof/Deceleration row tests + TrimRowsDropsTheCancelledNewRow (cancelled row leaves zero-byte delta) — PASS.
- FDF second series from Functions.CurvePoints, absent without data → FdfOtherSeriesComesFromCurvePointsAndIsAbsentWithoutData + FdfTwoSeriesFixtureHasBothSubFunctions — PASS.
- Non-numeric message/title and vehicle confirmations are Atb.Core constants equal to 3I literals → NonNumericMessageAndTitleAreCoreConstants, VehicleConfirmationTextsAre3IsLiterals (all written-out literals) — PASS.
- Robot scenario criterion — out of this gate; evidence comes from the separate app-e2e run.
- Existing tests remain passing → 1276/0 — PASS.

## Mutations (backup `cp`, restore from copy, `cmp` + `git status`)
- (a) app/Atb.Core/Cards/Vehicles.cs:202 `RowCount(b) > rows` → `> rows + 1` → red: S2ParityTests.TrimRowsDropsTheCancelledNewRow (sole failure, 1275 passed) — restored identical: yes.
- (b) app/Atb.Core/Cards/Vehicles.cs:145 `if (seg <= nseg)` → `if (seg <= 0)` → red: VehicleInsertAndDeleteOn2480_4KeepBodySegmentRefs at S2ParityTests.cs:190, message names token 13 (Expected `…16 CARD C.2.a`, Actual `…19`) — sole failure — restored identical: yes.
- (c1) app/Atb.Core/Cards/Vehicles.cs:130 PrimaryText literal reworded → red: VehicleConfirmationTextsAre3IsLiterals AND VehicleDeleteRefusesThePrimaryAndRenumbersOtherwise (the latter pins the written-out literal, confirming it is not self-referential to the constant) — restored identical: yes.
- (c2) app/Atb.Core/Cards/Functions.cs:447 `int o = 1 - sub` → `int o = sub` → red: FdfTwoSeriesFixtureHasBothSubFunctions and FdfOtherSeriesComesFromCurvePointsAndIsAbsentWithoutData — restored identical: yes.
- No `git checkout --` used; working tree clean apart from three untracked report files.

## Not mutation-covered (not a failing finding, stated for the record)
- app/Atb.App/FunctionForms.cs Insert (no-confirmation append + InvalidOperationException → "Insert Operation Warning") and app/Atb.App/VehicleForms.cs:253 RowsRemoved hook are WinForms-only; Atb.App is net8.0-windows and does not build or run under `dotnet test` on macOS, so no unit mutant is possible. Their guards are the robot scenario's `Assert.Null(FindWin(r, "Insert Data"))` and the row-typed/row-cancelled waits — the app-e2e run is the gate for both.
- RowsRemoved double-delete checked by reading: the Delete-key path calls Vehicles.DeleteRow then FillGrid, which sets `loading = true` before `Rows.Clear()`, so the hook is suppressed; TrimRows is a no-op when deck rows == grid rows.

## Scenarios.cs 966248f vs 3618cf2
- 966248f only replaces the F4 keypress with F2 + a focused-element ComboBox lookup and `Expand()`, keeping the same `ExpandCollapseState == Expanded` wait and the same screenshot — no assertion removed or weakened.
- The one earlier removal in range (d5556ff) drops the `Insert Data` "Yes" click and replaces it with `Assert.Null(FindWin(r, "Insert Data"))` — a stricter assertion matching 3I's no-confirmation add-new row, not a loosening.

## Guardrails
- No renumbering added in the forms; Insert's post-step rewrites only the new vehicle's own C.2.A token 13 after Renumber. No change under `src/`, `verify/`, `cases/`. Atb.Core still UI/DB-free. No tests added by QA, so no commit.
