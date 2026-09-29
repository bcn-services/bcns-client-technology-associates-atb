# Lane Acceptance Report — Round 2, Session S2
**Date:** 2026-09-14
**Diff:** `git diff tier2-app...r2-s2` (head b1303a3), 2 items: Vehicle Motion list and sub-editors, Function editors. 20 files, +3918/-6.
**Mode:** read only (no repo edits, no commits, no pushes). The CI artifacts were downloaded to /tmp/s2acc. Two opus parity agents compared the forms with ~/atb-work/p0/decomp/ATB3I/.
**Files Reviewed:** 20
- Atb.Core: Cards/Vehicles.cs, Cards/Functions.cs, Labeler.cs
- Atb.App: MainForm.cs, VehicleForms.cs, FunctionForms.cs, DataPlotForm.cs
- UiTests: Scenarios.cs
- Core tests: VehiclesTests, VehiclesQaTests, FunctionsTests, plus fixtures
- Docs: STANDARDS.md, LANE.md, LANE_PROGRESS.md
**Dimensions Swept:**
- Efficiency: 1 finding (Minor)
- Reliability: 4 findings (1 Important, 3 Minor)
- Scalability: clean
- Safety & Security: clean (desktop app; the diff has no auth, network or upload path)
- Fault Tolerance: 2 findings (Minor)
- Data Integrity: 1 finding (Minor)
- Over-Engineering: 1 finding (Minor)
- 3I-parity: 9 findings (1 Critical, 6 Important, 2 Minor groups)

**Overall verdict:**
- **Both S2 items meet their own done-whens and guardrails,** with two things for a human to sign off. First, 3 of the 6 vehicle robot decks and both wind/joint robot decks are synthetic, because no client deck has those types. Second, the vehicle robot's Windows run predates the DataPlotForm extraction.
- **S2 does not yet meet the plan decision "v1 = everything ATB 3I does".**
  - The worst gap is not recorded anywhere: an empty function list gives no way to create the first function. Every client deck has no E.6 or E.7, so no client deck can add a wind or joint function from the app.
  - The Vehicle list's Insert/Copy/Delete/Replace and the grids' add/delete-row are disabled. Both are recorded, but they are still v1 gaps.
- **Where "Copy ATB 3I exactly" holds and where it does not.**
  - Holds: rules, texts, token mappings and button positions.
  - Does not hold: layout inside the sub-editors, and styling (fonts and colours). Most of these differences are not recorded.
- **macOS gate:** 1262/0.
- **Lane criteria:** criterion 4 is met and criterion 2 is partly met. Criteria 1 and 3 are not yet due.

---

## Lane criteria (LANE.md "Lane done when:")

| # | Criterion | Verdict | Why |
|---|---|---|---|
| 1 | Green app-e2e run opens every §2 screen (1–38), a screenshot of each | **not yet** (expected) | S2 adds robot scenarios and screenshots for #10 Vehicle Motion and for #17, #18 and #19 (FDF, Wind, Joint). The all-screens run belongs to S5. |
| 2 | In that run, Run on 2479_2.LIN is identical to direct atb-win32 (cross_gate.py) | **partly met** | The cross_gate step exists (app-e2e.yml:96-98), but it runs only when the filter is empty or contains `Run2479`. It was skipped in both S2 runs, because those were filtered to VehicleMotionEditors and FunctionEditors. src/, verify/ and cases/ are untouched (`git diff --stat tier2-app...r2-s2 -- src verify cases` is empty). |
| 3 | Setup .exe installs; every robot scenario passes against the installed app | **not yet** (expected) | The installer is an S5 item. |
| 4 | macOS `dotnet test` passes | **met** | `PATH="$HOME/atb-work/dotnet:$PATH" dotnet test app/Atb.sln` on b1303a3: Passed 1262, Failed 0, Skipped 0. |

