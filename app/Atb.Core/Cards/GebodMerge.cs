using System.Globalization;
using Atb.Core.Lin;

namespace Atb.Core.Cards;

/// Add: after the last body (the first body of an empty deck). InsertBefore/InsertAfter/Replace name a 1-based body.
public enum GebodMode { Add, InsertBefore, InsertAfter, Replace }
public sealed record GebodPlacement(GebodMode Mode, int Body = 0);

/// Merges a GEBOD.ain body (B.2-B.6 cards) into a .lin deck, as ATB 3I's GEBOD form does (GEBOD.cs InsertHumanBody,
/// Body.cs placement / DeleteBody, ATBUpdate.UpdateDueToBody). The .ain is read with the solver's fixed FORMATs and
/// each line is written in the solver's AIN_CONVERT .lin layout (src/input_bcards.for, src/input_joints.for).
/// Every segment and joint goes in through Renumber.Insert (Replace's surplus goes out through Renumber.Delete), so all
/// reference shifting is Renumber's. Returns a new deck; the one passed in is never touched.
public static class GebodMerge
{
    static readonly CultureInfo Inv = CultureInfo.InvariantCulture;

    sealed record Seg(DeckLine B2a, DeckLine? B2b, DeckLine B6);
    sealed record Jnt(int ProxSeg, List<string> B3aRest, string Name, DeckLine B3b, List<DeckLine> B4, List<DeckLine> B5);

    /// Segment number where each body starts (ATB 3I ATBParam.RefSegment): 1, then J+1 for each joint J whose
    /// Seg JNT is 0. Solver: joint J joins segment |PROX_SEG| to segment J+1 and PROX_SEG 0 is a NULL joint (src/Chain.for:38-43).
    public static List<int> BodyStarts(Deck d)
    {
        if (Renumber.Count(d, Entity.Segment) == 0) return [];
        var starts = new List<int> { 1 };
        int j = 0;
        foreach (var l in d.Cards("B.3.A"))
        {
            j++;
            if (l.Count > 1 && int.TryParse(l.Tokens[1], NumberStyles.Integer, Inv, out var s) && s == 0) starts.Add(j + 1);
        }
        return starts;
    }

    /// Body k's segments a..b-1 (b = the next body's first segment, or NSEG+1) and its joints j..j+J-1: its own NULL
    /// joint a-1 then a..b-2, so J = S; body 1 has no NULL joint (1..b-2, J = S-1). The next body's NULL joint b-1 is
    /// not one of its joints (3I's DeleteBody counts it; STANDARDS.md "ATB 3I divergences").
    static (int A, int S, int J, int Jn) BodyRange(Deck d, int k)
    {
        var starts = BodyStarts(d);
        int nb = starts.Count;
        if (k < 1 || k > nb) throw new ArgumentOutOfRangeException(nameof(k), $"Body {k} is outside 1..{nb}.");
        int a = starts[k - 1], s = (k < nb ? starts[k] : Renumber.Count(d, Entity.Segment) + 1) - a;
        return (a, s, a > 1 ? a - 1 : 1, a > 1 ? s : s - 1);
    }

    /// Every field outside body k that Replace with a newSegments-segment GEBOD body drops: the ones naming a surplus
    /// position, a segment or joint of the old body past the new body's count (Renumber.Delete cascades or blanks them),
    /// plus the H.11 entries of the F.10 actuators that cascade takes with it (and H.11's STOP 741 warning when it empties).
    /// References to the kept positions name the new body's segment or joint at the same position and are not listed.
    public static List<RefSite> ReplacedReferences(Deck d, int body, int newSegments)
    {
        var (a, so, j, jo) = BodyRange(d, body);
        int jn = a > 1 ? newSegments : newSegments - 1;
        var own = Enumerable.Range(a, so).Select(s => (Entity.Segment, s)).Concat(Enumerable.Range(j, jo).Select(x => (Entity.Joint, x)))
            .SelectMany(x => Renumber.Owned(d, x.Item1, x.Item2).SelectMany(g => g)).ToHashSet();
        var surplus = Enumerable.Range(j + jn, Math.Max(jo - jn, 0)).Select(x => (Entity.Joint, x))
            .Concat(Enumerable.Range(a + newSegments, Math.Max(so - newSegments, 0)).Select(s => (Entity.Segment, s))).ToList();
        var acts = surplus.SelectMany(x => Renumber.CascadedActuators(d, x.Item1, x.Item2)).Distinct().ToList();
        var sites = surplus.SelectMany(x => Renumber.References(d, x.Item1, x.Item2))
            .Concat(acts.SelectMany(x => Renumber.References(d, Entity.Actuator, x))).ToList();
        if (Renumber.H11Emptied(d, acts) is { } warn) sites.Add(warn);
        return sites.Where(s => !own.Contains(d.Lines[s.Line - 1])).Distinct().OrderBy(s => s.Line).ToList();
    }

