// Model > Function > General FDF... / Joint Stiffness... / Wind Force...: ATB 3I's GenList over tables E1E2, E7ac and E6ab
// (decomp ATB3I/GenList.cs, ATBGrid.cs cell rules), the editors its Edit button opens — FDFData (polynomial / tabular
// force deflection data), JntFData (joint stiffness data), StdTable E6d (wind force time history) — and the Data Plot.
// Card math is Atb.Core.Cards.Functions.
using Atb.Core.Cards;
using Atb.Core.Lin;
using K = Atb.Core.Cards.Functions.Kind;

namespace Atb.App;

public sealed class FunctionListForm : Form
{
    const string NoRow = "No record/row selected for this operation.", OneRow = "Only one record can be selected at each time.";
    const string Yn = "You can't undo this operation once it proceeds.  Continue?";

    /// The deck after the list's operations: 3I writes each one to its database at once, so closing keeps them.
    public Deck Deck { get; }
    public bool Changed => Deck.Write() != original;
    readonly string original;
    readonly K kind;
    readonly string[] cols;
    readonly ListBox? which;
    bool loading;

    // GenList layout: grid (0,0) 640x333, 96x24 buttons at x 248 / 360 / 472, rows y 341 / 381, client 640x418.
    readonly DataGridView grid = new()
    {
        Location = new Point(0, 0), Size = new Size(640, 333), AllowUserToAddRows = false, AllowUserToDeleteRows = false,
        SelectionMode = DataGridViewSelectionMode.RowHeaderSelect, RowHeadersWidth = 24, EditMode = DataGridViewEditMode.EditOnKeystrokeOrF2,
    };

    public FunctionListForm(Deck deck, K kind)
    {
        Deck = Deck.Parse(deck.Write());
        original = Deck.Write();
        this.kind = kind;
        Text = kind switch { K.Fdf => "Force Deflection Function Definition", K.Joint => "Joint Stiffness Function Definition", _ => "Wind Force Function Definition" };
        ClientSize = new Size(kind == K.Wind ? 744 : 640, 418); FormBorderStyle = FormBorderStyle.FixedDialog;
        MaximizeBox = MinimizeBox = false; StartPosition = FormStartPosition.CenterParent;
        if (kind == K.Wind) grid.Width = 744;
        cols = kind switch
        {
            K.Fdf => ["FunctionID", "Title", "D3", "D4", "F1 Type", "F2 Type"],
            K.Joint => ["FunctionID", "Title", "NTheta", "NPhi", "Type"],
            _ => ["FunctionID", "Title", "Specific Heats", "Sound Speed", "Absolute Pressure", "Velocity SegID", "Reference SegID"],
        };
        // ATBGrid E6ab: Velocity / Reference SegID are dropdowns of the deck's segments (0 = none, then bodies and vehicles).
        string[] segs = [.. Enumerable.Range(0, Deck.SegmentCount + 1).Select(i => i.ToString())
            .Union(Vehicles.Blocks(Deck).Select(v => Vehicles.SegId(Deck, v).ToString()))
            .Union(Functions.Winds(Deck).SelectMany(w => new[] { Tok(w.B, 3), Tok(w.B, 4) }).Where(t => t.Length > 0))];
        foreach (var h in cols)
        {
            string[]? items = h switch
            {
                "F1 Type" => Functions.F1Types, "F2 Type" => Functions.F2Types, "Type" => ["Tabular", "Polynomial"],
                "Velocity SegID" or "Reference SegID" => segs, _ => null,
            };
            DataGridViewColumn c = items == null ? new DataGridViewTextBoxColumn() : new DataGridViewComboBoxColumn { DisplayStyle = DataGridViewComboBoxDisplayStyle.ComboBox, FlatStyle = FlatStyle.Flat };
            if (c is DataGridViewComboBoxColumn cb) cb.Items.AddRange(items!);
            c.Name = c.HeaderText = h; c.SortMode = DataGridViewColumnSortMode.NotSortable; c.Width = h == "Title" ? 170 : 75;
            grid.Columns.Add(c);
        }
        grid.CurrentCellDirtyStateChanged += (_, _) => { if (grid.CurrentCell is DataGridViewComboBoxCell) grid.CommitEdit(DataGridViewDataErrorContexts.Commit); };
        grid.CellValueChanged += (_, e) => { if (!loading && e.RowIndex >= 0) BeginInvoke(() => CellChanged(e.RowIndex, e.ColumnIndex)); };
        grid.DataError += (_, e) => e.ThrowException = false;
        Controls.Add(grid);
        Btn(248, 341, "Insert", Insert); Btn(360, 341, "Copy", Copy); Btn(472, 341, kind == K.Wind ? "Time Hist" : "Edit", Edit);
        Btn(248, 381, "Delete", Delete); Btn(360, 381, "Paste", Paste); Btn(472, 381, "Save && Exit", Close);
        if (kind == K.Fdf)
        {
            Controls.Add(new Label { Text = "Editing Function", Location = new Point(128, 349), AutoSize = true, ForeColor = Color.Green });
            // GenList lstFunctions: Arial 8.25 bold Navy, ItemHeight 14 — both F1 and F2 in view.
            which = new ListBox
            {
                Location = new Point(128, 365), Size = new Size(96, 32), AccessibleName = "Editing Function", IntegralHeight = false,
                Font = new Font("Arial", 8.25f, FontStyle.Bold), ForeColor = Color.Navy, DrawMode = DrawMode.OwnerDrawFixed, ItemHeight = 14,
            };
            which.DrawItem += (_, e) =>
            {
                if (e.Index < 0) return;
                e.DrawBackground();
                TextRenderer.DrawText(e.Graphics, which.Items[e.Index].ToString(), e.Font, e.Bounds,
                    (e.State & DrawItemState.Selected) != 0 ? SystemColors.HighlightText : Color.Navy, TextFormatFlags.Left | TextFormatFlags.VerticalCenter);
                e.DrawFocusRectangle();
            };
            which.Items.AddRange(["Function F1", "Function F2"]);
            which.SelectedIndex = 0;
            Controls.Add(which);
        }
        Fill();
        Shown += (_, _) => grid.ClearSelection();
    }

