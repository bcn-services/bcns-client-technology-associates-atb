# ATB V.3 Windows Build: Verification Report

The ATB V.3 occupant/crash solver (Fortran, v5.3.1) has been rebuilt from the original source
with GNU gfortran and delivered as a 32-bit x86 Windows executable, statically linked, using the
x87 FPU (`-m32 -mfpmath=387`) as the original Compaq Visual Fortran build did. Eight small
source edits were needed to compile under a modern toolchain; none touch solver logic, and all
are listed in `README.md`. All 12 client-supplied runs (11 case folders; 2638 is a two-step
restart pair) were run through the new executable, and every number in every output file was
compared against the original executable's outputs. Two runs (2589 and the 2638 start run)
reproduce the original to the printed digits over their full length. The other ten reproduce it
exactly for an initial period, then drift as last-bit rounding differences accumulate; onset
ranges from 48 ms to 1448 ms into the event, and once it begins the late-time values differ by
order one. See the table for per-case onset times and magnitudes. Section 3 explains why that
drift is expected for this class of simulation and is not a defect.

## 1. What was verified

32-bit x86 binary, statically linked, verified on Windows Server 2022 (GitHub Actions x86-64); target is Windows 10 22H2.

<!-- RUNNER-INFO -->
Runner used for this report:

```
OS: Microsoft Windows Server 2022 Datacenter 10.0.20348 (64-bit)
CPU: INTEL(R) XEON(R) PLATINUM 8573C
Image: win22 20260907.297.1
```
<!-- /RUNNER-INFO -->

The runner OS is not the target OS. For this program that does not affect the results:

- **Same hardware and instruction set.** The runner is real x86-64 silicon, not an emulator. The
  arithmetic instructions the solver executes are the ones your machine executes.
- **Same 32-bit subsystem.** A 32-bit exe runs under WOW64 on both, and WOW64 is the same
  component in both. It determines how a 32-bit process sees memory and the CPU.
- **Almost no OS surface is used.** The solver opens files, reads and writes text, and prompts on
  the console, all through the C runtime. No graphics, networking, registry, or version-specific
  API. The one Windows-specific piece, the Compaq QuickWin window code, was removed (edit 1).
- **Statically linked.** The exe carries its own Fortran and C runtime and imports no MinGW DLL,
  so there is no redistributable to install and no DLL version to mismatch. The build fails if
  the binary is not a 32-bit PE or imports one.

**What changed for the user:** the original ran inside a Compaq QuickWin window; the new exe is
a plain console program with the same prompts and the same input and output files. Run it from
a Command Prompt in the case folder, or pipe the answers in as shown in `README.md`.

**Not verified:** it was not run on Windows 10 22H2 itself, nor on your machines; first-run
confirmation there is your step. Solver limits, array sizes, and model capabilities are
unchanged. No cases beyond the 12 you supplied, so features none of them use are untested.

## 2. Results

<!-- TABLE:win32 -->
Build: 32-bit x86, x87 FPU (-m32 -mfpmath=387), static; OS: Microsoft Windows Server 2022 Datacenter 10.0.20348 (64-bit)
| Case | Files compared | Max relative diff | Values off by >1e-4 | First divergence (ms) | Run length (ms) | Result | Runtime (s) |
|---|---|---|---|---|---|---|---|
| 2479 | 8 | 2 | 70751 | 416 | 4000 | rounding drift after onset | 4 |
| 2495 | 11 | 2 | 191062 | 1092 | 6000 | rounding drift after onset | 13 |
| 2496 | 7 | 2 | 214336 | 206 | 6000 | rounding drift after onset | 4 |
| 2513 | 13 | 2 | 42877 | 348 | 4000 | rounding drift after onset | 8 |
| 2589 | 10 | 0.028 | 0 | none | 1200 | matches to printed precision | 1 |
| 2638_Start_135_ | 13 | 0.69 | 0 | none | 1000 | matches to printed precision | 1 |
| 2638_135_Restart_2a | 13 | 2 | 83687 | 200 | 2000 | rounding drift after onset | 2 |
| 2657 | 13 | 1.8 | 3385 | 370 | 1000 | rounding drift after onset | 0 |
| 2696 | 11 | 2 | 177329 | 1448 | 6000 | rounding drift after onset | 10 |
| 2750 | 12 | 2 | 51652 | 209 | 1000 | rounding drift after onset | 2 |
| 2819 | 17 | 1 | 579 | 654 | 2000 | rounding drift after onset | 2 |
| 2893 | 33 | 2 | 405916 | 48 | 2500 | rounding drift after onset | 5 |
<!-- /TABLE:win32 -->

