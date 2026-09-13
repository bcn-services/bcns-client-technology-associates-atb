using System.Diagnostics;
using FlaUI.Core;
using FlaUI.Core.AutomationElements;
using FlaUI.Core.Capturing;
using FlaUI.Core.Conditions;
using FlaUI.Core.Definitions;
using FlaUI.Core.Input;
using FlaUI.Core.WindowsAPI;
using FlaUI.UIA3;

[assembly: Xunit.CollectionBehavior(DisableTestParallelization = true)]   // one desktop, one keyboard

namespace Atb.App.UiTests;

/// Drives the published ATB.exe through UI Automation. Every element is found by its Name / window title
/// (its visible content), never by position in the tree. Screenshots go to $E2E_OUT/shots/<scenario>/NN-<step>.png.
public sealed class Robot : IDisposable
{
    public static string Exe => Env("ATB_EXE");
    public static string Out => Env("E2E_OUT");
    public static string Work => Path.GetFullPath(Env("WORK"));
    static string Env(string n) => Environment.GetEnvironmentVariable(n) is { Length: > 0 } v ? v : throw new InvalidOperationException($"set {n}");

    /// Repo root = nearest ancestor of the test binary that holds cases/ (as Atb.Core.Tests/Fixtures.cs).
    public static string Repo
    {
        get
        {
            var d = new DirectoryInfo(AppContext.BaseDirectory);
            while (d != null && !Directory.Exists(Path.Combine(d.FullName, "cases"))) d = d.Parent;
            return d?.FullName ?? throw new InvalidOperationException("cases/ not found above " + AppContext.BaseDirectory);
        }
    }

    public readonly UIA3Automation A = new();
    public readonly Application App;
    public readonly Window Main;
    public readonly string MainTitle;
    readonly string scenario, shots; int n; readonly IntPtr mainHwnd;
    ConditionFactory Cf => A.ConditionFactory;

    public Robot(string scenario, string? deck = null)
    {
        if (deck != null) AssertTempCopy(deck);
        this.scenario = scenario;
        shots = Path.Combine(Out, "shots", scenario); Directory.CreateDirectory(shots);
        var psi = new ProcessStartInfo(Exe) { WorkingDirectory = Path.GetDirectoryName(Exe)!, UseShellExecute = false };
        if (deck != null) psi.ArgumentList.Add(deck);
        App = Application.Launch(psi);
        Main = App.GetMainWindow(A, TimeSpan.FromSeconds(60)) ?? throw new InvalidOperationException("ATB main window did not appear");
        MainTitle = Main.Name; mainHwnd = Main.Properties.NativeWindowHandle.ValueOrDefault;
        Main.SetForeground(); Wait.UntilInputIsProcessed();
        Log($"launched pid {App.ProcessId} '{MainTitle}' deck={deck}");
    }

    /// Guardrail: the robot never opens (and so never saves or runs) a deck inside the repo's cases/.
    public static void AssertTempCopy(string path)
    {
        var cases = Path.GetFullPath(Path.Combine(Repo, "cases")) + Path.DirectorySeparatorChar;
        if (Path.GetFullPath(path).StartsWith(cases, StringComparison.OrdinalIgnoreCase))
            throw new InvalidOperationException("robot must work on a temp copy, not " + path);
    }

    /// Copy repo-relative `rel` into $WORK/<area>/ and return the copy's path.
    public static string TempCopy(string rel, string area)
    {
        var dir = Path.Combine(Work, area); Directory.CreateDirectory(dir);
        var to = Path.Combine(dir, Path.GetFileName(rel));
        File.Copy(Path.Combine(Repo, rel), to, true);
        return to;
    }

    public void Log(string s) => File.AppendAllText(Path.Combine(Out, "robot.log"), $"{DateTime.Now:HH:mm:ss.fff} [{scenario}] {s}\n");

    public string Shot(string step)
    {
        var p = Path.Combine(shots, $"{++n:00}-{step}.png");
        try { using var img = Capture.Screen(); img.ToFile(p); Log("shot " + p); }
        catch (Exception e) { Log($"screenshot {p} failed: {e.Message}"); }
        return p;
    }

    public static T Until<T>(Func<T?> f, double sec, string what) where T : class
    {
        var sw = Stopwatch.StartNew(); Exception? last = null;
        while (true)
        {
            try { if (f() is { } r) return r; } catch (Exception e) { last = e; }
            if (sw.Elapsed.TotalSeconds > sec) throw new TimeoutException($"{what}: not after {sec}s" + (last != null ? $" (last error: {last.Message})" : ""));
            Thread.Sleep(250);
        }
    }
    public static void UntilTrue(Func<bool> f, double sec, string what) => Until(() => f() ? "" : null, sec, what);