    /// ATB 3I Replace (GEBOD.cs:1766-1800 update list, ATBUpdate.UpdateDueToBody / UpdateOtherTable): the old body's
    /// segment or joint i becomes the new body's i-th, so references to it stay; surplus old positions go through
    /// Renumber.Delete (highest first), extra new ones through Renumber.Insert after the kept positions, and the kept
    /// positions' own lines (B.2, B.6, G.3.a; B.3-B.5) are swapped for GEBOD's. The body count does not change (no G.2).
    static Deck Replace(Deck d, int k, List<Seg> segs, List<Jnt> jnts, Func<IReadOnlyList<RefSite>, bool> confirm)
    {
        var (a, so, j, jo) = BodyRange(d, k);
        int sn = segs.Count, jn = a > 1 ? sn : sn - 1;
        var sites = ReplacedReferences(d, k, sn);
        if (sites.Count > 0 && !confirm(sites)) throw new OperationCanceledException("Replace declined; the deck is unchanged.");
        var newJ = (a > 1 ? [NullJoint()] : new List<EntityData>()).Concat(jnts.Select(x => JointData(x, a - 1))).ToList();
        for (int s = a + so - 1; s >= a + sn; s--) Renumber.Delete(d, Entity.Segment, s, _ => true);   // confirmed above, as one list
        for (int x = j + jo - 1; x >= j + jn; x--) Renumber.Delete(d, Entity.Joint, x, _ => true);
        for (int i = so; i < sn; i++) Renumber.Insert(d, Entity.Segment, a + i, SegData(segs[i]));
        for (int i = jo; i < jn; i++) Renumber.Insert(d, Entity.Joint, j + i, newJ[i]);           // Seg JNT final: no segment moves after this
        for (int i = 0; i < Math.Min(so, sn); i++) Swap(d, Entity.Segment, a + i, SegData(segs[i]));
        for (int i = 0; i < Math.Min(jo, jn); i++) Swap(d, Entity.Joint, j + i, newJ[i]);
        return d;
    }

    /// Entity n's own lines, group by group, become data's (no reference anywhere changes). Every group is one per
    /// segment / joint in the schema (B.2, B.6, G.3.A; B.3-B.5), so a missing one is a malformed deck, not skipped.
    static void Swap(Deck d, Entity e, int n, EntityData data)
    {
        var old = Renumber.Owned(d, e, n);
        for (int g = 0; g < old.Count && g < data.Groups.Count; g++)
        {
            if (old[g].Count == 0) throw new InvalidOperationException($"{e} {n} has no {data.Groups[g][0].Card} line; the deck needs one per {e.ToString().ToLowerInvariant()}.");
            int at = d.Lines.IndexOf(old[g][0]);
            d.Lines.RemoveAll(old[g].Contains);
            d.Lines.InsertRange(at, data.Groups[g]);
        }
    }

    static EntityData SegData(Seg s)
    {
        var data = new EntityData();
        data.Groups.Add(s.B2b == null ? [s.B2a] : [s.B2a, s.B2b]);
        data.Groups.Add([s.B6]);
        data.Groups.Add([Line("G.3.A", Zeros(10))]);
        data.Values.AddRange(["0", "0", "0"]);                            // D.7, F.3.A, F.7.A: ATBUpdate adds D7 rows as 0
        return data;
    }

