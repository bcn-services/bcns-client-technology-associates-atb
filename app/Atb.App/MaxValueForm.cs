// File > Setting: ATB 3I's "ATB 3I Maximum Value List" (decomp MainMenu.cs:4296-4317, a StdTable over [Setting]).
// Read-only: 3I's "Save" button is left out (STANDARDS.md, ATB 3I divergences).
using Atb.Core.Cards;

namespace Atb.App;

public sealed class MaxValueForm : Form
{
    public MaxValueForm()
    {
        // 3I: StdTable (StdTable.cs:129-172) resized to Width 245, grid 230 wide at (5,5), 414 high; Cancel at y 421.
        Text = "ATB 3I Maximum Value List"; ClientSize = new Size(237, 453); StartPosition = FormStartPosition.CenterParent;
        var bold = new Font(Font, FontStyle.Bold);
        var grid = new DataGridView
        {
            Location = new Point(5, 5), Size = new Size(230, 414), Anchor = AnchorStyles.Top | AnchorStyles.Bottom | AnchorStyles.Left | AnchorStyles.Right,
            ReadOnly = true, AllowUserToAddRows = false, AllowUserToDeleteRows = false, AllowUserToResizeRows = false,
            EnableHeadersVisualStyles = false, RowHeadersWidth = 20, ScrollBars = ScrollBars.Vertical,
        };
        grid.ColumnHeadersDefaultCellStyle.ForeColor = Color.Green;   // ATBGrid.cs:712-713 heading style
        grid.ColumnHeadersDefaultCellStyle.Font = bold;
        // Visible columns: Value, then the label column 3I locks at width 100 in cyan (ATBGrid.cs:1052-1058).
        grid.Columns.Add(new DataGridViewTextBoxColumn { Name = "Value", HeaderText = "Value", Width = 40, SortMode = DataGridViewColumnSortMode.NotSortable });
        grid.Columns.Add(new DataGridViewTextBoxColumn
        {
            Name = "Name", HeaderText = "Name", SortMode = DataGridViewColumnSortMode.NotSortable,
            AutoSizeMode = DataGridViewAutoSizeColumnMode.Fill, MinimumWidth = 100, DefaultCellStyle = { BackColor = Color.Cyan },
        });   // Fill: 3I's ExtendRightColumn (ATBGrid.cs:800-803)
        foreach (var r in MaxValues.Rows) grid.Rows.Add(r.Value, r.Name);
        var cancel = new Button { Text = "Cancel", Location = new Point(150, 421), Anchor = AnchorStyles.Bottom | AnchorStyles.Right, Font = new Font("Arial", 8.25f, FontStyle.Bold) };
        cancel.Click += (_, _) => Close();
        CancelButton = cancel;
        Controls.Add(grid); Controls.Add(cancel);
    }
}
