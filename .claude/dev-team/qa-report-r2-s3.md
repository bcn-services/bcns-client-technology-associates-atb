# QA Report
**Task:** S2 parity fixes (a)-(h) · **Branch:** r2-s3 @ 3618cf2 · **Date:** 2026-09-15 · **Gate mode:** tests+behavioral

## VERDICT: FAIL

## Criteria Checked
- First wind + first joint on 2479_2 copy — S2ParityTests.FirstWindAndJointFunctionCreateTheirSectionsAndTerminator, ran in gate — PASS
- Vehicle insert/copy/delete/replace via Renumber, primary refusal, row-count rewrite — S2ParityTests vehicle/row tests ran green; engineer mutation log present (5 guards, each named red test) — PASS (mutations not re-run by QA, time)
- FDF second series from CurvePoints / absent without data; FormatError constants — S2ParityTests.FdfOtherSeries... ran green — PASS
- Robot scenario with all required screenshots — run 35021573881 green 13/13, 85 PNGs downloaded and read — FAIL (see Failures)
- Existing tests remain passing — `dotnet test app/Atb.sln` run by QA: 1272 passed, 0 failed (baseline 1262) — PASS

## Failures
- No two-series FDF plot screenshot in any run folder (only single-series 05-data-plot/04-data-plot shots) — the done-when names it explicitly; add a synthetic fixture copy with F1+F2 data and shoot the plot — bug
- No Copy Vehicle step screenshot: Scenarios.cs:544 clicks Copy Vehicle but calls no r.Shot; s2parity-vehicles has 01-10 with no "copied" frame — bug
- Wind segment dropdown only visible closed (s2parity-grids/09-wind-first-function.png shows combo arrows on Velocity/Reference, list never dropped open) — weak; a dropped list shot would settle it — bug

## Screenshots read (pass)
- 11-fdf-editing-function-box: "Function F1"/"Function F2" listbox, bold Navy — matches (b)
- 04-inserted (2645, 15 segments): Inserted Motion at SegID 16, DOOR 17, TARGET VEHICLE 18 — renumbered, consistent

## Engineer open points — rulings
- (1) SegID renumber: on 2645 the status bar shows 15 segments and vehicles sit at 16/17/18, i.e. already NSEG+n, so ours and 3I's "SegID > NSEG" rule agree there; the 3I Vehicle.cs decompile is not in the repo tree to confirm 2638/2480_4/5 — Not Verifiable by QA, not counted as a failure
- (2) C1C2a defaults: `mdb-export ATB3iData.mdb C1C2a` returns the header row only, no data rows — so the mdb has no defaults to read; zeros are defensible (C2b not checked)
- (3) Two-series FDF screenshot missing — FAIL, see Failures

## Guardrails
- Forms renumbering / only-edited-line / unedited-save zero bytes: covered by engineer tests that passed in the gate; the robot's existing S2 assertions were not diffed by QA (time)

## Tests Added
- none (no time for a Windows robot round-trip before 14:14; the fix is two r.Shot calls plus an F1+F2 fixture)

## Not Verifiable
- 3I renumber behavior on decks where vehicle SegID <= NSEG (decompile not located); interpretation tested: 2645 screenshot only