    /// confirm is asked once, for Replace only, with ReplacedReferences when there are any; false throws
    /// OperationCanceledException and nothing changes.
    public static Deck Merge(Deck deck, string ainText, GebodPlacement p, Func<IReadOnlyList<RefSite>, bool> confirm)
    {
        var (segs, jnts) = ParseAin(ainText);
        var d = Deck.Parse(deck.Write());
        d.Path = deck.Path;
        if (d.Card("B.1") is not { Count: 4 } b1) throw new InvalidOperationException("The deck has no B.1 card.");
        if (b1.Int(3) != 0) throw new NotSupportedException("GEBOD merge into a deck with flexible bodies (B.1 NFBOD > 0, B.3.C cards) is not supported.");
        int nseg = Renumber.Count(d, Entity.Segment), njnt = Renumber.Count(d, Entity.Joint);
        if (nseg != d.SegmentCount || njnt != d.JointCount) throw new InvalidOperationException($"B.1 says {d.SegmentCount} segments / {d.JointCount} joints but the deck has {nseg} B.2.a / {njnt} B.3.a lines.");
        if (njnt != Math.Max(nseg - 1, 0)) throw new InvalidOperationException($"The deck has {nseg} segments and {njnt} joints; the solver needs one joint per segment after the first (src/Chain.for:38-43).");

        var starts = BodyStarts(d);
        int nb = starts.Count, k = p.Body;
        if (p.Mode != GebodMode.Add && (k < 1 || k > nb)) throw new ArgumentOutOfRangeException(nameof(p), $"Body {k} is outside 1..{nb}.");
        if (p.Mode == GebodMode.Replace) return Replace(d, k, segs, jnts, confirm);
        int s0 = p.Mode switch
        {
            GebodMode.Add => nseg + 1,
            GebodMode.InsertBefore => starts[k - 1],
            _ => k < nb ? starts[k] : nseg + 1,
        };
        bool others = Renumber.Count(d, Entity.Segment) > 0;
        int bodyIndex = BodyStarts(d).Count(s => s < s0) + 1;

        for (int i = 0; i < segs.Count; i++) Renumber.Insert(d, Entity.Segment, s0 + i, SegData(segs[i]));
        // GEBOD numbers its segments 1..NSEGS; the body's segments are now s0..s0+NSEGS-1 (the ain's own numbers, placed).
        int first = s0 > 1 ? s0 - 1 : 1;
        if (s0 > 1) Renumber.Insert(d, Entity.Joint, first++, NullJoint());
        for (int i = 0; i < jnts.Count; i++) Renumber.Insert(d, Entity.Joint, first + i, JointData(jnts[i], s0 - 1));
        if (s0 == 1 && others) Renumber.Insert(d, Entity.Joint, segs.Count, NullJoint());   // roots the old first body

        // ATBUpdate.UpdateDueToBody: G.1 if missing, and a blank G.2 row at the new body's number.
        if (d.Card("G.1") == null) d.Lines.Insert(Renumber.Place(d, "G.1"), Line("G.1", Zeros(2)));
        var g2 = d.Cards("G.2").ToList();
        int at = bodyIndex <= g2.Count ? d.Lines.IndexOf(g2[bodyIndex - 1]) : g2.Count > 0 ? d.Lines.IndexOf(g2[^1]) + 1 : Renumber.Place(d, "G.2");
        d.Lines.Insert(at, Line("G.2", Zeros(8)));
        // ponytail: list cards Renumber.Insert skips when absent (empty deck) are created here as zeros; F.7.A only exists with wind (NWINDF > 0).
        EnsureList(d, "D.7", d.SegmentCount);
        EnsureList(d, "F.3.A", d.SegmentCount);
        EnsureList(d, "F.4.A", d.JointCount);
        return d;
    }

    /// ATB 3I FileManager.CreateEmptyFile: IN/LB/SEC, gravity Z 386.088, A.5 defaults (A5Defination: all 0 but NPRT(36) = 1),
    /// B.1 "No Data", one dummy vehicle with Time Duration 1. No segments, so no D.7/F/G cards (WriteFile skips them).
    public static Deck NewDeck()
    {
        var d = new Deck();
        void Add(string key, params string[] t) => d.Lines.Add(Line(key, t));
        Add("A.1.A", "\"01-01-2004\""); Add("A.1.B", "\"New Simulation\""); Add("A.1.C", "\"New Simulation\"");
        // G = 386.088 (as 2479), not CreateEmptyFile's unset 0: the solver divides by G (Inrtia.for:122, Print.for:122, output_body_prop.for:57).
        Add("A.3", "\"IN.\"", "\"LB.\"", "\"SEC.\"", "0", "0", "386.088", "386.088");
        Add("A.4", "4", "0", "0.002", "0.0005", "0.001", "6.25E-05");
        Add("A.5", [.. Zeros(35), "1"]);
        Add("B.1", "0", "0", "\"No Data\"", "0");
        Add("C.1", "\"Dummy Vehicle\"");
        Add("C.2.A", "0", "0", "0", "0", "1", "0", "0", "0", "0", "0", "0", "0", "0", "0");
        Add("D.1.A", Zeros(12));
        Add("E.1", "999", "\"\"");
        foreach (var n in new[] { 1, 2, 3 }) { Add($"H.{n}.A", Zeros(7)); Add($"H.{n}.B", "0"); }
        foreach (var h in new[] { "H.4", "H.5", "H.6", "H.7", "H.8", "H.9", "H.10.A" }) Add(h, "0");
        return d;
    }

