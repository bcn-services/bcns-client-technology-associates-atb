# Handoff plan — ATB desktop app (Tier 2)

Rule for every open design choice: copy ATB 3I. Kept extras (3I has none of them): output-card (H.1–H.9) renumbering,
H.11 actuator fix, the warning before saving a broken deck. Scope list: `docs/TIER2-SCOPE.md` §2.

## Test material

- `cases/` — 12 decks with reference results. The Windows solver check and the robot use these.
- `corpus/` — 127 more client decks (`.LIN` only, from the client's `ATB_Examples`, 2026-09-13). The Mac tests
  check open → save, schema, labels and copy/paste on every one (1151 tests).
- `~/atb/ATB_Examples/` — the full set with results (`.aou`, `.sa1`, 788 MB). Not in git. Use it for the VM pass.

## Steps

### 1. Scope and client questions — you, ~30 min, now
- [ ] Send him the 38-screen list (not the app). Ask: "Is this everything you use? How often do you use GEBOD?"
- [ ] Ask him for one Weight Balancing run from his XP machine: the `.LIN`, `balance.pos`, `balance.res`.
- [ ] Optional: ask for screenshots of 3I's screens with `2479_2.LIN` open.
- [ ] Say yes to pushing `tier2-app` (not `main`), so the Windows build and tests run on it.

**You verify:** his reply names no screen missing from the list.

### 2. Build round 2 — Claude, unattended (`/dev-team-auto`)
1. GEBOD Replace: shift the old body's references by position, as 3I does (`ATBUpdate.cs:326-351`).
2. Maximum Value List (read-only grid).
3. Body Summary screen.
4. Vehicle Motion list and its 4 sub-editors.
5. Function editors (force-deflection, joint stiffness, wind force) with plots.
6. HIC/CSI screen, Run Control form, output-control grids.
7. Installer: one setup `.exe` with the app and the solver.
8. Robot: a scenario per new screen, plus one deck from each new `corpus/` folder.

**You verify:** the run summary shows each item `done`. Every robot screenshot sits beside the matching 3I screen
(`TIER2-SCOPE.md` row). The Windows run is green.

### 3. Your Windows pass #1 — you, ~1 hr setup + ~1 hr checks
- [ ] Set up the UTM VM (`LANE_PROGRESS.md` → "Windows VM click-through").
- [ ] Install with the new setup `.exe`, as a **standard** (non-admin) user.
- [ ] Walk the 11-item checklist in `LANE_PROGRESS.md`, plus one pass through each new screen.
- [ ] Open 3 decks the robot never opens (e.g. `2645`, `2463`, `2313_HIGH_250_1` from `~/atb/ATB_Examples`). Run
      each. Open its `.sa1` in the viewer.
- [ ] Optional: install `~/atb-work/p0/ATBV3_msi.exe` (original 3I) in the same VM. If it runs, compare screens side
      by side.

**You verify:** each box ticked; screenshot anything odd and send it to Claude.

### 4. ▶ Send him the first draft — when all of these hold
- Every scope screen except Weight Balancing is built.
- The Windows robot run is green.
- Your pass #1 found no blocker (a crash, a wrong save, a run that fails).
- The installer works for a standard user on your clean VM.

Send: the setup `.exe`, and a one-page note. The note says: draft for review, what's in it, that Weight Balancing is
still missing, the 3 kept extras, and "try it on your own decks, send any deck that misbehaves".

### 5. Draft feedback and Weight Balancing — Claude
- Fix what he reports; each reported deck goes into `corpus/` as a test.
- Build Weight Balancing from his sample.

### 6. Final — you
- [ ] Windows pass #2 with the full checklist and 3 decks not used in pass #1.
- [ ] `ACCEPTANCE.md` Tier 2 items all checked.
- [ ] Send the final installer.
