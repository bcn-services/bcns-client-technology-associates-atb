# Review Report — r2-s3b (DELTA, 3618cf2..966248f)
**Date:** 2026-09-15 · **Files reviewed:** 6 code (Vehicles.cs, VehicleForms.cs, FunctionForms.cs, S2ParityTests.cs, Scenarios.cs, STANDARDS.md) + 1 fixture
**Dimensions:** Efficiency 1 · Reliability 1 · Scalability clean · Safety/Security clean · Fault Tolerance 2 · Data Integrity 1 · Over-Engineering clean
**C/I/M: 0/3/4**

## Prior-report Importants (verified against 3618cf2..966248f)
FIXED — Vehicles.cs:138-145 — SegID post-step is Core-only, rewrites the new C.2.A token 13 alone; ref shift still divergent, now recorded in STANDARDS.md:29 for Nate.
FIXED — S2ParityTests.cs:181-205 — insert+delete literal test on corpus/2480/2480_4.LIN, token 16 held, byte round-trip asserted.
FIXED — VehicleForms.cs:253 + Vehicles.cs:200 — Esc-cancelled new row trimmed from the deck; TrimRowsDropsTheCancelledNewRow pins zero-byte round-trip on 2479_2 and 2210_1.
FIXED — S2ParityTests.cs:171-180 — all 7 vehicle texts pinned to literals; byte-checked against decomp Vehicle.cs:404/407/582/684 — exact, including insert's double space before "Continue?".
NO REGRESSION — Scenarios.cs: additions only plus one replacement (the removed "Insert Data" Yes click is replaced by a stronger `Assert.Null(FindWin(r,"Insert Data"))`); no existing assertion loosened; no src/, verify/, cases/ touched; Atb.Core still UI/DB-free.

## Findings

### Important
IMPORTANT — app/Atb.App.UiTests/Scenarios.cs:659 — Fault Tolerance (vacuous guard) — the "SegID list dropped" wait asserts the ExpandCollapseState that the robot's own `seg.Expand()` on line 658 just set, so it cannot reproduce the F4 failure and nothing asserts the list holds the deck's segments — fix: before the shot assert `seg.AsComboBox().Items.Length` equals the expected SegID option count, so the guard fails on an empty or unpopulated editor.
IMPORTANT — LANE.md:195 / .claude/dev-team/engineer-report.md:4 — Reliability (unverified) — 966248f has no green app-e2e run; the only Windows evidence is 35024899124, which failed at this exact step pre-fix, and the fix pass's PNGs (wind-segid-dropdown, row-cancelled, copied, two-series FDF) are unread — fix: run app-e2e on 966248f, read those four PNGs, record the URL before the item leaves blocked.
IMPORTANT — app/Atb.App/VehicleForms.cs:253 — Fault Tolerance (mutation isolation) — the only unit test calls `Vehicles.TrimRows` directly, so deleting the `RowsRemoved` wiring line stays green on the Mac gate; the wiring is covered only by the unrun robot — fix: after the Windows run, delete line 253 and confirm the s2parity-grids saved-deck compare goes red, then log it in the engineer report.

### Minor
MINOR — app/Atb.App/VehicleForms.cs:253 — Data Integrity — `RowsRemoved` is unconditional: any non-`loading` row removal (a future programmatic `Rows.RemoveAt`, a grid rebind outside FillGrid) silently deletes committed deck rows with no cancel path — fix: guard on the removed index being the uncommitted new row (`e.RowIndex >= Vehicles.RowCount(B) - 1`) or set `loading` around every programmatic removal.
MINOR — app/Atb.Core/Cards/Vehicles.cs:201 — Efficiency — `TrimRows` re-runs `Blocks(d)` (a full deck scan) on every loop iteration — fix: hoist the block out of the loop; `DeleteRow` does not invalidate it.
MINOR — app/Atb.App/FunctionForms.cs:243 — Data Integrity (parity) — the new catch shows the exception text under 3I's real title "Insert Operation Warning" (ATBGrid.cs:509), whose 3I body is always "No record/row selected for this operation."; our body is an invented string and is pinned nowhere — fix: use the 3I body or record the divergence in STANDARDS.md.
MINOR — STANDARDS.md:29 — Data Integrity (open conflict, human decision) — insert still shifts vehicle-segment refs where 3I queues no update (selected SegID <= NSEG); recorded as a divergence, not resolved. Pulls against "copy ATB 3I exactly" — left for Nate.

## STANDARDS.md Updates
none (delta review; the engineer's SegID divergence entry is accurate as written)
