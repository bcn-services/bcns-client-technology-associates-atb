# Tier 2 desktop app — round 1 (core model, generic editor, run, viewer)

## Objective

A Windows app that opens a client `.LIN`, edits any card in a grid, runs the solver, and animates the
resulting `.sa1`, replacing ATB 3I for the everyday edit → run → view loop.

Lane done when:
- Open then Save of every deck under `cases/` writes the file back byte-for-byte, and a value edited in a grid lands on that card in the saved file
- Run from the app on `cases/2479/2479_2.LIN` produces `.aou`, `.sa1`, `.t2x` that `verify/cmp.py` accepts against the reference outputs
- The viewer plays every `cases/**/*.sa1` and `example/sledout.sa1` with segments, planes, contact ellipsoids, and belts drawn
- `dotnet test app/Atb.sln` passes on macOS and `dotnet build app/Atb.sln` passes on the `windows-2022` runner

Status: round 1's seven items are done (200 tests pass). Round 1b fixes what the lane acceptance
review found (`.claude/dev-team/lane-acceptance-report.md`): Run overwrites reference outputs, GEBOD
output is never merged, renumbering gaps, and nothing has run on Windows. Scope and stack decision:
`docs/TIER2-SCOPE.md`.

Global rules:
- `Atb.Core` stays free of UI and database dependencies; everything in it must build and test on macOS
- No new NuGet packages in `Atb.App` without a line in `docs/TIER2-SCOPE.md` §3 saying why
- Never change the solver (`src/`), `verify/`, or the reference outputs under `cases/`
- Unedited deck lines are written back from their original text; only edited lines are reformatted
- Run the tests with `PATH="$HOME/atb-work/dotnet:$PATH" dotnet test app/Atb.sln`
- Agents run on macOS and cannot launch the Windows app locally. Every `done when:` is a compile check,
  an `Atb.Core.Tests` unit test, or a green `app-e2e.yml` run on `windows-2022` dispatched with
  `GITHUB_TOKEN= gh workflow run <file> --ref <branch>` and read with `GITHUB_TOKEN= gh run view` /
  `gh run download`. Pushing a non-`main` branch to `origin` for that is allowed; never push `main`, never
  force-push. A `Human check:` line under a task is Nate's by-eye pass on the CI artifact and is not gated
  by QA. Copy ATB 3I's behaviour from the decompile at `~/atb-work/p0/decomp/` rather than redesigning it
- Where ATB 3I leaves a reference stale, fix it and note the divergence in `STANDARDS.md`

Context: `README.md` (solver, verification), `docs/TIER2-SCOPE.md` (feature list, risks),
`frontend/ATBRunner/` (QA runner the solver-run code came from).

---

- task: Card schema for every `.LIN` card in `Atb.Core/Cards/CardSchema.cs` — for each `CARD x.y`
    label the ordered field names, field kinds (string / int / real / segment-ref / joint-ref /
    plane-ref / function-ref), and the condition under which the card appears (e.g. `B.2.b` only
    when `B.2.a` field 12 is 1; `D.2` count from `D.1`). Source: `~/atb-work/p0/pdf/atbusrguide.txt`
    card descriptions, cross-checked against the Access column lists (schema column order is card
    token order) and the 12 client decks. Extend the seed dictionary already in the file.
  guardrails:
    - Field names match the ATB 3I column titles where one exists, so the client sees familiar labels
    - Do not invent fields to make a deck fit; a deck line that disagrees with the guide is a test failure to investigate
  done when:
    - Every labelled line in every `cases/**/*.LIN` has a schema entry and its token count equals the schema's field count (or a documented variable-length rule)
    - Every card the scope table in `docs/TIER2-SCOPE.md` §2 names has a schema entry
    - A `Deck.Validate()` reports label, line number, and reason for each mismatch, and reports nothing for the 12 client decks
    - Existing passing tests remain passing
  status: done

