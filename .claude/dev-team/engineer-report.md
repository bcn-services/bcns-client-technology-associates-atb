# Engineer Report
**Task:** Run Control form (§2 #4) — A.1/A.3/A.4, 16 fields, copying 3I RunControl.cs; Analysis > Run Control...
**Branch:** r2-s3c
**Date:** 2026-09-28

Commit: 5257158 (code) — macOS gate 1283 passed / 0 failed (baseline 1276, +7)
Windows filtered (RunControlEditSave): https://github.com/bcn-services/bcns-client-technology-associates-atb/actions/runs/36496867754 — green, 1/1, 7 PNGs read
Windows full: https://github.com/bcn-services/bcns-client-technology-associates-atb/actions/runs/36497390376 — green, 49/49 (was 48), tokendiff + cross gates green
Mutations (cp-backed, restored cmp-identical): M_a Read keeps quotes -> RED BoxesReadTheirTokens_2479 + EveryDeckOpensAndUneditedSaveChangesZeroBytes; M_b A.4 writes token+1 -> RED OneBoxEditRewritesOnlyItsToken(7) + EveryDeckOpens...ZeroBytes

## Design Decisions
- Core `RunControl.Fields` = 3I Textbox1..16 order -> (card, token); Read/Set go through `Deck.Edit`, which leaves a line's Raw untouched when the token is unchanged, so unedited OK is zero bytes.
- Form follows the VehEditor pattern: working copy, each box writes its token on Leave (3I number check on boxes 7-16), OK keeps / Cancel drops; modal, not MDI (existing STANDARDS entry).
- Layout copied from 3I InitializeComponent coordinates (664x325, Arial 8.25 bold, four 320x72 groups, Default/OK/Cancel at y 288).
- Analysis menu added after Model, as 3I's top-menu order (Environment/Output not built yet).

## Files Changed
- `app/Atb.Core/Cards/RunControl.cs` — new: field map, Read, Set, Defaults(today)
- `app/Atb.Core.Tests/RunControlTests.cs` — new: literal mapping on 2479_2, zero-byte unedited save over all 139 cases/+corpus decks, one-box edit = one line/one token (3 literal cases), number refusal, Default literals
- `app/Atb.App/RunControlForm.cs` — new: the 3I form
- `app/Atb.App/MainForm.cs` — Analysis > Run Control... wiring; missing A card -> message instead of crash
- `app/Atb.App.UiTests/Scenarios.cs` — `RunControlEditSave`: unedited OK+Save byte compare, then Num of Output 2000->2500, line diff == [4], token diff == [1], literal A.4 line
- `STANDARDS.md` — divergence: whole-number boxes refuse decimals; form needs labelled A cards

## Deferred / Out of Scope
- Vendor sample decks (`A.1b`/`A.1c` labels) are refused with a message until relabelled; not in done-when (cases/ only).
- 3I disables the menu item until a file is open; ours is enabled and does nothing without a deck (same as Vehicle Motion / Function).
- No robot mutation run (core mutations cover the mapping; robot asserts written-out literals).

## Flags for Reviewer
- Keyboard Enter does not trigger OK (no AcceptButton, as 3I), so Leave always fires before OK's click.
- Default writes all 16 tokens with DateTime.Now's date (3I DateAndTime.DateString, MM-dd-yyyy); not robot-exercised.
