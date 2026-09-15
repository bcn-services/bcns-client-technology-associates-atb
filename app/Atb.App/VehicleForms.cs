// Model > Vehicle Motion...: ATB 3I's "Vehicle Motion" list (decomp ATB3I/Vehicle.cs) and the sub-editor its Edit Vehicle
// button opens for the vehicle's VehicleType — VehOpt1 (half sine), VehOpt2 (unidirectional, C.3), VehOpt34 (6-DOF C.4 and
// spline C.5) — plus the "Data Plot" window (Plots.cs), drawn with GDI. Card math is Atb.Core.Cards.Vehicles.
using System.Drawing.Drawing2D;
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
        Location = new Point(0, 8), Size = new Size(592, 312), ReadOnly = true, AllowUserToAddRows = false, AllowUserToDeleteRows = false,
        SelectionMode = DataGridViewSelectionMode.FullRowSelect, RowHeadersVisible = false, AutoSizeColumnsMode = DataGridViewAutoSizeColumnsMode.Fill,
    };

    public VehicleListForm(Deck deck)
    {
        Deck = deck;
        Text = "Vehicle Motion"; ClientSize = new Size(592, 389); FormBorderStyle = FormBorderStyle.FixedDialog;
        MaximizeBox = MinimizeBox = false; StartPosition = FormStartPosition.CenterParent;
        foreach (var h in new[] { "VehicleID", "Vehicle SegID", "Vehicle Title", "Vehicle Type" })
            grid.Columns[grid.Columns.Add(h, h)].SortMode = DataGridViewColumnSortMode.NotSortable;
        Controls.Add(grid);
        // ponytail: Insert / Copy / Delete / Replace Vehicle are shown but disabled (STANDARDS.md divergence) — build them
        // when a client asks to add or remove a vehicle; they cascade C.1-C.5 and every segment reference.
        Btn(72, 320, "Insert Vehicle", null); Btn(240, 320, "Copy Vehicle", null); Btn(408, 320, "Edit Vehicle", EditVehicle);
        Btn(72, 360, "Delete Vehicle", null); Btn(240, 360, "Replace Vehicle", null); Btn(408, 360, "Save && Exit", Close);
        Fill();
        Shown += (_, _) => grid.ClearSelection();   // 3I opens with no row selected (grdEx.GridClearSelectRow)
    }

    void Btn(int x, int y, string text, Action? act)
    {
        var b = new Button { Text = text, Location = new Point(x, y), Size = new Size(112, 24), Enabled = act != null };
        if (act != null) b.Click += (_, _) => act();
        Controls.Add(b);
    }

    void Fill()
    {
        grid.Rows.Clear();
        foreach (var v in Vehicles.Blocks(Deck))
            grid.Rows.Add(v.Id, Vehicles.SegId(Deck, v), v.Title, v.Type < Vehicles.TypeNames.Length ? Vehicles.TypeNames[v.Type] : "");
    }

    /// Vehicle.cs:481-550: one selected row opens the sub-editor for its VehicleType.
    void EditVehicle()
    {
        if (grid.SelectedRows.Count == 0) { Warn(NoRow); return; }
        if (grid.SelectedRows.Count > 1) { Warn(OneRow); return; }
        int row = grid.SelectedRows[0].Index;
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

    void Warn(string text) => MessageBox.Show(this, text, "Edit Vehicle Operation Warning", MessageBoxButtons.OK, MessageBoxIcon.Exclamation);
}

/// What VehOpt1 / VehOpt2 / VehOpt34 share: a working copy of the deck (OK keeps it, Cancel drops it), Label11, the three
/// segment combos, number boxes bound to one deck token each, the Motion Data grid and the Plot window.
public abstract class VehEditor : Form
{
    public Deck Deck { get; }
    protected readonly Vehicles.Block B;
    bool loading; string entered = "";
    protected DataGridView? Grid;
    DataPlotForm? plot;

    protected VehEditor(Deck src, int id, Size client)
    {
        Deck = Deck.Parse(src.Write());
        B = Vehicles.Blocks(Deck)[id - 1];
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
            Dock = DockStyle.Fill, AllowUserToAddRows = false, AllowUserToDeleteRows = false, RowHeadersVisible = false,
            SelectionMode = DataGridViewSelectionMode.CellSelect, MultiSelect = false, EditMode = DataGridViewEditMode.EditOnKeystrokeOrF2,
        };
        foreach (var h in Vehicles.Columns(B.Type)) Grid.Columns[Grid.Columns.Add(h, h)].SortMode = DataGridViewColumnSortMode.NotSortable;
        if (Vehicles.TimeComputed(B.Type)) { Grid.Columns[0].ReadOnly = true; Grid.Columns[0].DefaultCellStyle.BackColor = Color.Cyan; }
        // ponytail: rows cannot be added or deleted (Interpolated Points / Number of Data Points stay as read) — add with C.2 upkeep.
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
            deg.Items.AddRange(Enumerable.Range(0, 4).Where(n => n >= t - 2).Select(n => (object)n.ToString()).ToArray());   // type 3 drops 0,1; type 4 drops 0
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
        for (int k = 0; k < labels.Length; k++) Field(box, labels[k], 8 + k * 96, 28, 36, line, tok + k);
    }
}

