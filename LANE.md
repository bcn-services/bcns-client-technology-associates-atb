# Tier 2 desktop app — round 2 (v1: full ATB 3I parity + installer)

## Objective

Every screen in `docs/TIER2-SCOPE.md` §2, Weight Balancing included, matches ATB 3I, and one setup `.exe`
installs it — v1, the build Nate tests before anything goes to the client.

Lane done when:
- One green `app-e2e.yml` run opens every §2 screen (1–38) from the menu on the client decks, with a screenshot of each
- In that run, Run through the app on `cases/2479/2479_2.LIN` yields `.aou/.sa1/.t2x` identical to a direct `atb-win32.exe` run of the same deck on the same machine (`cross_gate.py`; the solver's numbers vary by CPU, so the reference outputs are a report, not the gate)
- The setup `.exe` installs on the `windows-2022` runner and every robot scenario passes against the installed app
- `PATH="$HOME/atb-work/dotnet:$PATH" dotnet test app/Atb.sln` passes on macOS

Status: rounds 1 and 1b are done (card schema, labeler, grid, run, viewer, renumbering, GEBOD, Windows robot;
see `LANE_PROGRESS.md`). Round 2 builds the remaining §2 screens, Weight Balancing and the installer, one
session per block in `docs/HANDOFF-PLAN.md` (S1–S5).

Global rules:
- `Atb.Core` stays free of UI and database dependencies; everything in it must build and test on macOS
- No new NuGet packages in `Atb.App` without a line in `docs/TIER2-SCOPE.md` §3 saying why
- Never change the solver (`src/`), `verify/`, or the reference outputs under `cases/`
- Unedited deck lines are written back from their original text; only edited lines are reformatted
- Run the tests with `PATH="$HOME/atb-work/dotnet:$PATH" dotnet test app/Atb.sln`
- Agents run on macOS and cannot launch the Windows app locally. Every `done when:` is a compile check,
  an `Atb.Core.Tests` unit test, or a green `app-e2e.yml` run on `windows-2022` dispatched with
  `GITHUB_TOKEN= gh workflow run app-e2e.yml --ref <branch>` and read with `GITHUB_TOKEN= gh run view` /
  `gh run download`. Pushing a non-`main` branch to `origin` for that is allowed; never push `main`, never
  force-push, never merge a PR. Use `GITHUB_TOKEN= gh` for every `gh` call. A `Human check:` line under a task
  is Nate's by-eye pass on the CI artifact and is not gated by QA
- **Copy ATB 3I exactly** for every design choice: behaviour, labels, dialog texts, defaults, order. Decompile:
  `~/atb-work/p0/decomp/ATB3I/` and `~/atb-work/p0/decomp/ATB3I.Util/`. Data tables:
  `~/atb-work/p0/msi/General Dynamics/ATB3I/ATB3iData.mdb`, read with `mdb-export`
- Three kept extras 3I does not have stay as they are: output-card (H.1–H.9) renumbering, the H.11 actuator fix,
  and the warning before saving a deck that fails `Deck.Validate()`. Where 3I leaves a reference stale
  elsewhere, fix it and note the divergence in `STANDARDS.md`
- Every new screen gets a robot scenario in `app/Atb.App.UiTests/Scenarios.cs` in the item that builds it,
  screenshotting each step; scenario assertions are never loosened to make a run pass
- GEBOD keeps 3I's full behaviour, Replace included. `C:\ATBFIG.SYS` (work folder `C:\Users\Public\ATBRun`,
  format pinned by `GebodTests.AtbFig_MatchesInstallerLayout`) is written once by the installer, as 3I's
  installer did; once the installer item lands, the app never writes to `C:\` itself
- File > New keeps 3I's 0 time steps. The follow camera stays on the torso, as 3I
- Weight Balancing runs the client's original solver, `frontend/bin/ATBV3_ATB3I.exe` (exe B in
  `frontend/FIDELITY.md`), through 3I's handoff (`SolverRun` `FeedMode.Handoff`: `C:\ATBFIG.SYS` names the handoff
  folder, the deck goes there as `winintm.sys`, `EXECATB.DAT` holds the single line `99`). Every other run keeps
  using `atb-win32.exe`. No balance code is ever written into `src/`; the pose math lives in the app

Context: `docs/HANDOFF-PLAN.md` (sessions, decisions), `docs/TIER2-SCOPE.md` (screen list, risks),
`STANDARDS.md` (divergences from 3I), `frontend/FIDELITY.md` (exe B gates), `README.md` (solver, verification).

---

### S1 — GEBOD Replace, lone-segment warning, Body Summary, Maximum Value List

- task: GEBOD Replace follows ATB 3I — in `Atb.Core/Cards/GebodMerge.cs` `Merge` with `GebodMode.Replace`,
    references into the replaced body are kept by position, as 3I's `GEBOD.cs:1766-1800` builds its update list
    and `ATBUpdate.UpdateDueToBody` / `UpdateOtherTable` (`ATBUpdate.cs:103`, `:326-351`) applies it: a reference
    outside the body to old segment (or joint) *i* of the body names the new body's *i*-th segment (or joint); when
    the old body had more segments or joints than the new one, the surplus positions go through `Renumber.Delete`
    (so references to them cascade or blank exactly as a segment/joint delete does) and every later reference
    shifts down by the difference; when the new body has more, the extra ones go in through `Renumber.Insert`
    after the kept positions and every later reference shifts up. The body's own cards (B.2.a/b, B.6, G.3.a,
    B.3–B.5) are replaced by GEBOD's. The single confirmation uses 3I's text from `Body.cs:1049`.
    `ReplacedReferences` lists only the references that will be dropped (surplus positions). Remove the
    `ponytail:` note at `GebodMerge.cs:51` and update any `STANDARDS.md` line that describes the old drop-all
    behaviour.
  guardrails:
    - `Gebodv.exe` is never modified; the app only answers its prompts
    - The merge has no renumbering of its own; every reference shift goes through `Renumber`
    - Add, Insert before and Insert after behave exactly as today; only Replace changes
  done when:
    - Replacing body 1 of `cases/2479/2479_2.LIN` with `fixtures/gebod-50m.ain` leaves every reference outside the body that named old segment *i* (for *i* up to the smaller segment count) naming new segment *i*, and the deck validates (unit test with literal expected lines)
    - Replacing a body with a smaller GEBOD body drops references to the surplus positions, shifts later references by the difference, and updates B.1 counts (unit test; where no client deck fits, build the case from the schema and say so); reverting to the old drop-all rule, or skipping the shift, makes a test fail (mutation checks recorded in the item report)
    - A robot scenario opens a temp copy of `2479_2.LIN`, runs Tools > GEBOD (50th-percentile adult male) with Replace body 1, answers Yes, saves and runs to completion, screenshotting each step, in a green `app-e2e.yml` run (run URL in the item report)
    - Existing passing tests remain passing, except those that asserted the old drop-all Replace, which are updated to the 3I rule and named in the item report
  caution: true
  status: done

- task: Segment and joint insert/delete warning, as ATB 3I — on the segment screens (`B.2.A`, `B.6`, `G.3.A`) and
    joint screens (`B.3.A`, `B.4.A`, `B.5.A`) in `Atb.App/MainForm.cs` (`AddRow`, `DeleteRows`, `PasteRows`), show
    3I's cascade warning once per action before changing the deck: segments "You have inserted/deleted segments
    and this requires CASCADE UPDATE/DELETE\r\nother input cards referring these segments.  Continue?" titled
    "Cascade Update of Segment ID Number"; joints the twin text and title (`TableForm.cs:412-440`), Yes/No, No
    leaves the deck unchanged. Inserting a segment inserts the segment alone: no joint is added and no joint-count
    check is added anywhere; the solver's STOP 24 on such a deck is 3I's behaviour too. Delete shows one dialog:
    3I's text, with today's list of referencing cards (`ConfirmDelete`) below it. The texts live as `Atb.Core`
    constants.
  guardrails:
    - Plane, vehicle and actuator screens keep today's dialogs
    - `Deck.Validate()` gains no joint-count rule
  done when:
    - The two warning texts and titles are `Atb.Core` constants equal, character for character, to 3I's strings (unit test with the literal 3I text)
    - Inserting one segment through `Renumber.Insert` on `cases/2479/2479_2.LIN` leaves the joint count unchanged and `Deck.Validate()` reports nothing (unit test)
    - A robot scenario on a temp copy of `2479_2.LIN` screenshots the segment warning, answers No and saves a file byte-identical to the original, then answers Yes and sees the grid grow by one row; the existing `InsertSegmentRun` scenario still passes answering Yes to both warnings (green `app-e2e.yml` run, URL in the item report)
    - Existing passing tests remain passing
  status: done

- task: Body Summary screen (§2 #6), copying ATB 3I's `Body.cs` "Body Editing Form" — Model > Body Summary...
    (`MainMenu.cs:2698`) opens a list of the deck's bodies (3I's columns, General Description from B.1) with
    3I's buttons in 3I's order: Add/Insert Copied Body, Copy Body, Replace Body with Copied Body, Delete Body,
    Add/Insert Body Using GEBOD, Replace Body Using GEBOD, Save & Exit; each shows 3I's dialog text
    (`Body.cs:627`, `:665`, `:756`, `:860`, `:990`, `:1019`, `:1049`) with 3I's buttons. The whole-body operations
    live in new `Atb.Core/Cards/Bodies.cs` over `Renumber` and `GebodMerge.BodyStarts` / `ReplaceRange`: copy
    carries the body's segments, joints and every dependent per-segment/per-joint card (`Body.cs:1255-1298`);
    delete removes the body as 3I's `DeleteBody` (`Body.cs:1078-1124`) through `Renumber.Delete`; replace with a
    copied body uses the same keep-by-position function as the GEBOD Replace item (one shared function, not
    two). The GEBOD buttons open the existing `GebodForm` with the placement preset.
  guardrails:
    - No renumbering of its own; every reference shift goes through `Renumber`
    - A body copy carries its joints and every dependent card, as ATB 3I does
  done when:
    - Deleting the second body in `cases/2638/2638_Start_135_.LIN` leaves a deck that validates (unit test), and a robot scenario doing it through the screen saves and runs that deck to completion
    - Copying body 1 of a client deck and adding it appends its segments and joints with every copied reference renumbered onto the copy (unit test with literal expected lines)
    - Replacing a body with a copied body of a different size keeps references by position and drops or shifts the rest, through the same function the GEBOD Replace uses (unit test; removing the shared call makes it fail)
    - A robot scenario opens Body Summary on a client deck and screenshots the form and each button's dialog, in a green `app-e2e.yml` run (URL in the item report)
  caution: true
  status: done

- task: Maximum Value List screen (§2 #38) — the read-only grid 3I opens from `mnuSetting` (`MainMenu.cs:2561`),
    same menu place, title, columns and row order, showing the solver limits from the `Setting` table
    (`mdb-export ATB3iData.mdb Setting`: Max Segment 80 … Balance Force 2). The rows are an `Atb.Core` constant
    copied from the export; the app never opens the `.mdb`.
  guardrails:
    - Read-only: no cell can be edited and nothing is written; raising limits is out of scope
  done when:
    - The `Atb.Core` constant holds all 21 `Setting` rows with the export's names and values, in 3I's display order (unit test with the literal rows)
    - `dotnet build app/Atb.sln` passes with the grid read-only and the menu item wired
    - A robot scenario opens the screen and screenshots it, in a green `app-e2e.yml` run (URL in the item report)
  status: done

### S2 — Vehicle Motion, function editors

- task: Vehicle Motion list (§2 #10) and its four sub-editors (half-sine, unidirectional, 6-DOF, spline P/V/A)
    with the deceleration plot, copying `Vehicle.cs`, `VehOpt1.cs`, `VehOpt2.cs`, `VehOpt34.cs`, `Plots.cs`
    (C.1–C.5 cards).
  guardrails:
    - One form per variant; the variant is decided by the same rule as ATB 3I's `VehicleType()`
    - Editing a row rewrites only that deck line
  done when:
    - Each client deck's vehicles open in the sub-editor `VehicleType()` picks (unit test on the rule over `cases/` and `corpus/`)
    - Editing a time-history row updates the C.3/C.4/C.5 card and nothing else, and the plot's points come from one `Atb.Core` function (unit tests)
    - A robot scenario opens every sub-editor on a client deck, edits one row, saves, and screenshots the plot, in a green `app-e2e.yml` run
  caution: true
  status: not started

- task: Function editors (§2 #17, #18, #19) — Force Deflection (constant / polynomial / tabular), Wind Force time
    history, Joint Stiffness, with the painted curve plot, copying `FDFData.cs`, `JntFData.cs`, `Plots.cs`
    (E.1–E.4, E.6, E.7 cards).
  guardrails:
    - Polynomial evaluation for the plot matches the solver's function definition in the user guide
  done when:
    - Every E.* function in `cases/` and `corpus/` opens, and saving it unedited changes zero bytes (unit test)
    - The plot's curve points come from one `Atb.Core` function, unit-tested for a constant, a polynomial and a tabular function
    - A robot scenario opens each editor on a client deck and screenshots the plot, in a green `app-e2e.yml` run
  status: not started

> **⚠️ AUTONOMOUS RUN — STOP HERE**

### S3 — Run Control, Output Control, HIC/CSI

- task: Run Control form (§2 #4) — A.1, A.3, A.4 (units, gravity, integrator, output interval), 16 fields, copying
    `RunControl.cs`.
  guardrails:
    - Editing a field rewrites only its deck line
  done when:
    - The form opens on every `cases/` deck and saving unedited changes zero bytes (unit test on the form's field ↔ card mapping)
    - A robot scenario edits one field, saves, and the saved deck differs in exactly that token
  status: not started

- task: General / Diagnostic Output Control Parameters (§2 #5) — the A.5 grid of 36 NPRT flags in 3I's two
    categories, names from the `A5Defination` table (copied as an `Atb.Core` constant).
  guardrails:
    - Flag names and category split match `A5Defination` exactly
  done when:
    - The constant matches `mdb-export ATB3iData.mdb A5Defination` (unit test with literal rows)
    - A robot scenario toggles one flag, saves, and the saved deck differs in exactly that token
  status: not started

- task: HIC and CSI Definition (§2 #36) — H.12 form + grid, copying `HIC.cs`, enabled by NPRT(4).
  guardrails:
    - HIC screen enablement follows NPRT(4) exactly as ATB 3I
  done when:
    - The enablement rule is an `Atb.Core` function unit-tested on a deck with NPRT(4) on and off
    - The screen opens on every client deck that enables it and saving unedited changes zero bytes (unit test)
    - A robot scenario opens the screen and screenshots it
  status: not started

### S4 — Weight Balancing

- task: Weight Balancing probe — a robot step in `app-e2e.yml` that runs `frontend/bin/ATBV3_ATB3I.exe` through
    the handoff (`EXECATB.DAT` = `99`) on one `cases/` deck with a body, once with NPRT(33) = 1 (setup run) and
    once with NPRT(33) = 2 (balance run, the balanced body's G.2 / G.3.a carrying the pose, `FileManager.cs:1186`,
    `:2044-2066`), and uploads `balance.run`, `balance.pos`, `balance.res`, `ATBDEBUG.TXT`. Commit the outputs under
    `app/Atb.Core.Tests/fixtures/balance/`.
  guardrails:
    - No balance code in `src/`; if exe B will not produce the files, stop and report to Nate
    - The robot never writes into `cases/`
  done when:
    - A green `app-e2e.yml` run's artifact holds all four files for both runs (URL in the item report)
    - The files are committed under `app/Atb.Core.Tests/fixtures/balance/`
  status: not started

- task: Weight Balancing screens (§2 #29) — "Weight Balancing Setup" (pick a body, contact-plane flags,
    `ToBalance.cs`) and "Body Weight Balancing" (rotate / translate a segment, angles, accelerations, forces, OK,
    `Balance.cs`), with the 3D pose in the existing viewer. `balance.pos` / `balance.res` are read by position
    (`Balance.cs:776-820`, `:1264-1314`, `:1465-1501`); `balance.run` present = success, else point at
    `ATBDEBUG.TXT`. The pose math is `FindAngle()` (`Balance.cs:3194-3304`); OK writes G.2 and G.3.a
    (`Balance.cs:1590-1643`).
  guardrails:
    - Only Weight Balancing uses exe B; every other run keeps `atb-win32.exe`
    - OK rewrites only G.2 and G.3.a lines
  done when:
    - The `.pos` / `.res` parsers read the probe fixtures on macOS (unit tests with literal values)
    - OK writes G.2 / G.3.a and every other line stays byte-exact (unit test)
    - The robot runs the full wizard once on Windows and screenshots each step
  caution: true
  status: not started

### S5 — installer, robot sweep

- task: Installer — Inno Setup on `windows-2022` producing one unsigned setup `.exe` with the self-contained x64
    app, `atb-win32.exe`, `ATBV3_ATB3I.exe` (Weight Balancing only), `Gebodv.exe` + `GEBOD.DAT`. It asks for admin
    once and writes `C:\ATBFIG.SYS` in the layout `GebodTests.AtbFig_MatchesInstallerLayout` pins; the app stops
    writing `C:\` itself. Original for comparison: `~/atb-work/p0/ATBV3_msi.exe`.
  guardrails:
    - The setup `.exe` is unsigned; nothing asks for a certificate
  done when:
    - The setup `.exe` installs silently on the runner, and `C:\ATBFIG.SYS` then matches the pinned layout
    - No code path in `Atb.App` writes under `C:\` outside the install and work folders (unit test or grep floor plus a test)
    - The installed app starts, opens a deck, and runs the solver in a robot scenario
  status: not started

- task: Robot sweep — install with the setup `.exe` on the runner, then run every scenario against the installed
    app, plus open-save one deck from each `corpus/` folder; every §2 screen opens with a screenshot.
  guardrails:
    - Scenario assertions are not loosened to make the run pass; a failure is fixed at its cause or reported
  done when:
    - A green `app-e2e.yml` run against the installed app with every scenario (URL in the item report)
    - Every screenshot is listed in the item report with what it shows, and none shows an error dialog
  status: not started

## Not yet specified

None this round.

## Out of scope

- License gate, About/order dialog, SnagIt capture — dropped on purpose; the client owns the software
- Raising solver limits; the `Setting` table is a read-only display — excluded by the quote §3
- Bit-identical numerics across machines — excluded by the quote §3; documented in `VERIFICATION.md`
- Plotting `.t2x`/`.tp8` time histories — ATB 3I never did it; parity does not require it
- Mac build of the app — client runs Windows; `Atb.Core` tests on Mac are enough
- Code signing — the client note tells him SmartScreen will warn ("More info → Run anyway")
- Nate's change requests — they come after v1 (HANDOFF-PLAN S8)
