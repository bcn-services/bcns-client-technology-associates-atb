# Engineer Report
Branch: r2-s3
Commits: 2b72d3a (core checkpoint), 64461c8 (forms + robot)
Gate: dotnet test app/Atb.sln — 1276 passed, 0 failed (fix pass wip checkpoint; was 1272). Atb.App / UiTests not compiled on Mac — unverified until a Windows run
Fix pass (wip, stopped on time): items 1-7 + both minors coded; NOT done: push, Windows app-e2e run, PNG read, mutation checks (TrimRows guard, Insert SegID post-step)
Item 7: implemented (decompile Vehicle.cs:589-601 unambiguous: new Vehicle Segment = selected SegID) as a Core post-step on the new C.2.A only; the no-ref-shift-when-SegID<=NSEG part recorded as a STANDARDS.md divergence for Nate
Windows run: https://github.com/bcn-services/bcns-client-technology-associates-atb/actions/runs/35021573881 — success, 13/13 (S2ParityVehicleOps, S2ParityGridsAndFunctions, VehicleMotionEditors, FunctionEditors)
PNGs read: Speed label whole; row add 7.25/delete 2 visible; "ATB 3I" Error-icon box; F1+F2 listbox bold Navy; primary refusal; insert confirm; title HATCH — nothing visibly wrong
**Task:** S2 parity fixes (a)-(h) · **Date:** 2026-09-15

## Mutation checks (backup cp, loud diff -q, restore from cp; all restored, diff-clean)
- Primary refusal (`n == Count` -> `n < 0`) — red: S2ParityTests.VehicleDeleteRefusesThePrimaryAndRenumbersOtherwise
- Row-count rewrite (token 8 / C.2.B token 2 set to "0") — red: SplineRowAddAndDeleteRewriteC2bToken2, SixDofRowAddAndDeleteRewriteC2aToken8Negative, DecelerationRowAddAndDeleteRewriteC2aToken8
- First-function terminator dropped — red: FirstWindAndJointFunctionCreateTheirSectionsAndTerminator
- FDF second-series absence guard removed — red: FdfOtherSeriesComesFromCurvePointsAndIsAbsentWithoutData
- Vehicle insert bypassing Renumber (raw InsertRange) — red: VehicleInsertGoesThroughRenumber

## Design Decisions
- Vehicle ops live in Core (Vehicles.Insert/Copy/Delete/Replace/SetTitle/AddRow/DeleteRow); forms only confirm and call them on a Parse(Write()) copy.
- Replace swaps lines and keeps the old C.2.A token 13; no renumber (3I runs no UpdateSegID there).
- Grid add = DGV new row (UserAddedRow -> AddRow); delete = Delete key on the current row, no confirm (3I has none).
- DataPlotForm takes a list of Series with 3I palette index (Blue, Green, Red, Cyan, Gray); the old single-series SetData overloads wrap it.
- Function Insert with no selection appends (null anchor); a first joint brings `999 ""` E.7.A terminator.

## Files Changed
- `app/Atb.Core/Cards/Functions.cs` — Insert(before?), End(), JointTerminator, OtherCurve, FormatError/FormatErrorTitle.
- `app/Atb.Core/Cards/Vehicles.cs` — list ops, 3I texts, SetTitle, AddRow/DeleteRow/SetC3/SetRowCount.
- `app/Atb.Core.Tests/S2ParityTests.cs` — 10 literal-line tests.
- `app/Atb.App/VehicleForms.cs` — buttons wired, Title editable, Delete disabled at one vehicle, B re-read, grid add/delete, Speed label 48.
- `app/Atb.App/FunctionForms.cs` — Insert on empty list, Editing Function listbox Arial 8.25 bold Navy ItemHeight 14, FormatError box, wind SegID combos, FDF Gray second series.
- `app/Atb.App/DataPlotForm.cs` — multi-series.
- `app/Atb.App.UiTests/Scenarios.cs` — S2ParityVehicleOps, S2ParityGridsAndFunctions.
- `STANDARDS.md` — dropped the two vehicle-disabled lines; corrected the Paste/"use Insert first" line.

## Findings / Deferred
- Divergence: 3I renumbers vehicle SegIDs only when SegID > NSEG and gives an inserted vehicle the selected one's SegID; Renumber always uses NSEG+n. Client decks 2645, 2638, 2480_4/5 have vehicle 1 at body segment 16. Not changed (forms must not renumber) — needs a decision.
- Vehicle Insert writes zeros for C1C2a defaults (ponytail note); 3I reads ATB3iData.mdb defaults.
- Robot does not exercise a two-series FDF plot (no fixture FDF with both F1 and F2 data); covered by the unit test only.

## Flags for Reviewer
- VehEditor.B is now a property that re-scans Vehicles.Blocks on every access (fine at deck sizes; hot in FillGrid loops).
- Vehicle Delete cascades with `_ => true` (3I asks once up front).
