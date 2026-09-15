# Tier 2 — desktop app replacing ATB 3I: scope

Quote §2 Tier 2: *"Replace the ATB 3I front end with a new native desktop app: create/edit
input files in a GUI, run the solver, visualize and animate the `.sa1` output. Windows installer
provided. Parity with ATB 3I workflow, no UX redesign required."* Exclusions (§3): raising solver
limits, redesigned UX, bit-identical numerics, training.

Source of truth for "parity": the ILSpy decompile of ATB 3I v2.0 (`~/atb-work/p0/decomp`, 44 files,
~48k lines) plus its Access database `ATB3iData.mdb`. Inventory reports (screen-by-screen, with
`file:line` citations) are in the job scratch dir; the conclusions are folded in below.

## 1. What ATB 3I actually is

- **Deck in → Access → grids → deck out.** Open reads the `.LIN` into ~62 per-card Access tables
  (keyed by `FileID`), builds 5 join tables, and every editor screen is a `C1TrueDBGrid` bound to one
  table. Save regenerates the whole `.LIN` from the tables. The database is a cache, not a document.
- **Run / Convert bypass the database.** They copy the deck to `%SystemRoot%\System32\winintm.sys`,
  write a mode code + base name to `EXECATB.DAT`, start `ATBV3.exe`, and wait.
- **Animation** reads the `.sa1` into arrays and drives an Open Inventor scene (TGS Visual3Space
  ActiveX, per-frame `SoTransform.setMatrix`, segment-mounted camera).
- **Plots** are `C1Chart` displays of typed-in polynomial/tabular function data. They never read
  `.t2x`/`.tp8`.
- **Balance** ("weight balancing") runs the solver in a special mode (99) on a stripped deck and reads
  the resulting pose back into the initial-condition cards.
- **GEBOD** generates a body from anthropometric inputs through `GEBODFor.dll`, a Fortran-compiled
  .NET 1.x assembly with no source. The ATB 1.3 era `Gebodv.exe` (console, PE32) + `GEBOD.DAT` is on
  disk and is the fallback.
- **Dropped:** license gate (`Msvby24.dll`), SnagIt capture, MDI-window management, About/order box.

## 2. Feature list (parity target)

Grouped as the ATB 3I menu groups them. "Cards" is what each screen edits in the deck.

| # | Screen (ATB 3I title) | Cards | Shape | Notes for the rebuild |
|---|---|---|---|---|
| **File** | | | | |
| 1 | New / Open / Save / Save As (`.lin`) | all | menu | Byte-exact round trip of an unedited deck is the acceptance test. |
| 2 | Convert `.ain` → `.lin` | — | menu | Solver mode 102; the app never parses `.ain` itself. |
| 3 | Run ATB (`.lin`) | — | menu + progress | Solver in a per-run temp dir, stdin-fed, async with cancel; outputs listed at the end. Existing `SolverRun.cs`. |
| **Run control** | | | | |
| 4 | Run Control (units, gravity, integrator, output interval) | A.1, A.3, A.4 | form (16 fields) | |
| 5 | General / Diagnostic Output Control Parameters | A.5 | grid (36 NPRT flags, 2 categories) | Flag names from the `A5Defination` table. |
| **Model** | | | | |
| 6 | Body Summary (insert/copy/replace/delete whole bodies) | B.1–B.6 | list + buttons | Renumbers segment/joint IDs and every card that references them. |
| 7 | GEBOD V.2 + 32 Body Dimensions | B.2–B.5 | form | Shell `Gebodv.exe`; **needs a client decision** (see risks). |
| 8 | Segment Definition | B.2, B.6 | grid, 2 tabs | |
| 9 | Joint Definition | B.3, B.4, B.5 | grid, 4 tabs | |
| 10 | Vehicle Motion + 4 sub-editors (half-sine, unidirectional, 6-DOF, spline P/V/A) | C.1–C.5 | list + 4 forms, grids, plot | One form per variant. |
| 11 | Symmetry Condition | D.7 | grid | |
| **Definition** | | | | |
| 12 | Contact Plane Definition | D.2 | grid | Renumbers plane references. |
| 13 | Contact Ellipsoid Definition | D.5 | grid | |
| 14 | Constraint Definition | D.6 | grid | |
| 15 | Spring Damper Definition | D.8 | grid | |
| 16 | Applied Force/Torque Definition | D.9 | grid | |
| 17 | Force Deflection Function Definition + editor (constant / polynomial / tabular) | E.1–E.4 | list → form + grid + plot | |
| 18 | Wind Force Function Definition + time history | E.6 | list → grid | |
| 19 | Joint Stiffness Function Definition + editor | E.7 | list → grid + plot | |
| 20 | Plane/Segment Contact | F.1.b | grid | |
| 21 | Segment/Segment Contact | F.3.b | grid | |
| 22 | Globalgraphic Joint Definition | F.4.b | grid | |
| 23 | Wind Force Contact Definition (+ blocking segment) | F.7.b, F.7.c | list → grid | |
| 24 | Harness Belt Definition (+ belt points) | F.8 | list → grid | |
| 25 | Joint Actuator Definition | F.10 | grid | |
| **Analysis** | | | | |
| 26 | Velocity Data Source | G.1 | grid | |
| 27 | Reference Segment Initial Position and Velocity | G.2 | grid | |
| 28 | Segment Initial Rotation and Angular Velocity | G.3.a | grid | |
| 29 | Weight Balancing (setup wizard + 3D pose check + write back to G.2/G.3.a) | G.2, G.3.a | wizard + viewer | Solver mode 99 + positional `balance.pos`/`balance.res`. |
| **Output** | | | | |
| 30 | Linear Acceleration / Velocity / Position Output | H.1–H.3 | grid | |
| 31 | Angular Acceleration / Velocity / Position Output | H.4–H.6 | grid | |
| 32 | Joint Parameter / Actuator Output | H.7, H.11 | grid | |
| 33 | Wind Force Time History Output | H.8 | grid | |
| 34 | Joint Forces/Torques Output | H.9 | grid | |
| 35 | Total Body Definition (+ segments in body) | H.10 | list → grid | |
| 36 | HIC and CSI Definition | H.12 | form + grid | Only when NPRT(4) enables it. |
| **View** | | | | |
| 37 | Animation (`.sa1`): play/pause/step/speed, per-object show/hide + colour, planes, contact ellipsoids, belts, segment-mounted camera, view-all | — | 3D viewer | |
| 38 | Maximum Value List | — | read-only grid | Solver limits from the `Setting` table. Read-only: raising limits is excluded. |

