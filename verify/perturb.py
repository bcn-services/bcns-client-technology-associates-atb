"""Input-precision ensemble member generator: jitter every real input inside the
rounding interval of its own printed representation.

    python3 verify/perturb.py <src_cases> <dst_cases> <seed>
    python3 verify/perturb.py                       # self-check

The client decks are text.  Every real-valued number in them is printed with at
most 7 significant digits, so the deck does not carry the value the analyst had
-- it carries a decimal interval that value fell in.  A token printed `15.30887`
stands for anything in [15.308865, 15.308875).  This script draws one sample
from that interval for every such token:

    x' = x + u * ulp,      u ~ Uniform(-0.5, +0.5),  drawn independently per token
    ulp = one unit in the token's last printed digit

    15.30887   -> ulp 1e-5        6.25E-05 -> ulp 1e-7 (2 mantissa decimals, e-5)
    0.4819279  -> ulp 1e-7        0.0025   -> ulp 1e-4

The RNG is numpy's default_rng(seed); files are visited in sorted order and
tokens left-to-right, so a seed reproduces a tree byte-for-byte.  Perturbed
tokens are rewritten with repr() (uppercase E, always a decimal point) so the
jitter is not re-rounded away by the rewrite.  The solver reads these decks with
list-directed READ(LU,*), so the tokens may change width; only token text
changes, never the line/record structure, and the trailing `CARD x.y` label is
left byte-identical.

A token is perturbed only if all of:
  * it contains a '.' or an exponent -- i.e. it is real-valued *as printed*;
  * it is non-zero (0 is exact, and a rounding interval around it is meaningless);
  * it is not inside a double-quoted string (segment names, units, titles);
  * its line's CARD label is not one of the excluded cards below.

Excluded cards
  A.4  integrator step controls (NDINT, NSTEPS, DT, H0, HMAX, HMIN) -- the step
       size is swept by a separate step ladder; jittering it here would mix
       integration error into the input-precision band.
  A.5  option/output flags -- not physical quantities.
  B.6  convergence tolerances -- solver controls, not deck data.
  C.5  *first column only* (the time abscissa of the vehicle-motion table).
       VSPLIN.FOR hard-STOPs ("Time points must be in ascending order for
       vehicle input option 4") if that column is not strictly increasing.
       The column is a sampling grid, not a measured quantity, and it is
       printed at the grid's own resolution -- `0.1` on an 0.005-spaced grid
       carries a 0.1 ulp under the rule above, so a half-ulp draw reorders the
       grid and the solver refuses the deck.  Columns 2-6 of C.5 (the actual
       vehicle displacement/acceleration history) ARE perturbed.

Integer-formatted tokens (no '.', no exponent) are deliberately left alone.
Without a full card-by-card schema, an integer-looking token is indistinguishable
from a count, an index, or a flag, and perturbing one of those is not a precision
question -- it is a different simulation.  Some of them really are physical
quantities printed to zero decimals (a `0` moment arm, a `-13` offset), so this
choice makes the reported band a conservative *lower* bound on input-precision
spread, never an inflated one.
"""
import io, os, re, shutil, sys
import numpy as np

NUMRE  = re.compile(r'[-+]?(?:\d+\.\d*|\.\d+|\d+)(?:[EeDd][-+]?\d+)?')
CARDRE = re.compile(r'\bCARD\b', re.I)
SKIP_CARDS = frozenset(('A.4', 'A.5', 'B.6'))
SKIP_FIRST_COL_CARDS = frozenset(('C.5',))   # time abscissa; see module docstring


def quoted_spans(line):
    """[start, end) character spans of every double-quoted string, quotes included."""
    spans, i = [], 0
    while True:
        a = line.find('"', i)
        if a < 0:
            return spans
        b = line.find('"', a + 1)
        if b < 0:                      # unterminated: treat rest of line as quoted
            spans.append((a, len(line)))
            return spans
        spans.append((a, b + 1))
        i = b + 1


def card_split(line, spans):
    """(index where the CARD label starts, uppercased label) -- (len(line), None) if none."""
    for m in CARDRE.finditer(line):
        if any(s <= m.start() < e for s, e in spans):
            continue               # the word CARD inside a quoted title
        rest = line[m.end():].split()
        return m.start(), (rest[0].upper() if rest else '')
    return len(line), None


