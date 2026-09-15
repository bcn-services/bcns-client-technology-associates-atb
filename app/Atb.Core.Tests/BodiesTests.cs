using Atb.Core.Cards;
using Atb.Core.Lin;
using Xunit;

namespace Atb.Core.Tests;

/// Body Summary (ATB 3I Body.cs). Expected lines are read off the client decks by hand:
/// 2479_2: body 1 = segments 1-2 (RN, DR), joint 1 HNG (Seg JNT 1), NULL joint 2; body 2 = segments 3-17, joints 3-16;
/// vehicles are segments 18, 19. 2495_2: body 1 = segments 1-17, joints 1-16, NULL joint 17; body 2 = 18-34, joints
/// 18-33; vehicle segment 35 (both G.2 rows name it).
public class BodiesTests
{
    static Deck Load(string rel) => Deck.Load(Path.Combine(Fixtures.RepoRoot, rel));
    static string Toks(DeckLine l) => string.Join(" ", l.Tokens);
    static DeckLine Row(Deck d, string card, int n) => d.Cards(card).ElementAt(n - 1);
    const string HngTail = "1 11 0 5 -11 0 0 0 0 0";   // HNG's B.3.a after Seg JNT

    [Fact]
    public void Summary_ListsBodiesWithSegmentAndJointCounts()
    {
        Assert.Equal([new(1, 2, 1), new(2, 15, 14)], Bodies.Summary(Load("cases/2479/2479_2.LIN")));
        Assert.Equal([new(1, 17, 16), new(2, 17, 16)], Bodies.Summary(Load("cases/2495/2495_2.LIN")));
        Assert.Equal([new(1, 15, 14)], Bodies.Summary(Load("cases/2638/2638_Start_135_.LIN")));
    }

    /// Done-when 1 names 2638_Start_135_, but that deck holds one body (no B.3.a has Seg JNT 0): there is no second body.
    [Fact]
    public void Deck2638_HasNoSecondBody()
    {
        var o = Load("cases/2638/2638_Start_135_.LIN");
        Assert.Equal([1], GebodMerge.BodyStarts(o));
        Assert.Throws<ArgumentOutOfRangeException>(() => Bodies.Delete(o, 2));
    }

    [Fact]
    public void DeleteSecondBody_2495_LeavesBody1AndAValidDeck()
    {
        var o = Load("cases/2495/2495_2.LIN");
        var before = o.Write();
        var d = Bodies.Delete(o, 2);
        Assert.Equal(before, o.Write());                                   // the open deck is untouched
        Assert.Empty(d.Validate());
        if (Environment.GetEnvironmentVariable("ATB_QA_DUMP") is { Length: > 0 } dir) File.WriteAllText(Path.Combine(dir, "2495_del2.lin"), d.Write());   // for src/atb
        Assert.Equal("17 16 \"\" 0", Toks(d.Card("B.1")!));
        Assert.Equal([1], GebodMerge.BodyStarts(d));
        Assert.Equal("-5.9 10 -16.3 0 0 0 18 18", Toks(d.Cards("G.2").Single()));   // vehicle 35 is now segment 18
        Assert.Equal(17, d.Cards("G.3.A").Count());
        Assert.Equal("0 22 0 0 0 0 0 0 0 18", Toks(Row(d, "G.3.A", 1)));
        Assert.Equal("\"LW\" 16 0 -0.637863 0.5094141 4.70225 0.04023699 0.561779 -2.11287 0 0 0", Toks(d.Cards("B.3.A").Last()));
    }

