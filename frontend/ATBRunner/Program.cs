// ATBRunner entry point. GUI when started with no arguments; batch when --lin is given.
// Batch and GUI share SolverRun (one code path). The solver binary is hash-checked before every use.
using System;
using System.Collections.Generic;
using System.IO;
using System.Threading;
using System.Windows.Forms;

namespace ATBRunner
{
    static class Program
    {
        public const string Version = "0.1";
        public static string ExeDir { get { return Path.GetDirectoryName(Application.ExecutablePath); } }
        public static string DefaultSolver { get { return Path.Combine(ExeDir, "ATBV3.exe"); } }

        // returns null if ok, else an error message
        public static string CheckSolver(string path, out string sha)
        {
            sha = null;
            if (!File.Exists(path)) return "ATBV3.exe not found next to ATBRunner.exe: " + path;
            sha = SolverRun.Sha256(path);
            if (Hashes.Describe(sha) == null) return "ATBV3.exe SHA-256 does not match the client's original binary. Refusing to run.\n" + path + "\n" + sha;
            return null;
        }

        [STAThread]
        static int Main(string[] args)
        {
            if (args.Length == 0)
            {
                Application.EnableVisualStyles();
                Application.SetCompatibleTextRenderingDefault(false);
                Application.Run(new MainForm());
                return 0;
            }
            Win32.AttachConsole(-1); // echo to the parent console when run from cmd/verify.bat
            if (args[0] == "--strip-hash") return StripHash(args);
            var o = new RunOptions(); string exe = null; bool enumOnly = false;
            for (int i = 0; i < args.Length; i++)
            {
                string a = args[i]; string v = i + 1 < args.Length ? args[i + 1] : null;
                switch (a.ToLowerInvariant())
                {
                    case "--lin": o.InputBase = Path.GetFileNameWithoutExtension(v); if (o.WorkDir == null && Path.IsPathRooted(v)) o.WorkDir = Path.GetDirectoryName(v); i++; break;
                    case "--out": o.OutputBase = v; i++; break;
                    case "--dir": o.WorkDir = Path.GetFullPath(v); i++; break;
                    case "--exe": exe = Path.GetFullPath(v); i++; break;
                    case "--feed": o.Mode = (FeedMode)Enum.Parse(typeof(FeedMode), v, true); i++; break;
                    case "--log": o.LogPath = Path.GetFullPath(v); i++; break;
                    case "--shots": o.ScreenshotDir = Path.GetFullPath(v); i++; break;
                    case "--timeout": o.TimeoutSec = int.Parse(v); i++; break;
                    case "--abort-after": o.NoOutputAbortSec = int.Parse(v); i++; break;
                    case "--seed-parms": o.SeedParms = true; break;
                    case "--handoff-dir": o.HandoffDir = string.Equals(v, "system32", StringComparison.OrdinalIgnoreCase) ? Environment.SystemDirectory : Path.GetFullPath(v); i++; break;
                    case "--keep-parms": o.DeleteParms = false; break;
                    case "--foreground": o.Foreground = true; break;
                    case "--enum": enumOnly = true; break;
                    case "--answers": o.Answers = v.Split('|'); i++; break;
                    case "--help": case "-h": case "/?": Console.WriteLine(Usage()); return 0;
                    default: Console.Error.WriteLine("unknown option " + a); Console.Error.WriteLine(Usage()); return 2;
                }
            }
            if (o.InputBase == null || o.WorkDir == null) { Console.Error.WriteLine(Usage()); return 2; }
            if (o.OutputBase == null) o.OutputBase = o.InputBase + "_new";
            o.EnumOnly = enumOnly;
            o.ExePath = exe ?? DefaultSolver;
            string sha; string err = CheckSolver(o.ExePath, out sha);
            if (err != null) { Console.Error.WriteLine("REFUSED: " + err); return 3; }
            bool created; using (var m = new Mutex(true, "Local\\ATBRunner.SingleRun", out created))
            {
                if (!created) { Console.Error.WriteLine("REFUSED: another ATBRunner run is in progress"); return 4; }
                var run = new SolverRun();
                run.Status += delegate(string s) { Console.WriteLine(s); };
                var r = run.Run(o);
                Console.WriteLine("ATBRunner: " + (r.Success ? "FINISHED" : "FAILED") + " exit=" + r.ExitCode + " elapsed=" + r.ElapsedSec.ToString("F1") + "s outputs=" + r.Outputs.Count + (r.Error != "" ? " error=" + r.Error : ""));
                return r.Success ? 0 : 1;
            }
        }

        // --strip-hash FILE... [--volatile volatile.txt]  -> "<sha256> <dropped>/<total> <file>" per file
        static int StripHash(string[] args)
        {
            string vol = null, outFile = null; var files = new List<string>();
            for (int i = 1; i < args.Length; i++) { if (args[i] == "--volatile") vol = args[++i]; else if (args[i] == "--outfile") outFile = args[++i]; else files.Add(args[i]); }
            var pats = Strip.LoadVolatile(vol ?? Path.Combine(ExeDir, "volatile.txt"));
            int rc = 0; var sb = new System.Text.StringBuilder();
            foreach (var f in files)
            {
                string line;
                if (!File.Exists(f)) { line = "MISSING - " + f; rc = 1; }
                else { int t, d; string h = Strip.StrippedHash(f, pats, out t, out d); line = h + " " + d + "/" + t + " " + f; }
                Console.WriteLine(line); sb.Append(line + "\r\n");
            }
            if (outFile != null) File.WriteAllText(outFile, sb.ToString());
            return rc;
        }

        static string Usage()
        {
            return "ATBRunner " + Version + "\n" +
                   "  ATBRunner.exe                       GUI\n" +
                   "  ATBRunner.exe --lin X.LIN --out NAME --dir D   batch (same code path as GUI)\n" +
                   "  options: --exe PATH --feed postchar|postkey|postchardeep|sendinput|sendkeys|conin|stdin|handoff --log FILE --shots DIR\n" +
                   "           --timeout S --abort-after S --seed-parms --keep-parms --foreground --enum --answers a|b|c|d|e\n" +
                   "           --handoff-dir system32|PATH (feed handoff only)\n" +
                   "  ATBRunner.exe --strip-hash FILE... [--volatile volatile.txt] [--outfile F]   SHA-256 with volatile lines masked\n";
        }
    }
}