/// ATB 3I Plots.cs "Data Plot": 264x264 white chart, legend at the top, one solid Blue series, Copy (image to the clipboard)
/// and Exit. Drawn with GDI (no chart package).
public sealed class DataPlotForm : Form
{
    float[] xs = [], ys = []; string series = "", xLabel = "", yLabel = "";
    readonly PictureBox chart = new() { Location = new Point(8, 8), Size = new Size(264, 264), BackColor = Color.White, AccessibleName = "Chart" };
    static readonly Font Axis = new("Arial", 8f), Btn = new("Arial", 8.25f, FontStyle.Bold);

    public DataPlotForm()
    {
        Text = "Data Plot"; ClientSize = new Size(280, 309); FormBorderStyle = FormBorderStyle.FixedDialog; MaximizeBox = MinimizeBox = false;
        StartPosition = FormStartPosition.CenterParent;
        chart.Paint += (_, e) => Draw(e.Graphics, chart.ClientSize);
        var copy = new Button { Text = "Copy", Location = new Point(112, 280), Size = new Size(72, 24), Font = Btn };
        var exit = new Button { Text = "Exit", Location = new Point(200, 280), Size = new Size(72, 24), Font = Btn };
        copy.Click += (_, _) => { using var bmp = new Bitmap(chart.Width, chart.Height); chart.DrawToBitmap(bmp, chart.ClientRectangle); Clipboard.SetImage(bmp); };
        exit.Click += (_, _) => Close();
        Controls.AddRange([chart, copy, exit]);
    }

    public void SetData(float[] x, float[] y, string seriesLabel, string xAxis, string yAxis)
    {
        (xs, ys, series, xLabel, yLabel) = (x, y, seriesLabel, xAxis, yAxis);
        chart.Invalidate();
    }

    void Draw(Graphics g, Size s)
    {
        g.SmoothingMode = SmoothingMode.AntiAlias;
        g.Clear(Color.White);
        // legend (top, LightGray, black border, left-aligned)
        var legend = new Rectangle(4, 4, s.Width - 8, 18);
        g.FillRectangle(Brushes.LightGray, legend); g.DrawRectangle(Pens.Black, legend);
        g.DrawLine(new Pen(Color.Blue, 2), legend.X + 6, legend.Y + 9, legend.X + 26, legend.Y + 9);
        g.DrawString(series, Axis, Brushes.Black, legend.X + 30, legend.Y + 3);
        var area = new Rectangle(44, 30, s.Width - 54, s.Height - 66);
        g.DrawRectangle(Pens.Black, area);
        // Y label rotated 270, X label under the axis
        var st = g.Save(); g.TranslateTransform(4, area.Y + area.Height / 2f); g.RotateTransform(270);
        var ysz = g.MeasureString(yLabel, Axis); g.DrawString(yLabel, Axis, Brushes.Black, -ysz.Width / 2, 0); g.Restore(st);
        var xsz = g.MeasureString(xLabel, Axis); g.DrawString(xLabel, Axis, Brushes.Black, area.X + (area.Width - xsz.Width) / 2, s.Height - 16);
        if (xs.Length == 0) return;
        float x0 = xs.Min(), x1 = xs.Max(), y0 = ys.Min(), y1 = ys.Max();
        if (x1 == x0) x1 = x0 + 1; if (y1 == y0) { y0 -= 1; y1 += 1; }
        PointF P(float x, float y) => new(area.X + (x - x0) / (x1 - x0) * area.Width, area.Bottom - (y - y0) / (y1 - y0) * area.Height);
        for (int k = 0; k <= 4; k++)   // major ticks only (3I: no minor ticks)
        {
            float fx = x0 + (x1 - x0) * k / 4, fy = y0 + (y1 - y0) * k / 4;
            var px = P(fx, y0); var py = P(x0, fy);
            g.DrawLine(Pens.Black, px.X, area.Bottom, px.X, area.Bottom + 3); g.DrawLine(Pens.Black, area.X - 3, py.Y, area.X, py.Y);
            var tx = fx.ToString("G3"); var ty = fy.ToString("G3");
            g.DrawString(tx, Axis, Brushes.Black, px.X - g.MeasureString(tx, Axis).Width / 2, area.Bottom + 3);
            g.DrawString(ty, Axis, Brushes.Black, area.X - 3 - g.MeasureString(ty, Axis).Width, py.Y - 6);
        }
        if (xs.Length > 1) g.DrawLines(new Pen(Color.Blue, 1.5f), xs.Select((x, i) => P(x, ys[i])).ToArray());
    }
}