    void Btn(int x, int y, string text, Action act)
    {
        var b = new Button { Text = text, Location = new Point(x, y), Size = new Size(96, 24) };
        b.Click += (_, _) => act();
        Controls.Add(b);
    }

    List<DeckLine> Heads => Functions.Heads(Deck, kind);

    void Fill()
    {
        loading = true;
        grid.Rows.Clear();
        switch (kind)
        {
            case K.Fdf:
                foreach (var f in Functions.Fdfs(Deck))
                    grid.Rows.Add(f.Id.ToString(), f.Title, Tok(f.E2, 3), Tok(f.E2, 4), Functions.F1Types[f.F1], Functions.F2Types[f.F2]);
                break;
            case K.Joint:
                foreach (var j in Functions.Joints(Deck))
                    grid.Rows.Add(j.Id.ToString(), j.Title, j.NTheta.ToString(), j.NPhi.ToString(), j.Type < 0 ? "Polynomial" : "Tabular");
                break;
            default:
                foreach (var w in Functions.Winds(Deck))
                    grid.Rows.Add([w.Id.ToString(), w.Title, .. Enumerable.Range(0, 5).Select(i => Tok(w.B, i))]);
                break;
        }
        foreach (DataGridViewRow r in grid.Rows)   // a FunctionID <= -1 is LightCoral (GenList.grdDB_FetchCellStyle)
            if (int.TryParse(r.Cells[0].Value?.ToString(), out var id) && id <= -1) r.Cells[0].Style.BackColor = Color.LightCoral;
        loading = false;
    }

    static string Tok(DeckLine l, int i) => i < l.Count ? l.Tokens[i] : "";

