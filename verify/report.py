"""Build the per-case verification table (Markdown) from a run_all.sh scratch dir.
   EXAMPLES=... WORK=... python3 verify/report.py [--label "32-bit x86 ..."] > table.md"""
import os, sys, json, atbcmp as A
label = sys.argv[sys.argv.index('--label') + 1] if '--label' in sys.argv else ''
rows = []; summary = {}
for c in A.cases():
    files = 0; worst = 0.0; nbad = 0; errs = []; missing = []
    for e in A.exts(c):
        new = A.new_path(c, e)
        if not os.path.exists(new): missing.append(e); continue
        r = A.cmp(A.ref_path(c, e), new)
        if 'error' in r: errs.append(f"{e}: {r['error']}"); continue
        files += 1; worst = max(worst, r['maxrel']); nbad += r['nbad']
    first = None; last_t = None
    t21 = A.new_path(c, 't21')
    if os.path.exists(t21):
        first, hist = A.divergence(A.ref_path(c, 't21'), t21)
        if hist: last_t = hist[-1][0]
    # The solver ends a normal run with STOP 1, so exit 1 is success; gfortran
    # runtime errors exit 2, solver STOP nn codes are >= 22.
    if c['rc'] not in (0, 1): verdict = f"FAILED (exit {c['rc']})"
    elif missing or errs: verdict = "INCOMPLETE"
    elif worst == 0: verdict = "bit-identical"
    elif nbad == 0: verdict = "matches to printed precision"
    else: verdict = "rounding drift after onset"
    rows.append(dict(key=c['key'], secs=c['secs'], files=files, maxrel=worst, nbad=nbad,
                     first=first, last_t=last_t, verdict=verdict, missing=missing, errs=errs))
print(f"Build: {label}\n" if label else "", end='')
print("| Case | Files compared | Max relative diff | Values off by >1e-4 | First divergence (ms) | Run length (ms) | Result | Runtime (s) |")
print("|---|---|---|---|---|---|---|---|")
for r in rows:
    fd = "none" if r['first'] is None else f"{r['first']:.0f}"
    lt = "?" if r['last_t'] is None else f"{r['last_t']:.0f}"
    note = (" missing: " + ",".join(r['missing']) if r['missing'] else "") + (" " + "; ".join(r['errs']) if r['errs'] else "")
    print(f"| {r['key']} | {r['files']} | {r['maxrel']:.2g} | {r['nbad']} | {fd} | {lt} | {r['verdict']}{note} | {r['secs']} |")
json.dump(rows, open(os.path.join(A.WORK, 'report.json'), 'w'), indent=1)