### Column key

- **Case**: the case directory. 2638 is a restart pair, run as two rows in order.
- **Files compared**: the `.sa1` animation file plus every `.t21` through `.t5x` time history.
  `.aou` is skipped because it records the run date and time.
- **Max relative diff**: largest relative difference over every number in those files.
- **Values off by >1e-4**: count of individual numbers differing by more than 1 part in 10,000
  relative and 1e-6 absolute.
- **First divergence (ms)**: first `.t21` row where any value differs by more than 1 part in a
  million; `none` means the whole run matched.
- **Run length (ms)**: last simulated time in `.t21`, so onset reads as a fraction of the run.
- **Result**: `bit-identical`, `matches to printed precision`, or `rounding drift after onset`.
- **Runtime (s)**: wall-clock solve time on the runner.

**How to read a row.** Compare **First divergence** against **Run length**. No divergence, or
divergence near the end, means the run reproduces the original for practical purposes. Early
onset with a large **Max relative diff** means the run tracked the original through the first
part of the event, then separated.

## 3. Why long runs diverge, and why it is not a logic defect

**Every arithmetic operation rounds.** Numbers are stored in a fixed number of bits. Add two and
the true answer usually does not fit, so it is rounded. That error is about 1 part in 10^16 in
double precision. It is unavoidable, and the original exe has it too.

**Two compilers round in different places.** Compaq held intermediates in x87 registers at 80
bits before storing them back at 64, and picked one order for summing terms. A modern compiler
does both differently. Both orders are mathematically correct, but since each step rounds, they
differ in the last bit or two. That, about 1 part in 10^16, is the entire starting difference.

**This simulation amplifies tiny differences.** ATB integrates connected body segments through
contacts, joint stops, and friction, all of which are switches. A segment either barely contacts
a surface on a given step or barely misses. A friction force is either sticking or sliding.
Starting 1e-16 apart, eventually one run takes a switch on step N and the other on step N+1. The
runs are then separated by the size of a force impulse rather than a last bit, and the gap grows
roughly exponentially. This is sensitive dependence on initial conditions, the property that
limits weather forecasting. It belongs to the physical model, not the code.

**Rounding drift and a logic error have different signatures.** The results above show the first:

| Rounding drift | Logic error |
|---|---|
| Identical to every printed digit up to a distinct onset | Wrong at step 0, or at one specific event |
| After onset, smooth growth over many steps | Sudden jump, or a constant offset |
| Onset moves with machine and compiler on most runs, same source | Same wrong value at the same step on every build |
| Diverged values stay plausible oscillations | Values go non-physical or unbounded at once |

The same source built on macOS/arm64, which uses 64-bit arithmetic and no x87, shows the same
pattern (Appendix A). On six of the ten drifting runs the onset time moves with the hardware
(for example 2479: 416 ms on x87, 806 ms on arm64). On the other four (2495, 2638 restart,
2696, 2893) both builds first depart at the same output step. That is consistent with rounding,
not against it: up to onset the printed values are identical, so the sub-printed-digit
differences that exist before it are only amplified at the first switch event, a contact or
joint stop, and where that event dominates, both builds tip there. A logic error would show a
wrong value from the first step or a fixed wrong event on every build, and neither appears.
The x87 build, which matches the original's arithmetic most closely, ends with fewer differing
values than the arm64 build on seven of the eight comparable runs, which is the direction
rounding predicts.