    void Warn(string text, string title) => MessageBox.Show(this, text, title, MessageBoxButtons.OK, MessageBoxIcon.Exclamation);
    bool Ask(string text, string title) => MessageBox.Show(this, text, title, MessageBoxButtons.YesNo, MessageBoxIcon.Question) == DialogResult.Yes;
    /// ATBGrid.cs:2523-2528 / :2728-2733: a non-numeric FunctionID / NTheta / NPhi / Type / Specific Heats.
    void FormatError() => MessageBox.Show(this, Functions.FormatError, Functions.FormatErrorTitle, MessageBoxButtons.OK, MessageBoxIcon.Error);

    List<int> Selected() => grid.SelectedRows.Cast<DataGridViewRow>().Select(r => r.Index)
        .Concat(grid.SelectedRows.Count == 0 && grid.SelectedCells.Count > 0 ? grid.SelectedCells.Cast<DataGridViewCell>().Select(c => c.RowIndex) : [])
        .Distinct().OrderBy(i => i).ToList();

    void Reselect(int row)
    {
        grid.ClearSelection();
        if (row >= 0 && row < grid.Rows.Count) grid.Rows[row].Selected = true;
    }

    /// ATBGrid cell rules (ATBGrid.cs:2183-2777): every change is confirmed or refused, then the list is reread.
    void CellChanged(int row, int col)
    {
        if (row >= Heads.Count) return;
        var text = grid[col, row].Value?.ToString() ?? "";
        var head = Heads[row];
        string name = cols[col];
        if (name == "FunctionID")
        {
            var err = Functions.SetId(Deck, head, text);
            if (err == Functions.FormatError) FormatError();
            else if (err != null) Warn(err, "Change Function ID");
        }
        else if (name == "Title") Deck.Edit(head, 1, text);
        else if (kind == K.Fdf) FdfCell(Functions.Fdfs(Deck)[row], name, text);
        else if (kind == K.Joint) JointCell(Functions.Joints(Deck)[row], name, text);
        else WindCell(Functions.Winds(Deck)[row], col - 2, text);
        Fill();
        Reselect(row);
    }

    void FdfCell(Functions.Fdf f, string name, string text)
    {
        if (name is "D3" or "D4") { if (Deck.Edit(f.E2, name == "D3" ? 3 : 4, text) != null) Warn("Input must be a number!", "Input Warning"); return; }
        const string T = "Change Function Type";
        double d1 = Math.Abs(f.D(1)), d2 = Math.Abs(f.D(2));
        string N(double v) => DeckLine.FormatNum(v);
        if (name == "F1 Type")
        {
            int t = Array.IndexOf(Functions.F1Types, text);
            if (t < 0 || t == f.F1) return;
            if (t == 2 && f.F2 == 2)
            {
                MessageBox.Show(this, "Sub-function F1 can't be changed to tabular type because sub-function F2 is in\r\n tabular format already.  You can copy F2's data into F1 and then delete F2.", T, MessageBoxButtons.OK, MessageBoxIcon.Information);
                return;
            }
            string msg = t switch
            {
                0 => "Change F1's type to constant will clear entire function data and reset \r\nD1 and D2 to zeros.  " + Yn,
                1 => "Change F1 type to polynomial will clear all existing F1 data and reset\r\nD1 to" + N(d1 == 0 ? 1 : d1) + " " + Yn,
                _ => "Change F1 type to tabular will clear all existing F1 data and reset\r\nD1 to" + N(d1 == 0 ? -1 : -d1) + " " + Yn,
            };
            if (Ask(msg, T)) Functions.SetF1Type(Deck, f, t);
        }
        else
        {
            int t = Array.IndexOf(Functions.F2Types, text);
            if (t < 0 || t == f.F2 || f.F1 == 0) return;   // F1 constant: F2 stays None (STANDARDS.md divergence)
            if (t == 2 && f.F1 == 2)
            {
                MessageBox.Show(this, "Sub-function F2 can't be changed to tabular type because sub-function F1 is in\r\n tabular format already.  You can copy F2's data into F1 and then delete F2", T, MessageBoxButtons.OK, MessageBoxIcon.Information);
                return;
            }
            double n = d2 == 0 ? d1 + 1 : d2;
            string msg = t switch
            {
                0 => "Change F2's type to none will clear all F2 data and reset \r\nD2 to zero.  " + Yn,
                1 => "Change F2 type to polynomial will clear all existing F2 data and reset\r\nD2 to" + N(n) + " " + Yn,
                _ => "Change F2 type to tabular will clear all existing F2 data and reset\r\nD2 to" + N(-n) + " " + Yn,
            };
            if (Ask(msg, T)) Functions.SetF2Type(Deck, f, t);
        }
    }

