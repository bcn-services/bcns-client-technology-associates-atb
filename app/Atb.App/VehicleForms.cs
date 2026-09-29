// Model > Vehicle Motion...: ATB 3I's "Vehicle Motion" list (decomp ATB3I/Vehicle.cs) and the sub-editor its Edit Vehicle
// button opens for the vehicle's VehicleType — VehOpt1 (half sine), VehOpt2 (unidirectional, C.3), VehOpt34 (6-DOF C.4 and
// spline C.5) — plus the "Data Plot" window (Plots.cs), drawn with GDI. Card math is Atb.Core.Cards.Vehicles.
using Atb.Core.Cards;
using Atb.Core.Lin;

namespace Atb.App;

public sealed class VehicleListForm : Form
{
    const string NoRow = "No record/row selected for this operation.", OneRow = "Only one record can be selected at each time.";   // Vehicle.cs:487, :492

    /// The deck after the sub-editors' OKs: 3I writes each OK to its database at once, so the list's close keeps them.
    public Deck Deck { get; private set; }
    public bool Changed { get; private set; }

    // 3I layout (Vehicle.cs InitializeComponent): grid (0,8) 592x312, buttons 112x24 on rows y 320 / 360, client 592x389.
    readonly DataGridView grid = new()
    {
        Location = new Point(0, 8), Size = new Size(592, 312), AllowUserToAddRows = false, AllowUserToDeleteRows = false,
        SelectionMode = DataGridViewSelectionMode.FullRowSelect, RowHeadersVisible = false, AutoSizeColumnsMode = DataGridViewAutoSizeColumnsMode.Fill,
        EditMode = DataGridViewEditMode.EditOnKeystrokeOrF2,
    };
    readonly Button delete;
    bool loading;
    /// Copy Vehicle's clipboard (3I keeps the copied C1C2a-C5 rows in its database for Replace).
    List<DeckLine>? copied;

    public VehicleListForm(Deck deck)
    {
        Deck = deck;
        Text = "Vehicle Motion"; ClientSize = new Size(592, 389); FormBorderStyle = FormBorderStyle.FixedDialog;
        MaximizeBox = MinimizeBox = false; StartPosition = FormStartPosition.CenterParent;
        foreach (var h in new[] { "VehicleID", "Vehicle SegID", "Vehicle Title", "Vehicle Type" })
        {
            var c = grid.Columns[grid.Columns.Add(h, h)];
            c.SortMode = DataGridViewColumnSortMode.NotSortable; c.ReadOnly = h != "Vehicle Title";
        }
        grid.CellValueChanged += (_, e) => { if (!loading && e.RowIndex >= 0 && e.ColumnIndex == 2) BeginInvoke(() => SetTitle(e.RowIndex)); };
        Controls.Add(grid);
        Btn(72, 320, "Insert Vehicle", InsertVehicle); Btn(240, 320, "Copy Vehicle", CopyVehicle); Btn(408, 320, "Edit Vehicle", EditVehicle);
        delete = Btn(72, 360, "Delete Vehicle", DeleteVehicle); Btn(240, 360, "Replace Vehicle", ReplaceVehicle); Btn(408, 360, "Save && Exit", Close);
        Fill();
        Shown += (_, _) => grid.ClearSelection();   // 3I opens with no row selected (grdEx.GridClearSelectRow)
    }

    Button Btn(int x, int y, string text, Action act)
    {
        var b = new Button { Text = text, Location = new Point(x, y), Size = new Size(112, 24) };
        b.Click += (_, _) => act();
        Controls.Add(b);
        return b;
    }

    void Fill()
    {
        loading = true;
        grid.Rows.Clear();
        var vs = Vehicles.Blocks(Deck);
        foreach (var v in vs)
            grid.Rows.Add(v.Id, Vehicles.SegId(Deck, v), v.Title, v.Type < Vehicles.TypeNames.Length ? Vehicles.TypeNames[v.Type] : "");
        delete.Enabled = vs.Count > 1;   // only the primary vehicle: nothing 3I lets you delete
        loading = false;
    }

