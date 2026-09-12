// Minimal WinForms front end: pick a .LIN, name the output, run the original solver, watch status, open the folder.
using System;
using System.Diagnostics;
using System.Drawing;
using System.IO;
using System.Threading;
using System.Windows.Forms;

namespace ATBRunner
{
    public class MainForm : Form
    {
        TextBox linBox = new TextBox(), outBox = new TextBox(), logBox = new TextBox();
        Button browseBtn = new Button(), runBtn = new Button(), openBtn = new Button();
        Label status = new Label(), solverLbl = new Label();
        ListBox outputs = new ListBox();
        System.Windows.Forms.Timer tick = new System.Windows.Forms.Timer();
        Thread worker; Stopwatch clock; string lastWorkDir; string solverErr, solverSha; Mutex mutex;
        volatile string state = "idle"; volatile int exitCode = -999;

        public MainForm()
        {
            Text = "ATB Runner " + Program.Version + " (original ATBV3.exe)"; Width = 760; Height = 560; StartPosition = FormStartPosition.CenterScreen;
            var t = new TableLayoutPanel { Dock = DockStyle.Fill, ColumnCount = 3, RowCount = 7, Padding = new Padding(8) };
            t.ColumnStyles.Add(new ColumnStyle(SizeType.Absolute, 90)); t.ColumnStyles.Add(new ColumnStyle(SizeType.Percent, 100)); t.ColumnStyles.Add(new ColumnStyle(SizeType.Absolute, 110));
            for (int i = 0; i < 5; i++) t.RowStyles.Add(new RowStyle(SizeType.Absolute, 30));
            t.RowStyles.Add(new RowStyle(SizeType.Absolute, 110)); t.RowStyles.Add(new RowStyle(SizeType.Percent, 100));

            t.Controls.Add(new Label { Text = "Input .LIN", TextAlign = ContentAlignment.MiddleLeft, Dock = DockStyle.Fill }, 0, 0);
            linBox.Dock = DockStyle.Fill; linBox.ReadOnly = true; t.Controls.Add(linBox, 1, 0);
            browseBtn.Text = "Browse..."; browseBtn.Dock = DockStyle.Fill; browseBtn.Click += Browse; t.Controls.Add(browseBtn, 2, 0);
            t.Controls.Add(new Label { Text = "Output name", TextAlign = ContentAlignment.MiddleLeft, Dock = DockStyle.Fill }, 0, 1);
            outBox.Dock = DockStyle.Fill; t.Controls.Add(outBox, 1, 1);
            runBtn.Text = "Run"; runBtn.Dock = DockStyle.Fill; runBtn.Click += RunClick; t.Controls.Add(runBtn, 2, 1);
            t.Controls.Add(new Label { Text = "Solver", TextAlign = ContentAlignment.MiddleLeft, Dock = DockStyle.Fill }, 0, 2);
            solverLbl.Dock = DockStyle.Fill; solverLbl.TextAlign = ContentAlignment.MiddleLeft; solverLbl.AutoEllipsis = true; t.Controls.Add(solverLbl, 1, 2); t.SetColumnSpan(solverLbl, 2);
            t.Controls.Add(new Label { Text = "Status", TextAlign = ContentAlignment.MiddleLeft, Dock = DockStyle.Fill }, 0, 3);
            status.Dock = DockStyle.Fill; status.TextAlign = ContentAlignment.MiddleLeft; status.Font = new Font(Font, FontStyle.Bold); t.Controls.Add(status, 1, 3);
            openBtn.Text = "Open folder"; openBtn.Dock = DockStyle.Fill; openBtn.Enabled = false; openBtn.Click += delegate { if (lastWorkDir != null) Process.Start("explorer.exe", "\"" + lastWorkDir + "\""); }; t.Controls.Add(openBtn, 2, 3);
            t.Controls.Add(new Label { Text = "Outputs", TextAlign = ContentAlignment.MiddleLeft, Dock = DockStyle.Fill }, 0, 5);
            outputs.Dock = DockStyle.Fill; outputs.DoubleClick += delegate { if (outputs.SelectedItem != null) Process.Start("notepad.exe", "\"" + Path.Combine(lastWorkDir, outputs.SelectedItem.ToString().Split(' ')[0]) + "\""); }; t.Controls.Add(outputs, 1, 5); t.SetColumnSpan(outputs, 2);
            t.Controls.Add(new Label { Text = "Log", TextAlign = ContentAlignment.TopLeft, Dock = DockStyle.Fill }, 0, 6);
            logBox.Multiline = true; logBox.ReadOnly = true; logBox.ScrollBars = ScrollBars.Both; logBox.WordWrap = false; logBox.Font = new Font(FontFamily.GenericMonospace, 8); logBox.Dock = DockStyle.Fill; t.Controls.Add(logBox, 1, 6); t.SetColumnSpan(logBox, 2);
            Controls.Add(t);
            tick.Interval = 250; tick.Tick += delegate { Refresh_(); };
            Load += delegate { CheckSolver(); };
            FormClosing += delegate(object s, FormClosingEventArgs e) { if (state == "running") { MessageBox.Show(this, "A solver run is still in progress.", "ATB Runner"); e.Cancel = true; } };
        }

