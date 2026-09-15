using System.Globalization;
using Atb.Core.Lin;

namespace Atb.Core.Cards;

/// Model > Function (ATB 3I GenList over tables E1E2 / E6ab / E7ac, FDFData.cs, JntFData.cs, StdTable E6d, Plots.cs):
/// the deck's E.1-E.4 force deflection functions, E.6 wind force functions and E.7 joint stiffness functions, their
/// data tables, 3I's list operations, and the one source of every function plot's points. All card math lives here.
public static class Functions
{
    public enum Kind { Fdf, Wind, Joint }

    /// DrpDBList SpecialList 114 / 115 (ATB3iData.mdb), indexed by type; 116 is Tabular 1, Polynomial -1.
    public static readonly string[] F1Types = ["Constant", "Polynomial", "Tabular"];
    public static readonly string[] F2Types = ["None", "Polynomial", "Tabular"];

    /// 3I's sign-driven mode rule (FileManager.GetFunctionType, Labeler.FunctionType): E.2 D1/D2 -> [F1, F2] type,
    /// 0 = constant / none, 1 = polynomial (E.3), 2 = tabular (E.4).
    public static int[] Types(double d1, double d2) => Labeler.FunctionType(d1, d2);

    /// One F1 / F2 sub-function: its E.3 (polynomial) or E.4.a (tabular) line and the unlabelled X-Y pair lines.
    public sealed record Sub(int Type, DeckLine? E3, DeckLine? E4a, List<DeckLine> Data)
    {
        /// Polynomial: the 6 coefficients A0..A5; tabular: X1, Y1, X2, Y2, ...
        public List<string> Values => Type == 1 ? (E3?.Tokens.ToList() ?? []) : Type == 2 ? Data.SelectMany(l => l.Tokens).ToList() : [];
        public IEnumerable<DeckLine> Lines => new[] { E3, E4a }.OfType<DeckLine>().Concat(Data);
    }

    public sealed record Fdf(DeckLine E1, DeckLine E2, Sub[] Subs)
    {
        public int Id => Int(E1, 0);
        public string Title => E1.Count > 1 ? E1.Str(1) : "";
        public double D(int i) => Num(E2, i);
        public int F1 => Subs[0].Type;
        public int F2 => Subs[1].Type;
        public List<DeckLine> Lines => [E1, E2, .. Subs[0].Lines, .. Subs[1].Lines];
    }

    /// One wind force function: E.6.A, E.6.B, and when Specific Heats == 0 the E.6.C count and one Time Fx Fy Fz row each.
    public sealed record Wind(DeckLine A, DeckLine B, DeckLine? C, List<List<DeckLine>> Rows)
    {
        public int Id => Int(A, 0);
        public string Title => A.Count > 1 ? A.Str(1) : "";
        public List<DeckLine> Lines => [A, B, .. new[] { C }.OfType<DeckLine>(), .. Rows.SelectMany(r => r)];
    }

    /// One joint stiffness function: E.7.A, E.7.B, E.7.C (Type x NTheta, NPhi) and one |NTheta|-value row per phi.
    public sealed record Joint(DeckLine A, DeckLine B, DeckLine C, List<List<DeckLine>> Rows)
    {
        public int Id => Int(A, 0);
        public string Title => A.Count > 1 ? A.Str(1) : "";
        public int NTheta => Math.Abs(Int(C, 0));
        public int NPhi => Int(C, 1);
        /// 3I's E7ac Type: 1 tabular, -1 polynomial (the sign of E.7.C NTheta).
        public int Type => Int(C, 0) < 0 ? -1 : 1;
        public List<DeckLine> Lines => [A, B, C, .. Rows.SelectMany(r => r)];
    }

    static double Num(DeckLine l, int i) =>
        i < l.Count && double.TryParse(l.Tokens[i].Replace('D', 'E').Replace('d', 'e'), NumberStyles.Float, CultureInfo.InvariantCulture, out var v) ? v : 0;
    static int Int(DeckLine l, int i) => (int)Math.Round(Num(l, i));

