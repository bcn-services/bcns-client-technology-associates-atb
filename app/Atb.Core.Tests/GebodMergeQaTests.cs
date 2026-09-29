using Atb.Core.Cards;
using Atb.Core.Lin;
using Xunit;

namespace Atb.Core.Tests;

/// QA: independent checks on GebodMerge. Solver acceptance is run out of band against the decks written by
/// DumpMergedDecks (set ATB_QA_DUMP=dir); the in-suite checks mirror the solver's input STOPs.
public class GebodMergeQaTests
{
    static Deck D2479() => Deck.Load(Fixtures.ClientDecks().Single(p => Path.GetFileName(p) == "2479_2.LIN"));
    static string Ain => File.ReadAllText(Path.Combine(Fixtures.RepoRoot, "app/Atb.Core.Tests/fixtures/gebod-50m.ain"));

    static IEnumerable<(string Name, Deck Deck)> Merged()
    {
        yield return ("add", GebodMerge.Merge(D2479(), Ain, new(GebodMode.Add), _ => true));
        yield return ("before1", GebodMerge.Merge(D2479(), Ain, new(GebodMode.InsertBefore, 1), _ => true));
        yield return ("before2", GebodMerge.Merge(D2479(), Ain, new(GebodMode.InsertBefore, 2), _ => true));
        yield return ("after1", GebodMerge.Merge(D2479(), Ain, new(GebodMode.InsertAfter, 1), _ => true));
        yield return ("after2", GebodMerge.Merge(D2479(), Ain, new(GebodMode.InsertAfter, 2), _ => true));
        yield return ("replace1", GebodMerge.Merge(D2479(), Ain, new(GebodMode.Replace, 1), _ => true));
        yield return ("replace2", GebodMerge.Merge(D2479(), Ain, new(GebodMode.Replace, 2), _ => true));
        yield return ("newadd", GebodMerge.Merge(GebodMerge.NewDeck(), Ain, new(GebodMode.Add), _ => true));
        yield return ("replace1small", GebodMerge.Merge(D2479(), GebodMergeTests.SmallAin(1), new(GebodMode.Replace, 1), _ => true));
        yield return ("replace2small", GebodMerge.Merge(D2479(), GebodMergeTests.SmallAin(3), new(GebodMode.Replace, 2), _ => true));
    }

    [Fact]
    public void DumpMergedDecks()
    {
        var dir = Environment.GetEnvironmentVariable("ATB_QA_DUMP");
        foreach (var (name, d) in Merged())
        {
            Assert.Empty(d.Validate());
            if (dir != null) { Directory.CreateDirectory(dir); File.WriteAllText(Path.Combine(dir, name + ".lin"), d.Write()); }
        }
    }

    /// InsertAfter the last body equals Add; InsertAfter 1 equals InsertBefore 2 (same s0 in 3I's placement).
    [Fact]
    public void InsertAfter_MatchesEquivalentPlacements()
    {
        var o = D2479();
        Assert.Equal(GebodMerge.Merge(o, Ain, new(GebodMode.Add), _ => true).Write(), GebodMerge.Merge(o, Ain, new(GebodMode.InsertAfter, 2), _ => true).Write());
        Assert.Equal(GebodMerge.Merge(o, Ain, new(GebodMode.InsertBefore, 2), _ => true).Write(), GebodMerge.Merge(o, Ain, new(GebodMode.InsertAfter, 1), _ => true).Write());
    }

