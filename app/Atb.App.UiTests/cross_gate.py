#!/usr/bin/env python3
"""Gate: the app's run of a deck is identical to a direct atb-win32.exe run of it, modulo frontend/package/volatile.txt.
  cross_gate.py <app root> <direct root>      each root: cases.txt + <sub>/<base>_new.*  (as compare.py cross reads)
Exit 1 unless compare.py prints CROSS PASS and every case compared at least one output file (compare.py alone would
pass a case with no outputs, or a case missing from the second root)."""
import json, os, subprocess, sys, tempfile

REPO = os.path.abspath(os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..'))

def main(app, direct):
    with open(os.path.join(REPO, 'frontend', 'package', 'volatile.txt'), encoding='latin-1') as f:
        pats = [l.rstrip('\r\n') for l in f if l.strip() and not l.startswith('#')]
    vol = os.path.join(tempfile.mkdtemp(), 'volatile.json')
    with open(vol, 'w') as f: json.dump({'patterns': pats}, f)
    out = subprocess.run([sys.executable, os.path.join(REPO, 'frontend', 'probe', 'compare.py'), 'cross', app, direct, '--volatile', vol],
                         capture_output=True, text=True, check=True).stdout
    print(out, end='')
    rows = [[c.strip() for c in l.split('|')[1:-1]] for l in out.splitlines() if l.startswith('| ') and not l.startswith('| case')]
    bad = [] if rows else ['no cases compared']
    for key, files, same, differs in rows:
        if not files.isdigit() or int(files) == 0 or differs != '-': bad.append('%s: files=%s differs=%s' % (key, files, differs))
    if 'CROSS PASS' not in out: bad.append('compare.py: CROSS FAIL')
    for b in bad: print('GATE FAIL:', b)
    if not bad: print('GATE PASS: %d case(s) identical modulo volatile.txt (%d patterns)' % (len(rows), len(pats)))
    return 1 if bad else 0

if __name__ == '__main__':
    sys.exit(main(sys.argv[1], sys.argv[2]))
