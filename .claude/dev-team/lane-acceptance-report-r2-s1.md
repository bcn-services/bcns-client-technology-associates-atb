# Lane Acceptance Report — Round 2, Session S1
**Date:** 2026-09-14
**Diff:** `git diff 759fa78...35fb366` (branch tier2-app), 4 items: GEBOD Replace follows ATB 3I, segment/joint insert/delete warning, Body Summary screen, Maximum Value List screen
**Mode:** read only (no repo edits, no git state changes; mutation probes ran on a throwaway copy in /tmp, since deleted)
**Files Reviewed:** 22 (Atb.Core Cards: GebodMerge, Bodies, Renumber, MaxValues; Atb.App: MainForm, BodyForm, GebodForm, MaxValueForm; UiTests: Robot, Scenarios; Core tests: CascadeWarningTests, MaxValuesTests, BodiesTests, BodiesQaTests, GebodMergeTests, GebodMergeQaTests, GebodReplace*QaTests, GebodReplaceActuatorTests; STANDARDS.md; LANE.md; app-e2e.yml)
**Dimensions Swept:** Efficiency — 1 finding (Minor) · Reliability — 2 findings (Minor) · Scalability — clean · Safety & Security — clean (desktop app, no auth/network/upload path in the diff) · Fault Tolerance — clean · Data Integrity — 1 finding (Important) · Over-Engineering — clean · 3I-parity documentation — 3 findings (Minor)

**Overall verdict:** S1 accepted. All four items' done-whens hold. One substitution needs a human sign-off: 2495_2 is used in place of 2638 for Body Summary's first done-when. There are no Critical findings. One Important finding is a test gap: the carried-copy reference shift is correct in the code, but no test would catch its removal. The macOS gate is 1194/1194. Lane criterion 4 is met and criterion 2 is partly met. Criteria 1 and 3 are not yet met, and both are expected below the stop marker.

---

## Lane criteria (LANE.md `## Objective`)