    public static void Press(params VirtualKeyShort[] keys) { Keyboard.TypeSimultaneously(keys); Wait.UntilInputIsProcessed(); }

    /// Every window of the app: its top-level windows plus the (modal / owned) windows UIA parents under them.
    public List<AutomationElement> Windows()
    {
        var res = new List<AutomationElement>();
        foreach (var top in A.GetDesktop().FindAllChildren(Cf.ByProcessId(App.ProcessId)))
        {
            if (top.ControlType == ControlType.Window) res.Add(top);
            res.AddRange(top.FindAllChildren(Cf.ByControlType(ControlType.Window)));
        }
        return res;
    }
    public AutomationElement? Dialog(string title) => Windows().FirstOrDefault(w => w.Name == title);
    public string DialogText(AutomationElement w) => string.Join(" | ", w.FindAllDescendants(Cf.ByControlType(ControlType.Text)).Select(e => e.Name));

    /// Windows other than the main window and the named allowed ones: an error box, an exception dialog, ...
    /// The main window is matched by handle too: its title changes with the deck (File > New, Save As).
    public List<string> Unexpected(params string[] allowedPrefixes) =>
        Windows().Where(w => w.Name != MainTitle && w.Properties.NativeWindowHandle.ValueOrDefault != mainHwnd
                             && !allowedPrefixes.Any(p => w.Name.StartsWith(p, StringComparison.Ordinal)))
                 .Select(w => $"{w.Name} [{w.ClassName}] {DialogText(w)}").ToList();

    public AutomationElement WaitDialog(string title, double sec = 30) => Until(() => Dialog(title), sec, $"'{title}' dialog");
    public AutomationElement Named(AutomationElement within, ControlType t, string name) =>
        Until(() => within.FindFirstDescendant(Cf.ByControlType(t).And(Cf.ByName(name))), 10, $"{t} '{name}'");

    /// A combo box's shown text (ValuePattern, else the selected list item).
    public static string ComboText(AutomationElement cb) =>
        cb.Patterns.Value.PatternOrDefault?.Value.ValueOrDefault is { Length: > 0 } v ? v : cb.AsComboBox().SelectedItem?.Text ?? "";

    /// Pick `item` in the combo box named `combo` with the mouse (opens the list, clicks the item by its text), so the
    /// app sees a real SelectedIndexChanged. Throws unless the box then shows `item`.
    public void Choose(AutomationElement within, string combo, string item)
    {
        var cb = Named(within, ControlType.ComboBox, combo);
        var cond = Cf.ByControlType(ControlType.ListItem).And(Cf.ByName(item));
        Click(cb);
        Until(() =>
        {
            var li = cb.FindFirstDescendant(cond)
                     ?? A.GetDesktop().FindAllChildren(Cf.ByProcessId(App.ProcessId)).Select(w => w.FindFirstDescendant(cond)).FirstOrDefault(e => e != null);
            li?.Click(); return li;       // a collapsed list has no clickable point: throws, Until retries
        }, 10, $"list item '{item}' of '{combo}'");
        Wait.UntilInputIsProcessed();
        UntilTrue(() => ComboText(cb) == item, 5, $"'{combo}' shows '{item}' (shows '{ComboText(cb)}')");
        Log($"{combo} = {item}");
    }

    /// Type into the text box named `name`, replacing its text.
    public void Type(AutomationElement within, string name, string text)
    {
        var e = Named(within, ControlType.Edit, name);
        e.Focus(); Press(VirtualKeyShort.CONTROL, VirtualKeyShort.KEY_A); Keyboard.Type(text); Wait.UntilInputIsProcessed();
        if (Value(e) != text) throw new InvalidOperationException($"'{name}' holds '{Value(e)}', not '{text}'");
    }

    public AutomationElement Button(AutomationElement within, string name) =>
        Until(() => within.FindFirstDescendant(Cf.ByControlType(ControlType.Button).And(Cf.ByName(name))), 10, $"button '{name}'");

    // Mouse clicks, not Invoke: an Invoke on an item that opens a modal dialog blocks until the dialog closes.
    public void Click(AutomationElement e) { e.Click(); Wait.UntilInputIsProcessed(); }

    public void Menu(string top, string item)
    {
        Main.SetForeground();
        Click(Until(() => Main.FindFirstDescendant(Cf.ByControlType(ControlType.MenuItem).And(Cf.ByName(top))), 10, "menu " + top));
        var cond = Cf.ByControlType(ControlType.MenuItem).And(Cf.ByName(item));
        Click(Until(() => Main.FindFirstDescendant(cond)
            ?? A.GetDesktop().FindAllChildren(Cf.ByProcessId(App.ProcessId)).Select(w => w.FindFirstDescendant(cond)).FirstOrDefault(e => e != null), 10, "menu item " + item));
    }

