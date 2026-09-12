# ATBRunner fidelity record (Tier A, run on GitHub's Windows Server 2022 runner)

Solver under test: the client's ORIGINAL `ATBV3.exe` (Compaq Visual Fortran 5 / QuickWin 6.00,
2005), byte-identical, never patched. Two copies of it exist on the client's machine and both
are in `frontend/bin/`:

| copy | SHA-256 | origin | role here |
|---|---|---|---|
| `ATBV3.exe` (exe A) | `291c33c8cc3af4241de41508c997c58e9d700303b6ef002cc1f478707f55a65c` | client's `ATBv3-1` folder (the one their 2018 `atb_parms.mem` points at) | **shipped** in the package |
| `ATBV3_ATB3I.exe` (exe B) | `e1187cf6790d6abae83e00809a1125f92f0aa051470f61d75b3bad9c687fc2f7` | extracted from `ATB3I Setup.msi` (the copy ATB 3I drives) | reference-producer check only |

Runners: GitHub `windows-2022`, Microsoft Windows Server 2022 Datacenter 10.0.20348 (64-bit),
image `win22 20260907.297.1`, interactive desktop session 1024x768. The pool mixes CPUs and
that turned out to matter (gate 4):

| push | run | CPU |
|---|---|---|
| #1 | 34688153059 | AMD EPYC 7763 64-Core |
| #2 | 34689350005 | Intel Xeon Platinum 8573C |
| #3 | 34690000856 | AMD EPYC 7763 64-Core (a different VM from push #1) |

No VM was added by us; no shims, no compatibility layers, no DLL copies, no registry changes.
The exe runs under WoW64 exactly as it would on Windows 10 x64.

Evidence: the `frontend-probe` artifact of each run (local copies `~/atb-work/probe1`,
`probe2`, `probe3`; push #2 and #3 also upload `ATBRunner-package`). Tables below were
produced by `frontend/probe/fidelity.py` over those artifacts.

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

All 12 runs completed on every route and every exe tried:

| push | exe | route | runs | exit codes | secs |
|---|---|---|---|---|---|
| #1 | A | postchar (app route) | 12 | all 0 | 6-41 |
| #1 | A | postchardeep | 12 | all 0 | 6-41 |
| #2 | B | ATB 3I handoff (no prompts) | 12 | all 0 | 4-39 |
| #2 | A | SendInput | 12 | all 0 | 7-44 |
| #3 | A | postchar via `verify.bat` (the shipped package, as the client runs it) | 12 | all 0 ("0 FAILED TO RUN") | 210 for all 12 |
| #3 | B | ATB 3I handoff | 12 | all 0 | 4-43 |
| #3 | A | SendInput | 12 | all 0 | 7-41 |

**Gate 1: PASS.**

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
| 1 | what ATB 3I does: `C:\ATBFIG.SYS` (installer), `winintm.sys` + `EXECATB.DAT` in System32, start exe B with no args | push #1 FAIL (we had not yet written `C:\ATBFIG.SYS`: "Error opening ATBFIG.SYS file. STOP 500_1 in Subroutine INPUT_FILES"); push #2 **PASS** for exe B once the runner writes the installer's `C:\ATBFIG.SYS` (also passes with the handoff files in the work dir, and on a repeat) | push #1 `r1-atb3i-handoff-B.log` + `shots/r1-*/04-dialog.png`; push #2 `r1a-handoff-sys32-B.log`, `r1b-*`, `r1-dup-B.log` |
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
which is why rungs 2, 3 and 5 cannot work by construction. Rung 1 only exists for exe B (exe A
has no `ATBFIG.SYS` code path; it prompts). The app uses rung 4a (first pass, needs neither
focus nor foreground). Exe B driven by 4a in push #1 failed for the same missing-`ATBFIG.SYS`
reason as rung 1 (exit 0, no outputs), not because of the input route. The five answers sent are the ones a user types:
`y` (use this directory), Enter (default parms), `l` (.LIN input), `<deck base>`, `<output base>`.

Transparency, all 12 runs, app route vs an independent method:

| comparison (same machine, same push) | files | result |
|---|---|---|
| A postchar (app) vs A postchardeep, push #1 | 173 | identical modulo set A (only `.aou` timing/clock/path lines differed; 161 files byte-identical) |
| A SendInput vs B ATB 3I handoff (no prompts at all), push #2 | 173 | identical modulo set A |
| A postchar via `verify.bat` (app) vs A SendInput, push #3 | 173 | identical modulo set A |
| A postchar via `verify.bat` (app) vs B ATB 3I handoff, push #3 | 173 | identical modulo set A |
| A postchar, push #1 vs A SendInput, push #3 (two different VMs, same CPU model) | 173 | identical modulo set A |

The push #2 pair is the strongest: the prompt-free ATB 3I mechanism (what the client uses
today) and a keyboard-driven run of the other exe agree byte for byte outside set A.
**Gate 3: PASS.**

