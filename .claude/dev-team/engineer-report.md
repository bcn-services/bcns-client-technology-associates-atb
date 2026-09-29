# Engineer Report
**Task:** General / Diagnostic Output Control Parameters (§2 #5) — A.5 grid of 36 NPRT flags in 3I's two categories, names from `A5Defination`
**Branch:** r2-s3c
**Date:** 2026-09-28

## Design Decisions
- `OutputControl.Definition` holds all 36 `A5Defination` rows (NPRT, name, Value, Category) in NPRT order; `Rows(category)` = 3I's `WHERE Category=n ORDER BY NPRT ASC`.
- Category 1 is 8 rows (1,3,4,18,19,26,30,35), not 7 as the brief said; Category 2 is 18 rows; Category 0 (10 rows, incl. 33 and 36) is on neither form, as in 3I.
- Menu mirrors 3I MainMenu.cs:2770-2781: Output (between Model and Analysis) > Control Parameter > General Parameter... / Diagnostic Parameter...
- Form mirrors StdTable + ATBGrid A5 layout: ClientSize 757x453 then Width 393, columns NPRT (cyan, locked) / Control Parameter (200, cyan, locked) / Value (editable, fills), green bold headers, OK/Cancel bottom-right; modal with a working-copy deck, as RunControlForm.
- NPRT(4) upkeep follows 3I: 0/4 removes H.12.A/B (StdTable.cs:246-262), other value with no H.12 adds 3I's default `1 0.0360000 1 0 0` H.12.a at the deck end (FileManager.cs:2234-2248).

## Files Changed
- `app/Atb.Core/Cards/OutputControl.cs` — A5Defination constant, Rows/Value/Set (Deck.Edit) + NPRT(4) H.12 upkeep.
- `app/Atb.Core.Tests/OutputControlTests.cs` — literal mdb-export rows vs constant, category split, unedited zero-byte round trip over cases/+corpus, one-token edits, non-integer refusal, NPRT(4) H.12 add/remove.
- `app/Atb.App/OutputControlForm.cs` — the StdTable-shaped grid form.
- `app/Atb.App/MainForm.cs` — Output > Control Parameter menu and `OutputControlDialog`.
- `app/Atb.App.UiTests/Scenarios.cs` — `OutputControlEditSave` robot scenario + `OpenOutputControl` helper.
- `STANDARDS.md` — divergence bullet: no add/delete rows, non-integer message, H.12 timing.

## Deferred / Out of Scope
- HIC menu enable/disable on NPRT(4) (3I StdTable.cs:246-252): the app has no HIC menu yet (§2 #36).

## Flags for Reviewer
- The card-tree generic screen "General / Diagnostic Output Control Parameters [A.5]" still exists alongside the new forms (pre-existing).
- H.12 default line is appended at the deck end; H.12 layout has no corpus evidence (no deck has NPRT(4) != 0).
- Atb.App and Atb.App.UiTests do compile on macOS with `-p:EnableWindowsTargeting=true` (contradicts "compile only on Windows").

## Verification
- macOS: `dotnet test app/Atb.sln` 1292 passed / 0 failed (baseline 1283).
- Windows filtered OutputControlEditSave: https://github.com/bcn-services/bcns-client-technology-associates-atb/actions/runs/36499766274 (1/1).
- Windows full: https://github.com/bcn-services/bcns-client-technology-associates-atb/actions/runs/36500200522 (50/50).
- Mutation 1 (NPRT 35 category 1->2 in the constant): DefinitionIsA5DefinationExactly + GeneralAndDiagnostic... red; restored byte-identical.
- Mutation 2 (Set writes token nprt instead of nprt-1): OneFlagEditRewritesOnlyItsToken x4, Nprt4KeepsH12InStep, EveryDeckUneditedSave... red; restored byte-identical.
