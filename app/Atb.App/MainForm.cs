using System.IO;
using Atb.App.Solver;
using Atb.App.Viewer;
using Atb.Core.Cards;
using Atb.Core.Lin;
using Atb.Core.Sa1;
using Atb.Core.Solver;

namespace Atb.App;

/// Main window: card list on the left, one grid per card on the right, File/Run/View menus.
public sealed class MainForm : Form
{
    Deck? deck; string? deckPath; bool dirty, suppress;
    CardSchema.Screen? screen; Dictionary<(Kind, int), string> refs = new();
    string? solverExe; bool running;
    readonly ListBox cards = new() { Dock = DockStyle.Fill, IntegralHeight = false };
    readonly DataGridView grid = new()
    {
        Dock = DockStyle.Fill, AllowUserToAddRows = false, AllowUserToDeleteRows = false,
        EditMode = DataGridViewEditMode.EditOnKeystrokeOrF2, ClipboardCopyMode = DataGridViewClipboardCopyMode.EnableWithoutHeaderText, AutoSizeColumnsMode = DataGridViewAutoSizeColumnsMode.AllCells,
    };
    readonly ToolStripStatusLabel status = new("Open a .lin deck to begin.");

    public MainForm(string? path = null)
    {
        Text = "ATB"; Width = 1200; Height = 750; StartPosition = FormStartPosition.CenterScreen;
        var menu = new MenuStrip();
        var file = new ToolStripMenuItem("&File");
        file.DropDownItems.Add(Item("&New", Keys.Control | Keys.N, NewDeck));
        file.DropDownItems.Add(Item("&Open...", Keys.Control | Keys.O, OpenDialog));
        file.DropDownItems.Add(Item("&Save", Keys.Control | Keys.S, Save));
        file.DropDownItems.Add("Save &As...", null, (_, _) => SaveAs());
        file.DropDownItems.Add(new ToolStripSeparator());
        file.DropDownItems.Add(Item("&Run ATB", Keys.F5, async () => await RunDeck()));
        file.DropDownItems.Add("Con&vert .ain to .lin...", null, async (_, _) => await ConvertAin());
        file.DropDownItems.Add("Choose &solver executable...", null, (_, _) => solverExe = PickSolver());
        file.DropDownItems.Add(new ToolStripSeparator());
        // ATB 3I MainMenu.cs:2655-2659: File > Setting, between separators before Exit; non-modal as 3I's Show() (:4315).
        file.DropDownItems.Add("Setting", null, (_, _) => new MaxValueForm().Show(this));
        file.DropDownItems.Add(new ToolStripSeparator());
        file.DropDownItems.Add("E&xit", null, (_, _) => Close());
        // Ctrl+Shift so plain Ctrl+C/V keep working inside a cell being edited.
        var edit = new ToolStripMenuItem("&Edit");
        edit.DropDownItems.Add(Item("&Add row (copy of selected)", Keys.Control | Keys.Insert, AddRow));
        edit.DropDownItems.Add(Item("&Delete rows", Keys.Control | Keys.Delete, DeleteRows));
        edit.DropDownItems.Add(Item("&Copy rows", Keys.Control | Keys.Shift | Keys.C, CopyRows));
        edit.DropDownItems.Add(Item("&Paste rows", Keys.Control | Keys.Shift | Keys.V, PasteRows));
        var view = new ToolStripMenuItem("&View");
        view.DropDownItems.Add("&Animation (.sa1)...", null, (_, _) => OpenSa1());
        var tools = new ToolStripMenuItem("&Tools");
        tools.DropDownItems.Add("&GEBOD...", null, async (_, _) => await Gebod());
        // ATB 3I MainMenu.cs:2698: Model > Body... > Body Summary...
        var model = new ToolStripMenuItem("&Model");
        var body = new ToolStripMenuItem("Body...");
        body.DropDownItems.Add("Body Summary...", null, async (_, _) => await BodySummary());
        model.DropDownItems.Add(body);
        menu.Items.AddRange([file, edit, view, model, tools]);
        MainMenuStrip = menu;

        var split = new SplitContainer { Dock = DockStyle.Fill, SplitterDistance = 300 };
        split.Panel1.Controls.Add(cards); split.Panel2.Controls.Add(grid);
        var bar = new StatusStrip(); bar.Items.Add(status);
        Controls.Add(split); Controls.Add(bar); Controls.Add(menu);

        cards.DisplayMember = nameof(CardSchema.Screen.Name);
        cards.Items.AddRange(CardSchema.Screens);
        cards.SelectedIndexChanged += (_, _) => { if (cards.SelectedItem is CardSchema.Screen s) ShowScreen(s); };
        grid.CellValueChanged += (_, e) => OnCellChanged(e.RowIndex, e.ColumnIndex);
        grid.CellFormatting += OnCellFormatting;
        grid.CellParsing += OnCellParsing;
        FormClosing += (_, e) =>
        {
            if (running) { e.Cancel = true; status.Text = "Cancel the solver run first."; }
            else if (dirty && !ConfirmDiscard()) e.Cancel = true;
        };
        if (path != null) Open(path);
    }

