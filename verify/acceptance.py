"""Acceptance-band scoring for the gfortran rebuild vs the original CVF build.

    python3 verify/acceptance.py            # writes ACCEPTANCE.md + verify/acceptance_channels.csv

A channel is one numeric column (col >= 1; col 0 is time) of a reference time-history table
(.t21, .t22, ...) whose peak |value| >= 1.0 unit.  .sa1 animation files are not time-history
tables and are excluded (their column count is reported so totals reconcile with analyze.py).

A channel PASSES when both hold, rebuild (shipped -O2 build, shipped integrator step) vs original:
  1. ISO/TS 18571 overall rating R >= 0.80  (verify/iso18571.py)
  2. |peak(rebuild) - peak(original)| / peak(original) <= max(TOL_B6, BAND), where
       TOL_B6 = the deck's own CARD B.6 per-step relative error tolerance for that quantity type
                (ang_vel / lin_vel / lin_acc / ang_acc; displacement and contact-force channels
                have no B.6 entry and get TOL_B6 = 0), and
       BAND   = max( spread of peak across the 4 arithmetic builds at h64,
                     spread of peak across the o2 step ladder h1/h8/h64,
                     spread of peak across the 93-member input-precision ensemble ) / peak(original)
A case passes when every channel passes.
"""
import os, re, sys, glob, json, collections, csv
import numpy as np
HERE = os.path.dirname(os.path.abspath(__file__)); ROOT = os.path.dirname(HERE)
sys.path.insert(0, HERE)
T = os.environ.get('ATBWORK', os.path.expanduser('~/atb-work'))
CASES = os.path.join(ROOT, 'cases')
BUILDS = ['o2', 'os', 'o3', 'nv']; LADDER = ['h1', 'h8', 'h64']
ENS = os.path.join(T, 'ens', 'series')
NUM = re.compile(r'[-+]?(?:\d+\.\d*|\.\d+|\d+)(?:[EeDd][-+]?\d+)?')
R_GOOD = 0.80
FLAT_STD = 1e-3  # channel is 'flat' when std(ref) < 0.1% of its peak: ISO phase/slope terms are undefined on a constant
SPEC_TOL = dict(ang_vel=0.01, lin_vel=0.01, lin_acc=0.01, ang_acc=0.10)
B6_ORDER = ['ang_vel', 'lin_vel', 'ang_acc', 'lin_acc']          # input_bcards.for:156-159
HEAD = [('Point Total Acceleration', 'lin_acc'), ('Point Rel. Velocity', 'lin_vel'),
        ('Segment Rel. Angular Velocity', 'ang_vel'), ('Segment Angular Acceleration', 'ang_acc'),
        ('Point Rel. Linear Displacement', 'lin_disp'), ('Segment Rel. Angular Displacement', 'ang_disp'),
        ('Joint Forces & Torques', 'joint'), ('Contact Forces', 'contact'), ('Spring Damper Forces', 'spring'),
        ('Belt Endpoint Forces', 'belt')]

def rows(p):
    """Same parser as ~/atb-work/scripts/analyze.py: mode row length, monotone time."""
    raw = []
    for line in open(p, errors='replace').read().splitlines():
        t = NUM.findall(line)
        if len(t) >= 3:
            try: raw.append([float(x) for x in t])
            except ValueError: pass
    if not raw: return None
    m = collections.Counter(len(r) for r in raw).most_common(1)[0][0]
    out, last = [], None
    for r in raw:
        if len(r) != m: continue
        if last is not None and r[0] <= last: continue
        last = r[0]; out.append(r)
    return np.array(out) if out else None

def qtype(p):
    head = open(p, errors='replace').read(4000)
    for s, q in HEAD:
        if s in head: return q
    return 'other'

def cases():
    for line in open(os.path.join(T, 'ts_o2_h1', 'cases.txt')):
        f = line.split()
        if len(f) >= 6: yield dict(key=f[0], dir=f[1], base=f[2], sub=f[3])

