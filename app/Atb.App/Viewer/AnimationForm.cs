using System.Windows.Forms.Integration;
using Atb.Core.Sa1;

namespace Atb.App.Viewer;

/// Plays one .sa1: viewport, play/pause, frame slider, speed, follow-camera pick, per-object visibility.
public sealed class AnimationForm : Form
{
    readonly Sa1File sa1; readonly Sa1Scene scene;
    readonly System.Windows.Forms.Timer timer = new() { Interval = 16 };
    readonly TrackBar slider; readonly Label clock = new() { AutoSize = true, Anchor = AnchorStyles.Left, Padding = new(6, 8, 6, 0) };
    readonly Button play = new() { Text = "Play", Width = 70 };
    readonly NumericUpDown speed = new() { DecimalPlaces = 2, Increment = 0.05m, Minimum = 0.01m, Maximum = 10, Value = 0.1m, Width = 70 };
    readonly ComboBox follow = new() { DropDownStyle = ComboBoxStyle.DropDownList, Width = 200 };
    double t; DateTime last; bool syncing;

    public AnimationForm(Sa1File file)
    {
        sa1 = file; scene = new Sa1Scene(file);
        Text = $"ATB animation — {file.Titles.FirstOrDefault()?.Trim()}"; Width = 1100; Height = 720;
        slider = new TrackBar { Minimum = 0, Maximum = Math.Max(0, file.Frames.Count - 1), TickFrequency = Math.Max(1, file.Frames.Count / 40), Dock = DockStyle.Fill };

        var host = new ElementHost { Dock = DockStyle.Fill, Child = scene.Root };
        var objects = new CheckedListBox { Dock = DockStyle.Right, Width = 220, CheckOnClick = true, IntegralHeight = false };
        foreach (var (name, _) in scene.Objects) objects.Items.Add(name, true);
        objects.ItemCheck += (_, e) => scene.SetVisible(e.Index, e.NewValue == CheckState.Checked);

        var bar = new TableLayoutPanel { Dock = DockStyle.Bottom, Height = 46, ColumnCount = 8, Padding = new(4) };
        bar.ColumnStyles.Add(new(SizeType.AutoSize)); bar.ColumnStyles.Add(new(SizeType.Percent, 100));
        for (int i = 0; i < 6; i++) bar.ColumnStyles.Add(new(SizeType.AutoSize));
        bar.Controls.Add(play, 0, 0); bar.Controls.Add(slider, 1, 0); bar.Controls.Add(clock, 2, 0);
        bar.Controls.Add(new Label { Text = "Speed ×", AutoSize = true, Padding = new(6, 8, 0, 0) }, 3, 0); bar.Controls.Add(speed, 4, 0);
        bar.Controls.Add(new Label { Text = "Camera", AutoSize = true, Padding = new(6, 8, 0, 0) }, 5, 0); bar.Controls.Add(follow, 6, 0);
        var reset = new Button { Text = "View all", Width = 70 }; bar.Controls.Add(reset, 7, 0);
        Controls.Add(host); Controls.Add(objects); Controls.Add(bar);

        follow.Items.Add("Fixed");
        for (int i = 0; i < file.NGnd; i++) follow.Items.Add(i < file.Segments.Count ? file.Segments[i].Name.Trim() : $"Entry {i + 1}");
        follow.SelectedIndex = 0;
        follow.SelectedIndexChanged += (_, _) => { scene.CameraSegment = follow.SelectedIndex - 1; Show(Frame()); };
        reset.Click += (_, _) => scene.ViewAll();
        play.Click += (_, _) => { if (timer.Enabled) timer.Stop(); else { last = DateTime.Now; timer.Start(); } play.Text = timer.Enabled ? "Pause" : "Play"; };
        slider.Scroll += (_, _) => { if (syncing) return; timer.Stop(); play.Text = "Play"; t = file.Frames[slider.Value].Time; Show(slider.Value); };
        timer.Tick += (_, _) =>
        {
            var now = DateTime.Now; t += (now - last).TotalSeconds * (double)speed.Value; last = now;
            if (t > file.Frames[^1].Time) t = file.Frames[0].Time;
            Show(Frame());
        };
        FormClosed += (_, _) => timer.Dispose();
        if (file.Frames.Count > 0) { t = file.Frames[0].Time; Show(0); }
    }

    int Frame()
    {
        int lo = 0, hi = sa1.Frames.Count - 1;
        while (lo < hi) { int mid = (lo + hi + 1) / 2; if (sa1.Frames[mid].Time <= t) lo = mid; else hi = mid - 1; }
        return lo;
    }

    void Show(int i)
    {
        scene.SetFrame(i);
        syncing = true; slider.Value = i; syncing = false;
        clock.Text = $"t = {sa1.Frames[i].Time:F4} s   frame {i + 1}/{sa1.Frames.Count}";
    }
}
