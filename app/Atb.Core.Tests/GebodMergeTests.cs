using Atb.Core.Cards;
using Atb.Core.Lin;
using Xunit;

namespace Atb.Core.Tests;

public class GebodMergeTests
{
    static Deck D2479() => Deck.Load(Fixtures.ClientDecks().Single(p => Path.GetFileName(p) == "2479_2.LIN"));
    static string Ain => File.ReadAllText(Path.Combine(Fixtures.RepoRoot, "app/Atb.Core.Tests/fixtures/gebod-50m.ain"));
    static string Toks(DeckLine l) => string.Join(" ", l.Tokens);
    static DeckLine Row(Deck d, string card, int n) => d.Cards(card).ElementAt(n - 1);
    const int G = 15;   // GEBOD segments in the fixture; 14 joints + 1 NULL joint when the deck already has a body

    /// B.1 counts equal the B.2.a / B.3.a rows, and the solver's chain holds (src/Chain.for:38-43): joint J joins
    /// segment |Seg JNT| to J+1, 0 = NULL joint starting a body, so joints = segments - 1 and every proximal
    /// segment lies earlier in the same body. One G.2 row per body. The deck also walks the full input grammar.
    static List<int> AssertSolverShape(Deck d)
    {
        var b1 = d.Card("B.1")!;
        int nseg = b1.Int(0), njnt = b1.Int(1);
        Assert.Equal(nseg, d.Cards("B.2.A").Count());
        Assert.Equal(njnt, d.Cards("B.3.A").Count());
        Assert.Equal(nseg - 1, njnt);
        var prox = d.Cards("B.3.A").Select(l => Math.Abs(l.Int(1))).ToList();
        var starts = new List<int> { 1 };
        for (int j = 1; j <= njnt; j++) if (prox[j - 1] == 0) starts.Add(j + 1);
        for (int j = 1; j <= njnt; j++)
            if (prox[j - 1] != 0) Assert.InRange(prox[j - 1], starts.Last(s => s <= j + 1), j);
        Assert.Equal(starts.Count, d.Cards("G.2").Count());
        Assert.Equal(nseg, d.Cards("D.7").Sum(l => l.Count));
        Assert.Equal(nseg, d.Cards("F.3.A").Sum(l => l.Count));
        Assert.Equal(njnt, d.Cards("F.4.A").Sum(l => l.Count));
        Assert.Equal(nseg, d.Cards("G.3.A").Count());
        Assert.Empty(d.Validate());
        Labeler.Label(d);                                                  // throws if the grammar cannot walk it
        Assert.Equal(starts, GebodMerge.BodyStarts(d));
        return starts;
    }

    // Fortran AIN_CONVERT layout, worked out by hand from the FORMATs and the fixture's columns.
    const string LtB2a = " \"LT\"       24.8700000       0.9202000       0.8451000       1.0672000       4.7180000       6.9420000       4.3220000      -0.4720000       0.0000000       0.8850000    1  Card B.2.a";
    const string LtB2b = "       0.0000000       0.0000000       0.0000000 Card B.2.b";
    const string PB3b = "       0.0000000       0.0000000       0.0000000       0.0000000       5.0000000       0.0000000       0.0000000       0.0000000       0.0000000  0  0  0  0  0  0  Card B.3.b";
    const string PB4a = "       0.00000000000      10.00000000000       0.00000000000       0.70000000000      20.00000000000       0.00000000000      10.00000000000       0.00000000000       0.70000000000       5.00000000000  Card B.4.a";
    const string PB5a = "       0.1000000       0.0000000      30.0000000       0.0000000       0.0000000       0.0000000       0.0000000  Card B.5.a";
    const string LtB6 = "       0.0100000       0.0100000       0.0100000       0.0100000       0.0100000       0.0100000       0.1000000       0.1000000       0.1000000       0.1000000       0.1000000       0.0100000 Card B.6";
    static string PB3a(int seg) => $" \"P\" {seg,4}    0      -1.4500000       0.0000000      -2.2400000      -2.3900000       0.0000000       2.2500000    0       0.0000000       0.0000000  Card B.3.a";

