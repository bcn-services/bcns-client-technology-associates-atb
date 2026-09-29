using Atb.Core.Cards;
using Atb.Core.Lin;
using Xunit;

namespace Atb.Core.Tests;

/// QA for Body Summary: 2893_5 has a continuation card present for some segments and absent for others
/// (body 1 = segments 1-5 without B.2.B; body 2 = segments 6-20, each with B.2.B; bodies 3, 4 = segments 21, 22).
/// A copy must carry each segment's own B.2.B, not shift it onto a neighbour.
public class BodiesQaTests
{
    static Deck Load() => Deck.Load(Path.Combine(Fixtures.RepoRoot, "cases/2893/2893_5.LIN"));
    static string Toks(DeckLine? l) => l is null ? "<absent>" : string.Join(" ", l.Tokens);
    static List<string> Seg(Deck d, int s) => d.Rows(["B.2.A", "B.2.B"])[s - 1].Select(Toks).ToList();

    [Fact]
    public void Deck2893_HasFourBodies_AndPartialB2B()
    {
        var d = Load();
        Assert.Equal([1, 6, 21, 22], GebodMerge.BodyStarts(d));
        Assert.Equal("<absent>", Seg(d, 5)[1]);
        Assert.NotEqual("<absent>", Seg(d, 6)[1]);
    }

    [Fact]
    public void CopyBody2AndInsertBeforeBody1_CarriesEachSegmentsOwnB2B()
    {
        var o = Load();
        var d = Bodies.Insert(o, Bodies.Copy(o, 2), new(GebodMode.InsertBefore, 1));
        Assert.Empty(d.Validate());
        Assert.Equal([1, 16, 21, 36, 37], GebodMerge.BodyStarts(d));
        for (int i = 0; i < 15; i++) Assert.Equal(Seg(o, 6 + i), Seg(d, 1 + i));    // the copy, B.2.B on each
        for (int i = 0; i < 5; i++) Assert.Equal(Seg(o, 1 + i), Seg(d, 16 + i));    // old body 1, still no B.2.B
        Assert.Equal(d.Cards("B.2.A").Count(), d.Cards("G.3.A").Count());
        Assert.Equal(15 + 15, d.Cards("B.2.B").Count());
    }

    [Fact]
    public void CopyBody1AndAdd_CopyHasNoB2B()
    {
        var o = Load();
        var d = Bodies.Insert(o, Bodies.Copy(o, 1), new(GebodMode.Add));
        Assert.Empty(d.Validate());
        Assert.Equal([1, 6, 21, 22, 23], GebodMerge.BodyStarts(d));
        for (int i = 0; i < 5; i++) Assert.Equal(Seg(o, 1 + i)[1], Seg(d, 23 + i)[1]);
        Assert.Equal(15, d.Cards("B.2.B").Count());
        Assert.Equal(26, d.Cards("B.3.A").Count());   // 21 + NULL + 4 copied joints
    }

    [Fact]
    public void DeleteMiddleBody2_KeepsNeighboursB2BAndValidates()
    {
        var o = Load();
        var d = Bodies.Delete(o, 2);
        Assert.Empty(d.Validate());
        Assert.Equal([1, 6, 7], GebodMerge.BodyStarts(d));
        Assert.Empty(d.Cards("B.2.B"));
        Assert.Equal(Seg(o, 21), Seg(d, 6));
        Assert.Equal(Seg(o, 22), Seg(d, 7));
    }
}
