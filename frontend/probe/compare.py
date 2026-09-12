#!/usr/bin/env python3
"""Compare probe-artifact outputs against the client's reference outputs.

  compare.py volatile <run1dir> <base1> <run2dir> <base2>
      -> lists the lines that differ between two runs of the same input (the volatile set)
  compare.py refs <artifact>/all-<route> [--volatile volatile.json] [--refs cases]
      -> per case, per file: IDENTICAL / DIFFERS from line N (volatile lines masked)
  compare.py cross <artifact>/all-<route1> <artifact>/all-<route2> [--volatile ...]
      -> driver transparency: same input, two input routes, must be identical modulo volatile set
Volatile-line masking: a line is masked if any regex in the volatile set matches it. The volatile
set is derived from data (two runs of one input), never guessed.
"""
import json, os, re, sys, glob

def read_lines(p):
    with open(p, 'rb') as f:
        return f.read().decode('latin-1').split('\n')

def outputs(d, base):
    res = {}
    for p in glob.glob(os.path.join(d, base + '.*')):
        ext = os.path.splitext(p)[1].lower()
        if ext in ('.lin', '.log', '.txt', '.mem', '.json', '.png'): continue
        res[ext] = p
    return res

def cases_of(root):
    """[(key, casedir, base, subdir, rc, secs)] from <root>/cases.txt"""
    out = []
    for ln in open(os.path.join(root, 'cases.txt')):
        parts = ln.split()
        if len(parts) >= 6: out.append(parts[:6])
    return out

def line_diff(a, b):
    """pairs (lineno, a_line, b_line) that differ; lineno is 1-based; handles length mismatch."""
    d = []
    n = max(len(a), len(b))
    for i in range(n):
        x = a[i] if i < len(a) else None
        y = b[i] if i < len(b) else None
        if x != y: d.append((i + 1, x, y))
    return d

def volatile(run1, base1, run2, base2):
    o1, o2 = outputs(run1, base1), outputs(run2, base2)
    pats = {}
    for ext in sorted(set(o1) | set(o2)):
        if ext not in o1 or ext not in o2: print('MISSING', ext, ext in o1, ext in o2); continue
        a, b = read_lines(o1[ext]), read_lines(o2[ext])
        d = line_diff(a, b)
        print('%s: %d lines differ of %d/%d' % (ext, len(d), len(a), len(b)))
        for ln, x, y in d[:40]:
            print('   L%d\n     %r\n     %r' % (ln, x, y))
        pats[ext] = [ (ln, x, y) for ln, x, y in d ]
    return pats

def load_masks(path):
    if not path: return []
    return [re.compile(p) for p in json.load(open(path))['patterns']]

def masked(lines, masks):
    if not masks: return lines
    out = []
    for l in lines:
        m = l
        for r in masks:
            if r.search(l): m = '<VOLATILE>'; break
        out.append(m)
    return out

def cmp_files(pa, pb, masks):
    a, b = masked(read_lines(pa), masks), masked(read_lines(pb), masks)
    d = line_diff(a, b)
    if not d: return 'IDENTICAL', None, len(a)
    return 'DIFFERS', d, len(a)

def refs(root, refdir, masks):
    rows = []
    for key, cd, base, sub, rc, secs in cases_of(root):
        new = outputs(os.path.join(root, sub), base + '_new')
        ref = outputs(os.path.join(refdir, cd), base)
        exts = sorted(set(ref) | set(new))
        ident, diff, missing = [], [], []
        for ext in exts:
            if ext not in new: missing.append(ext + '(no new)'); continue
            if ext not in ref: missing.append(ext + '(no ref)'); continue
            v, d, n = cmp_files(new[ext], ref[ext], masks)
            if v == 'IDENTICAL': ident.append(ext)
            else: diff.append('%s@L%d/%d' % (ext, d[0][0], n))
        rows.append((key, rc, secs, len(ident), len(exts), ident, diff, missing))
    print('| case | exit | s | identical | total | differs (first line) | missing |')
    print('|---|---|---|---|---|---|---|')
    for key, rc, secs, ni, nt, ident, diff, missing in rows:
        print('| %s | %s | %s | %d | %d | %s | %s |' % (key, rc, secs, ni, nt, ' '.join(diff) or '-', ' '.join(missing) or '-'))
    return rows

def cross(r1, r2, masks):
    c1 = {c[0]: c for c in cases_of(r1)}; c2 = {c[0]: c for c in cases_of(r2)}
    print('| case | files | identical modulo volatile | differs |'); print('|---|---|---|---|')
    allok = True
    for key in sorted(c1):
        if key not in c2: print('| %s | - | - | not in second route |' % key); continue
        _, cd, base, sub, rc, secs = c1[key]
        o1 = outputs(os.path.join(r1, sub), base + '_new'); o2 = outputs(os.path.join(r2, sub), base + '_new')
        exts = sorted(set(o1) | set(o2)); diffs = []
        for ext in exts:
            if ext not in o1 or ext not in o2: diffs.append(ext + '(missing)'); continue
            v, d, n = cmp_files(o1[ext], o2[ext], masks)
            if v != 'IDENTICAL': diffs.append('%s@L%d' % (ext, d[0][0]))
        if diffs: allok = False
        print('| %s | %d | %d | %s |' % (key, len(exts), len(exts) - len(diffs), ' '.join(diffs) or '-'))
    print('CROSS', 'PASS' if allok else 'FAIL')

if __name__ == '__main__':
    a = sys.argv[1:]
    mode = a[0]
    vol = None
    if '--volatile' in a: i = a.index('--volatile'); vol = a[i + 1]; del a[i:i + 2]
    refdir = 'cases'
    if '--refs' in a: i = a.index('--refs'); refdir = a[i + 1]; del a[i:i + 2]
    masks = load_masks(vol)
    if mode == 'volatile': volatile(a[1], a[2], a[3], a[4])
    elif mode == 'refs': refs(a[1], refdir, masks)
    elif mode == 'cross': cross(a[1], a[2], masks)