### Windows evidence
| Run | Commit | Scenarios (all green) |
|---|---|---|
| 34920934490 | ee6aa02 | VehicleMotionEditors ×6: sixdof (type 2), 2479_2_halfsine (0), 2107_A2 (4), 2479_2 (5), splinepos (3), 2210_1 (1) |
| 34924273082 | a4b7870 | FunctionEditors ×5: joint row 0, joint row 1, wind row 0, 2479_2 FDF row 3 (polynomial), row 6 (tabular) |

- **34920934490 still stands for b1303a3.** Between ee6aa02 and 91a996b only tests and docs changed.
- **The vehicle evidence was not re-run after the DataPlotForm move.** a4b7870 moved DataPlotForm out of VehicleForms.cs verbatim and added a `double[]` SetData overload. No VehicleMotionEditors run exists on a4b7870 or later (Minor 12).
- **Screenshots I viewed look correct.** In each one, 7.25 is visible in the grid and the plot's peak matches it:
  - VehOpt1 (halfsine) and VehOpt2 (2210_1) with its plot.
  - VehOpt34 (2479_2, "Spline Fit Acceleartion Data") with its plot.
  - FDF list, polynomial and tabular FDF plots.
  - Joint polynomial plot (θ 30–180).
  - Wind time-history table.
- The cmp-app.txt FileNotFoundError in both runs comes from the report-only cmp step. It is expected when no app run happens.

---

## (1) S2 done-whens

### Vehicle Motion list and sub-editors — **holds, with sign-off**

**Guardrail: one form per variant, chosen by VehicleType() — met**
- `Vehicles.VehicleType` (Vehicles.cs:13-18) matches 3I Vehicle.cs:975-994 exactly:
  - 0 → type 0 (half-sine)
  - greater than 0 → type 1 (unidirectional)
  - less than 0 → decided by the Spline Data Type: 0→2, 1→3, 2→4, 3→5, anything else → 0
- Type names match mdb SpecialList 113, including 3I's typo "Deleleration".
- The form each type opens matches Vehicle.cs:497-545.

**Guardrail: editing a row rewrites only that deck line — met**
- EditCell goes through `Deck.Edit` on one line.

**Done-when 1: each client deck's vehicles open in the editor the rule picks — holds**
- `VehiclesTests.EveryClientDeckVehicleOpensItsRuleEditor` asserts the literal census {1:4, 4:9, 5:147} over `Fixtures.ClientDecks()`, which is cases/ plus corpus/.
- No client deck has type 0, 2 or 3.

**Done-when 2: an edit changes only the C.3/C.4/C.5 card, and the plot comes from one Core function — holds**
- `EditRowRewritesOnlyThatLine` has 5 cases across C.3, C.4 and C.5. `ComputedTimeIsNotEditable` also passes.
- `Vehicles.PlotPoints` is the only plot source. VehicleForms.cs:206-212 is its only caller.

**Done-when 3: the robot opens every sub-editor on a client deck, edits a row, saves and screenshots the plot — holds, with sign-off**
- The robot covers all six types, but three decks are synthetic, because no client deck has those types:
  - sixdof (type 2)
  - 2479_2_halfsine (type 0)
  - splinepos (type 3)
- Sign-off is the same kind as S1's 2638 substitution.
- The scenario asserts that exactly the expected line index changed.

### Function editors — **holds, with sign-off**

**Guardrail: the plot's polynomial matches the solver — met**
- `Functions.Poly` (Functions.cs:173-178) is the Horner form of EVALFD_POLY (src/evalfd_poly.for), TAB(NP)+X*(TAB(NP+1)+…).
- `Functions.Table` (:182-192) follows evalfd_table.for:
  - the scan starts at the second X (K1=NP+3)
  - it interpolates on the segment (k-1, k)
  - past the last X it returns TAB(K2), which is Y_last

**Done-when 1: every E.\* function in cases/ and corpus/ opens, and an unedited save changes zero bytes — holds**
- `EveryFunctionOpensAndUneditedSaveChangesZeroBytes` runs over the client decks, vendor samples and synthetic fixtures. It asserts more than 1000 FDFs, 3 wind functions and 13 joint functions.
- Every save path is compared against the file bytes.
- No cases/ or corpus/ deck has E.6 or E.7. For those cards the "every … in cases/corpus" clause is empty, and the vendor and synthetic decks cover them instead.