    /// Unlabelled data lines from i until n values are read (a Fortran list-directed READ); stops at a labelled line.
    static List<DeckLine> TakeValues(Deck d, ref int i, int n)
    {
        var res = new List<DeckLine>();
        for (int got = 0; got < n && i < d.Lines.Count && d.Lines[i].Label.Length == 0; i++) { res.Add(d.Lines[i]); got += d.Lines[i].Count; }
        return res;
    }

    // ---- walks, as the solver reads them (Labeler.cs E section) ----

    /// E.1-E.4 functions up to the E.1 terminator (FunctionID >= 51).
    public static List<Fdf> Fdfs(Deck d)
    {
        var res = new List<Fdf>();
        var L = d.Lines;
        int i = L.FindIndex(l => l.Is("E.1"));
        while (i >= 0 && i + 1 < L.Count && L[i].Is("E.1") && Int(L[i], 0) < 51 && L[i + 1].Is("E.2"))
        {
            var e1 = L[i]; var e2 = L[i + 1]; i += 2;
            var types = Types(Num(e2, 1), Num(e2, 2));
            var subs = new Sub[2];
            for (int s = 0; s < 2; s++)
            {
                if (types[s] == 1 && i < L.Count && L[i].Is("E.3")) subs[s] = new Sub(1, L[i++], null, []);
                else if (types[s] == 2 && i < L.Count && L[i].Is("E.4.A")) { var a = L[i++]; subs[s] = new Sub(2, null, a, TakeValues(d, ref i, 2 * Int(a, 0))); }
                else subs[s] = new Sub(types[s], null, null, []);
            }
            res.Add(new Fdf(e1, e2, subs));
        }
        return res;
    }

    /// The E.1 terminator line (FunctionID >= 51), or null.
    public static DeckLine? FdfEnd(Deck d) => d.Lines.FirstOrDefault(l => l.Is("E.1") && Int(l, 0) >= 51);

    public static int NWindF(Deck d) => d.Card("D.1.A") is { } l ? Int(l, 7) : 0;

    /// NWINDF E.6 functions.
    public static List<Wind> Winds(Deck d)
    {
        var res = new List<Wind>();
        var L = d.Lines;
        int i = L.FindIndex(l => l.Is("E.6.A")), n = NWindF(d);
        while (i >= 0 && res.Count < n && i + 1 < L.Count && L[i].Is("E.6.A") && L[i + 1].Is("E.6.B"))
        {
            var a = L[i]; var b = L[i + 1]; i += 2;
            DeckLine? c = null; var rows = new List<List<DeckLine>>();
            if (Num(b, 0) == 0 && i < L.Count && L[i].Is("E.6.C"))
            {
                c = L[i++];
                for (int k = Int(c, 0); k > 0 && i < L.Count && L[i].Label.Length == 0; k--) rows.Add(TakeValues(d, ref i, 4));
            }
            res.Add(new Wind(a, b, c, rows));
        }
        return res;
    }

    /// E.7 functions up to the E.7 terminator (FunctionID >= 51).
    public static List<Joint> Joints(Deck d)
    {
        var res = new List<Joint>();
        var L = d.Lines;
        int i = L.FindIndex(l => l.Is("E.7.A"));
        while (i >= 0 && i + 2 < L.Count && L[i].Is("E.7.A") && Int(L[i], 0) < 51 && L[i + 1].Is("E.7.B") && L[i + 2].Is("E.7.C"))
        {
            var a = L[i]; var b = L[i + 1]; var c = L[i + 2]; i += 3;
            var rows = new List<List<DeckLine>>();
            int nt = Math.Abs(Int(c, 0));
            for (int k = Int(c, 1); k > 0 && nt > 0 && i < L.Count && L[i].Label.Length == 0; k--) rows.Add(TakeValues(d, ref i, nt));
            res.Add(new Joint(a, b, c, rows));
        }
        return res;
    }

    public static DeckLine? JointEnd(Deck d) => d.Lines.FirstOrDefault(l => l.Is("E.7.A") && Int(l, 0) >= 51);

