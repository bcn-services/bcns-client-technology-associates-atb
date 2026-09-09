"""Diff every number in every output file of every case against the reference set.
   EXAMPLES=<cases dir> WORK=<run_all scratch dir> python3 verify/cmp.py"""
import os, atbcmp as A
for c in A.cases():
    for e in A.exts(c):
        ref, new = A.ref_path(c, e), A.new_path(c, e)
        if not os.path.exists(new): print(c['key'], e, "NEW MISSING"); continue
        r = A.cmp(ref, new)
        if 'error' in r: print(c['key'], e, r['error'])
        else: print(f"{c['key']} {e} n={r['n']} maxabs={r['maxabs']:.3g} maxrel={r['maxrel']:.3g} n_over_1e-4={r['nbad']}")
