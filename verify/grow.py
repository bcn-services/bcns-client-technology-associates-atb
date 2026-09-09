"""Show when each case's .t21 time history first departs from the reference and how
   the difference grows.   python3 verify/grow.py [key ...]   (default: all cases)"""
import sys, os, atbcmp as A
want = set(sys.argv[1:])
for c in A.cases():
    if want and c['key'] not in want: continue
    ref, new = A.ref_path(c, 't21'), A.new_path(c, 't21')
    if not os.path.exists(new): print("==", c['key'], "NEW MISSING"); continue
    first, rows = A.divergence(ref, new)
    print("==", c['key'], "rows", len(rows), " first row rel>1e-6 at time", first)
    for k in [0, 1, 2, 5, 10, 20, 50, 100, 200, 400, 800, 1600]:
        if k < len(rows): print(f"   t={rows[k][0]:8.3f} maxrel={rows[k][1]:.2e}")