    /// Does any joint use stiffness functions (a B.4.A value &lt; 0)? The solver reads E.7 only then.
    public static bool JointsUseFunctions(Deck d) => d.Cards("B.4.A").Any(l => Enumerable.Range(0, l.Count).Any(k => Num(l, k) < 0));

    // ---- the plot's points ----

    /// The one source of the FDF plot's points (FDFData.btnPlot; the solver's EVALFD / evalfd_table): the curve of a
    /// constant (data[0] = D2), polynomial (data = A0..A5) or tabular (data = X1, Y1, X2, Y2, ...) function over [lo, hi].
    /// Polynomial: 101 points, Horner as EVALFD. Tabular: the pairs strictly inside (lo, hi) plus both ends, valued by
    /// evalfd_table's rule (linear between neighbours, extrapolated below X1, Y_last beyond the last X).
    public static (double[] X, double[] Y) CurvePoints(int type, IReadOnlyList<double> data, double lo, double hi)
    {
        switch (type)
        {
            case 0:
                double v = data.Count > 0 ? data[0] : 0;
                return ([lo, hi], [v, v]);
            case 1:
            {
                var x = new double[101]; var y = new double[101];
                for (int k = 0; k <= 100; k++) { x[k] = lo + (hi - lo) * k / 100; y[k] = Poly(data, x[k]); }
                return (x, y);
            }
            default:
            {
                var x = new List<double> { lo }; var y = new List<double> { Table(data, lo) };
                for (int k = 0; k + 1 < data.Count; k += 2)
                    if (data[k] > lo && data[k] < hi) { x.Add(data[k]); y.Add(data[k + 1]); }
                x.Add(hi); y.Add(Table(data, hi));
                return (x.ToArray(), y.ToArray());
            }
        }
    }

    /// EVALFD polynomial: TAB(NP) + X*(TAB(NP+1) + X*(... + X*TAB(NP+5))).
    public static double Poly(IReadOnlyList<double> a, double x)
    {
        double f = 0;
        for (int k = Math.Min(a.Count, 6) - 1; k >= 0; k--) f = a[k] + x * f;
        return f;
    }

    /// evalfd_table.for: the first X_k (k >= 2) with d &lt;= X_k interpolates (or, below X1, extrapolates) on segment
    /// (k-1, k); past the last X the value is Y_last; a single pair is Y1.
    public static double Table(IReadOnlyList<double> xy, double d)
    {
        int n = xy.Count / 2;
        if (n == 0) return 0;
        if (n == 1) return xy[1];
        for (int k = 1; k < n; k++)
        {
            double x0 = xy[2 * k - 2], y0 = xy[2 * k - 1], x1 = xy[2 * k], y1 = xy[2 * k + 1];
            if (d <= x1) return x1 == x0 ? y1 : y0 + (y1 - y0) * (d - x0) / (x1 - x0);
        }
        return xy[2 * n - 1];
    }

    /// The Joint Stiffness plot's points for one phi row (JntFData.btnPlot, the solver's FNTERP), torque clamped &gt;= 0.
    /// Tabular (type 1): (theta0, 0), then (k*180/(NTheta-1), value k) for each grid angle past theta0.
    /// Polynomial (type -1): 61 points theta0..180 degrees, G = sum C_k (theta - theta0)^k with angles in radians (pi/180).
    public static (double[] X, double[] Y) JointCurvePoints(int type, IReadOnlyList<double> row)
    {
        if (row.Count == 0) return ([], []);
        double t0 = row[0];
        if (type < 0)
        {
            var x = new double[61]; var y = new double[61];
            for (int k = 0; k <= 60; k++)
            {
                x[k] = t0 + (180 - t0) * k / 60;
                double th = (x[k] - t0) * Math.PI / 180, g = 0;
                for (int c = row.Count - 1; c >= 1; c--) g = th * (row[c] + g);
                y[k] = Math.Max(g, 0);
            }
            return (x, y);
        }
        var xs = new List<double> { t0 }; var ys = new List<double> { 0 };
        for (int k = 1; k < row.Count; k++)
        {
            double ang = k * 180.0 / (row.Count - 1);
            if (ang > t0) { xs.Add(ang); ys.Add(Math.Max(row[k], 0)); }
        }
        return (xs.ToArray(), ys.ToArray());
    }

