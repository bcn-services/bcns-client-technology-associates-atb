#!/usr/bin/env python3
"""ISO/TS 18571 objective rating metric for non-ambiguous time-history signals.

Implements the four sub-ratings and the combined overall rating R of
ISO/TS 18571:2014, "Road vehicles -- Objective rating metric for non-ambiguous
signals":

    R = wZ*Z + wP*EP + wM*EM + wS*ES            Clause 6.1, Formula (1)

  Z   corridor score                            Clause 6.2, Formulae (3)-(9)
  EP  phase score        (EEARTH)               Clause 6.3.1, Formulae (10)-(12)
  EM  magnitude score    (EEARTH, DTW-aligned)  Clause 6.3.2
  ES  slope score        (EEARTH, derivatives)  Clause 6.3.3

PARAMETERS AND WHERE THEY COME FROM
-----------------------------------
Clause 6.1, Table 1 -- weighting factors:
    wZ = 0.40, wP = 0.20, wM = 0.20, wS = 0.20      (sum = 1, Formula (2))

Clause 6.2.1, Table 2 -- corridor metric:
    a0 = 0.05   relative half width of the inner corridor
    b0 = 0.50   relative half width of the outer corridor
    kZ = 2      progression of the 1 -> 0 transition between the corridors
  Tnorm = max(|min(T)|, |max(T)|) over the evaluation interval, Formula (3);
  delta_i = a0*Tnorm (4), delta_o = b0*Tnorm (5); Z(t) per Formula (8);
  Z = sum(Z(t))/N per Formula (9).

Clause 6.3.1, Table 3 -- phase score:
    kP      = 1     exponent factor
    eps_P*  = 0.2   maximum allowable percentage of time shift
  The test (CAE) curve is shifted left then right one sample at a time up to
  eps_P*(t_end - t_start); rho_L(m) / rho_R(m) are the mean-removed Pearson
  cross correlations of Formulae (10) and (11) over the n = N - m overlapping
  samples.  n_eps is the shift giving the maximum rho_E; EP from Formula (12).
  Ambiguity resolved: when several shifts tie at rho_E the SMALLEST |shift| is
  kept (the standard says n_eps is "the number of time shifting steps that
  yields the maximum cross correlation" without a tie rule; taking the smallest
  shift is the only choice that keeps EP=1 for identical signals and matches
  the TU Graz reference implementation).

Clause 6.3.2, Table 4 -- magnitude score:
    kM      = 1     exponent factor
    eps_M*  = 0.50  maximum allowable magnitude error
  Cts and Tts (the phase-shifted, truncated curves from 6.3.1) are aligned by
  dynamic time warping.  Local cost matrix d(i,j) = (Cts(i) - Tts(j))^2
  (pair-wise SQUARED distances, 6.3.2); cumulative cost
  dtw[i,j] = d(i,j) + min(dtw[i-1,j], dtw[i,j-1], dtw[i-1,j-1]) (symmetric
  step pattern, unit weights); the optimal warping path w is recovered by
  backtracking from (n-1, n-1) to (0,0) and gives the warped curves Cts+w and
  Tts+w of length nw.  Then
      eps_mag = sum|Cts+w - Tts+w| / sum|Tts+w|
      EM = 1                              if eps_mag == 0
         = ((eps_M* - eps_mag)/eps_M*)^kM if 0 < eps_mag < eps_M*
         = 0                              if eps_mag >= eps_M*

Clause 6.3.3, Table 5 -- slope score:
    kS      = 1     exponent factor
    eps_S*  = 2.0   maximum allowable slope error
  Derivative curves Cts+d and Tts+d are formed from Cts and Tts by central
  differences and then smoothed with a nine-point moving average (the window
  shrinks symmetrically to 7, 5, 3 and 1 points at the four samples nearest
  each end, so every output point stays centred on its own sample).  Then
      eps_slope = sum|Cts+d - Tts+d| / sum|Tts+d|
      ES = (eps_S* - eps_slope)/eps_S*   clipped to [0, 1]
  eps_slope is a ratio of derivative L1 norms, so the value of dt cancels
  exactly and only the sample spacing regularity matters.

DTW window (user-selectable in the 2014 text, fixed here):
    dtw_window = 0.10 of the data length, as a Sakoe-Chiba band |i - j| <= w
    with w = ceil(0.10*n) - 1.
  ISO/TS 18571:2024 makes this explicit in its foreword ("More descriptions
  about window size for Dynamic Time Warping were provided.  Ten percent of
  data length was used as window size."), so 10 % is the standard's own
  default and is used here.

Clause 7 -- meaning of the overall rating (see label()):
    R <= 0.58 poor, <= 0.80 fair, <= 0.94 good, above that excellent.

PROVENANCE NOTE
---------------
The copy of the standard used here, refs/iso18571.txt, is the public iTeh
preview and stops mid-6.3.2 (page 9), so Tables 4 and 5, the DTW recursion and
the eps_mag / eps_slope formulae could not be read directly from it.  Those
were taken from the ISO18571 reference implementation published by Graz
University of Technology (openvt.eu/validation-metrics/ISO18571, the
implementation cited by the IRCOBI paper in refs/ircobi.txt) and cross-checked
against the symbol list in Clause 4 of the preview, which names every quantity
used above (Cts+w, Tts+w, DTWopt(i,j), d(i,j), nw, eps_mag, eps_slope,
eps_M*, eps_S*, kM, kS).  Everything in Clauses 6.1, 6.2 and 6.3.1 is read
directly from refs/iso18571.txt.

Pre-processing (Clause 8) is NOT performed here: the caller supplies the
common time base, the common evaluation interval and any filtering.  Clause 8.2
asks for a 10 kHz sampling rate; the metric itself is resolution independent
because every threshold (eps_P*, the DTW window) is a fraction of N.

Only numpy and the standard library are used.  Nothing here is tied to a
numpy version (verified on 1.26 and 2.5).  Note that on this machine the
default /usr/bin/python3 (3.9) has no numpy: run with /opt/homebrew/bin/
python3.13 or /usr/local/bin/python3.12.

    python3.13 verify/iso18571.py                  # run the self test
    python3.13 verify/iso18571.py ref.t21 test.t21 # per-column Z EP EM ES R
"""

