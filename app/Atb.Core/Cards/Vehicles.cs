using Atb.Core.Lin;

namespace Atb.Core.Cards;

/// Vehicle Motion (ATB 3I Vehicle.cs, VehOpt1/2/34.cs): the deck's C.1-C.5 blocks, 3I's VehicleType rule, the
/// time-history rows each sub-editor shows, and the points its Plot button charts. All card math lives here.
public static class Vehicles
{
    /// DrpDBList SpecialList 113 (ATB3iData.mdb), indexed by VehicleType — 3I's spelling.
    public static readonly string[] TypeNames = ["Half Sine Wave", "Deceleration", "6 Degree Deleleration", "Spline - Position", "Spline - Velocity", "Spline - Acceleration"];

    /// ATB 3I Vehicle.cs:975-994, copied: nATAB = C.2.A Interpolated Points, lType = C.2.B Spline Data Type.
    public static int VehicleType(int nATAB, int lType)
    {
        if (nATAB == 0) return 0;
        if (nATAB > 0) return 1;
        return lType switch { 0 => 2, 1 => 3, 2 => 4, 3 => 5, _ => 0 };
    }

    /// The sub-editor 3I's btnEdit_Click opens (Vehicle.cs:497-545): VehOpt34 serves types 2-5, keyed by type.
    public static string Editor(int type) => type switch { 0 => "VehOpt1", 1 => "VehOpt2", _ => "VehOpt34" };

    /// Window title per type (VehOpt1/VehOpt2 designer text, VehOpt34_Load :2219-2281; "Acceleartion" is 3I's).
    public static string Title(int type) => type switch
    {
        0 => "Half Sine Wave Deceleration Impulse",
        1 => "Unidirectional Deceleration",
        2 => "Six Degree of Freedom Deceleration",
        3 => "Spline Fit Position Data",
        4 => "Spline Fit Velocity Data",
        5 => "Spline Fit Acceleartion Data",
        _ => "Prescribed Motion Definition Option 3 and 4",
    };

    /// Plot series label (VehOpt2.btnPlot "Deceleration"; VehOpt34.btnPlot :2470-2484, "Split" is 3I's).
    public static string SeriesLabel(int type) => type switch
    {
        1 => "Deceleration", 2 => "6 Degree Deceleration", 3 => "Split Fit Position", 4 => "Split Fit Velocity", _ => "Split Fit Acceleration",
    };

    /// One vehicle: C.1, C.2.A, the C.2.B line when Interpolated Points &lt; 0, and its data lines in deck order
    /// (C.3 value lines, C.4 rows, or C.5 rows — the first Spline Data Type - 1 of those are 3I's C5a initial values).
    public sealed record Block(int Id, DeckLine C1, DeckLine C2a, DeckLine? C2b, List<DeckLine> Data)
    {
        public int Type => VehicleType(C2a.Int(8), C2b?.Int(0) ?? 0);
        public string Title => C1.Count > 0 ? C1.Str(0) : "";
        /// C5a rows ahead of the C5b data rows (0 for position, 1 velocity, 2 acceleration).
        public int InitialRows => Type >= 3 ? Type - 3 : 0;
        public List<DeckLine> DataRows => Data.Skip(InitialRows).ToList();
    }

    /// The vehicle blocks, walked as the solver reads them (Labeler.cs, input_vehicle.for): until C.2.A Vehicle Segment == 0.
    public static List<Block> Blocks(Deck d)
    {
        var res = new List<Block>();
        int i = d.Lines.FindIndex(l => l.Is("C.1"));
        while (i >= 0 && i + 1 < d.Lines.Count && d.Lines[i + 1].Is("C.2.A"))
        {
            var c1 = d.Lines[i]; var c2a = d.Lines[i + 1]; i += 2;
            DeckLine? c2b = null; var data = new List<DeckLine>();
            int interp = c2a.Int(8);
            if (interp > 0)
                for (int n = 0; n < interp && i < d.Lines.Count; i++) { data.Add(d.Lines[i]); n += d.Lines[i].Count; }   // C.3, up to 12 per line
            else if (interp < 0 && i < d.Lines.Count && d.Lines[i].Is("C.2.B"))
            {
                c2b = d.Lines[i++];
                int spline = c2b.Int(0), rows = spline == 0 ? -interp : spline > 0 ? spline - 1 + c2b.Int(2) : 0;
                for (int k = 0; k < rows && i < d.Lines.Count; k++) data.Add(d.Lines[i++]);
            }
            res.Add(new Block(res.Count + 1, c1, c2a, c2b, data));
            if (c2a.Int(13) == 0) break;
        }
        return res;
    }