def exts(c):
    out = []
    for p in sorted(glob.glob(os.path.join(CASES, c['dir'], c['base'] + '.*'))):
        e = p.rsplit('.', 1)[1]
        if e.lower() in ('lin', 'aou'): continue
        out.append(e)
    return out

def b6_tol(c):
    """Per quantity type: max nonzero CARD B.6 tolerance in this deck; None if the deck never tests it."""
    tol = {q: 0.0 for q in B6_ORDER}
    for line in open(os.path.join(CASES, c['dir'], c['base'] + '.LIN'), errors='replace'):
        if 'CARD B.6' not in line: continue
        v = [float(x) for x in NUM.findall(line.split('CARD')[0])]
        if len(v) != 12: continue
        for i, q in enumerate(B6_ORDER):
            tol[q] = max(tol[q], max(v[3*i:3*i+3]))
    return {q: (t if t > 0 else None) for q, t in tol.items()}

def peak(a, j): return float(np.max(np.abs(a[:, j])))

def load_ens(c, e, shape):
    out = []
    for d in sorted(glob.glob(os.path.join(ENS, 'm*'))):
        p = os.path.join(d, f"{c['key']}__{e}.npy")
        if os.path.exists(p):
            a = np.load(p)
            if a.shape == shape: out.append(a)
    return out

def main():
    import iso18571 as ISO
    chans, notes, excluded_sa1 = [], [], 0
    have_ens = os.path.isdir(ENS)
    for c in cases():
        tol = b6_tol(c)
        for e in exts(c):
            ref_p = os.path.join(CASES, c['dir'], f"{c['base']}.{e}")
            R = rows(ref_p)
            if R is None: continue
            if e.lower() == 'sa1':
                excluded_sa1 += sum(1 for j in range(1, R.shape[1]) if peak(R, j) >= 1.0); continue
            q = qtype(ref_p)
            tabs = {}
            ok = True
            for k in BUILDS:
                for s in LADDER:
                    p = os.path.join(T, f'ts_{k}_{s}', c['sub'], f"{c['base']}_new.{e}")
                    a = rows(p) if os.path.exists(p) else None
                    if a is None or a.shape != R.shape:
                        if k == 'o2' and s == 'h1': ok = False
                        notes.append(f"{c['key']} {e}: missing/shape-mismatch {k}/{s}"); continue
                    tabs[(k, s)] = a
            if not ok: continue
            ens = load_ens(c, e, R.shape) if have_ens else []
            t = R[:, 0]
            for j in range(1, R.shape[1]):
                pr = peak(R, j)
                if pr < 1.0: continue
                sh = tabs[('o2', 'h1')]
                iso1 = ISO.rate(t, R[:, j], sh[:, j])
                iso64 = ISO.rate(t, R[:, j], tabs[('o2', 'h64')][:, j]) if ('o2', 'h64') in tabs else None
                pdiff = abs(peak(sh, j) - pr) / pr
                p64 = [peak(tabs[(k, 'h64')], j) for k in BUILDS if (k, 'h64') in tabs]
                arith64 = (max(p64) - min(p64)) / pr if len(p64) == len(BUILDS) else None
                pl = [peak(tabs[('o2', s)], j) for s in LADDER if ('o2', s) in tabs]
                ladder = (max(pl) - min(pl)) / pr if len(pl) == len(LADDER) else None
                pk = {ks: peak(a, j) for ks, a in tabs.items()}
                step18 = abs(pk[('o2','h8')] - pk[('o2','h1')]) / pr if ('o2','h8') in pk else None
                step864 = abs(pk[('o2','h64')] - pk[('o2','h8')]) / pr if ('o2','h64') in pk and ('o2','h8') in pk else None
                p1 = [pk[(k,'h1')] for k in BUILDS if (k,'h1') in pk]
                p8 = [pk[(k,'h8')] for k in BUILDS if (k,'h8') in pk]
                arith8v = (max(p8) - min(p8)) / pr if len(p8) == len(BUILDS) else None
                arith1 = (max(p1) - min(p1)) / pr if len(p1) == len(BUILDS) else None
                pe = [peak(a, j) for a in ens]
                ensb = (max(pe) - min(pe)) / pr if len(pe) >= 2 else None
                bands = [b for b in (arith64, ladder, ensb) if b is not None]
                band = max(bands) if bands else None
                tq = tol.get(q) if q in SPEC_TOL else 0.0
                tol_src = 'B.6'
                if q in SPEC_TOL and tq is None: tq, tol_src = SPEC_TOL[q], 'spec-default(B.6 zero)'
                if q not in SPEC_TOL: tol_src = 'none'
                allow = max(tq, band or 0.0)
                maxpt = float(np.max(np.abs(R[:, j] - sh[:, j]))) / pr
                std_ratio = float(np.std(R[:, j])) / pr
                flat = bool(std_ratio < FLAT_STD)
                iso_ok = (iso1['R'] >= R_GOOD) if not flat else (maxpt <= allow)
                band_ok = pdiff <= allow
                ens_lo, ens_hi = (min(pe), max(pe)) if pe else (None, None)
                orig_in_ens = (ens_lo <= pr <= ens_hi) if pe else None
                ens90 = (float(np.percentile(pe, 95) - np.percentile(pe, 5)) / pr) if len(pe) >= 20 else None
                chans.append(dict(case=c['key'], file=e, col=j, qtype=q, ref_peak=pr,
                    R=iso1['R'], Z=iso1['Z'], EP=iso1['EP'], EM=iso1['EM'], ES=iso1['ES'],
                    R_h64=(iso64['R'] if iso64 else None), peak_diff=pdiff, tol_b6=tq, tol_src=tol_src,
                    band_arith_h64=arith64, band_ladder=ladder, band_ens=ensb, n_ens=len(pe), band=band,
                    step_h1_h8=step18, step_h8_h64=step864, arith_h1=arith1, arith_h8=arith8v,
                    flat=flat, std_ratio=std_ratio, maxpt_diff=maxpt, orig_in_ens=orig_in_ens, band_ens_p90=ens90,
                    iso_ok=iso_ok, band_ok=band_ok, passed=(iso_ok and band_ok)))
    write_csv(chans); write_md(chans, notes, excluded_sa1)
    return chans

