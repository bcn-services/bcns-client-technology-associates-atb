using System.Globalization;
using System.Numerics;
using System.Text;
using Atb.Core.Lin;

namespace Atb.Core.Sa1;

/// One body segment's display ellipsoid (object type 1).
public sealed record SegmentEllipsoid(string Name, Vector3 SemiAxes, Vector3 Offset);

/// Contact plane (object type 2): 3 corners from the file, 4th = P1 + P2 - P0.
public sealed record Plane(string Name, int RefSegment, Vector3 P0, Vector3 P1, Vector3 P2)
{
    public Vector3 P3 => P1 + P2 - P0;
}

/// Additional (contact) ellipsoid (object type 5). Replaces segment Id1's ellipsoid when Id1 <= NGnd.
public sealed record ContactEllipsoid(string Name, int Id0, int Id1, Vector3 SemiAxes, Vector3 Offset, Vector3 Ypr, Vector3 Power);

/// Harness belt static tables (object type 6).
public sealed record Harness(int Systems, int Belts, int Points, int[] PointsPerBelt, int[] Ibar);

public sealed class Frame
{
    public double Time { get; init; }
    /// NGnd × 12: x y z then the 3×3 DCM as printed (9 values).
    public double[] Data { get; init; } = Array.Empty<double>();
    public double[]? Bar { get; init; }     // Points × 9
    public int[]? Nl { get; init; }         // Points × 2
    public int[]? NPtPly { get; init; }     // Belts

    public Vector3 Position(int i) => new((float)Data[i * 12], (float)Data[i * 12 + 1], (float)Data[i * 12 + 2]);

    /// Same packing ATB 3I fed to Inventor's SoTransform: M[a,b] = dcm[3b+a], translation in row 4 (row-vector convention, as System.Numerics).
    public Matrix4x4 Transform(int i)
    {
        int o = i * 12 + 3;
        float D(int a, int b) => (float)Data[o + 3 * b + a];
        return new Matrix4x4(
            D(0, 0), D(0, 1), D(0, 2), 0,
            D(1, 0), D(1, 1), D(1, 2), 0,
            D(2, 0), D(2, 1), D(2, 2), 0,
            (float)Data[i * 12], (float)Data[i * 12 + 1], (float)Data[i * 12 + 2], 1);
    }
}

/// ATB solver .sa1 animation file. Layout verified against ATB 3I's FileManager.ReadPostPRFile.
public sealed class Sa1File
{
    public string Banner { get; private set; } = "";
    public List<string> Titles { get; } = new();
    public List<SegmentEllipsoid> Segments { get; } = new();
    public List<Plane> Planes { get; } = new();
    public List<ContactEllipsoid> ContactEllipsoids { get; } = new();
    public Harness? Harness { get; private set; }
    /// Entries per frame (segments + vehicles); from the Dynamic Data Header.
    public int NGnd { get; private set; }
    public List<Frame> Frames { get; } = new();
    /// True when the file ended mid-frame (solver aborted); Frames holds the complete ones.
    public bool Truncated { get; private set; }

    public static Sa1File Load(string path) => Parse(File.ReadAllText(path, Encoding.Latin1));

    /// World (solver-axis) points of each belt strand at frame `i`, in draw order. As ATB 3I FileManager
    /// (DynBCord) + Animation.ShowBelt: point k = its segment IBAR[0,k]'s transform applied to BAR[3..5]+BAR[6..8];
    /// strand b takes the next NPtPLY[b] entries of NL[0,*]. Empty when the file has no harness.
    public Vector3[][] BeltStrands(int i)
    {
        var f = Frames[i];
        if (Harness is not { } h || f.Bar == null || f.Nl == null || f.NPtPly == null) return Array.Empty<Vector3[]>();
        var strands = new Vector3[h.Belts][];
        int np = 0;
        for (int b = 0; b < h.Belts; b++)
        {
            var pts = new List<Vector3>();
            for (int j = 0; j < f.NPtPly[b] && np < f.Nl.Length / 2; j++, np++)
            {
                int k = f.Nl[2 * np] - 1;
                if (k < 0 || k >= h.Points) continue;
                var local = new Vector3((float)(f.Bar[9 * k + 3] + f.Bar[9 * k + 6]), (float)(f.Bar[9 * k + 4] + f.Bar[9 * k + 7]), (float)(f.Bar[9 * k + 5] + f.Bar[9 * k + 8]));
                int seg = h.Ibar[2 * k] - 1;
                pts.Add(seg >= 0 && seg < NGnd ? Vector3.Transform(local, f.Transform(seg)) : local);
            }
            strands[b] = pts.ToArray();
        }
        return strands;
    }

