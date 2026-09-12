// Drives one ATBV3.exe run: starts the unmodified solver in a work dir, answers its five
// QuickWin prompts through the selected input route, dismisses the QuickWin exit prompt,
// and reports the output files. The solver binary is never touched; only keystrokes and files.
using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Drawing;
using System.Drawing.Imaging;
using System.IO;
using System.Linq;
using System.Security.Cryptography;
using System.Text;
using System.Threading;

namespace Atb.App.Solver
{
    public enum FeedMode { PostChar, PostCharDeep, PostKey, SendInput, SendKeys, ConIn, Stdin, None, Handoff }

    public class RunOptions
    {
        public string ExePath, WorkDir, InputBase, OutputBase;
        public FeedMode Mode = FeedMode.PostChar;
        public int TimeoutSec = 900;          // hard cap for one solver run
        public int NoOutputAbortSec = 45;     // if no .aou appears this long after feeding, the input route failed
        public string LogPath, ScreenshotDir;
        public bool DeleteParms = true, SeedParms = false, EnumOnly = false, Foreground = false;
        public string[] Answers;              // null = standard 5 answers
        public int SettleMs = 1500, LineGapMs = 400;
        public string HandoffDir;             // Handoff mode only: folder named in C:\ATBFIG.SYS (null = work dir; ATB 3I used System32)
    }

    public class RunResult
    {
        public bool Success; public int ExitCode = -999; public string Error = ""; public double ElapsedSec;
        public List<string> Outputs = new List<string>(); public int DialogsDismissed; public string FeedTarget = "";
        public double SecToWindow = -1, SecToAou = -1, SecToDialog = -1, SecToExit = -1;
    }

    public class SolverRun
    {
        public event Action<string> Status;
        readonly StringBuilder log = new StringBuilder();
        StreamWriter logFile;
        Stopwatch sw;

        public string LogText { get { return log.ToString(); } }

        void Log(string s)
        {
            string line = string.Format("[{0,8:F2}] {1}", sw == null ? 0 : sw.Elapsed.TotalSeconds, s);
            log.AppendLine(line);
            if (logFile != null) { logFile.WriteLine(line); logFile.Flush(); }
            var h = Status; if (h != null) h(line);
        }

        // A short, space-free folder the solver can echo into its 80-column directory line. Same order as verify.bat.
        public static string ShortWorkRoot()
        {
            foreach (var c in new[] { Environment.GetEnvironmentVariable("PUBLIC"), Environment.GetEnvironmentVariable("LOCALAPPDATA"), Path.GetTempPath() })
            {
                if (string.IsNullOrEmpty(c)) continue;
                string d = Path.Combine(c, "ATBRun");
                try { Directory.CreateDirectory(d); File.WriteAllText(Path.Combine(d, ".w"), ""); File.Delete(Path.Combine(d, ".w")); }
                catch { continue; }
                if (d.Length <= 40 && !d.Contains(" ")) return d;
            }
            return Path.Combine(Path.GetTempPath(), "ATBRun");
        }

        public static string Sha256(string path)
        {
            using (var f = File.OpenRead(path)) using (var h = SHA256.Create()) return BitConverter.ToString(h.ComputeHash(f)).Replace("-", "").ToLowerInvariant();
        }

        static readonly string[] OutExts = { ".aou", ".sa1", ".dbg", ".tp1", ".st1", ".st2" };
        static bool IsOutputExt(string ext)
        {
            ext = ext.ToLowerInvariant();
            if (OutExts.Contains(ext)) return true;
            return ext.Length == 4 && ext[0] == '.' && ext[1] == 't' && char.IsDigit(ext[2]) && char.IsDigit(ext[3]);
        }

