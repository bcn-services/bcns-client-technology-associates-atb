using System.Diagnostics;
using System.Text;
using Atb.Core.Solver;
using FlaUI.Core.Capturing;
using Xunit;

namespace Atb.App.UiTests;

/// Gebodv.exe (shipped beside ATB.exe) fed Gebod.Answers for a 50th-percentile adult male, once without and once with
/// C:\ATBFIG.SYS. Writes $E2E_OUT/gebod/probe.txt and GEBOD.ain. Only the with-ATBFIG run is asserted; the other is recorded.
public class GebodProbe
{
    const string Fig = @"C:\ATBFIG.SYS";

    [Fact]
    public void Gebodv_50thPercentileMale_WithAndWithoutAtbFig()
    {
        var outDir = Path.Combine(Robot.Out, "gebod"); Directory.CreateDirectory(outDir);
        var exeDir = Path.GetDirectoryName(Robot.Exe)!;
        var ans = Gebod.Answers(new GebodRequest("50TH PERCENTILE ADULT MALE", 3, 3, Weight: new(3, 50), Height: new(3, 50)));
        var rep = new StringBuilder($"answers: {string.Join(" | ", ans)}\n");
        var backup = File.Exists(Fig) ? File.ReadAllBytes(Fig) : null;
        rep.Append($"C:\\ATBFIG.SYS before probe: {(backup == null ? "absent" : "present")}\n");
        string? with;
        try
        {
            File.Delete(Fig);
            Run(exeDir, Path.Combine(Robot.Work, "g0"), ans, rep, "WITHOUT C:\\ATBFIG.SYS", outDir);
            var w = Path.Combine(Robot.Work, "g1");
            Prepare(exeDir, w);
            var tmp = Path.Combine(Environment.GetEnvironmentVariable("windir") ?? @"C:\Windows", "Temp");
            File.WriteAllText(Fig, Gebod.AtbFig(w, tmp));
            rep.Append($"C:\\ATBFIG.SYS written: [{File.ReadAllText(Fig).Replace("\r\n", "|")}]\n");
            with = Run(exeDir, w, ans, rep, "WITH C:\\ATBFIG.SYS", outDir);
        }
        finally
        {
            if (backup != null) File.WriteAllBytes(Fig, backup); else File.Delete(Fig);
            File.WriteAllText(Path.Combine(outDir, "probe.txt"), rep.ToString());
        }
        Assert.True(with != null, "Gebodv.exe wrote no GEBOD.ain with C:\\ATBFIG.SYS present; see gebod/probe.txt");
        File.Copy(with!, Path.Combine(outDir, "GEBOD.ain"), true);
    }

    static void Prepare(string exeDir, string dir)
    {
        if (Directory.Exists(dir)) Directory.Delete(dir, true);
        Directory.CreateDirectory(dir);
        File.Copy(Path.Combine(exeDir, "GEBOD.DAT"), Path.Combine(dir, "GEBOD.DAT"));
    }

    /// One Gebodv.exe run in dir (cwd). Returns the GEBOD.ain it wrote in dir, or null.
    static string? Run(string exeDir, string dir, string[] ans, StringBuilder rep, string label, string outDir)
    {
        if (!Directory.Exists(dir)) Prepare(exeDir, dir);
        var psi = new ProcessStartInfo(Path.Combine(exeDir, "Gebodv.exe"))
        {
            WorkingDirectory = dir, UseShellExecute = false, CreateNoWindow = true,
            RedirectStandardInput = true, RedirectStandardOutput = true, RedirectStandardError = true,
        };
        var sw = Stopwatch.StartNew();
        using var p = Process.Start(psi)!;
        var so = p.StandardOutput.ReadToEndAsync(); var se = p.StandardError.ReadToEndAsync();
        p.StandardInput.NewLine = "\r\n";
        try { foreach (var a in ans) p.StandardInput.WriteLine(a); p.StandardInput.Close(); }
        catch (IOException e) { rep.Append($"[{label}] stdin closed early: {e.Message}\n"); }
        bool exited = p.WaitForExit(60_000);
        if (!exited)
        {
            using (var img = Capture.Screen()) img.ToFile(Path.Combine(outDir, $"timeout-{(label.StartsWith("WITHOUT") ? "without" : "with")}-atbfig.png"));
            p.Kill(true); p.WaitForExit(5000);
        }
        var ain = Path.Combine(dir, "GEBOD.ain");
        bool made = File.Exists(ain) && new FileInfo(ain).Length > 0;
        rep.Append($"\n== {label}: cwd {dir}\n")
           .Append($"exit code: {(exited ? p.ExitCode.ToString() : "none (killed after 60 s)")}, {sw.Elapsed.TotalSeconds:F1} s\n")
           .Append($"GEBOD.ain produced: {(made ? $"yes, {new FileInfo(ain).Length} bytes" : "no")}\n")
           .Append($"files in cwd: {string.Join(", ", Directory.GetFiles(dir).Select(Path.GetFileName))}\n")
           .Append($"--- stdout (last 40 lines)\n{Tail(so.Result)}\n--- stderr (last 40 lines)\n{Tail(se.Result)}\n");
        return made ? ain : null;
    }

    static string Tail(string s) => string.Join("\n", s.Replace("\r", "").Split('\n').TakeLast(40));
}