    public static Sa1File Parse(string text)
    {
        var f = new Sa1File();
        var lines = text.Split('\n');
        int n = 0;
        string Next() => n < lines.Length ? lines[n++].TrimEnd('\r') : throw new FormatException("unexpected end of .sa1 object section");
        void Skip(int k) { n += k; }

        f.Banner = Next().Trim();
        Next();                                    // format tag ("5")
        for (int i = 0; i < 5; i++) f.Titles.Add(Next().TrimEnd());

        // Object blocks: [32-char name][type][count]
        while (true)
        {
            var line = Next();
            if (line.StartsWith("End Objects")) break;
            var (name, rest) = Fixed(line, 32);
            if (rest.Length < 2) throw new FormatException($".sa1 object header not understood: '{line}'");
            int type = int.Parse(rest[0], CultureInfo.InvariantCulture), count = int.Parse(rest[1], CultureInfo.InvariantCulture);
            switch (type)
            {
                case 1:
                    for (int i = 0; i < count; i++)
                    {
                        var (seg, _) = Fixed(Next(), 8);
                        var v = Nums(Next(), Next());
                        Skip(6);
                        f.Segments.Add(new(seg, V(v, 0), V(v, 3)));
                    }
                    Skip(1);                        // End Segment Ellipsoids
                    break;
                case 2:
                    for (int i = 0; i < count; i++)
                    {
                        var (pn, r) = Fixed(Next(), 20);
                        var v = Nums(Next(), Next(), Next());
                        f.Planes.Add(new(pn, int.Parse(r[1], CultureInfo.InvariantCulture), V(v, 0), V(v, 3), V(v, 6)));
                    }
                    // End Planes + "PL Array" block (17 values/plane at 6/line, derivable) + End PL Array
                    Skip(17 * count / 6 + (17 * count % 6 != 0 ? 4 : 3));
                    break;
                case 5:
                    for (int i = 0; i < count; i++)
                    {
                        var (en, r) = Fixed(Next(), 13);
                        Skip(4);
                        var v = Nums(Next(), Next(), Next(), Next());
                        f.ContactEllipsoids.Add(new(en, int.Parse(r[0], CultureInfo.InvariantCulture), int.Parse(r[1], CultureInfo.InvariantCulture), V(v, 0), V(v, 3), V(v, 6), V(v, 9)));
                    }
                    Skip(1);
                    break;
                case 6:
                {
                    var hdr = Ints(Next());
                    int belts = hdr[0], pts = hdr[1];
                    int total = count + belts + pts * 2;
                    var tbl = new List<int>();
                    while (tbl.Count < total) tbl.AddRange(Ints(Next()));
                    var ppb = tbl.GetRange(count, belts).ToArray();
                    var ibar = tbl.GetRange(count + belts, pts * 2).ToArray();
                    for (int k = 0; k < pts; k++) if (ibar[2 * k] > 100) ibar[2 * k] %= 100;
                    f.Harness = new(count, belts, pts, ppb, ibar);
                    Skip(1);
                    break;
                }
                case 101:
                    Next();
                    f.NGnd = Ints(Next())[1];
                    if (f.Harness != null) Next();
                    Skip(1);                        // End Dynamic Data Header
                    break;
                default:
                    throw new FormatException($".sa1 object type {type} ('{name}') is not supported");
            }
        }
        if (f.NGnd == 0) throw new FormatException(".sa1 has no Dynamic Data Header");

        // Frames: pure token stream to EOF. time, NGnd*12 doubles, then belt tables if any.
        var toks = string.Join('\n', lines, n, lines.Length - n).Split((char[]?)null, StringSplitOptions.RemoveEmptyEntries);
        int p = 0, per = f.NGnd * 12;
        int beltToks = f.Harness is { } h ? h.Points * 9 + h.Points * 2 + h.Belts : 0;
        while (p < toks.Length)
        {
            if (p + 1 + per + beltToks > toks.Length) { f.Truncated = true; break; }
            var fr = new double[per];
            var time = DeckLine.ParseNum(toks[p++]);
            for (int i = 0; i < per; i++) fr[i] = DeckLine.ParseNum(toks[p++]);
            double[]? bar = null; int[]? nl = null, nptply = null;
            if (f.Harness is { } hb)
            {
                bar = new double[hb.Points * 9];
                for (int i = 0; i < bar.Length; i++) bar[i] = DeckLine.ParseNum(toks[p++]);
                nl = new int[hb.Points * 2];
                for (int i = 0; i < nl.Length; i++) nl[i] = (int)DeckLine.ParseNum(toks[p++]);
                nptply = new int[hb.Belts];
                for (int i = 0; i < nptply.Length; i++) nptply[i] = (int)DeckLine.ParseNum(toks[p++]);
            }
            f.Frames.Add(new Frame { Time = time, Data = fr, Bar = bar, Nl = nl, NPtPly = nptply });
        }
        return f;
    }

    static (string name, string[] rest) Fixed(string line, int width)
    {
        var w = Math.Min(width, line.Length);
        return (line[..w].Trim(), line[w..].Split((char[]?)null, StringSplitOptions.RemoveEmptyEntries));
    }
    static double[] Nums(params string[] lines) =>
        lines.SelectMany(l => l.Split((char[]?)null, StringSplitOptions.RemoveEmptyEntries)).Select(DeckLine.ParseNum).ToArray();
    static int[] Ints(string line) => Nums(line).Select(x => (int)x).ToArray();
    static Vector3 V(double[] a, int i) => new((float)a[i], (float)a[i + 1], (float)a[i + 2]);
}