    [Fact]
    public void Add_To2479_AppendsBodyWithLiteralLines()
    {
        var src = D2479();
        var before = src.Write();
        var d = GebodMerge.Merge(src, Ain, new(GebodMode.Add), _ => true);
        Assert.Equal(before, src.Write());                                 // the open deck is untouched

        Assert.Equal("32 31 \"\" 0", Toks(d.Card("B.1")!));                // 17+15 segments; 16 + NULL + 14 joints
        Assert.Equal([1, 3, 18], AssertSolverShape(d));
        Assert.Equal(LtB2a, Row(d, "B.2.A", 18).Raw);
        Assert.Equal(LtB2b, d.Lines[d.Lines.IndexOf(Row(d, "B.2.A", 18)) + 1].Raw);
        Assert.Equal("\"NULL\" 0 0 0 0 0 0 0 0 0 0 0", Toks(Row(d, "B.3.A", 17)));
        Assert.Equal(PB3a(18), Row(d, "B.3.A", 18).Raw);                  // GEBOD Seg JNT 1 -> segment 18 (LT)
        Assert.Equal(PB3b, Row(d, "B.3.B", 18).Raw);
        Assert.Equal(PB4a, Row(d, "B.4.A", 18).Raw);
        Assert.Equal(PB5a, Row(d, "B.5.A", 18).Raw);
        Assert.Equal(LtB6, Row(d, "B.6", 18).Raw);
        Assert.Equal("0 0 0 0 0 0 0 0 0 0", Toks(Row(d, "G.3.A", 18)));
        Assert.Equal("0 0 0 0 0 0 0 0", Toks(Row(d, "G.2", 3)));
        // GEBOD's own Seg JNT (RH -> 1, RK -> 6, LE -> 14) land on the new body's segments.
        Assert.Equal(["RH", "18"], Row(d, "B.3.A", 22).Tokens.Take(2).Select((t, i) => i == 0 ? t.Trim('"') : t));
        Assert.Equal("23", Row(d, "B.3.A", 23).Tokens[1]);
        Assert.Equal("31", Row(d, "B.3.A", 31).Tokens[1]);
        // Nothing before the new body moved: the first 17 segments' and 16 joints' lines keep their original text.
        var o = D2479();
        for (int i = 1; i <= 17; i++) Assert.Equal(Row(o, "B.2.A", i).Raw, Row(d, "B.2.A", i).Raw);
        for (int i = 1; i <= 16; i++) Assert.Equal(Row(o, "B.3.A", i).Raw, Row(d, "B.3.A", i).Raw);
    }

    /// The solver's reading of a ref token: ABS only for H.1-H.8 Segment / Segment-or-Joint and H.7 Joint.
    static readonly HashSet<string> Signed = new(StringComparer.OrdinalIgnoreCase) { "H.1.A", "H.1.B", "H.2.A", "H.2.B", "H.3.A", "H.3.B", "H.4", "H.5", "H.6", "H.7", "H.8" };