    /// JntFData grid captions after the read-only Phi column: "Theta 0", then "C1".. (polynomial) or the grid angles.
    public static string[] JointColumns(Joint j) =>
        ["Theta 0", .. Enumerable.Range(1, Math.Max(j.NTheta - 1, 0)).Select(k => j.Type < 0 ? "C" + k : Fmt(k * 180.0 / (j.NTheta - 1)))];

    /// Phi of row r: -180 + 360 r / NPhi.
    public static double Phi(Joint j, int r) => -180 + 360.0 * r / j.NPhi;

    static string Fmt(double v) => v.ToString("G", CultureInfo.InvariantCulture);

    // ---- data edits (every unchanged token keeps its bytes) ----

    static bool IsNum(string s) => double.TryParse(s.Trim().Replace('D', 'E').Replace('d', 'e'), NumberStyles.Float, CultureInfo.InvariantCulture, out _);

    /// Write values over a data block: same count -> cell by cell (unchanged tokens keep their bytes); otherwise the block
    /// is regenerated perLine values a line (3I WriteFile layout) at the block's place, after `after`.
    static void SetBlock(Deck d, List<DeckLine> lines, IReadOnlyList<string> values, int perLine, DeckLine after)
    {
        if (lines.Sum(l => l.Count) == values.Count)
        {
            int k = 0;
            foreach (var l in lines) for (int t = 0; t < l.Count; t++, k++) if (l.Tokens[t] != values[k].Trim()) l.Set(t, values[k].Trim());
            return;
        }
        foreach (var l in lines) d.Lines.Remove(l);
        int at = d.Lines.IndexOf(after) + 1;
        d.Lines.InsertRange(at, values.Select(v => v.Trim()).Chunk(perLine).Select(c => new DeckLine(c, "")));
    }

    static void SetTok(DeckLine l, int i, string tok) { if (i < l.Count && l.Tokens[i] != tok) l.Set(i, tok); }

    /// FDFData OK: sub 0 writes D0 and |D1| (E.2 tokens 0, 1), sub 1 |D2| (token 2), each |D| signed by the sub's type
    /// (tabular negative), then the coefficients or X-Y pairs. Null = written, else why refused (nothing written).
    public static string? SaveFdfSub(Deck d, Fdf f, int sub, string? d0, string dAbs, IReadOnlyList<string> values)
    {
        var s = f.Subs[sub];
        if (f.E2.Count < 5) return "E.2 has fewer than 5 values";
        if (!IsNum(dAbs) || (d0 != null && !IsNum(d0)) || values.Any(v => !IsNum(v))) return "Input must be a number!";
        if (s.Type == 1 && (s.E3 == null || values.Count != s.E3.Count)) return "E.3 needs 6 coefficients";
        if (s.Type == 2 && (s.E4a == null || values.Count % 2 != 0)) return "E.4 needs X-Y pairs";
        if (sub == 0 && d0 != null) SetTok(f.E2, 0, d0.Trim());
        var abs = dAbs.Trim().TrimStart('-');
        SetTok(f.E2, sub + 1, s.Type == 2 ? "-" + abs : abs);
        if (s.Type == 1) for (int k = 0; k < values.Count; k++) SetTok(s.E3!, k, values[k].Trim());
        if (s.Type == 2)
        {
            SetTok(s.E4a!, 0, (values.Count / 2).ToString(CultureInfo.InvariantCulture));
            SetBlock(d, s.Data, values, 6, s.E4a!);
        }
        return null;
    }

