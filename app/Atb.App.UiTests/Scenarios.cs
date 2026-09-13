using System.Globalization;
using System.Text.RegularExpressions;
using Atb.Core.Cards;
using Atb.Core.Lin;
using Atb.Core.Sa1;
using Atb.Core.Solver;
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

    /// Insert before segment 3 (the lane's Renumber case): Add row on segment 2 puts a copy at 3, then Add row on
    /// joint 1 puts its copy at joint 2. ATB hangs segment j+1 on joint j (input_linear.for reads a G.2 free-body card
    /// for every segment whose JNT(I-1) has no proximal segment), so a segment added without a joint leaves the deck
    /// one G.2 card short and the solver misreads G.3.a (STOP 24). Save, Run to completion.
    [Fact]
    public void InsertSegmentRun()
    {
        var copy = Robot.TempCopy("cases/2479/2479_2.LIN", "ins");
        var d0 = Deck.Load(copy);
        int segs = d0.SegmentCount, joints = d0.JointCount;
        using var r = new Robot("insert-segment-2479_2", copy);
        r.SelectScreen(SegScreen);
        r.Click(r.Cell("Weight Row 1"));
        r.Shot("segment-2-selected");
        Robot.Press(VirtualKeyShort.CONTROL, VirtualKeyShort.INSERT);
        r.Cell($"Weight Row {segs}");                   // the grid grew by one row
        r.Shot("segment-inserted");
        r.SelectScreen("Joint Definition [B.3.A, B.3.B, B.3.C]");
        r.Click(r.Cell("Name Row 0"));
        r.Shot("joint-1-selected");
        Robot.Press(VirtualKeyShort.CONTROL, VirtualKeyShort.INSERT);
        r.Cell($"Name Row {joints}");
        r.Shot("joint-inserted");
        r.SaveDeck(copy);
        var d1 = Deck.Load(copy);
        Assert.Equal((segs + 1, joints + 1), (d1.SegmentCount, d1.JointCount));
        var outDir = Path.Combine(Robot.Work, "ins", "out"); Directory.CreateDirectory(outDir);
        r.RunDeck(Path.Combine(outDir, "2479_2_ins"));
        foreach (var ext in new[] { ".aou", ".t21" })
            Assert.True(new FileInfo(Path.Combine(outDir, "2479_2_ins" + ext)) is { Exists: true, Length: > 0 }, "missing 2479_2_ins" + ext);
        Assert.Empty(r.Unexpected());
    }

    /// File > New, Tools > GEBOD (Adult Human Male, weight and height at the 50th percentile, English, forearm and hand
    /// combined), Add as a new body, Save As, Run to completion. New's deck keeps ATB 3I's NSTEPS 0, so the solver ends
    /// normally (STOP 1) after writing the .aou and no .sa1 (no viewer step); "completed" = the app reported success
    /// and the .aou carries the solver's closing timing block (SolverJob.AouEndedNormally).
    [Fact]
    public void NewGebodSaveRun()
    {
        var dir = Path.Combine(Robot.Work, "gebod-new");
        if (Directory.Exists(dir)) Directory.Delete(dir, true);
        Directory.CreateDirectory(Path.Combine(dir, "out"));
        var deck = Path.Combine(dir, "gebod50m.lin");
        using var r = new Robot("new-gebod-run");
        r.Shot("launched");
        r.Menu("File", "New");
        r.Shot("new-deck");
        r.Menu("Tools", "GEBOD...");
        var g = r.WaitDialog("GEBOD V.2");
        r.Shot("gebod-form");
        Assert.Equal("Add a new body after the last", Robot.ComboText(r.Named(g, ControlType.ComboBox, "Place the GEBOD body")));
        r.Choose(g, "Subject Type", "Adult Human Male");
        r.Choose(g, "Supplied Parameter", "3) All the Above");       // resets the unit rows: pick it before them
        r.Choose(g, "Units for Weight", "Percentile");
        r.Type(g, "Weight", "50");
        r.Choose(g, "Units for Height", "Percentile");
        r.Type(g, "Height", "50");
        r.Choose(g, "Units for Output Data Set", "English");
        r.Choose(g, "Lower Arm Segmentation", "Forearm and Hand Combined");
        r.Shot("gebod-filled");
        r.Click(r.Button(g, "Run GEBOD"));
        // Done = the status bar shows the merged deck's segments (ShowDeck), or a "GEBOD" error box is up (reported below).
        var segs = new Regex(@"\b[1-9]\d* segments");
        Robot.UntilTrue(() => r.Dialog("GEBOD") != null
            || (r.Dialog("GEBOD V.2") == null && !r.Windows().Any(w => w.Name.StartsWith("GEBOD: ", StringComparison.Ordinal))
                && r.Main.FindAllDescendants(r.A.ConditionFactory.ByControlType(ControlType.Text)).Any(e => segs.IsMatch(e.Name))), 120, "GEBOD run and merge");
        r.Shot("gebod-merged");
        Assert.Empty(r.Unexpected());               // a "GEBOD" error box (exe failed, merge failed) lands here
        r.SelectScreen(SegScreen);
        r.Cell("Weight Row 0");                     // the merged body's segments are in the grid
        r.Shot("segment-screen");

        r.SaveDeck(deck, saveAs: true);
        var d = Deck.Load(deck);
        // Same request as GebodProbe / fixtures/gebod-50m.ain (Gebodv.exe output for it), merged as the app merges.
        var want = GebodMerge.Merge(GebodMerge.NewDeck(), File.ReadAllText(Path.Combine(Robot.Repo, "app/Atb.Core.Tests/fixtures/gebod-50m.ain")), new(GebodMode.Add), _ => true);
        Assert.Equal((want.SegmentCount, want.JointCount, 1), (d.SegmentCount, d.JointCount, GebodMerge.BodyStarts(d).Count));
        Assert.Empty(d.Validate());

        var dest = Path.Combine(dir, "out", "gebod50m");
        r.RunDeck(dest);
        Assert.Empty(r.Unexpected());
        var aou = dest + ".aou";
        Assert.True(new FileInfo(aou) is { Exists: true, Length: > 0 }, "missing " + aou);
        var text = File.ReadAllText(aou);
        Assert.True(SolverJob.AouEndedNormally(text), "solver did not finish normally; .aou tail:\n" + string.Join("\n", text.Split('\n').TakeLast(15)));
        r.Log($"gebod run outputs: {string.Join(", ", Directory.GetFiles(Path.Combine(dir, "out")).Select(Path.GetFileName))}");
        r.Shot("run-completed");
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

        // "View all" frames frame 1 only, as ATB 3I (viewAll once at scene load); a travelling body leaves it. Ride the
        // camera on the entry that moves furthest, picked by its name in the Camera list.
        if (Mover(Sa1File.Load(copy)) is { } mover) { r.Choose(anim, "Camera", mover); r.Shot("camera-follow"); }
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

    /// Camera-list name (as AnimationForm lists them) of the entry with the largest first→last frame displacement,
    /// among entries whose name is unique and non-empty (so a click by name selects that entry). Null for &lt; 2 frames.
    static string? Mover(Sa1File s)
    {
        if (s.Frames.Count < 2) return null;
        var names = Enumerable.Range(0, s.NGnd).Select(i => i < s.Segments.Count ? s.Segments[i].Name.Trim() : $"Entry {i + 1}").ToList();
        return Enumerable.Range(0, s.NGnd)
            .Where(i => names[i].Length > 0 && names.Count(x => x == names[i]) == 1 && names[i] != "View all (fixed)")
            .OrderByDescending(i => System.Numerics.Vector3.Distance(s.Frames[0].Position(i), s.Frames[^1].Position(i)))
            .Select(i => names[i]).FirstOrDefault();
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
