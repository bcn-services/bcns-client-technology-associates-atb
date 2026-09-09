"""Shared helpers: parse cases.txt, extract numbers, compare files, find divergence."""
import os, re, glob
NUM = re.compile(r'[-+]?(?:\d+\.\d*|\.\d+|\d+)(?:[EeDd][-+]?\d+)?')
HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
EXAMPLES = os.environ.get('EXAMPLES', os.path.join(ROOT, 'cases'))
WORK = os.environ.get('WORK', os.path.join(HERE, 'out'))

def cases():
    """Yield dicts for every run recorded by run_all.sh."""
    for line in open(os.path.join(WORK, 'cases.txt')):
        f = line.split()
        if len(f) < 6: continue
        yield dict(key=f[0], dir=f[1], base=f[2], sub=f[3], rc=int(f[4]), secs=int(f[5]))

def ref_path(c, ext): return os.path.join(EXAMPLES, c['dir'], f"{c['base']}.{ext}")
def new_path(c, ext): return os.path.join(WORK, c['sub'], f"{c['base']}_new.{ext}")

def exts(c):
    """Output extensions present in the reference set (sa1 + every t2x/t3x/...)."""
    out = []
    for p in sorted(glob.glob(os.path.join(EXAMPLES, c['dir'], c['base'] + '.*'))):
        e = p.rsplit('.', 1)[1]
        if e.lower() in ('lin', 'aou'): continue   # .aou carries run date/time
        out.append(e)
    return out

def nums(p):
    out = []
    for line in open(p, errors='replace'):
        for t in NUM.findall(line):
            try: out.append(float(t.replace('D', 'E').replace('d', 'e')))
            except ValueError: pass
    return out

def cmp(a, b):
    """Compare every number in two files. Returns dict or {'error': msg}."""
    A, B = nums(a), nums(b)
    if len(A) != len(B): return dict(error=f"count differs {len(A)} vs {len(B)}")
    mx = mxrel = 0.0; nbad = 0
    for x, y in zip(A, B):
        d = abs(x - y); mx = max(mx, d)
        r = d / max(abs(x), abs(y), 1e-9); mxrel = max(mxrel, r)
        if r > 1e-4 and d > 1e-6: nbad += 1
    return dict(n=len(A), maxabs=mx, maxrel=mxrel, nbad=nbad)

def divergence(ref, new, tol=1e-6):
    """Walk a time-history table (.t21 etc.) row by row; return
    (first_time_with_rel_diff>tol or None, [(time, maxrel), ...])."""
    R = open(ref, errors='replace').read().splitlines()
    N = open(new, errors='replace').read().splitlines()
    rows = []
    for a, b in zip(R, N):
        A = [float(x) for x in NUM.findall(a)]; B = [float(x) for x in NUM.findall(b)]
        if len(A) < 3 or len(A) != len(B): continue
        rel = max(abs(x - y) / max(abs(x), abs(y), 1e-6) for x, y in zip(A[1:], B[1:]))
        rows.append((A[0], rel))
    first = next((t for t, r in rows if r > tol), None)
    return first, rows
