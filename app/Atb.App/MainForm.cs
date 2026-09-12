using System.IO;
using Atb.App.Solver;
using Atb.App.Viewer;
using Atb.Core.Cards;
using Atb.Core.Lin;
using Atb.Core.Sa1;

namespace Atb.App;

/// Main window: card list on the left, one grid per card on the right, File/Run/View menus.
public sealed class MainForm : Form
{
    Deck? deck; string? deckPath; bool dirty, suppress;
    CardSchema.Screen? screen; Dictionary<(Kind, int), string> refs = new();
    string? solverExe;
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
        file.DropDownItems.Add(Item("&Open...", Keys.Control | Keys.O, OpenDialog));
        file.DropDownItems.Add(Item("&Save", Keys.Control | Keys.S, Save));
        file.DropDownItems.Add("Save &As...", null, (_, _) => SaveAs());
        file.DropDownItems.Add(new ToolStripSeparator());
        file.DropDownItems.Add("E&xit", null, (_, _) => Close());
        // Ctrl+Shift so plain Ctrl+C/V keep working inside a cell being edited.
        var edit = new ToolStripMenuItem("&Edit");
        edit.DropDownItems.Add(Item("&Add row (copy of selected)", Keys.Control | Keys.Insert, AddRow));
        edit.DropDownItems.Add(Item("&Delete rows", Keys.Control | Keys.Delete, DeleteRows));
        edit.DropDownItems.Add(Item("&Copy rows", Keys.Control | Keys.Shift | Keys.C, CopyRows));
        edit.DropDownItems.Add(Item("&Paste rows", Keys.Control | Keys.Shift | Keys.V, PasteRows));
        var run = new ToolStripMenuItem("&Run");
        run.DropDownItems.Add(Item("&Run ATB", Keys.F5, async () => await RunSolver()));
        run.DropDownItems.Add("Choose &solver executable...", null, (_, _) => solverExe = PickSolver());
        var view = new ToolStripMenuItem("&View");
        view.DropDownItems.Add("&Animation (.sa1)...", null, (_, _) => OpenSa1());
        menu.Items.AddRange([file, edit, run, view]);
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
        FormClosing += (_, e) => { if (dirty && !ConfirmDiscard()) e.Cancel = true; };
        if (path != null) Open(path);
    }

    static ToolStripMenuItem Item(string text, Keys keys, Action act) => new(text, null, (_, _) => act()) { ShortcutKeys = keys };

    public void Open(string path)
    {
        deck = Deck.Load(path); deckPath = path; dirty = false;
        Text = $"ATB — {Path.GetFileName(path)}";
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

    // ponytail: "add" duplicates the selected row as its template — a blank-from-schema row can come with the renumbering item.
    void AddRow()
    {
        if (SelectedRows().LastOrDefault() is not { } row) { status.Text = "Select a row to copy as the new row."; return; }
        InsertLines(row.OfType<DeckLine>().Select(l => new DeckLine(l.Tokens, l.Label)).ToList(), "Add row");
    }

    void DeleteRows()
    {
        if (deck == null || screen == null) return;
        var rows = SelectedRows();
        if (rows.Length == 0) return;
        grid.EndEdit();
        foreach (var l in rows.SelectMany(r => r.OfType<DeckLine>())) deck.Lines.Remove(l);
        dirty = true; ShowScreen(screen);
        status.Text = $"Deleted {rows.Length} row(s). Count cards (B.1, D.1.a, ...) are not updated.";
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
        InsertLines(res.Lines, "Paste");
        if (res.Rejected.Count > 0)
            MessageBox.Show(this, "Rows not pasted:\n" + string.Join("\n", res.Rejected.Take(20)), "Paste", MessageBoxButtons.OK, MessageBoxIcon.Warning);
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
        grid.EndEdit(); deck.Save(deckPath); dirty = false; status.Text = $"Saved {deckPath}";
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

    async Task RunSolver()
    {
        if (deck == null || deckPath == null) { status.Text = "Open a deck first."; return; }
        if (dirty) Save();
        solverExe ??= FindSolver();
        if (solverExe == null) return;
        var b = Path.GetFileNameWithoutExtension(deckPath);
        var work = Path.Combine(SolverRun.ShortWorkRoot(), DateTime.Now.ToString("HHmmss"));
        Directory.CreateDirectory(work);
        File.Copy(deckPath, Path.Combine(work, b + ".lin"), true);
        var o = new RunOptions { ExePath = solverExe, WorkDir = work, InputBase = b, OutputBase = b, Mode = FeedMode.Stdin };
        var sr = new SolverRun();
        sr.Status += s => BeginInvoke(() => status.Text = s);
        UseWaitCursor = true;
        var r = await Task.Run(() => sr.Run(o));
        UseWaitCursor = false;
        if (!r.Success)
        {
            MessageBox.Show(this, $"Solver failed (exit {r.ExitCode}): {r.Error}\n\n{sr.LogText}", "ATB run", MessageBoxButtons.OK, MessageBoxIcon.Error);
            return;
        }
        var dest = Path.GetDirectoryName(deckPath)!;
        foreach (var f in r.Outputs) File.Copy(f, Path.Combine(dest, Path.GetFileName(f)), true);
        try { Directory.Delete(work, true); } catch { /* scratch */ }
        status.Text = $"Run finished in {r.ElapsedSec:F1} s: {string.Join(", ", r.Outputs.Select(Path.GetFileName))}";
        var sa1 = Path.Combine(dest, b + ".sa1");
        if (File.Exists(sa1) && MessageBox.Show(this, "Run finished. Open the animation?", "ATB run", MessageBoxButtons.YesNo) == DialogResult.Yes)
            new AnimationForm(Sa1File.Load(sa1)).Show(this);
    }

    void OpenSa1()
    {
        using var d = new OpenFileDialog { Filter = "ATB animation (*.sa1)|*.sa1;*.SA1", InitialDirectory = deckPath == null ? null : Path.GetDirectoryName(deckPath) };
        if (d.ShowDialog(this) != DialogResult.OK) return;
        try { new AnimationForm(Sa1File.Load(d.FileName)).Show(this); }
        catch (Exception ex) { MessageBox.Show(this, ex.Message, "Cannot open .sa1", MessageBoxButtons.OK, MessageBoxIcon.Error); }
    }
}