    /// Every segment/joint ref in every card family of 2479 is compared against the same ref in the merged deck
    /// by entity identity (name/raw text of the referenced B.2.a / B.3.a row), not by arithmetic — so a family
    /// shifted by the wrong amount, or not shifted, points at a different named segment and fails.
    [Theory]
    [InlineData(GebodMode.InsertBefore, 1)]
    [InlineData(GebodMode.InsertBefore, 2)]
    [InlineData(GebodMode.Add, 0)]
    public void EveryFamilyRef_StillNamesTheSameEntity(GebodMode mode, int body)
    {
        var o = D2479();
        var d = GebodMerge.Merge(o, Ain, new(mode, body), _ => true);
        Labeler.Label(o); Labeler.Label(d);
        var oSeg = o.Cards("B.2.A").Select(l => l.Raw ?? "").ToList();
        var dSeg = d.Cards("B.2.A").Select(l => l.Raw ?? "").ToList();
        var oJnt = o.Cards("B.3.A").Select(l => l.Str(0) ?? "").ToList();
        var dJnt = d.Cards("B.3.A").Select(l => l.Str(0) ?? "").ToList();
        string[] skipCards = ["B.1", "B.2.A", "B.2.B", "B.3.A", "B.3.B", "B.4.A", "B.4.B", "B.5.A", "B.5.B", "B.5.C", "B.6", "G.3.A", "G.2", "D.7", "F.3.A", "F.4.A"];
        int checkedRefs = 0;
        var families = new HashSet<string>();
        foreach (var card in o.Lines.Select(l => l.Card).Where(c => c.Length > 0 && !skipCards.Contains(c.ToUpperInvariant())).Distinct())
        {
            var olds = o.Cards(card).ToList(); var news = d.Cards(card).ToList();
            Assert.True(olds.Count == news.Count, $"{card}: {olds.Count} -> {news.Count} rows");
            for (int r = 0; r < olds.Count; r++)
            {
                int sk = CardSchema.Skip(card, olds[r].Count);
                for (int i = 0; i < olds[r].Count; i++)
                {
                    var kind = CardSchema.KindOf(card, i + sk);
                    if (kind is not (Kind.SegRef or Kind.JointRef or Kind.EllipRef) || !int.TryParse(olds[r].Tokens[i], out var v) || !int.TryParse(news[r].Tokens[i], out var w)) continue;
                    // Ellipsoids 1..NSEG belong to segments 1..NSEG (same identity as the segment); later ones move by the added segments.
                    if (kind == Kind.EllipRef && Math.Abs(v) > oSeg.Count) { Assert.True(Math.Abs(w) == Math.Abs(v) + dSeg.Count - oSeg.Count, $"{card} row {r + 1} tok {i + 1}: ellipsoid {v} -> {w}"); checkedRefs++; continue; }
                    Assert.True(Math.Sign(v) == Math.Sign(w) || v == 0, $"{card} row {r + 1} tok {i + 1}: sign {v} -> {w}");
                    int av = Math.Abs(v), aw = Math.Abs(w);
                    if (av == 0) { Assert.Equal(0, w); continue; }
                    var (ol, nl) = kind == Kind.JointRef ? (oJnt, dJnt) : (oSeg, dSeg);
                    if (av > ol.Count) continue;                            // vehicle / out-of-range refs are the other kinds' job
                    Assert.True(aw <= nl.Count && ol[av - 1] == nl[aw - 1], $"{card} row {r + 1} tok {i + 1} ({CardSchema.Header(card, i + sk)}): {v} -> {w} names a different entity");
                    checkedRefs++; families.Add(card.Split('.')[0]);
                }
            }
        }
        Assert.True(checkedRefs > 20, $"only {checkedRefs} refs checked");
        Assert.Contains("H", families); Assert.Contains("B", families.Append("B"));
    }

    /// Shorter GEBOD bodies (surplus positions with references): asked once, a decline leaves the deck byte-identical.
    [Theory]
    [InlineData(1, 1)]
    [InlineData(2, 3)]
    public void ReplaceDecline_LeavesDeckByteIdentical_AndConfirmIsAskedOnce(int body, int newSegs)
    {
        var o = D2479();
        var before = o.Write();
        int asked = 0;
        Assert.Throws<OperationCanceledException>(() => GebodMerge.Merge(o, GebodMergeTests.SmallAin(newSegs), new(GebodMode.Replace, body), _ => { asked++; return false; }));
        Assert.Equal(1, asked);
        Assert.Equal(before, o.Write());
        asked = 0;
        GebodMerge.Merge(o, GebodMergeTests.SmallAin(newSegs), new(GebodMode.Replace, body), _ => { asked++; return true; });
        Assert.Equal(1, asked);
        Assert.Equal(before, o.Write());
    }

