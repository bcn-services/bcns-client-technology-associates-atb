# Project Standards

## Card schema
- **Schema marks drive every rewrite**: code that changes references (Renumber) touches only fields whose CardSchema kind is g/j/p/e/a; a missing reference is fixed by adding the mark in CardSchema.cs, never by detecting it heuristically.
- **Cite the source for each mark**: a new or changed field kind carries a comment naming the ATB 3I decomp file or the Fortran `src/*.for:line` that proves it (e.g. H.9 → heding_joint_forces.for:51).
- **Signed refs**: the H.1–H.8 Segment / Segment-or-Joint / H.7 Joint fields can be negative (the solver uses ABS and branches on the sign); compare those on |v| and preserve the sign. Ref Segment, H.9 joint and H.10.B are compared signed.

## Deck editing
- **Delete outcome matches the solver's read**: for each ref a delete clears or drops, check the result against the `src/*.for` read — a count-led list whose Count hits 0 is removed or blocked when the solver requires >= 1 (H.10.B drops with H.10.C; H.11 STOP 741), and a blanked 0 is only valid where the solver guards SEG(0).
- **Byte-for-byte round-trip**: mutate lines through DeckLine.SetTokens / Set*, which clear Raw only when a token changes; untouched lines must write back byte-identical.
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
- **GEBOD Replace joint positions**: 3I's `Body.DeleteBody` counts a non-last body's joints as segments a..b (the next body's NULL joint, not its own a-1) while `GEBOD.cs:1766-1800` bases the update list on a-1, so a reference to the next body's NULL joint is left naming a GEBOD joint. GebodMerge counts body k's joints as its own NULL joint a-1 then a..b-1 (body 1: 1..b-1), so joint *i* of the old body maps to joint *i* of the new one and the next body's NULL joint moves with the difference.

## Body structure
- **Body boundaries are NULL joints**: a body starts at segment 1 and at J+1 for each joint J with Seg JNT 0 (`src/Chain.for:38-43`); NJNT = NSEG-1 with no flexible bodies; G.2 has one row per reference segment (`src/input_linear.for:66-70`). Used by GebodMerge.BodyStarts.
- **Merged rows carry their own numbering**: an imported body's body-relative refs (GEBOD Seg JNT) are mapped to deck numbers when its rows are built; every ref already in the deck moves only through Renumber.Insert/Delete.
- **GEBOD Replace is by position** (3I `GEBOD.cs:1766-1800`, `ATBUpdate.UpdateOtherTable`): a reference to old segment/joint *i* of the body names the new body's *i*-th; surplus old positions go through Renumber.Delete, extra new ones through Renumber.Insert, and only references to surplus positions are dropped (`GebodMerge.ReplacedReferences`).