    /// Wind time history (StdTable E6d) OK: rows of Time Fx Fy Fz; E.6.C follows the row count.
    public static string? SaveWindRows(Deck d, Wind w, IReadOnlyList<string[]> rows)
    {
        if (w.C == null) return "This function type is velocity dependent.";
        if (rows.Any(r => r.Length != 4 || r.Any(v => !IsNum(v)))) return "Input must be a number!";
        SetTok(w.C, 0, rows.Count.ToString(CultureInfo.InvariantCulture));
        var flat = rows.SelectMany(r => r).ToList();
        var lines = w.Rows.SelectMany(r => r).ToList();
        if (lines.Sum(l => l.Count) == flat.Count && w.Rows.All(r => r.Sum(l => l.Count) == 4)) SetBlock(d, lines, flat, 4, w.C);
        else { foreach (var l in lines) d.Lines.Remove(l); d.Lines.InsertRange(d.Lines.IndexOf(w.C) + 1, rows.Select(r => new DeckLine(r.Select(v => v.Trim()), ""))); }
        return null;
    }

    /// JntFData OK: one |NTheta|-value row per phi (dimensions are the list's NTheta / NPhi).
    public static string? SaveJointRows(Deck d, Joint j, IReadOnlyList<string[]> rows)
    {
        if (rows.Count != j.NPhi || rows.Any(r => r.Length != j.NTheta)) return "Rows must be NPhi rows of NTheta values";
        if (rows.Any(r => r.Any(v => !IsNum(v)))) return "Input must be a number!";
        if (j.Rows.Count == rows.Count && j.Rows.Select((r, k) => r.Sum(l => l.Count) == rows[k].Length).All(b => b))
            for (int k = 0; k < rows.Count; k++) SetBlock(d, j.Rows[k], rows[k], 6, j.C);
        else { RegenJointRows(d, j, rows); }
        return null;
    }

    static void RegenJointRows(Deck d, Joint j, IReadOnlyList<string[]> rows)
    {
        foreach (var l in j.Rows.SelectMany(r => r)) d.Lines.Remove(l);
        d.Lines.InsertRange(d.Lines.IndexOf(j.C) + 1, rows.SelectMany(r => r.Select(v => v.Trim()).Chunk(6)).Select(c => new DeckLine(c, "")));
    }

    // ---- list cell rules (ATBGrid.cs:2183-2777) ----

    /// ATBParam.UsedFunctionID, copied: 3I checks the E1E2 table (E.1 IDs) whichever list is edited.
    public static bool IdUsed(Deck d, int id, DeckLine self) => Fdfs(d).Any(f => f.E1 != self && f.Id == id);

    public static string? SetId(Deck d, DeckLine head, string text)
    {
        if (!int.TryParse(text.Trim(), NumberStyles.Integer, CultureInfo.InvariantCulture, out var id)) return "Input string was not in correct format!";
        if (IdUsed(d, id, head)) return "This ID has been used by other functions!";
        SetTok(head, 0, id.ToString(CultureInfo.InvariantCulture));
        return null;
    }

    static string F(double v) => DeckLine.FormatNum(v);

    static void RemoveSub(Deck d, Sub s) { foreach (var l in s.Lines) d.Lines.Remove(l); }

    static DeckLine Zeros(int n, string card) => new(Enumerable.Repeat("0", n), Labeler.LabelFor(card));

    /// F1 Type change (ATBGrid.cs "F1 Type"): 0 clears the function (F2 none, D1 = D2 = 0); 1 / 2 set D1 to +/-|D1|
    /// (or +/-1) with blank E.3 zeros / an empty E.4 table. Leaving Constant also zeroes D2 (STANDARDS.md divergence).
    /// Returns false when refused (tabular while F2 is tabular).
    public static bool SetF1Type(Deck d, Fdf f, int type)
    {
        if (type == f.F1) return true;
        if (type == 2 && f.F2 == 2) return false;
        double d1 = Math.Abs(f.D(1));
        RemoveSub(d, f.Subs[0]);
        if (type == 0)
        {
            RemoveSub(d, f.Subs[1]);
            SetTok(f.E2, 1, "0"); SetTok(f.E2, 2, "0");
            return true;
        }
        if (f.F1 == 0) SetTok(f.E2, 2, "0");
        SetTok(f.E2, 1, F(type == 1 ? (d1 == 0 ? 1 : d1) : -(d1 == 0 ? 1 : d1)));
        d.Lines.Insert(d.Lines.IndexOf(f.E2) + 1, type == 1 ? Zeros(6, "E.3") : Zeros(1, "E.4.A"));
        return true;
    }