    static ToolStripMenuItem Item(string text, Keys keys, Action act) => new(text, null, (_, _) => act()) { ShortcutKeys = keys };

    public void Open(string path)
    {
        deck = Deck.Load(path); deckPath = path; dirty = false; bodyClip = null;
        ShowDeck();
    }

    /// File > New: ATB 3I's empty deck (FileManager.CreateEmptyFile), unsaved.
    void NewDeck()
    {
        if (running || (dirty && !ConfirmDiscard())) return;
        deck = GebodMerge.NewDeck(); deckPath = null; dirty = true; bodyClip = null;
        ShowDeck();
    }

    void ShowDeck()
    {
        if (deck == null) return;
        Text = $"ATB — {(deckPath == null ? "untitled" : Path.GetFileName(deckPath))}";
        status.Text = $"{deck.Title}: {deck.SegmentCount} segments, {deck.JointCount} joints, {deck.Lines.Count} lines";
        if (cards.SelectedItem is CardSchema.Screen s) ShowScreen(s); else cards.SelectedIndex = 0;
    }

    /// One grid over a card group: a row per primary line, continuation cards as extra columns.
    /// Column Tag = (group index, schema column); row Tag = the row's lines (Deck.Rows).
    void ShowScreen(CardSchema.Screen s)
    {
        if (deck == null) return;
        screen = s; refs = deck.RefNames();
        var rows = deck.Rows(s.Cards);
        suppress = true; grid.SuspendLayout(); grid.Rows.Clear(); grid.Columns.Clear();
        for (int g = 0; g < s.Cards.Length; g++)
        {
            var card = s.Cards[g];
            int w = rows.Where(r => r[g] != null).Select(r => r[g]!.Count + CardSchema.Skip(card, r[g]!.Count))
                        .Append(CardSchema.Cards[card].Names.Length).Max();
            for (int f = 0; f < w; f++)
                grid.Columns.Add(new DataGridViewTextBoxColumn
                {
                    HeaderText = CardSchema.Header(card, f), ToolTipText = card, Tag = (g, f),
                    SortMode = DataGridViewColumnSortMode.NotSortable,
                });
        }
        foreach (var row in rows)
        {
            var r = grid.Rows[grid.Rows.Add()]; r.Tag = row;
            foreach (DataGridViewColumn c in grid.Columns)
            {
                var (g, f) = ((int, int))c.Tag!;
                var line = row[g];
                int t = line == null ? -1 : f - CardSchema.Skip(line.Card, line.Count);
                if (line != null && t >= 0 && t < line.Count) r.Cells[c.Index].Value = line.Str(t);
                else r.Cells[c.Index].ReadOnly = true;          // no such token on this row
            }
        }
        grid.ResumeLayout(); suppress = false;
    }