| # | Criterion | Verdict | Why |
|---|---|---|---|
| 1 | Green app-e2e run opens every §2 screen (1–38), a screenshot of each | **not yet** (expected) | S1 adds Body Summary (#6) and Maximum Value List (#38) with robot scenarios (BodySummaryDialogs, MaxValueList). The rest of the §2 screens are S2–S5 items below the `⚠️ AUTONOMOUS RUN — STOP HERE` marker. |
| 2 | In that run, Run on 2479_2.LIN is identical to direct atb-win32 (cross_gate.py) | **partly met** | cross_gate.py is already a step in app-e2e.yml (:98), and the S1 run scenarios passed. But "that run" (the all-screens run) does not exist yet, and the S1 evidence runs were filtered to named scenarios. |
| 3 | Setup .exe installs; every robot scenario passes against the installed app | **not yet** (expected) | The installer is an S5 item, below the marker. |
| 4 | macOS `dotnet test` passes | **met** | `PATH="$HOME/atb-work/dotnet:$PATH" dotnet test app/Atb.sln` → Passed 1194, Failed 0, which meets the 1194 floor. |

### Windows evidence
| Run | Commit | Scenarios (all green) |
|---|---|---|
| 34908386359 | cdd5e1f | GebodReplaceBody1Run, InsertSegmentRun, NewGebodSaveRun |
| 34910270110 | 18520c5 | GebodReplaceBody1Run, InsertSegmentWarning, InsertSegmentRun |
| 34914745232 | e6b965d | BodySummaryDialogs, BodySummaryDeleteRun, GebodReplaceBody1Run |
| 34916340763 | 741b3f9 | BodySummaryDialogs, MaxValueList |
| 34917011692 | 35fb366 | full run in progress, not waited on per instruction |

---

## (1) S1 done-whens

### GEBOD Replace follows ATB 3I — **holds**
- **Refs by position; later refs shift by the difference.** GebodMergeTests.cs:157 `ReplaceBody1_KeepsRefsByPosition_AndShiftsLaterOnesByTheDifference` asserts literal lines, e.g. `1 32 1 63 1 0 1 3 1 -1 0`, and B.1 `30 29`.
- **Shorter body drops only the surplus refs.**
  - GebodMergeTests.cs:190 `ReplaceWithShorterBody_DropsSurplusRefs_AndShiftsLaterOnesDown` (B.1 `5 4`) and GebodMergeTests.cs:223 `ReplaceBody1WithShorterBody_MovesTheNextBodyDown`.
  - QA tests: GebodMergeQaTests (Decline, LongerOrEqual_DoesNotAsk, EveryFamilyRef, ConfirmList_CoversEveryRefToASurplusPosition), GebodReplaceJointQaTests (Body1Extra/Body1Surplus/Body2Surplus/LaterBodyExtra/LaterBodySurplus), GebodReplaceH11QaTests, GebodReplaceActuatorTests, and GebodReplaceClientDeckQaTests.ReplaceEveryBody_NeverThrows_AndValidates.
  - Mutations are recorded in the item reports. In fe5d7ea, (a) drop-all fails at GebodMergeTests.cs:164 (4 tests) and (b) skip-shift fails at :227 (5 tests). 4de868d records M1, M2 and M5.
- **Robot.** GebodReplaceBody1Run is green in 34908386359, 34910270110 and 34914745232.
- **Old drop-all tests updated, and stale text removed.**
  - The drop-all tests were renamed or rewritten to the 3I rule.
  - The ponytail note in GebodMerge is gone, and the old drop-all STANDARDS line was replaced by STANDARDS.md:32.
  - A grep for drop-all or "not remapped" wording outside history finds nothing stale.

### Segment/joint insert/delete warning — **holds**
- **Texts and titles match 3I.**
  - Renumber.cs:168-171 matches 3I TableForm.cs:412/:432 character for character.
  - `CascadeWarningTests.Texts_AreAtb3IStrings` pins them as literals, not as the constants, so it avoids the vacuous-constant trap.
- **Behaviour.** `No_IsNotConfirmed`, `Asks_3IText_WithDeleteListBelow_OnlyForSegmentsAndJoints` and `InsertSegment_LeavesJointsAlone_ValidatesClean`.
- **Wiring.** MainForm.cs:213 (AddRow) and :322 (PasteRows) ask before inserting. :237-239 (DeleteRows) asks once with the reference list below the text, and :245 skips the per-row confirm through `cascade ||`.
- **Robot.** InsertSegmentWarning is green in 34910270110. InsertSegmentRun answers Yes to both prompts.

### Body Summary screen — **holds, with one substitution to sign off**
- **Delete second body.** The done-when names 2638_Start_135_, but that deck has one body. BodiesTests.cs:28 `Deck2638_HasNoSecondBody` proves this: BodyStarts is [1] and Delete(2) throws. 2495_2 was used instead, in BodiesTests.cs:36 `DeleteSecondBody_2495_LeavesBody1AndAValidDeck` and in the robot's BodySummaryDeleteRun (green in 34914745232). **A human needs to sign off on this.**
- **Copy + Add.** BodiesTests.cs:68 `CopyBody1AndAdd_2479_AppendsItWithReferencesOnTheCopy` asserts literal lines. BodiesTests.cs:94 and BodiesQaTests.cs:26/:39 cover Insert before body 1 and partial B.2.B.
- **Replace uses the GEBOD Replace path.** Bodies.cs:53 calls `GebodMerge.ReplaceBody`, the same function GEBOD Replace uses (GebodMerge.cs). BodiesTests.cs:110 and :128 check it by position.
- **Dialogs.** BodySummaryDialogs covers the :627, :860, :990, :1049, :756 and empty-clipboard dialogs. Coverage gaps are listed as a Minor finding below.
- **Parity.**
  - Button texts and positions and the form title "Body Editing Form" match 3I Body.cs:384-470. The on-screen order follows 3I's Location values, not the order listed in the task.
  - Delete follows 3I DeleteBody (Body.cs:1078-1124): Bodies.cs:65-69.

### Maximum Value List screen — **holds**
- **Rows.** MaxValues.cs has 21 rows. I checked every ID, name and value against `mdb-export … Setting`; all match and they are in ID order. `MaxValuesTests.Rows_AreTheSettingTableInIdOrder` pins them as literals.
- **Menu and title.**
  - File > Setting sits between separators before Exit, as in 3I MainMenu.cs:2650-2690.
  - The title "ATB 3I Maximum Value List" matches MainMenu.cs:4301.
  - The form is read-only with a Cancel button (see STANDARDS divergence below).
- **Robot.** MaxValueList is green in 34916340763.
- **Human call.** The item says "same … columns". 3I's grid literally shows Value | FileID | ZzzKey: the Name column is hidden by lftHideCols=1 (TableGridParam.cs:210, ATBGrid.cs:741-746). Ours shows Value | Name. STANDARDS records this as a deliberate divergence. The citations are accurate, but whether this satisfies "same columns" is a product call.

---

## (2) Cross-item interactions from stacking the four items

| Interaction | Result |
|---|---|
| `GebodMerge.ReplaceBody` shared by GEBOD Replace and Body Summary Replace | Sound. GEBOD passes the confirm callback, and Body Summary passes `_ => true`, since 3I asks only :860 (Bodies.cs:53). Both callers are tested: GebodMergeTests.cs:157/190/223 and BodiesTests.cs:110/128. The held-token `Renumber.Place` wrapper resolves correctly after Swap and after Insert. |
| `GebodMerge.AddBody` shared by GEBOD Add and Body Summary Insert | Sound (Bodies.cs:41). |
| Renumber cascade constants used by three consumers (MainForm prompts, BodyForm, robot titles) | Sound. The robot uses the constants only to find dialog titles, and the texts are asserted as literals in CascadeWarningTests and Scenarios. |
| Renumber `Live(d)` added to Unref and Insert (:268, :308) for the Body Summary item, which also runs under every grid insert/delete from the warning item | Sound. The carried table is empty outside `Place` (Renumber.cs:145-146, `finally` removes it), so grid edits see exactly `d.Lines`. There is a test gap, though; see Important finding 1. |
| MainForm menu wiring (Setting, Body Summary, GEBOD preset) | Sound. The menu order is File, Edit, View, Model, Tools. `bodyClip` is cleared on Open, NewDeck, and a GEBOD merge into a null deck. `Gebod(preset)` skips ConfirmReplace, because Body Summary already asked :1049. The GebodForm preset clamp runs after `body.Maximum` is set. |
| ReplaceBody order: segments deleted before joints | Safe. There is no B.3 cascade, and a surplus joint's Seg JNT is blanked to -1 and then deleted. |
| Robot `RunDeck` late-dialog poll (Robot.cs:251) | No regression. It is green in all four runs. It costs up to 10 s per run on the no-dialog path (Minor). |

---

## (3) 3I divergences recorded in STANDARDS.md — checked against ~/atb-work/p0/decomp/ATB3I/

| STANDARDS line | Real? | Evidence |
|---|---|---|
| :24 GEBOD Replace, body 1 of a multi-body deck | **Real** | Checked against GEBOD.cs:1797 (`Math.Max(selJnt - 1, 0) + num3 + num23`), GEBOD.cs:2407-2413 (NULL re-added at NSEGS, `array[1] = num5 + NSEGS - 1`) and Body.cs DeleteBody (joints a..b-1 for k<nb). For middle and last bodies the arithmetic equals ours. |
| :25 Copied bodies carry their own references | **Real** | 3I InsertBody pastes the B2B6M/B3B4B5M rows through InsertValues, which rewrites only SegID/JntID. G.3.A is in neither table, so 3I's copies get no G.3.A rows. |
| Max Value List read-only, columns Value and Name | **Real, citations accurate** | Checked against MainMenu.cs:4296-4317 (GridMode 4, btnOK "Save", width 245, grid 230), ATBGrid.cs:614-616, TableGridParam.cs:210 (lftHideCols = 1), ATBGrid.cs:741, :742-746 and :1052-1058. |
| :27 Body Summary's GEBOD buttons ask once | **Accurate, but it is parity, not a divergence** | 3I GEBOD.cs has no confirmation MsgBox; :1447-1985 are only input-validation prompts. So 3I also asks once (Body.cs:990/:1019/:1049). team-memory.md's "3I asks twice" is wrong. |
| :32 GEBOD Replace is by position | **Real parity statement** | Matches GEBOD.cs:1766-1800 and the ATBUpdate.UpdateOtherTable update list. |

---

## Findings

### Critical
None.

### Important
1. **app/Atb.Core/Cards/Renumber.cs:160-165 (`Live`, consumed at :268 and :308) — Data Integrity.**
   - **Problem.** No test covers the carried-copy shift. A mutation making `Live` return `d.Lines` leaves 1194/1194 green. Yet on the client decks, 472 of 1159 Copy + Insert/Replace operations write different decks without it. The copied G.3.A rows' segment reference goes wrong:
     - 2495_2 body 1, Add: 35 instead of 52.
     - 2479_2 body 2, InsertBefore 1: 1 instead of 16.
     - 2513_2 body 1, Replace 2: 30 instead of 29.
     The shipped code gives the correct values.
   - **Fix.** Add a literal assertion to BodiesTests pinning the copied G.3.A segment reference: 52 for 2495_2 Copy(1)+Add, and 16 for 2479_2 Copy(2)+InsertBefore(1).

### Minor
2. **app/Atb.Core/Cards/Bodies.cs:76 — Reliability.**
   - **Problem.** `Take` checks only that the Clip range is inside the deck. A Clip left stale by grid edits made after Copy can straddle two bodies and paste a malformed "body". This is 3I parity, since 3I's clipboard (`BODY\tFID\tfirst\tlast\t…`) is also positional.
   - **Fix.** Also require that `BodyStarts(d)` contains `c.First`, and that the next start (or NSEG+1) equals `First+Segments`.
3. **app/Atb.App.UiTests/Robot.cs:251 — Efficiency.**
   - **Problem.** Every RunDeck that ends at Main polls 10 s for a late run dialog, adding up to 10 s to each clean run.
   - **Fix.** Poll about 2 s, or poll only after the .aou appears within a short window.
4. **app/Atb.App/MainForm.cs:237 with :264-270 — Reliability (UX text).**
   - **Problem.** The delete detail joins entries with "\r\n\r\n", but RefText builds its lines with "\n", so the line endings are mixed in one MessageBox.
   - **Fix.** Use "\r\n" in RefText.
5. **Scenarios.cs (BodySummaryDialogs) — Reliability (test coverage).**
   - **Problem.** 3I's empty-deck prompts (:665, :1019) are exercised nowhere. The robot never presses Yes on Insert Copied or Replace Copied; only the unit tests cover those paths.
   - **Fix.** Add one robot step that answers Yes on :860 and checks the Body Summary row counts.
6. **STANDARDS.md:24 — 3I-parity documentation.**
   - **Problem.** The body-1 divergence applies equally to Body Summary's Replace with Copied Body: 3I btnReplace uses the same `Math.Max(num4-1,0)+num+length` math. The line names only GEBOD.
   - **Fix.** Extend the line to cover Bodies.Replace.
7. **STANDARDS.md:27 — 3I-parity documentation.**
   - **Problem.** "Ask once" is filed under divergences, but it is parity, since 3I GEBOD.cs has no confirmation prompt. team-memory.md says "3I asks twice", which is wrong.
   - **Fix.** Reword it as parity and correct team-memory.
8. **STANDARDS.md (missing line) — 3I-parity documentation.**
   - **Problem.** An unrecorded divergence: 3I's btnGReplace_Click calls DeleteBody() before the GEBOD form opens, so cancelling GEBOD in 3I leaves the body deleted. Ours (MainForm `BodySummary` → `Gebod(preset)`) leaves the deck unchanged. That is safer, but it is not written down.
   - **Fix.** Add a divergence line.

### Needs human sign-off (not defects)
- Body Summary's first done-when: 2495_2 was used instead of 2638_Start_135_, which has only one body (BodiesTests.cs:28).
- Maximum Value List "same … columns": ours shows Value | Name, while 3I literally shows Value | FileID | ZzzKey (see §3).

## STANDARDS.md Updates
None. This review is read only, as instructed. Suggested edits are findings 6–8.
