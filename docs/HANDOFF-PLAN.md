# Handoff plan — ATB desktop app (Tier 2), session by session

Plain-English guide to the app, the words used here, and the 38 screens:
https://claude.ai/code/artifact/68f2cb71-bb35-42b3-bbfb-03417ed56cdd

Each **session** below is one fresh Claude Code window. Start it in `~/bcns-client-technology-associates-atb`, paste
that session's kickoff prompt, and let it run to its exit check. "You" = Nate. Scope list: `docs/TIER2-SCOPE.md` §2.

## Decisions already made (sessions must not re-ask)

- **Copy ATB 3I exactly** for every design choice. The decomp is `~/atb-work/p0/decomp/ATB3I/`; its data tables are
  in `~/atb-work/p0/msi/General Dynamics/ATB3I/ATB3iData.mdb` (read with `mdb-export`).
- **Kept extras** (3I has none; keep unless Nate says "revert"): output-card (H.1–H.9) renumbering, the H.11 actuator
  fix, the warning before saving a broken deck.
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
  4. `C:\ATBFIG.SYS`: 3I's installer ran as admin. Our installer asks for admin once and writes that file (work
     folder under `C:\Users\Public\ATBRun`, format pinned by `GebodTests.AtbFig_MatchesInstallerLayout`); the app
     stops writing `C:\` itself. This replaces the old "no admin" installer guardrail.
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

## S0 — You: client email (~30 min, now)

- [ ] Send him the 38-screen list (not the app). Ask: "Is this everything you use? How often do you use GEBOD?"
- [ ] Ask for one Weight Balancing run from his XP machine: the `.LIN`, `balance.pos`, `balance.res`.
- [ ] Optional: screenshots of 3I's screens with `2479_2.LIN` open.

**Exit:** email sent. S1–S4 don't wait for his reply; S8 needs the Weight Balancing files.

## S1 — Claude: round-2 contract + GEBOD Replace, Body Summary, Max Value List

Kickoff prompt:
> Work in ~/bcns-client-technology-associates-atb on branch tier2-app. Read docs/HANDOFF-PLAN.md and do session S1
> exactly as written. Follow its "Decisions already made" and "Rules for every Claude session".

Steps:
1. Archive rounds 1 and 1b into `LANE_PROGRESS.md`, then replace `LANE.md` wholesale for round 2 (lane-md schema).
   - Objective: every screen in `TIER2-SCOPE.md` §2 except Weight Balancing matches ATB 3I, plus a working installer.
   - Global rules: carry the current ones; add the Decisions section above as rules.
   - Items, in this order — S1: GEBOD Replace parity (`caution: true`), lone-segment insert warning (decision 2),
     Body Summary #6 (`caution: true`), Maximum Value List #38. S2: Vehicle Motion + 4 sub-editors
     (`caution: true`), function editors + plots. S3: Run Control, Output Control grids, HIC/CSI. S4: installer,
     robot sweep. Reuse the guardrails / done-when already written below the old marker; add a robot scenario
     done-when to each screen item.
   - STOP marker right after the S1 items. Weight Balancing stays under "Not yet specified".
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

## S4 — Claude: installer + full robot sweep

Kickoff prompt:
> Work in ~/bcns-client-technology-associates-atb on branch tier2-app. Read docs/HANDOFF-PLAN.md and do session S4
> exactly as written.

Steps:
1. Move the marker below the S4 items; run `/dev-team-auto`.
2. Installer: Inno Setup on `windows-2022`, one unsigned setup `.exe` with the self-contained x64 app,
   `atb-win32.exe`, `Gebodv.exe` + `GEBOD.DAT`. Asks for admin once and writes `C:\ATBFIG.SYS` (decision 4).
   Original for comparison: `~/atb-work/p0/ATBV3_msi.exe`.
3. Robot: install with the setup `.exe` on the runner, then run every scenario against the installed app, plus
   open-save one deck from each `corpus/` folder.
4. Windows gate; download the setup `.exe` to `~/atb/dist/`.

**Exit:** green run from the installed app; `~/atb/dist/ATB-setup.exe` exists.

## S5 — You + Claude: Windows VM pass #1 (~1 hr setup + ~1 hr checks)

Kickoff prompt:
> Work in ~/bcns-client-technology-associates-atb on branch tier2-app. Read docs/HANDOFF-PLAN.md, session S5. I am
> doing the VM pass now; walk me through it one step at a time and fix any blocker I report in this session.

- [ ] Set up the UTM VM (`LANE_PROGRESS.md` → "Windows VM click-through").
- [ ] Log in as a **standard** (non-admin) user. Run `~/atb/dist/ATB-setup.exe`; enter the admin password once when
      asked.
- [ ] Walk the 11-item checklist in `LANE_PROGRESS.md`, plus one pass through each new screen.
- [ ] Tools > GEBOD works as the standard user.
- [ ] Open, run and view 3 decks the robot never opens: `2645`, `2463`, `2313_HIGH_250_1` from `~/atb/ATB_Examples`.
- [ ] Optional: install `~/atb-work/p0/ATBV3_msi.exe` in the same VM and compare screens side by side.

**Exit:** every box ticked, no blocker (crash, wrong save, failed run) left open. Claude re-runs both gates after any
fix.

## S6 — Claude drafts, you send: first draft

Kickoff prompt:
> Work in ~/bcns-client-technology-associates-atb on branch tier2-app. Read docs/HANDOFF-PLAN.md and do session S6.

Claude:
1. Checks the draft gate and reports each line: every scope screen but Weight Balancing is built; latest Windows run
   green; S5 left no blocker; the installer worked for a standard user.
2. Writes `docs/CLIENT-NOTE-DRAFT.md` (one page, plain words): this is a draft for review; what's in it; Weight
   Balancing is still coming; the 3 kept extras; SmartScreen will warn — click "More info → Run anyway"; the
   installer asks for an admin password once; try it on your own decks and send any deck that misbehaves.

You:
- [ ] Upload `~/atb/dist/ATB-setup.exe` to Google Drive, share as "Anyone with the link".
- [ ] Email him the link with the note.

## S7 — Claude: draft feedback (repeat per batch of feedback)

Kickoff prompt:
> Work in ~/bcns-client-technology-associates-atb on branch tier2-app. Read docs/HANDOFF-PLAN.md, session S7. Here is
> the client's feedback: <paste>. Decks he sent are in <folder>.

Steps: each reported deck goes into `corpus/<name>/` as a test; turn each report into a `LANE.md` item above the
marker; run `/dev-team-auto`; both gates. Anything that conflicts with 3I parity goes back to Nate as a question.

## S8 — Claude: Weight Balancing (needs his sample from S0)

Kickoff prompt:
> Work in ~/bcns-client-technology-associates-atb on branch tier2-app. Read docs/HANDOFF-PLAN.md and do session S8.
> The Weight Balancing sample is in <folder>.

Steps: copy the sample into `corpus/balance/`; write the item (screen #29, solver mode 99, `balance.pos` /
`balance.res`) from `Balance.cs` and `ToBalance.cs`; done-when includes reproducing his `balance.res` from his
`.LIN`; `/dev-team-auto`; both gates; rebuild the installer.

## S9 — You + Claude: final

Kickoff prompt:
> Work in ~/bcns-client-technology-associates-atb on branch tier2-app. Read docs/HANDOFF-PLAN.md, session S9. Walk me
> through the final VM pass and finish the release.

- [ ] VM pass #2: fresh VM snapshot, full checklist, 3 decks not used in S5.
- [ ] Claude adds the 5 Tier 2 tests from `TIER2-SCOPE.md` §4 to `ACCEPTANCE.md` and ticks each with evidence.
- [ ] Claude builds the final installer and updates PR #3's description.
- [ ] You merge: `! GITHUB_TOKEN= gh pr merge 3`. Upload the final `.exe` to Drive and email him the link.

## Test material

- `cases/` — 12 decks with reference results (solver check + robot).
- `corpus/` — 127 more client decks (`.LIN` only); Mac tests open, save, label and copy/paste every one.
- `~/atb/ATB_Examples/` — the full set with results (788 MB, not in git). VM passes pick decks from here.