## Gate 4: reference check vs the client's reference outputs

Masked with the set above. "identical" = every remaining byte equal. Runner CPU is the
decisive variable, so the table is per CPU.

### On the AMD EPYC 7763 (push #1, exe A, app route)

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

### On the Intel Xeon Platinum 8573C (push #2; exe A via SendInput and exe B via the ATB 3I handoff give the same table)

| run | files | identical | differs (file@first line/lines) |
|---|---|---|---|
| 2479 | 9 | 0 | .aou@L1954/2471 .sa1@L1527/11356 .t21@L487/689 .t22@L500/1485 .t23@L516/1337 .t24@L571/270 .t25@L483/1502 .t26@L527/1192 .t27@L541/1404 |
| 2495 | 12 | 2 | .aou@L3962/1513 .sa1@L6619/33510 .t21@L558/2420 .t22@L565/2435 .t23@L565/2427 .t25@L562/2452 .t26@L593/2377 .t28@L565/2441 .t29@L564/2443 .t30@L695/455 |
| 2496 | 8 | 0 | .aou@L2265/17 .sa1@L13640/8172 .t21@L1893/489 .t22@L1820/606 .t23@L1992/837 .t24@L1839/517 .t25@L1931/414 .t26@L1926/532 |
| 2513 | 14 | 0 | .aou@L3254/77 .sa1@L19864/4653 .t21@L1674/94 .t22@L1607/49 .t23@L1691/259 .t24@L1722/125 .t25@L1715/40 .t26@L1682/90 .t27@L1897/3 .t28@L1762/27 .t29@L1921/6 .t30@L1567/232 .t31@L1605/261 .t32@L1714/10 |
| 2589 | 11 | 11 | none |
| 2638 Start | 14 | 14 | none |
| 2638 Restart_2a | 14 | 13 | .sa1@L6450/248 |
| 2657 | 14 | 14 | none |
| 2696 | 12 | 12 | none |
| 2750 | 13 | 13 | none |
| 2819 | 18 | 18 | none |
| 2893 | 34 | 1 | .aou@L2879/723 .sa1@L3372/19470 .t21@L299/2212 ... .t51@L305/104 (33 files) |

### On the AMD EPYC 7763 again (push #3, a different VM; exe A via the shipped `verify.bat`, exe A via SendInput and exe B via the handoff all give the same table)

Identical to the push #1 table line for line: 11 runs identical, 2696 differs at exactly the
same first lines (.aou@L4212/696 .sa1@L6530/26333 .t21@L804/2210 ... .t30@L1044/1).
`verify.bat` itself printed `11 IDENTICAL, 1 DIFFERS, 0 FAILED TO RUN`, with 2696 the one
DIFFERS. Same CPU model on two different VMs, three routes and two exes: the same bytes.

### Reading the two tables

* Every case that differs from the references on one CPU is identical on the other, and the
  same exe fed the same deck gives different late-time trajectories on the two CPUs. Exe A
  vs exe B on the same CPU: identical. Input route (PostMessage, SendInput, ATB 3I handoff)
  on the same CPU: identical. So the differences are a property of the CPU the 2005 x87
  floating-point code runs on, not of the build and not of the front end.