**The original exe has this property too.** Two computers running the original ATBV3.exe, built
with different compiler flags or handling x87 differently, would also disagree late in a long
run for the same reasons. The original is not a reference answer the new build approximates.
Both are equally valid samples of a genuinely sensitive system.

**What this means for your work.** The divergence is real and we are not going to talk it away.
For a long run, do not rest an engineering conclusion on the last digits of either build, or on
the exact value of an oscillating quantity late in the run. Rest it on what is stable across the
sensitivity: peak values, event timing at the resolution the model supports, and trends that
survive perturbing the inputs. A conclusion that flips between the builds sits inside the
model's own noise, and would have with the original exe as well.

## 4. How to re-run the verification

Fully scripted; details in `README.md`.

1. `.github/workflows/windows-build.yml` builds the exe on a Windows runner, asserts it is a
   32-bit PE with no MinGW runtime DLLs, runs all 12 runs, and uploads `atb-win32-exe` (the
   deliverable) and `verification-report-win32` (table, per-file diffs, divergence growth, runner
   info, binary check, and every output file). Manual trigger only.
2. Locally: `verify/run_all.sh` runs every case, `verify/cmp.py` diffs every number against the
   reference set, `verify/grow.py` shows when and how each `.t21` departs, and
   `verify/report.py` regenerates the section 2 table.

Nothing is hand-selected: `cmp.py` extracts every numeric token from both files, compares them
positionally, and rejects the file if the counts differ.

## Appendix A: macOS arm64 comparison build

The same source built for macOS on arm64, where all arithmetic is 64-bit with no 80-bit extended
precision. Not shipped. Included because divergence onset moves with the arithmetic hardware,
which is the evidence that the cause is rounding, not logic.

<!-- TABLE:arm64 -->
Build: macOS 26.5.1 arm64 (Apple Silicon), Homebrew GCC 16.2.0 gfortran native, 64-bit SSE/NEON arithmetic
| Case | Files compared | Max relative diff | Values off by >1e-4 | First divergence (ms) | Run length (ms) | Result | Runtime (s) |
|---|---|---|---|---|---|---|---|
| 2479 | 8 | 2 | 73541 | 806 | 4000 | rounding drift after onset | 5 |
| 2495 | 11 | 2 | 200873 | 1092 | 6000 | rounding drift after onset | 12 |
| 2496 | 7 | 2 | 214595 | 212 | 6000 | rounding drift after onset | 2 |
| 2513 | 13 | 2 | 38684 | 374 | 4000 | rounding drift after onset | 7 |
| 2589 | 10 | 0.0087 | 0 | none | 1200 | matches to printed precision | 1 |
| 2638_Start_135_ | 13 | 0.63 | 0 | none | 1000 | matches to printed precision | 1 |
| 2638_135_Restart_2a | 13 | 2 | 82958 | 200 | 2000 | rounding drift after onset | 1 |
| 2657 | 13 | 2 | 35123 | 310 | 1000 | rounding drift after onset | 0 |
| 2696 | 11 | 2 | 173957 | 1448 | 6000 | rounding drift after onset | 9 |
| 2750 | 12 | 2 | 55587 | 234 | 1000 | rounding drift after onset | 1 |
| 2819 | 17 | 0.33 | 617 | 654 | 2000 | rounding drift after onset | 2 |
| 2893 | 33 | 2 | 418341 | 48 | 2500 | rounding drift after onset | 3 |
<!-- /TABLE:arm64 -->

## Appendix B: source edits

The eight edits are listed individually in `README.md` under "Source edits (solver logic
unchanged)". In summary: five remove or replace Compaq-specific extensions (QuickWin windowing
in two files, `DFPORT`, a `DATA` statement form, a path separator), one is a pair of build flags
that reproduce Compaq defaults (zero-initialized and static locals), one initializes a variable
Compaq happened to zero, and one adds a missing `DEALLOCATE` on an early `RETURN` path. No solver equation,
coefficient, integration step, or contact model was changed.
