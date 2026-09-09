# ATB V.3 Windows Build: Verification Report

The ATB V.3 occupant/crash solver (Fortran, v5.3.1) has been rebuilt from the original source
with GNU gfortran and delivered as a 32-bit x86 Windows executable, statically linked, using the
x87 FPU (`-m32 -mfpmath=387`) as the original Compaq Visual Fortran build did. Eight small
source edits were needed to compile under a modern toolchain; none touch solver logic, and all
are listed in `README.md`. All 12 client-supplied cases were run through the new executable, and
every number in every output file was compared against the original executable's outputs. Short
runs reproduce the original to the printed digits. Longer runs reproduce it exactly for an
initial period, then drift as last-bit rounding differences accumulate; see the table for
per-case onset times and magnitudes. Section 3 explains why that drift is expected for this
class of simulation and is not a defect.

## 1. What was verified

32-bit x86 binary, statically linked, verified on Windows Server 2022 (GitHub Actions x86-64); target is Windows 10 22H2.

<!-- RUNNER-INFO -->

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

**Not verified:** it was not run on Windows 10 22H2 itself, nor on your machines; first-run
confirmation there is your step. Solver limits, array sizes, and model capabilities are
unchanged. No cases beyond the 12 you supplied, so features none of them use are untested.

## 2. Results

<!-- TABLE:win32 -->

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
| Onset differs by machine and compiler, same source | Same failure at the same step everywhere |
| Diverged values stay plausible oscillations | Values go non-physical or unbounded at once |

The same source built on macOS/arm64, which uses 64-bit arithmetic and no x87, shows the same
pattern with different onset times (Appendix A). Different onset on different hardware from
identical source is the fingerprint of rounding; a logic error would land in the same place on
both.

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
   32-bit PE with no MinGW runtime DLLs, runs all 12 cases, and uploads `atb-win32-exe` (the
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

## Appendix B: source edits

The eight edits are listed individually in `README.md` under "Source edits (solver logic
unchanged)". In summary: four remove or replace Compaq-specific extensions (QuickWin windowing,
`DFPORT`, a `DATA` statement form, a path separator), two are build-flag equivalents of Compaq
defaults (zero-initialized and static locals), one initializes a variable Compaq happened to
zero, and one adds a missing `DEALLOCATE` on an early `RETURN` path. No solver equation,
coefficient, integration step, or contact model was changed.