        public static List<string> OutputsOf(string workDir, string outBase)
        {
            var list = new List<string>();
            foreach (var p in Directory.GetFiles(workDir, outBase + ".*"))
                if (string.Equals(Path.GetFileNameWithoutExtension(p), outBase, StringComparison.OrdinalIgnoreCase) && IsOutputExt(Path.GetExtension(p))) list.Add(p);
            list.Sort(StringComparer.OrdinalIgnoreCase);
            return list;
        }

        public RunResult Run(RunOptions o)
        {
            var r = new RunResult();
            sw = Stopwatch.StartNew();
            if (o.LogPath != null) { logFile = new StreamWriter(o.LogPath, true); }
            Process p = null;
            try
            {
                Log("ATBRunner run: exe=" + o.ExePath + " work=" + o.WorkDir + " in=" + o.InputBase + " out=" + o.OutputBase + " mode=" + o.Mode + (o.SeedParms ? " seed-parms" : "") + (o.Foreground ? " foreground" : ""));
                if (!File.Exists(o.ExePath)) { r.Error = "solver exe not found: " + o.ExePath; return r; }
                if (!Directory.Exists(o.WorkDir)) { r.Error = "work dir not found: " + o.WorkDir; return r; }
                if (o.WorkDir.Length > 79) { r.Error = "work dir path longer than 79 chars (solver stores it in an 80-char field): " + o.WorkDir; return r; }
                if (o.InputBase.Length > 32 || o.OutputBase.Length > 32) { r.Error = "input/output base name longer than 32 chars"; return r; }
                string lin = Directory.GetFiles(o.WorkDir, o.InputBase + ".lin").FirstOrDefault();
                if (lin == null) { r.Error = "no " + o.InputBase + ".lin in " + o.WorkDir; return r; }
                Log("exe sha256=" + Sha256(o.ExePath) + " size=" + new FileInfo(o.ExePath).Length);
                uint mySid; Win32.ProcessIdToSessionId((uint)Process.GetCurrentProcess().Id, out mySid);
                Log("session: mine=" + mySid + " console=" + Win32.WTSGetActiveConsoleSessionId() + " interactive=" + Environment.UserInteractive + " fg=0x" + Win32.GetForegroundWindow().ToInt64().ToString("X") + " (" + Win32.ClassOf(Win32.GetForegroundWindow()) + ")");

                // stale outputs with the same name would mask a failed run
                foreach (var f in OutputsOf(o.WorkDir, o.OutputBase)) { File.Delete(f); Log("deleted stale " + Path.GetFileName(f)); }
                string parms = Path.Combine(o.WorkDir, "atb_parms.mem");
                if (o.DeleteParms && File.Exists(parms)) { File.Delete(parms); Log("deleted atb_parms.mem"); }
                if (o.SeedParms) { File.WriteAllText(parms, o.WorkDir.PadRight(79) + "\r\n"); Log("seeded atb_parms.mem with work dir"); }

                if (o.Mode == FeedMode.Handoff && !Handoff(o, lin, r)) return r;

                var psi = new ProcessStartInfo(o.ExePath);
                psi.WorkingDirectory = o.WorkDir; psi.UseShellExecute = false; psi.RedirectStandardInput = (o.Mode == FeedMode.Stdin);
                p = Process.Start(psi);
                Log("started pid=" + p.Id);

                string[] answers = o.Answers ?? new[] { "y", "", "l", o.InputBase, o.OutputBase };
                string aou = Path.Combine(o.WorkDir, o.OutputBase + ".aou");

                if (o.Mode == FeedMode.Stdin)
                {
                    foreach (var a in answers) { p.StandardInput.Write(a + "\r\n"); }
                    p.StandardInput.Flush(); p.StandardInput.Close();
                    Log("stdin: wrote " + answers.Length + " lines and closed");
                }

                // wait for a visible top-level window of the solver
                List<Win32.WinInfo> wins = null; IntPtr frame = IntPtr.Zero; var tw = Stopwatch.StartNew();
                while (tw.Elapsed.TotalSeconds < 20 && !p.HasExited)
                {
                    wins = Win32.TopWindowsOf(p.Id);
                    var vis = wins.FirstOrDefault(w => w.Visible && w.Class != "#32770");
                    if (vis != null) { frame = vis.H; break; }
                    Thread.Sleep(100);
                }
                r.SecToWindow = sw.Elapsed.TotalSeconds;
                if (frame == IntPtr.Zero) Log("no visible top-level window after 20 s (exited=" + p.HasExited + ")");
                else Log("frame window seen: " + Win32.Info(frame, 0));
                Thread.Sleep(o.SettleMs);
                DumpWindows(p.Id, "after settle");
                Shot(o, "01-window");

                if (o.EnumOnly)
                {
                    for (int i = 0; i < 6 && !p.HasExited; i++) { Thread.Sleep(1000); DumpWindows(p.Id, "enum t+" + (i + 1)); }
                    Shot(o, "02-enum"); Kill(p); r.Error = "enum-only"; return r;
                }

                if (!p.HasExited && o.Mode != FeedMode.Stdin && o.Mode != FeedMode.None && o.Mode != FeedMode.Handoff) Feed(o, p, frame, answers, r);
                double fedAt = sw.Elapsed.TotalSeconds;
                Log("fed; monitoring");

                bool aouSeen = false; double lastProgress = sw.Elapsed.TotalSeconds; var lastDump = sw.Elapsed.TotalSeconds;
                while (true)
                {
                    if (p.WaitForExit(250)) break;
                    double now = sw.Elapsed.TotalSeconds;
                    if (!aouSeen && (File.Exists(aou) || (o.Mode == FeedMode.Handoff && File.Exists(Path.Combine(o.HandoffDir ?? o.WorkDir, o.OutputBase + ".aou"))))) { aouSeen = true; r.SecToAou = now; Log(".aou appeared: input accepted"); Shot(o, "03-running"); }
                    if (aouSeen && now - lastProgress > 5) { lastProgress = now; var fi = new FileInfo(aou); Log("progress: .aou " + fi.Length + " bytes"); }
                    var dlg = Win32.TopWindowsOf(p.Id).FirstOrDefault(w => w.Visible && w.Class == "#32770");
                    if (dlg != null)
                    {
                        if (r.SecToDialog < 0) { r.SecToDialog = now; Shot(o, "04-dialog"); }
                        Log("dialog: " + dlg + " text=[" + DialogText(dlg.H) + "]");
                        Dismiss(dlg.H); r.DialogsDismissed++;
                        Thread.Sleep(500);
                    }
                    if (!aouSeen && now - fedAt > o.NoOutputAbortSec)
                    {
                        if (now - lastDump > 10) { lastDump = now; DumpWindows(p.Id, "no output yet"); Shot(o, "05-stuck"); }
                        r.Error = "no .aou within " + o.NoOutputAbortSec + " s after feeding: input route did not reach the solver"; Kill(p); break;
                    }
                    if (now > o.TimeoutSec) { r.Error = "timeout after " + o.TimeoutSec + " s"; Shot(o, "06-timeout"); Kill(p); break; }
                }
                r.SecToExit = sw.Elapsed.TotalSeconds;
                try { r.ExitCode = p.ExitCode; } catch { }
                Log("process exited code=" + r.ExitCode + " after " + r.SecToExit.ToString("F1") + " s; dialogs dismissed=" + r.DialogsDismissed);
                if (o.Mode == FeedMode.Handoff) SweepHandoffOutputs(o);
                r.Outputs = OutputsOf(o.WorkDir, o.OutputBase);
                foreach (var f in r.Outputs) Log("output " + Path.GetFileName(f) + " " + new FileInfo(f).Length + " B sha256=" + Sha256(f));
                bool t21 = r.Outputs.Any(f => f.EndsWith(".t21", StringComparison.OrdinalIgnoreCase) && new FileInfo(f).Length > 0);
                r.Success = r.Error == "" && (r.ExitCode == 0 || r.ExitCode == 1) && File.Exists(aou) && new FileInfo(aou).Length > 0;
                Log("RESULT " + (r.Success ? "OK" : "FAIL") + " exit=" + r.ExitCode + " outputs=" + r.Outputs.Count + " t21=" + t21 + (r.Error != "" ? " error=" + r.Error : ""));
            }
            catch (Exception ex) { r.Error = ex.GetType().Name + ": " + ex.Message; Log("EXCEPTION " + ex); if (p != null) Kill(p); }
            finally { r.ElapsedSec = sw.Elapsed.TotalSeconds; if (logFile != null) { logFile.Close(); logFile = null; } }
            return r;
        }