    /// One edit on a copy of the deck; the list keeps it (3I writes each operation to its database at once).
    void Apply(Action<Deck> op, int select)
    {
        var d = Deck.Parse(Deck.Write());
        op(d);
        if (d.Write() != Deck.Write()) { Deck = d; Changed = true; }
        Fill();
        grid.ClearSelection();
        if (select >= 0 && select < grid.Rows.Count) grid.Rows[select].Selected = true;
    }

    /// Vehicle_Closing: the Vehicle Title cell is C.1 token 0, one line rewritten.
    void SetTitle(int row) => Apply(d => Vehicles.SetTitle(d, Vehicles.Blocks(d)[row], grid[2, row].Value?.ToString() ?? ""), row);

    int? One(string op)
    {
        if (grid.SelectedRows.Count == 0) { Warn(NoRow, op); return null; }
        if (grid.SelectedRows.Count > 1) { Warn(OneRow, op); return null; }
        return grid.SelectedRows[0].Index;
    }

    bool Ask(string text, string title) => MessageBox.Show(this, text, title, MessageBoxButtons.YesNo, MessageBoxIcon.Question) == DialogResult.Yes;

    /// btnInsert (Vehicle.cs:557-631): confirm, then Renumber inserts before the selected vehicle.
    void InsertVehicle()
    {
        if (One("Insert Vehicle Operation Warning") is not { } row || !Ask(Vehicles.InsertText, Vehicles.InsertTitle)) return;
        Apply(d => Vehicles.Insert(d, row + 1), row);
    }

    /// btnCopy: the selected vehicle's lines, for Replace Vehicle.
    void CopyVehicle()
    {
        if (One("Copy Vehicle Operation Warning") is { } row) copied = Vehicles.Copy(Deck, row + 1);
    }

    /// btnDelete (Vehicle.cs:374-479): the primary vehicle is refused; otherwise confirm, then Renumber deletes.
    void DeleteVehicle()
    {
        if (One("Delete Vehicle Operation Warning") is not { } row) return;
        if (row + 1 == Vehicles.Blocks(Deck).Count) { Warn(Vehicles.PrimaryText, "Delete Vehicle Operation Warning"); return; }
        if (!Ask(Vehicles.DeleteText, Vehicles.DeleteTitle)) return;
        Apply(d => Vehicles.Delete(d, row + 1), row);
    }

    /// btnReplace (Vehicle.cs:633-748): the selected vehicle becomes the copied one.
    void ReplaceVehicle()
    {
        if (One("Replace Vehicle Operation Warning") is not { } row) return;
        if (copied == null) { Warn("Clipboard doesn't contain any data.", "Replace Vehicle Operation Warning"); return; }
        if (!Ask(Vehicles.ReplaceText, Vehicles.ReplaceTitle)) return;
        Apply(d => Vehicles.Replace(d, row + 1, copied), row);
    }

    /// Vehicle.cs:481-550: one selected row opens the sub-editor for its VehicleType.
    void EditVehicle()
    {
        if (One("Edit Vehicle Operation Warning") is not { } row) return;
        var v = Vehicles.Blocks(Deck)[row];
        using VehEditor f = Vehicles.Editor(v.Type) switch
        {
            "VehOpt1" => new VehOpt1Form(Deck, v.Id),
            "VehOpt2" => new VehOpt2Form(Deck, v.Id),
            _ => new VehOpt34Form(Deck, v.Id),
        };
        if (f.ShowDialog(this) != DialogResult.OK) return;
        if (f.Deck.Write() != Deck.Write()) { Deck = f.Deck; Changed = true; }
        Fill();
        grid.Rows[row].Selected = true;
    }

    void Warn(string text, string title) => MessageBox.Show(this, text, title, MessageBoxButtons.OK, MessageBoxIcon.Exclamation);
}

/// What VehOpt1 / VehOpt2 / VehOpt34 share: a working copy of the deck (OK keeps it, Cancel drops it), Label11, the three
/// segment combos, number boxes bound to one deck token each, the Motion Data grid and the Plot window.
public abstract class VehEditor : Form
{
    public Deck Deck { get; }
    readonly int id;
    /// Re-read after every row add / delete (C.3 lines are rewritten then).
    protected Vehicles.Block B => Vehicles.Blocks(Deck)[id - 1];
    bool loading; string entered = "";
    protected DataGridView? Grid;
    DataPlotForm? plot;