**Done-when 2: plot points come from one Core function, tested for constant, polynomial and tabular — holds**
- `CurvePoints` is tested by CurvePointsConstant, CurvePointsPolynomial, CurvePointsTabular and TableInterpolation.
- `JointCurvePoints` has its own tests.

**Done-when 3: the robot opens each editor on a client deck and screenshots the plot — holds, with sign-off**
- FDF runs on the client deck 2479_2.
- Wind and joint run on 2479_2_wind and 2479_2_joint. These are client 2479_2 with synthetic E.6/E.7 cards added.
- The wind editor has no plot, and neither does 3I's.

### Plan decisions

**"Copy ATB 3I exactly" — partly met**

Matches 3I:
- The type rule.
- Every message text and title, including the typos "Groud", "Acceleartion", "Waring", "Toque" and "D1 to"+value.
- Deck token mappings.
- Button texts and positions.
- The FDF, joint and wind column captions.
- The F1/F2 default rules.
- The new-ID rule.
- Plot series labels.

Does not match 3I, and mostly not recorded:
- Sub-editor field layout.
- Label fonts and colours.
- The listbox height.
- Wind segment columns are text boxes, where 3I uses dropdowns.
- The joint and wind non-numeric message.

**"v1 = everything ATB 3I does" — unmet.** Missing from ours:
- Creating a function in an empty list.
- Vehicle Insert, Copy, Delete and Replace.
- Adding and deleting rows in the vehicle grids.
- Editing Vehicle Title in the list.
- The second FDF plot series.
- Wind SegID dropdowns.

### Known gaps

| Gap | Result |
|---|---|
| Vehicle Insert/Copy/Delete/Replace and grid add/delete disabled | **Confirmed.** VehicleForms.cs:32-35 (buttons built with `act == null`), and :178/:183 (`AllowUserToAddRows`/`AllowUserToDeleteRows` false). Recorded in STANDARDS.md:28-29. For how much work 3I's versions would be, see Important 3. |
| Function D3/D4 and wind captions not checked against the mdb | **Refuted, no gap.** The E1E2 columns really are named D3 and D4. The wind list matches E6ab, and the time history matches E6d (Time, Fx, Fy, Fz). |
| "Editing Function" listbox shows 1 item where 3I shows 2 | **Confirmed. It is a display bug, not a missing item.** Both lists hold "Function F1" and "Function F2". 3I's box is 96x32 with Arial 8.25 bold and ItemHeight 14 (GenList.cs:492-505), which shows two rows. Ours uses the default font, so IntegralHeight shows one (FunctionForms.cs:63-67). |
| Robot doesn't drive function Insert/Delete/Copy/Paste | **Confirmed.** The FunctionEditors and VehicleMotionEditors scenarios open, edit and save only. They don't drive list Insert/Delete/Copy/Paste or the F1/F2 type-change dialogs. Unit tests cover the core operations. |

---

## (2) Cross-item interactions

