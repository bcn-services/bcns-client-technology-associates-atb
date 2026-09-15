# Lane Acceptance Report — Tier 2 round 1 + 1b
**Date:** 2026-09-12
**Branch:** r1b-run-overwrite @ a99cf61 (code-identical to bcfad2b, the commit CI tested: `git diff bcfad2b..HEAD` touches only `.claude/dev-team/*`, `LANE.md`, `LANE_PROGRESS.md`). Base: tier2-app.
**Windows evidence:** run https://github.com/bcn-services/bcns-client-technology-associates-atb/actions/runs/34735611144 (headSha bcfad2b, all jobs green), artifacts downloaded to `~/.claude/jobs/ee1bba3e/tmp/accept-34735611144/`
**Prior report:** `.claude/dev-team/lane-acceptance-report.md` is not recoverable. It is not in this worktree, not in the main checkout, and not in any branch. Commit 0bd826e ("lane acceptance report") changed only `LANE_PROGRESS.md`. This report is based on LANE.md's own summary of what the prior review found (LANE.md:14-16).

## Verdicts

| # | Criterion | Verdict |
|---|---|---|
| 1 | Open→Save byte-for-byte; a grid edit lands on its card | **MET** |
| 2 | Run on 2479_2 → `.aou/.sa1/.t2x` that `cmp.py` accepts vs references | **PARTIAL.** The app is proven to run the solver faithfully. The "cmp.py accepts" part cannot fail, so it proves nothing. |
| 3 | Viewer plays every `cases/**/*.sa1` + `sledout.sa1` with segments, planes, contact ellipsoids, belts | **MET** (the 3 occluded follow-camera frames do not change this) |
| 4 | `dotnet test app/Atb.sln` on macOS; `dotnet build app/Atb.sln` on windows-2022 | **PARTIAL.** macOS is MET. On Windows, `Atb.sln` itself was never built at this head. |

### 1 — MET
- **Byte-exact round trip, all 12 decks:** `app/Atb.Core.Tests/DeckTests.cs:13` `ClientDeck_RoundTrips_ByteExact_PreservingRaw` and `:21` `..._Canonical`. Both iterate every `cases/**/*.LIN` (`Fixtures.cs` `ClientDecks`). I re-ran the macOS suite myself; results under criterion 4.
- **The app's Save uses the tested code:** `MainForm.cs:327` `Write()` → `Deck.Save` (`Deck.cs:45-47`: `File.WriteAllText(path, Write(), Encoding.Latin1)`). That is the same `Write()` the round-trip test checks. Every line is re-emitted with CRLF (`Deck.cs:59`), so an edited line keeps its line ending.
- **An edit lands on its card, unit level:** `CardGridTests.cs:15` `Edit_Segment1Weight_SaveDiffersInExactlyThatToken`.
- **An edit lands on its card, through the real UI on Windows:** 12/12 `GridEditSave` passed (`app-e2e/trx/robot.trx`).
  - The gate `app-e2e/tokendiff.txt` printed `OK` for all 12 decks. It checks two things: every other line is byte-identical, and exactly one token on one line changed from old to new (`tokendiff.py:13-27`).
  - Screenshots `shots/edit-*/03-edited.png` show the status bar reading "CARD B.2.a Weight = …".
- **Gap (minor):**
  - No Windows scenario does an unedited Open→Save. Tokendiff's "every other line identical" check covers it in practice.
  - The saved edit decks (`$WORK/edit/`) are not collected into the artifact (app-e2e.yml Collect step), so they can't be re-checked now.
  - Tokendiff does not check the label of the changed line. Only the screenshot shows it was B.2.a.

### 2 — PARTIAL
What the uploaded `cmp.py` report actually says (`app-e2e/cmp-app.txt`, app run on an Intel Xeon 8573C):
- It compares 8 files: `sa1` and `t21`–`t27`. **The `.aou` is never compared** (`verify/atbcmp.py:24` skips it because it carries the run date and time).
- The outputs match the references for about the first 0.4 s, then drift. `sa1` has 40,965 of 92,906 values off by more than 1e-4, with maxrel = 2 (sign flips). `t21`/`t22`/`t23` also have maxrel 2. `t25` (contact) has maxabs 57.2. Across all files, 70,751 values are off by more than 1e-4.
- `cmp.py` has no pass/fail. It prints numbers and nothing else (`verify/cmp.py`), and the workflow runs it with `|| true`. So "cmp.py accepts" can never be false. **As written, the criterion is not a gate.**

What is actually proven:
- **The app runs the solver exactly as a direct run does.** `app-e2e/cross.txt`: all 9 files (aou, sa1, t21–t27) are identical to a direct `atb-win32.exe` run in the same job, except for the lines `frontend/package/volatile.txt` masks. It ends `CROSS PASS` / `GATE PASS`.
  - `volatile.txt` masks only dates, CPU times, the work folder, the output-file-name echo lines, and one banner full stop. No simulation numbers are masked.
  - `cmp-direct.txt` matches `cmp-app.txt` line for line.
- **The drift depends on the CPU.** The solver job on an AMD EPYC 9V74 gave 73,130 values off for 2479 (`verification-report-win32/table.md`). The e2e job on the Intel runner gave 70,751. `VERIFICATION.md:13-17,128-148` documents this as rounding drift after onset and says cmp is not the acceptance test.
- **Real acceptance is scored elsewhere.** `ACCEPTANCE.md:31` scores 2479 PASS, 51/51 channels (ISO/TS 18571 + peak band). But that score comes from the 2026-09-10 run trees, not from this run's Windows output.

