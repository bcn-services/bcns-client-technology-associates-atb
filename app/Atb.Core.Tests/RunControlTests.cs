using System.Text;
using Atb.Core.Cards;
using Atb.Core.Lin;
using Xunit;

namespace Atb.Core.Tests;

/// Run Control (§2 #4): 3I RunControl.cs's 16 boxes ↔ A.1.A / A.1.B / A.1.C / A.3 / A.4 tokens.
public class RunControlTests
{
    static string Case(string rel) => Path.Combine(Fixtures.RepoRoot, rel);

    /// The mapping as written-out literals: 2479_2.LIN's A cards, box by box in 3I's Textbox1..16 order.
    [Fact]
    public void BoxesReadTheirTokens_2479()
    {
        Assert.Equal(
            ["8/18/20", "ATB Gas Range Fall", "5 ft 2 in tall 180 lb adult female plaintiff", "IN.", "LB.", "SEC.",
             "4", "2000", "0.002", "0", "0", "386.088", "0.0005", "0.001", "6.25E-05", "386.088"],
            RunControl.Read(Deck.Load(Case("cases/2479/2479_2.LIN"))));
        Assert.Equal(16, RunControl.Fields.Length);
        Assert.Equal(["Date", "Comment1", "Comment2", "Unit of Length", "Unit of Force", "Unit of Time", "Num of Iteration", "Num of Output",
                      "Output Interval", "Gravity X", "Gravity Y", "Gravity Z", "Initial Size", "Maximum Size", "Minimum Size", "G"],
                     RunControl.Fields.Select(f => f.Name));
    }

    /// Every cases/ and corpus/ deck: the form's 16 boxes read, then every box written back unedited, changes zero bytes
    /// of the file. (The vendor samples label A.1b / A.1c, which the Labeler fixes; the form refuses them until then.)
    [Fact]
    public void EveryDeckOpensAndUneditedSaveChangesZeroBytes()
    {
        int n = 0;
        foreach (var p in Fixtures.ClientDecks())
        {
            var d = Deck.Load(p);
            var boxes = RunControl.Read(d);
            Assert.Equal(16, boxes.Length);
            for (int i = 0; i < boxes.Length; i++) Assert.Null(RunControl.Set(d, i, boxes[i]));
            Assert.True(File.ReadAllBytes(p).SequenceEqual(Encoding.Latin1.GetBytes(d.Write())), p + ": unedited Run Control save changed bytes");
            n++;
        }
        Assert.True(n >= 12, $"only {n} decks");
    }

    /// One box edited: exactly one deck line differs, and within it exactly that token.
    [Theory]
    [InlineData(7, "2500", 4, "4    2500    0.002    0.0005    0.001    6.25E-05    CARD A.4")]
    [InlineData(11, "32.2", 3, "\"IN.\"    \"LB.\"    \"SEC.\"    0    0    32.2    386.088    CARD A.3")]
    [InlineData(1, "Run Control edit", 1, "\"Run Control edit\"    CARD A.1.b")]
    public void OneBoxEditRewritesOnlyItsToken(int box, string text, int line, string want)
    {
        var p = Case("cases/2479/2479_2.LIN");
        var before = File.ReadAllLines(p, Encoding.Latin1);
        var d = Deck.Load(p);
        Assert.Null(RunControl.Set(d, box, text));
        var after = d.Write().Split("\r\n")[..^1];
        Assert.Equal(before.Length, after.Length);
        Assert.Equal([line], Enumerable.Range(0, before.Length).Where(i => before[i] != after[i]));
        Assert.Equal(want, after[line]);
    }

    [Fact]
    public void NumberBoxesRefuseText_AndLeaveTheDeck()
    {
        var p = Case("cases/2479/2479_2.LIN");
        var d = Deck.Load(p);
        Assert.NotNull(RunControl.Set(d, 9, "abc"));    // Gravity X
        Assert.NotNull(RunControl.Set(d, 6, "4.5"));    // Num of Iteration is whole
        Assert.True(File.ReadAllBytes(p).SequenceEqual(Encoding.Latin1.GetBytes(d.Write())));
    }

    [Fact]
    public void DefaultsAre3IsBtnDefault()
    {
        Assert.Equal(["09-28-2026", "", "", "IN.", "LB.", "SEC.", "4", "0", "0.002", "0", "0", "386.088", "0.0005", "0.001", "0.0000625", "0"],
                     RunControl.Defaults(new DateTime(2026, 9, 28)));
    }
}