def is_real_token(tok):
    return '.' in tok or 'E' in tok.upper() or 'D' in tok.upper()


def token_value(tok):
    return float(tok.replace('D', 'E').replace('d', 'e'))


def token_ulp(tok):
    """One unit in the token's last printed digit."""
    t = tok.replace('D', 'E').replace('d', 'e').upper()
    mant, _, ex = t.partition('E')
    e = int(ex) if ex else 0
    k = len(mant.split('.')[1]) if '.' in mant else 0
    return float('1e%d' % (e - k))


def fmt(x):
    """repr() of a float, in a form Fortran list-directed input accepts."""
    s = repr(float(x))
    if 'e' in s or 'E' in s:
        m, _, e = s.lower().partition('e')
        if '.' not in m:
            m += '.0'
        return m + 'E' + e
    return s if '.' in s else s + '.0'


def perturb_line(line, rng, counter=None):
    spans = quoted_spans(line)
    cpos, label = card_split(line, spans)
    if label in SKIP_CARDS:
        return line
    head = line[:cpos]
    skip_first = label in SKIP_FIRST_COL_CARDS
    pieces, last, ntok = [], 0, 0
    for m in NUMRE.finditer(head):
        tok = m.group()
        if any(s <= m.start() < e for s, e in spans):
            continue
        ntok += 1
        if skip_first and ntok == 1:
            continue
        if not is_real_token(tok):
            continue
        v = token_value(tok)
        if v == 0.0:
            continue
        u = float(rng.uniform(-0.5, 0.5))
        pieces.append(head[last:m.start()])
        pieces.append(fmt(v + u * token_ulp(tok)))
        last = m.end()
        if counter is not None:
            counter[0] += 1
    pieces.append(head[last:])
    return ''.join(pieces) + line[cpos:]


def perturb_file(src, dst, rng, counter=None):
    with open(src, errors='replace', newline='') as f:
        text = f.read()
    out = [perturb_line(l, rng, counter) for l in text.splitlines(keepends=True)]
    with open(dst, 'w', newline='') as f:
        f.write(''.join(out))


def main(src, dst, seed):
    """Copy the case tree (reference outputs included) and jitter every .LIN in it."""
    if os.path.exists(dst):
        shutil.rmtree(dst)
    shutil.copytree(src, dst)
    rng = np.random.default_rng(int(seed))
    counter, per_deck = [0], []
    for root, dirs, files in os.walk(dst):
        dirs.sort()
        for name in sorted(files):
            if not name.upper().endswith('.LIN'):
                continue
            before = counter[0]
            p = os.path.join(root, name)
            perturb_file(p, p, rng, counter)
            per_deck.append((os.path.relpath(p, dst), counter[0] - before))
    for name, n in per_deck:
        print(f"{n:6d}  {name}")
    print(f"{counter[0]} tokens perturbed in {len(per_deck)} decks, seed {seed}")


# ---------------------------------------------------------------- self-check

SAMPLE = (
    '"8/18/20"    CARD A.1.a\n'
    '"IN."    "LB."    "SEC."    0    0    386.088    386.088    CARD A.3\n'
    '4    2000    0.002    0.0005    0.001    6.25E-05    CARD A.4\n'
    '5    0    1    0    0    1    CARD A.5\n'
    '"LT "    30.86138    1.400881    0    1.993187    1    CARD B.2.a\n'
    '0.01    0.01    0.1    CARD B.6\n'
    '0    0    0.25    25    0.5    100    \n'
    '"P "    3    0    -2.835566    0    2.067626    CARD B.3.a\n'
    '15.30887    6.25E-05    0.4819279    CARD C.5\n'
    '0.1    -1    0    0    0    0    0    CARD C.5\n'
    '0.2    -1.5    0    0    0    0    0    CARD C.5\n'
)


