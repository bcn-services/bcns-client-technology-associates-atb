using System.Windows.Forms.Integration;
using Atb.Core.Sa1;

namespace Atb.App.Viewer;

/// Plays one .sa1: viewport, play/pause/step, frame slider, speed, camera pick, per-object visibility and colour.
public sealed class AnimationForm : Form
{
    readonly Sa1File sa1; readonly Sa1Scene scene;
    readonly double[] times;
    readonly System.Windows.Forms.Timer timer = new() { Interval = 16 };
    readonly TrackBar slider; readonly Label clock = new() { AutoSize = true, Anchor = AnchorStyles.Left, Padding = new(6, 8, 6, 0) };
    readonly Button play = new() { Text = "Play", Width = 60 };
    readonly NumericUpDown speed = new() { DecimalPlaces = 2, Increment = 0.05m, Minimum = 0.01m, Maximum = 10, Value = 0.1m, Width = 70 };
    readonly ComboBox follow = new() { DropDownStyle = ComboBoxStyle.DropDownList, Width = 200, AccessibleName = "Camera" };
    double wall; DateTime last; int shown; bool syncing;

    public AnimationForm(Sa1File file)
    {
        sa1 = file; scene = new Sa1Scene(file);
        times = file.Frames.Select(f => f.Time).ToArray();
        Text = $"ATB animation — {file.Titles.FirstOrDefault()?.Trim()}"; Width = 1100; Height = 720;
        slider = new TrackBar { Minimum = 0, Maximum = Math.Max(0, times.Length - 1), TickFrequency = Math.Max(1, times.Length / 40), Dock = DockStyle.Fill };

        var host = new ElementHost { Dock = DockStyle.Fill, Child = scene.Root };
        var objects = new CheckedListBox { Dock = DockStyle.Fill, CheckOnClick = true, IntegralHeight = false };
        foreach (var (name, _) in scene.Objects) objects.Items.Add(name, true);
        objects.ItemCheck += (_, e) => scene.SetVisible(e.Index, e.NewValue == CheckState.Checked);
        var colour = new Button { Text = "Colour…", Dock = DockStyle.Bottom };
        colour.Click += (_, _) => PickColour(objects.SelectedIndex);
        var side = new Panel { Dock = DockStyle.Right, Width = 220 };
        side.Controls.Add(objects); side.Controls.Add(colour);

        var prev = new Button { Text = "◀", Width = 32 }; var next = new Button { Text = "▶", Width = 32 };
        var bar = new TableLayoutPanel { Dock = DockStyle.Bottom, Height = 46, ColumnCount = 10, Padding = new(4) };
        for (int i = 0; i < 3; i++) bar.ColumnStyles.Add(new(SizeType.AutoSize));
        bar.ColumnStyles.Add(new(SizeType.Percent, 100));
        for (int i = 0; i < 6; i++) bar.ColumnStyles.Add(new(SizeType.AutoSize));
        bar.Controls.Add(prev, 0, 0); bar.Controls.Add(play, 1, 0); bar.Controls.Add(next, 2, 0);
        bar.Controls.Add(slider, 3, 0); bar.Controls.Add(clock, 4, 0);
        bar.Controls.Add(new Label { Text = "Speed ×", AutoSize = true, Padding = new(6, 8, 0, 0) }, 5, 0); bar.Controls.Add(speed, 6, 0);
        bar.Controls.Add(new Label { Text = "Camera", AutoSize = true, Padding = new(6, 8, 0, 0) }, 7, 0); bar.Controls.Add(follow, 8, 0);
        var reset = new Button { Text = "View all", Width = 70 }; bar.Controls.Add(reset, 9, 0);
        Controls.Add(host); Controls.Add(side); Controls.Add(bar);

        follow.Items.Add("View all (fixed)");
        for (int i = 0; i < file.NGnd; i++) follow.Items.Add(i < file.Segments.Count ? file.Segments[i].Name.Trim() : $"Entry {i + 1}");
        follow.SelectedIndex = 0;
        follow.SelectedIndexChanged += (_, _) => scene.FollowSegment(follow.SelectedIndex - 1);
        reset.Click += (_, _) => { follow.SelectedIndex = 0; scene.ViewAll(); };
        play.Click += (_, _) =>
        {
            if (timer.Enabled) { Pause(); return; }
            if (times.Length == 0) return;
            if (shown == times.Length - 1) Show(0);
            Rebase(); last = DateTime.Now; timer.Start(); play.Text = "Pause";
        };
        prev.Click += (_, _) => Step(-1);
        next.Click += (_, _) => Step(+1);
        speed.ValueChanged += (_, _) => Rebase();
        slider.Scroll += (_, _) => { if (syncing) return; Pause(); Show(slider.Value); };
        timer.Tick += (_, _) =>
        {
            var now = DateTime.Now; wall += (now - last).TotalSeconds; last = now;
            int i = Playback.FrameAt(times, wall, (double)speed.Value);
            if (i == times.Length - 1 && shown == i) { i = 0; wall = 0; }   // loop after holding the last frame one tick
            Show(i);
        };
        FormClosed += (_, _) => timer.Dispose();
        if (times.Length > 0) Show(0);
    }

    void Pause() { timer.Stop(); play.Text = "Play"; }

    void Step(int d)
    {
        if (times.Length == 0) return;
        Pause();
        Show(Math.Clamp(shown + d, 0, times.Length - 1));
    }

    /// Restart the wall clock so Playback.FrameAt lands on the shown frame at the current speed.
    void Rebase() { if (times.Length > 0) wall = (times[shown] - times[0]) / (double)speed.Value; }

    void PickColour(int index)
    {
        if (index < 0) { MessageBox.Show(this, "Select an object in the list first.", "Colour"); return; }
        var c = scene.ColorOf(index);
        using var dlg = new ColorDialog { Color = System.Drawing.Color.FromArgb(c.R, c.G, c.B), FullOpen = true };
        if (dlg.ShowDialog(this) == DialogResult.OK) scene.SetColor(index, System.Windows.Media.Color.FromRgb(dlg.Color.R, dlg.Color.G, dlg.Color.B));
    }

    void Show(int i)
    {
        shown = i;
        scene.SetFrame(i);
        syncing = true; slider.Value = i; syncing = false;
        clock.Text = $"t = {times[i]:F4} s   frame {i + 1}/{times.Length}";
        if (!timer.Enabled) Rebase();
    }
}
