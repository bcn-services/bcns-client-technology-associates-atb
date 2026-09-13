# Engineer Report — fix pass (attempt #2)
Branch: r1b-run-overwrite
Commit: 04ba8ea (on top of QA 0b21248)
Tests: 257 passed, 0 failed (full gate). Build has 0 errors. The one warning outside SolverRun.cs/Win32.cs is CS8619 at GebodMergeQaTests.cs:81, from QA's commit.
**Date:** 2026-09-12

## Changes Made
- Replace confirm (review Important 1), in GebodMerge.cs:
  - Merge now requires `Func<IReadOnlyList<RefSite>, bool> confirm`.
  - For Replace, the new `ReplacedReferences(deck, body)` gathers `Renumber.References` for every segment and joint in the body, leaving out the body's own lines (`Renumber.Owned`, now internal).
  - `confirm` is called once. Declining throws OperationCanceledException and leaves the deck unchanged.
- Replace UI (review Important 1):
  - `GebodForm.ReplaceText` now says references are REMOVED, not moved to the new body.
  - MainForm's `ConfirmReplace` lists the lines before GEBOD runs, sharing `RefList` with ConfirmDelete (25 lines shown, then "... and N more").
  - At merge time it asks again only if the list changed during the run.
- Retargeting references onto the new body is not done. 3I remaps them, and that is an open human decision, marked ponytail at GebodMerge.cs `ReplacedReferences`.
- Merge failure (review Important 2), in MainForm.cs Gebod: the GEBOD.ain text stays in memory. A failed, declined or out-of-date merge calls `OfferSaveAin`, a Save As prompt for the .ain.
- Stale placement (review Minor), in MainForm.cs Gebod: the body count is checked again just before merging. If it changed, a clear message goes through `OfferSaveAin` and the deck is left unchanged.
- Order coverage (review Minor): new test `EveryCardInTheSchema_HasAGrammarRank` checks that every `CardSchema.Cards` key has `Renumber.Rank >= 0`.
  - `Rank` is now internal, and Atb.Core.csproj adds `InternalsVisibleTo Atb.Core.Tests`.
- A.3 G (review Minor), GebodMerge.cs NewDeck: the solver divides by G (Inrtia.for:122, Print.for:122, output_body_prop.for:57), so a New deck now writes G = 386.088, matching 2479.
- Literal lines (review Minor), GebodMergeTests.cs:
  - InsertBefore-1 asserts F.1.b `1 34 16 65 1 0 1 3 1 -1 0` and H.2.a `2 34 18 0 0 0 0`.
  - Replace-1 asserts F.1.b `2 32 16 16 10 0 11 3 12 -2 0`, that the F.1.b rows on segments 1-2 are gone, and H.2.a `2 32 16 0 0 0 0`.
  - These were worked out from the 2479 source lines, not taken from the output.
- New test `ReplaceBody1_ConfirmSeesTheRemovedReferences_AndDeclineChangesNothing`:
  - Decline leaves the deck unchanged.
  - The callback gets `ReplacedReferences`, which include line 209 Contact Segment and the line 325 H.6, and no B-card lines.
  - Accept gives B.1 30/29.
- All 20 existing test calls to Merge (9 in GebodMergeTests.cs, 11 in GebodMergeQaTests.cs) now pass `_ => true`.

## Disputed
- None.

## Deferred
- Retargeting the replaced body's references onto the new body (3I's behaviour). This is an open human decision.
- File > New's 0 time steps, left as is on instruction (it matches 3I).
- Uncommitted STANDARDS.md edits in the worktree are not mine and were left out of the commit.