    /// Every old line of cards in skip (new rows first) is paired in order with its merged line; ref tokens >= 1
    /// must have moved by segShift / jntShift, every other token unchanged.
    static void AssertShifted(Deck o, Deck d, int segShift, int jntShift, Dictionary<string, int> skip, Func<string, int, int>? oldToNew = null)
    {
        Labeler.Label(o); Labeler.Label(d);                                // same labels on both (2479's H.3.a reads "CARD H.1.a")
        var lists = new[] { "D.7", "F.3.A", "F.4.A", "F.7.A", "B.1" };
        foreach (var card in o.Lines.Where(l => l.Card.Length > 0 && !lists.Contains(l.Card)).Select(l => l.Card).Distinct())
        {
            var olds = o.Cards(card).ToList();
            var news = d.Cards(card).Skip(skip.GetValueOrDefault(card)).ToList();
            if (oldToNew == null) Assert.True(olds.Count == news.Count, $"{card}: {olds.Count} rows before, {news.Count} after");
            for (int r = 0; r < olds.Count; r++)
            {
                int nr = oldToNew?.Invoke(card, r) ?? r;
                if (nr < 0) continue;
                var (a, b) = (olds[r], d.Cards(card).ElementAt(nr + (oldToNew == null ? skip.GetValueOrDefault(card) : 0)));
                Assert.Equal(a.Count, b.Count);
                int sk = CardSchema.Skip(card, a.Count);
                for (int i = 0; i < a.Count; i++)
                {
                    var kind = CardSchema.KindOf(card, i + sk);
                    int shift = kind is Kind.SegRef or Kind.EllipRef ? segShift : kind == Kind.JointRef ? jntShift : 0;
                    if (shift == 0 || !int.TryParse(a.Tokens[i], out var v)) { Assert.True(a.Tokens[i] == b.Tokens[i], $"{card} row {r + 1} token {i + 1}: {a.Tokens[i]} -> {b.Tokens[i]}"); continue; }
                    bool abs = Signed.Contains(card) && !CardSchema.Header(card, i + sk).StartsWith("Ref ");
                    int refv = abs ? Math.Abs(v) : v;
                    var want = refv >= 1 ? (Math.Sign(v) * (Math.Abs(v) + shift)).ToString() : a.Tokens[i];
                    Assert.True(want == b.Tokens[i], $"{card} row {r + 1} token {i + 1} ({CardSchema.Header(card, i + sk)}): {a.Tokens[i]} -> {b.Tokens[i]}, want {want}");
                }
            }
        }
    }

    static readonly string[] SegCards = ["B.2.A", "B.2.B", "B.6", "G.3.A"], JntCards = ["B.3.A", "B.3.B", "B.4.A", "B.5.A"];

    [Fact]
    public void InsertBeforeBody1_ShiftsEveryExistingSegmentAndJointRef()
    {
        var o = D2479();
        var d = GebodMerge.Merge(o, Ain, new(GebodMode.InsertBefore, 1), _ => true);
        Assert.Equal("32 31 \"\" 0", Toks(d.Card("B.1")!));
        Assert.Equal([1, 16, 18], AssertSolverShape(d));
        Assert.Equal(LtB2a, Row(d, "B.2.A", 1).Raw);
        Assert.Equal(PB3a(1), Row(d, "B.3.A", 1).Raw);                    // offset 0: GEBOD's numbers as they are
        Assert.Equal("\"NULL\" 0 0 0 0 0 0 0 0 0 0 0", Toks(Row(d, "B.3.A", 15)));   // roots the old body 1 (segment 16)
        Assert.Equal("0 0 0 0 0 0 0 0", Toks(Row(d, "G.2", 1)));
        var skip = SegCards.ToDictionary(c => c, _ => G).Concat(JntCards.ToDictionary(c => c, _ => G)).ToDictionary();
        skip["G.2"] = 1;
        AssertShifted(o, d, segShift: G, jntShift: G, skip);
        // spot checks written out: old H.6 "2 19 1 1 2" (vehicle 19, segments 1, 2) and old G.3.a 3 Ref Segment 1
        Assert.Equal("2 34 16 16 17", Toks(d.Card("H.6")!));
        Assert.Equal("16", Row(d, "G.3.A", 18).Tokens[9]);
        // Written out, not from CardSchema marks: 2479 F.1.b line 209 "1 19 1 50 ..." (plane 1, vehicle segment 19, contact
        // segment 1, ellipsoid 50) and H.2.a line 319 "2 19 3 ..." (vehicle 19, segment 3). Every segment and ellipsoid +15.
        Assert.Equal("1 34 16 65 1 0 1 3 1 -1 0", Toks(d.Cards("F.1.B").First()));
        Assert.Equal("2 34 18 0 0 0 0", Toks(d.Card("H.2.A")!));
    }