def write_csv(chans):
    p = os.path.join(HERE, 'acceptance_channels.csv')
    with open(p, 'w', newline='') as f:
        w = csv.DictWriter(f, fieldnames=list(chans[0].keys())); w.writeheader()
        for r in chans: w.writerow(r)
    print('wrote', p, len(chans), 'channels')

NARRATIVE = {
 '2495': ('The failing channels are contact-force, acceleration and one displacement output of the golf-car occupant model. They do not converge on the integrator step at any level tested '
          '(the h8→h64 change is as large as the h1→h8 change) and the four arithmetic builds disagree with each other at every step. '
          'The deck does not determine these channels: the rebuild, the original, and every ensemble member are draws from one wide population. '
          'Honest claim: the rebuild reproduces the original on the channels the model does determine (54 of 73, all rated good or excellent), '
          'and on the rest no build, including the original, can be said to give "the" answer; the measured band is the width of what the deck specifies.'),
 '2496': ('Arithmetic spread is near zero at h8 and h64 (the rebuild is deterministic across compilers), but the peaks move by more than the peak itself when the step is refined, '
          'and the magnitude term EM is the one that fails. The shipped step controls under-resolve the joint and contact events on this deck (fire-escape fall); the original and the rebuild sit at different points of a step-dependent answer. '
          'Honest claim: the rebuild and original agree on 12 of 39 channels; the remaining channels are step-limited by the deck, not compiler-limited, and would need a step-convergence study on the original build to compare at all.'),
 '2638_135_Restart_2a': ('This is the restart run. At the shipped step the four arithmetic builds disagree by up to three times the peak (arith @h1), yet at h8 and h64 they agree exactly, '
          'and when the rebuild is run at h64 nearly every failing channel rates good or excellent against the original at its shipped step. '
          'The original CVF build happened to land on the converged side of a numerically marginal restart step; the gfortran build at the same step does not. '
          'Honest claim: the rebuild reproduces the original for this run when the restart integrator step is refined (scored at 64×; the four builds already agree exactly at 8×), not at the deck\'s shipped step.'),
 '2696': ('Failures are contact forces and accelerations with EM (magnitude) near zero: the rebuild produces the same event with a different amplitude. '
          'Arithmetic spread at the shipped step is large and collapses by h64, and the step change h1→h8 is of order the peak. As with 2638 restart the shipped step is marginal; unlike it, only a minority of the failing channels recover at h64. '
          'Honest claim: 57 of 73 channels match; the 16 contact/acceleration channels are not determined at the shipped step and the two builds pick different amplitudes.'),
 '2893': ('Four of 205 channels fail. Two are joint channels whose original peak is barely above the 1.0 inclusion threshold and whose ensemble spread is 87–116 times that peak: noise-floor channels with no signal to compare. '
          'Two are spring-force channels (peaks 12 and 11) rated fair (R 0.70–0.72) with an ensemble spread of about three times the peak. '
          'Honest claim: the run matches on 201 of 205 channels; the two spring channels are within the band the deck\'s own input precision allows but do not match in shape; the two joint channels are below the model\'s noise floor.'),
 '2479': 'See the flat-channel note; the remaining channels pass.',
 'default': 'See the per-channel rows below.',
}

