# Review Report
**Date:** 2026-09-12
**Scope:** re-review, diff 0b21248..04ba8ea (GebodMerge.cs, Renumber.cs, GebodForm.cs, MainForm.cs, Atb.Core.csproj, GebodMergeTests.cs)
**Files Reviewed:** 6
**Dimensions Swept:** Efficiency clean; Reliability 2; Scalability clean; Safety & Security clean; Fault Tolerance clean; Data Integrity clean; Over-Engineering clean

## Findings

### Minor
- app/Atb.Core/Cards/GebodMerge.cs:54-58 — Reliability — ReplacedReferences lists only Renumber.References. It leaves out the H.11 "Count becomes 0 while actuators remain" warning that Renumber.Delete adds (H11Emptied), and Merge then deletes with `_ => true`, so a Replace that empties H.11 gives the user no STOP 741 warning before the deck changes. Validate flags it afterward. — Fix: append H11Emptied's site for the lost F.10 positions to the list, or run Validate after the merge and show new errors.
- app/Atb.App/MainForm.cs:494 — Reliability — the re-check compares only the body count, so a same-count grid edit during the run (a Seg JNT change that moves a boundary) is not caught; the confirm re-ask covers only changed references. — Fix: compare the BodyStarts lists, not their counts.

## Prior Important findings
- Replace silently drops references: RESOLVED. The core takes a confirm callback with ReplacedReferences, a decline throws OperationCanceledException and leaves the deck unchanged, the text now says REMOVED, and a test pins literal F.1.b/H.2.a lines. Remap vs remove stays an open human decision, marked ponytail.
- GEBOD.ain lost on merge failure: RESOLVED. OfferSaveAin runs on decline, on a stale placement and on any merge exception.
- Prior Minors (body re-check, Rank test, G = 386.088 with cited src, literal lines): all addressed.

## STANDARDS.md Updates
none (scoped re-review)

C/I/M: 0/0/2