    protected VehEditor(Deck src, int id, Size client)
    {
        Deck = Deck.Parse(src.Write());
        this.id = id;
        Text = Vehicles.Title(B.Type); ClientSize = client; FormBorderStyle = FormBorderStyle.FixedDialog;
        MaximizeBox = MinimizeBox = false; StartPosition = FormStartPosition.CenterParent;
        Controls.Add(new Label { Text = "Vehicle Segment ID: " + B.Id, Location = new Point(8, 8), AutoSize = true });   // Label11
        FormClosed += (_, _) => plot?.Close();
    }

    protected void OkCancel(int x1, int y1, int x2, int y2)
    {
        var ok = new Button { Text = "OK", Location = new Point(x1, y1), Size = new Size(72, 24), DialogResult = DialogResult.OK };
        var cancel = new Button { Text = "Cancel", Location = new Point(x2, y2), Size = new Size(72, 24), DialogResult = DialogResult.Cancel };
        Controls.Add(ok); Controls.Add(cancel);
    }

    protected void Warn(string text, string title) => MessageBox.Show(this, text, title, MessageBoxButtons.OK, MessageBoxIcon.Exclamation);

    sealed record Item(string Text, int Value) { public override string ToString() => Text; }

    /// Motion Reference / Reference Segment / Vehicle Segment (VehOpt1.cs:849, :1195-1253), labels at y, combos at y+16.
    protected void SegmentCombos(Control parent, int y)
    {
        var c = B.C2a;
        var motion = Combo(parent, "Motion Reference", 8, y, [new("Vehicle to Groud", 0), new("Vehicle to Reference", 1), new("Reference to Vehicle", 2)], c, 11);
        // ponytail: 3I also drops vehicles fixed to a rotating body segment (B2B6M "Define Rotation"); this lists every other vehicle.
        var refs = new List<Item> { new("0    Ground", 0) };
        refs.AddRange(Vehicles.Blocks(Deck).Where(v => v.Id != B.Id).Select(v => new Item(Vehicles.SegId(Deck, v) + "    " + v.Title, Vehicles.SegId(Deck, v))));
        var refSeg = Combo(parent, "Reference Segment", 144, y, refs, c, 12);
        int me = Vehicles.SegId(Deck, B);
        // ponytail: 3I lists the body segments ATB.RefSegment() returns ahead of the vehicle's own; this offers its own and its current one.
        var vs = c.Int(13) == 0 ? [new Item("0    Primary", 0)] : new List<Item> { new(me + "    " + B.Title, me) };
        if (c.Int(13) != 0 && c.Int(13) != me) vs.Insert(0, new Item(c.Int(13).ToString(), c.Int(13)));
        var vehSeg = Combo(parent, "Vehicle Segment", 280, y, vs, c, 13);
        vehSeg.Enabled = c.Int(13) != 0;
        refSeg.Enabled = motion.SelectedIndex != 0;
        motion.SelectedIndexChanged += (_, _) =>   // VehOpt1.cs:1320-1331
        {
            if (loading) return;
            if (motion.SelectedIndex == 0) refSeg.SelectedIndex = 0;
            refSeg.Enabled = motion.SelectedIndex != 0;
        };
    }

    ComboBox Combo(Control parent, string label, int x, int y, List<Item> items, DeckLine line, int tok)
    {
        parent.Controls.Add(new Label { Text = label, Location = new Point(x, y), AutoSize = true });
        var cb = new ComboBox { Location = new Point(x, y + 16), Size = new Size(128, 22), DropDownStyle = ComboBoxStyle.DropDownList, AccessibleName = label };
        cb.Items.AddRange(items.ToArray());
        loading = true; cb.SelectedIndex = items.FindIndex(i => i.Value == line.Int(tok)); loading = false;
        cb.SelectedIndexChanged += (_, _) => { if (!loading && cb.SelectedItem is Item i) Deck.Edit(line, tok, i.Value.ToString()); };
        parent.Controls.Add(cb);
        return cb;
    }

