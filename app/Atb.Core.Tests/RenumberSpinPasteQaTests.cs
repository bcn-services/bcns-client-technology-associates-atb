using Atb.Core.Cards;
using Atb.Core.Lin;
using Xunit;

namespace Atb.Core.Tests;

/// QA: B.4 / B.5 joint paste spin-line check (Renumber.Paste, gi > 0). 2479_2.LIN has no spin joints, so
/// SpinDeck builds one from the schema: joint 2 ("NULL", line 42) gets B.3.A Joint Type 4 (-> "304", a spin
/// joint per Labeler.IsSpin), a B.4.B after its B.4.A (line 73) and B.5.B + B.5.C after its B.5.A (line 89).
public class RenumberSpinPasteQaTests
{
    static string Fixture => Path.Combine(Fixtures.RepoRoot, "cases", "2479", "2479_2.LIN");

    static Deck SpinDeck()
    {
        var src = File.ReadAllText(Fixture).Split("\r\n").ToList();
        Assert.Equal("\"NULL\"    0    0    0    0    0    0    0    0    0    0    0    CARD B.3.a", src[41]);
        src[41] = "\"NULL\"    0    4    0    0    0    0    0    0    0    0    0    CARD B.3.a";
        src.Insert(89, "0    0    0    0    0    0    0    CARD B.5.c");   // after B.5.B, both before old line 90
        src.Insert(89, "0    0    0    0    0    0    0    CARD B.5.b");
        src.Insert(73, "0    0    0    0    0    0    0    0    CARD B.4.b");
        return Deck.Parse(string.Join("\r\n", src));
    }

    static readonly string[] B4 = ["B.4.A", "B.4.B"];
    static readonly string[] B5 = ["B.5.A", "B.5.B", "B.5.C"];
    const string B4A = "0\t10\t0\t0.7\t20\t0\t10\t0\t0.7\t5";
    const string B4B = "1\t2\t3\t4\t5\t6\t7\t8";
    const string B4Blank = "\t\t\t\t\t\t\t";
    const string B5A = "0.1\t0\t30\t0\t0\t0\t0";
    const string B5X = "1\t2\t3\t4\t5\t6\t7";
    const string B5Blank = "\t\t\t\t\t\t";
    const string Reject = "row 1: Joint Type needs different B.4/B.5 lines than joint 2";

    static List<string> Paste(Deck d, string[] cards, string row)
    {
        var res = Deck.ParsePaste(row + "\r\n", cards);
        Assert.Empty(res.Rejected);
        return Renumber.Paste(d, Entity.Joint, cards, 3, 2, res.Rows);
    }

    [Fact]
    public void SpinDeck_IsValid_AndJoint2IsSpin()
    {
        var d = SpinDeck();
        Assert.Empty(d.Validate());
        Assert.Single(d.Cards("B.4.B"));
        Assert.Single(d.Cards("B.5.B"));
        Assert.Single(d.Cards("B.5.C"));
    }

    // reverse case: no-spin-line row onto a spin template
    [Fact]
    public void SpinTemplate_B4RowWithoutSpinLine_IsRejected_DeckUnchanged()
    {
        var d = SpinDeck(); var before = d.Write();
        Assert.Equal([Reject], Paste(d, B4, B4A + "\t" + B4Blank));
        Assert.Equal(before, d.Write());
    }

    [Fact]
    public void SpinTemplate_B5RowWithoutSpinLines_IsRejected_DeckUnchanged()
    {
        var d = SpinDeck(); var before = d.Write();
        Assert.Equal([Reject], Paste(d, B5, B5A + "\t" + B5Blank + "\t" + B5Blank));
        Assert.Equal(before, d.Write());
    }

    // no false rejections: matching spin class is accepted and the deck stays valid
    [Fact]
    public void SpinTemplate_B4RowWithSpinLine_IsAccepted_Validates()
    {
        var d = SpinDeck();
        Assert.Empty(Paste(d, B4, B4A + "\t" + B4B));
        Assert.Equal(17, d.Cards("B.4.A").Count());
        Assert.Equal(["0 0 0 0 0 0 0 0", "1 2 3 4 5 6 7 8"], d.Cards("B.4.B").Select(l => string.Join(" ", l.Tokens)));
        Assert.Equal(2, d.Cards("B.5.B").Count());
        Assert.Empty(d.Validate());
    }

    [Fact]
    public void SpinTemplate_B5RowWithSpinLines_IsAccepted_Validates()
    {
        var d = SpinDeck();
        Assert.Empty(Paste(d, B5, B5A + "\t" + B5X + "\t" + B5X));
        Assert.Equal(2, d.Cards("B.4.B").Count());
        Assert.Equal(2, d.Cards("B.5.C").Count());
        Assert.Empty(d.Validate());
    }

    [Fact]
    public void NonSpinTemplate_B4AndB5RowsWithoutSpinLines_AreAccepted_Validate()
    {
        var d = Deck.Load(Fixture);
        Assert.Empty(Paste(d, B4, B4A + "\t" + B4Blank));
        Assert.Empty(Paste(d, B5, B5A + "\t" + B5Blank + "\t" + B5Blank));
        Assert.Equal(18, d.Cards("B.4.A").Count());
        Assert.Empty(d.Cards("B.4.B"));
        Assert.Empty(d.Cards("B.5.B"));
        Assert.Empty(d.Validate());
    }

    // Partial spin block: the solver reads B.5.B and B.5.C together per spin joint (Labeler.cs:65), and
    // Validate() is per-line only, so a half block would shift every later card read. Rejected, deck unchanged.
    [Fact]
    public void NonSpinTemplate_B5RowWithOnlyB5C_IsRejected_DeckUnchanged()
    {
        var d = Deck.Load(Fixture); var before = d.Write();
        Assert.Equal([Reject], Paste(d, B5, B5A + "\t" + B5Blank + "\t" + B5X));
        Assert.Equal(before, d.Write());
    }

    [Fact]
    public void SpinTemplate_B5RowWithOnlyB5B_IsRejected_DeckUnchanged()
    {
        var d = SpinDeck(); var before = d.Write();
        Assert.Equal([Reject], Paste(d, B5, B5A + "\t" + B5X + "\t" + B5Blank));
        Assert.Equal(before, d.Write());
    }
}
