using System.Globalization;
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
    string? solverExe;
    readonly ListBox cards = new() { Dock = DockStyle.Fill, IntegralHeight = false };
    readonly DataGridView grid = new()
    {
        Dock = DockStyle.Fill, AllowUserToAddRows = false, AllowUserToDeleteRows = false,
        EditMode = DataGridViewEditMode.EditOnKeystrokeOrF2, AutoSizeColumnsMode = DataGridViewAutoSizeColumnsMode.AllCells,
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
        var run = new ToolStripMenuItem("&Run");
        run.DropDownItems.Add(Item("&Run ATB", Keys.F5, async () => await RunSolver()));
        run.DropDownItems.Add("Choose &solver executable...", null, (_, _) => solverExe = PickSolver());
        var view = new ToolStripMenuItem("&View");
        view.DropDownItems.Add("&Animation (.sa1)...", null, (_, _) => OpenSa1());
        menu.Items.AddRange([file, run, view]);
        MainMenuStrip = menu;

        var split = new SplitContainer { Dock = DockStyle.Fill, SplitterDistance = 220 };
        split.Panel1.Controls.Add(cards); split.Panel2.Controls.Add(grid);
        var bar = new StatusStrip(); bar.Items.Add(status);
        Controls.Add(split); Controls.Add(bar); Controls.Add(menu);

        cards.SelectedIndexChanged += (_, _) => { if (cards.SelectedItem is string c) ShowCard(c); };
        grid.CellValueChanged += (_, e) => OnCellChanged(e.RowIndex, e.ColumnIndex);
        FormClosing += (_, e) => { if (dirty && !ConfirmDiscard()) e.Cancel = true; };
        if (path != null) Open(path);
    }

    static ToolStripMenuItem Item(string text, Keys keys, Action act) => new(text, null, (_, _) => act()) { ShortcutKeys = keys };

    public void Open(string path)
    {
        deck = Deck.Load(path); deckPath = path; dirty = false;
        Text = $"ATB — {Path.GetFileName(path)}";
        cards.Items.Clear();
        foreach (var c in deck.Lines.Select(l => l.Card).Where(c => c != "").Distinct()) cards.Items.Add(c);
        status.Text = $"{deck.Title}: {deck.SegmentCount} segments, {deck.JointCount} joints, {deck.Lines.Count} lines";
        if (cards.Items.Count > 0) cards.SelectedIndex = 0;
    }

    void ShowCard(string card)
    {
        if (deck == null) return;
        var lines = deck.Cards(card).ToList();
        int n = lines.Count == 0 ? 0 : lines.Max(l => l.Count);
        suppress = true; grid.SuspendLayout(); grid.Columns.Clear(); grid.Rows.Clear();
        for (int i = 0; i < n; i++)
            grid.Columns.Add(new DataGridViewTextBoxColumn { HeaderText = CardSchema.Header(card, i), SortMode = DataGridViewColumnSortMode.NotSortable });
        foreach (var l in lines)
        {
            var r = grid.Rows[grid.Rows.Add()]; r.Tag = l;
            for (int i = 0; i < l.Count; i++) r.Cells[i].Value = l.Str(i);
        }
        grid.ResumeLayout(); suppress = false;
    }

    void OnCellChanged(int row, int col)
    {
        if (suppress || row < 0 || grid.Rows[row].Tag is not DeckLine line || col >= line.Count) return;
        var old = line.Tokens[col];
        var v = grid[col, row].Value?.ToString() ?? "";
        string token;
        if (old.StartsWith('"')) token = "\"" + v.Replace('"', '\'') + "\"";
        else if (double.TryParse(v, NumberStyles.Float, CultureInfo.InvariantCulture, out _)) token = v.Trim();
        else
        {
            status.Text = $"'{v}' is not a number; value reverted.";
            suppress = true; grid[col, row].Value = line.Str(col); suppress = false; return;
        }
        if (token == old) return;
        line.Set(col, token); dirty = true;
        status.Text = $"{line.Label} field {col + 1} = {v}";
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
