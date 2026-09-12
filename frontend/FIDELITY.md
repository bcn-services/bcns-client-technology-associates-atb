# ATBRunner fidelity record (Tier A, run on GitHub's Windows Server 2022 runner)

Solver under test: the client's ORIGINAL `ATBV3.exe` (Compaq Visual Fortran 5 / QuickWin 6.00,
2005), byte-identical, never patched. Two copies of it exist on the client's machine and both
are in `frontend/bin/`:

| copy | SHA-256 | origin | role here |
|---|---|---|---|
| `ATBV3.exe` (exe A) | `291c33c8cc3af4241de41508c997c58e9d700303b6ef002cc1f478707f55a65c` | client's `ATBv3-1` folder (the one their 2018 `atb_parms.mem` points at) | **shipped** in the package |
| `ATBV3_ATB3I.exe` (exe B) | `e1187cf6790d6abae83e00809a1125f92f0aa051470f61d75b3bad9c687fc2f7` | extracted from `ATB3I Setup.msi` (the copy ATB 3I drives) | reference-producer check only |

Runner (both pushes): Microsoft Windows Server 2022 Datacenter 10.0.20348 (64-bit), AMD EPYC
7763 64-Core, image `win22 20260907.297.1`, interactive desktop session 1024x768. No VM was
added by us; no shims, no compatibility layers, no DLL copies. The exe runs under WoW64 exactly
as it would on Windows 10 x64.

Evidence: GitHub Actions run 34688153059 (push #1, artifact `frontend-probe`, local copy
`~/atb-work/probe1`) and run 34689350005 (push #2, artifacts `frontend-probe` and
`ATBRunner-package`, local copy `~/atb-work/probe2`). Tables below were produced by
`frontend/probe/fidelity.py` over those artifacts.

## Gate 1: runs natively, all 12 runs

