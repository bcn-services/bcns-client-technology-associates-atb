using System.Text;
using Atb.Core.Cards;
using Atb.Core.Lin;
using Xunit;
using Xunit.Abstractions;

namespace Atb.Core.Tests;

/// HIC and CSI Definition (§2 #36): Output > HIC... enabled by A.5 NPRT(4) as ATB 3I (MainMenu.cs:4719-4722), H.12 ↔ the form.
public class HicTests(ITestOutputHelper output)
{
    static string Rel(string rel) => Path.Combine(Fixtures.RepoRoot, rel);
    const string Fixture = "app/Atb.Core.Tests/fixtures/hic/2479_2_hic.LIN";   // 2479_2 with NPRT(4)=1 + 3I's default H.12 line

    /// 3I's test is `num != 0 && num != 4`: only 0 and 4 leave HIC off.
    [Theory]
    [InlineData(0, false)]
    [InlineData(4, false)]
    [InlineData(1, true)]
    [InlineData(2, true)]
    [InlineData(3, true)]
    [InlineData(5, true)]
    [InlineData(-1, true)]
    public void Nprt4Rule(int nprt4, bool on) => Assert.Equal(on, OutputControl.EnablesHic(nprt4));

    [Fact]
    public void DeckWithNprt4OnEnables_DeckWithNprt4OffDoesNot()
    {
        var on = Deck.Load(Rel(Fixture));
        var off = Deck.Load(Rel("cases/2479/2479_2.LIN"));
        Assert.Equal("1", on.Card("A.5")!.Tokens[3]);
        Assert.Equal("0", off.Card("A.5")!.Tokens[3]);
        Assert.True(OutputControl.HicEnabled(on));
        Assert.False(OutputControl.HicEnabled(off));
        // The same deck flipped through Output Control follows the rule both ways (and keeps H.12 in step).
        Assert.Null(OutputControl.Set(on, 4, "4"));
        Assert.False(OutputControl.HicEnabled(on));
        Assert.Empty(on.Lines.Where(Hic.IsLine));
        Assert.Null(OutputControl.Set(off, 4, "3"));
        Assert.True(OutputControl.HicEnabled(off));
        Assert.Equal("0.0360000", Hic.Span(off));
    }

    static List<string> EnablingDecks()
    {
        var client = Fixtures.ClientDecks().Where(p => OutputControl.HicEnabled(Deck.Load(p))).ToList();
        return [.. client, Rel(Fixture), .. Fixtures.VendorSamples().Where(p => OutputControl.HicEnabled(Deck.Load(p)))];
    }

    /// Every deck that enables HIC (client decks — none today — plus the fixture and vendor ejection.lin): the form's
    /// model read and written back unedited changes zero bytes.
    [Fact]
    public void EveryEnablingDeckUneditedSaveChangesZeroBytes()
    {
        int clients = Fixtures.ClientDecks().Count(p => OutputControl.HicEnabled(Deck.Load(p)));
        output.WriteLine($"client decks (cases/+corpus/) enabling HIC: {clients} of {Fixtures.ClientDecks().Count()}");
        var decks = EnablingDecks();
        Assert.Contains(Rel(Fixture), decks);
        Assert.True(decks.Count >= 2, $"only {decks.Count} enabling decks");
        foreach (var p in decks)
        {
            var d = Deck.Load(p);
            Assert.Null(Hic.SetSpan(d, Hic.Span(d)));
            var rows = Hic.Rows(d);
            Assert.NotEmpty(rows);
            for (int r = 0; r < rows.Count; r++)
                for (int c = 0; c < 3; c++) Assert.Null(Hic.Set(d, r, c, Hic.Cell(d, r, c)));
            Assert.True(File.ReadAllBytes(p).SequenceEqual(Encoding.Latin1.GetBytes(d.Write())), p + ": unedited HIC save changed bytes");
        }
    }

    [Fact]
    public void FixtureReadsAs3IWouldShowIt()
    {
        var d = Deck.Load(Rel(Fixture));
        Assert.Equal("0.0360000", Hic.Span(d));
        Assert.Single(Hic.Rows(d));
        Assert.Equal(["1", "0", "0"], Enumerable.Range(0, 3).Select(c => Hic.Cell(d, 0, c)));
        Assert.Equal(["0", "1"], Hic.Choices(d));   // 2479_2 has one H.1 row, plus the 0 3I's default line holds
        Assert.Equal("H.12.A", Labeler.Label(Deck.Load(Rel(Fixture))).Last(k => k != null));
    }

    [Fact]
    public void VendorEjectionHasThreeH1RowsToChooseFrom()
    {
        var d = Deck.Load(Rel("app/Atb.Core.Tests/fixtures/vendor/ejection.lin"));
        Assert.Equal(["1", "1", "2"], Enumerable.Range(0, 3).Select(c => Hic.Cell(d, 0, c)));
        Assert.Equal(["1", "2", "3"], Hic.Choices(d));
    }

    /// Edits rewrite only the H.12 line, only the token edited.
    [Fact]
    public void EditsRewriteOnlyTheirToken()
    {
        var p = Rel(Fixture);
        var before = File.ReadAllLines(p, Encoding.Latin1);
        var d = Deck.Load(p);
        Assert.Null(Hic.SetSpan(d, "0.015"));
        Assert.Null(Hic.Set(d, 0, 1, "1"));
        var after = d.Write().Split("\r\n")[..^1];
        Assert.Equal([before.Length - 1], Enumerable.Range(0, before.Length).Where(i => before[i] != after[i]));
        Assert.Equal("1    0.015    1    1    0    Card H.12.a", after[^1]);
    }

    [Fact]
    public void RefusesNonNumbers_AndLeavesTheDeck()
    {
        var p = Rel(Fixture);
        var d = Deck.Load(p);
        Assert.NotNull(Hic.SetSpan(d, "abc"));
        Assert.NotNull(Hic.Set(d, 0, 1, "1.5"));
        Assert.True(File.ReadAllBytes(p).SequenceEqual(Encoding.Latin1.GetBytes(d.Write())));
    }

    /// 3I's writer with [H12a2] sets: every set on the one "CARD H.12" line (FileManager.cs:2240-2244, OneDimArrayOutput).
    [Fact]
    public void ThreeIOneLineSetsAreRows()
    {
        var d = Deck.Parse("2    0.036    1    1    0    2    2    1    CARD H.12\r\n");
        Assert.Equal(2, Hic.Rows(d).Count);
        Assert.Equal(["2", "2", "1"], Enumerable.Range(0, 3).Select(c => Hic.Cell(d, 1, c)));
        Assert.Equal("0.036", Hic.Span(d));
    }
}
