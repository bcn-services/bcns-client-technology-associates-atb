#!/usr/bin/env python3
"""Gate for the robot's grid edit + Save: each saved deck differs from its original in exactly the edited token.
  tokendiff.py <edits.tsv> <expected rows>   rows: original \t saved \t old token \t new token  (exit 1 on any failure)
  tokendiff.py --selftest                    proves the check goes red on an extra token, an extra line, a wrong value
Whitespace between tokens may change on the edited line (Deck.Save reformats only that line); every other line must be
byte-identical, and the edited line must keep every token but one."""
import os, sys, tempfile

def lines(p):
    with open(p, 'rb') as f:
        return f.read().decode('latin-1').split('\n')

def check(orig, saved, old, new):
    """None when saved == orig with exactly one token old -> new; else the reason."""
    a, b = lines(orig), lines(saved)
    if len(a) != len(b): return 'line count %d -> %d' % (len(a), len(b))
    d = [i for i, (x, y) in enumerate(zip(a, b)) if x != y]
    if len(d) != 1: return '%d lines differ (want 1): %s' % (len(d), [i + 1 for i in d[:5]])
    i = d[0]; ta, tb = a[i].split(), b[i].split()
    if len(ta) != len(tb): return 'line %d: token count %d -> %d' % (i + 1, len(ta), len(tb))
    t = [k for k, (x, y) in enumerate(zip(ta, tb)) if x != y]
    if len(t) != 1: return 'line %d: %d tokens differ (want 1)' % (i + 1, len(t))
    k = t[0]
    if ta[k] != old or tb[k] != new:
        return 'line %d token %d: %r -> %r, robot typed %r -> %r' % (i + 1, k + 1, ta[k], tb[k], old, new)
    return None

def main(tsv, want):
    rows = [l.rstrip('\r\n').split('\t') for l in open(tsv, encoding='utf-8') if l.strip()]
    bad = 0
    for orig, saved, old, new in rows:
        why = check(orig, saved, old, new)
        print('%s %s  %s -> %s%s' % ('OK  ' if why is None else 'FAIL', os.path.basename(saved), old, new, '' if why is None else '  ' + why))
        bad += why is not None
    if len(rows) != want: print('FAIL: %d edit rows, expected %d' % (len(rows), want)); bad += 1
    return 1 if bad else 0

def selftest():
    d = tempfile.mkdtemp()
    def f(name, text):
        p = os.path.join(d, name); open(p, 'wb').write(text.encode('latin-1')); return p
    o = f('o', 'A.1\r\n"HEAD SEG"   10.5  2.0 3\r\nB\r\n')
    cases = [
        ('good (reformatted spacing)', f('g', 'A.1\r\n"HEAD SEG" 11.75 2.0 3\r\nB\r\n'), None),
        ('extra token on the edited line', f('x', 'A.1\r\n"HEAD SEG" 11.75 2.5 3\r\nB\r\n'), 'tokens differ'),
        ('extra token on another line', f('y', 'A.2\r\n"HEAD SEG" 11.75 2.0 3\r\nB\r\n'), 'lines differ'),
        ('wrong new value', f('w', 'A.1\r\n"HEAD SEG" 11.7 2.0 3\r\nB\r\n'), 'robot typed'),
        ('token appended', f('a', 'A.1\r\n"HEAD SEG" 11.75 2.0 3 4\r\nB\r\n'), 'token count'),
    ]
    ok = True
    for name, p, want in cases:
        why = check(o, p, '10.5', '11.75')
        good = why is None if want is None else (why is not None and want in why)
        print('%s %-32s -> %s' % ('pass' if good else 'FAIL', name, why)); ok &= good
    return 0 if ok else 1

if __name__ == '__main__':
    sys.exit(selftest() if sys.argv[1:] == ['--selftest'] else main(sys.argv[1], int(sys.argv[2])))
