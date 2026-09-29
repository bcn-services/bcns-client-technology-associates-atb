using Atb.Core.Cards;
using Atb.Core.Lin;
using Xunit;

namespace Atb.Core.Tests;

/// QA additions for round 1b: joint-screen paste and the D.4 "nothing to mark" guard. Literals from cases/2479/2479_2.LIN.
public class RenumberGapQaTests
{
    static string Fixture => Path.Combine(Fixtures.RepoRoot, "cases", "2479", "2479_2.LIN");
    static string T(DeckLine l) => string.Join(" ", l.Tokens);

    [Fact]
    public void PasteJointRowAfterJoint2_GoesThroughRenumber_RejectsShortRow()
    {
        var deck = Deck.Load(Fixture);
        var cards = new[] { "B.3.A", "B.3.B", "B.3.C" };
        const string text = "PX\t3\t0\t-2.835566\t0\t-1.744625\t-3.676071\t0\t2.067626\t0\t0\t0\t0\t0\t0\t0\t5\t0\t0\t0\t0\t0\t0\t0\t0\t0\t0\r\n"
                          + "BAD\t3\t0\r\n";
        var res = Deck.ParsePaste(text, cards);
        Assert.Single(res.Rejected);
        Assert.Single(res.Rows);

        Assert.Empty(Renumber.Paste(deck, Entity.Joint, cards, 3, 2, res.Rows));

        Assert.Equal("17 17 \"\" 0", T(deck.Card("B.1")!));
        Assert.Equal(["\"HNG\"", "\"NULL\"", "\"PX\"", "\"P \""], deck.Cards("B.3.A").Take(4).Select(l => l.Tokens[0]));
        Assert.Equal(17, deck.Cards("B.3.A").Count());
        Assert.Empty(deck.Validate());
    }

    [Fact]
    public void InsertSegment_LeavesD4AirbagLinesUntouched()
    {
        var src = File.ReadAllText(Fixture).Split("\r\n").ToList();
        string[] d4 =
        [
            "\"BAG\"    1    CARD D.4.a", "3    3    3    3    3    3    CARD D.4.b", "3    3    3    3    CARD D.4.c",
            "3    3    3    3    3    3    CARD D.4.d", "3    3    3    3    3    3    CARD D.4.e", "3    3    3    3    3    CARD D.4.f",
            "3    3    3    3    3    3    CARD D.4.g", "3    3    3    3    CARD D.4.h",
        ];
        src.InsertRange(174, d4);
        var deck = Deck.Parse(string.Join("\r\n", src));
        var before = deck.Lines.Where(l => l.Card.StartsWith("D.4")).Select(T).ToArray();
        Assert.Equal(8, before.Length);

        Renumber.Insert(deck, Entity.Segment, 3, Renumber.Copy(deck, Entity.Segment, 3));

        Assert.Equal(["\"BAG\" 1", "3 3 3 3 3 3", "3 3 3 3", "3 3 3 3 3 3", "3 3 3 3 3 3", "3 3 3 3 3", "3 3 3 3 3 3", "3 3 3 3"],
            deck.Lines.Where(l => l.Card.StartsWith("D.4")).Select(T));
    }
}
