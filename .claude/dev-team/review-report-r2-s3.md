# Review Report
**Date:** 2026-09-15
**Item:** S2 parity fixes (diff e2b01e0..3618cf2, branch r2-s3)
**Files Reviewed:** 7 (Vehicles.cs, Functions.cs, VehicleForms.cs, FunctionForms.cs, DataPlotForm.cs, S2ParityTests.cs, Scenarios.cs) + STANDARDS.md
**Dimensions Swept:** Efficiency 1 · Reliability 1 · Scalability clean · Safety & Security clean (no auth/API/input-to-fetch surface) · Fault Tolerance 1 · Data Integrity 2 · Over-Engineering 1

Guardrails: no renumbering in the forms (VehicleForms only confirms and calls Vehicles.* → Renumber.Insert/Delete; Replace moves no refs, as in 3I) — held. Title edit is one C.1 line; TitleEditRewritesOnlyC1 pins a no-op edit to zero bytes — held. Layout beyond (b)/(h) untouched — held. Scenarios.cs is additions only, no existing assertion loosened — held.

## Findings

### Critical
none

### Important
IMPORTANT — app/Atb.Core/Cards/Vehicles.cs:~130 (Insert) via Renumber.cs:326 — Data Integrity — engineer's flagged divergence, assessed: Renumber shifts only refs >= NSEG+n, so an existing vehicle's token 13 that points at a body segment (2480_4/5: NSEG 18, vehicle 1 token 13 = 16) is left alone, which matches 3I's "only when SegID > NSEG". No existing reference gets corrupted. The one real difference: the inserted vehicle's C.2.A token 13 is always NSEG+n (19 on 2480_4), where 3I copies the selected vehicle's SegID (16). On 2645/2638 (NSEG 15, token 16 = NSEG+1) the two agree. The engineer's report is wrong that 2645 and 2638 put the vehicle on a body segment. — fix: in Vehicles.Insert, after Renumber.Insert, when the selected vehicle's token 13 is nonzero and <= NSEG, set the new C.2.A token 13 to it (a Core post-step, not form renumbering), or record it in STANDARDS.md as a divergence. Nate decides.
IMPORTANT — app/Atb.Core.Tests/S2ParityTests.cs:49-92 — Data Integrity — every vehicle-op test runs on 2645 only, so nothing covers a deck with a body-segment vehicle ref (2480_4/5) — fix: add an insert and delete literal test on corpus/2480/2480_4.LIN asserting token 16 stays 16 and the deck validates.
IMPORTANT — app/Atb.App/VehicleForms.cs:251 — Reliability — UserAddedRow writes the zero deck row as soon as the user starts typing in the new row, and nothing handles CancelRowEdit or Esc. If the user presses Esc, DGV drops the row but the deck keeps it and the row count moves up by one: a hidden row, and the grid and deck row indexes no longer match. — fix: handle Grid.CancelRowEdit (or UserDeletedRow) to call Vehicles.DeleteRow on the last row and FillGrid, or FillGrid after AddRow so the row is committed to the deck.
IMPORTANT — app/Atb.App.UiTests/Scenarios.cs:546,554 + S2ParityTests.cs — Fault Tolerance (vacuous-constant) — the confirmation texts (Vehicles.InsertText/DeleteText/ReplaceText and their titles) are checked only against their own constants and never pinned to literals, so a typo in 3I's text passes every test — fix: add one unit test that Assert.Equals each constant against the literal 3I string, the same way NonNumericMessageAndTitleAreCoreConstants does.

### Minor
MINOR — app/Atb.App/VehicleForms.cs:425 — Efficiency — `B` rescans Vehicles.Blocks(Deck) on every read, and FillGrid and the cell handlers read it per cell: O(rows x cols x deck lines) — fix: cache the block and re-read it only after AddRow, DeleteRow or SetC3.
MINOR — .claude/dev-team/engineer-report.md:9-14 — Fault Tolerance (mutation coverage) — no mutation is recorded for Replace's token-13 keep, Delete's cascade, or Copy, and the row-count mutation sets all three branches of SetRowCount to "0" at once, so no single branch (e.g. the 6-DOF "-" sign) is tested alone — fix: one mutation per guard: drop the `c2a.Set(13, …)`, drop the "-" prefix, and bypass Renumber.Delete.
MINOR — app/Atb.Core/Cards/Functions.cs:507 — Reliability — Insert throws InvalidOperationException when a wind or FDF list has no anchor, and FunctionForms.Insert (:249) doesn't catch it, so the form crashes on a malformed deck — fix: return an error string and Warn, or catch in the form.
MINOR — app/Atb.App/FunctionForms.cs:246 — Data Integrity (parity) — the append path (no selection) still shows the "insert a blank record" confirmation. 3I's add-new row inserts with no confirmation (3I's silence is the spec). — fix: skip Ask when sel.Count == 0, or record the divergence.

### Over-Engineering
MINOR — app/Atb.App/VehicleForms.cs:385 + Vehicles.cs:~150 + Renumber.cs:199 — Over-Engineering — the primary-vehicle rule is written three times (form pre-check, Core return value, Renumber throw). The form check is needed before the confirm, but Vehicles.Delete's own check could just catch Renumber's — fix: have the form call a single `Vehicles.IsPrimary(d, n)` and drop one copy.

Checked clean: clipboard `copied` lives only inside the modal VehicleListForm, and Replace clones its lines, so a deck swap by Apply can't alias it. Replace's C.2.A copy has a count guard (`{ Count: 14 }` on both sides). OtherCurve's ranges match the editor's own (D0..|D1|, |D1|..|D2|). The wind SegID combo unions in existing token values, so there's no DataError on load. NonNumeric test pins literals.

## STANDARDS.md Updates
none (engineer's two removals and the Paste line correction are accurate; the SegID divergence awaits Nate's decision before it becomes a rule)