    /// Cell edit -> Deck.Edit on that one line; refused text (e.g. non-numeric) reverts the cell.
    void OnCellChanged(int row, int col)
    {
        if (suppress || deck == null || row < 0 || grid.Rows[row].Tag is not DeckLine?[] lines || grid.Columns[col].Tag is not (int g, int f)) return;
        if (lines[g] is not { } line) return;
        int t = f - CardSchema.Skip(line.Card, line.Count);
        var v = grid[col, row].Value?.ToString() ?? "";
        var error = deck.Edit(line, t, v);
        if (error != null)
        {
            status.Text = $"{error}; value reverted.";
            suppress = true; grid[col, row].Value = t >= 0 && t < line.Count ? line.Str(t) : null; suppress = false;
            return;
        }
        if (line.Raw == null) dirty = true;
        status.Text = $"{line.Label} {CardSchema.Header(line.Card, f)} = {v}";
    }

    Kind? ColumnKind(int col) =>
        screen != null && grid.Columns[col].Tag is (int g, int f) ? CardSchema.KindOf(screen.Cards[g], f) : null;
    static bool IsRef(Kind? k) => k is Kind.SegRef or Kind.JointRef or Kind.PlaneRef or Kind.FuncRef;

    // Reference columns display "3 (Head)" but the cell (and the deck) keep the number.
    void OnCellFormatting(object? sender, DataGridViewCellFormattingEventArgs e)
    {
        if (e.RowIndex < 0 || e.ColumnIndex < 0 || e.Value is not string v || ColumnKind(e.ColumnIndex) is not { } k || !IsRef(k)) return;
        if (int.TryParse(v, out var n) && refs.TryGetValue((k, n), out var name)) { e.Value = $"{v} ({name})"; e.FormattingApplied = true; }
    }
    void OnCellParsing(object? sender, DataGridViewCellParsingEventArgs e)
    {
        if (e.Value is not string v || !IsRef(ColumnKind(e.ColumnIndex))) return;
        int i = v.IndexOf(" (", StringComparison.Ordinal);
        if (i >= 0) { e.Value = v[..i]; e.ParsingApplied = true; }
    }

    DeckLine?[][] SelectedRows() => grid.SelectedCells.Cast<DataGridViewCell>().Select(c => c.RowIndex).Distinct().Order()
        .Select(i => (DeckLine?[])grid.Rows[i].Tag!).ToArray();

    /// Row to insert after: the last selected row, else the screen's last row.
    DeckLine? InsertAnchor() =>
        (SelectedRows().LastOrDefault() ?? grid.Rows.Cast<DataGridViewRow>().Select(r => (DeckLine?[])r.Tag!).LastOrDefault())
            ?.Last(l => l != null);

    void InsertLines(IReadOnlyCollection<DeckLine> lines, string what)
    {
        if (deck == null || screen == null || lines.Count == 0) return;
        if (InsertAnchor() is not { } anchor) { status.Text = $"No {screen.Cards[0]} row to place the {what} after."; return; }
        grid.EndEdit();
        deck.Lines.InsertRange(deck.Lines.IndexOf(anchor) + 1, lines);
        dirty = true; ShowScreen(screen);
        status.Text = $"{what}: {lines.Count} line(s) added. Count cards (B.1, D.1.a, ...) are not updated.";
    }

    // Screens with one row per segment / joint / plane / vehicle: add and delete go through Renumber.
    static Entity? EntityOf(CardSchema.Screen s) => s.Cards[0] switch
    {
        "B.2.A" or "B.6" or "G.3.A" => Entity.Segment,
        "B.3.A" or "B.4.A" or "B.5.A" => Entity.Joint,
        "D.2.A" => Entity.Plane,
        "F.10" => Entity.Actuator,
        "C.1" or "C.2.A" => Entity.Vehicle,
        _ => null,
    };

    int[] SelectedIndexes() => grid.SelectedCells.Cast<DataGridViewCell>().Select(c => c.RowIndex).Where(i => i >= 0).Distinct().Order().ToArray();