import collections
import math
import re
import sys

import numpy as np

# --- Table 1 (6.1) -----------------------------------------------------------
W_Z, W_P, W_M, W_S = 0.4, 0.2, 0.2, 0.2
# --- Table 2 (6.2.1) ---------------------------------------------------------
A_0, B_0, K_Z = 0.05, 0.50, 2
# --- Table 3 (6.3.1) ---------------------------------------------------------
K_P, EPS_P_MAX = 1, 0.2
# --- Table 4 (6.3.2) ---------------------------------------------------------
K_M, EPS_M_MAX = 1, 0.50
# --- Table 5 (6.3.3) ---------------------------------------------------------
K_S, EPS_S_MAX = 1, 2.0
# --- DTW Sakoe-Chiba window, 10 % of the data length -------------------------
DTW_WINDOW = 0.10

# Clause 7 thresholds.
_LABELS = ((0.58, "poor"), (0.80, "fair"), (0.94, "good"))


def label(R):
    """Clause 7: poor <= 0.58, fair <= 0.80, good <= 0.94, excellent above."""
    for hi, name in _LABELS:
        if R <= hi:
            return name
    return "excellent"


# -----------------------------------------------------------------------------
# 6.2 Corridor score
# -----------------------------------------------------------------------------
def corridor_score(ref, test, a0=A_0, b0=B_0, kz=K_Z):
    """Z per Formulae (3)-(9).  ref and test are 1-D arrays of equal length."""
    t_norm = float(np.max(np.abs(ref)))  # Formula (3)
    diff = np.abs(ref - test)
    if t_norm == 0.0:
        # Degenerate reference: the corridors collapse to zero width.
        return float(np.mean(diff == 0.0))
    d_i = a0 * t_norm  # Formula (4)
    d_o = b0 * t_norm  # Formula (5)
    with np.errstate(invalid="ignore"):
        z = ((d_o - diff) / (d_o - d_i)) ** kz  # Formula (8), middle branch
    z = np.where(diff < d_i, 1.0, z)
    z = np.where(diff > d_o, 0.0, z)
    return float(np.sum(z) / len(diff))  # Formula (9)