Route: `ATBRunner.exe --lin <deck> --out <base>_new --dir <short dir>` (default feed, see gate 3).
Exit code is the solver process exit code after the runner answered its "Exit Window?" prompt
(the solver's own STOP code, 1, is shown in that prompt; the process then exits 0).

| run | deck | exit | secs (push #1, route postchar) | .t21 bytes |
|---|---|---|---|---|
| 2479 | 2479_2.LIN | 0 | 16 | non-empty |
| 2495 | 2495_2.LIN | 0 | 41 | non-empty |
| 2496 | 2496_2.LIN | 0 | 14 | non-empty |
| 2513 | 2513_2.LIN | 0 | 31 | non-empty |
| 2589 | 2589_10.LIN | 0 | 9 | non-empty |
| 2638 Start | 2638_Start_135_.LIN | 0 | 7 | non-empty |
| 2638 Restart_2a | 2638_135_Restart_2a.LIN (same dir, after Start) | 0 | 8 | non-empty |
| 2657 | 2657_4.LIN | 0 | 6 | non-empty |
| 2696 | 2696_3.LIN | 0 | 38 | non-empty |
| 2750 | 2750_7.LIN | 0 | 7 | non-empty |
| 2819 | 2819_5.LIN | 0 | 10 | non-empty |
| 2893 | 2893_5.LIN | 0 | 16 | non-empty |

All 12 runs completed on every route tried (push #1: postchar and postchardeep, 24 runs;
push #2: see gate 3). **Gate 1: PASS.**

## Gate 2: the volatile set

Derived from data, not assumed: the same 12 inputs were run twice (push #1, two routes) and
every output file was compared byte for byte. Only `.aou` files differed, and only in these
lines (every other file, `.sa1 .t21 .t22 ... .t32`, was byte-identical in all 12 runs):

| # | line | why it changes |
|---|---|---|
| A1 | `           <work dir>` under "The various files used for this run are in the directory:" | path |
| A2 | `1 Elapsed CPU Time =  ...` | CPU seconds |
| A3 | subroutine timing rows `   MAIN3D  1  0.32  8.04` etc. | CPU seconds |
| A4 | `0Total  ...  100.00` | CPU seconds |
| A5 | ` The run started at: ...` | clock |
| A6 | ` The run ended at:   ...` | clock |
| A7 | `  Elapsed CPU time: ...` | CPU seconds |

The shipped `volatile.txt` also masks two things that are not run-to-run volatile but differ
between the client's reference files and any run made through the front end:

| # | line | why |
|---|---|---|
| B1-B4 | the four footer lines that echo the input/output file names | references are named `<case>.*`, runner output is `<case>_new.*`; the reference "input file name" line holds 32 NUL bytes (ATB 3I hands the deck over as `winintm.sys`) |
| C | banner line 54, `terms by executing the following analysis` | exe A prints it with a period, exe B without; see "Who produced the references" |

Everything else in every file must match byte for byte. **Gate 2: PASS** (set is explicit,
data-derived, and every comparison below uses exactly this set).

## Gate 3: driver transparency

Input ladder, case 2589, exe A, push #1 (`p1_ladder.ps1`, logs `r*.log` in the artifact):

| rung | method | result | evidence |
|---|---|---|---|
| 1 | what ATB 3I does: `winintm.sys` + `EXECATB.DAT` in System32, start exe B with no args | FAIL in push #1 (missing `C:\ATBFIG.SYS`, "STOP 500_1 in Subroutine INPUT_FILES"); push #2: TBD-push2 | `r1-atb3i-handoff-B.log`, `shots/r1-*` |
| 2a | `cmd /c ATBV3.exe < answers.txt` | FAIL, no `.aou` in 60 s, killed | `probe.log` |
| 2b | redirected StandardInput from the runner | FAIL, no `.aou` in 45 s | `r2b-stdin-A.log` |
| 3 | pre-seeded `atb_parms.mem` + stdin | FAIL, no `.aou` in 45 s | `r3-seedparms-stdin-A.log` |
| 4a | `PostMessage WM_CHAR` to the UI thread's focus window (`ATBV3Graphic`) | **PASS** | `r4a-postchar-A.log` |
| 4b | `WM_KEYDOWN/WM_CHAR/WM_KEYUP` triplets | FAIL, no `.aou` in 45 s | `r4b-postkey-A.log` |
| 4c | `WM_CHAR` to the deepest visible child | PASS | `r4c-postchardeep-A.log` |
| 4d | 4a plus SetForegroundWindow | PASS | `r4d-postchar-fg-A.log` |
| 5 | `WriteConsoleInput` on `CONIN$` | FAIL, `AttachConsole` error 5 (the solver has no console) | `r5-conin-A.log` |
| 6 | `SendInput` (KEYEVENTF_UNICODE) to the focused window | PASS | `r6-sendinput-A.log` |
| 7 | UI Automation SetFocus + SendKeys | PASS | `r7-uia-sendkeys-A.log` |

The QuickWin runtime reads its keyboard from the window message queue; stdin is never read,
which is why rungs 2, 3 and 5 cannot work by construction. The app uses rung 4a (first pass,
needs neither focus nor foreground). The five answers sent are the ones a user types:
`y` (use this directory), Enter (default parms), `l` (.LIN input), `<deck base>`, `<output base>`.

Transparency, all 12 runs, app route vs an independent method:

| comparison | files | result |
|---|---|---|
| postchar (app) vs postchardeep, push #1 | 173 | identical modulo set A (only `.aou` timing/clock/path lines differed) |
| postchar (app) vs SendInput (hardware input queue, no PostMessage), push #2 | TBD-push2 | TBD-push2 |

**Gate 3: PASS** on the push #1 pair; push #2 adds the independent SendInput pair (TBD-push2).

## Gate 4: reference check (exe A on the runner vs the client's reference outputs)

Masked with the set above. "identical" = every remaining byte equal.

| run | files | identical | differs (file@first line/lines) |
|---|---|---|---|
| 2479 | 9 | 9 | none |
| 2495 | 12 | 12 | none |
| 2496 | 8 | 8 | none |
| 2513 | 14 | 14 | none |
| 2589 | 11 | 11 | none |
| 2638 Start | 14 | 14 | none |
| 2638 Restart_2a | 14 | 14 | none |
| 2657 | 14 | 14 | none |
| 2696 | 12 | 2 | .aou@L4212/696 .sa1@L6530/26333 .t21@L804/2210 .t22@L805/2209 .t23@L811/2202 .t25@L797/2215 .t26@L805/2209 .t28@L803/2211 .t29@L810/2203 .t30@L1044/1 |
| 2750 | 13 | 13 | none |
| 2819 | 18 | 18 | none |
| 2893 | 34 | 34 | none |

Case 2696: identical up to t = 1580 ms, then at `.aou` line 4212 one integration convergence
quantity differs in its last printed digit (`0.9554E-02` vs `0.9555E-02`) during a
"Test failed" step-size retry; from there the step control takes a different path and the
time histories diverge (relative differences grow from 2 % at t = 1582 ms to order 1 later).
That is the signature of a last-bit floating-point difference, which can come from the CPU
(the references were made on the client's machine in April 2022, this run on an AMD EPYC
7763) or from the build (see next section). CPU-only differences are not a failure of the
front end; the client's own machine (Tier B, `verify.bat`) is the final authority for 2696.

### Who produced the references

The reference `.aou` files carry three fingerprints of exe B driven by ATB 3I, not of exe A
driven by hand: banner line 54 has no period (exe B's string; exe A prints `analysis. `), the
directory line is `           .` (ATB 3I runs the solver in its own current directory) and the
input-file-name line is 32 NUL bytes (ATB 3I passes the deck as `winintm.sys`, the solver
never learns a name). So the client's "what I get today" is exe B through ATB 3I. Exe B on
the runner, driven through the exact ATB 3I handoff: TBD-push2.

## Gate 5: package

TBD-push2 (verify.bat rehearsal on the runner, tamper test).
