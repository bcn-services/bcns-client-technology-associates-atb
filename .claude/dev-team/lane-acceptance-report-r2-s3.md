# Lane Acceptance Report — r2-s3
**Date:** 2026-09-15 · **Diff:** tier2-app...r2-s3 · **Item in scope:** S2 parity fixes (BLOCKED, 1hr time stop)

## Objective "Lane done when:" (4 criteria)

1. **Green app-e2e.yml opening every §2 screen 1-38 with screenshots** — UNMET. This diff only touches S2 items (Vehicle Motion, function editors); S3 (Run Control, Output Control, HIC/CSI) not started, S4/S5 not begun per LANE_PROGRESS. No single run covers all 38 screens.
2. **cross_gate.py parity on 2479_2.LIN** — UNMET. Not exercised in this diff; no evidence of a cross_gate run in engineer/QA reports.
3. **Setup .exe installs on windows-2022 + all robot scenarios pass** — UNMET. Installer item not started this round; no installer-run evidence.
4. **`dotnet test app/Atb.sln` passes on macOS** — PARTLY MET. Mac gate 1276 passed/0 failed (Atb.Core.Tests only; Atb.App/UiTests don't compile on Mac by design, per LANE.md's own note that agents can't run the app locally — consistent, not a gap). Full-solution macOS pass for App/UiTests is inherently unverifiable per LANE.md, so this criterion is met as far as it can be on this platform.

## S2 parity fixes item — 5 "done when" criteria

1. **First wind/joint function defaults + validates deck** — MET. `S2ParityTests.FirstWindAndJointFunctionCreateTheirSectionsAndTerminator`, green in Mac gate (1276 passed); mutation-checked (engineer report: terminator-drop mutation → red).
2. **Vehicle insert/copy/delete/replace via Renumber, primary refusal, row-count rewrite, mutation checks recorded** — PARTLY MET. Tests green (`VehicleDeleteRefusesThePrimaryAndRenumsOtherwise`, `SplineRowAddAndDeleteRewriteC2bToken2`, etc.) and 4 of 5 mutation checks are logged in engineer-report.md. But review-report.md (Important, Vehicles.cs:~130) found a real parity gap the tests don't cover: inserted-vehicle SegID uses NSEG+n instead of copying the selected vehicle's SegID when that SegID ≤ NSEG (2480_4/5 case) — unresolved, "Nate decides." Also QA and engineer did not re-run the mutation suite this session (QA report: "mutations not re-run by QA, time"); test-13-SegID post-step mutation not checked (per your known facts).
3. **FDF two-series from CurvePoints + FormatError constants** — MET for unit level: `FdfOtherSeriesComesFromCurvePointsAndIsAbsentWithoutData` green + mutation-checked (guard-removal → red). Robot-level not yet confirmed (see #4).
4. **Robot scenario screenshotting all required steps, green app-e2e.yml** — UNMET. Windows run 35021573881 is green 13/13 but predates fix pass 1e259fb; QA report explicitly flags: no two-series FDF screenshot, no Copy Vehicle screenshot, wind SegID dropdown shown closed only. These are QA-confirmed bugs against this done-when's literal screenshot list, not yet re-run on Windows.
5. **Existing passing tests remain passing** — MET on Mac (1276 vs prior 1272, 0 failed). Not confirmed on Windows post-fix (UiTests unverified per engineer report).

## Guardrails
No breach found: `git diff tier2-app...r2-s3 --stat -- src/ verify/ cases/` is empty; Atb.Core.csproj unchanged, still no UI/DB package refs; no new NuGet packages added anywhere in the diff; Scenarios.cs diff is additions-only (no removed Assert lines), matching review-report's "additions only, no existing assertion loosened."

## Verdict
Lane objective: UNMET (3 of 4 criteria unmet, 1 partly). S2 parity fixes item: 2 MET / 2 PARTLY MET / 1 UNMET — correctly left "not started"/BLOCKED status; do not mark done. No guardrail breach.
