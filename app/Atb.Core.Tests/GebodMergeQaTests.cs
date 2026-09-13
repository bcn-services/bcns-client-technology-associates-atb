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
        yield return ("add", GebodMerge.Merge(D2479(), Ain, new(GebodMode.Add)));
        yield return ("before1", GebodMerge.Merge(D2479(), Ain, new(GebodMode.InsertBefore, 1)));
        yield return ("before2", GebodMerge.Merge(D2479(), Ain, new(GebodMode.InsertBefore, 2)));
        yield return ("after1", GebodMerge.Merge(D2479(), Ain, new(GebodMode.InsertAfter, 1)));
        yield return ("after2", GebodMerge.Merge(D2479(), Ain, new(GebodMode.InsertAfter, 2)));
        yield return ("replace1", GebodMerge.Merge(D2479(), Ain, new(GebodMode.Replace, 1)));
        yield return ("replace2", GebodMerge.Merge(D2479(), Ain, new(GebodMode.Replace, 2)));
        yield return ("newadd", GebodMerge.Merge(GebodMerge.NewDeck(), Ain, new(GebodMode.Add)));
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
        Assert.Equal(GebodMerge.Merge(o, Ain, new(GebodMode.Add)).Write(), GebodMerge.Merge(o, Ain, new(GebodMode.InsertAfter, 2)).Write());
        Assert.Equal(GebodMerge.Merge(o, Ain, new(GebodMode.InsertBefore, 2)).Write(), GebodMerge.Merge(o, Ain, new(GebodMode.InsertAfter, 1)).Write());
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
        var d = GebodMerge.Merge(o, Ain, new(mode, body));
        Labeler.Label(o); Labeler.Label(d);
        var oSeg = o.Cards("B.2.A").Select(l => l.Raw).ToList();
        var dSeg = d.Cards("B.2.A").Select(l => l.Raw).ToList();
        var oJnt = o.Cards("B.3.A").Select(l => l.Str(0)).ToList();
        var dJnt = d.Cards("B.3.A").Select(l => l.Str(0)).ToList();
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