    // ponytail: "add" duplicates the selected row as its template — a blank-from-schema row is not offered.
    void AddRow()
    {
        if (deck != null && screen != null && EntityOf(screen) is { } e)
        {
            var sel = SelectedIndexes();
            if (sel.Length == 0) { status.Text = "Select a row to copy as the new row."; return; }
            grid.EndEdit();
            if (!Renumber.CascadeConfirmed(e, null, AskYesNo)) return;
            int n = sel[^1] + 1, at = e == Entity.Vehicle ? n : n + 1;   // a vehicle goes before the selected one: the primary stays last
            try { Renumber.Insert(deck, e, at, Renumber.Copy(deck, e, n)); }
            catch (Exception ex) when (ex is InvalidOperationException or ArgumentOutOfRangeException) { status.Text = ex.Message; return; }
            dirty = true; ShowScreen(screen);
            status.Text = $"Added {e.ToString().ToLowerInvariant()} {at} as a copy; references and count cards renumbered.";
            return;
        }
        if (SelectedRows().LastOrDefault() is not { } row) { status.Text = "Select a row to copy as the new row."; return; }
        InsertLines(row.OfType<DeckLine>().Select(l => new DeckLine(l.Tokens, l.Label)).ToList(), "Add row");
    }

    void DeleteRows()
    {
        if (deck == null || screen == null) return;
        if (EntityOf(screen) is { } e)
        {
            grid.EndEdit();
            var sel = SelectedIndexes();
            bool cascade = e is Entity.Segment or Entity.Joint;
            if (cascade)
            {
                // ATB 3I asks once per grid update; the reference lists of every selected row go below its text.
                string detail;
                try { detail = string.Join("\r\n\r\n", sel.Select(i => RefText(e, i + 1, Renumber.DeleteRefs(deck, e, i + 1))).Where(t => t != "")); }
                catch (Exception ex) when (ex is InvalidOperationException or ArgumentOutOfRangeException) { status.Text = ex.Message; return; }
                if (!Renumber.CascadeConfirmed(e, detail, AskYesNo)) return;
            }
            int done = 0;
            foreach (var i in sel.Reverse())                                // highest first: lower numbers stay valid
            {
                int n = i + 1;
                try { if (Renumber.Delete(deck, e, n, refs => cascade || ConfirmDelete(e, n, refs)) != null) done++; }
                catch (Exception ex) when (ex is InvalidOperationException or ArgumentOutOfRangeException) { status.Text = ex.Message; }
            }
            if (done == 0) return;
            dirty = true; ShowScreen(screen);
            status.Text = $"Deleted {done} {e.ToString().ToLowerInvariant()}(s); references and count cards renumbered.";
            return;
        }
        var rows = SelectedRows();
        if (rows.Length == 0) return;
        grid.EndEdit();
        foreach (var l in rows.SelectMany(r => r.OfType<DeckLine>())) deck.Lines.Remove(l);
        dirty = true; ShowScreen(screen);
        status.Text = $"Deleted {rows.Length} row(s). Count cards (B.1, D.1.a, ...) are not updated.";
    }

    /// Asks before deleting an entity that other cards still refer to, listing each referencing line.
    bool ConfirmDelete(Entity e, int n, IReadOnlyList<RefSite> refs)
    {
        var text = RefText(e, n, refs)
                 + "\n\nDelete it anyway? As in ATB 3I, contact/constraint/force rows that depend on it are deleted and other references are cleared.";
        return MessageBox.Show(this, text, $"Delete {e.ToString().ToLowerInvariant()}", MessageBoxButtons.YesNo, MessageBoxIcon.Warning) == DialogResult.Yes;
    }

    /// "Segment 3 is still referenced by N line(s):" and the list; "" when nothing refers to it.
    static string RefText(Entity e, int n, IReadOnlyList<RefSite> refs)
    {
        if (refs.Count == 0) return "";
        var (count, list) = RefList(refs);
        return $"{e} {n} is still referenced by {count} line(s):\n\n" + list;
    }

    /// ATB 3I's cascade MessageBox: Yes/No, question icon, first button default (TableForm.cs:412).
    bool AskYesNo(string text, string title) =>
        MessageBox.Show(this, text, title, MessageBoxButtons.YesNo, MessageBoxIcon.Question, MessageBoxDefaultButton.Button1) == DialogResult.Yes;

    /// Referencing lines, one per line with its fields, first 25 shown.
    static (int Count, string Text) RefList(IReadOnlyList<RefSite> refs)
    {
        var lines = refs.GroupBy(r => (r.Line, r.Label)).Select(g => $"line {g.Key.Line}  {g.Key.Label}: {string.Join(", ", g.Select(r => r.Field))}").ToList();
        return (lines.Count, string.Join("\n", lines.Take(25)) + (lines.Count > 25 ? $"\n... and {lines.Count - 25} more" : ""));
    }

