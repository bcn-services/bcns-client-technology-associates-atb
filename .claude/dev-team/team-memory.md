# Dev-team memory log

## 2026-09-12 — dev-team-auto — Card schema for every .LIN card
- **Outcome:** DONE — 1 attempt — caution: no — team: dt-analyze sonnet/high, dt-engineer opus/high — lane-card-schema
- **What happened:** CardSchema now has names/kinds/appearance rule for all 48 deck labels plus solver/.mdb-only cards; Deck.Validate() returns (line, label, reason). 56 -> 90 tests. Orchestrator mutation-checked fixed-count check, variable-rule check, and a removed entry; all went red.
- **What worked:** ATB 3I column titles live in `~/atb-work/p0/msi/General Dynamics/ATB3I/ATB3iData.mdb` (mdbtools reads it); the solver's read order, not .mdb column order, is token order (e.g. F.1.B Edge Test before Output).
- **What failed:** dt-analyze reported no .mdb exists — wrong; the engineer found it. Seed D.5 was missing EllipID (13 tokens, not 12); seed D.2 key matched no deck label (decks use D.2.A-D).
- **Remember next run:** build baseline is 27 nullable warnings in Atb.App/Solver (SolverRun.cs, Win32.cs), not 0. Only ONE H.1.a-mislabelled empty H.3 row exists (2479_2.LIN:321), not three — the labeler item's done-when says three. Validate() is per-line only; cross-card totals (D.7 vs segment count) unchecked. B.1 field 4 is Flexible Bodies (solver), not Symmetry.