Why PARTIAL:
- The app-faithfulness part is fully proven. The reference-acceptance part is not proven for these outputs.
- LANE.md:222 (item C) already moved the gate to the cross comparison, but the lane-level criterion at LANE.md:10 was never reworded.
- To close it, either reword LANE.md:10 to "identical to a direct solver run (cross gate) and 2479 in the ACCEPTANCE band", or score `app-e2e/outputs/2479_2/*` with `verify/acceptance.py`/`iso18571.py`.

### 3 — MET
- **Robot results:** 13/13 `ViewerPlayStep` passed (12 case `.sa1` + `example/sledout.sa1`). Each scenario asserts:
  - no error window
  - frame 1 at open
  - frames advance while playing
  - step forward/back works
  - seek to the 0/50/100% frames (`Scenarios.cs:165-196`)
- **The error check works:** the negative control `ViewerErrorDetector_TripsOnTruncatedSa1` passed, and its screenshot `view-truncated-control/02` shows the expected error.
- **Drawing is not asserted by the robot.** The evidence for drawing is the screenshots. I looked at these myself:
  - `view-sledout/02-frame-0pct`: segments, yellow planes, green contact-ellipsoid pad, and red belts all drawn on frame 0. "Belt 1/Belt 2" appear in the legend.
  - `view-2638_135_Restart_2a/02`: full body, planes, and green bar ellipsoids.
  - `view-2750_7/02`: legs visible below a ramp plane.
  - `view-2479_2/05`: fully blocked by a yellow Door/Floor plane.
  - `view-2638_135_Restart_2a/06`: a blue speck only.
- **The 3 bodiless frames** are 2479_2/05 and 2638_135_Restart_2a/06, /07. All three are torso-follow camera frames. That camera copies 3I's segment camera, which turns with its segment (LANE.md:104-105 asks for exactly that). The same files show the body at View all, and every file has at least one frame with the body visible. **They do not undercut the criterion.** They are a UX risk; see below.
- **Caveats:**
  - "Plays every" is tested as play, step, and 3 seek points, not a start-to-end render.
  - Belts exist only in sledout, where they are drawn.
  - The viewer item's Human check (LANE.md:106-107) is still Nate's by-eye pass.

### 4 — PARTIAL
- **macOS: MET, reproduced independently.** I ran `dotnet test app/Atb.sln` on a clean `git archive` export of a99cf61 (`~/.claude/jobs/ee1bba3e/tmp/r1b-head`). Result: `Passed! Failed: 0, Passed: 262, Skipped: 0, Total: 262`. This matches the 262 claimed.
- **windows-2022: not run as written.**
  - Run 34735611144 compiled `Atb.Core` + `Atb.App` (step "Publish app": `dotnet publish app/Atb.App -c Release -r win-x64`, success) and `Atb.App.UiTests`.
  - **`Atb.Core.Tests` was never compiled or run on Windows at this head.**
  - The only `app-build.yml` run (34716805657, success) is at 08ebc0e, the round-1 PR #3 head. That is before any round-1b code.
  - **Closing it is cheap:** push r1b onto tier2-app. Open PR #3 will then re-run `app-build.yml` (`paths: app/**`), which does `dotnet test app/Atb.Core.Tests` + publishes `Atb.App`. That covers all three sln projects. Or add one `dotnet build app/Atb.sln` step to app-e2e.yml.

## Top residual risks before client handoff
1. **GEBOD needs administrator rights on a real client machine.**
   - Gebodv.exe dies without `C:\ATBFIG.SYS`: `app-e2e/gebod/probe.txt` shows `forrtl: severe (29): file not found … C:\ATBFIG.SYS`, exit -1073741795.
   - The app writes that file itself (`MainForm.cs` Gebod, `const string fig = @"C:\ATBFIG.SYS"`). A standard Windows user cannot create files in the `C:\` root.
   - CI runs as `runneradmin` (`app-e2e/runner-info.txt`), so the robot cannot see this problem.
   - It conflicts with the Installer item's guardrail "No admin-only paths; per-user install works".
   - Two ATB instances running GEBOD at once also clobber each other's copy of the file.
   - **Test as a non-admin user before handoff.**
2. **Nothing gates regressions after merge.**
   - `app-e2e.yml` runs on push only for `branches: [r1b-run-overwrite]`, and `workflow_dispatch` works only once the file is on main.
   - `app-build.yml` runs on PRs only.
   - Once this branch lands, no Windows UI or solver-transparency check runs on tier2-app or main.
3. **The client will see different numbers from their old outputs.**
   - Outputs leave the references after about 0.4 s on 2479 (maxrel 2), and they differ between two Windows CPUs.
   - The only CI gate is app ≡ solver on the same machine. The ACCEPTANCE band is not computed on the shipped binary's Windows output.
   - The handoff needs the VERIFICATION/ACCEPTANCE story in front of the client, and ideally an acceptance score of the e2e output.
4. **The "new deck" path stops short of the viewer.**
   - File > New keeps 3I's `NSTEPS 0`. New → GEBOD → Run therefore writes only `.aou` and no `.sa1` (engineer report Findings; `new-gebod-run/12`).
   - The Run Control form is not built yet, so the user has to find NSTEPS in the generic grid.
   - Combined with the torso camera being blocked by planes (3 of the 39 frames shot after a camera switch) and the far View-all framing on 2495_2 and 2819_5, the viewer will read as "no body shown" to a client unless someone explains it or View all re-frames.
5. **Some Windows evidence is thin.**
   - `Atb.Core.Tests` (Latin1, CRLF, and path-sensitive tests) has never run on Windows with round-1b code.
   - The saved edited decks are not uploaded.
   - Rendering correctness rests on screenshot reads, not assertions.
   - In the 2-occupant decks (2495_2, 2696_3), the follow camera can select only the first occupant (engineer report).
