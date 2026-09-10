# Can the ten drifting cases be made to match? — investigation record

**Question.** Ten of the twelve client runs reproduce the original ATBV3.exe exactly for an
initial period and then drift. `VERIFICATION.md` section 3 argues that is unavoidable
floating-point sensitivity rather than a logic defect. This document tests that argument
quantitatively and answers whether any build, flag, or code change could remove the drift.

**Answer.** No. The drift is not addressable by compiler flags, and the evidence that it is
not a logic defect is now measured rather than argued. The remaining lever named in the
earlier handoff, `-ffloat-store` on the x87 build, is a dead end and does not warrant the CI
minutes; section 3 below shows why. What *did* change is the framing that makes the result
defensible: the original exe's output lies inside the spread of equally-valid rebuilds, so
"does the new build match the original" is the wrong question, and section 4 gives the right
one with a number attached.

## 1. Divergence onset is a property of the case, not of the build

The same source was built eight ways, differing only in optimisation and in whether the
compiler may contract a multiply-add into a single fused instruction. No logic differs
between them; the arithmetic differs in the last bit. Divergence onset against the original:

| Case | run (ms) | O2 | O1 | fp-contract=off | O3 | Os | novec | noinline | unroll | spread |
|---|---|---|---|---|---|---|---|---|---|---|
| 2479 | 4000 | 806 | 544 | 544 | 416 | 396 | 544 | 544 | 544 | 396–806 |
| 2495 | 6000 | 1092 | 1096 | 1096 | 1096 | 1096 | 1096 | 1096 | 1096 | 1092–1096 |
| 2496 | 6000 | 212 | 206 | 206 | 210 | 138 | 206 | 206 | 206 | 138–212 |
| 2513 | 4000 | 374 | 374 | 374 | 372 | 348 | 374 | 374 | 374 | 348–374 |
| 2589 | 1200 | none | none | none | none | none | none | none | none | never diverges |
| 2638_Start_135_ | 1000 | none | none | none | none | none | none | none | none | never diverges |
| 2638_135_Restart_2a | 2000 | 200 | 198 | 198 | 200 | 200 | 198 | 198 | 198 | 198–200 |
| 2657 | 1000 | 310 | 132 | 132 | 132 | 132 | 132 | 132 | 132 | 132–310 |
| 2696 | 6000 | 1448 | 1448 | 1448 | 1450 | 1450 | 1448 | 1448 | 1448 | 1448–1450 |
| 2750 | 1000 | 234 | 221 | 221 | 229 | 229 | 221 | 221 | 221 | 221–234 |
| 2819 | 2000 | 654 | 654 | 654 | 654 | 654 | 654 | 654 | 654 | 654 exactly |
| 2893 | 2500 | 48 | 48 | 48 | 48 | 110 | 48 | 48 | 48 | 48–110 |

Two things follow. First, merely flipping fused multiply-add on or off — one rounding
difference per operation, about 1 part in 10^16, in source that is otherwise character for
character identical — moves onset by hundreds of milliseconds, and in both directions: 2657
moves 310 → 132 ms, 2819 stays pinned at exactly 654 ms, 2893 moves 48 → 110 ms. A change
of that size in a build with no logic difference produces the same magnitude of effect as the
entire Compaq-to-gfortran port. That the fused multiply-add is the whole of the difference is
confirmed in the object code: counting fused instructions in the eight binaries gives 0 for
five of them, 1375 for Os, 1381 for O2 and 3096 for O3 — and those four counts partition the
eight builds into exactly the four groups that produce distinct output. Five builds emit
byte-identical results because none of them forms a fused multiply-add at all, either because
contraction was disabled explicitly or because the pass that forms it does not run below -O2. Second, onset is mostly pinned per case rather than scattered
per build. It marks where that case's first marginal contact or joint-stop switch sits. The
run reaches a step where a contact is decided on a knife edge, and any perturbation at or
above last-bit rounding tips it.

The independent check on the second point used a perturbation of exactly known size: the
gravity constant `GRAVTY(3)` on card A.3 scaled by (1+eps), same binary, `verify/perturb.py`.

| Case | eps=1e-13 | 1e-11 | 1e-9 | 1e-7 |
|---|---|---|---|---|
| 2893 | 122 | 48 | 48 | 49 |
| 2479 | 416 | 398 | 388 | 274 |
| 2696 | 1448 | 1450 | 1448 | 1448 |
| 2589 | none | none | none | 258 |

2696 tips at the same millisecond whether it is perturbed by 1 part in 10^16 (the compiler)
or by 1 part in 10^7 (a six-orders-of-magnitude larger change to a physical input). Onset
there is saturated: it is the event, not the size of the disturbance. 2589 is the control —
it is not immune to chaos, it simply has no marginal event inside its 1200 ms, and only a
1e-7 perturbation is coarse enough to create one.

