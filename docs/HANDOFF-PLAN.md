# Handoff plan — ATB desktop app (Tier 2), session by session

Plain-English guide to the app, the words used here, and the 38 screens:
https://claude.ai/code/artifact/68f2cb71-bb35-42b3-bbfb-03417ed56cdd

Each **session** below is one fresh Claude Code window. Start it in `~/bcns-client-technology-associates-atb`, paste
that session's kickoff prompt, and let it run to its exit check. "You" = Nate. Scope list: `docs/TIER2-SCOPE.md` §2.

## Decisions already made (sessions must not re-ask)

The client delegated every decision to Nate (2026-09-14). Nate's answers:

- **v1 = everything ATB 3I does.** All 38 screens, Weight Balancing included, before anything goes to the client.
  He tests v1, then sends the changes he wants; those change rounds come after v1.
- **Copy ATB 3I exactly** for every v1 design choice. Decomp: `~/atb-work/p0/decomp/ATB3I/`. Data tables:
  `~/atb-work/p0/msi/General Dynamics/ATB3I/ATB3iData.mdb` (read with `mdb-export`). After v1, his requests win over
  3I.
- **Kept extras** (3I has none; keep unless Nate says "revert"): output-card (H.1–H.9) renumbering, the H.11 actuator
  fix, the warning before saving a broken deck.
