using System.Globalization;
using System.Text.RegularExpressions;
using Atb.Core.Lin;
using FlaUI.Core.AutomationElements;
using FlaUI.Core.Definitions;
using FlaUI.Core.WindowsAPI;
using Xunit;

namespace Atb.App.UiTests;

/// The everyday loop through the real UI: grid edit + Save, Run, insert a segment + Run, the .sa1 viewer.
/// Decks are temp copies under $WORK; the gates that compare files (tokendiff.py, cross_gate.py) run in the workflow.
public class Scenarios
{
    const string SegScreen = "Segment Definition [B.2.A, B.2.B]", Weight0 = "Weight Row 0";
    static readonly CultureInfo Inv = CultureInfo.InvariantCulture;

    public static IEnumerable<object[]> Decks() =>
        Directory.GetFiles(Path.Combine(Robot.Repo, "cases"), "*.LIN", SearchOption.AllDirectories).Order()
            .Select(p => new object[] { Path.GetRelativePath(Robot.Repo, p) });

    public static IEnumerable<object[]> Sa1s() =>
        Directory.GetFiles(Path.Combine(Robot.Repo, "cases"), "*.sa1", SearchOption.AllDirectories).Order()
            .Append(Path.Combine(Robot.Repo, "example", "sledout.sa1"))
            .Select(p => new object[] { Path.GetRelativePath(Robot.Repo, p) });

    /// Segment 1's weight: typed into the grid, saved with Ctrl+S. Appends "orig \t saved \t old \t new" to edits.tsv.
    [Theory, MemberData(nameof(Decks))]
    public void GridEditSave(string rel)
    {
        var b = Path.GetFileNameWithoutExtension(rel);
        var copy = Robot.TempCopy(rel, Path.Combine("edit", b));
        using var r = new Robot("edit-" + b, copy);
        r.Shot("opened");
        r.SelectScreen(SegScreen);
        r.Shot("segment-screen");
        var cell = r.Cell(Weight0);
        var old = Robot.Value(cell);
        var nv = (double.Parse(old.Replace('D', 'E').Replace('d', 'e'), NumberStyles.Float, Inv) + 1.25).ToString("0.0###", Inv);
        r.Click(cell);
        FlaUI.Core.Input.Keyboard.Type(nv);          // EditOnKeystroke: the first key starts the edit, replacing the text
        Robot.Press(VirtualKeyShort.RETURN);
        Assert.Equal(nv, Robot.Value(r.Cell(Weight0)));
        r.Shot("edited");
        r.SaveDeck(copy);
        File.AppendAllText(Path.Combine(Robot.Out, "edits.tsv"), $"{Path.Combine(Robot.Repo, rel)}\t{copy}\t{old}\t{nv}\n");
        Assert.Empty(r.Unexpected());
    }

    /// Run on 2479_2 through the app; outputs land as $WORK/2479_2/2479_2_new.* (the layout compare.py and cmp.py read).
    [Fact]
    public void Run2479()
    {
        var copy = Robot.TempCopy("cases/2479/2479_2.LIN", "appin");
        var outDir = Path.Combine(Robot.Work, "2479_2"); Directory.CreateDirectory(outDir);
        foreach (var f in Directory.GetFiles(outDir, "2479_2_new.*")) File.Delete(f);
        using var r = new Robot("run-2479_2", copy);
        r.Shot("opened");
        var took = r.RunDeck(Path.Combine(outDir, "2479_2_new"));
        foreach (var ext in new[] { ".aou", ".sa1", ".t21" })
            Assert.True(new FileInfo(Path.Combine(outDir, "2479_2_new" + ext)) is { Exists: true, Length: > 0 }, "missing 2479_2_new" + ext);
        // rc 0: the app only reports success for solver exit 0 or 1 (SolverRun); cmp.py/compare.py ignore the field.
        File.WriteAllText(Path.Combine(Robot.Work, "cases.txt"), $"2479_2 2479 2479_2 2479_2 0 {(int)took.TotalSeconds}\n");
        Assert.Empty(r.Unexpected());
    }

    /// Edit > Add row on segment 1 (Renumber inserts a copy as segment 2), Save, Run to completion.
    [Fact]
    public void InsertSegmentRun()
    {
        var copy = Robot.TempCopy("cases/2479/2479_2.LIN", "ins");
        int before = Deck.Load(copy).SegmentCount;
        using var r = new Robot("insert-segment-2479_2", copy);
        r.SelectScreen(SegScreen);
        r.Click(r.Cell(Weight0));
        r.Shot("segment-1-selected");
        Robot.Press(VirtualKeyShort.CONTROL, VirtualKeyShort.INSERT);
        r.Cell($"Weight Row {before}");                 // the grid grew by one row
        r.Shot("segment-inserted");
        r.SaveDeck(copy);
        Assert.Equal(before + 1, Deck.Load(copy).SegmentCount);
        var outDir = Path.Combine(Robot.Work, "ins", "out"); Directory.CreateDirectory(outDir);
        r.RunDeck(Path.Combine(outDir, "2479_2_ins"));
        foreach (var ext in new[] { ".aou", ".t21" })
            Assert.True(new FileInfo(Path.Combine(outDir, "2479_2_ins" + ext)) is { Exists: true, Length: > 0 }, "missing 2479_2_ins" + ext);
        Assert.Empty(r.Unexpected());
    }