# -----------------------------------------------------------------------------
# 6.3.1 Phase score
# -----------------------------------------------------------------------------
def _corr(a, b):
    """Mean-removed cross correlation of Formulae (10)/(11); nan-safe."""
    a = a - a.mean()
    b = b - b.mean()
    den = math.sqrt(float(a @ a) * float(b @ b))
    if den == 0.0:
        return -np.inf  # undefined -> never wins the maximum
    return float(a @ b) / den


def _phase_shift(ref, test, eps_p=EPS_P_MAX):
    """Return (n_eps signed, rho_E, Cts, Tts).

    n_eps > 0 means the test curve was shifted LEFT by n_eps samples, i.e. the
    test signal lagged the reference by that many samples (Formula (10)).
    n_eps < 0 is the mirrored case of Formula (11).
    """
    n_total = len(ref)
    max_m = int(math.floor(n_total * eps_p))
    best_rho = _corr(ref, test)
    best_m = 0
    cts, tts = test, ref
    for m in range(1, max_m + 1):
        # rho_L(m): C moved to the left, C(t_start + (m+i)dt) vs T(t_start + i dt)
        rho_l = _corr(ref[: n_total - m], test[m:])
        if rho_l > best_rho:
            best_rho, best_m = rho_l, m
            tts, cts = ref[: n_total - m], test[m:]
        # rho_R(m): C moved to the right
        rho_r = _corr(ref[m:], test[: n_total - m])
        if rho_r > best_rho:
            best_rho, best_m = rho_r, -m
            tts, cts = ref[m:], test[: n_total - m]
    if best_rho == -np.inf:
        best_rho = 0.0
    return best_m, best_rho, np.asarray(cts, float), np.asarray(tts, float)


def _phase_score(n_eps, n_total, eps_p=EPS_P_MAX, kp=K_P):
    """EP per Formula (12)."""
    thresh = n_total * eps_p  # eps_P* * N
    n_eps = abs(n_eps)
    if n_eps == 0:
        return 1.0
    if n_eps >= thresh:
        return 0.0
    return float(((thresh - n_eps) / thresh) ** kp)


