# Project Standards

## Card schema
- **Schema marks drive every rewrite**: code that changes references (Renumber) touches only fields whose CardSchema kind is g/j/p/e/a; a missing reference is fixed by adding the mark in CardSchema.cs, never by detecting it heuristically.
- **Cite the source for each mark**: a new or changed field kind carries a comment naming the ATB 3I decomp file or the Fortran `src/*.for:line` that proves it (e.g. H.9 → heding_joint_forces.for:51).
- **Signed refs**: the H.1–H.8 Segment / Segment-or-Joint / H.7 Joint fields can be negative (the solver uses ABS and branches on the sign); compare those on |v| and preserve the sign. Ref Segment, H.9 joint and H.10.B are compared signed.

## Deck editing
- **Delete outcome matches the solver's read**: for each ref a delete clears or drops, check the result against the `src/*.for` read — a count-led list whose Count hits 0 is removed or blocked when the solver requires >= 1 (H.10.B drops with H.10.C; H.11 STOP 741), and a blanked 0 is only valid where the solver guards SEG(0).
- **Byte-for-byte round-trip**: mutate lines through DeckLine.SetTokens / Set*, which clear Raw only when a token changes; untouched lines must write back byte-identical.
- **Per-entity card families are positional**: `Renumber.Owned` / `Deck.Rows` give entity n the n-th row of each group (B.2/B.6/G.3.A per segment, B.3/B.4/B.5 per joint), so a family missing in the middle is invisible. Whole-body ops that copy or place entities check each family's row count is 0 or the entity count before touching the deck.
- **Core stays UI-free**: Atb.Core takes a confirm callback (e.g. `Func<IReadOnlyList<RefSite>, bool>`) for any destructive step; MainForm supplies the MessageBox. Decline = no mutation.

## Tests
- **Fixture literals**: renumbering tests assert written-out token lines from `cases/2479/2479_2.LIN` (Python oracle or hand-checked), plus File.ReadAllBytes for round-trips — never values computed by Atb.Core helpers.

## ATB 3I divergences
Renumber follows ATB 3I `ATB3I.Util/ATBUpdate.cs` except where 3I leaves a reference stale or breaks the deck:
- **H cards are renumbered**: 3I never touches the H tables (`ATBUpdate.cs:203-308`); Renumber shifts, clears or drops H.1–H.11 refs so output selections keep pointing at the same segment/joint/actuator.
- **H.11 actuators**: marked `a` (ActRef) = F.10 position. Deleting an F.10 row (directly or by the joint/segment cascade) drops it from H.11, shifts later actuators down and decrements Count; with NRTORQ = 0 the H.11 line is removed (read only when NRTORQ > 0, `input_h11_cards.for:33`). Compared on |v| (`heding_actuators.for:70-71`).
- **F.2.B BeltID is not compacted**: 3I's `resetRID: "BeltID"` (`ATBUpdate.cs:237`) would renumber belts after a cascade delete, but the solver stops unless NJ = belt ordinal (`input_belt_force.for:109`). Other `resetRID` columns (RID, ActuatorID) are row order, which the deck keeps anyway.
- **Not deck tokens**: D4aD4f/F6 `AirbagID` (D.4.a has no id, `FileManager.cs:1493`; F.6 writes the ordinal, `FileManager.cs:1778`) and F9m `Output SeqID` are 3I database keys; nothing in the .LIN to mark.
- **D.6 is one line per constraint** for every Type (`input_contraints.for:29-30`).
- **GEBOD Replace, body 1 of a multi-body deck**: 3I's joint count for body 1 includes the next body's NULL joint (`Body.DeleteBody` removes joints 1..b-1, b = body 2's first segment; the new count NSEGS includes the NULL GEBOD re-adds at NSEGS, `GEBOD.cs:2407-2413`), while selJnt = 0 puts the surplus base at 0 (`GEBOD.cs:1797`). So a shorter body 1 drops refs to old joints sn+1..so, including the next body's NULL joint, and keeps a ref to old joint sn, which then names the new root NULL joint. GebodMerge maps old joint *i* to new joint *i* (surplus sn..so-1) and moves the next body's NULL joint with the difference. Later bodies and a single body match 3I.
- **Copied bodies carry their own references**: 3I's `InsertBody` / Replace paste the copied B2B6M / B3B4B5M rows with their Seg JNT (and other segment numbers) unchanged, so a copy's joints still name the original body. `Bodies.Insert` / `Bodies.Replace` point every segment number inside the copy at the copy (`Renumber.Remap`), and the copy carries its G.3.A rows too (3I leaves them out: the new segments get none).
- **Body Summary's GEBOD buttons ask once**: Body.cs:990/:1019/:1049 is the only confirmation; the GEBOD form opens with the placement fixed (its placement row hidden) and does not ask :1049 again.

## Body structure
- **Body boundaries are NULL joints**: a body starts at segment 1 and at J+1 for each joint J with Seg JNT 0 (`src/Chain.for:38-43`); NJNT = NSEG-1 with no flexible bodies; G.2 has one row per reference segment (`src/input_linear.for:66-70`). Used by GebodMerge.BodyStarts.
- **Merged rows carry their own numbering**: an imported body's body-relative refs (GEBOD Seg JNT) are mapped to deck numbers when its rows are built; every ref already in the deck moves only through Renumber.Insert/Delete.
- **GEBOD Replace is by position** (3I `GEBOD.cs:1766-1800`, `ATBUpdate.UpdateOtherTable`): a reference to old segment/joint *i* of the body names the new body's *i*-th; surplus old positions go through Renumber.Delete, extra new ones through Renumber.Insert, and only references to surplus positions are dropped (`GebodMerge.ReplacedReferences`), without a dialog, as 3I.