    /// ATB 3I Body.cs:1049, asked before GEBOD runs (title, buttons and icon as 3I's MessageBox).
    bool ConfirmReplace() =>
        MessageBox.Show(this, GebodForm.ReplaceText, "Replace Body Using GEBOD", MessageBoxButtons.YesNo, MessageBoxIcon.Question) == DialogResult.Yes;

    /// A GEBOD run that could not be merged: offer to keep its output so the user need not rerun GEBOD.
    void OfferSaveAin(string ain, string why)
    {
        if (MessageBox.Show(this, why + "\n\nSave the GEBOD output (GEBOD.ain) so it is not lost?", "GEBOD", MessageBoxButtons.YesNo, MessageBoxIcon.Warning) != DialogResult.Yes) return;
        using var s = new SaveFileDialog { Filter = "ATB fixed-format input (*.ain)|*.ain", FileName = "GEBOD.ain", Title = "Save GEBOD output" };
        if (s.ShowDialog(this) != DialogResult.OK) return;
        try { File.WriteAllText(s.FileName, ain); status.Text = "GEBOD output saved to " + s.FileName; }
        catch (Exception ex) { MessageBox.Show(this, ex.Message, "GEBOD", MessageBoxButtons.OK, MessageBoxIcon.Error); }
    }

    void CopyRows()
    {
        if (screen == null || SelectedRows() is not { Length: > 0 } rows) return;
        Clipboard.SetText(Deck.ToPasteText(rows, screen.Cards));
        status.Text = $"Copied {rows.Length} row(s).";
    }

    /// Excel/grid paste -> Deck.ParsePaste; accepted rows go in after the selected row.
    void PasteRows()
    {
        if (screen == null || !Clipboard.ContainsText()) return;
        var res = Deck.ParsePaste(Clipboard.GetText(), screen.Cards);
        var rejected = res.Rejected;
        if (deck != null && EntityOf(screen) is { } e)
        {
            var sel = SelectedIndexes();
            if (sel.Length == 0) status.Text = "Select the row to paste after (its copy fills the entity's other cards).";
            else if (res.Rows.Count > 0)
            {
                grid.EndEdit();
                if (!Renumber.CascadeConfirmed(e, null, AskYesNo)) return;
                int n = sel[^1] + 1, at = e == Entity.Vehicle ? n : n + 1;   // as AddRow: a vehicle goes before the selected one
                try
                {
                    rejected.AddRange(Renumber.Paste(deck, e, screen.Cards, at, n, res.Rows));
                    dirty = true; ShowScreen(screen);
                    status.Text = $"Pasted {e.ToString().ToLowerInvariant()}(s) at {at}; references and count cards renumbered.";
                }
                catch (Exception ex) when (ex is InvalidOperationException or ArgumentOutOfRangeException) { status.Text = ex.Message; }
            }
        }
        else InsertLines(res.Lines, "Paste");
        if (rejected.Count > 0)
            MessageBox.Show(this, "Rows not pasted:\n" + string.Join("\n", rejected.Take(20)), "Paste", MessageBoxButtons.OK, MessageBoxIcon.Warning);
    }

    void OpenDialog()
    {
        if (dirty && !ConfirmDiscard()) return;
        using var d = new OpenFileDialog { Filter = "ATB input decks (*.lin)|*.lin;*.LIN|All files|*.*" };
        if (d.ShowDialog(this) == DialogResult.OK) Open(d.FileName);
    }
    bool ConfirmDiscard() =>
        MessageBox.Show(this, "Discard unsaved changes?", "ATB", MessageBoxButtons.YesNo, MessageBoxIcon.Warning) == DialogResult.Yes;

    void Save()
    {
        if (deck == null) return;
        if (deckPath == null) { SaveAs(); return; }
        grid.EndEdit();
        if (!DeckValid("Save")) return;
        Write();
    }
    void Write() { deck!.Save(deckPath!); dirty = false; status.Text = $"Saved {deckPath}"; }