    void JointCell(Functions.Joint j, string name, string text)
    {
        int nt = j.NTheta, np = j.NPhi, type = j.Type;
        if (name == "Type") type = text == "Polynomial" ? -1 : 1;
        else if (!int.TryParse(text.Trim(), out var v)) { FormatError(); return; }
        else if (name == "NTheta") { if (v < 2) { Warn("NTheta can't be less than 2!", "Change NTheta Value"); return; } nt = v; }
        else { if (v < 1) { Warn("NPhi can't be less than 1!", "Change NPhi Value"); return; } np = v; }
        if ((nt, np, type) == (j.NTheta, j.NPhi, j.Type)) return;
        string msg = name == "Type" ? "Change type will reset function data to zeros.\r\n " + Yn : "Change " + name + " value will reset function data to zeros.\r\n " + Yn;
        if (Ask(msg, name == "NTheta" ? "Change NTheta Value" : "Change NPhi Value")) Functions.SetJointShape(Deck, j, nt, np, type);
    }

    void WindCell(Functions.Wind w, int tok, string text)
    {
        if (tok == 0 && double.TryParse(text, System.Globalization.NumberStyles.Float, System.Globalization.CultureInfo.InvariantCulture, out var sh))
        {
            if (w.B.Num(0) == 0 && sh != 0 && !Ask("Change Specific Heats value from zero to other value will reset function\r\n type from time dependent to velocity dependent and clear all time history\r\n data.  You can't undo this operation once it proceeds.  Continue?", "Change Specific Heats Value")) return;
            Functions.SetSpecificHeats(Deck, w, text);
            return;
        }
        if (tok == 0) { FormatError(); return; }
        if (Deck.Edit(w.B, tok, text) != null) Warn("Input must be a number!", "Input Warning");
    }

    void Insert()
    {
        var sel = Selected();   // none selected: append at the end, as 3I's add-new row (an empty list's first function)
        string msg = kind switch
        {
            K.Fdf => "You are about to insert a blank constant value type force deflection function.\r\nYou can't undo this operation once it proceeds. Continue?",
            K.Joint => "You are about to insert a blank tabular type joint stiffness function.\r\nYou can't undo this operation once it proceeds. Continue?",
            _ => "You are about to insert a blank record.\r\nYou can't undo this operation once it proceeds. Continue?",
        };
        if (!Ask(msg, "Insert Data")) return;
        Functions.Insert(Deck, kind, sel.Count > 0 ? Heads[sel[0]] : null);
        Fill(); Reselect(sel.Count > 0 ? sel[0] : grid.Rows.Count - 1);
    }

    void Delete()
    {
        var sel = Selected();
        if (sel.Count == 0) { Warn(NoRow, "Delete Operation Warning"); return; }
        if (!Ask("You are about to delete the selected item(s). You can't\r\nundo this operation once it proceeds. Continue?", "Delete Data")) return;
        var heads = Heads;
        Functions.Delete(Deck, kind, sel.Select(i => heads[i]));
        Fill();
    }

    void Copy()
    {
        var sel = Selected();
        if (sel.Count == 0) { Warn(NoRow, "Copy Operation Warning"); return; }
        var heads = Heads;
        Clipboard.SetText(Functions.CopyText(Deck, kind, sel.Select(i => heads[i])));
    }

