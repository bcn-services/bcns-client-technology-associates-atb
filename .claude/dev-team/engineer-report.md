# Engineer Report
**Task:** Segment and joint insert/delete warning, as ATB 3I
**Branch:** r2-gebod-replace
**Date:** 2026-09-14

- Branch: r2-gebod-replace; feat commit f18eea3 (checkpoint commit follows)
- Tests: 1176 -> 1180 passed, 0 failed (`dotnet test app/Atb.sln`)
- Windows run: https://github.com/bcn-services/bcns-client-technology-associates-atb/actions/runs/34910052325 — FAILURE, job never started: "recent account payments have failed or your spending limit needs to be increased" (GitHub billing). BLOCKED on Nate fixing billing; robot gate and screenshots NOT verified
- Mutation (b): `these segments.  Continue` -> one space => only `CascadeWarningTests.Texts_AreAtb3IStrings` red (Strings differ); restored, cmp clean
- Mutation (a): `CascadeConfirmed` ignores the answer (`ask(...) | true`) => only `CascadeWarningTests.No_IsNotConfirmed` red (Assert.False); restored, cmp clean. First try `|| true` also reddened the Asks test (skipped ask), so it was redone isolated
- Screenshots checked: none (the run never started)

## Design Decisions
- 3I texts/titles are `Renumber` constants; `Renumber.CascadeConfirmed(e, detail, ask)` is the pure No-path seam: asks only for Segment/Joint, detail goes below 3I's text after a blank line
- Delete of segment/joint: one dialog per action (3I asks once per grid update): 3I text + `RefText` for every selected row that has references; after Yes the per-row `Delete` confirm is `true`
- The reference list keeps today's heading+list ("Segment 3 is still referenced by N line(s):"); today's "Delete it anyway? ..." question is dropped from the combined dialog, since 3I's "Continue?" is the question
- Plane/vehicle/actuator keep today's `ConfirmDelete`; GEBOD Replace/merge does not go through `CascadeConfirmed` (grid Add/Delete/Paste only)
- `Renumber.DeleteRefs` factored out of `Delete` (References + H.11 warning) so the dialog can list references before deleting

## Files Changed
- `app/Atb.Core/Cards/Renumber.cs` — 3I constants, `CascadeConfirmed`, `DeleteRefs`
- `app/Atb.App/MainForm.cs` — warning in `AddRow`, `DeleteRows`, `PasteRows`; `RefText`, `AskYesNo` (YesNo, Question, Button1 as 3I)
- `app/Atb.Core.Tests/CascadeWarningTests.cs` — literal 3I text, No path, ask routing, segment insert on 2479_2 leaves joints alone and `Validate()` clean
- `app/Atb.App.UiTests/Robot.cs` — `Answer(title, button)` helper
- `app/Atb.App.UiTests/Scenarios.cs` — new `InsertSegmentWarning` (No -> save byte-identical, Yes -> grid grows); `InsertSegmentRun` answers Yes to both warnings

## Deferred / Out of Scope
- Robot gate: re-dispatch once billing is fixed: `GITHUB_TOKEN= gh workflow run app-e2e.yml --ref r2-gebod-replace -f filter='FullyQualifiedName~InsertSegmentWarning|FullyQualifiedName~InsertSegmentRun|FullyQualifiedName~GebodReplaceBody1Run'`
- `Deck.Validate()` untouched; no joint-count rule added

## Flags for Reviewer
- Robot `InsertSegmentWarning` checks "no new row after No" via `Main.FindFirstDescendant(ByName("Weight Row {segs}"))` being null; this is unverified on Windows
- A multi-row delete lists the references of each row as computed on the deck before any row is deleted