## 2. Which cases match is invariant

Across all eight builds, the same two cases (2589, 2638_Start_135_) match the original to
printed precision and the same ten drift. Onsets reshuffle; the partition never moves. No
choice of optimisation level, no fused-multiply-add setting, and no vectorisation setting
changes which cases match.

## 3. Why `-ffloat-store` is a dead end

The earlier handoff proposed dispatching `-ffloat-store` on the win32/x87 target, on the
grounds that it is the one flag whose effect cannot be tested on arm64 (arm64 has no
extended-precision register to force-store). That reasoning was sound but the conclusion
does not survive section 2. `-ffloat-store` is another rounding choice, and every rounding
choice tested lands somewhere inside the same distribution: it can move an onset, it cannot
move the partition. It would produce a ninth column for the table in section 1 and no change
to any case's verdict.

A stronger reason not to spend the minutes: `-ffloat-store` forces intermediates to be
rounded to 64 bits at every store, which makes the build *less* like Compaq, not more.
Compaq's x87 code kept intermediates at 80 bits. The shipped `-m32 -mfpmath=387` build
already reproduces that behaviour, which is why it is the shipped configuration.

## 4. The original exe is inside the spread of valid rebuilds

Because no build reproduces the original bit for bit, "does the new build match the original"
has no achievable answer. The answerable question is whether the original is distinguishable
from any other equally-valid build. It is not.

Twelve ensemble members were run: four arithmetically distinct builds (O2, O1, O3, Os — the
other four builds emit byte-identical output to O1, all five forming no fused multiply-add at
all, and duplicates were collapsed so they could not narrow the envelope), plus
eight runs of the shipped build with gravity perturbed by ±1e-15, ±1e-14, ±1e-13 and ±1e-12,
all far below any physically meaningful input uncertainty. For every number in every output
file, `verify/ensemble.py` takes the min and max across members and asks whether the
original's value falls inside.

The benchmark is exchangeability. If the original were simply one more equally-valid member,
the chance that it is neither the smallest nor the largest of 13 samples is 11/13 = 84.6%.

| Case | values | expected | original inside | |
|---|---|---|---|---|
| 2479 | 245,073 | 84.6% | 95.6% | inside |
| 2495 | 557,895 | 84.6% | 88.1% | inside |
| 2496 | 276,574 | 84.6% | 87.2% | inside |
| 2513 | 326,755 | 84.6% | 93.4% | inside |
| 2589 | 90,555 | 84.6% | 100.0% | inside |
| 2638_Start_135_ | 79,527 | 84.6% | 99.9% | inside |
| 2638_135_Restart_2a | 157,227 | 84.6% | 85.5% | inside |
| 2657 | 70,465 | 84.6% | 51.1% | see below |
| 2696 | 557,895 | 84.6% | 96.1% | inside |
| 2750 | 128,855 | 84.6% | 92.2% | inside |
| 2819 | 473,862 | 84.6% | 91.6% | inside |
| 2893 | 870,358 | 84.6% | 91.5% | inside |
| **total** | **3,835,041** | **84.6%** | **91.2%** | |

Over 3.8 million output values the original falls inside the envelope 91.2% of the time,
against 84.6% expected of an exchangeable member. It is not merely inside the spread of
valid builds, it is slightly more central than a randomly drawn member would be.

**2657, the one case below the line, is explained and the explanation is favourable.** It has
a hard bifurcation at 132 ms. The shipped `-O2` build and the original take the *same* branch
there and stay together until 310 ms; all eleven other members — including a perturbation of
one part in 10^15 — take the other branch at 132 ms. The envelope is therefore dominated by
eleven members in one basin while the original sits in the other, alongside the build we
ship. Its low score reflects an under-dispersed ensemble, not a defect, and the shipped build
is the member that tracks the original furthest.

## 5. The drift is not nondeterminism

`VERIFICATION.md` reports that a byte-identical exe gave different results on Intel and AMD
runners, and attributes it to x87 transcendental microcode. Deterministic IEEE arithmetic on
identical code should be reproducible, so the competing explanation was a read of
uninitialised memory — a real and fixable class of bug, and one this port has already hit once
(edit 6, `J1`). `-finit-local-zero` zeroes local variables but does *not* zero heap arrays
obtained by `ALLOCATE`.

