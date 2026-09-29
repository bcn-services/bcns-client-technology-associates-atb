using System.Text;
using Atb.Core.Cards;
using Atb.Core.Lin;
using Xunit;

namespace Atb.Core.Tests;

/// General / Diagnostic Output Control Parameters (§2 #5): 3I's A5Defination rows ↔ A.5 NPRT tokens.
public class OutputControlTests
{
    static string Case(string rel) => Path.Combine(Fixtures.RepoRoot, rel);

    /// `mdb-export "ATB3I/ATB3iData.mdb" A5Defination`, pasted verbatim (export order), header NPRT,Control Parameter,Value,Category.
    const string Export = """
        1,"Unit 1 (.SA1) Output Step",0,1
        2,"Sub ELTIME Table Output",0,2
        4,"Unit 8 (HIC) Output",0,1
        5,"Not Used",0,0
        6,"Not Used",0,0
        7,"Not Used",0,0
        8,"IJK, RHS and C Array Output",0,2
        9,"Sub PRINT Output",0,2
        10,"Diagnostic Output in Sub IMPULS",0,2
        11,"U2 and V1 Array Output",0,2
        13,"Not Used",0,0
        14,"Wind Force Diagnostic Output",0,2
        15,"Diagnostic Output in Sub BELTG",0,2
        16,"Diagnostic Output in Sub HBELT",0,2
        17,"Diagnostic Output in Sub EDEPTH",0,2
        18,"Time History Output",0,1
        19,"Time History Headers",0,1
        20,"SEGLP and SEGLV Output",0,2
        21,"Diagnostic Output in Sub AIRBAG",0,2
        22,"Diagnostic Output in Sub AIRBG1",0,2
        23,"HT and HB Array Output",0,2
        24,"Roll-Slide Test Output",0,2
        25,"Convergence Test Data Output",0,2
        29,"Not Used",0,0
        30,"HIC Data Output Frequency",0,1
        31,"Not Used",0,0
        32,"Not Used",0,0
        34,"Not Used",0,0
        3,"Unit 6 (.AOU) Output Step",0,1
        12,"Diagnostic Output in Sub VISPR",0,2
        27,"Internediate Results Output",0,2
        28,"Diagnostic Output in Sub HPTURB",0,2
        35,"Select VIEW Program Version",0,1
        26,"Time History Output Frequency",0,1
        33,"Used by ATB3i for Weight Balancing",0,0
        36,"Not Used and Always Is 1",1,0
        """;

    static string Csv(OutputControl.Row r) => $"{r.Nprt},\"{r.Name}\",{r.Value},{r.Category}";

    [Fact]
    public void DefinitionIsA5DefinationExactly()
    {
        var rows = Export.Split('\n').Select(l => l.TrimEnd('\r')).ToList();
        Assert.Equal(36, rows.Count);
        Assert.Equal(rows.OrderBy(l => int.Parse(l.Split(',')[0])), OutputControl.Definition.Select(Csv));
    }

    /// 3I's two forms: WHERE Category=n ORDER BY NPRT ASC.
    [Fact]
    public void GeneralAndDiagnosticAreCategories1And2InNprtOrder()
    {
        Assert.Equal([1, 3, 4, 18, 19, 26, 30, 35], OutputControl.Rows(OutputControl.General).Select(r => r.Nprt));
        Assert.Equal([2, 8, 9, 10, 11, 12, 14, 15, 16, 17, 20, 21, 22, 23, 24, 25, 27, 28], OutputControl.Rows(OutputControl.Diagnostic).Select(r => r.Nprt));
    }

    /// Every cases/ and corpus/ deck: every NPRT read and written back unedited changes zero bytes.
    [Fact]
    public void EveryDeckUneditedSaveChangesZeroBytes()
    {
        int n = 0;
        foreach (var p in Fixtures.ClientDecks())
        {
            var d = Deck.Load(p);
            Assert.Equal(36, OutputControl.Line(d).Count);
            for (int k = 1; k <= 36; k++) Assert.Null(OutputControl.Set(d, k, OutputControl.Value(d, k)));
            Assert.True(File.ReadAllBytes(p).SequenceEqual(Encoding.Latin1.GetBytes(d.Write())), p + ": unedited Output Control save changed bytes");
            n++;
        }
        Assert.True(n >= 12, $"only {n} decks");
    }

