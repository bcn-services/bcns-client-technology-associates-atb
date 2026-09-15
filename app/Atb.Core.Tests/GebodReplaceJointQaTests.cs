using Atb.Core.Cards;
using Atb.Core.Lin;
using Xunit;

namespace Atb.Core.Tests;

/// QA: GEBOD Replace by position for joint references outside the body (2479 has none, so H.7 / H.9 are planted),
/// for extra and surplus positions, body 1 and a later non-last body (3-body deck built by InsertAfter 1 of a 3-segment body).
public class GebodReplaceJointQaTests
{
    static Deck D2479() => Deck.Load(Fixtures.ClientDecks().Single(p => Path.GetFileName(p) == "2479_2.LIN"));
    static string Ain => File.ReadAllText(Path.Combine(Fixtures.RepoRoot, "app/Atb.Core.Tests/fixtures/gebod-50m.ain"));
    static string Toks(DeckLine l) => string.Join(" ", l.Tokens);

    /// Rewrites the deck's H.7 and H.9 lines ("0 Card H.7" in 2479) to the given tokens.
    static Deck Plant(Deck o, string h7, string h9)
    {
        var lines = o.Write().Split('\n').Select(l =>
            l.TrimEnd('\r').EndsWith("Card H.7") ? h7 + "    Card H.7" :
            l.TrimEnd('\r').EndsWith("Card H.9") ? h9 + "    Card H.9" : l);
        var d = Deck.Parse(string.Join("\n", lines));
        Assert.Equal(h7, Toks(d.Card("H.7")!));
        Assert.Equal(h9, Toks(d.Card("H.9")!));
        return d;
    }

    /// Bodies [1-2], [3-5], [6-20]; joints 1 | 2 (NULL), 3, 4 | 5 (NULL), 6..19.
    static Deck ThreeBodies()
    {
        var d = GebodMerge.Merge(D2479(), GebodMergeTests.SmallAin(3), new(GebodMode.InsertAfter, 1), _ => true);
        Assert.Equal([1, 3, 6], GebodMerge.BodyStarts(d));
        return d;
    }

    static Deck Replace(Deck o, string ain, int body)
    {
        var d = GebodMerge.Merge(o, ain, new(GebodMode.Replace, body), _ => true);
        Assert.Empty(d.Validate());
        var dir = Environment.GetEnvironmentVariable("ATB_QA_DUMP");
        if (dir != null) { Directory.CreateDirectory(dir); File.WriteAllText(Path.Combine(dir, $"jq-b{body}-{Toks(d.Card("B.1")!).Split(' ')[0]}.lin"), d.Write()); }
        return d;
    }

    /// Body 1 (joint 1) grows to 14 joints: joint 1 kept, body 2's NULL joint 2 -> 15 (STANDARDS divergence: 3I leaves it 2), 5 -> 18.
    [Fact]
    public void Body1Extra_JointRefsKeepPositionAndLaterOnesShiftUp()
    {
        var d = Replace(Plant(D2479(), "3 1 2 5", "1 3 2"), Ain, 1);
        Assert.Equal("3 1 15 18", Toks(d.Card("H.7")!));
        Assert.Equal("1 16 15", Toks(d.Card("H.9")!));
        Assert.Equal("30 29 \"\" 0", Toks(d.Card("B.1")!));
    }

    /// Body 1 shrinks to 1 segment / 0 joints: segment 2 and joint 1 are surplus (entries dropped), the rest shift down by 1.
    [Fact]
    public void Body1Surplus_DropsSurplusJointRefsAndShiftsLaterOnesDown()
    {
        var o = Plant(D2479(), "3 1 2 5", "2 2 1 3 2");
        Assert.Contains(GebodMerge.ReplacedReferences(o, 1, 1), s => s.Label.Contains("H.7", StringComparison.OrdinalIgnoreCase));
        var d = Replace(o, GebodMergeTests.SmallAin(1), 1);
        Assert.Equal("2 1 4", Toks(d.Card("H.7")!));
        Assert.Equal("1 2 1", Toks(d.Card("H.9")!));
    }

    /// Body 2 (joints 2..16) shrinks to 3 segments: joints 2..4 kept, 5..16 surplus.
    [Fact]
    public void Body2Surplus_KeepsJoints2To4_DropsTheRest()
    {
        var o = Plant(D2479(), "4 1 2 4 5", "2 5 4 6 5");
        var listed = GebodMerge.ReplacedReferences(o, 2, 3);
        Assert.Contains(listed, s => s.Label.Contains("H.7", StringComparison.OrdinalIgnoreCase));
        Assert.Contains(listed, s => s.Label.Contains("H.9", StringComparison.OrdinalIgnoreCase));
        var d = Replace(o, GebodMergeTests.SmallAin(3), 2);
        Assert.Equal("3 1 2 4", Toks(d.Card("H.7")!));
        Assert.Equal("1 5 4", Toks(d.Card("H.9")!));
    }

    /// Later non-last body 2 (segments 3-5, joints 2-4) grows to 15: joints 2-4 kept, body 3's NULL 5 -> 17, 7 -> 19, segment 6 -> 18.
    [Fact]
    public void LaterBodyExtra_KeepsPositionsAndShiftsTheNextBodyUp()
    {
        var d = Replace(Plant(ThreeBodies(), "4 2 4 5 7", "1 6 5"), Ain, 2);
        Assert.Equal("4 2 4 17 19", Toks(d.Card("H.7")!));
        Assert.Equal("1 18 17", Toks(d.Card("H.9")!));
        Assert.Equal("32 31 \"\" 0", Toks(d.Card("B.1")!));
        Assert.Equal([1, 3, 18], GebodMerge.BodyStarts(d));
    }

    /// Later non-last body 2 shrinks to 1 segment: joint 2 (its NULL) kept; segments 4, 5 and joints 3, 4 dropped; the rest down 2.
    [Fact]
    public void LaterBodySurplus_DropsSurplusAndShiftsTheNextBodyDown()
    {
        var d = Replace(Plant(ThreeBodies(), "4 2 4 5 7", "2 4 3 6 5"), GebodMergeTests.SmallAin(1), 2);
        Assert.Equal("3 2 3 5", Toks(d.Card("H.7")!));
        Assert.Equal("1 4 3", Toks(d.Card("H.9")!));
        Assert.Equal("18 17 \"\" 0", Toks(d.Card("B.1")!));
        Assert.Equal([1, 3, 4], GebodMerge.BodyStarts(d));
    }
}