# -----------------------------------------------------------------------------
# 6.3.2 Magnitude score -- dynamic time warping
# -----------------------------------------------------------------------------
def _dtw_path(x, y, window=DTW_WINDOW):
    """Optimal warping path for equal-length x, y under a Sakoe-Chiba band.

    Local cost d(i,j) = (x_i - y_j)^2; cumulative cost
    dtw[i,j] = d(i,j) + min(dtw[i-1,j], dtw[i,j-1], dtw[i-1,j-1]).
    Returns (i_path, j_path) as int arrays running from (0,0) to (n-1,n-1).

    Solved diagonal by diagonal (s = i + j) so each anti-diagonal is one
    vectorised numpy step; work and memory are O(window * n^2), not O(n^2)
    dense, because only cells inside the band are ever touched.
    """
    n = len(x)
    if n == 1:
        return np.zeros(1, int), np.zeros(1, int)
    w = max(0, int(math.ceil(window * n)) - 1)

    INF = np.inf
    # Diagonals are indexed by i; slot 0 is a -1 sentinel, so value at i is [i+1].
    prev2 = np.full(n + 1, INF)  # diagonal s-2
    prev1 = np.full(n + 1, INF)  # diagonal s-1
    steps = []  # per diagonal: (i_lo, int8 array of argmin choices)

    for s in range(0, 2 * n - 1):
        i_lo = max(0, s - (n - 1), int(math.ceil((s - w) / 2.0)))
        i_hi = min(n - 1, s, int(math.floor((s + w) / 2.0)))
        if i_lo > i_hi:
            steps.append((0, np.zeros(0, np.int8)))
            prev2, prev1 = prev1, np.full(n + 1, INF)
            continue
        idx = np.arange(i_lo, i_hi + 1)
        cost = (x[idx] - y[s - idx]) ** 2
        if s == 0:
            cur = np.full(n + 1, INF)
            cur[1] = cost[0]
            steps.append((i_lo, np.zeros(1, np.int8)))
        else:
            # candidates: 0 -> (i-1, j) from prev1, 1 -> (i, j-1) from prev1,
            #             2 -> (i-1, j-1) from prev2
            cand = np.vstack(
                (
                    prev1[idx],       # prev1 at i-1  == slot (i-1)+1 == idx
                    prev1[idx + 1],   # prev1 at i    == slot i+1
                    prev2[idx],       # prev2 at i-1
                )
            )
            choice = np.argmin(cand, axis=0).astype(np.int8)
            best = cand[choice, np.arange(len(idx))]
            cur = np.full(n + 1, INF)
            cur[idx + 1] = cost + best
            steps.append((i_lo, choice))
        prev2, prev1 = prev1, cur

    # Backtrack from (n-1, n-1).
    i, j = n - 1, n - 1
    ip, jp = [i], [j]
    while i > 0 or j > 0:
        s = i + j
        i_lo, choice = steps[s]
        c = int(choice[i - i_lo])
        if c == 0:
            i -= 1
        elif c == 1:
            j -= 1
        else:
            i -= 1
            j -= 1
        ip.append(i)
        jp.append(j)
    return np.array(ip[::-1], int), np.array(jp[::-1], int)


def _magnitude_score(cts, tts, eps_m=EPS_M_MAX, km=K_M, window=DTW_WINDOW):
    """EM per 6.3.2.  cts/tts are the phase-shifted, truncated curves."""
    ip, jp = _dtw_path(cts, tts, window)
    c_w, t_w = cts[ip], tts[jp]
    den = float(np.sum(np.abs(t_w)))
    num = float(np.sum(np.abs(c_w - t_w)))
    if den == 0.0:
        eps_mag = 0.0 if num == 0.0 else np.inf
    else:
        eps_mag = num / den
    if eps_mag == 0.0:
        return 1.0, 0.0
    if eps_mag >= eps_m:
        return 0.0, eps_mag
    return float(((eps_m - eps_mag) / eps_m) ** km), eps_mag


# -----------------------------------------------------------------------------
# 6.3.3 Slope score
# -----------------------------------------------------------------------------
def _derivative(y, dt):
    """Central-difference derivative smoothed by a centred moving average.

    Nine points in the interior; the window shrinks to 7, 5, 3 and 1 points at
    the four samples nearest each end so that every output sample stays
    centred on itself.
    """
    d0 = np.gradient(y, dt)
    n = len(d0)
    if n < 9:
        return d0
    d = np.empty(n)
    for k, nr in enumerate((1, 3, 5, 7)):
        d[k] = d0[:nr].mean()
        d[n - 1 - k] = d0[n - nr:].mean()
    d[4:-4] = np.convolve(d0, np.ones(9) / 9.0, mode="valid")
    return d


def _slope_score(cts, tts, dt, eps_s=EPS_S_MAX, ks=K_S):
    """ES per 6.3.3."""
    c_d = _derivative(cts, dt)
    t_d = _derivative(tts, dt)
    den = float(np.sum(np.abs(t_d)))
    num = float(np.sum(np.abs(c_d - t_d)))
    if den == 0.0:
        eps_slope = 0.0 if num == 0.0 else np.inf
    else:
        eps_slope = num / den
    if eps_slope <= 0.0:
        return 1.0, 0.0
    if eps_slope >= eps_s:
        return 0.0, eps_slope
    return float(((eps_s - eps_slope) / eps_s) ** ks), eps_slope


