# Project Standards

## Card schema
- **Schema marks drive every rewrite**: code that changes references (Renumber) touches only fields whose CardSchema kind is g/j/p/e; a missing reference is fixed by adding the mark in CardSchema.cs, never by detecting it heuristically.
- **Cite the source for each mark**: a new or changed field kind carries a comment naming the ATB 3I decomp file or the Fortran `src/*.for:line` that proves it (e.g. H.9 → heding_joint_forces.for:51).
- **Signed refs**: the H.1–H.8 Segment / Segment-or-Joint / H.7 Joint fields can be negative (the solver uses ABS and branches on the sign); compare those on |v| and preserve the sign. Ref Segment, H.9 joint and H.10.B are compared signed.

## Deck editing
- **Byte-for-byte round-trip**: mutate lines through DeckLine.SetTokens / Set*, which clear Raw only when a token changes; untouched lines must write back byte-identical.
- **Core stays UI-free**: Atb.Core takes a confirm callback (e.g. `Func<IReadOnlyList<RefSite>, bool>`) for any destructive step; MainForm supplies the MessageBox. Decline = no mutation.

## Tests
- **Fixture literals**: renumbering tests assert written-out token lines from `cases/2479/2479_2.LIN` (Python oracle or hand-checked), plus File.ReadAllBytes for round-trips — never values computed by Atb.Core helpers.