    /// Deck.Validate before the deck is written or reaches the solver. Warn-only: a validator false positive
    /// must never block a deck the solver would accept, so Save and Run both offer Continue (OK) / Cancel.
    bool DeckValid(string action)
    {
        var issues = deck!.Validate();
        if (issues.Count == 0) return true;
        var text = "The solver will reject or misread this deck:\n\n" + string.Join("\n", DeckIssue.Format(issues))
                 + $"\n\nOK to {action.ToLowerInvariant()} anyway, Cancel to go back.";
        return MessageBox.Show(this, text, action, MessageBoxButtons.OKCancel, MessageBoxIcon.Warning, MessageBoxDefaultButton.Button2) == DialogResult.OK;
    }
    void SaveAs()
    {
        if (deck == null) return;
        using var d = new SaveFileDialog { Filter = "ATB input decks (*.lin)|*.lin", FileName = Path.GetFileName(deckPath ?? "new.lin") };
        if (d.ShowDialog(this) != DialogResult.OK) return;
        deckPath = d.FileName; Text = $"ATB — {Path.GetFileName(deckPath)}"; Save();
    }

    string? PickSolver()
    {
        using var d = new OpenFileDialog { Filter = "ATB solver (*.exe)|*.exe", Title = "Choose the ATB solver executable" };
        return d.ShowDialog(this) == DialogResult.OK ? d.FileName : solverExe;
    }
    string? FindSolver()
    {
        var here = AppContext.BaseDirectory;
        return new[] { "atb-win32.exe", "atb.exe", "ATBV3.exe" }.Select(n => Path.Combine(here, n)).FirstOrDefault(File.Exists) ?? PickSolver();
    }

    Task RunDeck()
    {
        if (deck == null || deckPath == null) { status.Text = "Open a deck first."; return Task.CompletedTask; }
        grid.EndEdit();
        if (!DeckValid("Run")) return Task.CompletedTask;
        if (dirty) Write(); // already validated above; Save() would ask a second time
        return RunSolver(SolverMode.RunLin, deckPath);
    }

    Task ConvertAin()
    {
        if (running || (dirty && !ConfirmDiscard())) return Task.CompletedTask;
        using var d = new OpenFileDialog { Filter = "ATB fixed-format input (*.ain)|*.ain;*.AIN", Title = "Convert .ain to .lin" };
        return d.ShowDialog(this) == DialogResult.OK ? RunSolver(SolverMode.ConvertAin, d.FileName) : Task.CompletedTask;
    }

