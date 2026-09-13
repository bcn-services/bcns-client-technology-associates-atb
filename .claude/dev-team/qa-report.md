# QA Report
**Task:** Round 1b — merge GEBOD output into the open deck (re-gate, attempt #2)
**Branch:** r1b-run-overwrite (engineer fix 04ba8ea; QA tests 0b21248, 541425d)
**Date:** 2026-09-12
**Gate mode:** tests

## VERDICT: PASS

## Criteria Checked
- Gate: engineer's 04ba8ea gives 257/257; with the QA additions it is 261/261, and the CS8619 warning is gone — PASS
- Add into 2479_2 (literal lines, counts, Validate) — engineer's test plus the solver run: completed, 32 segments / 31 joints — PASS (joints grow by 15, not 14; that is 3I's NULL joint and a criterion wording gap)
- Insert before 1 shifts every ref; Replace 1 removes then inserts, validates — EveryFamilyRef identity test plus solver runs for before1 (32/31) and replace1 (30/29) — PASS
- File > New + Add passes Validate — engineer's test plus the solver: input accepted (15/14), A.3 G is now 386.088 — PASS
- Build with the placement choice, and Tools > GEBOD merges into the open deck — solution builds; MainForm calls Merge with the confirm callback — PASS (build only)
- Replace decline — ReplaceDecline_… (bodies 1 and 2): throws OperationCanceledException, confirm is asked once, and the input deck is byte-identical after both decline and accept — PASS
- Replace confirm list covers what Delete removes — ReplaceConfirmList_… compares against a separate schema scan of the original deck, and every listed line's original text is gone from the result — PASS. Body 1 has 32 lines, including G.3.a line 302, which is body 2's Ref Segment 1.

## Solver acceptance (local src/atb, macOS)
- All 8 decks complete with STOP 1, like the unmodified 2479_2: add, before1, before2, after1, after2, replace1, replace2, newadd.

## Findings
- [MINOR] New+Add still writes no .sa1. The G fix doesn't help: A.4 NSTEPS is 0 (3I's default), so the run is only a quick input check. This conflicts with the lane's run → view goal: human decision.
- [MINOR] Replace drops refs into the replaced body instead of pointing them at the new body, as 3I does. The engineer marked it with a ponytail comment: human decision.
- [MINOR] The solver was checked on the macOS build only, and the UI on Windows was not clicked through.

## Tests Added
- `app/Atb.Core.Tests/GebodMergeQaTests.cs` — adds the decline and confirm-list tests, and the CS8619 fix.

## Not Verifiable
- none (Windows UI is build-only, which the gate mode allows)