    /// Label at (x, y), number box right of it bound to line[tok]; 3I's TextBox_Leave check (VehOpt1.cs:1340-1350).
    /// negate: the box shows |value| and writes "-" + text (Number of Spline Fit Points = -Interpolated Points).
    protected TextBox Field(Control parent, string label, int x, int y, int labelWidth, DeckLine line, int tok, bool negate = false)
    {
        if (label.Length > 0) parent.Controls.Add(new Label { Text = label, Location = new Point(x, y + 3), Size = new Size(labelWidth, 16) });
        var t = new TextBox { Location = new Point(x + labelWidth, y), Size = new Size(64, 20), AccessibleName = label, Text = negate ? line.Str(tok).TrimStart('-') : line.Str(tok) };
        t.Enter += (_, _) => entered = t.Text;
        t.Leave += (_, _) =>
        {
            if (t.Text == entered) return;
            if (Deck.Edit(line, tok, negate ? "-" + t.Text : t.Text) != null) { Warn("Input must be a number!", "Input Warning"); t.Text = entered; return; }
            FillGrid();   // Time = Start Time + row * Interval follows the boxes (ATBGrid.cs:2005-2020)
        };
        parent.Controls.Add(t);
        return t;
    }

    /// "Vehicle Reference Origin (Initial)" X / Y / Z = C.2.A tokens 5-7 (VehOpt1 GroupBox4, VehOpt2).
    protected void Origin(Control p, int x, int y)
    {
        var g = Group(p, "Vehicle Reference Origin (Initial)", x, y, 272, 80);
        for (int k = 0; k < 3; k++) Field(g, "XYZ"[k].ToString(), 8 + k * 88, 32, 16, B.C2a, 5 + k);
    }

    protected static GroupBox Group(Control parent, string text, int x, int y, int w, int h)
    {
        var g = new GroupBox { Text = text, Location = new Point(x, y), Size = new Size(w, h) };
        parent.Controls.Add(g);
        return g;
    }

    /// The "Motion  Data" grid: 3I table C3 / C4 / C5b with Time first (unbound, read-only, cyan for C3 / C4).
    protected void MakeGrid(Control parent)
    {
        Grid = new DataGridView
        {
            Dock = DockStyle.Fill, AllowUserToAddRows = true, AllowUserToDeleteRows = false, RowHeadersVisible = false,
            SelectionMode = DataGridViewSelectionMode.CellSelect, MultiSelect = false, EditMode = DataGridViewEditMode.EditOnKeystrokeOrF2,
        };
        foreach (var h in Vehicles.Columns(B.Type)) Grid.Columns[Grid.Columns.Add(h, h)].SortMode = DataGridViewColumnSortMode.NotSortable;
        if (Vehicles.TimeComputed(B.Type)) { Grid.Columns[0].ReadOnly = true; Grid.Columns[0].DefaultCellStyle.BackColor = Color.Cyan; }
        // AllowAddNew / AllowDelete: the new row becomes a zero deck row at once and Delete removes the current row, each
        // rewriting Interpolated Points (C.2.A token 8) / Number of Data Points (C.2.B token 2) from the row count.
        Grid.UserAddedRow += (_, _) => { if (!loading) Vehicles.AddRow(Deck, B); };
        // Esc on the new row removes it from the grid (CancelRowEdit fires only in VirtualMode): its deck row goes too.
        Grid.RowsRemoved += (_, _) => { if (!loading) Vehicles.TrimRows(Deck, B.Id, Grid.Rows.Count - (Grid.AllowUserToAddRows ? 1 : 0)); };
        Grid.KeyDown += (_, e) =>
        {
            if (e.KeyCode != Keys.Delete || Grid.IsCurrentCellInEditMode || Grid.CurrentCell is not { } c || c.RowIndex >= Vehicles.RowCount(B)) return;
            e.Handled = true;
            int r = c.RowIndex, col = c.ColumnIndex;
            Vehicles.DeleteRow(Deck, B, r);
            FillGrid();
            if (Grid.Rows.Count > 0) Grid.CurrentCell = Grid[col, Math.Min(r, Grid.Rows.Count - 1)];
        };
        Grid.CellValueChanged += (_, e) =>
        {
            if (loading || e.RowIndex < 0) return;
            var cell = Grid[e.ColumnIndex, e.RowIndex];
            if (Vehicles.EditCell(Deck, B, e.RowIndex, e.ColumnIndex, cell.Value?.ToString() ?? "") != null) Warn("Input must be a number!", "Input Warning");
            BeginInvoke(() => { loading = true; cell.Value = Vehicles.CellText(B, e.RowIndex, e.ColumnIndex); loading = false; });
        };
        parent.Controls.Add(Grid);
        FillGrid();
    }