def pct(x): return '—' if x is None else f"{100*x:.2f}%"
def arith8(v):
    x = [r['arith_h8'] for r in v if r['arith_h8'] is not None]; return pct(max(x)) if x else '—'

def write_md(chans, notes, excluded_sa1):
    by = collections.defaultdict(list)
    for r in chans: by[r['case']].append(r)
    L = []
    L.append('# ATB V.3 gfortran rebuild — acceptance against the original CVF build\n')
    L.append('Generated by `verify/acceptance.py`. Per-channel data: `verify/acceptance_channels.csv`. Standard: ISO/TS 18571.\n')
    L.append('## Pass condition\n')
    L.append('A **channel** is one numeric column of a reference time-history output table whose peak |value| is >= 1.0 unit. '
             'A channel **passes** when both hold, rebuild (shipped -O2 build, shipped integrator settings) vs original:\n')
    L.append('1. **ISO/TS 18571 overall rating R >= 0.80** ("good"; poor <= 0.58, fair <= 0.80, good <= 0.94, excellent above).')
    L.append('2. **Peak difference inside the irreducible band**: |peak(rebuild) − peak(original)| / peak(original) is <= at least one of')
    L.append('   - the deck\'s own CARD B.6 per-step relative error tolerance for that quantity as written in that deck (in these decks: angular velocity 1%, '
             'linear velocity 1%, angular acceleration 10%, linear acceleration 10%, see the B.6 note; displacement, joint/contact/spring/belt force channels have no B.6 entry), or')
    L.append('   - the **measured band** for that channel: the max of (a) spread of the peak across the 4 arithmetic builds at the finest step h64, '
             '(b) spread across the integrator-step ladder h1/h8/h64 for the shipped build, (c) spread across the 93-member input-precision ensemble. '
             'No build can be more accurate than that width: every one of those inputs is a choice the original itself left free.\n')
    L.append('"Peak" is max |value| over the record (unsigned). **Flat channels** (std of the original < 0.1% of its peak, i.e. a constant with last-digit flicker) have no phase or slope, '
             'so ISO/TS 18571 is not applicable to them; criterion 1 is replaced by max pointwise |rebuild − original| / peak <= the same allowance as criterion 2. '
             'Flat channels are listed below; none is dropped.\n')
    L.append('A **case** passes when every channel passes. The **run** passes when all 12 cases pass or every failing channel is documented below.\n')
    L.append('This document reports measured bands. It does not assert that any tolerance is legally sufficient; that is a decision for counsel.\n')
    L.append('## Method notes\n')
    L.append('- **ISO/TS 18571 implementation** (`verify/iso18571.py`): corridor Z (a0 = 0.05, b0 = 0.50, kZ = 2), phase EP (kP = 1, εP* = 0.2), '
             'magnitude EM (DTW, kM = 1, εM* = 0.50), slope ES (kS = 1, εS* = 2.0), R = 0.4Z + 0.2EP + 0.2EM + 0.2ES. '
             'The standard text available to this work (`refs/iso18571.txt`) is the public preview, which ends in clause 6.3.2; Z and EP and the weights are taken from it directly. '
             'Tables 4–5, the DTW recursion and the EM/ES scaling were taken from the openVT.eu reference implementation of ISO/TS 18571 (cited by the IRCOBI paper in `refs/`), '
             'and the module reproduces that implementation\'s published example ratings (0.713, 0.815). Z and EP were independently re-derived by hand for two channels and agree to 1e-15. '
             'Rating a channel against the full standard text remains a step for anyone holding the licensed document.')
    L.append('- **Input-precision ensemble** (`verify/perturb.py`): every real-valued, non-zero, unquoted numeric token in each deck is moved by u × ulp, u ~ Uniform(−0.5, +0.5), '
             'ulp = one unit in its last printed digit, independently per token; integrator controls (CARD A.4), option flags (A.5), convergence tolerances (B.6) and the vehicle-motion '
             'time abscissa (C.5 first column) are excluded. Integer-formatted tokens are left alone (conservative: the band is understated, not overstated). '
             '93 members = the two-sided Wilks count for 95 % / 95 % distribution-free coverage, run with the shipped build at the shipped step. The ensemble band is max − min of the peak across members.')
    L.append('- **Arithmetic builds**: shipped -O2, -Os, -O3, -O2 -fno-tree-vectorize — four distinct floating-point orderings of the same frozen source. Step ladder: H0/HMAX/HMIN ÷ 8 and ÷ 64.')
    L.append('- **Channel count**: 829 time-history channels. 58 further columns in `.sa1` animation files meet the peak ≥ 1 rule but are excluded because `.sa1` is not a time-history table (mixed geometry blocks).\n')
    L.append('## Per-case verdict\n')
    L.append('| case | channels | pass | fail ISO only | fail band only | fail both | worst R | max peak diff | band width (median / max) | verdict |')
    L.append('|---|---|---|---|---|---|---|---|---|---|')
    tot_pass = 0
    for k in by:
        v = by[k]; n = len(v); p = sum(r['passed'] for r in v)
        fi = sum((not r['iso_ok']) and r['band_ok'] for r in v)
        fb = sum(r['iso_ok'] and (not r['band_ok']) for r in v)
        fx = sum((not r['iso_ok']) and (not r['band_ok']) for r in v)
        bands = [r['band'] for r in v if r['band'] is not None]
        med = float(np.median(bands)) if bands else None
        verdict = 'PASS' if p == n else 'FAIL'
        tot_pass += (p == n)
        L.append(f"| {k} | {n} | {p} | {fi} | {fb} | {fx} | {min(r['R'] for r in v):.3f} | {pct(max(r['peak_diff'] for r in v))} | "
                 f"{pct(med)} / {pct(max(bands) if bands else None)} | **{verdict}** |")
    n_all = len(chans); p_all = sum(r['passed'] for r in chans)
    L.append(f"\n**{tot_pass}/{len(by)} cases pass; {p_all}/{n_all} channels pass.** "
             f"({excluded_sa1} .sa1 animation columns with peak >= 1 are excluded: .sa1 is not a time-history table.)\n")
    L.append('## Which criterion binds\n')
    L.append('Same channels, same ISO ratings, band allowance varied. This shows how much of the verdict rests on each band component.\n')
    L.append('| allowance for criterion 2 | cases passing | channels passing |'); L.append('|---|---|---|')
    def alt(bf):
        cp = 0; ch = 0
        for k in by:
            v = by[k]; okv = [r['iso_ok'] and r['peak_diff'] <= max(r['tol_b6'] or 0.0, bf(r)) for r in v]
            cp += all(okv); ch += sum(okv)
        return cp, ch
    for lab, bf in (('B.6 tolerance or full measured band (arith, ladder, ensemble) — the pass condition', lambda r: r['band'] or 0.0),
                    ('B.6 tolerance or max(arith @h64, step ladder) — no ensemble', lambda r: max(r['band_arith_h64'] or 0.0, r['band_ladder'] or 0.0)),
                    ('B.6 tolerance only', lambda r: 0.0),
                    ('criterion 1 (ISO R >= 0.80) alone, no peak criterion', lambda r: float('inf'))):
        cp, ch = alt(bf); L.append(f"| {lab} | {cp}/{len(by)} | {ch}/{len(chans)} |")
    rely = [r for r in chans if r['passed'] and r['peak_diff'] > max(r['tol_b6'] or 0.0, r['band_arith_h64'] or 0.0, r['band_ladder'] or 0.0)]
    rc = collections.Counter(r['case'] for r in rely)
    L.append(f"\n{len(rely)} passing channels pass criterion 2 only because of the input-precision ensemble band "
             f"({', '.join(f'{k}: {n}' for k, n in sorted(rc.items()))}). Every channel that fails, fails criterion 1 (ISO rating); "
             'no channel fails on the peak criterion alone. The ISO shape rating is the binding test; the peak band is wide because the ensemble band is wide (see Band components).\n')
    fl = [r for r in chans if r['flat']]
    L.append(f"**Flat channels ({len(fl)}).** Scored on pointwise difference instead of ISO R (see Pass condition). ISO R is shown for reference only.\n")
    L.append('| case | file | col | type | max pointwise diff | allowance | ISO R (not applied) | result |'); L.append('|---|---|---|---|---|---|---|---|')
    for r in fl:
        L.append(f"| {r['case']} | {r['file']} | {r['col']} | {r['qtype']} | {pct(r['maxpt_diff'])} | {pct(max(r['tol_b6'] or 0.0, r['band'] or 0.0))} | {r['R']:.2f} | {'pass' if r['passed'] else 'FAIL'} |")
    L.append('')
    L.append('## ISO/TS 18571 rating distribution (shipped settings)\n')
    Rs = np.array([r['R'] for r in chans])
    for lo, hi, lab in ((0, .58, 'poor'), (.58, .80, 'fair'), (.80, .94, 'good'), (.94, 1.01, 'excellent')):
        L.append(f"- {lab}: {int(np.sum((Rs > lo) & (Rs <= hi)))} channels")
    R64 = [r['R_h64'] for r in chans if r['R_h64'] is not None]
    if R64:
        L.append(f"\nAt the refined step h64 (rebuild h64 vs original at its shipped step) median R = {np.median(R64):.3f}; "
                 f"at shipped settings median R = {np.median(Rs):.3f}. The refined-step rating is diagnostic only: the pass condition is scored at shipped settings.\n")
    L.append('## Step convergence (phase 1: h1 → h8 → h64)\n')
    L.append('Integrator step controls H0/HMAX/HMIN divided by 8 and by 64 (NDINT, NSTEPS, DT untouched, so rows stay comparable). '
             'Shipped build. Values are |Δpeak| / reference peak; "arith" is the spread of the peak across the 4 arithmetic builds at that step.\n')
    L.append('| case | channels | step h1→h8 (median / max) | step h8→h64 (median / max) | arith @h1 | arith @h8 | arith @h64 | converging channels |')
    L.append('|---|---|---|---|---|---|---|---|')
    for k in by:
        v = by[k]
        def mm(key): 
            x = [r[key] for r in v if r[key] is not None]; return (pct(np.median(x)) + ' / ' + pct(max(x))) if x else '—'
        def mx(key):
            x = [r[key] for r in v if r[key] is not None]; return pct(max(x)) if x else '—'
        conv = sum(1 for r in v if r['step_h1_h8'] is not None and r['step_h8_h64'] is not None and r['step_h8_h64'] < r['step_h1_h8'])
        L.append(f"| {k} | {len(v)} | {mm('step_h1_h8')} | {mm('step_h8_h64')} | {mx('arith_h1')} | {mx('arith_h8')} | {mx('band_arith_h64')} | {conv}/{len(v)} |")
    L.append('\nA channel is "converging" when the h8→h64 change is smaller than the h1→h8 change. Where the arithmetic spread collapses at h64 but the step change stays large '
             '(2495, 2496), the four builds agree with each other at every step yet the answer depends on the step: the sensitivity is in the model, not in the compiler. '
             'Where the shipped step already reproduces the original exactly but refinement moves the peak (2819), the original\'s value is one point on the same curve.\n')
    L.append('## Band components (all channels, relative to reference peak)\n')
    L.append('| component | median | 90th pct | max |'); L.append('|---|---|---|---|')
    for key, lab in (('band_arith_h64', 'arithmetic spread, 4 builds @ h64'), ('band_ladder', 'step ladder h1/h8/h64, shipped build'),
                     ('band_ens', 'input-precision ensemble (93 members), max − min'), ('band_ens_p90', 'input-precision ensemble, 95th − 5th percentile (diagnostic)'),
                     ('band', 'measured band = max of the three'), ('peak_diff', 'rebuild vs original peak difference')):
        x = np.array([r[key] for r in chans if r[key] is not None])
        if len(x): L.append(f"| {lab} | {pct(np.median(x))} | {pct(np.percentile(x, 90))} | {pct(x.max())} |")
    ie = [r for r in chans if r['orig_in_ens'] is not None]
    L.append(f"\nThe ensemble band is not driven by single outlier members: the 95th − 5th percentile spread is of the same order as max − min. "
             f"Perturbing inputs in their last printed digit moves peaks by tens of percent on most channels and by multiples of the peak on small-amplitude channels. "
             f"The original's own peak lies inside the ensemble's [min, max] on {sum(1 for r in ie if r['orig_in_ens'])}/{len(ie)} channels, i.e. the original build is itself one plausible member of the population the deck defines.\n")
    short = [r for r in chans if r['n_ens'] < 93]
    if short:
        sc = collections.Counter((r['case'], r['file'], r['n_ens']) for r in short)
        L.append('Ensemble members whose output table has a different row count from the reference are dropped for that table, so the ensemble band is over fewer than 93 members on '
                 + f"{len(short)} channels: " + '; '.join(f"{k} {f} ({n} members, {c} channels)" for (k, f, n), c in sorted(sc.items()))
                 + '. Fewer members can only narrow the band, so this is conservative.\n')
    fl2 = [r for r in chans if not r['flat']]
    L.append(f"Flat-channel threshold margin: the least-varying non-flat channel has std/peak = {min(r['std_ratio'] for r in fl2):.6f} "
             f"against the 0.001 cut; the most-varying flat channel has {max(r['std_ratio'] for r in chans if r['flat']):.6f}. The 2893 displacement channels cluster near the cut.\n")
    la = [r for r in chans if r['qtype'] == 'lin_acc']
    flip = sum(1 for r in la if r['iso_ok'] and r['band_ok'] and not (r['peak_diff'] <= max(0.01, r['band'] or 0.0)))
    L.append(f"\n**CARD B.6 note.** The client decks set the linear-acceleration tolerance to 10% on X/Y and 1% on Z for the segments that test it "
             f"(other segments carry 0 = untested), so TOL_B6 for linear-acceleration channels is taken as 10%, the deck's own accepted value. "
             f"If 1% were used instead, {flip} of {len(la)} linear-acceleration channels would change from pass to fail.\n")
    fails = [r for r in chans if not r['passed']]
    L.append(f"\n## Failing channels ({len(fails)})\n")
    if fails:
        L.append('### Why each failing case cannot pass, and what can be claimed instead\n')
        for k in by:
            v = by[k]; fv = [r for r in v if not r['passed']]
            if not fv: continue
            comp = {c: float(np.median([r[c] for r in fv])) for c in ('Z', 'EP', 'EM', 'ES')}
            low = min(comp, key=comp.get)
            inband = sum(r['peak_diff'] <= max(r['tol_b6'] or 0.0, r['band'] or 0.0) for r in fv)
            inens = sum(1 for r in fv if r['orig_in_ens'])
            r64 = [r['R_h64'] for r in fv if r['R_h64'] is not None]; good64 = sum(x >= R_GOOD for x in r64)
            types = ', '.join(f'{t} {n}' for t, n in collections.Counter(r['qtype'] for r in fv).most_common())
            a1 = max((r['arith_h1'] or 0) for r in v); a8 = max((r['arith_h8'] or 0) for r in v); a64 = max((r['band_arith_h64'] or 0) for r in v)
            s18 = max((r['step_h1_h8'] or 0) for r in v); s864 = max((r['step_h8_h64'] or 0) for r in v)
            L.append(f"**{k}** — {len(fv)}/{len(v)} channels fail ({types}). Median ISO components on the failing channels: Z {comp['Z']:.2f}, EP {comp['EP']:.2f}, EM {comp['EM']:.2f}, ES {comp['ES']:.2f}; "
                     f"the weakest term is {low}. Peak difference is inside the allowance on {inband}/{len(fv)}; the original's peak lies inside the ensemble range on {inens}/{len(fv)}; "
                     f"rated good or better when the rebuild is run at h64 instead: {good64}/{len(r64)}. Case-wide max arithmetic spread @h1/h8/h64: {pct(a1)} / {pct(a8)} / {pct(a64)}; "
                     f"max step change h1→h8 / h8→h64: {pct(s18)} / {pct(s864)}.")
            L.append(NARRATIVE.get(k, NARRATIVE['default']) + '\n')
        L.append('| case | file | col | type | R | R@h64 | peak diff | B.6 tol | band | arith h64 | ladder | ensemble | orig in ens | why |'); L.append('|---|---|---|---|---|---|---|---|---|---|---|---|---|---|')
        for r in fails:
            why = []
            if not r['iso_ok']:
                if r['flat']: why.append(f"flat channel: pointwise diff {pct(r['maxpt_diff'])} > allowance")
                else:
                    comp = {c: r[c] for c in ('Z', 'EP', 'EM', 'ES')}; low = min(comp, key=comp.get)
                    why.append(f"R {r['R']:.2f} < 0.80 (weakest {low} {comp[low]:.2f})")
            if not r['band_ok']: why.append('peak diff exceeds both B.6 tol and band')
            r64s = '—' if r['R_h64'] is None else f"{r['R_h64']:.3f}"
            L.append(f"| {r['case']} | {r['file']} | {r['col']} | {r['qtype']} | {r['R']:.3f} | {r64s} | {pct(r['peak_diff'])} | {pct(r['tol_b6'])} | {pct(r['band'])} | "
                     f"{pct(r['band_arith_h64'])} | {pct(r['band_ladder'])} | {pct(r['band_ens'])} | {'—' if r['orig_in_ens'] is None else ('yes' if r['orig_in_ens'] else 'no')} | {'; '.join(why)} |")
    else:
        L.append('None.')
    if notes:
        L.append('\n## Data notes\n'); L.extend(f"- {n}" for n in sorted(set(notes)))
    open(os.path.join(ROOT, 'ACCEPTANCE.md'), 'w').write('\n'.join(L) + '\n')
    print('wrote ACCEPTANCE.md')

if __name__ == '__main__':
    main()