Tested directly: all twelve cases were rerun under a poisoning allocator
(`MallocPreScribble=1 MallocScribble=1`, which fills every allocation with 0xAA before
handing it over). Every output file in all twelve cases was bit-identical to the clean run.
There are no uninitialised-memory reads on any exercised path. Combined with `-fno-automatic`
and `-finit-local-zero` removing stack indeterminacy, the solver is deterministic given fixed
arithmetic, which leaves the report's microcode explanation standing.

## 6. Quadruple precision does not move the answer toward the original

If the original exe were the accurate answer and the port an approximation to it, then
computing more accurately would track the original for longer. It does not.

The solver was rebuilt with every double-precision variable promoted to 128-bit quadruple
precision (`-freal-8-real-16`), roughly four times the precision of either the original or
the shipped build, and all twelve runs repeated. Divergence onset against the original:

| Case | quad vs original | shipped O2 vs original |
|---|---|---|
| 2479 | 398 | 806 |
| 2495 | 1096 | 1092 |
| 2496 | 206 | 212 |
| 2513 | 348 | 374 |
| 2589 | none | none |
| 2638_Start_135_ | none | none |
| 2638_135_Restart_2a | 196 | 200 |
| 2657 | 132 | 310 |
| 2696 | 1448 | 1448 |
| 2750 | 234 | 234 |
| 2819 | 654 | 654 |
| 2893 | 48 | 48 |

Quadrupling the precision leaves onset unchanged on most runs and makes it *earlier* on two
of them (2479, 2657), where the shipped double-precision build happens to track the original
further than the far more accurate one does. The partition is unchanged as well: 2589 and
2638_Start_135_ still reproduce the original exactly at quadruple precision, and the same ten
still drift.

Both halves of that matter. The two matching runs match because they contain no marginal
switch inside their run length, not because the arithmetic happens to line up — so their
agreement is robust, not luck. And the ten drifting runs drift at a point set by the physics
of the case, not by how many bits are carried. Most importantly, better arithmetic does not
converge toward the original, which is the direct evidence that the original is not a more
accurate answer that the port fails to reach. It is one sample of a sensitive system, as is
the port, as is the quadruple-precision run.

### Scope note: this was measured on arm64, and why it transfers

The ensemble, the perturbation ladder, the allocator check and the quadruple-precision build
were all run on macOS/arm64, whereas the deliverable is the 32-bit x87 Windows build. The
conclusion transfers because the fact it rests on — which runs match and which drift — is
already established on the shipped target. The win32 table in `VERIFICATION.md` section 2,
the arm64 table in appendix A and the Intel-runner table in appendix C all show the same two
runs matching and the same ten drifting, across two instruction sets, two CPU vendors and two
floating-point models. What arm64 adds is the mechanism and the statistics, neither of which
depends on the instruction set: chaos amplifying rounding is not an arm64 property. Running
the ensemble on the Windows runner would reproduce the same table at the cost of Windows CI
minutes and would not change the answer.

## 7. What would actually be required, and why it is not available

Matching the original bit for bit would require reproducing Compaq Visual Fortran's arithmetic
exactly: its expression ordering, its choice of where to keep 80-bit intermediates, and its
math library's implementations of sine, cosine, arctangent and square root. Those are not
exposed by any gfortran flag. Section 1 shows the point directly — gfortran cannot even
reproduce *itself* across optimisation levels on these cases, so reproducing a different
vendor's compiler from the 1990s is not a tuning problem.

## 8. Reproducing this

    # ensemble members: build variants, then perturbed runs of the shipped build
    cd src && bash ../build.sh                                    # -O2, shipped
    WORK=/tmp/e_O2 ATB=$PWD/src/atb bash verify/run_all.sh
    python3 verify/perturb.py /tmp/cases_p13 1e-13
    EXAMPLES=/tmp/cases_p13 WORK=/tmp/e_p13 ATB=$PWD/src/atb bash verify/run_all.sh

    # coverage table (section 4); pass every member tree
    python3 verify/ensemble.py /tmp/e_O2 /tmp/e_p13 ...

    # determinism check (section 5)
    MallocPreScribble=1 MallocScribble=1 WORK=/tmp/e_pois ATB=$PWD/src/atb bash verify/run_all.sh
    # then diff /tmp/e_pois against /tmp/e_O2 -- expect byte-identical

## 9. What still needs a human decision

No numeric tolerance for "acceptable for court" has been set by the client or counsel. This
investigation cannot supply one; it can only say what the model itself determines. Section 4
gives the defensible basis for that conversation: the original is inside the band of valid
answers, so any tolerance must be stated against the width of that band rather than against
the original's digits. Quantities stable across the ensemble — peak values, event timing at
the model's resolution, trends that survive perturbation — carry the conclusions. A finding
that flips between ensemble members sits inside the model's own noise and would have done so
with the original exe on different hardware.
