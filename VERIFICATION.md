# ATB V.3 Windows Build: Verification Report

The ATB V.3 occupant/crash solver (Fortran 95, v5.3.1) has been rebuilt from the original
source with GNU gfortran and delivered as a 32-bit x86 Windows executable, statically linked,
compiled to use the x87 floating point unit (`-m32 -mfpmath=387`) exactly as the original
Compaq Visual Fortran build did. Eight small source edits were required to compile under a
modern toolchain; none of them touch solver logic, and they are listed in `README.md`.
Every one of the 12 client-supplied cases was run through the new executable and every number
in every output file was compared against the outputs the client's original executable
produced. Short runs reproduce the original to the printed digits. Longer runs reproduce the
original exactly for an initial period and then drift apart as last-bit rounding differences
accumulate. Per-case onset times and magnitudes are in the table below. Section 4 explains
why that drift is expected behavior for this class of simulation and not a defect in the port.

## 1. What was verified

32-bit x86 binary, statically linked, verified on Windows Server 2022 (GitHub Actions x86-64); target is Windows 10 22H2.

<!-- RUNNER-INFO -->

### Why the runner OS is not a concern here

The verification ran on Windows Server 2022, not on Windows 10 22H2. For this particular
program that difference does not affect the numbers or the ability to run:

- Same hardware and instruction set. The runner is real x86-64 silicon, not an emulator.
  The arithmetic instructions the solver executes are the same instructions your machine
  executes.
- Same 32-bit subsystem. A 32-bit executable runs under WOW64 on both Windows Server 2022
  and Windows 10 22H2. WOW64 is the same component in both, and it is what determines how a
  32-bit process sees memory and the CPU.
- Almost no operating system surface is used. The solver opens files, reads and writes text,
  and prompts on the console. All of that goes through the C runtime. It calls no graphics,
  no networking, no registry, no Windows-version-specific API. The Compaq QuickWin window
  code, which was the one Windows-specific piece, was removed (edit 1 in `README.md`).
- Statically linked. The executable carries its own Fortran and C runtime. It does not load
  `libgfortran`, `libgcc`, or any other MinGW DLL, so there is no runtime redistributable to
  install and no DLL version to mismatch. The build workflow asserts this: it fails if the
  binary is not a 32-bit PE or if it imports any MinGW runtime DLL.

### What was not verified

- The executable was **not** run on Windows 10 22H2 itself, and not on Technology Associates'
  machines. First-run confirmation on your hardware is the client's step.
- Solver limits, array sizes, and model capabilities are unchanged from the original source.
  Nothing was raised, extended, or tuned.
- No cases beyond the 12 you supplied were exercised. Input features that none of those 12
  cases use have not been tested.

## 2. Results

<!-- TABLE:win32 -->

### Column key

- **Case** is the case directory name. Case 2638 is a restart pair and appears as two rows,
  `2638_Start_135_` and `2638_135_Restart_2a`, run in that order in one directory.
- **Files compared** is how many output files were checked for that case: the `.sa1` animation
  file plus every `.t21` through `.t5x` time-history table. The `.aou` echo file is skipped
  because it records the run date and time, which necessarily differs.
- **Max relative diff** is the largest relative difference found across every number in every
  one of those files. `0` means byte-for-byte identical numbers.
- **Values off by >1e-4** counts how many individual numbers differ by more than 1 part in
  10,000 relative (and by more than 1e-6 absolute). This is a count of numbers, not of rows.
- **First divergence (ms)** is the first row of the `.t21` time history at which any value
  differs by more than 1 part in a million. `none` means the whole run matched at that
  tolerance.
- **Run length (ms)** is the last simulated time in the `.t21` table, so you can read the
  divergence onset as a fraction of the run.
- **Result** summarizes the row: `bit-identical`, `matches to printed precision` (nothing off
  by more than 1e-4), or `rounding drift after onset`.
- **Runtime (s)** is wall-clock solve time on the runner.

### How to read a row

Look at **First divergence** against **Run length**. A row with no divergence, or with
divergence starting near the end of the run, reproduces the original for all practical
purposes. A row where divergence starts early and **Max relative diff** is large is a run that
tracked the original for the first part of the event and then separated. Section 4 covers what
that means for the engineering.

## 3. Why long runs diverge, and why it is not a logic defect

**Every arithmetic operation rounds.** A computer stores a number in a fixed number of bits.
Add two of them and the true answer usually will not fit, so the result is rounded to the
nearest representable value. That rounding error is around 1 part in 10^16 for double
precision. It is unavoidable and it is present in the original executable too.