| Interaction | Result |
|---|---|
| DataPlotForm extracted from VehicleForms.cs (a4b7870) and shared by vehicles and functions | Sound. The move is verbatim, plus a `double[]` → `float[]` SetData overload (DataPlotForm.cs:32-33). The function run on a4b7870 exercises it. The vehicle path has no Windows run after the move (Minor 12). The shared form draws one series only, which blocks 3I's two-series FDF plot (Important 4). |
| MainForm handlers `VehicleMotion()` / `FunctionList(kind)` | Sound. Both return when a run is in progress or no deck is open. When `f.Changed` is true, they assign the deck, mark it dirty and call ShowDeck. Menu placement cites MainMenu.cs:2691-2721. |
| Labeler `FunctionType` changed from private to public | Harmless. Only the visibility changed. |
| `Functions.SetNWindF` edits D.1.A NWINDF and adds or removes F.7.A (another screen's card) | Correct on the tested decks. It returns silently when no anchor (F.8.A/F.9/F.10/G.1) is found, which leaves NWINDF and F.7 inconsistent (Minor 10). |
| src/ | No balance code. `grep -i balanc src/` finds only two comments that predate the diff (module_standard.for:936, input_harness.for:60). |

---

## (3) 3I divergences recorded in STANDARDS.md, checked against ~/atb-work/p0/decomp/ATB3I/

| STANDARDS line | Real? | Evidence |
|---|---|---|
| :28 Vehicle Insert/Copy/Delete/Replace disabled | **Real** | Vehicle.cs:557-631 (Insert, confirm at :582), :349-372 (Copy), :374-479 (Delete, confirm at :407, "You can't delete the primary vehicle."), :633-748 (Replace, confirm at :684). In 3I, Delete is also disabled when only one vehicle exists (:893). |
| :29 Grids can't add or delete rows | **Real** | ATBGrid.cs:702-704 (AllowAddNew/AllowDelete true), with the popup menu at :388-420 and Excel paste at :1833-1850. 3I's OK recomputes Interpolated Points / NumDataPoints (VehOpt2.cs:1604-1647, VehOpt34.cs:2379-2443). |
| :30 SegID derived | **Real** | 3I stores C1C2a "Vehicle SegID" at import. |
| :31 Segment lists | **Real** | Matches the parity agent's reading of 3I's RefSegment filtering. |
| :32 Write on leaving a box, working copy, modal | **Real** | VehOpt1.cs:1305-1318 writes every field on OK. The list's own MDI hide/reopen (VehOpt1.cs:1286-1298) is not mentioned (Minor 16). |
| :33 VehOpt2 Y axis "VehicleID" | **Real, citation accurate** | VehOpt2.cs:1649-1683: `int index = default(int)` makes `get_GridColumnCaption(0)` return "VehicleID". |
| :34 Function list stays open under its editor | **Real** | GenList btnEdit closes the list (MDI). |
| :35 F1→Constant zeroes D2; F2 refused while F1 is Constant | **Real** | 3I keeps D2 and allows the F2. |
| :36 Tabular plot endpoints interpolated | **Real** | FDFData.cs btnPlot draws the pairs only. |
| :37 Joint plot uses pi/180 and clamps at 0 | **Real** | 3I JntFData uses 57.3 with no clamp. |
| :38 FunctionID uniqueness checks E.1 only | **Real; this is parity** | 3I's own UsedFunctionID loops three times but checks E1E2 each time (ATB3I.Util/ATBParam.cs:117-128). |
| :39 New wind function adds F.7.A | **Real** | 3I leaves F.7 to its Wind screen. |
| :40 Paste into a deck with no E.7 adds nothing | **Real, but the wording is wrong** | It says "use Insert first", but Insert refuses on an empty list (Critical 1). |

---

## Findings

### Critical
1. **app/Atb.App/FunctionForms.cs:28 and :211 (with app/Atb.Core/Cards/Functions.cs:415) — 3I-parity (missing capability).**
   - **Problem.** An empty function list can't create its first function:
     - The grid has `AllowUserToAddRows=false`.
     - `Insert` refuses when no row is selected.
     - `Functions.Insert` needs a `before` head line.
     - Paste needs clipboard rows plus an existing section.
   - **Effect.** Every client deck has no E.6 and no E.7, so no client deck can add a wind or joint function in the app. 3I's add-new row works on zero rows (GenList.cs:690, ATBGrid.cs:2788-2818). It uses ID GridFindMin-1, and for a joint NTheta 2, NPhi 1, Type 1. This is not recorded, and STANDARDS.md:40 gives advice that can't be followed.
   - **Fix.** When the list is empty, let Insert with no selection append a blank function at the section's position, creating the E.6/E.7 section and its terminator when absent. Correct STANDARDS.md:40.

### Important
2. **app/Atb.App/FunctionForms.cs:63-67 — 3I-parity (UI).**
   - **Problem.** The "Editing Function" listbox shows only "Function F1". F2 is reachable only with the tiny scroll spinner.
   - **Fix.** Use 3I's Arial 8.25 bold Navy with ItemHeight 14 (GenList.cs:492-505), or set `IntegralHeight=false` with a two-row height.
3. **app/Atb.App/VehicleForms.cs:32-35, :178, :183 — 3I-parity (v1 scope, recorded).**
   - **Problem.** Four of the six Vehicle list actions are disabled, and grid row add/delete is off. 3I has them all, and "v1 = everything 3I does" requires them.
   - **Fix.** Build Insert, Delete, Copy and Replace as C.1–C.5 block operations on the existing Renumber machinery. Delete also needs the primary-vehicle guard, and Delete must be disabled when there is one vehicle. Grid add/delete must rewrite C.2.A token 8 and C.2.B token 2 from the row count. The parity agent estimates 1–2 days.
4. **app/Atb.App/FunctionForms.cs:445-452 and app/Atb.App/DataPlotForm.cs:26-33, :63 — 3I-parity.**
   - **Problem.** The FDF plot draws one series. 3I draws two: the current grid, plus the other sub-function from saved data with colour index 4 (FDFData.cs:675-708). 3I falls back to one series only when the other sub-function has no data. This is not recorded.
   - **Fix.** Let DataPlotForm take a list of series and pass the other sub-function's `CurvePoints`.
5. **app/Atb.App/FunctionForms.cs:45-50 — 3I-parity.**
   - **Problem.** The wind Velocity SegID and Reference SegID columns are free-text boxes. In 3I they are segment dropdowns (DropDownCols {7,3},{8,3}, MainMenu.cs:4509-4513). This is not recorded.
   - **Fix.** Use DataGridViewComboBoxColumn filled with the deck's segments.
6. **app/Atb.App/FunctionForms.cs:189 and :205 — 3I-parity (text).**
   - **Problem.** Non-numeric input in the joint list (FunctionID, NTheta, NPhi, Type) and the wind list (FunctionID, Specific Heats) shows "Input must be a number!" / "Input Warning". 3I shows "Input string was not in correct format!", titled "ATB 3I", with the Error icon (ATBGrid.cs:2523-2528, :2728-2733).
   - **Fix.** Use 3I's text, title and icon on those two paths.
7. **app/Atb.App/VehicleForms.cs (VehicleListForm grid, ReadOnly) — 3I-parity.**
   - **Problem.** Vehicle Title can't be edited in the list. 3I's list is an editable table, and Vehicle_Closing writes every row's title back to C1C2a (Vehicle.cs:750-796). This is not recorded.
   - **Fix.** Make the Title column editable and write C.1 token 0 through `Deck.Edit`.

### Minor
8. **app/Atb.App/VehicleForms.cs:293-310 — Fault Tolerance.**
   - **Problem.** VehOpt34 dereferences `r1!`/`r2!` with no guard. A type 4 or 5 deck with short C.5a data throws a NullReferenceException.
   - **Fix.** Guard it, and warn or disable the group when the row is missing.
9. **app/Atb.App/DataPlotForm.cs:42 and :63 — Efficiency.**
   - **Problem.** `new Pen(...)` is created on every paint and never disposed.
   - **Fix.** `using var`, or a static readonly pen.
10. **app/Atb.Core/Cards/Functions.cs (`SetNWindF`) — Fault Tolerance.**
    - **Problem.** When none of the F.8.A/F.9/F.10/G.1 anchors exists, it returns silently after NWINDF has changed, so D.1.A and F.7 disagree.
    - **Fix.** Fall back to appending before the deck's final section, or throw so the form can warn.
11. **app/Atb.Core/Cards/Functions.cs:464 and :504-536 — Data Integrity.**
    - **Problem.** CopyText writes FileID "0", and Paste looks up the source data only in the current deck. A row copied from another deck pastes with blank E.3/E.4/E.6/E.7 data and no warning. 3I reads the source file's data (ATBGrid.cs:3330-3372). This was reported by the parity agent and not re-checked by me.
    - **Fix.** Put the sub-data in the clipboard text, or refuse a paste whose source is not in the current deck.
12. **Windows evidence (run 34920934490) — Reliability.**
    - **Problem.** VehicleMotionEditors last passed on ee6aa02, before a4b7870 moved DataPlotForm. The move was verbatim, but the vehicle plot path has not been re-run.
    - **Fix.** Run app-e2e once on the r2-s2 head with `VehicleMotionEditors|FunctionEditors|Run2479`. Including Run2479 also runs cross_gate.
13. **Robot coverage (Scenarios.cs, S2 scenarios) — Reliability.**
    - **Problem.** The robot never drives function Insert, Delete, Copy or Paste, the F1/F2 type-change dialogs, or the vehicle "Wrong selection." / "No data to operate on." paths.
    - **Fix.** Add one FunctionEditors step that Inserts, then Deletes, and asserts the row count.
14. **app/Atb.App/VehicleForms.cs:119 — Over-Engineering.**
    - **Problem.** A dead SegId branch.
    - **Fix.** Delete it.
15. **LANE_PROGRESS.md "Next:" — Reliability (docs).**
    - **Problem.** It says "next the following S2 item", but both S2 items are done.
    - **Fix.** Name S3 Run Control.
16. **Unrecorded layout and styling divergences — 3I-parity. None changes behaviour.**
    - **Problem, vehicle sub-editors:**
      - Labels sit left of 64-wide boxes. In 3I, labels sit above 80-wide boxes, and fields that 3I puts side by side are stacked in ours.
      - The inner "Initial Velocity" label is missing in VehOpt1 and VehOpt2.
      - VehOpt2's Initial Velocity group and origin group are in reversed order.
      - VehOpt34's Start/Interval/Points row and Spline Degree are in different positions.
      - 3I's green and navy label colours are not used.
      - The Time column is read-only and cyan. In 3I it is editable and uncoloured.
      - The plot has no dashed gridlines and can't be resized.
    - **Problem, function editors:**
      - FDFData's D0/|D1| labels sit left of their boxes, not above.
      - JntFData's labels are not DarkRed bold, and its Phi column is not frozen.
      - List grids use default fonts, colours and widths, not Aqua even rows and fixed widths (ATBGrid.cs:686-917).
      - Message icons are Exclamation where 3I uses Error (ATBGrid.cs:2239, :2557, :2587).
      - The Specific Heats prompt appears only when the old value is 0; 3I asks on any nonzero change. The resulting data is the same.
      - The FDFData warning adds "(or |D2|)".
      - Five validation messages exist that 3I never shows (Functions.cs:255-296, FunctionForms.cs:483).
      - 3I's polynomial-plot warning "The lower and upper abscissas have the same value." is missing.
      - θ captions are formatted as `double` "G" where 3I uses `float` 7-digit.
      - The constant-value InputBox has the same text as 3I but a different layout (FunctionForms.cs:307-319).
    - **Fix.** Either fix the ones cheap enough to be worth it, or add one STANDARDS line: "sub-editor field layout, fonts and colours follow WinForms defaults, not 3I's designer". Also record 3I's `SELECT *` grid column order for C3/C4/C5b (unverified at runtime) as a divergence.

### Needs human sign-off (not defects)
- **Synthetic robot decks for vehicles.** The vehicle robot uses synthetic decks for types 0, 2 and 3: sixdof, 2479_2_halfsine and splinepos. No client deck in cases/ or corpus/ has those types.
- **Synthetic robot decks for functions.** The wind and joint robot scenarios run on 2479_2 with synthetic E.6/E.7 cards added, because no client deck has those cards.
- **The "v1 = everything 3I does" scope.** It currently excludes vehicle list actions and grid row add/delete, which are recorded as deliberate. Someone should decide whether that exclusion stands for v1 or becomes a later item before the installer ships.

## STANDARDS.md Updates
None. This review is read only, as instructed. The suggested edits are in Critical 1 (the :40 wording) and Minor 16 (the layout line, the :32 list-window note, and the `SELECT *` column order).