# -----------------------------------------------------------------------------
# Public API
# -----------------------------------------------------------------------------
def rate(t, ref, test):
    """Rate one signal pair against ISO/TS 18571.

    Parameters
    ----------
    t    : 1-D numpy array, the common time base (Clause 5: same N, constant dt)
    ref  : 1-D numpy array, the reference / test-measurement signal T
    test : 1-D numpy array, the analysed / CAE signal C

    Returns a dict with Z, EP, EM, ES, R, the signed phase shift in samples
    (`shift`; positive means the analysed signal lags the reference) and, for
    diagnosis, `shift_time`, `rho`, `eps_mag`, `eps_slope`, `n`, `label`.
    """
    t = np.asarray(t, dtype=float).ravel()
    ref = np.asarray(ref, dtype=float).ravel()
    test = np.asarray(test, dtype=float).ravel()
    if not (len(t) == len(ref) == len(test)):
        raise ValueError(
            "t, ref and test must have the same length (Clause 5): "
            f"{len(t)}, {len(ref)}, {len(test)}"
        )
    n = len(ref)
    if n < 2:
        raise ValueError("need at least 2 samples")
    dt = float(np.mean(np.diff(t))) if n > 1 else 1.0
    if dt == 0.0:
        dt = 1.0

    z = corridor_score(ref, test)
    n_eps, rho, cts, tts = _phase_shift(ref, test)
    ep = _phase_score(n_eps, n)
    em, eps_mag = _magnitude_score(cts, tts)
    es, eps_slope = _slope_score(cts, tts, dt)
    r = W_Z * z + W_P * ep + W_M * em + W_S * es  # Formula (1)

    return {
        "Z": z,
        "EP": ep,
        "EM": em,
        "ES": es,
        "R": r,
        "shift": n_eps,
        "shift_time": n_eps * dt,
        "rho": rho,
        "eps_mag": eps_mag,
        "eps_slope": eps_slope,
        "n": n,
        "label": label(r),
    }


def rate_table(ref_rows, test_rows):
    """Rate every data column of two tables produced by rows().

    ref_rows / test_rows are lists of equal-length numeric rows whose column 0
    is time.  Returns a list of rate() dicts, one per column 1..n-1.
    """
    if not ref_rows or not test_rows:
        raise ValueError("empty table")
    if len(ref_rows) != len(test_rows):
        raise ValueError(
            f"row count differs: ref {len(ref_rows)}, test {len(test_rows)}"
        )
    ncol = len(ref_rows[0])
    if len(test_rows[0]) != ncol:
        raise ValueError(
            f"column count differs: ref {ncol}, test {len(test_rows[0])}"
        )
    a = np.asarray(ref_rows, dtype=float)
    b = np.asarray(test_rows, dtype=float)
    t = a[:, 0]
    return [rate(t, a[:, j], b[:, j]) for j in range(1, ncol)]


# -----------------------------------------------------------------------------
# Parser -- copied verbatim from scripts/analyze.py / verify/atbcmp.py so that
# this module has no dependency outside numpy + stdlib.
# -----------------------------------------------------------------------------
NUM = re.compile(r'[-+]?(?:\d+\.\d*|\.\d+|\d+)(?:[EeDd][-+]?\d+)?')


def rows(p):
    raw = []
    for line in open(p, errors='replace').read().splitlines():
        t = NUM.findall(line)
        if len(t) >= 3:
            try:
                raw.append([float(x) for x in t])
            except ValueError:
                pass
    if not raw:
        return []
    m = collections.Counter(len(r) for r in raw).most_common(1)[0][0]
    out, last = [], None
    for r in raw:
        if len(r) != m:
            continue
        if last is not None and r[0] <= last:
            continue
        last = r[0]
        out.append(r)
    return out


