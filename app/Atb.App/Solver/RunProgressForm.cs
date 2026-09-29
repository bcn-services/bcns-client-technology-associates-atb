namespace Atb.App.Solver;

/// Modeless window showing a solver run's log lines as they arrive, with a Cancel button.
public sealed class RunProgressForm : Form
{
    readonly TextBox log = new() { Dock = DockStyle.Fill, Multiline = true, ReadOnly = true, ScrollBars = ScrollBars.Both, WordWrap = false, Font = new Font(FontFamily.GenericMonospace, 9f) };
    readonly Button cancel = new() { Text = "Cancel", Dock = DockStyle.Bottom, Height = 32 };

    /// Raised on the UI thread when the user clicks Cancel or closes the window mid-run.
    public event Action? CancelRequested;
    public bool Finished { get; set; }

    public RunProgressForm(string title)
    {
        Text = title; Width = 800; Height = 450; StartPosition = FormStartPosition.CenterParent; ShowInTaskbar = false;
        Controls.Add(log); Controls.Add(cancel);
        cancel.Click += (_, _) => RequestCancel();
        FormClosing += (_, e) => { if (!Finished) { e.Cancel = true; RequestCancel(); } };
    }

    void RequestCancel()
    {
        if (!cancel.Enabled) return;
        cancel.Enabled = false; cancel.Text = "Cancelling...";
        CancelRequested?.Invoke();
    }

    /// Thread-safe: marshals the line to the UI thread without waiting.
    public void Post(string line)
    {
        if (IsDisposed || !IsHandleCreated) return;
        try { BeginInvoke(() => log.AppendText(line + Environment.NewLine)); }
        catch (InvalidOperationException) { /* closed between the check and the post */ }
    }
}