        // Rung 1: exactly what ATB 3I (VB.NET, 2005) does before Process.Start(ATBV3.exe): the ATB3I build of
        // the solver reads C:\ATBFIG.SYS (written by the installer: length + path of the handoff folder,
        // length + path of a temp folder), then <handoff>\winintm.sys (the input deck) and
        // <handoff>\execatb.dat ("101" = .LIN run, then the output base name). No prompts.
        bool Handoff(RunOptions o, string lin, RunResult r)
        {
            string fig = @"C:\ATBFIG.SYS";
            string dir = (o.HandoffDir ?? o.WorkDir).TrimEnd('\\') + "\\";
            string tmp = Path.Combine(Environment.GetEnvironmentVariable("windir") ?? @"C:\Windows", "Temp") + "\\";
            string content = " " + dir.Length + " \r\n" + dir + "\r\n " + tmp.Length + " \r\n" + tmp + "\r\n";
            try { File.WriteAllText(fig, content); Log("handoff: wrote " + fig + " = " + content.Replace("\r\n", "|")); }
            catch (Exception ex) { r.Error = "cannot write " + fig + " (the ATB 3I installer wrote it as admin): " + ex.Message; Log(r.Error); return false; }
            File.Copy(lin, Path.Combine(dir, "winintm.sys"), true);
            File.WriteAllText(Path.Combine(dir, "execatb.dat"), "101\r\n" + o.OutputBase + "\r\n");
            Log("handoff: wrote winintm.sys (copy of " + Path.GetFileName(lin) + ") and execatb.dat [101|" + o.OutputBase + "] in " + dir);
            Thread.Sleep(500);
            return true;
        }