def _selfcheck():
    import tempfile, contextlib
    # ulp rule
    assert token_ulp('15.30887')  == 1e-5,  token_ulp('15.30887')
    assert token_ulp('6.25E-05')  == 1e-7,  token_ulp('6.25E-05')
    assert token_ulp('0.4819279') == 1e-7,  token_ulp('0.4819279')
    assert token_ulp('0.0025')    == 1e-4,  token_ulp('0.0025')
    assert token_ulp('386.088')   == 1e-3,  token_ulp('386.088')

    with tempfile.TemporaryDirectory() as t:
        src = os.path.join(t, 'cases', 'X'); os.makedirs(src)
        lin = os.path.join(src, 'X.LIN')
        open(lin, 'w').write(SAMPLE)
        open(os.path.join(src, 'X.t21'), 'w').write('reference table\n')

        with contextlib.redirect_stdout(io.StringIO()):
            main(os.path.join(t, 'cases'), os.path.join(t, 'a'), 7)
            main(os.path.join(t, 'cases'), os.path.join(t, 'b'), 7)
            main(os.path.join(t, 'cases'), os.path.join(t, 'c'), 8)
        A = open(os.path.join(t, 'a', 'X', 'X.LIN')).read()
        B = open(os.path.join(t, 'b', 'X', 'X.LIN')).read()
        C = open(os.path.join(t, 'c', 'X', 'X.LIN')).read()

        assert A == B, "same seed must reproduce the same file"
        assert A != C, "different seeds must differ"
        assert A != SAMPLE, "nothing was perturbed"
        assert os.path.exists(os.path.join(t, 'a', 'X', 'X.t21')), "reference files not copied"

        s, a = SAMPLE.splitlines(), A.splitlines()
        assert len(s) == len(a), "line count changed"
        for i, (o, n) in enumerate(zip(s, a)):
            # excluded cards byte-identical
            if any(f'CARD {c}' in o for c in SKIP_CARDS):
                assert o == n, f"line {i+1}: excluded card changed:\n  {o}\n  {n}"
            # quoted strings untouched
            assert re.findall(r'"[^"]*"', o) == re.findall(r'"[^"]*"', n), f"line {i+1}: quoted text changed"
            # token count per line unchanged
            assert len(NUMRE.findall(o)) == len(NUMRE.findall(n)), (
                f"line {i+1}: token count {len(NUMRE.findall(o))} -> {len(NUMRE.findall(n))}\n  {o}\n  {n}")
            # trailing CARD label byte-identical
            oc, nc = card_split(o, quoted_spans(o)), card_split(n, quoted_spans(n))
            assert o[oc[0]:] == n[nc[0]:], f"line {i+1}: CARD label changed"

        # every real token moved by <= 0.5 ulp, integers not at all
        moved = 0
        for o, n in zip(s, a):
            if any(f'CARD {c}' in o for c in SKIP_CARDS):
                continue
            ot = NUMRE.findall(o.split('CARD')[0])
            nt = NUMRE.findall(n.split('CARD')[0])
            for x, y in zip(ot, nt):
                if is_real_token(x) and token_value(x) != 0.0 and '"' not in o.split(x)[0][-1:]:
                    d = abs(token_value(y) - token_value(x))
                    assert d <= 0.5 * token_ulp(x) * (1 + 1e-9), f"{x} -> {y} moved {d}, ulp {token_ulp(x)}"
                    if d > 0:
                        moved += 1
                elif not is_real_token(x):
                    assert x == y, f"integer token {x} -> {y}"
        assert moved >= 10, f"only {moved} tokens moved"

        # the known token 15.30887 moved, and by <= 0.5e-5 -- it is C.5 column 2,
        # so the column-1 exclusion must not shield it
        known = [l for l in a if l.startswith('15.30887')][0]
        got = float(NUMRE.findall(known.split('CARD')[0])[1])
        assert got != 6.25e-05 and abs(got - 6.25e-05) <= 0.5e-7, got
        assert float(NUMRE.findall(known.split('CARD')[0])[0]) == 15.30887, "C.5 col 1 must be frozen"

        # C.5 time column frozen, its value columns not
        for t in ('0.1', '0.2'):
            ln = [l for l in a if l.startswith(t + ' ')]
            assert ln, f"C.5 row {t} missing"
            f0, f1 = NUMRE.findall(ln[0].split('CARD')[0])[:2]
            assert float(f0) == float(t), f"C.5 time column moved: {f0}"
        v = float(NUMRE.findall([l for l in a if l.startswith('0.2 ')][0].split('CARD')[0])[1])
        assert v != -1.5 and abs(v + 1.5) <= 0.5e-1, v

    print("perturb.py self-check OK")


if __name__ == '__main__':
    if len(sys.argv) == 1:
        _selfcheck()
    elif len(sys.argv) == 4:
        main(sys.argv[1], sys.argv[2], sys.argv[3])
    else:
        raise SystemExit(__doc__)