- task: Deck labeler for unlabelled or mislabelled decks — a grammar walk in `Atb.Core/Lin` that
    assigns `CARD x.y` labels to a bare `.lin` (the vendor samples in
    `~/atb-work/p0/msi/General Dynamics/Samples/*.lin`) using the schema's counts and conditions,
    and that corrects ATB 3I's `CARD H.1.a` label on empty `H.2.a`/`H.3.a` rows.
  guardrails:
    - Labelled client decks are never relabelled; the labeler only fills blanks and fixes the known H-card bug
    - A deck the grammar cannot walk raises a clear error naming the last card understood
  done when:
    - Every vendor sample labels completely and `Deck.Validate()` reports nothing afterwards
    - Labelling then saving a client deck changes zero bytes
    - The three `H.1.a`-mislabelled empty rows in the client decks are relabelled and the saved file is unchanged except for those labels
  status: done

- task: Generic card grid screen in `Atb.App/MainForm.cs` — one `DataGridView` over
    all lines of a card (or card group, e.g. `B.2.a` + conditional `B.2.b` as extra columns),
    column headers and cell types from the schema, add/delete/copy/paste rows, numeric validation
    with revert, and a card list on the left of the main window that opens each screen from the
    scope table's menu names.
    Human check: every scope-table screen opens on the 12 client decks; an Excel paste lands as rows.
  guardrails:
    - Editing a cell rewrites only that deck line; the `Deck` stays the single document
    - Reference columns (segment, joint, plane, function) show the referenced name next to the number but store the number
  done when:
    - Setting segment 1's weight through the `Deck` edit API on `cases/2479/2479_2.LIN` and saving differs from the original in exactly that token (unit test)
    - A `Atb.Core` function turns tab-separated paste text into deck lines carrying the given label, rejecting rows whose token count disagrees with the schema (unit test)
    - Every distinct card label across the 12 client decks and the vendor fixtures has a schema header for each column (unit test)
    - `dotnet build app/Atb.sln` passes with add/delete/copy/paste row actions wired in `MainForm`
  status: done

- task: Run action — File > Run uses `Atb.App/Solver/SolverRun.cs` in a per-run temp directory
    under a short path, streams solver stdout to a progress window, supports cancel, copies the
    outputs next to the deck, and offers to open the `.sa1` in the viewer when done. Convert
    `.ain` → `.lin` (solver mode 102) goes through the same code path.
    Human check: Run on `cases/2479/2479_2.LIN` yields outputs `verify/cmp.py` accepts; Cancel kills the
    solver within 2 s; Convert on `example/Sled.ain` opens in the grid.
  guardrails:
    - Never write into `System32` or the app's install directory; scratch files live in the temp dir and are removed after the outputs are copied
    - The UI thread never blocks on the solver
  done when:
    - Output collection is an `Atb.Core` function: given a work dir holding `<base>.aou/.sa1/.t2x` it copies them next to the deck path and removes the work dir, and leaves nothing behind when cancelled mid-run (unit test on temp dirs)
    - The stdin answer sequence for mode 101 (`.lin` run) and mode 102 (`.ain` convert) comes from one `Atb.Core` function, unit-tested against the answers `SolverRun` sends today
    - `dotnet build app/Atb.sln` passes with the progress window, Cancel, and Convert menu item wired to `SolverRun`
  status: done

