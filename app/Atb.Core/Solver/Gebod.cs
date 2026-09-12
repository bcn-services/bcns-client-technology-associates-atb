using System.Globalization;
using System.Text;

namespace Atb.Core.Solver;

/// One measured dimension: Unit is the number Gebodv.exe prints beside the unit (1-based):
/// age 1=MONTHS 2=YEARS; weight 1=LB. 2=N. 3=%-TILE; height 1=IN. 2=M. 3=%-TILE. Unit 3 makes Value a percentile.
public sealed record GebodMeasure(int Unit, double Value);

/// What ATB 3I's GEBOD.cs form collects, in exe terms.
///   Subject: 1 child, 2 adult female, 3 adult male, 4 user-supplied dimensions, 5-8 dummies (GEBOD.DAT order = ComboBox1 order).
///   Dim ("Supplied Parameter", IDIM): 0 age (child only), 1 weight, 2 standing height, 3 all of the above.
///   DimensionFile/MetricInput: subject 4 only (the 32 body dimensions, written to a UNIT 1 file).
public sealed record GebodRequest(
    string Description, int Subject, int Dim = 3,
    GebodMeasure? Age = null, GebodMeasure? Weight = null, GebodMeasure? Height = null,
    bool MetricOutput = false, bool HandSeparated = false, bool DetailedJoint = false,
    string? DimensionFile = null, bool MetricInput = false);

/// Lines typed at the unmodified Gebodv.exe console prompts (DVF, read(5,...)), in order. Order and read formats
/// taken from the exe's .text; each unit-5 read is named by its address:
///   0x40197c description (A, <=60)      0x401f75 subject number (I)
///   subject 4:    0x402148 "HAS THE ABOVE BEEN SATISFIED (Y/N)"  0x402309 file path (A42)  0x403835 input units 1 ENGLSH/2 METRIC
///   subject 1-3:  0x4027ae "PREDICTING DIMENSION(S)" (the printed number)
///                 then per dimension (age, weight, height in that order; age for the child only):
///                 0x403835 "SELECT UNITS FOR" (I)  then 0x402c3b value (F) or, for unit 3, 0x40390e percentile (F)
///   subject 2-3:  0x403478 lower arm 1 combined/2 separated   0x403602 joint 1 standard/2 detailed (always asked)
///   all:          0x403835 output units 1 ENGLSH/2 METRIC (0x40a80a/0x410c96/0x416c0e)
public static class Gebod
{
    public const int DescriptionMax = 60, PathMax = 42;

    public static string[] Answers(GebodRequest r)
    {
        if (r.Subject is < 1 or > 8) throw new ArgumentException("subject must be 1-8");
        if (r.Description.Length > DescriptionMax) throw new ArgumentException($"description longer than {DescriptionMax} chars");
        var a = new List<string> { r.Description, Int(r.Subject) };
        if (r.Subject == 4)
        {
            if (string.IsNullOrEmpty(r.DimensionFile) || r.DimensionFile.Length > PathMax)
                throw new ArgumentException($"subject 4 needs a dimension file path of 1-{PathMax} chars");
            a.AddRange(["Y", r.DimensionFile, r.MetricInput ? "2" : "1"]);
        }
        else if (r.Subject <= 3)
        {
            bool child = r.Subject == 1;
            if (r.Dim is < 0 or > 3 || (!child && r.Dim == 0)) throw new ArgumentException("dimension choice not offered for this subject");
            a.Add(Int(r.Dim));
            if (child && r.Dim is 0 or 3) Measure(a, r.Age, "age", 2);
            if (r.Dim is 1 or 3) Measure(a, r.Weight, "weight", child ? 2 : 3);
            if (r.Dim is 2 or 3) Measure(a, r.Height, "height", child ? 2 : 3);
            if (!child) { a.Add(r.HandSeparated ? "2" : "1"); a.Add(r.DetailedJoint ? "2" : "1"); }
        }
        a.Add(r.MetricOutput ? "2" : "1");
        return [.. a];
    }

    static void Measure(List<string> a, GebodMeasure? m, string name, int units)
    {
        if (m == null) throw new ArgumentException($"{name} is required");
        if (m.Unit < 1 || m.Unit > units) throw new ArgumentException($"{name} unit must be 1-{units}");
        // 0x403921: accepted only while (p-1)*(p-100) < 0; anything else re-asks and hits EOF on closed stdin.
        if (m.Unit == 3 && !(m.Value > 1 && m.Value < 100)) throw new ArgumentException($"{name} percentile must be between 1 and 100 (exclusive)");
        a.Add(Int(m.Unit));
        a.Add(Real(m.Value));
    }

    static string Int(int v) => v.ToString(CultureInfo.InvariantCulture);
    /// Always carries a decimal point, so an F-edit read with an implied d cannot rescale it.
    public static string Real(double v) => v.ToString("0.0###", CultureInfo.InvariantCulture);

    /// The UNIT 1 file for subject 4: 32 values read with format (3X,8F10.3/(8F10.3)) (0x45e1ac): three blank
    /// columns, then 8 ten-column fields per line, 4 lines. Order = BdyDim.cs TextBox0..TextBox31.
    public static string DimensionFileText(IReadOnlyList<double> dims)
    {
        if (dims.Count != 32) throw new ArgumentException("need 32 body dimensions");
        var sb = new StringBuilder();
        for (int i = 0; i < 32; i++)
        {
            if (i == 0) sb.Append("   ");
            string s = Real(dims[i]);
            if (s.Length > 10) throw new ArgumentException($"dimension {i + 1} does not fit a 10-column field: {s}");
            sb.Append(s.PadLeft(10));
            if (i % 8 == 7) sb.Append("\r\n");
        }
        return sb.ToString();
    }

    /// C:\ATBFIG.SYS as Gebodv.exe reads it at start-up (list-directed length, then A40 folder ending in '\'); the
    /// folder is where it finds GEBOD.DAT and writes GEBOD.ain / ExecATB.DAT. Same layout ATB 3I's installer wrote.
    public static string AtbFig(string dir, string tempDir)
    {
        dir = dir.TrimEnd('\\') + "\\"; tempDir = tempDir.TrimEnd('\\') + "\\";
        if (dir.Length > 40) throw new ArgumentException("GEBOD folder longer than 40 chars (Gebodv.exe reads it as A40): " + dir);
        return " " + dir.Length + " \r\n" + dir + "\r\n " + tempDir.Length + " \r\n" + tempDir + "\r\n";
    }
}