* Shape of a difference, case 2696 on the EPYC: identical up to t = 1580 ms, then at `.aou`
  line 4212 one integration convergence quantity differs in its last printed digit
  (`0.9554E-02` vs `0.9555E-02`) inside a "Test failed" step-size retry; the step control
  then takes a different path and the contact-phase histories diverge (relative differences
  grow from 2 % at t = 1582 ms to order 1 later). Case 2893 on the Xeon diverges the same way
  from line 2879. These are last-bit rounding effects amplified by the solver's adaptive step
  control during contact, the classic signature of running x87 code on a different CPU.
* The references were made on the client's machine in April 2022. Neither runner CPU
  reproduces all 12; each reproduces the cases the other does not. The spec anticipates this:
  CPU-only differences are not a failure of the front end, and the client's own machine,
  running `verify.bat` (Tier B), is the final authority. On that machine, if it is the 2022
  machine, all 12 should print IDENTICAL; on a different CPU some cases may print DIFFERS for
  the reason above, and the runner logs plus the `verify` work folder show which lines.

### Who produced the references

The reference `.aou` files carry three fingerprints of exe B driven by ATB 3I, not of exe A
driven by hand: banner line 54 has no period (exe B's string; exe A prints `analysis. `), the
directory line is `           .` (ATB 3I runs the solver in its own current directory) and the
input-file-name line is 32 NUL bytes (ATB 3I passes the deck as `winintm.sys`, the solver
never learns a name). Exe B on the runner through the exact ATB 3I handoff (push #2) writes
all three fingerprints byte for byte, and its numbers equal exe A's on the same CPU. So the
client's "what I get today" is exe B through ATB 3I, and exe A gives the same numbers; the
package ships exe A as specified (the client's `ATBv3-1` copy) with the one banner line
masked.

## Gate 5: package

Push #2 rehearsal found a packaging bug (the case list was flattened; only 2638 ran) and
fixed it; the tamper test passed there: a copy of `ATBV3.exe` with its last byte flipped
was refused with exit code 3 and no run started (`probe.log`, "tamper test").

Push #3, the shipped package (`ATBRunner-package` artifact of run 34690000856; `ATBRunner.exe`
SHA-256 `6f04456d3147e0cd94af7d3a19357e3670c0761a712274dbc538e4c49b09a194`, `ATBV3.exe` SHA-256
`291c33c8...a65c` = the client's original, checked by the workflow before the build and by
`ATBRunner.exe` at every start):

| check | result |
|---|---|
| package contents | `ATBRunner.exe ATBV3.exe README.txt verify.bat volatile.txt cases\<11 dirs>\*.LIN cases\cases.txt (12 runs) cases\reference-hashes.txt (173 files)` |
| `verify.bat` run from the package folder, no arguments, on the runner | `===== RESULT: 11 IDENTICAL, 1 DIFFERS, 0 FAILED TO RUN  (of 12 runs)`; 2696 DIFFERS (the EPYC pattern of gate 4), exit code 1; results appended to `verify-results.txt` |
| the same 12 outputs re-diffed offline against the references with `fidelity.py` | same answer: 11 identical, 2696 differs at .aou L4212 |
| hash tamper | last byte of a copy of `ATBV3.exe` flipped: `ATBRunner.exe` exits 3, no solver started (push #2 and #3) |
| GUI | not exercisable on a headless runner; same `SolverRun` code path as batch mode (`Program.cs` and `MainForm.cs` both call `SolverRun.Run`) |

Hash rule used by `--strip-hash` and by `reference-hashes.txt` (`Strip.cs`): every line matching a
`volatile.txt` regex is replaced by `<VOLATILE>`, every line (including the last) is terminated
by a single `\n`, and the SHA-256 of that text is taken. Joining lines with `\n` without the
final terminator reproduces 0 of 173 hashes; with it 173 of 173 (P3 verifier, item 4).

**Gate 5: PASS** (the package runs the 12 reference cases end to end and reports per case
against shipped hashes with the volatile lines stripped; the one DIFFERS is the CPU effect
documented in gate 4, not a packaging or driver fault).