    /// The fixture cut to its first n segments and n-1 joints, built from the .ain schema (every fixture segment has
    /// LPMI 1, so a B.2.b line; no joint has spin cards): no client deck has a body longer than GEBOD's 15 segments.
    internal static string SmallAin(int n)
    {
        var l = Ain.Split('\n').Select(x => x.TrimEnd('\r')).ToList();
        var cut = new List<string> { $"{n,6}{n - 1,6}" + l[0][12..] };
        cut.AddRange(l.GetRange(1, 2 * n));                                // B.2.a + B.2.b
        cut.AddRange(l.GetRange(31, 2 * (n - 1)));                         // B.3.a + B.3.b
        cut.AddRange(l.GetRange(59, n - 1));                               // B.4.a
        cut.AddRange(l.GetRange(73, n - 1));                               // B.5.a
        cut.AddRange(l.GetRange(87, n));                                   // B.6
        return string.Join("\n", cut) + "\n";
    }

    /// ATB 3I Replace (GEBOD.cs:1766-1800): body 1 (RN, DR) gets 15 GEBOD segments. References to old segments 1, 2 still
    /// name segments 1, 2 (now GEBOD's LT, CT); segments 3.. and the vehicle move up by 15 - 2 through Renumber.Insert.
    [Fact]
    public void ReplaceBody1_KeepsRefsByPosition_AndShiftsLaterOnesByTheDifference()
    {
        var o = D2479();
        bool asked = false;
        var d = GebodMerge.Merge(o, Ain, new(GebodMode.Replace, 1), _ => asked = true);
        // Written out: 2479 F.1.b line 209 "1 19 1 50 1 0 1 3 1 -1 0" (plane 1, vehicle 19, contact segment 1 of the
        // replaced body, ellipsoid 50): segment 1 stays 1, vehicle 19 -> 32, ellipsoid 50 -> 63.
        Assert.Equal("1 32 1 63 1 0 1 3 1 -1 0", Toks(d.Cards("F.1.B").First()));
        Assert.Equal("2 32 1 1 2", Toks(d.Card("H.6")!));                  // H.6 "2 19 1 1 2": segments 1, 2 kept
        Assert.Contains("2 32 16 16 10 0 11 3 12 -2 0", d.Cards("F.1.B").Select(Toks));   // line 217 "2 19 3 3 ...": 3 -> 16
        Assert.Equal("2 32 16 0 0 0 0", Toks(d.Card("H.2.A")!));           // H.2.a "2 19 3 ...": 3 -> 16
        Assert.Equal("1 71 16 16 10 0 11 3 13 0", Toks(d.Cards("F.3.B").First()));   // F.3.b "1 58 3 3 ...": ellipsoid 58 -> 71
        Assert.False(asked);                                               // nothing is dropped, so nothing to confirm
        Assert.Equal(o.Cards("F.1.B").Count(), d.Cards("F.1.B").Count());

        Assert.Equal("30 29 \"\" 0", Toks(d.Card("B.1")!));                // 17-2+15 segments; 16-1+14 joints
        Assert.Equal([1, 16], AssertSolverShape(d));
        Assert.DoesNotContain(d.Cards("B.2.A"), l => l.Str(0) is "RN" or "DR");
        Assert.Equal(LtB2a, Row(d, "B.2.A", 1).Raw);
        Assert.Equal(PB3a(1), Row(d, "B.3.A", 1).Raw);
        Assert.Equal(Row(o, "B.3.A", 2).Raw, Row(d, "B.3.A", 15).Raw);    // body 2's NULL joint 2 -> 15, its own text
        Assert.Equal(2, d.Cards("G.2").Count());                           // same number of bodies: G.2 untouched (UpdateDueToBody bdyChange 0)
        for (int j = 3; j <= 16; j++)                                      // old joints 3..16 (body 2) are now 16..29, Seg JNT + 13
        {
            var (a, b) = (Row(o, "B.3.A", j), Row(d, "B.3.A", j + 13));
            Assert.Equal(a.Str(0), b.Str(0));
            Assert.Equal(a.Int(1) + 13, b.Int(1));
        }
    }