**Two different compilers round in different places.** The original Compaq compiler kept
intermediate results sitting in x87 registers at 80 bits of precision before storing them back
to memory at 64 bits, and it chose one particular order in which to add up the terms of a sum.
A modern compiler keeps intermediates in different places and orders those sums differently.
Both orders are mathematically correct. Because rounding happens at each step, they give
answers that differ in the last bit or two. That is the entire source of the difference: about
1 part in 10^16, at the very start.

**This kind of simulation amplifies tiny differences.** ATB integrates a body of connected
segments through contacts, joint stops, and friction. Those introduce switches. A body segment
either contacts a surface on a given time step or it does not. A friction force is either
sticking or sliding. A joint either hits its stop or stays inside it. When two runs are
1 part in 10^16 apart, sooner or later one run takes a switch on step N and the other takes it
on step N+1. At that moment the two runs are no longer 1e-16 apart, they are separated by the
size of a small force impulse, and from there the separation grows roughly exponentially. This
is ordinary sensitive dependence on initial conditions, the same property that limits weather
forecasting. It is a property of the physical model, not of the code.

**What rounding drift looks like, and what a logic error looks like.** They have different
signatures, and the results above show the first one:

| Rounding drift | Logic error |
|---|---|
| Identical to every printed digit up to a distinct onset time | Wrong at step 0, or wrong at a specific event |
| After onset, smooth growth over many steps | Sudden jump, or a constant offset |
| Onset time differs between machines and compilers for the same source | Same failure at the same step everywhere |
| Diverged quantities remain physically plausible oscillations | Values go non-physical, NaN, or unbounded immediately |

We also built the same source on macOS/arm64, which uses 64-bit SSE/NEON arithmetic with no
x87 at all. It shows the same pattern with different onset times (appendix). Different onset
on different hardware from identical source is the fingerprint of rounding, because a logic
error would land in the same place on both.

**The original executable has the same property.** Two computers running the original
ATBV3.exe, built with different optimization flags or running on CPUs with different x87
handling, would also disagree in the late portion of a long run for exactly these reasons.
The original build is not a reference answer that the new build approximates. Both are equally
valid samples of a system that is genuinely sensitive at that time scale.

**What this means for your work.** The divergence is real and we are not going to talk it away.
For a long run, do not let an engineering conclusion rest on the last digits, or on the exact
value of an oscillating quantity late in the simulation, from either build. Conclusions should
rest on quantities that are stable across the sensitivity: peak values, event timing at the
resolution the model can actually support, and trends that hold up when you perturb the inputs.
If a conclusion changes between the two builds, that is telling you the conclusion is inside
the model's own noise, and that would have been true with the original executable as well.

## 4. How to re-run the verification

The verification is fully scripted and reproducible. Full details are in `README.md`.

1. The GitHub Actions workflow `.github/workflows/windows-build.yml` builds the 32-bit
   executable on a Windows runner, asserts it is a 32-bit PE with no MinGW runtime DLLs, runs
   all 12 cases, and uploads two artifacts: `atb-win32-exe` (the deliverable) and
   `verification-report-win32` (the table, per-file diffs, divergence growth, runner info,
   binary check, and every output file produced). It is manual trigger only.
2. Locally, `verify/run_all.sh` runs every case into a scratch directory, `verify/cmp.py`
   diffs every number in every output file against the reference set, `verify/grow.py` shows
   when and how each `.t21` history departs, and `verify/report.py` regenerates the table in
   section 2.

Nothing in the comparison is hand-selected. `cmp.py` extracts every numeric token from both
files and compares them positionally, and fails the file if the counts do not even match.

## Appendix A: macOS arm64 comparison build

The same source built for macOS on arm64, which performs all arithmetic in 64-bit SSE/NEON
with no 80-bit extended precision anywhere. This build is not shipped. It is included because
comparing it against the x87 build shows that divergence onset moves with the arithmetic
hardware, which is the evidence that the cause is rounding rather than logic.

<!-- TABLE:arm64 -->

## Appendix B: source edits

Eight edits were made to the original source to build it with gfortran. They are listed
individually in `README.md` under "Source edits (solver logic unchanged)". In summary: four
remove or replace Compaq-specific extensions (QuickWin windowing, `DFPORT`, a `DATA` statement
form, a path separator), two are build-flag equivalents of Compaq defaults (zero-initialized
and static locals), one initializes a variable the original left uninitialized and that Compaq
happened to zero, and one adds a missing `DEALLOCATE` on an early `RETURN` path. No solver
equation, coefficient, integration step, or contact model was modified.
