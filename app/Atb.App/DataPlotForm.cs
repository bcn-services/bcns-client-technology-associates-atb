// ATB 3I Plots.cs "Data Plot", shared by the Vehicle Motion and Function editors.
using System.Drawing.Drawing2D;

namespace Atb.App;

/// ATB 3I Plots.cs "Data Plot": 264x264 white chart, legend at the top, one solid line per series in 3I's palette,
/// Copy (image to the clipboard) and Exit. Drawn with GDI (no chart package).
public sealed class DataPlotForm : Form
{
    /// Plots.cs series colours by index: Blue, Green, Red, Cyan, Gray.
    public static readonly Color[] Palette = [Color.Blue, Color.Green, Color.Red, Color.Cyan, Color.Gray];

    public sealed record Series(float[] X, float[] Y, string Label, int Color = 0)
    {
        public Series(double[] x, double[] y, string label, int color = 0) : this(x.Select(v => (float)v).ToArray(), y.Select(v => (float)v).ToArray(), label, color) { }
    }

    List<Series> series = []; string xLabel = "", yLabel = "";
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

    public void SetData(IEnumerable<Series> s, string xAxis, string yAxis)
    {
        (series, xLabel, yLabel) = (s.ToList(), xAxis, yAxis);
        chart.AccessibleDescription = string.Join(",", series.Select(v => v.Label));
        chart.Invalidate();
    }

    public void SetData(float[] x, float[] y, string seriesLabel, string xAxis, string yAxis) => SetData([new Series(x, y, seriesLabel)], xAxis, yAxis);

    public void SetData(double[] x, double[] y, string seriesLabel, string xAxis, string yAxis) => SetData([new Series(x, y, seriesLabel)], xAxis, yAxis);

    void Draw(Graphics g, Size s)
    {
        g.SmoothingMode = SmoothingMode.AntiAlias;
        g.Clear(Color.White);
        // legend (top, LightGray, black border, left-aligned), one swatch + label per series
        var legend = new Rectangle(4, 4, s.Width - 8, 18);
        g.FillRectangle(Brushes.LightGray, legend); g.DrawRectangle(Pens.Black, legend);
        float lx = legend.X + 6;
        foreach (var v in series)
        {
            g.DrawLine(new Pen(Palette[v.Color % Palette.Length], 2), lx, legend.Y + 9, lx + 20, legend.Y + 9);
            g.DrawString(v.Label, Axis, Brushes.Black, lx + 24, legend.Y + 3);
            lx += 24 + g.MeasureString(v.Label, Axis).Width + 10;
        }
        var area = new Rectangle(44, 30, s.Width - 54, s.Height - 66);
        g.DrawRectangle(Pens.Black, area);
        // Y label rotated 270, X label under the axis
        var st = g.Save(); g.TranslateTransform(4, area.Y + area.Height / 2f); g.RotateTransform(270);
        var ysz = g.MeasureString(yLabel, Axis); g.DrawString(yLabel, Axis, Brushes.Black, -ysz.Width / 2, 0); g.Restore(st);
        var xsz = g.MeasureString(xLabel, Axis); g.DrawString(xLabel, Axis, Brushes.Black, area.X + (area.Width - xsz.Width) / 2, s.Height - 16);
        var all = series.Where(v => v.X.Length > 0).ToList();
        if (all.Count == 0) return;
        float x0 = all.Min(v => v.X.Min()), x1 = all.Max(v => v.X.Max()), y0 = all.Min(v => v.Y.Min()), y1 = all.Max(v => v.Y.Max());
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
        foreach (var v in all)
            if (v.X.Length > 1) g.DrawLines(new Pen(Palette[v.Color % Palette.Length], 1.5f), v.X.Select((x, i) => P(x, v.Y[i])).ToArray());
    }
}
