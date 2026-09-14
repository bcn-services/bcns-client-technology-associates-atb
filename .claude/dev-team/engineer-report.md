# Engineer Report
Branch: r2-gebod-replace
Commit: fc3c82a (feat), report commit follows
Tests: 1156 passed, 0 failed (floor 1151; +5)
Run: https://github.com/bcn-services/bcns-client-technology-associates-atb/actions/runs/34905843854 (success: GebodReplaceBody1Run, InsertSegmentRun, NewGebodSaveRun all Passed)
Date: 2026-09-14
Task: GEBOD Replace follows ATB 3I's by-position rule (GEBOD.cs:1766-1800, ATBUpdate.UpdateDueToBody/UpdateOtherTable)

## Findings
- GebodMerge.Replace: old seg/joint i -> new i via in-place Swap of own lines (B.2.a/b, B.6, G.3.a; B.3-B.5); surplus -> Renumber.Delete (highest first); extra -> Renumber.Insert after kept positions. No renumbering of its own.
- ReplacedReferences(deck, body, newSegments) now lists only refs to surplus positions (own body lines excluded); ponytail note at GebodMerge.cs:51 removed.
- Add / Insert before / Insert after paths are unchanged (all their existing tests pass).
- Confirmation: 3I's Body.cs:1049 text ("Replace Body Using GEBOD", Yes/No, Question), asked once before GEBOD runs (GebodForm.ReplaceText, MainForm.ConfirmReplace).
- FLAG for human: GEBOD's NSEGS (15/17/33) is unknown before the run, so when the new body is shorter a second "GEBOD" Yes/No dialog lists the dropped refs after the run (MainForm.ConfirmDropped); 3I drops them silently. Decline = deck unchanged.
- Divergence (STANDARDS.md): 3I DeleteBody counts a non-last body's joints as a..b, leaving the next body's NULL-joint ref stale; we use a-1..b-1 (body 1: 1..b-1) so joint i maps to i.
- STANDARDS.md had no drop-all line; added "GEBOD Replace is by position" under Body structure plus the divergence line.
- Test 1 (literal lines, 2479_2 body 1 + gebod-50m.ain): ReplaceBody1_KeepsRefsByPosition_AndShiftsLaterOnesByTheDifference; deck validates, B.1 "30 29".
- Test 2 (shorter body): no client deck has a GEBOD-shorter body, so SmallAin(n) cuts gebod-50m.ain to n segments per the .ain schema; ReplaceWithShorterBody_DropsSurplusRefs_AndShiftsLaterOnesDown (body 2, 3 segs, B.1 "5 4") and ReplaceBody1WithShorterBody_MovesTheNextBodyDown (body 1, 1 seg, B.1 "16 15").
- Drop-all tests changed: ReplaceBody1_RemovesItsSegmentsAndJointsThenInserts -> ReplaceBody1_KeepsRefsByPosition_AndShiftsLaterOnesByTheDifference.
- Drop-all tests changed: ReplaceBody1_ConfirmSeesTheRemovedReferences_AndDeclineChangesNothing -> ReplaceWithShorterBody_DropsSurplusRefs_AndShiftsLaterOnesDown.
- Drop-all tests changed: ReplaceDecline_LeavesDeckByteIdentical_AndConfirmIsAskedOnce now uses shorter bodies (1,1),(2,3); ReplaceConfirmList_CoversEveryRefIntoTheReplacedBody -> ReplaceConfirmList_CoversEveryRefToASurplusPosition.
- New QA tests: ReplaceWithLongerOrEqualBody_DoesNotAsk; Replace_EveryFamilyRef_KeepsItsPositionOrMovesByTheDifference(1,2); Merged() adds replace1small/replace2small.
- Mutation (a) drop-all rule: FAIL at GebodMergeTests.cs:164 Assert.Equal expected "1 32 1 63 1 0 1 3 1 -1 0" actual "2 32 16 16 10 0 11 3 12 -2 0" (4 tests fail in total).
- Mutation (b) skip shift (surplus segments removed without Renumber.Delete): FAIL at GebodMergeTests.cs:227 F.1.B Single() for the shifted row "2 18 2 2 ..." (5 tests fail in total).
- Both mutations: cp backup, restored by cp, cmp byte-identical, git status clean.
- Local solver src/atb completes (STOP 1, "ATB Simulation completed!") on replace1, replace2, replace1small, replace2small decks.
- Robot GebodReplaceBody1Run: 11 screenshots viewed; confirm shows 3I text; status goes 17 segments/16 joints -> 30/29; GEBOD LT 24.87 at row 0, old body at row 15; run finished with .aou/.sa1/.t21-.t27.

## Files Changed
- app/Atb.Core/Cards/GebodMerge.cs: by-position Replace, BodyRange, Swap, SegData; ReplacedReferences(body, newSegments).
- app/Atb.App/GebodForm.cs: ReplaceText = 3I Body.cs:1049 text.
- app/Atb.App/MainForm.cs: ConfirmReplace before the run, ConfirmDropped after the run (surplus only).
- app/Atb.Core.Tests/GebodMergeTests.cs: rewritten Replace tests, SmallAin helper.
- app/Atb.Core.Tests/GebodMergeQaTests.cs: Replace QA tests updated to the 3I rule, plus the new ones above.
- app/Atb.App.UiTests/Scenarios.cs: GebodReplaceBody1Run.
- STANDARDS.md: by-position rule and the joint-range divergence.
- Note: engineer-report.md was already deleted in the worktree before this spawn; this file replaces it.