    /// A 3-segment GEBOD body replaces body 2 (segments 3..17, joints 2..16): positions 1-3 are kept (segments 3-5,
    /// joints 2-4), surplus segments 6..17 and joints 5..16 go through Renumber.Delete, the vehicle moves down by 12.
    [Fact]
    public void ReplaceWithShorterBody_DropsSurplusRefs_AndShiftsLaterOnesDown()
    {
        var o = D2479();
        var before = o.Write();
        IReadOnlyList<RefSite>? seen = null;
        Assert.Throws<OperationCanceledException>(() => GebodMerge.Merge(o, SmallAin(3), new(GebodMode.Replace, 2), s => { seen = s; return false; }));
        Assert.Equal(before, o.Write());
        IReadOnlyList<RefSite>? accepted = null;
        var d = GebodMerge.Merge(o, SmallAin(3), new(GebodMode.Replace, 2), s => { accepted = s; return true; });
        // Shift: vehicle 19 -> 7, ellipsoid 50 -> 38 (F.1.b line 209 "1 19 1 50 ..."), H.2.a "2 19 3" -> "2 7 3".
        Assert.Equal("1 7 1 38 1 0 1 3 1 -1 0", Toks(d.Cards("F.1.B").First()));
        Assert.Equal("2 7 3 0 0 0 0", Toks(d.Card("H.2.A")!));
        // Kept by position: F.1.b "2 19 3 3 ..." / "3 19 5 5 ..." still name segments 3 and 5 (GEBOD's LT and its 3rd segment).
        Assert.Contains("2 7 3 3 10 0 11 3 12 -2 0", d.Cards("F.1.B").Select(Toks));
        Assert.Contains("3 7 5 5 10 0 11 3 12 -2 0", d.Cards("F.1.B").Select(Toks));
        // Dropped: every F.1.b row on segments 6..17 is gone (Renumber.Delete cascade), as ReplacedReferences listed.
        Assert.Equal(o.Cards("F.1.B").Count(l => l.Int(2) is >= 6 and <= 17), o.Cards("F.1.B").Count() - d.Cards("F.1.B").Count());
        Assert.Equal(GebodMerge.ReplacedReferences(o, 2, 3), seen);
        Assert.Equal(seen, accepted);
        Assert.Contains(seen!, s => s.Label.EndsWith("F.1.b", StringComparison.OrdinalIgnoreCase) && s.Field == "Contact Segment");
        Assert.DoesNotContain(seen!, s => s.Label.Contains("B.", StringComparison.OrdinalIgnoreCase));   // the body's own lines are not "references"

        Assert.Equal("5 4 \"\" 0", Toks(d.Card("B.1")!));                  // 17-12 segments, 16-12 joints
        Assert.Equal([1, 3], AssertSolverShape(d));
        Assert.Equal(LtB2a, Row(d, "B.2.A", 3).Raw);
        Assert.Equal("\"NULL\" 0 0 0 0 0 0 0 0 0 0 0", Toks(Row(d, "B.3.A", 2)));
        Assert.Equal(PB3a(3), Row(d, "B.3.A", 3).Raw);                    // GEBOD Seg JNT 1 -> segment 3
        Assert.Equal(Row(o, "B.3.A", 1).Raw, Row(d, "B.3.A", 1).Raw);     // body 1 untouched
    }

    /// Body 1 (2 segments, joint 1) replaced by a 1-segment body: segment 2 and joint 1 are surplus; body 2's NULL joint
    /// moves from 2 to 1 and every later reference down by 1.
    [Fact]
    public void ReplaceBody1WithShorterBody_MovesTheNextBodyDown()
    {
        var o = D2479();
        var d = GebodMerge.Merge(o, SmallAin(1), new(GebodMode.Replace, 1), _ => true);
        Assert.Equal("2 18 2 2 10 0 11 3 12 -2 0", Toks(d.Cards("F.1.B").Single(l => l.Int(0) == 2 && l.Int(2) == 2)));   // "2 19 3 3 ..."
        Assert.Equal("16 15 \"\" 0", Toks(d.Card("B.1")!));
        Assert.Equal([1, 2], AssertSolverShape(d));
        Assert.Equal(Row(o, "B.3.A", 2).Raw, Row(d, "B.3.A", 1).Raw);
        Assert.Equal(LtB2a, Row(d, "B.2.A", 1).Raw);
    }

