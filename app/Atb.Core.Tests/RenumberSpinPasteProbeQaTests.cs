using Atb.Core.Cards;
using Atb.Core.Lin;
using Xunit;

namespace Atb.Core.Tests;

/// QA probes for the B.4/B.5 paste row-shape check (Renumber.Paste, gi > 0): wrong-direction and half blocks,
/// multi-row pastes where only the bad row is skipped, and the B.3 screen (gi == 0) untouched by the check.
public class RenumberSpinPasteProbeQaTests
{
    static string Fixture => Path.Combine(Fixtures.RepoRoot, "cases", "2479", "2479_2.LIN");

    static Deck SpinDeck()
    {
        var src = File.ReadAllText(Fixture).Split("\r\n").ToList();
        src[41] = "\"NULL\"    0    4    0    0    0    0    0    0    0    0    0    CARD B.3.a";
        src.Insert(89, "0    0    0    0    0    0    0    CARD B.5.c");
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

    static List<string> Paste(Deck d, string[] cards, params string[] rows)
    {
        var res = Deck.ParsePaste(string.Join("\r\n", rows) + "\r\n", cards);
        Assert.Empty(res.Rejected);
        return Renumber.Paste(d, Entity.Joint, cards, 3, 2, res.Rows);
    }

    [Fact]
    public void NonSpinTemplate_B4RowWithSpinLine_IsRejected_DeckUnchanged()
    {
        var d = Deck.Load(Fixture); var before = d.Write();
        Assert.Equal(["row 1: Joint Type needs different B.4/B.5 lines than joint 2"], Paste(d, B4, B4A + "\t" + B4B));
        Assert.Equal(before, d.Write());
    }

    [Fact]
    public void NonSpinTemplate_B5RowWithOnlyB5B_IsRejected_DeckUnchanged()
    {
        var d = Deck.Load(Fixture); var before = d.Write();
        Assert.Equal(["row 1: Joint Type needs different B.4/B.5 lines than joint 2"], Paste(d, B5, B5A + "\t" + B5X + "\t" + B5Blank));
        Assert.Equal(before, d.Write());
    }

    [Fact]
    public void SpinTemplate_B5RowWithOnlyB5C_IsRejected_DeckUnchanged()
    {
        var d = SpinDeck(); var before = d.Write();
        Assert.Equal(["row 1: Joint Type needs different B.4/B.5 lines than joint 2"], Paste(d, B5, B5A + "\t" + B5Blank + "\t" + B5X));
        Assert.Equal(before, d.Write());
    }

    [Fact]
    public void SpinTemplate_MixedRows_OnlyHalfBlockRowSkipped_Validates()
    {
        var d = SpinDeck();
        Assert.Equal(["row 2: Joint Type needs different B.4/B.5 lines than joint 2"],
            Paste(d, B5, B5A + "\t" + B5X + "\t" + B5X, B5A + "\t" + B5X + "\t" + B5Blank, B5A + "\t" + B5X + "\t" + B5X));
        Assert.Equal(3, d.Cards("B.5.B").Count());
        Assert.Equal(3, d.Cards("B.5.C").Count());
        Assert.Equal(3, d.Cards("B.4.B").Count());
        Assert.Empty(d.Validate());
    }

    [Fact]
    public void NonSpinTemplate_MultipleValidRows_AllAccepted_Validates()
    {
        var d = Deck.Load(Fixture);
        int b4 = d.Cards("B.4.A").Count();
        Assert.Empty(Paste(d, B4, B4A + "\t" + B4Blank, B4A + "\t" + B4Blank));
        Assert.Equal(b4 + 2, d.Cards("B.4.A").Count());
        Assert.Empty(d.Cards("B.4.B"));
        Assert.Empty(d.Validate());
    }
}