    public void SelectScreen(string name)
    {
        var item = Until(() => Main.FindFirstDescendant(Cf.ByControlType(ControlType.ListItem).And(Cf.ByName(name))), 15, "card list item " + name);
        item.Patterns.ScrollItem.PatternOrDefault?.ScrollIntoView();
        if (item.Patterns.SelectionItem.PatternOrDefault is { } sel) sel.Select(); else Click(item);
        Wait.UntilInputIsProcessed();
    }

    /// DataGridView cells are named "<column header> Row <n>".
    public AutomationElement Cell(string name) => Until(() => Main.FindFirstDescendant(Cf.ByName(name)), 15, "grid cell " + name);
    public static string Value(AutomationElement e) => e.Patterns.Value.Pattern.Value.Value ?? "";

    /// Type a path into a common file dialog's "File name:" box and confirm it.
    public void FileDialog(string title, string path)
    {
        var d = Until(() => Dialog(title), 30, $"'{title}' dialog");
        var box = Until(() => d.FindFirstDescendant(Cf.ByControlType(ControlType.Edit).And(Cf.ByName("File name:"))), 10, "File name box");
        // Typed, not ValuePattern.SetValue: the Save dialog keeps its preset FileName when the box text is set via UIA.
        box.Focus(); Press(VirtualKeyShort.CONTROL, VirtualKeyShort.KEY_A); Keyboard.Type(path); Wait.UntilInputIsProcessed();
        if (Value(box) != path) throw new InvalidOperationException($"'{title}' File name box holds '{Value(box)}', not '{path}'");
        Shot(title.Replace(' ', '-').ToLowerInvariant() + "-dialog");
        box.Focus(); Keyboard.Type(VirtualKeyShort.RETURN); Wait.UntilInputIsProcessed();
        UntilTrue(() => Dialog(title) == null, 15, $"'{title}' dialog closed");
        Log($"{title}: {path}");
    }

    /// Ctrl+S, answering the Deck.Validate warning (title "Save") with OK if it appears; waits for the file to be rewritten.
    /// saveAs: the deck has no path yet (File > New), so Ctrl+S opens the "Save As" dialog, answered with `path`.
    public void SaveDeck(string path, bool saveAs = false)
    {
        var t0 = File.GetLastWriteTimeUtc(path);
        Main.SetForeground(); Press(VirtualKeyShort.CONTROL, VirtualKeyShort.KEY_S);
        if (saveAs) FileDialog("Save As", path);
        UntilTrue(() =>
        {
            if (Dialog("Save") is { } w) { Shot("save-validate-warning"); Log("Save warning: " + DialogText(w)); Click(Button(w, "OK")); }
            return File.GetLastWriteTimeUtc(path) != t0;
        }, 30, "deck saved to " + path);
        Shot("saved");
    }

    /// F5 (File > Run ATB): OK on the "Run" validate warning if shown, answer "Save results as" with dest, wait for the
    /// run to end, decline "Open the animation?". Throws with the dialog text when the app reports a failed run.
    public TimeSpan RunDeck(string dest)
    {
        Main.SetForeground(); Press(VirtualKeyShort.F5);
        var first = Until(() => Dialog("Save results as") ?? Dialog("Run"), 30, "'Save results as' or the Run warning");
        if (first.Name == "Run") { Shot("run-validate-warning"); Log("Run warning: " + DialogText(first)); Click(Button(first, "OK")); }
        FileDialog("Save results as", dest);
        var sw = Stopwatch.StartNew();
        Thread.Sleep(2000); Shot("running");
        var end = Until(() => Dialog("ATB run") ?? Dialog("ATB Run")
            ?? (File.Exists(dest + ".aou") && !Windows().Any(w => w.Name.StartsWith("ATB run: ", StringComparison.Ordinal)) ? Main : null),
            1800, "solver run to finish");
        Shot("run-finished");
        if (end.Name == "ATB Run") throw new Xunit.Sdk.XunitException("app reported a failed run: " + DialogText(end));
        if (end.Name == "ATB run") Click(Button(end, "No"));
        Log($"run finished in {sw.Elapsed.TotalSeconds:F0}s -> {dest}");
        return sw.Elapsed;
    }

    public void Dispose()
    {
        try { if (!App.HasExited) { App.Close(); UntilTrue(() => App.HasExited, 5, "app exit"); } } catch { }
        try { if (!App.HasExited) App.Kill(); } catch { }
        App.Dispose(); A.Dispose();
    }
}
