// Output > HIC...: ATB 3I's "HIC and CSI Definition" (decomp HIC.cs InitializeComponent :160-258, grid params MainMenu.cs:3701-3716).
// Span box + [H12a2] grid (BodyID locked, HIC/CSI Source drop-downs); deck mapping is Atb.Core.Cards.Hic.
using Atb.Core.Cards;
using Atb.Core.Lin;

namespace Atb.App;

public sealed class HicForm : Form
{
    public const string Title = "HIC and CSI Definition";

    /// Working copy: the Span box writes as it is left, each Source cell as it is committed; OK keeps it.
    public Deck Deck { get; }
    readonly DataGridView grid;
    bool loading;

    public HicForm(Deck src)
    {
        Deck = Deck.Parse(src.Write());
        var rows = Hic.Rows(Deck);   // throws when there is no H.12; MainForm reports it
        Text = Title; ClientSize = new Size(360, 253); StartPosition = FormStartPosition.CenterScreen;
        MaximizeBox = MinimizeBox = false; ShowInTaskbar = false;
        var bold = new Font("Arial", 8.25f, FontStyle.Bold);

        var label = new Label { Text = "Span (sec)", Location = new Point(8, 8), Size = new Size(72, 16), Font = bold, ForeColor = Color.Green, BackColor = Color.Transparent };
        var span = new TextBox { AutoSize = false, Location = new Point(80, 8), Size = new Size(72, 19), Font = new Font("Microsoft Sans Serif", 9f), Text = Hic.Span(Deck), AccessibleName = "Span (sec)" };
        string entered = span.Text;
        span.Enter += (_, _) => entered = span.Text;
        span.Leave += (_, _) =>   // HIC.cs TextBox_Leave :380-390
        {
            if (span.Text == entered) return;
            if (Hic.SetSpan(Deck, span.Text) != null)
            {
                MessageBox.Show(this, "Input must be a number!", "Input Warning", MessageBoxButtons.OK, MessageBoxIcon.Exclamation);
                span.Text = entered;
            }
        };

        grid = new DataGridView
        {
            Location = new Point(0, 32), Size = new Size(360, 184), Anchor = AnchorStyles.Top | AnchorStyles.Bottom | AnchorStyles.Left | AnchorStyles.Right,
            AllowUserToAddRows = false, AllowUserToDeleteRows = false, AllowUserToResizeRows = false, EnableHeadersVisualStyles = false,
            RowHeadersWidth = 20, SelectionMode = DataGridViewSelectionMode.CellSelect, MultiSelect = false,
        };
        grid.ColumnHeadersDefaultCellStyle.ForeColor = Color.Green;   // ATBGrid.cs:712-713 heading style
        grid.ColumnHeadersDefaultCellStyle.Font = bold;
        grid.ColumnHeadersDefaultCellStyle.Alignment = DataGridViewContentAlignment.MiddleCenter;
        // BodyID: the ID column, cyan and locked (ATBGrid.cs:1078-1082); HIC/CSI Source: drop-down type 11 (H.1 rows). MinColWidth 100.
        grid.Columns.Add(new DataGridViewTextBoxColumn { Name = Hic.Columns[0], HeaderText = Hic.Columns[0], Width = 100, ReadOnly = true, SortMode = DataGridViewColumnSortMode.NotSortable, DefaultCellStyle = { BackColor = Color.Cyan } });
        var choices = Hic.Choices(Deck).ToArray<object>();
        for (int c = 1; c < 3; c++)
        {
            var cb = new DataGridViewComboBoxColumn { Name = Hic.Columns[c], HeaderText = Hic.Columns[c], Width = 100, DisplayStyle = DataGridViewComboBoxDisplayStyle.ComboBox, FlatStyle = FlatStyle.Flat };
            cb.Items.AddRange(choices);
            grid.Columns.Add(cb);
        }
        loading = true;
        for (int r = 0; r < rows.Count; r++) grid.Rows.Add(Hic.Cell(Deck, r, 0), Hic.Cell(Deck, r, 1), Hic.Cell(Deck, r, 2));
        loading = false;
        grid.CurrentCellDirtyStateChanged += (_, _) => { if (grid.CurrentCell is DataGridViewComboBoxCell) grid.CommitEdit(DataGridViewDataErrorContexts.Commit); };
        grid.CellValueChanged += (_, e) =>
        {
            if (loading || e.RowIndex < 0 || e.ColumnIndex < 1) return;
            Hic.Set(Deck, e.RowIndex, e.ColumnIndex, grid[e.ColumnIndex, e.RowIndex].Value?.ToString() ?? "");   // choices are all whole numbers
        };

        var ok = new Button { Text = "OK", Location = new Point(184, 220), Size = new Size(72, 24), Font = bold, DialogResult = DialogResult.OK };
        var cancel = new Button { Text = "Cancel", Location = new Point(272, 220), Font = bold, DialogResult = DialogResult.Cancel };
        ok.Click += (_, _) => grid.EndEdit();
        Controls.Add(cancel); Controls.Add(ok); Controls.Add(grid); Controls.Add(span); Controls.Add(label);
        CancelButton = cancel;
    }
}
