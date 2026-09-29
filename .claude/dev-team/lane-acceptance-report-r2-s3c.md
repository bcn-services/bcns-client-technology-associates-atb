# Lane Acceptance Report — r2-s3c (2026-09-28, diff tier2-app...r2-s3c, tip b0de0fe; run SHA 71c5c35 differs by docs only)
VERDICT C1 (every §2 screen 1–38 from the menu, one green e2e run, screenshot each): UNMET, moved forward. Run 36503146585 (51/51, filter empty) opens #4 via Analysis > Run Control... (shot "form"), #5 via Output > Control Parameter > General/Diagnostic (shots "general", "diagnostic"), #36 via Output > HIC... (shots "output-menu-enabled", "hic-form"). #4 and #5 run on client deck 2479_2. #36 runs on the synthetic fixture, because 0 of 139 client decks enable HIC. S4 (#29) is still open.
VERDICT C2 (app Run == direct atb-win32 on 2479_2, cross_gate.py): MET in isolation, no regression. The same run logs "2479_2 | 9 | 9 | -", "GATE PASS: 1 case(s) identical modulo volatile.txt". The diff doesn't touch the run path; the Labeler.cs:176 change is equivalent (the `!=0 && !=4` rule moved into OutputControl.EnablesHic). Overall C2 stays unmet until C1's run exists.
VERDICT C3 (setup .exe installs on windows-2022, every scenario passes installed): UNMET, not yet in scope (S5). No regression: the 3 new scenarios run against the published out/app/ATB.exe like the rest.
VERDICT C4 (macOS dotnet test): MET per the engineer report, 1306 passed / 0 failed (+14). Not re-run by me.
VERDICT S3 Run Control #4: MET. Unit round-trip over all cases/+corpus decks (n>=12 guard). Robot RunControlEditSave: bytes unchanged when unedited; after the edit, lines==[4] and tokens==[1] plus a literal A.4 line. btnDefault values match RunControl.cs:1873-1890. The box↔column order matches A1A3A4.
VERDICT S3 Output Control #5: MET. `mdb-export ATB3iData.mdb A5Defination` re-run now is byte-identical to the test literal (36 rows). The test compares the literal to the constant (not self-referential). The General/Diagnostic NPRT lists are literals.
VERDICT S3 HIC #36: MET, with a data-loss divergence (I1 below). The menu rule matches MainMenu.cs:4719-4722 and StdTable.cs:246-262. It is unit-tested on and off, and the robot checks it both ways (NPRT(4)=1 enabled, NPRT(4)=4 disabled). The enabling-deck loop is guarded: it asserts the deck count is >= 2 and that the fixture is in the list.
OPEN POINT `CARD H.12`: REFUTED as a save defect. Our app edits tokens in place and keeps the label. It adds new lines as "CARD H.12.a", and Hic.IsHead reads both labels. Labeler.Label (the 5-token truncation) is called only from tests. What is left is Minor M1.
VACUOUS/EMPTY-SET/SELF-CONSTANT/WHOLE-FILE sweep: clean. Every "every deck" loop has a count guard. The literal-vs-constant tests use real literals. All writes go through Deck.Edit (one token, Raw dropped on that line only); deleting its `token != Tokens[i]` guard would turn the zero-byte tests red. Mutations are recorded for all 3 items (team-memory).

## Critical
none

## Important
- I1 app/Atb.Core/Cards/OutputControl.cs:49-50 — reliability/data loss. In one Output Control dialog, setting NPRT(4) to 4 and then back to 1 deletes the deck's H.12 on the "4" commit and writes 3I's default line on the "1" commit, so the user's Span/Sources are lost silently on OK. 3I applies the rule once, on OK, from the final value (StdTable.cs:246-262), so H.12 survives there. Fix: apply the H.12 add/remove once on OK, comparing the original NPRT(4) to the final one, not on each cell commit.
- I2 LANE.md:9 (criterion 1) — completeness. "#36 ... on the client decks" cannot be met: 0/139 decks enable HIC, and the robot uses fixtures/hic/2479_2_hic.LIN. Fix: Nate amends C1 to accept the synthetic fixture for #36, or supplies a client deck with HIC on.

## Minor
- M1 app/Atb.Core/Lin/Deck.cs:99 — reliability. Any HIC deck that 3I has round-tripped carries "CARD H.12" (FileManager.cs:2245 OneDimArrayOutput writes "CARD "+"H.12"). Validate then reports "no schema entry for this card" on every Save/Run (a warn-only OK/Cancel dialog, a false positive). Fix: add an "H.12" entry to CardSchema (NHIC, Span, repeating triples) or make it an alias of H.12.A.
- M2 app/Atb.Core/Cards/RunControl.cs:487, OutputControl.cs:432 — fault tolerance. A short A.3/A.4/A.5 line throws ArgumentOutOfRangeException, but MainForm.cs:130/141 catch only InvalidOperationException, so the user gets an unhandled-exception dialog. Fix: have Line() throw InvalidOperationException when Count <= the highest token it needs. No client deck hits this.
- M3 LANE.md:206,215,224 — bookkeeping. All 3 S3 statuses still say "not started" at the tip, although all three items shipped (5257158, 43213fc, 71c5c35). Fix: set them to done with the run IDs (36497390376 / 36500200522 / 36503146585).

## STANDARDS.md Updates
none (read-only review per the caller)