    void Paste()
    {
        var sel = Selected();
        if (grid.Rows.Count > 0 && sel.Count == 0) { Warn(NoRow, "Paste Operation Warning"); return; }
        if (!Ask("You are about to paste copied item(s). You can't \r\nundo this operation once it proceeds. Continue?", "Paste Data")) return;
        var text = Clipboard.ContainsText() ? Clipboard.GetText() : "";
        bool before = false; DeckLine? at = null;
        if (grid.Rows.Count > 0)
        {
            var a = MessageBox.Show(this, "Paste data before the selected row?\r\nClick NO button will paste data after the selected row.", "Paste Rows", MessageBoxButtons.YesNoCancel, MessageBoxIcon.Question);
            if (a == DialogResult.Cancel) return;
            before = a == DialogResult.Yes;
            at = Heads[before ? sel[0] : sel[^1]];
        }
        if (Functions.Paste(Deck, kind, text, at, before) < 0) { Warn("Clipboard doesn't contain any data.", "Paste Data Operation Warning"); return; }
        Fill();
    }

    /// GenList.btnEdit: FDFData (or the constant's InputBox), the E6d time history table, or JntFData.
    void Edit()
    {
        var sel = Selected();
        if (sel.Count == 0) { Warn(NoRow, "Edit Operation Warning"); return; }
        if (sel.Count > 1) { Warn(OneRow, "Edit Operation Warning"); return; }
        int row = sel[0];
        Form? ed = null;
        switch (kind)
        {
            case K.Fdf:
                var f = Functions.Fdfs(Deck)[row];
                int sub = which!.SelectedIndex;
                if (sub == 1 && f.F2 == 0) { Warn("F2 has not been setup yet.", "Edit Function Operation Warning"); return; }
                if (sub == 0 && f.F1 == 0)
                {
                    var v = InputBox.Show(this, "Function No." + f.Id + ": " + f.Title + "\r\nConstant value (D2):", "Constant Force Deflection Function", f.E2.Count > 2 ? f.E2.Tokens[2] : "0");
                    if (v != null && v.Length > 0 && Deck.Edit(f.E2, 2, v) != null) Warn("Input must be a number!", "Input Warning");
                    Fill(); Reselect(row);
                    return;
                }
                ed = new FdfDataForm(Deck, row, sub);
                break;
            case K.Wind:
                var w = Functions.Winds(Deck)[row];
                if (w.B.Count > 0 && w.B.Num(0) != 0)
                {
                    Warn("This function type is velocity dependent. Reset it to time dependent (Specific Heats = 0)\r\n before trying to add any wind force time history data.", "Edit Function Operation Warning");
                    return;
                }
                ed = new WindTimeHistForm(Deck, row);
                break;
            default:
                ed = new JntFDataForm(Deck, row);
                break;
        }
        using (ed)
            if (ed.ShowDialog(this) == DialogResult.OK && ed is IFunctionEditor fe)
            {
                Deck.Lines.Clear(); Deck.Lines.AddRange(fe.Result.Lines);
            }
        Fill(); Reselect(row);
    }
}

interface IFunctionEditor { Deck Result { get; } }

/// Microsoft.VisualBasic.Interaction.InputBox's layout: prompt, one text box, OK / Cancel. Null when cancelled.
static class InputBox
{
    public static string? Show(IWin32Window owner, string prompt, string title, string value)
    {
        using var f = new Form { Text = title, ClientSize = new Size(360, 120), FormBorderStyle = FormBorderStyle.FixedDialog, MaximizeBox = false, MinimizeBox = false, StartPosition = FormStartPosition.CenterParent };
        var t = new TextBox { Location = new Point(8, 88), Size = new Size(344, 20), Text = value, AccessibleName = "Value" };
        var ok = new Button { Text = "OK", Location = new Point(280, 8), Size = new Size(72, 24), DialogResult = DialogResult.OK };
        var cancel = new Button { Text = "Cancel", Location = new Point(280, 40), Size = new Size(72, 24), DialogResult = DialogResult.Cancel };
        f.Controls.AddRange([new Label { Text = prompt, Location = new Point(8, 8), Size = new Size(264, 72) }, t, ok, cancel]);
        f.AcceptButton = ok; f.CancelButton = cancel;
        return f.ShowDialog(owner) == DialogResult.OK ? t.Text : null;
    }
}