# -----------------------------------------------------------------------------
# Self test
# -----------------------------------------------------------------------------
def _selftest():
    ok = True

    def check(cond, msg):
        nonlocal ok
        print(("  PASS  " if cond else "  FAIL  ") + msg)
        if not cond:
            ok = False

    rng = np.random.default_rng(0)
    dt = 1e-4
    t = np.arange(0, 0.15, dt)
    ref = np.exp(-12 * t) * np.sin(2 * np.pi * 60 * t) * 50.0

    print("identical signals")
    r = rate(t, ref, ref.copy())
    for k in ("Z", "EP", "EM", "ES", "R"):
        check(abs(r[k] - 1.0) < 1e-12, f"{k} == 1.0 (got {r[k]:.12f})")
    check(r["shift"] == 0, f"shift == 0 (got {r['shift']})")
    check(r["label"] == "excellent", f"label excellent (got {r['label']})")

    print("time-shifted copy (test delayed by 40 samples = 4 ms)")
    sh = 40
    shifted = np.concatenate((np.zeros(sh), ref[:-sh]))
    r = rate(t, ref, shifted)
    check(r["EP"] < 1.0, f"EP < 1 (got {r['EP']:.4f})")
    check(r["Z"] < 1.0, f"Z  < 1 (got {r['Z']:.4f})")
    # positive shift == the analysed signal lags the reference
    check(r["shift"] == sh, f"shift == {sh} (got {r['shift']})")
    r2 = rate(t, ref, np.concatenate((ref[sh:], np.zeros(sh))))
    check(r2["shift"] == -sh, f"advanced copy shift == {-sh} (got {r2['shift']})")

    print("10 % scaled copy")
    r = rate(t, ref, ref * 1.10)
    check(r["EM"] < 1.0, f"EM < 1 (got {r['EM']:.4f})")
    check(r["EP"] == 1.0, f"EP == 1 (got {r['EP']:.4f})")

    print("pure noise")
    r = rate(t, ref, rng.normal(0.0, float(np.max(np.abs(ref))) / 2, len(t)))
    check(r["label"] == "poor", f"label poor (got {r['label']}, R={r['R']:.4f})")

    print("rate_table on a synthetic 3-column table")
    a = [[tt, v, 2 * v] for tt, v in zip(t, ref)]
    b = [[tt, v, 2 * v] for tt, v in zip(t, ref)]
    res = rate_table(a, b)
    check(len(res) == 2, f"2 columns rated (got {len(res)})")
    check(all(abs(x["R"] - 1.0) < 1e-12 for x in res), "both columns R == 1.0")

    print("\nSELFTEST " + ("PASSED" if ok else "FAILED"))
    return 0 if ok else 1


# -----------------------------------------------------------------------------
# CLI
# -----------------------------------------------------------------------------
def _main(argv):
    if len(argv) == 1:
        return _selftest()
    if len(argv) != 3:
        print(f"usage: {argv[0]} ref.t21 test.t21   (no args: self test)",
              file=sys.stderr)
        return 2
    ref_rows, test_rows = rows(argv[1]), rows(argv[2])
    if not ref_rows:
        print(f"no data rows parsed from {argv[1]}", file=sys.stderr)
        return 1
    if not test_rows:
        print(f"no data rows parsed from {argv[2]}", file=sys.stderr)
        return 1
    res = rate_table(ref_rows, test_rows)
    print(f"# ref  {argv[1]}")
    print(f"# test {argv[2]}")
    print(f"# {len(ref_rows)} rows, {len(res)} data columns")
    print(f"{'col':>4} {'Z':>7} {'EP':>7} {'EM':>7} {'ES':>7} {'R':>7} "
          f"{'label':<10} {'shift':>6} {'peak_ref':>11}")
    a = np.asarray(ref_rows, dtype=float)
    for j, d in enumerate(res, start=1):
        print(f"{j:>4} {d['Z']:7.4f} {d['EP']:7.4f} {d['EM']:7.4f} "
              f"{d['ES']:7.4f} {d['R']:7.4f} {d['label']:<10} "
              f"{d['shift']:>6} {np.max(np.abs(a[:, j])):11.4g}")
    return 0


if __name__ == "__main__":
    sys.exit(_main(sys.argv))
