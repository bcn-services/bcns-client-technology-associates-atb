// Output > Control Parameter > General Parameter... / Diagnostic Parameter...: ATB 3I's StdTable over [A5] (decomp
// MainMenu.cs:3595-3612 / :3502-3519, layout StdTable.cs:129-172, columns ATBGrid.cs GridLayout + GridInitSpecial "A5").
// Row <-> token mapping is Atb.Core.Cards.OutputControl.
using Atb.Core.Cards;
using Atb.Core.Lin;

namespace Atb.App;

public sealed class OutputControlForm : Form
{
    /// Working copy: each Value cell writes its NPRT token as it is committed; OK brings H.12 in step and keeps it.
    public Deck Deck { get; }
    readonly IReadOnlyList<OutputControl.Row> rows;
    readonly DataGridView grid;
    bool loading;

    public static string Title(int category) => category == OutputControl.General
        ? "General Output Control Parameter Definition" : "Diagnostic Output Control Parameter Definition";

    public OutputControlForm(Deck src, int category)
    {
        Deck = Deck.Parse(src.Write());
        rows = OutputControl.Rows(category);
        var values = rows.Select(r => OutputControl.Value(Deck, r.Nprt)).ToList();   // throws when A.5 is missing; MainForm reports it
        // StdTable: ClientSize 757x453, grid (5,5) 748x414 anchored all sides, OK/Cancel bottom-right; MainMenu then sets Width 393.
        Text = Title(category); ClientSize = new Size(757, 453); StartPosition = FormStartPosition.CenterParent;
        MaximizeBox = MinimizeBox = false; ShowInTaskbar = false;
        var bold = new Font("Arial", 8.25f, FontStyle.Bold);
        grid = new DataGridView
        {
            Location = new Point(5, 5), Size = new Size(748, 414), Anchor = AnchorStyles.Top | AnchorStyles.Bottom | AnchorStyles.Left | AnchorStyles.Right,
            AllowUserToAddRows = false, AllowUserToDeleteRows = false, AllowUserToResizeRows = false, EnableHeadersVisualStyles = false,
            RowHeadersWidth = 20, ColumnHeadersHeight = 34, ColumnHeadersHeightSizeMode = DataGridViewColumnHeadersHeightSizeMode.DisableResizing,
            RowTemplate = { Height = 28 }, SelectionMode = DataGridViewSelectionMode.CellSelect, MultiSelect = false,
        };
        grid.ColumnHeadersDefaultCellStyle.ForeColor = Color.Green;   // ATBGrid.cs:712-713 heading style
        grid.ColumnHeadersDefaultCellStyle.Font = bold;
        grid.ColumnHeadersDefaultCellStyle.Alignment = DataGridViewContentAlignment.MiddleCenter;
        // NPRT: the ID column, cyan and locked (ATBGrid.cs:1078-1082), MinColWidth 60; Control Parameter: width 200, cyan,
        // locked (GridInitSpecial :821-828, which also hides Category); Value: the one editable column, extended right.
        grid.Columns.Add(Col("NPRT", 60, true));
        grid.Columns.Add(Col("Control Parameter", 200, true));
        var value = Col("Value", 60, false); value.AutoSizeMode = DataGridViewAutoSizeColumnMode.Fill;
        grid.Columns.Add(value);
        loading = true;
        for (int i = 0; i < rows.Count; i++) grid.Rows.Add(rows[i].Nprt.ToString(), rows[i].Name, values[i]);
        loading = false;
        grid.CellValueChanged += (_, e) => { if (!loading && e.RowIndex >= 0 && e.ColumnIndex == 2) Commit(e.RowIndex); };

        var ok = new Button { Text = "OK", Location = new Point(582, 421), Size = new Size(72, 24), Font = bold, Anchor = AnchorStyles.Bottom | AnchorStyles.Right, DialogResult = DialogResult.OK };
        var cancel = new Button { Text = "Cancel", Location = new Point(670, 421), Size = new Size(72, 24), Font = bold, Anchor = AnchorStyles.Bottom | AnchorStyles.Right, DialogResult = DialogResult.Cancel };
        ok.Click += (_, _) => { grid.EndEdit(); OutputControl.KeepHicInStep(Deck); };
        Controls.Add(grid); Controls.Add(ok); Controls.Add(cancel);
        CancelButton = cancel;
        Width = 393;   // MainMenu.cs:3517 / :3610
    }

    static DataGridViewTextBoxColumn Col(string name, int width, bool locked)
    {
        var c = new DataGridViewTextBoxColumn { Name = name, HeaderText = name, Width = width, MinimumWidth = 60, ReadOnly = locked, SortMode = DataGridViewColumnSortMode.NotSortable };
        if (locked) c.DefaultCellStyle.BackColor = Color.Cyan;
        return c;
    }

    /// The Value cell into its NPRT token; refused text (not a whole number) is warned about and put back.
    void Commit(int r)
    {
        var cell = grid[2, r];
        if (OutputControl.Set(Deck, rows[r].Nprt, cell.Value?.ToString() ?? "") != null)
            MessageBox.Show(this, "Input must be a number!", "Input Warning", MessageBoxButtons.OK, MessageBoxIcon.Exclamation);
        BeginInvoke(() => { loading = true; cell.Value = OutputControl.Value(Deck, rows[r].Nprt); loading = false; });
    }
}
