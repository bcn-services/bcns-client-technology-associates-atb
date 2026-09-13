namespace Atb.Core.Solver;

/// ATB 3I's execatb.dat job codes (decompile MainMenu.cs:3092-3101): 101 = run a .LIN deck, 102 = convert .AIN -> .LIN.
public enum SolverMode { RunLin = 101, ConvertAin = 102 }

/// Platform-neutral half of a solver run: what to type at the solver's prompts, and what to keep afterwards.
public static class SolverJob
{
    /// Lines typed at the unmodified solver's prompts, in order (src/input_files.for):
    ///   "y"  terms prompt (:66)   ""  keep default working dir (:118)   input-type prompt (:155)
    ///   101: "l" -> .LIN input name (:206) -> output name (:262)
    ///   102: "a" -> "y" to "create a list-directed file ... with the extension .LIN?" (:176) -> .AIN input name (:232) -> output name (:262)
    /// The 102 sequence is the stdin equivalent of ATB 3I's handoff "102" (MainMenu.cs:3101); the converted
    /// deck is written as <input base>.lin in the work dir (src/input_files.for:289).
    public static string[] Answers(SolverMode mode, string inputBase, string outputBase) => mode switch
    {
        SolverMode.RunLin => ["y", "", "l", inputBase, outputBase],
        SolverMode.ConvertAin => ["y", "", "a", "y", inputBase, outputBase],
        _ => throw new ArgumentOutOfRangeException(nameof(mode)),
    };

    /// Input extension the solver reads for this mode.
    public static string InputExt(SolverMode mode) => mode == SolverMode.ConvertAin ? ".ain" : ".lin";

    static readonly string[] OutExts = [".aou", ".sa1", ".dbg", ".tp1", ".st1", ".st2"];

    /// Solver output extension: .aou/.sa1/.dbg/.tp1/.st1/.st2 or a .tNN time-history file (.t21 ...).
    public static bool IsOutputExt(string ext)
    {
        ext = ext.ToLowerInvariant();
        return OutExts.Contains(ext) || (ext.Length == 4 && ext[0] == '.' && ext[1] == 't' && char.IsDigit(ext[2]) && char.IsDigit(ext[3]));
    }

    /// Files in workDir named <outBase>.<output ext>, sorted. Convert mode also keeps the generated <outBase>.lin.
    public static List<string> Outputs(string workDir, string outBase, SolverMode mode = SolverMode.RunLin)
    {
        var list = Directory.GetFiles(workDir, outBase + ".*")
            .Where(p => string.Equals(Path.GetFileNameWithoutExtension(p), outBase, StringComparison.OrdinalIgnoreCase))
            .Where(p => IsOutputExt(Path.GetExtension(p)) || (mode == SolverMode.ConvertAin && Path.GetExtension(p).Equals(".lin", StringComparison.OrdinalIgnoreCase)))
            .ToList();
        list.Sort(StringComparer.OrdinalIgnoreCase);
        return list;
    }

    /// Ends a run: only when it succeeded, copies each output <outBase>.<ext> in workDir to destDir\<destBase>.<ext>
    /// (overwriting; the user confirmed the name in a Save dialog, as ATB 3I did, MainMenu.cs:3072-3081). Always
    /// deletes workDir, even when a copy throws. Returns the copied paths (empty unless succeeded). A missing workDir is fine.
    public static List<string> Finish(string workDir, string outBase, string destDir, string destBase, SolverMode mode, bool succeeded)
    {
        var copied = new List<string>();
        if (!Directory.Exists(workDir)) return copied;
        try
        {
            if (succeeded)
            {
                foreach (var f in Outputs(workDir, outBase, mode))
                {
                    var to = Path.Combine(destDir, destBase + Path.GetExtension(f));
                    File.Copy(f, to, true);
                    copied.Add(to);
                }
            }
        }
        finally { DeleteDir(workDir); }
        return copied;
    }

    // A killed solver can hold its files for a moment after exit; retry briefly.
    static void DeleteDir(string dir)
    {
        for (int i = 0; ; i++)
        {
            try { Directory.Delete(dir, true); return; }
            catch (IOException) when (i < 10) { Thread.Sleep(200); }
            catch (UnauthorizedAccessException) when (i < 10) { Thread.Sleep(200); }
        }
    }
}