        void CheckSolver()
        {
            solverErr = Program.CheckSolver(Program.DefaultSolver, out solverSha);
            if (solverErr != null) { solverLbl.Text = "REFUSED: " + solverErr.Replace("\n", " "); solverLbl.ForeColor = Color.DarkRed; runBtn.Enabled = false; MessageBox.Show(this, solverErr, "ATB Runner - solver check failed", MessageBoxButtons.OK, MessageBoxIcon.Error); }
            else { solverLbl.Text = "ATBV3.exe OK  sha256 " + solverSha.Substring(0, 16) + "...  (" + Hashes.Describe(solverSha) + ")"; solverLbl.ForeColor = Color.DarkGreen; }
            status.Text = "idle";
        }

        void Browse(object s, EventArgs e)
        {
            using (var d = new OpenFileDialog { Filter = "ATB input (*.LIN)|*.lin;*.LIN|All files|*.*", Title = "Choose ATB input deck" })
                if (d.ShowDialog(this) == DialogResult.OK) { linBox.Text = d.FileName; outBox.Text = Path.GetFileNameWithoutExtension(d.FileName) + "_new"; }
        }

        static bool Short(string dir) { return dir.Length <= 50 && !dir.Contains(" "); }

        void RunClick(object s, EventArgs e)
        {
            if (state == "running") { MessageBox.Show(this, "A run is already in progress.", "ATB Runner"); return; }
            if (!File.Exists(linBox.Text)) { MessageBox.Show(this, "Choose a .LIN file first.", "ATB Runner"); return; }
            string outName = outBox.Text.Trim(); string inBase = Path.GetFileNameWithoutExtension(linBox.Text);
            if (outName == "" || outName.IndexOfAny(Path.GetInvalidFileNameChars()) >= 0 || outName.Length > 32) { MessageBox.Show(this, "Output name must be 1-32 chars, no path characters.", "ATB Runner"); return; }
            if (string.Equals(outName, inBase, StringComparison.OrdinalIgnoreCase)) { MessageBox.Show(this, "Output name must differ from the input name (the solver would overwrite nothing, but this keeps the deck untouched).", "ATB Runner"); return; }
            bool created; mutex = new Mutex(true, "Local\\ATBRunner.SingleRun", out created);
            if (!created) { mutex.Close(); mutex = null; MessageBox.Show(this, "Another ATBRunner run is in progress (batch or GUI).", "ATB Runner"); return; }
            string srcDir = Path.GetDirectoryName(linBox.Text); string work = srcDir; bool copied = false;
            if (!Short(srcDir))
            {   // solver keeps its work dir in an 80-char field; use a short scratch dir and copy back
                work = Path.Combine(SolverRun.ShortWorkRoot(), inBase.Length > 12 ? inBase.Substring(0, 12) : inBase);
                Directory.CreateDirectory(work); File.Copy(linBox.Text, Path.Combine(work, inBase + ".lin"), true); copied = true;
            }
            var o = new RunOptions { ExePath = Program.DefaultSolver, WorkDir = work, InputBase = inBase, OutputBase = outName, LogPath = Path.Combine(work, outName + ".runner.log") };
            lastWorkDir = srcDir; outputs.Items.Clear(); logBox.Clear(); exitCode = -999; state = "running"; runBtn.Enabled = false; openBtn.Enabled = false; clock = Stopwatch.StartNew(); tick.Start();
            var run = new SolverRun();
            run.Status += delegate(string line) { try { BeginInvoke((Action)delegate { logBox.AppendText(line + "\r\n"); }); } catch { } };
            worker = new Thread(delegate()
            {
                RunResult r = run.Run(o);
                if (copied) foreach (var f in r.Outputs) File.Copy(f, Path.Combine(srcDir, Path.GetFileName(f)), true);
                exitCode = r.ExitCode;
                BeginInvoke((Action)delegate
                {
                    foreach (var f in r.Outputs) outputs.Items.Add(Path.GetFileName(f) + "  (" + new FileInfo(f).Length + " bytes)");
                    state = r.Success ? "finished" : "failed: " + (r.Error != "" ? r.Error : "exit code " + r.ExitCode);
                    runBtn.Enabled = true; openBtn.Enabled = true; tick.Stop(); Refresh_(); if (mutex != null) { mutex.ReleaseMutex(); mutex.Close(); mutex = null; }
                });
            });
            worker.IsBackground = true; worker.Start();
        }

        void Refresh_()
        {
            string el = clock == null ? "" : "  elapsed " + clock.Elapsed.TotalSeconds.ToString("F0") + " s";
            status.Text = state == "running" ? "running..." + el : state + (exitCode != -999 ? "  (solver exit code " + exitCode + ")" : "") + el;
        }
    }
}