    /// Run or convert through SolverRun (stdin feed) in a fresh scratch dir; SolverJob.Finish copies the outputs of a
    /// successful run to the name chosen in the Save dialog and always deletes the scratch dir. Solver work and cleanup run off the UI thread.
    async Task RunSolver(SolverMode job, string input)
    {
        if (running) return;
        solverExe ??= FindSolver();
        if (solverExe == null) return;
        var b = Path.GetFileNameWithoutExtension(input);
        string verb = job == SolverMode.ConvertAin ? "Convert" : "Run";
        // ATB 3I asked for the output name every time (MainMenu.cs:3072-3081); nothing lands next to the deck unless chosen here.
        string destDir, destBase;
        using (var save = new SaveFileDialog
        {
            Title = "Save results as", OverwritePrompt = true, FileName = b,
            InitialDirectory = Path.GetDirectoryName(Path.GetFullPath(input)),
            Filter = job == SolverMode.ConvertAin ? "ATB free format input (*.lin)|*.lin" : "ATB main output (*.aou)|*.aou",
        })
        {
            if (save.ShowDialog(this) != DialogResult.OK) return;
            destDir = Path.GetDirectoryName(save.FileName)!; destBase = Path.GetFileNameWithoutExtension(save.FileName);
        }
        // Stdin is the one feed mode that needs neither window focus nor Handoff (which writes C:\ATBFIG.SYS and sweeps System32).
        var work = Path.Combine(SolverRun.ShortWorkRoot(), Guid.NewGuid().ToString("N")[..8]);
        var o = new RunOptions { ExePath = solverExe, WorkDir = work, InputBase = b, OutputBase = b, Mode = FeedMode.Stdin, Job = job };
        var sr = new SolverRun();
        using var prog = new RunProgressForm($"ATB {verb.ToLowerInvariant()}: {Path.GetFileName(input)}");
        prog.CancelRequested += () => Task.Run(sr.Cancel);
        sr.Status += prog.Post;
        running = true; MainMenuStrip!.Enabled = false;
        prog.Show(this);
        RunResult r; List<string> outs;
        try
        {
            (r, outs) = await Task.Run(() =>
            {
                RunResult res;
                try
                {
                    Directory.CreateDirectory(work);
                    File.Copy(input, Path.Combine(work, b + SolverJob.InputExt(job)), true);
                    res = sr.Run(o);
                }
                catch { SolverJob.Finish(work, b, destDir, destBase, job, succeeded: false); throw; }   // scratch dir never outlives a throw
                return (res, SolverJob.Finish(work, b, destDir, destBase, job, succeeded: res.Success));
            });
        }
        catch (Exception ex)
        {
            MessageBox.Show(this, ex.Message, $"ATB {verb}", MessageBoxButtons.OK, MessageBoxIcon.Error);
            return;
        }
        finally { running = false; MainMenuStrip!.Enabled = true; prog.Finished = true; prog.Close(); }

        if (r.Error == "cancelled") { status.Text = $"{verb} cancelled."; return; }
        if (!r.Success)
        {
            MessageBox.Show(this, $"Solver failed (exit {r.ExitCode}): {r.Error}\n\n{sr.LogText}", $"ATB {verb}", MessageBoxButtons.OK, MessageBoxIcon.Error);
            return;
        }
        status.Text = $"{verb} finished in {r.ElapsedSec:F1} s: {string.Join(", ", outs.Select(Path.GetFileName))}";
        if (job == SolverMode.ConvertAin) { Open(Path.Combine(destDir, destBase + ".lin")); return; }
        var sa1 = Path.Combine(destDir, destBase + ".sa1");
        if (File.Exists(sa1) && MessageBox.Show(this, "Run finished. Open the animation?", "ATB run", MessageBoxButtons.YesNo) == DialogResult.Yes)
            new AnimationForm(Sa1File.Load(sa1)).Show(this);
    }