    void FillGrid()
    {
        if (Grid == null) return;
        loading = true;
        Grid.Rows.Clear();
        int cols = Grid.Columns.Count;
        for (int r = 0; r < Vehicles.RowCount(B); r++) Grid.Rows.Add(Enumerable.Range(0, cols).Select(c => (object)Vehicles.CellText(B, r, c)).ToArray());
        loading = false;
    }

    /// VehOpt2.btnPlot / VehOpt34.btnPlot: the Data Plot window, reused while open, points from Vehicles.PlotPoints.
    protected void Plot(int col, string yLabel)
    {
        var (x, y) = Vehicles.PlotPoints(B, col);
        if (plot == null || plot.IsDisposed) { plot = new DataPlotForm(); plot.Show(this); }
        plot.SetData(x, y, Vehicles.SeriesLabel(B.Type), "Time (sec)", yLabel);
        plot.Activate();
    }

    protected bool HasRows() { if (Vehicles.RowCount(B) > 0) return true; Warn("No data to operate on.", "Plot Operation Warning"); return false; }

    /// TabControl at (8,32) with "General" and "Motion  Data"; returns the two pages.
    protected (TabPage General, TabPage Data) Tabs(Size size, params Control[] dataOnly)
    {
        var tabs = new TabControl { Location = new Point(8, 32), Size = size };
        var g = new TabPage("General"); var d = new TabPage("Motion  Data");
        tabs.TabPages.Add(g); tabs.TabPages.Add(d);
        foreach (var c in dataOnly) c.Visible = false;
        tabs.SelectedIndexChanged += (_, _) => { foreach (var c in dataOnly) c.Visible = tabs.SelectedIndex == 1; };
        Controls.Add(tabs);
        return (g, d);
    }
}

/// VehOpt1 "Half Sine Wave Deceleration Impulse" (type 0): C.2.A only, no grid, no plot. Client 432x293.
public sealed class VehOpt1Form : VehEditor
{
    public VehOpt1Form(Deck d, int id) : base(d, id, new Size(432, 293))
    {
        var c = B.C2a;
        SegmentCombos(this, 32);
        var g1 = Group(this, "Deceleration Impulse Vector", 8, 96, 184, 80);
        Field(g1, "Azimuth", 8, 20, 72, c, 0); Field(g1, "Elevation", 8, 48, 72, c, 1);
        Field(Group(this, "Initial Velocity", 208, 96, 96, 80), "", 16, 36, 0, c, 3).AccessibleName = "Initial Velocity";
        var g3 = Group(this, "Half Sine Wave", 320, 96, 104, 80);
        g3.Controls.Add(new Label { Text = "Time Duration", Location = new Point(8, 20), AutoSize = true });
        Field(g3, "", 16, 44, 0, c, 4).AccessibleName = "Time Duration";
        Origin(this, 8, 200);
        OkCancel(312, 208, 312, 248);
    }
}

/// VehOpt2 "Unidirectional Deceleration" (type 1, C.3). Client 440x365.
public sealed class VehOpt2Form : VehEditor
{
    public VehOpt2Form(Deck d, int id) : base(d, id, new Size(440, 365))
    {
        var c = B.C2a;
        var plot = new Button { Text = "Plot", Location = new Point(160, 336), Size = new Size(72, 24) };
        var (g, data) = Tabs(new Size(424, 288), plot);
        SegmentCombos(g, 8);
        var g1 = Group(g, "Deceleration Impulse Vector", 8, 64, 192, 80);
        Field(g1, "Azimuth", 8, 20, 72, c, 0); Field(g1, "Elevation", 8, 48, 72, c, 1);
        var g2 = Group(g, "Time Scale", 208, 64, 200, 80);
        Field(g2, "Start Time", 8, 20, 72, c, 9); Field(g2, "Interval", 8, 48, 72, c, 10);
        Field(Group(g, "Initial Velocity", 8, 160, 96, 80), "", 16, 36, 0, c, 3).AccessibleName = "Initial Velocity";
        Origin(g, 120, 160);
        MakeGrid(data);
        // VehOpt2.cs:1659-1672: X = Time, Y = Deceleration; the axis caption is grid column 0's (3I's "VehicleID").
        plot.Click += (_, _) => { if (HasRows()) Plot(1, "VehicleID"); };
        Controls.Add(plot);
        OkCancel(256, 336, 352, 336);
    }
}

