"""Is the original exe's output inside the spread of equally-valid rebuilds?

    EXAMPLES=<cases> python3 verify/ensemble.py <workdir> [<workdir> ...]

Each workdir is one run_all.sh output tree (one "ensemble member"): a build of the
same source differing only in rounding, or a run perturbed at rounding scale.  For
every number in every output file the script takes the min/max across members and
asks whether the original exe's value lies inside that envelope.

The benchmark is exchangeability.  If the original were simply one more equally-valid
member, the chance it is neither the min nor the max of N+1 samples is (N-1)/(N+1).
Coverage at or above that line means the original is statistically indistinguishable
from another member, which is the claim the verification rests on.

Members that emit byte-identical output are collapsed first: duplicates narrow the
envelope without adding information, and would understate the expected coverage.
"""
import os, sys, hashlib

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
# cases.txt is written by run_all.sh into each member's tree; they list the same runs,
# so the first member names the run set.  Set before importing atbcmp, which reads WORK.
if len(sys.argv) > 1 and not os.environ.get('WORK'):
    os.environ['WORK'] = sys.argv[1]
import atbcmp as A


def member_digest(work, c, exts):
    m = hashlib.sha256()
    for e in exts:
        p = os.path.join(work, c['sub'], f"{c['base']}_new.{e}")
        if os.path.exists(p):
            m.update(open(p, 'rb').read())
    return m.hexdigest()


def main(works):
    print(f"{'case':22}{'values':>9}{'members':>9}{'expected':>10}{'inside':>9}  verdict")
    print('-' * 70)
    tot_in = tot = 0
    low = []
    for c in A.cases():
        exts = A.exts(c)
        seen, uniq = set(), []
        for w in works:                                  # collapse identical members
            d = member_digest(w, c, exts)
            if d not in seen:
                seen.add(d); uniq.append(w)
        nd = len(uniq)
        if nd < 2:
            print(f"{c['key']:22}  needs >=2 distinct members"); continue
        exp = 100.0 * (nd - 1) / (nd + 1)
        n_in = n = 0
        for e in exts:
            O = A.nums(A.ref_path(c, e))
            E = []
            for w in uniq:
                p = os.path.join(w, c['sub'], f"{c['base']}_new.{e}")
                if not os.path.exists(p): break
                x = A.nums(p)
                if len(x) != len(O): break
                E.append(x)
            if len(E) != nd: continue                    # skip files a member did not produce
            for i, o in enumerate(O):
                col = [x[i] for x in E]
                n += 1
                if min(col) - 1e-12 <= o <= max(col) + 1e-12:
                    n_in += 1
        if not n:
            print(f"{c['key']:22}  no comparable files"); continue
        got = 100.0 * n_in / n
        ok = got >= exp
        if not ok: low.append(c['key'])
        print(f"{c['key']:22}{n:9d}{nd:9d}{exp:9.1f}%{got:8.1f}%  {'inside' if ok else 'BELOW'}")
        tot_in += n_in; tot += n
    print('-' * 70)
    if tot:
        print(f"{'TOTAL':22}{tot:9d}{'':9}{'':10}{100.0*tot_in/tot:8.1f}%")
    if low:
        print("\nBelow expectation: " + ", ".join(low))
        print("Check whether the shipped build tracks the original through a bifurcation the\n"
              "other members miss -- that under-disperses the envelope and reads as 'BELOW'.\n"
              "Compare per-member onset against the original before treating it as a defect.")


if __name__ == '__main__':
    if len(sys.argv) < 2: raise SystemExit(__doc__)
    main(sys.argv[1:])