- **GEBOD:** full 3I behaviour, Replace included. The installer asks for an admin password once and writes
  `C:\ATBFIG.SYS`, as 3I's installer did (work folder `C:\Users\Public\ATBRun`, format pinned by
  `GebodTests.AtbFig_MatchesInstallerLayout`). The app stops writing `C:\` itself.
- **Weight Balancing uses the client's original solver.** Our solver source (`src/`) has no balance code; 3I's own
  `ATBV3.exe`, committed as `frontend/bin/ATBV3_ATB3I.exe` (exe B in `frontend/FIDELITY.md`), does. Ship exe B and
  use it only for Weight Balancing; every other run keeps using our `atb-win32.exe`. How 3I drives it:
  - Feed: 3I's handoff — `C:\ATBFIG.SYS` names the handoff folder; the deck goes there as `winintm.sys`, and
    `EXECATB.DAT` holds the single line `99`. No prompts, no arguments. `SolverRun` already has `FeedMode.Handoff`;
    `FIDELITY.md` gate 3 shows exe B passing all 12 cases this way on `windows-2022`.
  - Deck: written with NPRT(33) = 1 for the setup run, 2 for the balance run; on run 2 the balanced body's G.2 /
    G.3.a carry the pose being tested (`FileManager.cs:1186`, `:2044-2066`).
  - Results: `balance.run` present = success (else point at `ATBDEBUG.TXT`); `balance.pos` and `balance.res` are
    plain streams of numbers read by position (`Balance.cs:776-820`, `:1264-1314`, `:1465-1501`).
  - The pose math (rotate / translate a segment, joint-chain angles) is in the app, not the solver:
    `Balance.cs:3194-3304` `FindAngle()`. OK writes G.2 and G.3.a (`Balance.cs:1590-1643`).
- **Push:** pushing `tier2-app` is approved. Never push `main`, never force-push, never merge the PR (Nate runs
  `! GITHUB_TOKEN= gh pr merge`). Use `GITHUB_TOKEN= gh` for every `gh` call.
- **Installer:** unsigned. The client note tells him Windows SmartScreen will warn: "More info → Run anyway".
- **Delivery:** Nate uploads the setup `.exe` to Google Drive and emails the client the link (too big to attach).
- **Open questions from round 1b (`LANE_PROGRESS.md` Blockers), settled by the copy-3I rule:**
  1. File > New keeps 3I's 0 time steps.
  2. Inserting a lone segment: do as 3I — show its cascade warning (`TableForm.cs:412`, "You have
     inserted/deleted segments … Continue?"), insert the segment alone, add no joint, add no joint-count check.
     The solver's STOP 24 on such a deck is 3I's behaviour too.
  3. GEBOD Replace: point references at the new body by position, as 3I (`ATBUpdate.cs:326-351`).
  4. `C:\ATBFIG.SYS`: written once by the installer (see GEBOD above).
  5. Follow camera stays on the torso, as 3I.
  6. Lane goal 2 is reworded: the robot compares the app's run with a direct solver run on the same machine.
  7. Labeler: one mislabelled H.1.a row (not three); "Z up" means 3I's default view; D.4 has no segment reference.

## Rules for every Claude session

- Before editing `LANE.md` / `LANE_PROGRESS.md`, read `~/os/knowledge/frameworks/lane-md.md` and `progress-md.md`.
- Build with `/dev-team-auto`. It stops at the `⚠️ AUTONOMOUS RUN — STOP HERE` marker; a session moves the marker to
  just below its own items and nowhere further.
- macOS gate: `PATH="$HOME/atb-work/dotnet:$PATH" dotnet test app/Atb.sln` — all pass (1151 today).
- Windows gate: push `tier2-app`, `GITHUB_TOKEN= gh workflow run app-e2e.yml --ref tier2-app`, block on
  `gh run watch`, then `gh run download` and look at every new screenshot. Each new screen gets a robot scenario in
  the same session that builds it.
- End every session: commit, push `tier2-app`, update `LANE_PROGRESS.md` → "Current position", and print the next
  session's name.

---

## S1 — Claude: round-2 contract + GEBOD Replace, Body Summary, Max Value List

Kickoff prompt:
> Work in ~/bcns-client-technology-associates-atb on branch tier2-app. Read docs/HANDOFF-PLAN.md and do session S1
> exactly as written. Follow its "Decisions already made" and "Rules for every Claude session".

Steps:
1. Archive rounds 1 and 1b into `LANE_PROGRESS.md`, then replace `LANE.md` wholesale for round 2 (lane-md schema).
   - Objective: every screen in `TIER2-SCOPE.md` §2, Weight Balancing included, matches ATB 3I, plus a working
     installer — v1.
   - Global rules: carry the current ones; add the Decisions section above as rules.
   - Items, in this order —
     - S1: GEBOD Replace parity (`caution: true`), lone-segment insert warning (decision 2), Body Summary #6
       (`caution: true`), Maximum Value List #38.
     - S2: Vehicle Motion + 4 sub-editors (`caution: true`), function editors + plots.
     - S3: Run Control, Output Control grids, HIC/CSI.
     - S4: Weight Balancing probe, then Weight Balancing screens (`caution: true`).
     - S5: installer, robot sweep.
   - Reuse the guardrails / done-when already written below the old marker, but drop the installer's "No
     admin-only paths" guardrail (see GEBOD decision). Add a robot-scenario done-when to each screen item.
   - STOP marker right after the S1 items. "Not yet specified" no longer lists Weight Balancing.
2. Commit the new `LANE.md`, then run `/dev-team-auto`.
3. Windows gate (see Rules).

Parity sources: `ATB3I.Util/ATBUpdate.cs:326-351`, `Body.cs`, `BdyDim.cs`, `TableForm.cs`; Max Value List =
the `Setting` table (`mdb-export ATB3iData.mdb Setting`), read-only.

**Exit:** S1 items `done`, macOS gate green, Windows run green.
**You check:** skim the summary; open 2–3 new screenshots from the run page. Nothing to click yet.

## S2 — Claude: Vehicle Motion + function editors

Kickoff prompt:
> Work in ~/bcns-client-technology-associates-atb on branch tier2-app. Read docs/HANDOFF-PLAN.md and do session S2
> exactly as written.

Steps: move the STOP marker below the S2 items; run `/dev-team-auto`; Windows gate.
Parity sources: `Vehicle.cs` (`VehicleType()`), `VehOpt1.cs`, `VehOpt2.cs`, `VehOpt34.cs`, `FDFData.cs`,
`JntFData.cs`, `Plots.cs`. Screens #10, #17, #18, #19.

**Exit / You check:** as S1.

## S3 — Claude: Run Control, Output Control, HIC/CSI

Kickoff prompt:
> Work in ~/bcns-client-technology-associates-atb on branch tier2-app. Read docs/HANDOFF-PLAN.md and do session S3
> exactly as written.

Steps: move the marker below the S3 items; run `/dev-team-auto`; Windows gate.
Parity sources: `RunControl.cs`, `HIC.cs` (enabled by NPRT(4)), Output Control names from the `A5Defination` table.
Screens #4, #5, #36.

**Exit / You check:** as S1.

## S4 — Claude: Weight Balancing

Kickoff prompt:
> Work in ~/bcns-client-technology-associates-atb on branch tier2-app. Read docs/HANDOFF-PLAN.md and do session S4
> exactly as written.

Steps:
1. **Probe first.** Add a robot step that runs exe B through the handoff with `99` in `EXECATB.DAT` on one
   `cases/` deck with a body (NPRT(33) = 1, then 2). Upload `balance.run`, `balance.pos`, `balance.res`,
   `ATBDEBUG.TXT`. Commit the outputs under `app/Atb.Core.Tests/fixtures/balance/` — they are the sample the
   client would have sent. If exe B won't produce them, stop and report to Nate; do not write balance code into
   `src/`.
2. Move the marker below the S4 items; run `/dev-team-auto`. Screens: the "Weight Balancing Setup" form (pick a
   body, contact-plane flags — `ToBalance.cs`) and "Body Weight Balancing" (rotate / translate a segment, angles,
   accelerations, forces, OK — `Balance.cs`), with the 3D pose shown in our existing viewer. Screen #29.
3. Done-when includes: the `.pos`/`.res` parsers read the probe fixtures on macOS; OK writes G.2 / G.3.a and every
   other line stays byte-exact; the robot runs the full wizard once on Windows.
4. Windows gate.

**Exit / You check:** as S1.

## S5 — Claude: installer + full robot sweep

Kickoff prompt:
> Work in ~/bcns-client-technology-associates-atb on branch tier2-app. Read docs/HANDOFF-PLAN.md and do session S5
> exactly as written.

Steps:
1. Move the marker below the S5 items; run `/dev-team-auto`.
2. Installer: Inno Setup on `windows-2022`, one unsigned setup `.exe` with the self-contained x64 app,
   `atb-win32.exe`, `ATBV3_ATB3I.exe` (Weight Balancing only), `Gebodv.exe` + `GEBOD.DAT`. Asks for admin once and
   writes `C:\ATBFIG.SYS`. Original for comparison: `~/atb-work/p0/ATBV3_msi.exe`.
3. Robot: install with the setup `.exe` on the runner, then run every scenario against the installed app, plus
   open-save one deck from each `corpus/` folder.
4. Windows gate; download the setup `.exe` to `~/atb/dist/`.

**Exit:** green run from the installed app; `~/atb/dist/ATB-setup.exe` exists.

## S6 — You + Claude: Windows VM pass #1 (~1 hr setup + ~1 hr checks)

Kickoff prompt:
> Work in ~/bcns-client-technology-associates-atb on branch tier2-app. Read docs/HANDOFF-PLAN.md, session S6. I am
> doing the VM pass now; walk me through it one step at a time and fix any blocker I report in this session.

- [ ] Set up the UTM VM (`LANE_PROGRESS.md` → "Windows VM click-through").
- [ ] Log in as a **standard** (non-admin) user. Run `~/atb/dist/ATB-setup.exe`; enter the admin password once when
      asked.
- [ ] Walk the 11-item checklist in `LANE_PROGRESS.md`, plus one pass through each new screen.
- [ ] Tools > GEBOD and Weight Balancing both work as the standard user.
- [ ] Open, run and view 3 decks the robot never opens: `2645`, `2463`, `2313_HIGH_250_1` from `~/atb/ATB_Examples`.
- [ ] Optional: install `~/atb-work/p0/ATBV3_msi.exe` in the same VM and compare screens side by side.

**Exit:** every box ticked, no blocker (crash, wrong save, failed run) left open. Claude re-runs both gates after any
fix.

## S7 — Claude drafts, you send: v1

Kickoff prompt:
> Work in ~/bcns-client-technology-associates-atb on branch tier2-app. Read docs/HANDOFF-PLAN.md and do session S7.

Claude:
1. Checks the v1 gate and reports each line: all 38 scope screens built; latest Windows run green; S6 left no
   blocker; the installer worked for a standard user.
2. Writes `docs/CLIENT-NOTE-V1.md` (one page, plain words): v1 does everything ATB 3I did; what's in it; the 3 kept
   extras; SmartScreen will warn — click "More info → Run anyway"; the installer asks for an admin password once;
   test it on your own decks, then send the list of changes you want and any deck that misbehaves.

You:
- [ ] Upload `~/atb/dist/ATB-setup.exe` to Google Drive, share as "Anyone with the link".
- [ ] Email him the link with the note.

## S8 — Claude: his change requests (repeat per batch)

Kickoff prompt:
> Work in ~/bcns-client-technology-associates-atb on branch tier2-app. Read docs/HANDOFF-PLAN.md, session S8. Here is
> the client's feedback: <paste>. Decks he sent are in <folder>.

Steps: each reported deck goes into `corpus/<name>/` as a test; turn each request into a `LANE.md` item above the
marker (his request wins over 3I parity now); run `/dev-team-auto`; both gates; rebuild the installer. A request that
is unclear or outside the quote goes back to Nate as a question.

## S9 — You + Claude: final

Kickoff prompt:
> Work in ~/bcns-client-technology-associates-atb on branch tier2-app. Read docs/HANDOFF-PLAN.md, session S9. Walk me
> through the final VM pass and finish the release.

- [ ] VM pass #2: fresh VM snapshot, full checklist, 3 decks not used in S6.
- [ ] Claude adds the 5 Tier 2 tests from `TIER2-SCOPE.md` §4 to `ACCEPTANCE.md` and ticks each with evidence.
- [ ] Claude builds the final installer and updates PR #3's description.
- [ ] You merge: `! GITHUB_TOKEN= gh pr merge 3`. Upload the final `.exe` to Drive and email him the link.

## Test material

- `cases/` — 12 decks with reference results (solver check + robot).
- `corpus/` — 127 more client decks (`.LIN` only); Mac tests open, save, label and copy/paste every one.
- `~/atb/ATB_Examples/` — the full set with results (788 MB, not in git). VM passes pick decks from here.
- `app/Atb.Core.Tests/fixtures/balance/` — Weight Balancing outputs from exe B (made in S4).