- task: Animation viewer in `Atb.App/Viewer/AnimationForm.cs` + `Sa1Scene.cs` (WPF `Viewport3D` in an
    `ElementHost`) — segment ellipsoids as scaled unit-sphere meshes under the per-frame transform,
    contact ellipsoids as superquadrics with ATB 3I's `MakeHyperElip` vertex formula and `MakeCntacElipXFrm`
    rotation order (both already copied into `Sa1Scene`),
    planes as two-sided quads, belts as polylines from the per-frame belt tables, play/pause/step/
    speed controls, per-object visibility and colour (defaults from ATB 3I's `ColorMap`),
    view-all camera and a segment-mounted camera with the same look-at semantics as ATB 3I (the camera
    rides under the segment's transform, so it turns with the segment, as `Animation.cs` does).
    Human check: every `.sa1` plays start to end; sled belts are drawn on frame 0; toggling a segment
    off and on restores its colour; the segment camera stays centred and turns with the segment.
  guardrails:
    - Frame data comes only from `Atb.Core.Sa1`; no re-parsing in the UI
    - Solver axes map to screen the same way as ATB 3I (Z up on screen)
  done when:
    - Every `cases/**/*.sa1` and `example/sledout.sa1` loads with strictly increasing frame times and one transform per segment per frame (unit test)
    - For `example/sledout.sa1` frame 0, the world positions of both belt strands' points come from one `Atb.Core` function and lie within the sled's bounding box (unit test)
    - The playback clock maps wall time × speed to a frame index by binary search, in `Atb.Core`, unit-tested at the first, last, and a mid-file time
    - `dotnet build app/Atb.sln` passes with the segment camera parented under the segment transform
  status: done

- task: ID renumbering — one function in `Atb.Core/Cards/Renumber.cs` that inserts or deletes a
    segment, joint, plane, or vehicle and shifts every reference to it in every other card, using
    the schema's reference kinds; used by the grid screen's add/delete row for those cards.
  guardrails:
    - A reference the schema does not mark is never touched; add the schema mark instead
    - Deleting an entity that is still referenced asks first and lists the referencing cards
  done when:
    - Inserting a segment before segment 3 in `cases/2479/2479_2.LIN` increments every segment reference ≥ 3 across B.3, D.*, F.*, G.*, H.* cards, and the deck still validates
    - Deleting the last joint then re-adding it reproduces the original deck byte-for-byte
    - Existing passing tests remain passing
  caution: true
  status: done

- task: GEBOD body generator, copying ATB 3I's `GEBOD.cs` screen — the form's fields (subject
    description, subject type, percentile or measured values, unit choices) become the typed answers
    the 2000-era console program `Gebodv.exe` expects on stdin (prompts: `PLEASE ENTER A DESCRIPTION OF
    THE SUBJECT`, `ENTER NUMBER CORRESPONDING TO DESIRED SUBJECT TYPE`, `ENTER DESIRED PERCENTILE FOR`,
    `ENTER VALUE FOR`, `SELECT UNITS FOR`, `ENTER THE NUMBER CORRESPONDING TO THE DESIRED`, optional
    `FULL PATH NAME OF THE FILE ... UNIT 1`). Run it through `SolverRun` in stdin mode in a temp dir
    with `GEBOD.DAT` beside it, then feed the resulting `GEBOD.ain` through the existing Convert path
    and open the `.lin` in the grid. Copy `Gebodv.exe` and `GEBOD.DAT` from
    `~/atb/ATB_INSTALL/ATB_OLD/ATB 1.3/ATB Update/1300 patch/NewFiles/` into `frontend/bin/`.
    Human check: generating a 50th-percentile adult male on Windows yields a deck that opens and runs.
  guardrails:
    - `Gebodv.exe` is never modified; the app only answers its prompts
    - The GEBOD form asks exactly what ATB 3I's `GEBOD.cs` asks, in the same order, with the same defaults
  done when:
    - An `Atb.Core` function turns a GEBOD request record into the ordered stdin answer lines, and the prompt→answer mapping is unit-tested for the percentile path and the measured-values path
    - `frontend/bin/Gebodv.exe` and `frontend/bin/GEBOD.DAT` are in the repo and the publish step copies them beside `ATB.exe`
    - `dotnet build app/Atb.sln` passes with a Tools > GEBOD menu item opening the form
  status: done

### Round 1b — acceptance-review fixes (added 2026-09-12)

- task: Run and Convert never overwrite existing files silently, as in ATB 3I, which asked for the output
    name with a Save dialog every time (`decomp/ATB3I/MainMenu.cs:3072-3081`). In `Atb.App/MainForm.cs`
    `RunSolver`, before starting, show a `SaveFileDialog` "Save results as" (`OverwritePrompt` on),
    pre-filled with the deck's folder and base name, filter `*.aou` for Run and `*.lin` for Convert; the
    chosen folder + base becomes the output base; cancelling the dialog aborts the run. Change
    `Atb.Core/Solver/SolverJob.Finish(workDir, outBase, deckPath, mode, cancelled)` to take the destination
    directory and a `succeeded` flag: copy outputs only on success, and always delete the scratch dir
    (try/finally), even when a copy throws. This also fixes `MainForm.cs:327`, which keys on
    `res.Error == "cancelled"` and so copies partial outputs over good ones after a solver failure.
  guardrails:
    - Nothing is written into the deck's folder unless the user chose it in the dialog
    - The UI thread never blocks on the solver
  done when:
    - A failed, non-cancelled run leaves previously existing `<base>.aou/.sa1/.t2x` byte-identical and removes the scratch dir (unit test on temp dirs)
    - `Finish` copies to the given destination dir and base rather than the deck's dir, and Convert writes `<chosen>.lin` (unit test)
    - Flipping the success gate, or ignoring the destination dir, makes a test fail (mutation checks recorded in the item report)
    - `dotnet build app/Atb.sln` passes with the Save dialog wired into Run and Convert
  status: done

- task: Close the renumbering gaps item 6 left open, following ATB 3I's `ATB3I.Util/ATBUpdate.cs` except
    where 3I leaves a reference stale. (1) Keep renumbering H.1–H.9 (3I never touches H tables,
    `ATBUpdate.cs:203-308`) and record that divergence in `STANDARDS.md`. (2) Grid paste on the segment,
    joint, plane and vehicle screens (`MainForm.cs` `PasteRows` → `InsertLines`) goes through
    `Renumber.Insert` per accepted row, the same path as Add. (3) Mark H.11 `Actuator`
    (`CardSchema.cs:182`) with a new actuator reference kind so the F.10 cascade shifts or drops H.11
    refs and updates H.11's `Count` (3I has this gap; fix it and note the divergence). (4) Add schema
    marks for the D.4, F.2.B, F.6 and F.9 segment/ellipsoid/airbag fields that `ATBUpdate.cs:223-253`
    updates (`D4aD4f`, `F2b`, `F6`, `F9f/g/i/j/m`), mirroring `UpdateOtherTable` (shift on insert,
    shift or drop on delete, `resetRID`). (5) Remove the D.6 Type 5 "second line" branch
    (`Renumber.cs:128`) — `src/input_contraints.for` reads one line per constraint for every `KQTYPE`.
  guardrails:
    - A reference the schema does not mark is never touched; add the schema mark instead
    - Every new mark cites the `ATBUpdate.cs` line it copies, or the `STANDARDS.md` divergence it implements
    - Paste keeps rejecting rows whose token count disagrees with the schema
  done when:
    - Pasting two B.2 segment rows before segment 3 on `cases/2479/2479_2.LIN` shifts every segment reference ≥ 3 by 2, grows the B.1 counts by 2, and the deck validates (unit test)
    - Deleting an F.10 actuator removes it from H.11, renumbers later actuator refs, and updates H.11's `Count` (unit test)
    - Inserting a segment before one referenced by D.4, F.2.B, F.6 or F.9 shifts those refs, and deleting a D.6 Type 5 constraint removes exactly one line (unit tests on client decks; where no client deck carries a card, build the case from the schema and say so)
    - Existing passing tests remain passing
  caution: true
  status: done

- task: Validate the deck before Save and Run — `MainForm` calls `Deck.Validate()` before writing or
    running, and when it reports problems shows a warning listing each label, line number and reason,
    with Cancel and Continue.
  guardrails:
    - Continue writes exactly what Save writes today; validation never alters the deck
  done when:
    - An `Atb.Core` function formats `Deck.Validate()` results as one "line N (label): reason" row each, unit-tested on a deck with one bad token count
    - `dotnet build app/Atb.sln` passes with the check wired before Save, Save As, Run and Convert
  status: done

- task: Windows UI test robot. New project `app/Atb.App.UiTests/` (`net8.0-windows`, xunit, `FlaUI.UIA3`),
    kept out of `Atb.sln`. New `.github/workflows/app-e2e.yml` (`windows-2022`, `workflow_dispatch`):
    build the solver by calling `windows-build.yml` (add `on: workflow_call` there) and consuming its
    `atb-win32-exe` artifact; publish the app as `app-build.yml` does with `atb-win32.exe` beside `ATB.exe`
    (also as a Content item in `Atb.App.csproj` so every publish ships it); run a GEBOD probe
    (`frontend/bin/Gebodv.exe` fed `Gebod.Answers` for a 50th-percentile adult male, once with and once
    without `C:\ATBFIG.SYS`); then the UI scenarios on temp copies of the decks, screenshotting each
    step: grid edit + Save on each `cases/*.LIN`; Run on `2479_2.LIN` answering the Save dialog with
    `$WORK/2479_2/2479_2_new`, then `verify/cmp.py` with a matching `cases.txt`; insert a segment in
    `2479_2.LIN`, save, Run to completion; viewer open/play/step on every `cases/**/*.sa1` and
    `example/sledout.sa1` with screenshots at 0/50/100%. Upload screenshots, logs, outputs and the probe's
    `GEBOD.ain` as artifacts. Commit the probe's `GEBOD.ain` as `app/Atb.Core.Tests/fixtures/gebod-50m.ain`.
  guardrails:
    - `windows-build.yml` behaves exactly as before when dispatched by hand
    - The robot never writes into `cases/`; every deck it touches is a temp copy
    - macOS `dotnet test app/Atb.sln` is unaffected by the new project
  done when:
    - A dispatched `app-e2e.yml` run on the item branch completes green, and its artifact holds the published app folder with `atb-win32.exe` beside `ATB.exe`, a screenshot per scenario step, and the `cmp.py` report (run URL in the item report)
    - In that run each `cases/*.LIN` edit + Save differs from the original in exactly the edited token; Run on `2479_2.LIN` through the app yields `.aou/.sa1/.t2x` identical to a direct `atb-win32.exe` run of the same deck in the same job, per `frontend/probe/compare.py cross` with `frontend/package/volatile.txt` (the solver's results vary by runner CPU, so the references are not the gate), with `cmp.py`'s report against the references uploaded alongside; and the renumbered deck runs to completion
    - The viewer scenario plays every `.sa1` with no error dialog, and its screenshots are listed in the item report with what each shows
    - `app/Atb.Core.Tests/fixtures/gebod-50m.ain` is committed from the probe, and the item report says whether `Gebodv.exe` succeeds without `C:\ATBFIG.SYS`
  status: done

- task: Merge GEBOD output into the open deck, as ATB 3I does from its Body screen (`decomp/ATB3I/Body.cs:964-1076`
    Add / Insert before / Insert after / Replace; `GEBOD.cs:2239-2417` `InsertHumanBody`;
    `ATBUpdate.UpdateDueToBody` cascade; counts from row counts). New `Atb.Core/Cards/GebodMerge.cs`
    `Merge(Deck, ainText, placement)`: parse `GEBOD.ain`'s B.2–B.5 cards with the Fortran `FORMAT`s in
    `src/input_*` (the `AIN_CONVERT` branches show the matching `.lin` write format), emit `.lin` lines in
    that format, and insert each segment and joint through `Renumber.Insert`; Replace deletes the body's
    segments through `Renumber.Delete` with one up-front confirmation, then inserts. Body boundaries follow
    3I's `RefSegment`/`BodyCount` logic. `GebodForm` gets the placement choice and 3I's warning text
    (`Body.cs:990`). `MainForm.Gebod()` merges into the open deck instead of calling `ConvertAin`. A new
    File > New builds 3I's empty deck (`decomp/ATB3I/FileManager.cs:36-92`: IN/LB/SEC, gravity Z 386.088,
    dummy vehicle, B.1 "No Data") so GEBOD works with no deck open. Stop writing `C:\ATBFIG.SYS` if the
    robot's probe showed `Gebodv.exe` succeeds without it.
  guardrails:
    - `Gebodv.exe` is never modified; the app only answers its prompts
    - The merge has no renumbering of its own; every reference shift goes through `Renumber`
    - Column positions come from the Fortran `FORMAT`s, never guessed from the sample file
  done when:
    - Merging `fixtures/gebod-50m.ain` into `2479_2.LIN` as a new body appends its segments and joints, grows the B.1 counts by the GEBOD segment and joint counts, and the deck validates (unit test with literal expected lines)
    - Insert-before-body-1 shifts every existing segment and joint reference by the GEBOD counts, and Replace-body-1 removes body 1's segments and joints before inserting and leaves a deck that validates (unit tests)
    - File > New's deck plus a GEBOD Add passes `Deck.Validate()` (unit test)
    - `dotnet build app/Atb.sln` passes with the placement choice on `GebodForm` and Tools > GEBOD merging into the open deck
  caution: true
  status: done

- task: Full Windows end-to-end pass — add a GEBOD scenario to `Atb.App.UiTests` (File > New → Tools >
    GEBOD, 50th-percentile adult male, Add as new body → Save → Run to completion, screenshots each step)
    and dispatch `app-e2e.yml` on the final branch with every scenario.
  guardrails:
    - Scenario assertions are not loosened to make the run pass; a failure is fixed at its cause or reported
  done when:
    - A dispatched `app-e2e.yml` run with every scenario, the GEBOD one included, completes green (run URL in the item report)
    - Every screenshot in that run's artifact is listed in the item report with what it shows, and none shows an error dialog
  status: not started

> **⚠️ AUTONOMOUS RUN — STOP HERE**

- task: Body Summary screen (insert/copy/replace/delete whole bodies) over the renumbering function
  guardrails:
    - A body copy carries its joints and every dependent card, as ATB 3I does
  done when:
    - Deleting the second body in `cases/2638/2638_Start_135_.LIN` leaves a valid deck the solver runs
    - Copying a body appends its segments and joints with renumbered references
  status: not started

- task: Vehicle Motion list and its four sub-editors (half-sine, unidirectional, 6-DOF, spline P/V/A) with the deceleration plot
  guardrails:
    - One form per variant; the variant is decided by the same rule as ATB 3I's `VehicleType()`
  done when:
    - Each client deck's vehicles open in the right sub-editor
    - Editing a time-history row updates the C.3/C.4/C.5 card and the plot
  status: not started

- task: Function editors — Force Deflection (constant/polynomial/tabular), Joint Stiffness, Wind Force — with the painted curve plot
  guardrails:
    - Polynomial evaluation for the plot matches the solver's function definition in the user guide
  done when:
    - Every E.* function in the client decks opens, plots, and saves unchanged
  status: not started

- task: HIC/CSI screen, Run Control form, Output Control Parameter grids with names from `A5Defination`
  guardrails:
    - HIC screen enablement follows NPRT(4) exactly as ATB 3I
  done when:
    - The three screens open on every client deck and save unchanged
  status: not started

- task: Installer — Inno Setup script built on the `windows-2022` runner producing one setup exe with the self-contained app and `atb-win32.exe`
  guardrails:
    - No admin-only paths; per-user install works
  done when:
    - The setup exe installs on a clean Windows 11 VM, the app starts, opens a deck, and runs the solver
  status: not started

## Not yet specified

- Weight Balancing: the positional `balance.pos`/`balance.res` formats need a captured sample from the XP VM before an item can be written — revisit after the Run action item

## Out of scope

- License gate, About/order dialog, SnagIt capture — dropped on purpose; the client owns the software
- Raising solver limits, `Setting` table becomes read-only display — excluded by the quote §3
- Bit-identical numerics across machines — excluded by the quote §3; documented in `VERIFICATION.md`
- Plotting `.t2x`/`.tp8` time histories — ATB 3I never did it; parity does not require it
- Mac build of the app — client runs Windows; `Atb.Core` tests on Mac are enough