/// VehOpt34 "Prescribed Motion Definition Option 3 and 4", SelfType 2-5 (C.4 six-DOF, C.5 spline P / V / A). Client 632x421.
public sealed class VehOpt34Form : VehEditor
{
    public VehOpt34Form(Deck d, int id) : base(d, id, new Size(632, 421))
    {
        var c = B.C2a; int t = B.Type;
        var plot = new Button { Text = "Plot Current Column", Location = new Point(296, 392), Size = new Size(136, 24) };
        var hint = new Label { Text = "To make a column current: click a cell in it", Location = new Point(8, 396), AutoSize = true };   // Label21
        var (g, data) = Tabs(new Size(616, 344), plot, hint);
        SegmentCombos(g, 8);
        string spline = t > 2 ? " of Spline Fit" : "";
        Field(g, "Start Time" + spline, 8, 64, 176, c, 9);
        Field(g, "Interval" + spline, 8, 92, 176, c, 10);
        if (t != 2)
        {
            Field(g, "Number of Spline Fit  Points", 8, 120, 176, c, 8, negate: true);
            g.Controls.Add(new Label { Text = "Spline Degree", Location = new Point(8, 151), Size = new Size(176, 16) });
            var deg = new ComboBox { Location = new Point(184, 148), Size = new Size(64, 22), DropDownStyle = ComboBoxStyle.DropDownList, AccessibleName = "Spline Degree" };
            deg.Items.AddRange(Vehicles.SplineDegrees(t).Select(n => (object)n.ToString()).ToArray());
            deg.SelectedItem = B.C2b!.Int(1).ToString();
            deg.SelectedIndexChanged += (_, _) => Deck.Edit(B.C2b!, 1, (string)deg.SelectedItem!);
            g.Controls.Add(deg);
        }
        var r1 = B.Data.ElementAtOrDefault(0); var r2 = B.Data.ElementAtOrDefault(1);
        if (t == 2)
        {
            Box(g, "Vehicle Reference Origin (Inertial)", 8, 184, c, 5, "X", "Y", "Z");
            Box(g, "Initial Vehicle Rotation", 312, 184, c, 0, "Yaw", "Pitch", "Row");
            Box(g, "Initial Speed", 8, 256, c, 3, "Speed");
            Box(g, "Initial Vehicle Angular Velocity", 312, 256, B.C2b!, 3, "Wx", "Wy", "Wz");
        }
        if (t >= 4)
        {
            Box(g, "Initial Vehicle Position", 8, 184, r1!, 1, "X", "Y", "Z");
            Box(g, "Initial Vehicle Rotation", 312, 184, r1!, 4, "Yaw", "Pitch", "Row");
        }
        if (t == 5)
        {
            Box(g, "Initial Vehicle Linear Velocity", 8, 256, r2!, 1, "Vx", "Vy", "Vz");
            Box(g, "Initial Vehicle Angular Velocity", 312, 256, r2!, 4, "Wx", "Wy", "Wz");
        }
        MakeGrid(data);
        plot.Click += (_, _) =>   // VehOpt34.cs:2446-2496
        {
            if (!HasRows()) return;
            int col = Grid!.CurrentCell?.ColumnIndex ?? 0;
            if (col < 1) { Warn("Wrong selection.", "Plot Operation Warning"); return; }
            Plot(col, Grid.Columns[col].HeaderText);
        };
        Controls.Add(plot); Controls.Add(hint);
        OkCancel(456, 392, 552, 392);
    }

    void Box(Control g, string title, int x, int y, DeckLine line, int tok, params string[] labels)
    {
        var box = Group(g, title, x, y, 296, 64);
        int w = labels.Length == 1 ? 48 : 36;   // "Speed" in full (3I's Label is AutoSize)
        for (int k = 0; k < labels.Length; k++) Field(box, labels[k], 8 + k * 96, 28, w, line, tok + k).Width = 52;
    }
}