37 user-facing screens after dropping the license, About, and SnagIt dialogs. 28 of the grids are
instances of one generic grid screen in ATB 3I and stay that way here.

## 3. Stack decision

**WinForms on .NET 8, one solution `app/Atb.sln`:**

- `Atb.Core` (`net8.0`, no UI, no DB) — the deck model, the `.sa1` model, card schema, validation.
  Runs and is tested on macOS.
- `Atb.App` (`net8.0-windows`, WinForms; WPF `Viewport3D` hosted for the 3D view) — screens, run
  action, viewer. Cross-compiles on macOS, runs on Windows; UI smoke-tested on the `windows-2022`
  runner and by the client on real machines.
- `Atb.Core.Tests` (xunit) — round-trip and parser tests over the 12 client cases + vendor samples.

Why WinForms: ATB 3I is a WinForms grid app, so parity is a `DataGridView` per card and nothing
else. No third-party grid, chart, or 3D library: `DataGridView`, a small painted chart, and WPF's
built-in z-buffered `Viewport3D` cover the 30-ellipsoid scenes here. Installer: Inno Setup on the
runner, one self-contained x64 exe plus the solver.

Lazier alternative, not taken: Avalonia would run on the Mac too, but the client's machines are
Windows and nothing from the WinForms layout knowledge would carry over.

**Data model: the deck is the document.** `Deck` is the ordered list of `.LIN` lines, each a token
list plus its `CARD x.y` label; untouched lines are written back byte-for-byte, edited lines in the
canonical 4-space layout. Screens are typed views over the lines for their card. No database, no
`FileID`, no per-file table copies. The ID-renumbering cascades that ATB 3I ran as SQL become one
function over the deck (change segment N → fix every card that names N), tested in `Atb.Core`.

Not taken: an in-memory SQLite copy of the Access schema. It would let the original cascade SQL port
nearly verbatim, but it keeps two representations of the document in sync and the byte-exact
round-trip guarantee would be lost.

## 4. Acceptance (ships in `ACCEPTANCE.md` as Tier 2 items)

1. Open → Save of each of the 12 client decks reproduces the file byte-for-byte.
2. Each editor screen shows the same rows/columns as ATB 3I for the same deck, and an edit made in
   the screen appears on the expected card in the saved `.LIN`.
3. Run produces the same `.aou`/`.sa1`/`.t2x` set as running the solver by hand on that deck, and the
   verification harness accepts them.
4. The animation viewer opens every client `.sa1` (17 segments, 401 frames for 2479) and plays it
   with planes, contact ellipsoids, and belts where present.
5. Installer installs and launches on a clean Windows 10/11 x64 machine.

## 5. Risks, ranked

1. **GEBOD.** No Fortran source; the only artifacts are a .NET 1.x assembly and a 2000-era console
   exe. Plan: shell `Gebodv.exe` and parse its body deck. Fallback: leave GEBOD as "import a GEBOD
   deck" and flag it to the client. Needs a client answer on how often it's used.
2. **ID renumbering.** ATB 3I's `ATBUpdate` touches ~20 tables when a segment, joint, plane, or
   vehicle is inserted/deleted. Reproducing the reference map exactly is the largest single piece of
   logic. Mitigation: build the reference map once from the user guide, test on the client decks.
3. **3D viewer.** Complete rewrite off Open Inventor. Ellipsoids, planes, belts, camera are all
   simple; the risk is fidelity of the camera model and superquadric ("power") ellipsoids.
4. **Balance.** Positional `balance.pos`/`balance.res` formats are only documented by the decompile.
   Schedule last; verify against the XP VM.
5. **Deck labelling.** ATB 3I emits `CARD H.1.a` for empty H.2.a/H.3.a rows and hand-written vendor
   decks have no labels at all. A grammar-driven labeler is needed before unlabelled decks can be
   edited (labelled client decks already round-trip).
6. **Solver limits.** Reading `Setting` is display only, same as ATB 3I; the solver itself is the
   enforcement.

## 6. Schedule against the 2–3 week quote

Week 1: core model, schema for every card, generic grid screen, open/save/run, viewer. Week 2: the
special screens (Body, Vehicle, function editors, HIC), renumbering, installer. Week 3: GEBOD,
Balance, client test round. `LANE.md` holds the executable item list.