    /// Body 1 goes with joints 1..17 (3I DeleteBody: the next body's NULL joint 17), so body 2 roots itself as body 1.
    [Fact]
    public void DeleteFirstBody_2495_MovesBody2ToTheFront()
    {
        var d = Bodies.Delete(Load("cases/2495/2495_2.LIN"), 1);
        Assert.Empty(d.Validate());
        Assert.Equal("17 16 \"\" 0", Toks(d.Card("B.1")!));
        Assert.Equal([1], GebodMerge.BodyStarts(d));
        Assert.Equal("\"P \" 1 -1 -1.446761 0 -2.235768 -2.389261 0 2.245 0 0 0", Toks(Row(d, "B.3.A", 1)));
        Assert.Equal("-5.7 -10 -15 0 0 0 18 18", Toks(d.Cards("G.2").Single()));
        Assert.Equal("0 0 0 0 0 0 0 0 0 18", Toks(Row(d, "G.3.A", 1)));  // was segment 18's: vehicle 35 -> 18
        Assert.Equal("0 0 0 0 0 0 0 0 0 1", Toks(Row(d, "G.3.A", 2)));   // was 19's, Ref Segment 18 -> 1
    }

    /// Copy body 1 of 2479_2, add it after the last body: segments 18-19, NULL joint 17, joint 18 = HNG on the copy.
    [Fact]
    public void CopyBody1AndAdd_2479_AppendsItWithReferencesOnTheCopy()
    {
        var o = Load("cases/2479/2479_2.LIN");
        var c = Bodies.Copy(o, 1);
        Assert.Equal(new Bodies.Copied(1, 2), c);
        var d = Bodies.Insert(o, c, new(GebodMode.Add));
        Assert.Empty(d.Validate());
        Assert.Equal("19 18 \"\" 0", Toks(d.Card("B.1")!));
        Assert.Equal([1, 3, 18], GebodMerge.BodyStarts(d));
        Assert.Equal("\"RN\" 112 53.1 47.7 38.1 2 2 2 0 0 0 0", Toks(Row(d, "B.2.A", 18)));
        Assert.Equal("\"DR\" 10 1.9 1.2 3.2 2 2 2 0 0 0 0", Toks(Row(d, "B.2.A", 19)));
        Assert.Equal("\"HNG\" 1 " + HngTail, Toks(Row(d, "B.3.A", 1)));            // the original is untouched
        Assert.Equal("\"NULL\" 0 0 0 0 0 0 0 0 0 0 0", Toks(Row(d, "B.3.A", 17)));
        Assert.Equal("\"HNG\" 18 " + HngTail, Toks(Row(d, "B.3.A", 18)));           // Seg JNT 1 -> the copy's first segment
        Assert.Equal("0 0 0 0 0 0 0 0 0 0", Toks(Row(d, "G.3.A", 18)));
        Assert.Equal("0 0 0 0 0 0 0 0 0 18", Toks(Row(d, "G.3.A", 19)));            // Ref Segment 1 -> 18
        Assert.Equal("0 0 0 0 0 0 0 0 0 1", Toks(Row(d, "G.3.A", 2)));              // the original's still names 1
        Assert.Equal("0 0 0 0 0 0 0 0", Toks(Row(d, "G.2", 3)));                     // UpdateDueToBody's blank row
        Assert.Equal("1 21 1 52 1 0 1 3 1 -1 0", Toks(d.Cards("F.1.B").First()));    // vehicle 19 -> 21, ellipsoid 50 -> 52
        Assert.Equal(19, d.Cards("D.7").Sum(l => l.Count));
        Assert.Equal(19, d.Cards("F.3.A").Sum(l => l.Count));
        Assert.Equal(18, d.Cards("F.4.A").Sum(l => l.Count));
    }

    /// Insert the copy before body 1: the copy is segments 1-2, its NULL joint 2 roots the old body 1 (now 3-4).
    [Fact]
    public void CopyBody1AndInsertBeforeBody1_2479_RootsTheOldFirstBody()
    {
        var o = Load("cases/2479/2479_2.LIN");
        var d = Bodies.Insert(o, Bodies.Copy(o, 1), new(GebodMode.InsertBefore, 1));
        Assert.Empty(d.Validate());
        Assert.Equal([1, 3, 5], GebodMerge.BodyStarts(d));
        Assert.Equal("\"HNG\" 1 " + HngTail, Toks(Row(d, "B.3.A", 1)));             // the copy's joint on its own segment 1
        Assert.Equal("\"NULL\" 0 0 0 0 0 0 0 0 0 0 0", Toks(Row(d, "B.3.A", 2)));
        Assert.Equal("\"HNG\" 3 " + HngTail, Toks(Row(d, "B.3.A", 3)));             // the old body 1's joint, shifted
        Assert.Equal("0 0 0 0 0 0 0 0 0 1", Toks(Row(d, "G.3.A", 2)));
        Assert.Equal("0 0 0 0 0 0 0 0 0 3", Toks(Row(d, "G.3.A", 4)));
    }