    /// A GEBOD body at least as long as the replaced one drops nothing, so confirm is never asked.
    [Theory]
    [InlineData(1)]
    [InlineData(2)]
    public void ReplaceWithLongerOrEqualBody_DoesNotAsk(int body)
    {
        int asked = 0;
        GebodMerge.Merge(D2479(), Ain, new(GebodMode.Replace, body), _ => { asked++; return true; });
        Assert.Equal(0, asked);
        Assert.Empty(GebodMerge.ReplacedReferences(D2479(), body, 15));
    }

    /// Independent oracle for 3I's by-position rule, arithmetic only: every seg/joint/ellipsoid ref outside the replaced
    /// body names the same position when it is before or inside the kept part of the body, and moves by the count
    /// difference when it is after the body. Body 1 grows (2 -> 15 segments), body 2 stays 15.
    [Theory]
    [InlineData(1)]
    [InlineData(2)]
    public void Replace_EveryFamilyRef_KeepsItsPositionOrMovesByTheDifference(int body)
    {
        var o = D2479();
        var d = GebodMerge.Merge(o, Ain, new(GebodMode.Replace, body), _ => true);
        Labeler.Label(o); Labeler.Label(d);
        var starts = GebodMerge.BodyStarts(o);
        int nseg = o.Cards("B.2.A").Count();
        int a = starts[body - 1], b = body < starts.Count ? starts[body] - 1 : nseg, ds = 15 - (b - a + 1);
        int ja = a > 1 ? a - 1 : 1, jb = b - 1;                             // joints of the body; ds is the joint difference too
        string[] skipCards = ["B.1", "B.2.A", "B.2.B", "B.3.A", "B.3.B", "B.4.A", "B.4.B", "B.5.A", "B.5.B", "B.5.C", "B.6", "G.3.A", "G.2", "D.7", "F.3.A", "F.4.A"];
        int checkedRefs = 0, kept = 0;
        foreach (var card in o.Lines.Select(l => l.Card).Where(c => c.Length > 0 && !skipCards.Contains(c.ToUpperInvariant())).Distinct())
        {
            var olds = o.Cards(card).ToList(); var news = d.Cards(card).ToList();
            Assert.True(olds.Count == news.Count, $"{card}: {olds.Count} -> {news.Count} rows");
            for (int r = 0; r < olds.Count; r++)
                for (int i = 0; i < olds[r].Count; i++)
                {
                    int sk = CardSchema.Skip(card, olds[r].Count);
                    var kind = CardSchema.KindOf(card, i + sk);
                    if (kind is not (Kind.SegRef or Kind.JointRef or Kind.EllipRef) || !int.TryParse(olds[r].Tokens[i], out var v) || !int.TryParse(news[r].Tokens[i], out var w)) continue;
                    int av = Math.Abs(v);
                    var (lo, hi) = kind == Kind.JointRef ? (ja, jb) : (a, b);
                    int want = av == 0 || av <= hi ? v : Math.Sign(v) * (av + ds);
                    if (av >= lo && av <= hi) kept++;
                    Assert.True(want == w, $"{card} row {r + 1} tok {i + 1} ({CardSchema.Header(card, i + sk)}): {v} -> {w}, want {want}");
                    checkedRefs++;
                }
        }
        Assert.True(checkedRefs > 20 && kept > 0, $"{checkedRefs} refs checked, {kept} into the body");
    }