        void SweepHandoffOutputs(RunOptions o)
        {
            var dirs = new List<string> { o.HandoffDir ?? o.WorkDir, Path.GetDirectoryName(o.ExePath), Path.Combine(Environment.GetEnvironmentVariable("windir") ?? @"C:\Windows", "Temp"), @"C:\", Environment.SystemDirectory, Environment.CurrentDirectory };
            foreach (var d in dirs.Distinct())
            {
                if (string.Equals(d.TrimEnd('\\'), o.WorkDir.TrimEnd('\\'), StringComparison.OrdinalIgnoreCase)) continue;
                try
                {
                    foreach (var f in OutputsOf(d, o.OutputBase))
                    {
                        string dest = Path.Combine(o.WorkDir, Path.GetFileName(f));
                        Log("handoff: output found outside work dir: " + f + " -> copied to work dir"); File.Copy(f, dest, true); File.Delete(f);
                    }
                }
                catch (Exception ex) { Log("handoff sweep " + d + ": " + ex.Message); }
            }
        }

        void Feed(RunOptions o, Process p, IntPtr frame, string[] answers, RunResult r)
        {
            uint tid = 0; if (frame != IntPtr.Zero) { uint pid; tid = Win32.GetWindowThreadProcessId(frame, out pid); }
            var all = Win32.AllWindowsOf(p.Id);
            IntPtr focus = tid != 0 ? Win32.FocusWindowOfThread(tid) : IntPtr.Zero;
            IntPtr active = tid != 0 ? Win32.ActiveWindowOfThread(tid) : IntPtr.Zero;
            var deep = all.Where(w => w.Visible).OrderByDescending(w => w.Depth).ThenByDescending(w => (long)(w.R.Right - w.R.Left) * (w.R.Bottom - w.R.Top)).FirstOrDefault();
            Log("thread focus=0x" + focus.ToInt64().ToString("X") + " (" + Win32.ClassOf(focus) + ") active=0x" + active.ToInt64().ToString("X") + " deepest=" + (deep == null ? "none" : deep.ToString()));

            IntPtr target = IntPtr.Zero;
            switch (o.Mode)
            {
                case FeedMode.PostChar:
                case FeedMode.PostKey:
                    target = focus != IntPtr.Zero ? focus : (deep != null ? deep.H : frame); break;
                case FeedMode.PostCharDeep:
                    target = deep != null ? deep.H : frame; break;
            }
            if (o.Foreground || o.Mode == FeedMode.SendInput || o.Mode == FeedMode.SendKeys)
            {
                Log("bringing frame to foreground");
                Win32.AllowSetForegroundWindow(-1);
                if (Win32.IsIconic(frame)) Win32.ShowWindow(frame, Win32.SW_RESTORE);
                uint me = Win32.GetCurrentThreadId(); uint fgTid = 0; { uint x; fgTid = Win32.GetWindowThreadProcessId(Win32.GetForegroundWindow(), out x); }
                if (fgTid != 0 && fgTid != me) Win32.AttachThreadInput(me, fgTid, true);
                Win32.BringWindowToTop(frame); bool ok = Win32.SetForegroundWindow(frame);
                if (fgTid != 0 && fgTid != me) Win32.AttachThreadInput(me, fgTid, false);
                Thread.Sleep(300);
                Log("SetForegroundWindow=" + ok + " fg now=0x" + Win32.GetForegroundWindow().ToInt64().ToString("X") + " focus now=0x" + Win32.FocusWindowOfThread(tid).ToInt64().ToString("X") + " (" + Win32.ClassOf(Win32.FocusWindowOfThread(tid)) + ")");
                if (o.Mode == FeedMode.PostChar || o.Mode == FeedMode.PostKey) { var f2 = Win32.FocusWindowOfThread(tid); if (f2 != IntPtr.Zero) target = f2; }
            }
            if (target != IntPtr.Zero) r.FeedTarget = Win32.Info(target, 0).ToString();
            Log("feed target: " + (target == IntPtr.Zero ? "(none)" : r.FeedTarget));

            for (int i = 0; i < answers.Length; i++)
            {
                string line = answers[i] + "\r";
                switch (o.Mode)
                {
                    case FeedMode.PostChar:
                    case FeedMode.PostCharDeep:
                        foreach (char c in line) Win32.PostChar(target, c); break;
                    case FeedMode.PostKey:
                        foreach (char c in line) Win32.PostKeyAndChar(target, c); break;
                    case FeedMode.SendInput:
                        Win32.SendInputText(line); break;
                    case FeedMode.SendKeys:
                        UiaFocusAndSendKeys(frame, answers[i]); break;
                    case FeedMode.ConIn:
                        {
                            string err; bool at = Win32.AttachConsole(p.Id); int gle = System.Runtime.InteropServices.Marshal.GetLastWin32Error();
                            Log("AttachConsole(" + p.Id + ")=" + at + " gle=" + gle);
                            bool ok = Win32.WriteConIn(line, out err); Log("WriteConsoleInput ok=" + ok + " " + err);
                            if (at) Win32.FreeConsole();
                            break;
                        }
                }
                Log("sent line " + (i + 1) + ": \"" + answers[i] + "\"");
                Thread.Sleep(o.LineGapMs);
            }
        }

        void UiaFocusAndSendKeys(IntPtr frame, string text)
        {
            try
            {
                var asm = System.Reflection.Assembly.Load("UIAutomationClient, Version=4.0.0.0, Culture=neutral, PublicKeyToken=31bf3856ad364e35");
                var aeType = asm.GetType("System.Windows.Automation.AutomationElement");
                var el = aeType.GetMethod("FromHandle").Invoke(null, new object[] { frame });
                aeType.GetMethod("SetFocus").Invoke(el, null);
                Log("UIA SetFocus on frame: name=" + aeType.GetProperty("Current").GetValue(el, null).GetType().GetProperty("Name").GetValue(aeType.GetProperty("Current").GetValue(el, null), null));
            }
            catch (Exception ex) { Log("UIA focus failed: " + ex.GetType().Name + ": " + ex.Message); }
            string esc = "";
            foreach (char c in text) esc += ("+^%~(){}[]".IndexOf(c) >= 0) ? "{" + c + "}" : c.ToString();
            System.Windows.Forms.SendKeys.SendWait(esc + "{ENTER}");
        }

        string DialogText(IntPtr dlg)
        {
            var sb = new StringBuilder();
            Win32.EnumChildWindows(dlg, delegate(IntPtr h, IntPtr lp) { var t = Win32.TitleOf(h); if (t.Length > 0) sb.Append("<" + Win32.ClassOf(h) + ":" + t.Replace("\r", " ").Replace("\n", " ") + "> "); return true; }, IntPtr.Zero);
            return sb.ToString();
        }

        void Dismiss(IntPtr dlg)
        {
            Log("dismissing dialog: WM_COMMAND IDYES");
            Win32.PostMessage(dlg, Win32.WM_COMMAND, (IntPtr)Win32.IDYES, IntPtr.Zero);
            Thread.Sleep(700);
            if (!Win32.IsWindow(dlg) || !Win32.IsWindowVisible(dlg)) return;
            IntPtr btn = IntPtr.Zero;
            Win32.EnumChildWindows(dlg, delegate(IntPtr h, IntPtr lp) { var t = Win32.TitleOf(h).Replace("&", ""); if (Win32.ClassOf(h) == "Button" && (t == "Yes" || t == "OK")) { btn = h; return false; } return true; }, IntPtr.Zero);
            if (btn != IntPtr.Zero) { Log("dismissing dialog: BM_CLICK on " + Win32.TitleOf(btn)); Win32.PostMessage(btn, Win32.BM_CLICK, IntPtr.Zero, IntPtr.Zero); Thread.Sleep(700); }
            if (Win32.IsWindow(dlg) && Win32.IsWindowVisible(dlg)) { Log("dismissing dialog: WM_CLOSE"); Win32.PostMessage(dlg, Win32.WM_CLOSE, IntPtr.Zero, IntPtr.Zero); }
        }

        void DumpWindows(int pid, string tag)
        {
            var all = Win32.AllWindowsOf(pid);
            Log("windows (" + tag + "): " + all.Count);
            foreach (var w in all) Log("   " + new string(' ', w.Depth * 2) + w);
        }

        void Shot(RunOptions o, string name)
        {
            if (string.IsNullOrEmpty(o.ScreenshotDir)) return;
            try
            {
                Directory.CreateDirectory(o.ScreenshotDir);
                var b = System.Windows.Forms.SystemInformation.VirtualScreen;
                using (var bmp = new Bitmap(b.Width, b.Height)) using (var g = Graphics.FromImage(bmp))
                { g.CopyFromScreen(b.Left, b.Top, 0, 0, b.Size); bmp.Save(Path.Combine(o.ScreenshotDir, name + ".png"), ImageFormat.Png); }
                Log("screenshot " + name + " " + b.Width + "x" + b.Height);
            }
            catch (Exception ex) { Log("screenshot failed: " + ex.Message); }
        }

        static void Kill(Process p) { try { if (!p.HasExited) { p.Kill(); p.WaitForExit(5000); } } catch { } }
    }
}