/// What FDFData / JntFData / StdTable share: a working copy of the deck (OK keeps it, Cancel drops it), a grid, the plot.
public abstract class FunctionEditor : Form, IFunctionEditor
{
    public Deck Result { get; }
    protected readonly DataGridView Grid = new()
    {
        RowHeadersWidth = 24, SelectionMode = DataGridViewSelectionMode.CellSelect, MultiSelect = false, EditMode = DataGridViewEditMode.EditOnKeystrokeOrF2,
    };
    DataPlotForm? plot;

    protected FunctionEditor(Deck src, string title, Size client)
    {
        Result = Deck.Parse(src.Write());
        Text = title; ClientSize = client; FormBorderStyle = FormBorderStyle.FixedDialog;
        MaximizeBox = MinimizeBox = false; StartPosition = FormStartPosition.CenterParent;
        FormClosed += (_, _) => plot?.Close();
    }

    protected void Warn(string text, string title) => MessageBox.Show(this, text, title, MessageBoxButtons.OK, MessageBoxIcon.Exclamation);

    protected void Column(string h, bool readOnly = false)
    {
        var i = Grid.Columns.Add(h.Replace(" ", ""), h);
        Grid.Columns[i].SortMode = DataGridViewColumnSortMode.NotSortable;
        Grid.Columns[i].ReadOnly = readOnly;
        if (readOnly) Grid.Columns[i].DefaultCellStyle.BackColor = Color.Cyan;
    }

    /// Committed rows of the grid (the new-row placeholder skipped), columns from `from`.
    protected List<string[]> Rows(int from = 0) => Grid.Rows.Cast<DataGridViewRow>().Where(r => !r.IsNewRow)
        .Select(r => Enumerable.Range(from, Grid.Columns.Count - from).Select(c => r.Cells[c].Value?.ToString()?.Trim() ?? "").ToArray()).ToList();

    protected void Buttons(int y, params (string Text, int X, int W, Action? Act, DialogResult R)[] bs)
    {
        foreach (var b in bs)
        {
            var btn = new Button { Text = b.Text, Location = new Point(b.X, y), Size = new Size(b.W, 24) };
            if (b.Act != null) btn.Click += (_, _) => b.Act();
            if (b.R == DialogResult.Cancel) { btn.DialogResult = DialogResult.Cancel; CancelButton = btn; }
            Controls.Add(btn);
        }
    }

    protected void Plot(double[] x, double[] y, string series, string xAxis, string yAxis) => Plot([new DataPlotForm.Series(x, y, series)], xAxis, yAxis);

    protected void Plot(List<DataPlotForm.Series> series, string xAxis, string yAxis)
    {
        if (plot == null || plot.IsDisposed) { plot = new DataPlotForm(); plot.Show(this); }
        plot.SetData(series, xAxis, yAxis);
        plot.Activate();
    }

    protected void Ok(string? error)
    {
        if (error != null) { Warn(error, "Input Warning"); return; }
        DialogResult = DialogResult.OK;
    }
}

/// FDFData "Polynomial / Tabular FDF Data Definition" for sub-function F1 (D0, |D1|) or F2 (|D2|). Client 280x389.
public sealed class FdfDataForm : FunctionEditor
{
    readonly Functions.Fdf f;
    readonly int sub;
    readonly TextBox t1; readonly TextBox? t2;