    /// F2 Type change: 0 clears F2 (D2 = 0); 1 / 2 set D2 to +/-|D2| (or +/-(|D1|+1)). Refused (false) while F1 is
    /// constant (STANDARDS.md divergence) or, for tabular, while F1 is tabular.
    public static bool SetF2Type(Deck d, Fdf f, int type)
    {
        if (type == f.F2) return true;
        if (f.F1 == 0 || (type == 2 && f.F1 == 2)) return false;
        double d2 = Math.Abs(f.D(2)), n = d2 == 0 ? Math.Abs(f.D(1)) + 1 : d2;
        RemoveSub(d, f.Subs[1]);
        SetTok(f.E2, 2, type == 0 ? "0" : F(type == 1 ? n : -n));
        if (type != 0)
        {
            var last = f.Subs[0].Lines.LastOrDefault() ?? f.E2;
            d.Lines.Insert(d.Lines.IndexOf(last) + 1, type == 1 ? Zeros(6, "E.3") : Zeros(1, "E.4.A"));
        }
        return true;
    }

    /// NTheta / NPhi / Type change on the joint list: reset the data to zeros (3I clears E7d and writes zero rows).
    public static string? SetJointShape(Deck d, Joint j, int nTheta, int nPhi, int type)
    {
        if (nTheta < 2) return "NTheta can't be less than 2!";
        if (nPhi < 1) return "NPhi can't be less than 1!";
        SetTok(j.C, 0, (type * nTheta).ToString(CultureInfo.InvariantCulture));
        SetTok(j.C, 1, nPhi.ToString(CultureInfo.InvariantCulture));
        RegenJointRows(d, j, Enumerable.Range(0, nPhi).Select(_ => Enumerable.Repeat("0", nTheta).ToArray()).ToList());
        return null;
    }

    /// Specific Heats change: from zero to nonzero drops E.6.C and its rows; back to zero adds an empty E.6.C.
    public static void SetSpecificHeats(Deck d, Wind w, string text)
    {
        SetTok(w.B, 0, text.Trim());
        bool timeDep = Num(w.B, 0) == 0;
        if (!timeDep && w.C != null) { d.Lines.Remove(w.C); foreach (var l in w.Rows.SelectMany(r => r)) d.Lines.Remove(l); }
        if (timeDep && w.C == null) d.Lines.Insert(d.Lines.IndexOf(w.B) + 1, Zeros(1, "E.6.C"));
    }

    // ---- list operations (GenList Insert / Delete / Copy / Paste) ----

    public static List<DeckLine> Heads(Deck d, Kind k) => k switch
    {
        Kind.Fdf => Fdfs(d).Select(f => f.E1).ToList(),
        Kind.Wind => Winds(d).Select(w => w.A).ToList(),
        _ => Joints(d).Select(j => j.A).ToList(),
    };

    static List<DeckLine> LinesOf(Deck d, Kind k, DeckLine head) => k switch
    {
        Kind.Fdf => Fdfs(d).First(f => f.E1 == head).Lines,
        Kind.Wind => Winds(d).First(w => w.A == head).Lines,
        _ => Joints(d).First(j => j.A == head).Lines,
    };

    /// GridFindMin - 1: min(0, the list's IDs) - 1.
    public static int NewId(Deck d, Kind k) => Math.Min(0, Heads(d, k).Select(h => Int(h, 0)).DefaultIfEmpty(0).Min()) - 1;

    static string Card(Kind k, char c) => k switch { Kind.Fdf => c == 'A' ? "E.1" : "E.2", Kind.Wind => "E.6." + c, _ => "E.7." + c };

    /// A blank function: FDF constant zero, wind time dependent with no rows, joint tabular 2 x 1 zeros.
    static List<DeckLine> Blank(Kind k, int id, string title = "")
    {
        var head = new DeckLine([id.ToString(CultureInfo.InvariantCulture), "\"" + title + "\""], Labeler.LabelFor(Card(k, 'A')));
        return k switch
        {
            Kind.Fdf => [head, Zeros(5, "E.2")],
            Kind.Wind => [head, Zeros(5, "E.6.B"), Zeros(1, "E.6.C")],
            _ => [head, Zeros(5, "E.7.B"), new DeckLine(["2", "1"], Labeler.LabelFor("E.7.C")), new DeckLine(["0", "0"], "")],
        };
    }

