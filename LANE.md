# Tier 2 desktop app — round 1 (core model, generic editor, run, viewer)

## Objective

A Windows app that opens a client `.LIN`, edits any card in a grid, runs the solver, and animates the
resulting `.sa1`, replacing ATB 3I for the everyday edit → run → view loop.

Lane done when:
- Open then Save of every deck under `cases/` writes the file back byte-for-byte, and a value edited in a grid lands on that card in the saved file
- Run from the app on `cases/2479/2479_2.LIN` produces `.aou`, `.sa1`, `.t2x` that `verify/cmp.py` accepts against the reference outputs
- The viewer plays every `cases/**/*.sa1` and `example/sledout.sa1` with segments, planes, contact ellipsoids, and belts drawn
- `dotnet test app/Atb.sln` passes on macOS and `dotnet build app/Atb.sln` passes on the `windows-2022` runner

Status: deck model with byte-exact round trip, `.sa1` parser, ported `SolverRun`, and the app
shell (generic grid + run + WPF viewer skeleton) exist; 56 tests pass. Scope and stack decision:
`docs/TIER2-SCOPE.md`.

Global rules:
- `Atb.Core` stays free of UI and database dependencies; everything in it must build and test on macOS
- No new NuGet packages in `Atb.App` without a line in `docs/TIER2-SCOPE.md` §3 saying why
- Never change the solver (`src/`), `verify/`, or the reference outputs under `cases/`
- Unedited deck lines are written back from their original text; only edited lines are reformatted
- Run the tests with `PATH="$HOME/atb-work/dotnet:$PATH" dotnet test app/Atb.sln`
- Agents run on macOS and cannot launch the Windows app. Every `done when:` is a compile check or an
  `Atb.Core.Tests` unit test; a `Human check:` line under a task is Nate's by-eye pass on the CI artifact
  and is not gated by QA. Copy ATB 3I's behaviour from the decompile at `~/atb-work/p0/decomp/` rather
  than redesigning it

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