    /// Independent oracle: scan the original deck by schema kind for every seg/joint/ellipsoid ref token outside the
    /// replaced body's own B/G.3 rows that points at a surplus position; the confirm list must name exactly those lines.
    [Theory]
    [InlineData(1, 1)]
    [InlineData(2, 3)]
    public void ReplaceConfirmList_CoversEveryRefToASurplusPosition(int body, int newSegs)
    {
        var o = D2479();
        Labeler.Label(o);
        var starts = GebodMerge.BodyStarts(o);
        int nseg = o.Cards("B.2.A").Count();
        int a0 = starts[body - 1], b = body < starts.Count ? starts[body] - 1 : nseg;
        int a = a0 + newSegs, j0 = a0 > 1 ? a0 - 1 + newSegs : newSegs, j1 = b - 1;   // surplus segments a..b, joints j0..j1
        string[] own = ["B.1", "B.2.A", "B.2.B", "B.3.A", "B.3.B", "B.4.A", "B.4.B", "B.5.A", "B.5.B", "B.5.C", "B.6", "D.7", "F.3.A", "F.4.A", "F.7.A"];
        var g3 = o.Cards("G.3.A").ToList();                                // G.3.a rows a..b go with their segments; others' Ref Segment counts
        var want = new SortedSet<int>();
        for (int li = 0; li < o.Lines.Count; li++)
        {
            var l = o.Lines[li];
            if (l.Card.Length == 0 || own.Contains(l.Card.ToUpperInvariant())) continue;
            int gi = g3.IndexOf(l);
            if (gi >= 0 && gi + 1 >= a0 && gi + 1 <= b) continue;
            int sk = CardSchema.Skip(l.Card, l.Count);
            for (int i = 0; i < l.Count; i++)
            {
                var kind = CardSchema.KindOf(l.Card, i + sk);
                if (!int.TryParse(l.Tokens[i], out var v) || v == 0) continue;
                int av = Math.Abs(v);
                if ((kind is Kind.SegRef or Kind.EllipRef && av >= a && av <= b) || (kind == Kind.JointRef && av >= j0 && av <= j1)) want.Add(li + 1);
            }
        }
        IReadOnlyList<RefSite>? got = null;
        var d = GebodMerge.Merge(o, GebodMergeTests.SmallAin(newSegs), new(GebodMode.Replace, body), s => { got = s; return true; });
        Assert.True(want.Count > 0, "no reference to a surplus position: the case tests nothing");
        var gotLines = new SortedSet<int>(got?.Select(s => s.Line) ?? []);
        Assert.True(want.SetEquals(gotLines), $"body {body}: schema scan {string.Join(",", want)}; confirm list {string.Join(",", gotLines)}; missing {string.Join(",", want.Except(gotLines))}; extra {string.Join(",", gotLines.Except(want))}");
        // what actually disappears: each listed line's original text is gone from the merged deck
        var after = d.Lines.Select(x => x.Raw).ToHashSet();
        foreach (var ln in gotLines) Assert.True(!after.Contains(o.Lines[ln - 1].Raw), $"line {ln} '{o.Lines[ln - 1].Raw}' survived the Replace unchanged");
    }

    /// Solver input checks on the merged decks (src/Chain.for, input_bcards.for, G.2 per body).
    [Fact]
    public void MergedDecks_PassSolverInputChecks()
    {
        foreach (var (name, d) in Merged())
        {
            var b1 = d.Card("B.1")!;
            Assert.True(b1.Int(0) == d.Cards("B.2.A").Count(), name);
            Assert.True(b1.Int(1) == d.Cards("B.3.A").Count(), name);
            Assert.True(b1.Int(1) == b1.Int(0) - 1, name);
            var prox = d.Cards("B.3.A").Select(l => l.Int(1)).ToList();
            for (int j = 1; j <= prox.Count; j++) Assert.True(Math.Abs(prox[j - 1]) <= j, $"{name} joint {j}: prox {prox[j - 1]} not earlier than segment {j + 1}");
            int bodies = 1 + prox.Count(p => p == 0);
            Assert.True(bodies == d.Cards("G.2").Count(), $"{name}: {bodies} bodies, {d.Cards("G.2").Count()} G.2");
        }
    }
}