    const string Anim = "ATB animation";

    /// View > Animation: open, play, step, frames at 0/50/100%; no window other than main + viewer at any check.
    [Theory, MemberData(nameof(Sa1s))]
    public void ViewerPlayStep(string rel)
    {
        var copy = Robot.TempCopy(rel, "view");
        using var r = new Robot("view-" + Path.GetFileNameWithoutExtension(rel));
        var anim = OpenSa1(r, copy) ?? throw new Xunit.Sdk.XunitException("viewer did not open: " + string.Join("; ", r.Unexpected(Anim)));
        Assert.Empty(r.Unexpected(Anim));
        var (i, n) = Frame(anim);
        Assert.Equal(1, i);
        r.Shot("frame-0pct");

        r.Click(r.Button(anim, "Play"));
        var seen = new HashSet<int>();
        for (int k = 0; k < 8; k++) { Thread.Sleep(250); seen.Add(Frame(anim).i); }
        r.Shot("playing");
        Assert.NotNull(anim.FindFirstDescendant(r.A.ConditionFactory.ByControlType(ControlType.Button).And(r.A.ConditionFactory.ByName("Pause"))));
        if (n > 1) Assert.True(seen.Count > 1, $"frame did not advance while playing: {string.Join(",", seen)}");
        r.Click(r.Button(anim, "Pause"));

        Seek(r, anim, 0, n);
        r.Click(r.Button(anim, "▶"));
        Assert.Equal(Math.Min(2, n), Frame(anim).i);
        r.Shot("step-forward");
        r.Click(r.Button(anim, "◀"));
        Assert.Equal(1, Frame(anim).i);

        Seek(r, anim, (n - 1) / 2, n); r.Shot("frame-50pct");
        Seek(r, anim, n - 1, n); r.Shot("frame-100pct");
        Assert.Empty(r.Unexpected(Anim));
    }

    /// Positive control for the "no error dialog" check: a truncated .sa1 must trip it.
    [Fact]
    public void ViewerErrorDetector_TripsOnTruncatedSa1()
    {
        var dir = Path.Combine(Robot.Work, "view"); Directory.CreateDirectory(dir);
        var bad = Path.Combine(dir, "truncated.sa1");
        File.WriteAllBytes(bad, File.ReadAllBytes(Path.Combine(Robot.Repo, "cases/2479/2479_2.sa1"))[..2000]);
        using var r = new Robot("view-truncated-control");
        var anim = OpenSa1(r, bad);
        r.Shot("error-dialog");
        Assert.Null(anim);
        Assert.Contains(r.Unexpected(Anim), w => w.StartsWith("Cannot open .sa1", StringComparison.Ordinal));
    }

    /// The viewer window, or null once any other window (an error box) is up instead.
    static AutomationElement? OpenSa1(Robot r, string path)
    {
        r.Menu("View", "Animation (.sa1)...");
        r.FileDialog("Open", path);
        var got = Robot.Until(() => (object?)r.Windows().FirstOrDefault(w => w.Name.StartsWith(Anim, StringComparison.Ordinal))
                                    ?? (r.Unexpected(Anim).Count > 0 ? "error" : null), 30, "viewer window or an error");
        r.Log("viewer: " + (got as AutomationElement)?.Name + " unexpected: " + string.Join("; ", r.Unexpected(Anim)));
        return got as AutomationElement;
    }

    static readonly Regex FrameRx = new(@"frame (\d+)/(\d+)");
    static (int i, int n) Frame(AutomationElement anim)
    {
        var t = anim.FindAllDescendants().Select(e => e.Name).First(s => s.StartsWith("t = ", StringComparison.Ordinal));
        var m = FrameRx.Match(t);
        return (int.Parse(m.Groups[1].Value), int.Parse(m.Groups[2].Value));
    }

    /// Put the frame slider on index k with the keyboard (TrackBar raises Scroll only for user input).
    static void Seek(Robot r, AutomationElement anim, int k, int n)
    {
        var sliders = anim.FindAllDescendants(r.A.ConditionFactory.ByControlType(ControlType.Slider));
        var s = Assert.Single(sliders);
        s.Focus();
        if (k == 0) Robot.Press(VirtualKeyShort.HOME);
        else if (k == n - 1) Robot.Press(VirtualKeyShort.END);
        else if (s.Patterns.RangeValue.PatternOrDefault is { } rv) { rv.SetValue(k - 1); Robot.Press(VirtualKeyShort.RIGHT); }
        else { Robot.Press(VirtualKeyShort.HOME); for (int j = 0; j < k; j++) Robot.Press(VirtualKeyShort.RIGHT); }
        Robot.UntilTrue(() => Frame(anim).i == k + 1, 10, $"frame {k + 1}/{n}");
    }
}
