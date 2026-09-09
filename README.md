# ATB V.3 solver — gfortran port and Windows build

Technology Associates' ATB V.3 crash-simulation solver (Fortran, v5.3.1, originally
built with Compaq Visual Fortran) rebuilt with GNU gfortran. The deliverable is a
32-bit, statically linked Windows executable built and verified on GitHub Actions.

- `VERIFICATION.md` — the verification report (per-case results, what was and wasn't checked)
- `src/` — solver source, original ATBv3-1/ATBSourceCode with the 8 edits listed below
- `build.sh` — the build; `TARGET=win32` for the Windows deliverable
- `cases/` — the client's 12 example cases with the reference outputs from the original exe
- `verify/` — runs every case and diffs every number against the reference outputs
- `.github/workflows/windows-build.yml` — builds the exe on a Windows runner and runs the verification
- `example/` — Sled.ain from the 1.3 distribution, run through the macOS build

## Source edits (solver logic unchanged)

1. `Main_atb.for` — removed Compaq QuickWin window calls (USE DFLIB, SETWSIZEQQ, DELETEMENUQQ, SETMESSAGEQQ)
2. `frame_window.for` — deleted (QuickWin-only, unused)
3. `input_files.for` — dropped `USE DFPORT` (GETCWD/STAT are gfortran intrinsics); STAT array 12→13
4. `Output.for`, `update_euler_joints.for` — DATA statements used named constants (`-I_1`); replaced with literals
5. `FNAME.FOR` — path separator `\` → `/` (the Windows C runtime accepts `/`, so this holds on both OSes)
6. `input_initial_conditions.for` — `J1` uninitialized in the .lin path; set to 0 (Compaq zeroed it by luck)
7. Build flags `-finit-local-zero -fno-automatic` — Compaq zero-initialized locals and kept them static; many routines rely on it. Without these every case is singular/NaN at step 0.
8. `VSPLIN.FOR` — the early `RETURN` for velocity/acceleration vehicle input skipped the routine's `DEALLOCATE`. Harmless under Compaq (unsaved allocatables are freed on return) but with `-fno-automatic` the arrays persist, so the second vehicle in a run failed with "Attempting to allocate already allocated variable". Only case 2638 has two vehicles. Added the `DEALLOCATE` before that `RETURN`; no numeric change.

No edit was needed specifically for the Windows target.

## Build

    cd src && bash ../build.sh                 # native (macOS/Linux), output src/atb
    cd src && TARGET=win32 bash ../build.sh    # Windows deliverable: 32-bit, x87 FPU, static -> atb-win32.exe

Flags: `-ffixed-form -ffixed-line-length-72 -std=legacy -fno-range-check -O2 -finit-local-zero -fno-automatic`,
plus `-m32 -mfpmath=387` and `-static` for `win32`. 72 columns is mandatory: `TRNPOS.FOR` has text past
column 72 that 132-column mode would compile. `-ffp-contract=off` was tried and does not change the
late-run divergence, so `-O2` stays.

Windows toolchain: MSYS2 `mingw-w64-i686-gcc-fortran` (see the workflow).

## Run

Same interactive prompts as ATBV3.exe, feedable via stdin:

    printf 'y\n\nl\n2479_2\n2479_2_new\n' | ./atb-win32.exe

(accept terms / working directory default / L = .lin input / input name / output name.)
The solver stores the working directory in an 80-character string, so run from a short path.
A normal run ends with `STOP 1` (exit code 1).

## Verify

    cd src && bash ../build.sh
    WORK=/tmp/atbw bash verify/run_all.sh        # runs all 12 cases (2638 = two-step restart pair)
    cd verify && WORK=/tmp/atbw python3 cmp.py    # per-file numeric diff vs reference outputs
    cd verify && WORK=/tmp/atbw python3 grow.py   # when each .t21 time history first departs, and how it grows
    cd verify && WORK=/tmp/atbw python3 report.py # the Markdown table used in VERIFICATION.md

`cases/2638` holds the restart pair `2638_Start_135_` then `2638_135_Restart_2a`; `run_all.sh` runs them
in that order in one directory. The solver has no restart-file mechanism (the second `.LIN` carries its
own initial conditions), so step 2 reads nothing step 1 wrote; each step is checked against its own
reference outputs.

## Re-running the Windows build

    GITHUB_TOKEN= gh workflow run windows-build.yml --repo bcn-services/bcns-client-technology-associates-atb

Manual trigger only (Windows runner minutes bill at 2x). Artifacts: `atb-win32-exe` (the deliverable)
and `verification-report-win32` (table, per-file diffs, divergence growth, runner info, binary check,
and every output file). Pass `-f win64=true` to also build an x86-64 comparison binary; it is not shipped.