    /// Insert a blank function before the selected one (GenList.btnInsert -> GridInsertRow).
    public static void Insert(Deck d, Kind k, DeckLine before)
    {
        d.Lines.InsertRange(d.Lines.IndexOf(before), Blank(k, NewId(d, k)));
        if (k == Kind.Wind) SetNWindF(d, NWindF(d) + 1);
    }

    /// Delete the selected functions with their data (E3/E4b, E6d, E7d).
    public static void Delete(Deck d, Kind k, IEnumerable<DeckLine> heads)
    {
        int n = 0;
        foreach (var h in heads.ToList()) { foreach (var l in LinesOf(d, k, h)) d.Lines.Remove(l); n++; }
        if (k == Kind.Wind) SetNWindF(d, NWindF(d) - n);
    }

    /// NWINDF upkeep: D.1.A token 7, and the F.7.A wind contact line the solver reads only when NWINDF > 0
    /// (3I WriteFile writes F.7 when NWINDF > 0): added as one zero per segment, removed with its F.7.B/C lines.
    static void SetNWindF(Deck d, int n)
    {
        if (d.Card("D.1.A") is not { } d1) return;
        SetTok(d1, 7, n.ToString(CultureInfo.InvariantCulture));
        bool has = d.Lines.Any(l => l.Is("F.7.A"));
        if (n > 0 && !has)
        {
            int at = d.Lines.FindIndex(l => l.Card is "F.8.A" or "F.9.A" or "F.10.A" or "G.1" || l.Card.StartsWith("F.9") || l.Card.StartsWith("F.10"));
            if (at < 0) return;
            int seg = Math.Max(d.SegmentCount, 1);
            // ponytail: F.7.A is written 18 values a line like 3I; this deck-level default never needs more than one line under 18 segments.
            d.Lines.InsertRange(at, Enumerable.Repeat("0", seg).Chunk(18).Select(c => new DeckLine(c, Labeler.LabelFor("F.7.A"))));
        }
        if (n <= 0 && has) d.Lines.RemoveAll(l => l.Is("F.7.A") || l.Is("F.7.B") || l.Is("F.7.C"));
    }

    /// GenList.btnCopy: the selected rows' bound columns but the last (RID), tab separated, "\r\n" a row; FileID is 0.
    public static string CopyText(Deck d, Kind k, IEnumerable<DeckLine> heads)
    {
        var rows = new List<string>();
        foreach (var h in heads)
        {
            string[] cols = k switch
            {
                Kind.Fdf => Fdfs(d).First(f => f.E1 == h) is var f ? [.. Head(f.E1), .. Enumerable.Range(0, 5).Select(i => Tok(f.E2, i)), f.F1.ToString(CultureInfo.InvariantCulture), f.F2.ToString(CultureInfo.InvariantCulture)] : [],
                Kind.Wind => Winds(d).First(w => w.A == h) is var w ? [.. Head(w.A), .. Enumerable.Range(0, 5).Select(i => Tok(w.B, i))] : [],
                _ => Joints(d).First(j => j.A == h) is var j ? [.. Head(j.A), j.NTheta.ToString(CultureInfo.InvariantCulture), j.NPhi.ToString(CultureInfo.InvariantCulture), j.Type.ToString(CultureInfo.InvariantCulture)] : [],
            };
            rows.Add(string.Join("\t", cols));
        }
        return string.Concat(rows.Select(r => r + "\r\n"));
    }

    static string[] Head(DeckLine a) => ["0", Tok(a, 0), a.Count > 1 ? a.Str(1) : ""];
    static string Tok(DeckLine l, int i) => i < l.Count ? l.Tokens[i] : "0";