    /// Replace body 2 of 2479_2 (15 segments) with a copy of body 1 (2 segments), through GebodMerge.ReplaceBody:
    /// references to body 2's segments 1-2 (3, 4) stay; those to its segments 3-15 (5..17) go; vehicles 18, 19 -> 5, 6.
    [Fact]
    public void ReplaceBody2WithCopiedBody1_2479_KeepsRefsByPositionAndDropsTheRest()
    {
        var o = Load("cases/2479/2479_2.LIN");
        var d = Bodies.Replace(o, 2, Bodies.Copy(o, 1));
        Assert.Empty(d.Validate());
        Assert.Equal("4 3 \"\" 0", Toks(d.Card("B.1")!));
        Assert.Equal([1, 3], GebodMerge.BodyStarts(d));
        Assert.Equal("\"RN\" 112 53.1 47.7 38.1 2 2 2 0 0 0 0", Toks(Row(d, "B.2.A", 3)));
        Assert.Equal("\"HNG\" 3 " + HngTail, Toks(Row(d, "B.3.A", 3)));
        Assert.Equal("0 0 0 0 0 0 0 0 0 3", Toks(Row(d, "G.3.A", 4)));             // the copy's Ref Segment 1 -> 3
        // H.2: row (19, 3) keeps segment 3 by position (vehicle 19 -> 6); row (19, 5) named a dropped position and goes.
        Assert.Equal("1 6 3 0 0 0 0", Toks(d.Card("H.2.A")!));
        Assert.Equal("0", Toks(d.Card("H.2.B")!));
        Assert.Equal(2, d.Cards("G.2").Count());                                   // the body count does not change
    }

    /// Replace body 1 (2 segments) with a copy of body 2 (15): body 1 grows, body 2 moves up by 13.
    [Fact]
    public void ReplaceBody1WithCopiedBody2_2479_GrowsAndShiftsTheNextBody()
    {
        var o = Load("cases/2479/2479_2.LIN");
        var d = Bodies.Replace(o, 1, Bodies.Copy(o, 2));
        Assert.Empty(d.Validate());
        Assert.Equal("30 29 \"\" 0", Toks(d.Card("B.1")!));
        Assert.Equal([1, 16], GebodMerge.BodyStarts(d));
        Assert.Equal("\"LT \" 30.86138 1.400881 1.299289 2.108249 5.29593 8.04508 4.892385 0.353062 0 1.993187 1", Toks(Row(d, "B.2.A", 1)));
        Assert.Equal("\"W \" 2 0 -2.505203 0 -0.9570769 -0.9472971 0 5.14171 0 0 0", Toks(Row(d, "B.3.A", 2)));   // P, W on the copy's own segments
        Assert.Equal("\"P \" 16 0 -2.835566 0 -1.744625 -3.676071 0 2.067626 0 0 0", Toks(Row(d, "B.3.A", 16)));  // the old body 2, 3 -> 16
        Assert.Equal("\"NULL\" 0 0 0 0 0 0 0 0 0 0 0", Toks(Row(d, "B.3.A", 15)));
    }

    /// Families are positional (STANDARDS.md): a G.3.A missing mid-deck would hand the copy segment 6's row as segment 5's.
    [Fact]
    public void CopyBody_FamilyMissingForOneSegment_Throws()
    {
        var o = Load("cases/2479/2479_2.LIN");
        o.Lines.Remove(Row(o, "G.3.A", 5));
        var c = Bodies.Copy(o, 2);
        var ex = Assert.Throws<InvalidOperationException>(() => Bodies.Insert(o, c, new(GebodMode.Add)));
        Assert.Contains("G.3.A", ex.Message);
        Assert.Throws<InvalidOperationException>(() => Bodies.Replace(o, 1, c));
    }
}
