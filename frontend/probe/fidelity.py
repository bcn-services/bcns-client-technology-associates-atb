#!/usr/bin/env python3
"""Reference and cross-route comparison tables for FIDELITY.md.
  fidelity.py refs  <runroot> <casesdir> <volatile.txt>   per run: files identical / first differing line (masked)
  fidelity.py cross <runroot1> <runroot2> <volatile.txt>  two routes, same inputs
  fidelity.py raw   <runroot1> <runroot2>                 unmasked: which lines differ (volatile-set derivation)
Masking replaces any line matching a volatile.txt regex with <VOLATILE>. Lines keep their \\r."""
import os, re, sys, glob

def load_vol(path):
    return [re.compile(l.rstrip('\n')) for l in open(path, encoding='latin-1') if l.strip() and not l.startswith('#')]

def lines(path):
    return open(path, 'rb').read().decode('latin-1').split('\n')

def mask(ls, vol):
    return ['<VOLATILE>' if any(p.search(l) for p in vol) else l for l in ls]

def runs(root):
    out = []
    for l in open(os.path.join(root, 'cases.txt')):
        if l.strip():
            key, cd, base, sub = l.split()[:4]
            out.append((key, cd, base, sub, l.split()[4:]))
    return out

def outputs(d, base):
    return sorted(f for f in glob.glob(os.path.join(d, base + '.*')) if not f.lower().endswith('.lin') and 'runner.log' not in f)

def cmp_files(fa, fb, vol):
    a, b = lines(fa), lines(fb)
    if vol is not None: a, b = mask(a, vol), mask(b, vol)
    if a == b: return None
    diffs = [i + 1 for i, (x, y) in enumerate(zip(a, b)) if x != y]
    if len(a) != len(b): diffs.append('len %d vs %d' % (len(a), len(b)))
    return diffs

def main():
    mode = sys.argv[1]
    if mode == 'refs':
        root, cases, vol = sys.argv[2], sys.argv[3], load_vol(sys.argv[4])
        print('| run | exit | secs | files | identical (masked) | differs |')
        print('|---|---|---|---|---|---|')
        allok = True
        for key, cd, base, sub, rest in runs(root):
            refs = outputs(os.path.join(cases, cd), base)
            ident, diff, missing = [], [], []
            for r in refs:
                ext = os.path.splitext(r)[1]
                n = os.path.join(root, sub, base + '_new' + ext)
                if not os.path.exists(n): missing.append(ext); continue
                d = cmp_files(r, n, vol)
                if d is None: ident.append(ext)
                else: diff.append('%s@L%s/%d' % (ext, d[0], len(d)))
            if diff or missing: allok = False
            print('| %s | %s | %s | %d | %d | %s |' % (key, rest[0] if rest else '', rest[1] if len(rest) > 1 else '', len(refs), len(ident), ' '.join(diff + ['missing ' + m for m in missing]) or 'none'))
        print('ALL IDENTICAL' if allok else 'SOME DIFFER')
    elif mode in ('cross', 'raw'):
        r1, r2 = sys.argv[2], sys.argv[3]
        vol = load_vol(sys.argv[4]) if mode == 'cross' else None
        ok = True
        for key, cd, base, sub, rest in runs(r1):
            fs = outputs(os.path.join(r1, sub), base + '_new')
            res = []
            for f in fs:
                g = os.path.join(r2, sub, os.path.basename(f))
                if not os.path.exists(g): res.append(os.path.splitext(f)[1] + ' missing'); ok = False; continue
                d = cmp_files(f, g, vol)
                if d is not None:
                    ok = False
                    if mode == 'raw':
                        a, b = lines(f), lines(g)
                        res.append('%s lines %s' % (os.path.splitext(f)[1], ','.join(str(x) for x in d)))
                        for i in d[:60]:
                            if isinstance(i, int): print('    L%d %r | %r' % (i, a[i-1][:60], b[i-1][:60]))
                    else:
                        res.append('%s@L%s/%d' % (os.path.splitext(f)[1], d[0], len(d)))
            print('%-22s %d files: %s' % (key, len(fs), ' '.join(res) or 'all identical'))
        print(('CROSS' if mode == 'cross' else 'RAW') + (' PASS' if ok else ' DIFF'))
main()