    // --- GEBOD.ain reading: FORMATs from src/input_bcards.for and src/input_joints.for ---

    static (List<Seg>, List<Jnt>) ParseAin(string text)
    {
        var lines = text.Split('\n').Select(l => l.TrimEnd('\r')).ToList();
        int at = 0;
        Rec Next(string card) => at < lines.Count ? new Rec(lines[at++], card) : throw new FormatException($"GEBOD.ain ended before {card}.");

        // B.1 (2I6, 8X, A20, I5). NFBOD is not read: GEBOD bodies are never flexible, and GEBOD's title can run past A20 into the I5 field.
        var r = Next("B.1");
        int nseg = r.I(6), njnt = r.I(6);
        if (nseg < 1 || njnt != nseg - 1) throw new FormatException($"GEBOD.ain B.1 has {nseg} segments and {njnt} joints; one body needs joints = segments - 1.");

        var b2 = new List<(DeckLine A, DeckLine? B)>();
        for (int s = 0; s < nseg; s++)
        {
            r = Next("B.2.a");                                             // (A4, 2X, 10F6.0, I4)
            var name = r.A(4); r.X(2);
            var v = r.Fs(6, 10); int lpmi = r.I(4);
            if (lpmi is not (0 or 1)) throw new FormatException($"GEBOD.ain B.2.a segment {s + 1}: LPMI = {lpmi} must be 0 or 1.");
            var a = Emit(" " + Q(name) + "  " + Fmt(v, 15, 7) + I(lpmi, 4) + "  " + "Card B.2.a");   // (1X, A, 2X, 10(F15.7,1X), I4, 2X, A)
            DeckLine? bb = null;
            if (lpmi == 1) { r = Next("B.2.b"); r.X(12); bb = Emit(" " + Fmt(r.Fs(6, 3), 15, 7) + "Card B.2.b"); }   // (12X, 3F6.0) -> (1X, 3(F15.7,1X), A)
            b2.Add((a, bb));
        }
        var jnts = new List<Jnt>();
        var euler = new List<bool>();
        for (int j = 0; j < njnt; j++)
        {
            r = Next("B.3.a");                                             // (A4, 2X, 2I4, 6F6.0, I4, 2F6.0, /, 14X, 9F6.0, 6I2)
            var name = r.A(4); r.X(2);
            int prox = r.I(4), jtype = r.I(4);
            var loc = r.Fs(6, 6); int ieuler = r.I(4); var lock2 = r.Fs(6, 2);
            r = Next("B.3.b"); r.X(14);
            var ypr = r.Fs(6, 9); var idypr = Enumerable.Range(0, 6).Select(_ => r.I(2)).ToList();
            // EULER per src/input_joints.for:110-113; it decides the B.4.b / B.5.b / B.5.c reads (input_joints.for:192, 236).
            bool e = jtype == 4 || (ieuler == 0 && jtype <= -4);
            if (e != Labeler.IsSpin(jtype, ieuler)) throw new FormatException($"GEBOD.ain joint {j + 1}: Joint Type {jtype} / IEULER {ieuler} has spin cards for the solver but not for the deck grammar.");
            euler.Add(e);
            // (1X, A, 1X, 2(I4,1X), 6(F15.7,1X), I4, 1X, 2(F15.7,1X), 1X, A) — Seg JNT is re-emitted at merge time.
            var rest = Fmt(loc, 15, 7) + I(ieuler, 4) + " " + Fmt(lock2, 15, 7) + " " + "Card B.3.a";
            var b3b = Emit(" " + Fmt(ypr, 15, 7) + string.Concat(idypr.Select(x => I(x, 2) + " ")) + " " + "Card B.3.b");   // (1X, 9(F15.7,1X), 6(I2,1X), 1X, A)
            jnts.Add(new Jnt(prox, [I(jtype, 4) + " " + rest], name, b3b, [], []));
        }
        for (int j = 0; j < njnt; j++)
        {
            r = Next("B.4.a");                                             // 2(4F6.0, F12.0) -> (1X, 10(F19.11,1X), 1X, A)
            jnts[j].B4.Add(Emit(" " + Fmt(Spring(r, 10), 19, 11) + " " + "Card B.4.a"));
            if (euler[j]) { r = Next("B.4.b"); jnts[j].B4.Add(Emit(" " + Fmt(Spring(r, 8), 19, 11) + " " + "Card B.4.b")); }   // (1X, 8(F19.11,1X), 1X, A)
        }
        for (int j = 0; j < njnt; j++)
            foreach (var c in euler[j] ? new[] { "a", "b", "c" } : ["a"])
            {
                r = Next("B.5." + c);                                      // (5F6.0, 18X, 2F6.0) -> (1X, 7(F15.7,1X), 1X, A)
                var v = r.Fs(6, 5); r.X(18); v.AddRange(r.Fs(6, 2));
                jnts[j].B5.Add(Emit(" " + Fmt(v, 15, 7) + " " + "Card B.5." + c));
            }
        var segs = new List<Seg>();
        for (int s = 0; s < nseg; s++)
        {
            r = Next("B.6");                                               // (12F6.0) -> (1X, 12(F15.7,1X), A)
            segs.Add(new Seg(b2[s].A, b2[s].B, Emit(" " + Fmt(r.Fs(6, 12), 15, 7) + "Card B.6")));
        }
        return (segs, jnts);
    }

