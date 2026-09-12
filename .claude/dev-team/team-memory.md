# Dev-team memory log

## 2026-09-12 — dev-team-auto — Card schema for every .LIN card
- **Outcome:** DONE — 1 attempt — caution: no — team: dt-analyze sonnet/high, dt-engineer opus/high — lane-card-schema
- **What happened:** CardSchema now has names/kinds/appearance rule for all 48 deck labels plus solver/.mdb-only cards; Deck.Validate() returns (line, label, reason). 56 -> 90 tests. Orchestrator mutation-checked fixed-count check, variable-rule check, and a removed entry; all went red.
- **What worked:** ATB 3I column titles live in `~/atb-work/p0/msi/General Dynamics/ATB3I/ATB3iData.mdb` (mdbtools reads it); the solver's read order, not .mdb column order, is token order (e.g. F.1.B Edge Test before Output).
- **What failed:** dt-analyze reported no .mdb exists — wrong; the engineer found it. Seed D.5 was missing EllipID (13 tokens, not 12); seed D.2 key matched no deck label (decks use D.2.A-D).
- **Remember next run:** build baseline is 27 nullable warnings in Atb.App/Solver (SolverRun.cs, Win32.cs), not 0. Only ONE H.1.a-mislabelled empty H.3 row exists (2479_2.LIN:321), not three — the labeler item's done-when says three. Validate() is per-line only; cross-card totals (D.7 vs segment count) unchecked. B.1 field 4 is Flexible Bodies (solver), not Symmetry.

## 2026-09-12 14:50 — dev-team-auto — Deck labeler for unlabelled or mislabelled decks
- **Outcome:** DONE — 1 attempt — caution: no — team: dt-engineer opus/high — lane-card-schema, 0a1763c
- **What happened:** New `Atb.Core/Lin/Labeler.cs` walks ATB 3I FileManager.ReadFile order/counts, labels blanks and non-schema labels, fixes the empty-H.2/H.3-as-H.1.a bug. 90 -> 114 tests. Orchestrator mutation-checked skip-labelled guard, F.3.B count, last-card error text, H-bug condition; all four went red on their own test.
- **What worked:** asserting the grammar agrees with every existing client-deck label (proves no desync); swapping only the label text inside Raw keeps relabelled lines byte-identical elsewhere.
- **What failed:** none. Done-when says three H.1.a-mislabelled rows; only one exists (2479_2.LIN:321). H.1 continuation rows labelled H.1.a are ATB 3I's normal layout, not the bug.
- **Remember next run:** F.8.B is written unlabelled by ATB 3I (treated as a data row). SetLabel drops tokens past the card's count (ejection.lin H.10.c 12 -> 10 values) — ATB's reader ignores them. D.3/D.4 belts/airbags and F.9 water throw as unsupported; B.3.C, D.6 Type 5 second line, H.12 multi-HIC layouts are unverified guesses (ponytail comments).