    // ponytail: 3I keeps Vehicle SegID as DB state set at import; this is Vehicle Segment when set, else NSEG + vehicle
    // ordinal — upgrade when a deck is found whose 3I import numbers its vehicles otherwise.
    public static int SegId(Deck d, Block b) => b.C2a.Int(13) != 0 ? b.C2a.Int(13) : d.SegmentCount + b.Id;

    /// Spline Degree items (VehOpt34_Load: items 0-3; type 3 removes 0 and 1, type 4 removes 0).
    public static int[] SplineDegrees(int type) => type is >= 3 and <= 5 ? Enumerable.Range(5 - type, type - 1).ToArray() : [];

    /// Grid column captions of the "Motion  Data" tab (3I tables C3 / C4 / C5b with their unbound Time column).
    public static string[] Columns(int type) => type switch
    {
        0 => [],
        1 => ["Time", "Deceleration"],
        _ => ["Time", "Linear - X", "Linear - Y", "Linear - Z", "Angular - X", "Angular - Y", "Angular - Z"],
    };

    /// Types 1 and 2 compute Time (ATBGrid.grdDB_UnboundColumnFetch: Start Time + row * Interval); 3-5 store it.
    public static bool TimeComputed(int type) => type is 1 or 2;

    /// The deck cell behind grid (row, col) of the Motion Data tab; col indexes Columns(type). Null for computed Time.
    public static (DeckLine Line, int Token)? Cell(Block b, int row, int col)
    {
        if (b.Type == 1)
        {
            if (col != 1) return null;
            foreach (var l in b.Data) { if (row < l.Count) return (l, row); row -= l.Count; }
            return null;
        }
        if (b.Type == 0 || (TimeComputed(b.Type) && col == 0)) return null;
        var rows = b.DataRows;
        int tok = TimeComputed(b.Type) ? col - 1 : col;
        return row < rows.Count && tok < rows[row].Count ? (rows[row], tok) : null;
    }

    public static int RowCount(Block b) => b.Type switch { 0 => 0, 1 => b.Data.Sum(l => l.Count), _ => b.DataRows.Count };

    /// Grid cell text (computed Time formatted as 3I's StringType.FromDouble would, "G").
    public static string CellText(Block b, int row, int col) =>
        Cell(b, row, col) is { } c ? c.Line.Str(c.Token)
        : TimeComputed(b.Type) && col == 0 ? Time(b, row).ToString("G", System.Globalization.CultureInfo.InvariantCulture) : "";

    static double Time(Block b, int row) => b.C2a.Num(9) + row * b.C2a.Num(10);

    /// Edit one time-history cell: Deck.Edit on that one line (null = accepted, else why refused).
    public static string? EditCell(Deck d, Block b, int row, int col, string text) =>
        Cell(b, row, col) is { } c ? d.Edit(c.Line, c.Token, text) : "Time is computed from Start Time and Interval";

    // ---- list operations (Vehicle.cs btnInsert / btnCopy / btnDelete / btnReplace, Vehicle_Closing) ----

    public const string InsertText = "You are about to insert a prescribed motion.  ATB 3I will\r\ncascade update other input cards for segment numbering.\r\nYou can't undo this operation once it proceeds.  Continue?";
    public const string InsertTitle = "Insert Prescribed Motion";
    public const string DeleteText = "You are about to delete a prescribed motion.  ATB 3I will\r\ncascade update other input cards for segment numbering.\r\nYou can't undo this operation once it proceeds. Continue?";
    public const string DeleteTitle = "Delete Prescribed Motion";
    public const string ReplaceText = "You are about to replace the selected prescribed motion with a copied prescribed motion.\r\nYou can't undo this operation once it proceeds. Continue?";
    public const string ReplaceTitle = "Replace Vehicle";
    public const string PrimaryText = "You can't delete the primary vehicle.";

    /// btnInsert (Vehicle.cs:557-631): a new vehicle titled "Inserted Motion" before vehicle n, taking its segment number;
    /// Renumber shifts every reference to that segment and later ones.
    // ponytail: 3I's other C1C2a columns take the database defaults; this writes zeros (a half sine) — upgrade when the
    // ATB3iData.mdb column defaults are read.
    public static void Insert(Deck d, int n)
    {
        var data = new EntityData();
        data.Groups.Add([new DeckLine(["\"Inserted Motion\""], Labeler.LabelFor("C.1")), new DeckLine(Enumerable.Repeat("0", 14), Labeler.LabelFor("C.2.A"))]);
        Renumber.Insert(d, Entity.Vehicle, n, data);
    }

    /// btnCopy: vehicle n's C.1-C.5 lines, for Replace.
    public static List<DeckLine> Copy(Deck d, int n) => Renumber.Copy(d, Entity.Vehicle, n).Groups[0];

