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
        r.Answer(Renumber.SegmentCascadeTitle, "Yes");
        r.Cell($"Weight Row {segs}");                   // the grid grew by one row
        r.Shot("segment-inserted");
        r.SelectScreen("Joint Definition [B.3.A, B.3.B, B.3.C]");
        r.Click(r.Cell("Name Row 0"));
        r.Shot("joint-1-selected");
        Robot.Press(VirtualKeyShort.CONTROL, VirtualKeyShort.INSERT);
        r.Answer(Renumber.JointCascadeTitle, "Yes");
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

    /// ATB 3I's cascade warning on Add row (segment screen): No leaves the deck as it was (Save writes the original
    /// bytes back), Yes inserts the copy and the grid grows by one row.
    [Fact]
    public void InsertSegmentWarning()
    {
        const string rel = "cases/2479/2479_2.LIN";
        var copy = Robot.TempCopy(rel, "inswarn");
        int segs = Deck.Load(copy).SegmentCount;
        using var r = new Robot("insert-segment-warning", copy);
        r.SelectScreen(SegScreen);
        r.Click(r.Cell("Weight Row 1"));
        Robot.Press(VirtualKeyShort.CONTROL, VirtualKeyShort.INSERT);
        var w = r.WaitDialog(Renumber.SegmentCascadeTitle);
        r.Shot("segment-warning");
        var text = r.DialogText(w);
        Assert.Contains("You have inserted/deleted segments and this requires CASCADE UPDATE/DELETE", text);
        Assert.Contains("other input cards referring these segments.  Continue?", text);
        r.Click(r.Button(w, "No"));
        Robot.UntilTrue(() => r.Dialog(Renumber.SegmentCascadeTitle) == null, 10, "warning closed");
        Assert.Null(r.Main.FindFirstDescendant(r.A.ConditionFactory.ByName($"Weight Row {segs}")));
        r.Shot("answered-no");
        r.SaveDeck(copy);
        Assert.Equal(File.ReadAllBytes(Path.Combine(Robot.Repo, rel)), File.ReadAllBytes(copy));
        r.Click(r.Cell("Weight Row 1"));
        Robot.Press(VirtualKeyShort.CONTROL, VirtualKeyShort.INSERT);
        r.Answer(Renumber.SegmentCascadeTitle, "Yes");
        r.Cell($"Weight Row {segs}");                   // the grid grew by one row
        r.Shot("answered-yes");
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

    /// ATB 3I Body.cs:1049 (MainForm.ConfirmReplace shows it with ReplaceText).
    const string ReplaceText = "You are about to replace the selected body with data generated by GEBOD.  ATB3I will\r\nADJUST this body's segment numbers referred on other cards for the difference between the\r\nreplaced and new body.  You can't undo this operation after clicking \"Run GEBOD\" button in the next window.  Continue?";

    /// Temp copy of 2479_2, Tools > GEBOD (same 50th-percentile adult male as NewGebodSaveRun), Replace body 1,
    /// Yes on 3I's replace confirmation, Save, Run to completion. The saved deck must equal the by-position merge of
    /// fixtures/gebod-50m.ain into body 1 (segment/joint counts and body starts) and validate.
    [Fact]
    public void GebodReplaceBody1Run()
    {
        var copy = Robot.TempCopy("cases/2479/2479_2.LIN", "gebod-replace");
        var orig = Deck.Load(copy);
        using var r = new Robot("gebod-replace-body1", copy);
        r.Shot("opened");
        r.Menu("Tools", "GEBOD...");
        var g = r.WaitDialog("GEBOD V.2");
        r.Shot("gebod-form");
        r.Choose(g, "Place the GEBOD body", "Replace body");
        r.Choose(g, "Subject Type", "Adult Human Male");
        r.Choose(g, "Supplied Parameter", "3) All the Above");       // resets the unit rows: pick it before them
        r.Choose(g, "Units for Weight", "Percentile");
        r.Type(g, "Weight", "50");
        r.Choose(g, "Units for Height", "Percentile");
        r.Type(g, "Height", "50");
        r.Choose(g, "Units for Output Data Set", "English");
        r.Choose(g, "Lower Arm Segmentation", "Forearm and Hand Combined");
        r.Shot("gebod-filled");                      // Body number stays at its default, 1
        r.Click(r.Button(g, "Run GEBOD"));
        var q = r.WaitDialog("Replace Body Using GEBOD");
        r.Shot("replace-confirm");
        Assert.Contains(ReplaceText.Replace("\r\n", "\n"), r.DialogText(q).Replace("\r\n", "\n"));
        r.Click(r.Button(q, "Yes"));
        var segs = new Regex(@"\b[1-9]\d* segments");
        Robot.UntilTrue(() => r.Dialog("GEBOD") != null
            || (r.Dialog("Replace Body Using GEBOD") == null && !r.Windows().Any(w => w.Name.StartsWith("GEBOD: ", StringComparison.Ordinal))
                && r.Main.FindAllDescendants(r.A.ConditionFactory.ByControlType(ControlType.Text)).Any(e => segs.IsMatch(e.Name))), 120, "GEBOD run and merge");
        r.Shot("gebod-merged");
        Assert.Empty(r.Unexpected());               // a "GEBOD" box (exe failed, merge failed) lands here; 3I shows no post-run list
        r.SelectScreen(SegScreen);
        r.Cell("Weight Row 0");
        r.Shot("segment-screen");

        r.SaveDeck(copy);
        var d = Deck.Load(copy);
        var want = GebodMerge.Merge(orig, File.ReadAllText(Path.Combine(Robot.Repo, "app/Atb.Core.Tests/fixtures/gebod-50m.ain")), new(GebodMode.Replace, 1), _ => true);
        Assert.Equal((want.SegmentCount, want.JointCount), (d.SegmentCount, d.JointCount));
        Assert.Equal(GebodMerge.BodyStarts(want), GebodMerge.BodyStarts(d));
        Assert.Empty(d.Validate());

        var outDir = Path.Combine(Robot.Work, "gebod-replace", "out"); Directory.CreateDirectory(outDir);
        var dest = Path.Combine(outDir, "2479_2_gebod");
        r.RunDeck(dest);
        Assert.Empty(r.Unexpected());
        var aou = dest + ".aou";
        Assert.True(new FileInfo(aou) is { Exists: true, Length: > 0 }, "missing " + aou);
        var text = File.ReadAllText(aou);
        Assert.True(SolverJob.AouEndedNormally(text), "solver did not finish normally; .aou tail:\n" + string.Join("\n", text.Split('\n').TakeLast(15)));
        r.Shot("run-completed");
    }

    const string BodyTitle = "Body Editing Form";
    // ATB 3I Body.cs messages, copied literally (the UI tests do not reference Atb.App).
    const string InsertCopiedText = "Insert a new copied body before the selected body?\r\nClick NO button will add copied body after the selected body.\r\nATB 3I will cascade update other input cards for segment numbering.\r\nYou can't undo this operation once it proceeds.";   // :627
    const string DeleteText = "You are about to delete the selected body.  ATB 3I will CASCADE DELETE\r\nother input cards referring segments of this body.\r\nYou can't undo this operation once it proceeds.  Continue?";   // :756
    const string ReplaceCopiedText = "You are about to replace the selected body with data from a copied body.  ATB3I will\r\nADJUST this body's segment numbers referred on other cards for the difference between\r\nreplaced and new bodies.  You can't undo this operation once it proceeds.  Continue?";   // :860
    const string GebodInsertText = "Insert a new body before the selected body?\r\nClick NO button will add the body after the selected body.\r\nATB 3I will cascade update other input cards for segment numbering.\r\nYou can't undo this operation after clicking \"Run GEBOD\" button in the next window.";   // :990

    /// Model > Body... > Body Summary... (Robot.Menu finds one level; the submenu item is clicked here).
    static AutomationElement OpenBodySummary(Robot r)
    {
        r.Menu("Model", "Body...");
        var cond = r.A.ConditionFactory.ByControlType(ControlType.MenuItem).And(r.A.ConditionFactory.ByName("Body Summary..."));
        r.Click(Robot.Until(() => r.A.GetDesktop().FindAllChildren(r.A.ConditionFactory.ByProcessId(r.App.ProcessId))
            .Select(w => w.FindFirstDescendant(cond)).FirstOrDefault(e => e != null), 10, "menu item Body Summary..."));
        return BodyWin(r, BodyTitle);
    }

    /// A window at any depth (a MessageBox owned by the Body form sits under it, below Robot.Windows' two levels).
    static AutomationElement? FindWin(Robot r, string title) =>
        r.A.GetDesktop().FindAllChildren(r.A.ConditionFactory.ByProcessId(r.App.ProcessId))
            .SelectMany(w => new[] { w }.Concat(w.FindAllDescendants(r.A.ConditionFactory.ByControlType(ControlType.Window))))
            .FirstOrDefault(w => w.Name == title);
    static AutomationElement BodyCell(Robot r, AutomationElement form, string name)
    {
        try { return Robot.Until(() => form.FindFirstDescendant(r.A.ConditionFactory.ByName(name)), 15, "Body table cell " + name); }
        catch (TimeoutException)
        {
            r.Shot("no-cell");
            r.Log("Body form elements: " + string.Join(" | ", form.FindAllDescendants().Take(80)
                .Select(e => $"{e.Properties.ClassName.ValueOrDefault}:{e.Properties.Name.ValueOrDefault}")));
            throw;
        }
    }
    static AutomationElement BodyWin(Robot r, string title) => Robot.Until(() => FindWin(r, title), 30, $"'{title}' window");

    /// Clicks `button` on the Body form, waits for 3I's box `title`, checks its text, screenshots it, answers `answer`.
    static void BodyAsk(Robot r, AutomationElement form, string button, string title, string text, string answer, string shot)
    {
        r.Click(r.Button(form, button));
        var q = BodyWin(r, title);
        r.Shot(shot);
        Assert.Contains(text.Replace("\r\n", "\n"), r.DialogText(q).Replace("\r\n", "\n"));
        r.Click(r.Button(q, answer));
        Robot.UntilTrue(() => FindWin(r, title) == null, 10, $"'{title}' closed");
    }

    /// Body Summary on client deck 2479_2 (two bodies): the form, then each button's ATB 3I dialog (Body.cs:627, :860,
    /// :990, :1049, :756), each cancelled or answered No, and the empty-clipboard warning; the deck stays unchanged.
    [Fact]
    public void BodySummaryDialogs()
    {
        var copy = Robot.TempCopy("cases/2479/2479_2.LIN", "body-dialogs");
        var before = File.ReadAllText(copy);
        using var r = new Robot("body-summary-dialogs", copy);
        var f = OpenBodySummary(r);
        r.Shot("body-form");
        Assert.Equal("15", Robot.Value(BodyCell(r, f, "Number of Seg Row 1")));
        r.Click(r.Button(f, "Add/Insert Copied Body"));
        var w = BodyWin(r, "Add/Insert Body Operation Warning");
        r.Shot("empty-clipboard-warning");
        Assert.Contains("Clipboard doesn't contain any data.", r.DialogText(w));
        r.Click(r.Button(w, "OK"));
        r.Click(r.Button(f, "Copy Body"));
        r.Shot("copied");
        BodyAsk(r, f, "Add/Insert Copied Body", "Add/Insert Copied Body", InsertCopiedText, "Cancel", "add-copied-627");
        BodyAsk(r, f, "Replace Body with Copied Body", "Replace Body", ReplaceCopiedText, "No", "replace-copied-860");
        BodyAsk(r, f, "Add/Insert Body Using GEBOD", "Add/Insert Body Using GEBOD", GebodInsertText, "Cancel", "gebod-add-990");
        BodyAsk(r, f, "Replace Body Using GEBOD", "Replace Body Using GEBOD", ReplaceText, "No", "gebod-replace-1049");
        BodyAsk(r, f, "Delete Body", "Delete Body", DeleteText, "No", "delete-756");
        Assert.Equal("15", Robot.Value(BodyCell(r, f, "Number of Seg Row 1")));
        r.Click(r.Button(f, "Save & Exit"));
        Robot.UntilTrue(() => FindWin(r, BodyTitle) == null, 10, "Body form closed");
        r.Shot("closed");
        Assert.Empty(r.Unexpected());
        Assert.Equal(before, File.ReadAllText(copy));
    }

    /// File > Setting: ATB 3I's Maximum Value List (MainMenu.cs:4296-4317), rows from the Setting table in ID order;
    /// read-only (typing into a cell changes nothing, no Save button), Cancel closes it, the deck stays unchanged.
    [Fact]
    public void MaxValueList()
    {
        var copy = Robot.TempCopy("cases/2479/2479_2.LIN", "max-value-list");
        var before = File.ReadAllText(copy);
        using var r = new Robot("max-value-list", copy);
        r.Menu("File", "Setting");
        var f = BodyWin(r, "ATB 3I Maximum Value List");
        r.Shot("max-value-list");
        Assert.Equal(("Max Segment", "80"), (Robot.Value(BodyCell(r, f, "Name Row 0")), Robot.Value(BodyCell(r, f, "Value Row 0"))));
        Assert.Equal(("Balance Accel", "1"), (Robot.Value(BodyCell(r, f, "Name Row 20")), Robot.Value(BodyCell(r, f, "Value Row 20"))));
        r.Click(BodyCell(r, f, "Value Row 0"));
        FlaUI.Core.Input.Keyboard.Type("9");
        Robot.Press(VirtualKeyShort.RETURN);
        Assert.Equal("80", Robot.Value(BodyCell(r, f, "Value Row 0")));
        Assert.Null(f.FindFirstDescendant(r.A.ConditionFactory.ByControlType(ControlType.Button).And(r.A.ConditionFactory.ByName("Save"))));
        r.Click(r.Button(f, "Cancel"));
        Robot.UntilTrue(() => FindWin(r, "ATB 3I Maximum Value List") == null, 10, "Maximum Value List closed");
        r.Shot("closed");
        Assert.Empty(r.Unexpected());
        Assert.Equal(before, File.ReadAllText(copy));
    }

    /// Body Summary on 2495_2: select body 2, Delete Body, Yes on Body.cs:756, Save & Exit, Save, Run to completion.
    /// (Done-when 1 names 2638_Start_135_, which has one body; 2495_2 is the client deck with a second body.)
    [Fact]
    public void BodySummaryDeleteRun()
    {
        var copy = Robot.TempCopy("cases/2495/2495_2.LIN", "body-delete");
        var want = Bodies.Delete(Deck.Load(copy), 2);
        using var r = new Robot("body-summary-delete", copy);
        var f = OpenBodySummary(r);
        r.Shot("body-form");
        r.Click(BodyCell(r, f, "BodyID Row 1"));
        r.Shot("body2-selected");
        BodyAsk(r, f, "Delete Body", "Delete Body", DeleteText, "Yes", "delete-confirm");
        Robot.UntilTrue(() => f.FindFirstDescendant(r.A.ConditionFactory.ByName("BodyID Row 1")) == null, 15, "body 2 gone from the table");
        r.Shot("deleted");
        r.Click(r.Button(f, "Save & Exit"));
        Robot.UntilTrue(() => FindWin(r, BodyTitle) == null, 10, "Body form closed");
        Assert.Empty(r.Unexpected());
        r.SaveDeck(copy);
        var d = Deck.Load(copy);
        Assert.Equal(want.Write(), d.Write());
        Assert.Empty(d.Validate());

        var outDir = Path.Combine(Robot.Work, "body-delete", "out"); Directory.CreateDirectory(outDir);
        var dest = Path.Combine(outDir, "2495_2_del2");
        r.RunDeck(dest);
        Assert.Empty(r.Unexpected());
        var aou = dest + ".aou";
        Assert.True(new FileInfo(aou) is { Exists: true, Length: > 0 }, "missing " + aou);
        var text = File.ReadAllText(aou);
        Assert.True(SolverJob.AouEndedNormally(text), "solver did not finish normally; .aou tail:\n" + string.Join("\n", text.Split('\n').TakeLast(15)));
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
    static readonly string[] Torso = ["CT", "UT", "LT"];
    static string? Mover(Sa1File s)
    {
        if (s.Frames.Count < 2) return null;
        // body segments only (vehicles/planes are "Entry N"): the follow camera should track the occupant
        var names = s.Segments.Select(g => g.Name.Trim()).ToList();
        return Enumerable.Range(0, Math.Min(s.NGnd, names.Count))
            // two occupants repeat every name (2495_2, 2696_3: 2x17); Choose selects a name's first item, so rank only that one
            .Where(i => names[i].Length > 0 && names.IndexOf(names[i]) == i && names[i] != "View all (fixed)")
            // the 3I segment camera turns with its segment (decomp Animation.cs:1476, Upward=0 FileManager.cs:2825), so a
            // limb/head follow swings behind floor/wall planes; the torso turns least. Else the entry that travels furthest.
            .OrderBy(i => Array.IndexOf(Torso, names[i]) is var t && t >= 0 ? t : Torso.Length)
            .ThenByDescending(i => System.Numerics.Vector3.Distance(s.Frames[0].Position(i), s.Frames[^1].Position(i)))
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
