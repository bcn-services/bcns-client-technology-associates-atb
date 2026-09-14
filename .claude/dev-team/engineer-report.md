# Engineer Report (attempt 2, fix pass)
Branch: r2-gebod-replace
Commit: cdd5e1f (fix), plus a comment-and-report commit on top
Tests: 1163 passed, 0 failed (floor 1151, was 1161, +2)
Run: https://github.com/bcn-services/bcns-client-technology-associates-atb/actions/runs/34908386359 (success at cdd5e1f: GebodReplaceBody1Run, InsertSegmentRun, NewGebodSaveRun all Passed)
Date: 2026-09-14
Task: GEBOD Replace follows ATB 3I (fix QA FAIL plus review 0/3/2)

## Fixes
- 1 DONE app/Atb.App/MainForm.cs:494-495: Merge is given `_ => true`; ConfirmDropped and its dead OperationCanceledException catch are deleted. Only ConfirmReplace (3I Body.cs:1049) remains. ReplacedReferences stays in Core. (QA bug, review Important)
- 2 DONE STANDARDS.md:23 is rewritten to cover body 1 of a multi-body deck and `GEBOD.cs:1797`. I checked this against the decompile: Body.cs:1052-1063 sets selJnt=0 for body 1, DeleteBody (Body.cs:1099-1102) takes joints 1..b-1, and the new count NSEGS includes the NULL added at GEBOD.cs:2407. So 3I makes sn+1..so surplus. Later bodies and a single-body deck match 3I. (review Important)
- 2 DONE GebodMerge.cs BodyRange comment: body k's joints are a-1..b-2, body 1's are 1..b-2; the next body's NULL joint b-1 is not one of them.
- 3 DONE Renumber.cs: the new internal CascadedActuators is the list Delete already computed (Delete now calls it), and H11Emptied is now internal. GebodMerge.ReplacedReferences adds the H.11 sites of cascaded actuators and the STOP 741 warning. No dialog. (review Important)
- 3 test: GebodReplaceActuatorTests.SurplusActuators_AreListedWithTheirH11Entries_AndGoneAfterTheMerge. It puts an F.10 on surplus joint 5 and one on surplus segment 10, with H.11 entries. It checks that 2 F.10 sites and 2 H.11 sites are listed and that after the merge F.10 is "2 2 1 1 1 1", D.1.B is 1, H.11 is "1 1", and the deck validates.
- 4 DONE GebodMerge.cs Swap: a missing group (such as G.3.A) now throws InvalidOperationException, because the schema says G.3.A is "one per segment". Before, GEBOD's line was dropped silently. MainForm's catch sends the throw to OfferSaveAin. Test: KeptSegmentWithoutG3A_Throws. (review Minor)
- 5 DONE: a mutation of body 1's joint base to 3I's sn+1..so turns tests red (results below). (review Minor)
- Scenarios.cs:197 comment no longer mentions a "surplus drop list". Comment only, after the green run.

## Mutations (each backed up with cp, restored from the copy, cmp identical, git status clean afterwards)
- M1 ReplacedReferences without actuator H.11 sites: 1 failure, GebodReplaceActuatorTests.cs:36 (H.11 count expected 2, actual 0).
- M2 Swap `continue` on a missing group: 1 failure, GebodReplaceActuatorTests.cs:52 (Assert.Throws, no exception thrown).
- M5 body 1 joint surplus loop shifted to 3I's sn+1..so: GebodReplaceJointQaTests.cs:62 Body1Surplus H.9 (expected "1 2 1", actual "0"). It also broke GebodMergeTests.cs:30 AssertSolverShape (via :229) and GebodMergeQaTests.cs:216, because deleting the next body's NULL joint breaks the body structure.

## Verification
- Local src/atb: replace1, replace1small, replace2, replace2small, jq-b1-16, jq-b1-30, jq-b2-18, jq-b2-32 and jq-b2-5 (ATB_QA_DUMP) all reach "ATB Simulation completed!" STOP 1.
- Windows run 34907818557 (same commit) failed on InsertSegmentRun only. Its Unexpected() caught "ATB run [#32770] Run finished. Open the animation?", so RunDeck missed a late dialog. That path is not in this diff, and the re-run 34908386359 passed. Looks flaky; worth watching.
- GebodReplaceBody1Run screenshots: 04 is 3I's text, title "Replace Body Using GEBOD", Yes/No, ? icon. 05 shows the status going from 17/16 to 30/29 with no second dialog. 11 shows LT 24.87 at row 1, old LT 30.86 at row 16, and "Run finished" with .aou/.sa1/.t21-.t27.

## Files Changed
- app/Atb.App/MainForm.cs: ConfirmDropped removed, Merge gets `_ => true`.
- app/Atb.Core/Cards/Renumber.cs: CascadedActuators extracted, H11Emptied made internal.
- app/Atb.Core/Cards/GebodMerge.cs: ReplacedReferences made complete, Swap throws on a missing group, BodyRange comment fixed.
- app/Atb.Core.Tests/GebodReplaceActuatorTests.cs: new, 2 tests.
- app/Atb.App.UiTests/Scenarios.cs: comment only.
- STANDARDS.md: divergence line rewritten; the by-position line now says there is no dialog.

## Disputed / Deferred
- none. Guardrails hold: Gebodv.exe is untouched, reference shifts go only through Renumber, and the Add/Insert paths are unchanged.
