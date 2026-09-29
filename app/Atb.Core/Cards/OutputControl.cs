// Output > Control Parameter > General Parameter... / Diagnostic Parameter...: ATB 3I's two StdTable views of [A5]
// (decomp MainMenu.cs:3595-3612 Category=1, :3502-3519 Category=2, both ORDER BY NPRT ASC). Row NPRT n is A.5 token n-1.
using Atb.Core.Lin;

namespace Atb.Core.Cards;

public static class OutputControl
{
    public const int General = 1, Diagnostic = 2;

    /// One `A5Defination` row: NPRT, Control Parameter, Value (3I's new-file default), Category (0 = shown on neither form).
    public sealed record Row(int Nprt, string Name, int Value, int Category);

    /// `mdb-export ATB3iData.mdb A5Defination`, all 36 rows, put in NPRT order (the export's own order is storage order).
    public static readonly IReadOnlyList<Row> Definition =
    [
        new(1, "Unit 1 (.SA1) Output Step", 0, 1), new(2, "Sub ELTIME Table Output", 0, 2), new(3, "Unit 6 (.AOU) Output Step", 0, 1),
        new(4, "Unit 8 (HIC) Output", 0, 1), new(5, "Not Used", 0, 0), new(6, "Not Used", 0, 0), new(7, "Not Used", 0, 0),
        new(8, "IJK, RHS and C Array Output", 0, 2), new(9, "Sub PRINT Output", 0, 2), new(10, "Diagnostic Output in Sub IMPULS", 0, 2),
        new(11, "U2 and V1 Array Output", 0, 2), new(12, "Diagnostic Output in Sub VISPR", 0, 2), new(13, "Not Used", 0, 0),
        new(14, "Wind Force Diagnostic Output", 0, 2), new(15, "Diagnostic Output in Sub BELTG", 0, 2), new(16, "Diagnostic Output in Sub HBELT", 0, 2),
        new(17, "Diagnostic Output in Sub EDEPTH", 0, 2), new(18, "Time History Output", 0, 1), new(19, "Time History Headers", 0, 1),
        new(20, "SEGLP and SEGLV Output", 0, 2), new(21, "Diagnostic Output in Sub AIRBAG", 0, 2), new(22, "Diagnostic Output in Sub AIRBG1", 0, 2),
        new(23, "HT and HB Array Output", 0, 2), new(24, "Roll-Slide Test Output", 0, 2), new(25, "Convergence Test Data Output", 0, 2),
        new(26, "Time History Output Frequency", 0, 1), new(27, "Internediate Results Output", 0, 2), new(28, "Diagnostic Output in Sub HPTURB", 0, 2),
        new(29, "Not Used", 0, 0), new(30, "HIC Data Output Frequency", 0, 1), new(31, "Not Used", 0, 0), new(32, "Not Used", 0, 0),
        new(33, "Used by ATB3i for Weight Balancing", 0, 0), new(34, "Not Used", 0, 0), new(35, "Select VIEW Program Version", 0, 1),
        new(36, "Not Used and Always Is 1", 1, 0),
    ];

    public static IReadOnlyList<Row> Rows(int category) => Definition.Where(r => r.Category == category).ToList();

    public static DeckLine Line(Deck d) => d.Card("A.5") ?? throw new InvalidOperationException("The deck has no A.5 card");

    public static string Value(Deck d, int nprt) => Line(d).Str(nprt - 1);

    /// ATB 3I's one NPRT(4) test, `!= 0 && != 4`: the Output > HIC... menu (MainMenu.cs:4719-4722 on open, StdTable.cs:249 on
    /// A5 OK) and the H.12 card (FileManager.cs:1031 read, :2238 write — both also need NSEG > 0, Labeler's num5).
    public static bool EnablesHic(int nprt4) => nprt4 != 0 && nprt4 != 4;

    /// The deck's NPRT(4) enables HIC (false when A.5 is missing or short).
    public static bool HicEnabled(Deck d) => d.Card("A.5") is { Count: > 3 } a && EnablesHic(a.Int(3));

    /// Writes NPRT(nprt) (Deck.Edit: only that token, nothing when unchanged). Returns null, or why the text was refused.
    /// NPRT(4) also keeps H.12 in step as 3I does: OK with 0 or 4 deletes the H12 records (StdTable.cs:246-262), and any
    /// other value with no H.12 writes 3I's default line (FileManager.cs:2234-2248).
    public static string? Set(Deck d, int nprt, string text)
    {
        var line = Line(d);
        var error = d.Edit(line, nprt - 1, text);
        if (error != null || nprt != 4) return error;
        if (!HicEnabled(d)) d.Lines.RemoveAll(Hic.IsLine);
        else if (!d.Lines.Any(Hic.IsHead)) d.Lines.Add(new DeckLine(["1", "0.0360000", "1", "0", "0"], Labeler.LabelFor("H.12.A")));
        return null;
    }
}