    /// 2(4F6.0, F12.0), first n values.
    static List<double> Spring(Rec r, int n)
    {
        var v = new List<double>();
        for (int i = 0; i < n; i++) v.Add(r.F(i % 5 == 4 ? 12 : 6));
        return v;
    }

    static EntityData JointData(Jnt j, int offset)
    {
        var data = new EntityData();
        int prox = j.ProxSeg == 0 ? 0 : Math.Sign(j.ProxSeg) * (Math.Abs(j.ProxSeg) + offset);
        data.Groups.Add([Emit(" " + Q(j.Name) + " " + I(prox, 4) + " " + j.B3aRest[0]), j.B3b]);
        data.Groups.Add(j.B4);
        data.Groups.Add(j.B5);
        data.Values.Add("0");                                              // F.4.A
        return data;
    }

    /// ATB 3I's NULL joint (Name "NULL", every other column 0): Seg JNT 0 roots the next body.
    static EntityData NullJoint()
    {
        var data = new EntityData();
        data.Groups.Add([Line("B.3.A", ["\"NULL\"", .. Zeros(11)]), Line("B.3.B", Zeros(15))]);
        data.Groups.Add([Line("B.4.A", Zeros(10))]);
        data.Groups.Add([Line("B.5.A", Zeros(7))]);
        data.Values.Add("0");
        return data;
    }

    static void EnsureList(Deck d, string card, int n)
    {
        if (n == 0 || d.Card(card) != null) return;
        int at = Renumber.Place(d, card);
        foreach (var chunk in Zeros(n).Chunk(18)) d.Lines.Insert(at++, Line(card, chunk));
    }

    static DeckLine Line(string key, IEnumerable<string> tokens) => new(tokens, Labeler.LabelFor(key));
    static string[] Zeros(int n) => Enumerable.Repeat("0", n).ToArray();
    static DeckLine Emit(string text) => Deck.Parse(text).Lines[0];
    static string Q(string name) => "\"" + name.Trim() + "\"";
    static string I(int v, int w) => v.ToString(Inv).PadLeft(w);
    static string Fmt(IEnumerable<double> vs, int w, int dec) => string.Concat(vs.Select(v => (v == 0 ? 0 : v).ToString("F" + dec, Inv).PadLeft(w) + " "));

    /// One fixed-format record read left to right. Blank fields read as 0 (the solver opens the .ain with the default BLANK='NULL').
    sealed class Rec(string line, string card)
    {
        int pos;
        string Take(int w)
        {
            var s = pos < line.Length ? line.Substring(pos, Math.Min(w, line.Length - pos)) : "";
            pos += w;
            return s;
        }
        public void X(int w) => pos += w;
        public string A(int w) => Take(w);
        public int I(int w)
        {
            var s = Take(w).Replace(" ", "");
            return s.Length == 0 ? 0 : int.TryParse(s, NumberStyles.AllowLeadingSign, Inv, out var v) ? v
                : throw new FormatException($"GEBOD.ain {card}: '{s}' is not an integer (column {pos - w + 1}).");
        }
        public double F(int w)
        {
            var s = Take(w).Replace(" ", "").Replace('D', 'E').Replace('d', 'e');
            return s.Length == 0 ? 0 : double.TryParse(s, NumberStyles.Float, Inv, out var v) ? v
                : throw new FormatException($"GEBOD.ain {card}: '{s}' is not a number (column {pos - w + 1}).");
        }
        public List<double> Fs(int w, int n) => Enumerable.Range(0, n).Select(_ => F(w)).ToList();
    }
}