    /// btnDelete (Vehicle.cs:374-479): the primary (last) vehicle is refused with 3I's text; any other goes through
    /// Renumber.Delete, which cascades and shifts every reference. Null = deleted.
    public static string? Delete(Deck d, int n)
    {
        if (n == Renumber.Count(d, Entity.Vehicle)) return PrimaryText;
        Renumber.Delete(d, Entity.Vehicle, n, _ => true);   // 3I asks once (DeleteText) before, not per reference
        return null;
    }

    /// btnReplace (Vehicle.cs:633-748): vehicle n's block becomes a copy of `copy`, keeping its own Vehicle Segment
    /// (0 for the primary). The vehicle count is unchanged, so no reference moves (3I runs no UpdateSegID here).
    public static void Replace(Deck d, int n, IReadOnlyList<DeckLine> copy)
    {
        var old = Renumber.Owned(d, Entity.Vehicle, n)[0];
        var fresh = copy.Select(l => new DeckLine(l.Tokens, l.Label)).ToList();
        var oldC2a = old.First(l => l.Is("C.2.A"));
        if (fresh.FirstOrDefault(l => l.Is("C.2.A")) is { Count: 14 } c2a && oldC2a.Count == 14) c2a.Set(13, oldC2a.Tokens[13]);
        int at = d.Lines.IndexOf(old[0]);
        d.Lines.RemoveRange(at, old.Count);
        d.Lines.InsertRange(at, fresh);
    }

    /// Vehicle_Closing (Vehicle.cs:750-796): the list's Vehicle Title is C.1 token 0.
    public static string? SetTitle(Deck d, Block b, string text) => d.Edit(b.C1, 0, text);

    // ---- sub-editor grid rows (VehOpt2 / VehOpt34 AllowAddNew / AllowDelete, their OK's count rewrite) ----

    /// Add a zero row at the end of the Motion Data grid.
    public static void AddRow(Deck d, Block b)
    {
        if (b.Type == 0) return;
        if (b.Type == 1) { SetC3(d, b, [.. b.Data.SelectMany(l => l.Tokens), "0"]); return; }
        var rows = b.DataRows;
        int width = rows.Count > 0 ? rows[^1].Count : b.Type == 2 ? 6 : 7;
        var last = b.Data.Count > 0 ? b.Data[^1] : b.C2b!;
        d.Lines.Insert(d.Lines.IndexOf(last) + 1, new DeckLine(Enumerable.Repeat("0", width), Labeler.LabelFor(b.Type == 2 ? "C.4" : "C.5")));
        SetRowCount(b, rows.Count + 1);
    }

    /// Delete grid row `row`.
    public static void DeleteRow(Deck d, Block b, int row)
    {
        if (row < 0 || row >= RowCount(b)) return;
        if (b.Type == 1) { var v = b.Data.SelectMany(l => l.Tokens).ToList(); v.RemoveAt(row); SetC3(d, b, v); return; }
        d.Lines.Remove(b.DataRows[row]);
        SetRowCount(b, b.DataRows.Count - 1);
    }

    /// C.3 values rewritten 12 a line (unlabelled, as the decks and 3I's writer have them); Interpolated Points = count.
    static void SetC3(Deck d, Block b, List<string> values)
    {
        foreach (var l in b.Data) d.Lines.Remove(l);
        d.Lines.InsertRange(d.Lines.IndexOf(b.C2a) + 1, values.Chunk(12).Select(c => new DeckLine(c, "")));
        SetRowCount(b, values.Count);
    }

    /// 3I's OK: VehOpt2.cs:1612 Interpolated Points = rows; VehOpt34.cs:2392 6-DOF Interpolated Points = -rows,
    /// :2396-2409 spline Number of Data Points (C.2.B token 2) = rows.
    static void SetRowCount(Block b, int rows)
    {
        string n = rows.ToString(System.Globalization.CultureInfo.InvariantCulture);
        if (b.Type == 1) b.C2a.Set(8, n);
        else if (b.Type == 2) b.C2a.Set(8, "-" + n);
        else b.C2b!.Set(2, n);
    }

    /// The one source of the Data Plot's points (VehOpt2.btnPlot :1659-1666, VehOpt34.btnPlot :2461-2468):
    /// X = the Time column, Y = column col, one point per row.
    public static (float[] X, float[] Y) PlotPoints(Block b, int col)
    {
        int n = RowCount(b);
        var x = new float[n]; var y = new float[n];
        for (int r = 0; r < n; r++)
        {
            x[r] = (float)(Cell(b, r, 0) is { } t ? t.Line.Num(t.Token) : Time(b, r));
            y[r] = Cell(b, r, col) is { } v ? (float)v.Line.Num(v.Token) : 0f;
        }
        return (x, y);
    }
}
