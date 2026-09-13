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

    [Fact]
    public void ReplaceBody1_RemovesItsSegmentsAndJointsThenInserts()
    {
        var o = D2479();
        var d = GebodMerge.Merge(o, Ain, new(GebodMode.Replace, 1), _ => true);
        Assert.Equal("30 29 \"\" 0", Toks(d.Card("B.1")!));                // 17-2+15 segments; 16-2+14+1 joints
        Assert.Equal([1, 16], AssertSolverShape(d));
        Assert.DoesNotContain(d.Cards("B.2.A"), l => l.Str(0) is "RN" or "DR");
        Assert.Equal(LtB2a, Row(d, "B.2.A", 1).Raw);
        Assert.Equal("\"NULL\" 0 0 0 0 0 0 0 0 0 0 0", Toks(Row(d, "B.3.A", 15)));
        Assert.Equal(2, d.Cards("G.2").Count());                           // same number of bodies: G.2 untouched (UpdateDueToBody bdyChange 0)
        // Old joints 3..16 (body 2) are now 16..29 with Seg JNT moved by 15 - 2.
        for (int j = 3; j <= 16; j++)
        {
            var (a, b) = (Row(o, "B.3.A", j), Row(d, "B.3.A", j + 13));
            Assert.Equal(a.Str(0), b.Str(0));
            Assert.Equal(a.Int(1) + 13, b.Int(1));
        }
        // Written out: 2479 F.1.b line 217 "2 19 3 3 ..." and H.2.a "2 19 3 ...": segments 3.. move by 15 - 2 and the
        // vehicle segment 19 (NSEG + 2) becomes 32. F.1.b rows on segments 1-2 (line 209 "1 19 1 50 ...") are gone.
        Assert.Contains("2 32 16 16 10 0 11 3 12 -2 0", d.Cards("F.1.B").Select(Toks));
        Assert.DoesNotContain(d.Cards("F.1.B"), l => l.Tokens[0] == "1" && l.Tokens[2] is "1" or "2");
        Assert.Equal("2 32 16 0 0 0 0", Toks(d.Card("H.2.A")!));
    }

    [Fact]
    public void ReplaceBody1_ConfirmSeesTheRemovedReferences_AndDeclineChangesNothing()
    {
        var src = D2479();
        var before = src.Write();
        IReadOnlyList<RefSite>? seen = null;
        Assert.Throws<OperationCanceledException>(() => GebodMerge.Merge(src, Ain, new(GebodMode.Replace, 1), s => { seen = s; return false; }));
        Assert.Equal(before, src.Write());
        Assert.NotNull(seen);
        Assert.Equal(GebodMerge.ReplacedReferences(src, 1), seen);
        // 2479 line 209, F.1.b "1 19 1 50 ...": its Contact Segment is segment 1 of the replaced body; H.6 line 325 names segments 1, 2.
        Assert.Contains(seen, s => s.Line == 209 && s.Field == "Contact Segment");
        Assert.Contains(seen, s => s.Line == 325);
        Assert.DoesNotContain(seen, s => s.Label.Contains("B.", StringComparison.OrdinalIgnoreCase));   // the body's own lines are not "references"

        IReadOnlyList<RefSite>? accepted = null;
        var d = GebodMerge.Merge(src, Ain, new(GebodMode.Replace, 1), s => { accepted = s; return true; });
        Assert.Equal(seen, accepted);
        Assert.Equal("30 29 \"\" 0", Toks(d.Card("B.1")!));
        Assert.Equal(before, src.Write());
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
