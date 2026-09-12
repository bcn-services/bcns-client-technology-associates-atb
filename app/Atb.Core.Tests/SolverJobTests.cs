using Atb.Core.Solver;
using Xunit;

namespace Atb.Core.Tests;

public sealed class SolverJobTests : IDisposable
{
    readonly string root = Directory.CreateTempSubdirectory("atbjob").FullName;
    string Work => Path.Combine(root, "work");
    string DeckDir => Path.Combine(root, "deck");

    public SolverJobTests() { Directory.CreateDirectory(Work); Directory.CreateDirectory(DeckDir); }
    public void Dispose() { try { Directory.Delete(root, true); } catch { } }

    static Dictionary<string, string> Snapshot(string dir) =>
        Directory.GetFiles(dir).ToDictionary(f => Path.GetFileName(f), f => File.ReadAllText(f));

    [Fact]
    public void Answers_RunLin_PinnedToSolverRunAt691575f()
    {
        // SolverRun.cs @691575f line 124: new[] { "y", "", "l", o.InputBase, o.OutputBase }
        Assert.Equal(new[] { "y", "", "l", "2479_2", "2479_2" }, SolverJob.Answers(SolverMode.RunLin, "2479_2", "2479_2"));
        Assert.Equal(new[] { "y", "", "l", "in", "out" }, SolverJob.Answers(SolverMode.RunLin, "in", "out"));
    }

    [Fact]
    public void Answers_ConvertAin_FollowsSolverPrompts()
    {
        // src/input_files.for: terms y, default dir, type "a", create .LIN "y", input name, output name
        Assert.Equal(new[] { "y", "", "a", "y", "Sled", "Sled" }, SolverJob.Answers(SolverMode.ConvertAin, "Sled", "Sled"));
    }

    [Fact]
    public void Finish_CopiesOutputsNextToDeck_AndRemovesWorkDir()
    {
        var deck = Path.Combine(DeckDir, "2479_2.LIN");
        File.WriteAllText(deck, "original deck");
        File.WriteAllText(Path.Combine(Work, "2479_2.lin"), "work copy");   // input copy: not an output
        File.WriteAllText(Path.Combine(Work, "2479_2.aou"), "aou");
        File.WriteAllText(Path.Combine(Work, "2479_2.sa1"), "sa1");
        File.WriteAllText(Path.Combine(Work, "2479_2.t21"), "t21");
        File.WriteAllText(Path.Combine(Work, "atb_parms.mem"), "parms");

        var copied = SolverJob.Finish(Work, "2479_2", deck, SolverMode.RunLin, cancelled: false);

        Assert.False(Directory.Exists(Work));
        Assert.Equal(3, copied.Count);
        var after = Snapshot(DeckDir);
        Assert.Equal(new[] { "2479_2.LIN", "2479_2.aou", "2479_2.sa1", "2479_2.t21" }, after.Keys.Order(StringComparer.Ordinal));
        Assert.Equal("original deck", after["2479_2.LIN"]);
        Assert.Equal("aou", after["2479_2.aou"]);
        Assert.Equal("sa1", after["2479_2.sa1"]);
        Assert.Equal("t21", after["2479_2.t21"]);
    }

    [Fact]
    public void Finish_Cancelled_LeavesNothingBehind()
    {
        var deck = Path.Combine(DeckDir, "2479_2.LIN");
        File.WriteAllText(deck, "original deck");
        File.WriteAllText(Path.Combine(DeckDir, "2479_2.aou"), "previous run");
        var before = Snapshot(DeckDir);
        File.WriteAllText(Path.Combine(Work, "2479_2.lin"), "work copy");
        File.WriteAllText(Path.Combine(Work, "2479_2.aou"), "partial");      // mid-run: partial outputs
        File.WriteAllText(Path.Combine(Work, "2479_2.sa1"), "partial");

        var copied = SolverJob.Finish(Work, "2479_2", deck, SolverMode.RunLin, cancelled: true);

        Assert.Empty(copied);
        Assert.False(Directory.Exists(Work));
        Assert.Equal(before, Snapshot(DeckDir));
    }

    [Fact]
    public void Finish_Convert_CopiesGeneratedLin_NotTheAinCopy()
    {
        var ain = Path.Combine(DeckDir, "Sled.ain");
        File.WriteAllText(ain, "original ain");
        File.WriteAllText(Path.Combine(Work, "Sled.ain"), "work copy");
        File.WriteAllText(Path.Combine(Work, "Sled.lin"), "converted");
        File.WriteAllText(Path.Combine(Work, "Sled.aou"), "aou");

        SolverJob.Finish(Work, "Sled", ain, SolverMode.ConvertAin, cancelled: false);

        var after = Snapshot(DeckDir);
        Assert.Equal("original ain", after["Sled.ain"]);
        Assert.Equal("converted", after["Sled.lin"]);
        Assert.Equal("aou", after["Sled.aou"]);
        Assert.False(Directory.Exists(Work));
    }

    [Fact]
    public void Finish_MissingWorkDir_IsNoOp()
    {
        Directory.Delete(Work);
        Assert.Empty(SolverJob.Finish(Work, "x", Path.Combine(DeckDir, "x.lin"), SolverMode.RunLin, cancelled: false));
    }
}