    public FdfDataForm(Deck src, int index, int sub) : base(src, "", new Size(280, 389))
    {
        f = Functions.Fdfs(Result)[index];
        this.sub = sub;
        var s = f.Subs[sub];
        Text = s.Type == 1 ? "Polynomial FDF Data Definition" : "Tabular FDF Data Definition";
        Controls.Add(new Label { Text = "No. " + f.Id + ": " + f.Title, Location = new Point(8, 8), AutoSize = true, ForeColor = Color.DarkRed, Font = new Font(Font, FontStyle.Bold) });
        string abs(int i) => f.E2.Count > i ? f.E2.Tokens[i].TrimStart('-') : "0";
        if (sub == 0)
        {
            t1 = Box("D0", 8, 40, f.E2.Count > 0 ? f.E2.Tokens[0] : "0");
            t2 = Box("|D1|", 144, 40, abs(1));
        }
        else t1 = Box("|D2|", 8, 40, abs(2));
        Grid.Location = new Point(0, 72); Grid.Size = new Size(280, 288);
        if (s.Type == 1)
        {
            Grid.AllowUserToAddRows = Grid.AllowUserToDeleteRows = false;
            Column("Coef Name", readOnly: true); Column("Coef");
            var v = s.Values;
            for (int k = 0; k < 6; k++) Grid.Rows.Add("A" + k, k < v.Count ? v[k] : "0");
        }
        else
        {
            Grid.AllowUserToAddRows = Grid.AllowUserToDeleteRows = true;   // C1 grid AllowAddNew / AllowDelete
            Column("X"); Column("Y");
            var v = s.Values;
            for (int k = 0; k + 1 < v.Count; k += 2) Grid.Rows.Add(v[k], v[k + 1]);
        }
        Controls.Add(Grid);
        Buttons(360, ("Plot", 24, 72, PlotNow, DialogResult.None), ("OK", 112, 72, Save, DialogResult.None), ("Cancel", 200, 72, null, DialogResult.Cancel));
    }

    TextBox Box(string label, int x, int y, string text)
    {
        Controls.Add(new Label { Text = label, Location = new Point(x, y + 3), Size = new Size(40, 16) });
        var t = new TextBox { Location = new Point(x + 40, y), Size = new Size(80, 20), Text = text, AccessibleName = label };
        string entered = text;
        t.Enter += (_, _) => entered = t.Text;
        t.Leave += (_, _) =>   // FDFData.TextBox_Leave
        {
            if (!double.TryParse(t.Text, System.Globalization.NumberStyles.Float, System.Globalization.CultureInfo.InvariantCulture, out var v)) { Warn("Input must be a number!", "Input Warning"); t.Text = entered; }
            else if (v < 0 && label != "D0") { Warn("Input for this field must be a positive number!", "Input Warning"); t.Text = entered; }
        };
        Controls.Add(t);
        return t;
    }

    List<string> Values() => f.Subs[sub].Type == 1 ? Rows(1).Select(r => r[0]).ToList() : Rows().SelectMany(r => r).ToList();

    static double Num(string s) => double.TryParse(s, System.Globalization.NumberStyles.Float, System.Globalization.CultureInfo.InvariantCulture, out var v) ? v : 0;

    void Save()
    {
        var dAbs = sub == 0 ? t2!.Text : t1.Text;
        if (Num(dAbs) == 0) { Warn("Please assign a value for " + (sub == 0 ? "|D1|" : "|D2|") + " before exit.", "Waring"); return; }
        Ok(Functions.SaveFdfSub(Result, f, sub, sub == 0 ? t1.Text : null, dAbs, Values()));
    }

    /// FDFData.btnPlot: the sub-function over [D0, |D1|] (F1) or [|D1|, |D2|] (F2), points from Functions.CurvePoints.
    void PlotNow()
    {
        var v = Values();
        if (v.Count == 0) { Warn("No data to operate on.", "Plot Operation Warning"); return; }
        double lo = sub == 0 ? Num(t1.Text) : Math.Abs(f.D(1)), hi = Num(sub == 0 ? t2!.Text : t1.Text);
        var (x, y) = Functions.CurvePoints(f.Subs[sub].Type, v.Select(Num).ToList(), lo, hi);
        // FDFData.cs:675-708: the other sub-function's saved curve as a second series, colour index 4 (Gray).
        List<DataPlotForm.Series> s = [new(x, y, sub == 0 ? "F1" : "F2")];
        if (Functions.OtherCurve(f, sub) is { } o) s.Add(new(o.X, o.Y, sub == 0 ? "F2" : "F1", 4));
        Plot(s, "X", "Y");
    }
}