    /// Tools > GEBOD: collect the GEBOD V.2 fields, answer the unmodified Gebodv.exe over stdin in a scratch dir
    /// (it finds GEBOD.DAT and writes GEBOD.ain in the folder named by C:\ATBFIG.SYS), then merge GEBOD.ain's body
    /// into the open deck (a new empty deck when none is open) at the chosen placement, as ATB 3I does.
    async Task Gebod(GebodPlacement? preset = null)
    {
        if (running) return;
        var target = deck ?? GebodMerge.NewDeck();
        int bodies = GebodMerge.BodyStarts(target).Count;
        using var f = new GebodForm(bodies, preset);
        if (f.ShowDialog(this) != DialogResult.OK || f.Request == null) return;
        var place = f.Placement;
        if (preset == null && place.Mode == GebodMode.Replace && !ConfirmReplace()) return;   // Body Summary asked Body.cs:1049 already
        var req = f.Request; var dims = f.BodyDims; string? ain = null;
        var exe = Path.Combine(AppContext.BaseDirectory, "Gebodv.exe");
        var work = Path.Combine(SolverRun.ShortWorkRoot(), "gebod");
        var o = new RunOptions { ExePath = exe, WorkDir = work, InputBase = "GEBOD", OutputBase = "GEBOD", Mode = FeedMode.Stdin, Job = SolverMode.ConvertAin,
            Answers = Atb.Core.Solver.Gebod.Answers(req), ResultFile = "GEBOD.ain", NoOutputAbortSec = 30, TimeoutSec = 60 };
        var sr = new SolverRun();
        using var prog = new RunProgressForm("GEBOD: " + req.Description);
        prog.CancelRequested += () => Task.Run(sr.Cancel);
        sr.Status += prog.Post;
        running = true; MainMenuStrip!.Enabled = false;
        prog.Show(this);
        RunResult r;
        const string fig = @"C:\ATBFIG.SYS";
        try
        {
            r = await Task.Run(() =>
            {
                if (Directory.Exists(work)) Directory.Delete(work, true);
                Directory.CreateDirectory(work);
                File.Copy(Path.Combine(AppContext.BaseDirectory, "GEBOD.DAT"), Path.Combine(work, "GEBOD.DAT"));
                if (dims != null) File.WriteAllText(Path.Combine(work, req.DimensionFile!), Atb.Core.Solver.Gebod.DimensionFileText(dims));
                // Gebodv.exe opens C:\ATBFIG.SYS (status OLD, no ERR=) at start-up; keep whatever ATB 3I left there.
                byte[]? old = File.Exists(fig) ? File.ReadAllBytes(fig) : null;
                var tmp = Path.Combine(Environment.GetEnvironmentVariable("windir") ?? @"C:\Windows", "Temp");
                File.WriteAllText(fig, Atb.Core.Solver.Gebod.AtbFig(work, tmp));
                try { return sr.Run(o); }
                finally { if (old != null) File.WriteAllBytes(fig, old); else File.Delete(fig); }
            });
            if (r.Success) ain = File.ReadAllText(Path.Combine(work, "GEBOD.ain"));
        }
        catch (Exception ex)
        {
            var hint = ex is UnauthorizedAccessException ? "\n\nGebodv.exe reads C:\\ATBFIG.SYS; writing it may need ATB to run as administrator." : "";
            MessageBox.Show(this, ex.Message + hint, "GEBOD", MessageBoxButtons.OK, MessageBoxIcon.Error);
            return;
        }
        finally { running = false; MainMenuStrip!.Enabled = true; prog.Finished = true; prog.Close(); }
        try { Directory.Delete(work, true); } catch { }
        if (r.Error == "cancelled") { status.Text = "GEBOD cancelled."; return; }
        if (!r.Success) { MessageBox.Show(this, $"GEBOD failed (exit {r.ExitCode}): {r.Error}\n\n{sr.LogText}", "GEBOD", MessageBoxButtons.OK, MessageBoxIcon.Error); return; }
        // The grid stayed editable during the run: the placement chosen against `bodies` bodies may no longer mean the same body.
        if (GebodMerge.BodyStarts(target).Count is var now && now != bodies)
        { OfferSaveAin(ain!, $"The deck had {bodies} bodies when GEBOD started and has {now} now, so the chosen placement is out of date. The deck is unchanged."); return; }
        Deck merged;
        // Works on a copy: a failure leaves the open deck as it was.
        // ATB 3I asks only Body.cs:1049 (ConfirmReplace, before the run); ATBUpdate drops surplus refs without a list.
        try { merged = GebodMerge.Merge(target, ain!, place, _ => true); }
        catch (Exception ex) { OfferSaveAin(ain!, "GEBOD output could not be merged: " + ex.Message); return; }
        if (deck == null) { deckPath = null; bodyClip = null; }
        deck = merged; dirty = true;
        ShowDeck();
    }

    Bodies.Copied? bodyClip;   // Body Summary's Copy Body (3I's clipboard); cleared when another deck is opened

    /// Model > Body... > Body Summary...: ATB 3I's Body Editing Form. Its operations apply as they are done, as 3I's do;
    /// its GEBOD buttons close it and open the GEBOD form at the placement it chose.
    async Task BodySummary()
    {
        if (running || deck == null) return;
        using var f = new BodyForm(deck, bodyClip);
        f.ShowDialog(this);
        bodyClip = f.Clip;
        if (f.Changed) { deck = f.Deck; dirty = true; ShowDeck(); }
        if (f.Gebod is { } p) await Gebod(p);
    }

    void OpenSa1()
    {
        using var d = new OpenFileDialog { Filter = "ATB animation (*.sa1)|*.sa1;*.SA1", InitialDirectory = deckPath == null ? null : Path.GetDirectoryName(deckPath) };
        if (d.ShowDialog(this) != DialogResult.OK) return;
        try { new AnimationForm(Sa1File.Load(d.FileName)).Show(this); }
        catch (Exception ex) { MessageBox.Show(this, ex.Message, "Cannot open .sa1", MessageBoxButtons.OK, MessageBoxIcon.Error); }
    }
}