    /// One flag edited on 2479_2 (A.5 is line 6): exactly that line differs, and within it exactly token NPRT-1.
    [Theory]
    [InlineData(18, "1")]    // General: Time History Output
    [InlineData(19, "0")]    // General: Time History Headers
    [InlineData(20, "1")]    // Diagnostic: SEGLP and SEGLV Output
    [InlineData(1, "10")]
    public void OneFlagEditRewritesOnlyItsToken(int nprt, string text)
    {
        var p = Case("cases/2479/2479_2.LIN");
        var before = File.ReadAllLines(p, Encoding.Latin1);
        var d = Deck.Load(p);
        Assert.Null(OutputControl.Set(d, nprt, text));
        var after = d.Write().Split("\r\n")[..^1];
        Assert.Equal(before.Length, after.Length);
        Assert.Equal([5], Enumerable.Range(0, before.Length).Where(i => before[i] != after[i]));
        string[] tb = before[5].Split("    "), ta = after[5].Split("    ");
        Assert.Equal(tb.Length, ta.Length);
        Assert.Equal([nprt - 1], Enumerable.Range(0, tb.Length).Where(i => tb[i] != ta[i]));
        Assert.Equal(text, ta[nprt - 1]);
    }

    [Fact]
    public void ValuesRefuseNonIntegers_AndLeaveTheDeck()
    {
        var p = Case("cases/2479/2479_2.LIN");
        var d = Deck.Load(p);
        Assert.NotNull(OutputControl.Set(d, 18, "abc"));
        Assert.NotNull(OutputControl.Set(d, 18, "1.5"));
        Assert.True(File.ReadAllBytes(p).SequenceEqual(Encoding.Latin1.GetBytes(d.Write())));
    }

    /// OK with NPRT(4) not 0/4 adds 3I's default H.12.a (FileManager.cs:2247) at the end; OK back at 0 removes it: the file is as it was.
    [Fact]
    public void Nprt4KeepsH12InStep()
    {
        var p = Case("cases/2479/2479_2.LIN");
        var orig = File.ReadAllText(p, Encoding.Latin1);
        var d = Deck.Load(p);
        Assert.Null(OutputControl.Set(d, 4, "1"));
        Assert.Empty(d.Cards("H.12.A"));   // an edit alone leaves H.12; OK decides
        OutputControl.KeepHicInStep(d);
        Assert.Equal("1    0.0360000    1    0    0    CARD H.12.a", d.Write().Split("\r\n")[^2]);
        Assert.Null(OutputControl.Set(d, 4, "2"));
        OutputControl.KeepHicInStep(d);
        Assert.Single(d.Cards("H.12.A"));
        Assert.Null(OutputControl.Set(d, 4, "4"));
        OutputControl.KeepHicInStep(d);
        Assert.Empty(d.Cards("H.12.A"));
        Assert.Null(OutputControl.Set(d, 4, "0"));
        OutputControl.KeepHicInStep(d);
        Assert.Equal(orig, d.Write());
    }

    /// NPRT(4) 1 → 4 → 1 inside one dialog, then OK: 3I decides once from the final value, so the deck's H.12 survives.
    [Fact]
    public void Nprt4OffAndOnBeforeOkKeepsH12()
    {
        var p = Case("app/Atb.Core.Tests/fixtures/hic/2479_2_hic.LIN");
        var orig = File.ReadAllText(p, Encoding.Latin1);
        var d = Deck.Load(p);
        Assert.Null(OutputControl.Set(d, 4, "4"));
        Assert.Null(OutputControl.Set(d, 4, "1"));
        OutputControl.KeepHicInStep(d);
        Assert.Equal(orig, d.Write());
    }
}