/// JntFData "Joint Stiffness Function Data": one row per phi (Phi read-only), Theta 0 then C1.. or the theta grid. Client 532x357.
public sealed class JntFDataForm : FunctionEditor
{
    readonly Functions.Joint j;

    public JntFDataForm(Deck src, int index) : base(src, "Joint Stiffness Function Data", new Size(532, 357))
    {
        j = Functions.Joints(Result)[index];
        Controls.Add(new Label { Text = "No. " + j.Id + ": " + j.Title, Location = new Point(16, 8), AutoSize = true });
        Grid.Location = new Point(0, 24); Grid.Size = new Size(532, 304);
        Grid.AllowUserToAddRows = Grid.AllowUserToDeleteRows = false;
        Column("Phi", readOnly: true);
        foreach (var c in Functions.JointColumns(j)) Column(c);
        for (int r = 0; r < j.NPhi; r++)
        {
            var vals = r < j.Rows.Count ? j.Rows[r].SelectMany(l => l.Tokens).ToList() : [];
            Grid.Rows.Add([Functions.Phi(j, r).ToString(System.Globalization.CultureInfo.InvariantCulture), .. Enumerable.Range(0, j.NTheta).Select(k => k < vals.Count ? vals[k] : "0")]);
        }
        Controls.Add(Grid);
        Controls.Add(new Label { Text = "To make a row current: click a cell in it", Location = new Point(8, 332), AutoSize = true });
        Buttons(328, ("Plot Current Row", 240, 112, PlotNow, DialogResult.None), ("OK", 364, 72, () => Ok(Functions.SaveJointRows(Result, j, Rows(1))), DialogResult.None),
            ("Cancel", 452, 72, null, DialogResult.Cancel));
    }

    /// JntFData.btnPlot: the current phi row, points from Functions.JointCurvePoints.
    void PlotNow()
    {
        int r = Grid.CurrentCell?.RowIndex ?? -1;
        if (r < 0) { Warn("No data to operate on.", "Plot Operation Warning"); return; }
        var row = Rows(1)[r].Select(s => double.TryParse(s, System.Globalization.NumberStyles.Float, System.Globalization.CultureInfo.InvariantCulture, out var v) ? v : 0).ToList();
        var (x, y) = Functions.JointCurvePoints(j.Type, row);
        Plot(x, y, "Joint Restoring Toque", "Theta (Degrees)", "Torque (in-lbs)");
    }
}

/// StdTable over E6d, "Wind Force Time History Data (Function No.N)": Time, Fx, Fy, Fz rows; 3I has no plot here.
public sealed class WindTimeHistForm : FunctionEditor
{
    public WindTimeHistForm(Deck src, int index) : base(src, "", new Size(484, 453))
    {
        var w = Functions.Winds(Result)[index];
        Text = "Wind Force Time History Data (Function No." + w.Id + ")";
        Grid.Location = new Point(5, 5); Grid.Size = new Size(474, 414);
        Grid.AllowUserToAddRows = Grid.AllowUserToDeleteRows = true;
        foreach (var c in new[] { "Time", "Fx", "Fy", "Fz" }) Column(c);
        foreach (var r in w.Rows) Grid.Rows.Add(r.SelectMany(l => l.Tokens).Take(4).Cast<object>().ToArray());
        Controls.Add(Grid);
        Buttons(421, ("OK", 316, 72, () => Ok(Functions.SaveWindRows(Result, w, Rows())), DialogResult.None), ("Cancel", 404, 72, null, DialogResult.Cancel));
    }
}