    [Fact]
    public void EveryCardInTheSchema_HasAGrammarRank()
    {
        foreach (var card in CardSchema.Cards.Keys) Assert.True(Renumber.Rank(card) >= 0, $"{card} is missing from Renumber.Order");
    }

    [Fact]
    public void NewDeck_ThenGebodAdd_Validates()
    {
        var n = GebodMerge.NewDeck();
        Assert.Empty(n.Validate());
        Labeler.Label(n);
        Assert.Empty(GebodMerge.BodyStarts(n));
        Assert.Equal("0 0 \"No Data\" 0", Toks(n.Card("B.1")!));
        Assert.Equal("\"IN.\" \"LB.\" \"SEC.\" 0 0 386.088 386.088", Toks(n.Card("A.3")!));

        var d = GebodMerge.Merge(n, Ain, new(GebodMode.Add), _ => true);
        Assert.Equal("15 14 \"No Data\" 0", Toks(d.Card("B.1")!));         // first body: 14 joints, no NULL joint
        Assert.Equal([1], AssertSolverShape(d));
        Assert.Equal(LtB2a, Row(d, "B.2.A", 1).Raw);
        Assert.Equal(PB3a(1), Row(d, "B.3.A", 1).Raw);
        Assert.Equal("0 0", Toks(d.Card("G.1")!));
        // Round trip: written and read back, it is the same deck.
        Assert.Equal(d.Write(), Deck.Parse(d.Write()).Write());
    }

    [Theory]
    [InlineData(GebodMode.InsertBefore, 2, new[] { 1, 3, 18 })]
    [InlineData(GebodMode.InsertAfter, 1, new[] { 1, 3, 18 })]
    [InlineData(GebodMode.InsertAfter, 2, new[] { 1, 3, 18 })]
    [InlineData(GebodMode.Replace, 2, new[] { 1, 3 })]
    public void OtherPlacements_KeepTheSolverShape(GebodMode mode, int body, int[] starts)
    {
        var d = GebodMerge.Merge(D2479(), Ain, new(mode, body), _ => true);
        Assert.Equal(starts, AssertSolverShape(d));
    }

    [Fact]
    public void InsertBeforeBody2_PutsTheBodyBetween()
    {
        var o = D2479();
        var d = GebodMerge.Merge(o, Ain, new(GebodMode.InsertBefore, 2), _ => true);
        Assert.Equal(LtB2a, Row(d, "B.2.A", 3).Raw);
        Assert.Equal(PB3a(3), Row(d, "B.3.A", 3).Raw);
        Assert.Equal("\"NULL\" 0 0 0 0 0 0 0 0 0 0 0", Toks(Row(d, "B.3.A", 2)));
        Assert.Equal(Row(o, "B.3.A", 2).Raw, Row(d, "B.3.A", 17).Raw);    // old body 2's NULL joint, now 17 -> segment 18
        Assert.Equal("0 0 0 0 0 0 0 0", Toks(Row(d, "G.2", 2)));
    }

    [Fact]
    public void BadInput_Throws()
    {
        Assert.Throws<ArgumentOutOfRangeException>(() => GebodMerge.Merge(D2479(), Ain, new(GebodMode.Replace, 3), _ => true));
        Assert.Throws<ArgumentOutOfRangeException>(() => GebodMerge.Merge(GebodMerge.NewDeck(), Ain, new(GebodMode.InsertBefore, 1), _ => true));
        Assert.Throws<FormatException>(() => GebodMerge.Merge(D2479(), string.Join("\n", Ain.Split('\n').Take(40)), new(GebodMode.Add), _ => true));
    }
}