    /// GenList.btnPaste: each clipboard row becomes a new function (IDs min-1, min-2, ...) before or after `at`
    /// (null: at the end of the list). Sub-data is copied from the source function with the row's FunctionID in this deck;
    /// a row whose source is gone gets blank data. Returns the number pasted, or -1 when the clipboard holds no rows.
    public static int Paste(Deck d, Kind k, string text, DeckLine? at, bool before)
    {
        int width = k switch { Kind.Fdf => 10, Kind.Wind => 8, _ => 6 };
        var rows = text.Replace("\r", "").Split('\n').Select(r => r.Split('\t')).Where(r => r.Length >= width).ToList();
        if (rows.Count == 0) return -1;
        int pos;
        if (at != null) { var ls = LinesOf(d, k, at); pos = d.Lines.IndexOf(before ? ls[0] : ls[^1]) + (before ? 0 : 1); }
        else
        {
            var heads = Heads(d, k);
            var end = heads.Count > 0 ? LinesOf(d, k, heads[^1])[^1] : null;
            pos = end != null ? d.Lines.IndexOf(end) + 1
                : k == Kind.Fdf ? (FdfEnd(d) is { } e ? d.Lines.IndexOf(e) : -1)
                : k == Kind.Joint ? (JointEnd(d) is { } je ? d.Lines.IndexOf(je) : -1)
                : WindAnchor(d);
            // ponytail: pasting into a deck with no E.7 section adds nothing (3I's writer drops E.7 unless a joint uses
            // functions, FileManager.cs:1646) — build the section when a client pastes into an empty Joint list.
            if (pos < 0) return 0;
        }
        int id = NewId(d, k), done = 0;
        foreach (var r in rows)
        {
            if (!int.TryParse(r[1].Trim(), out var src) || r.Skip(3).Take(width - 3).Any(v => !IsNum(v))) continue;
            var lines = PasteRow(d, k, r, src, id - done);
            d.Lines.InsertRange(pos, lines);
            pos += lines.Count; done++;
        }
        if (k == Kind.Wind && done > 0) SetNWindF(d, NWindF(d) + done);
        return done;
    }

    /// Where a wind function goes into a deck with none: after the E.1 terminator.
    static int WindAnchor(Deck d) => FdfEnd(d) is { } e ? d.Lines.IndexOf(e) + 1 : -1;

    static List<DeckLine> PasteRow(Deck d, Kind k, string[] r, int src, int id)
    {
        var lines = Blank(k, id, r[2].Replace('"', '\''));
        var vals = r.Skip(3).Select(v => v.Trim()).ToArray();
        static DeckLine Clone(DeckLine l) => new(l.Tokens, l.Label);
        switch (k)
        {
            case Kind.Fdf:
                lines[1] = new DeckLine(vals.Take(5), Labeler.LabelFor("E.2"));
                var srcF = Fdfs(d).FirstOrDefault(f => f.Id == src);
                var types = Types(DeckLine.ParseNum(vals[1]), DeckLine.ParseNum(vals[2]));
                for (int s = 0; s < 2; s++)
                    if (srcF != null && srcF.Subs[s].Type == types[s] && srcF.Subs[s].Lines.Any()) lines.AddRange(srcF.Subs[s].Lines.Select(Clone));
                    else if (types[s] == 1) lines.Add(Zeros(6, "E.3"));
                    else if (types[s] == 2) lines.Add(Zeros(1, "E.4.A"));
                break;
            case Kind.Wind:
                lines[1] = new DeckLine(vals.Take(5), Labeler.LabelFor("E.6.B"));
                lines.RemoveAt(2);
                if (DeckLine.ParseNum(vals[0]) == 0)
                {
                    var srcW = Winds(d).FirstOrDefault(w => w.Id == src);
                    if (srcW?.C != null) lines.AddRange(new[] { srcW.C }.Concat(srcW.Rows.SelectMany(x => x)).Select(Clone));
                    else lines.Add(Zeros(1, "E.6.C"));
                }
                break;
            default:
                var srcJ = Joints(d).FirstOrDefault(j => j.Id == src);
                if (srcJ != null) { lines.RemoveRange(1, 3); lines.AddRange(srcJ.Lines.Skip(1).Select(Clone)); }
                break;
        }
        return lines;
    }
}
