using System.Text;
using Atb.Core.Cards;
using Atb.Core.Lin;
using Xunit;

namespace Atb.Core.Tests;

/// Model > Function (§2 #17-#19): every E.* function opens and saves unedited with zero bytes changed, 3I's sign-driven
/// mode rule, the plot's points from Functions.CurvePoints / JointCurvePoints, and the list operations.
public class FunctionsTests
{
    static string Fx(string name) => Path.Combine(Fixtures.RepoRoot, "app/Atb.Core.Tests/fixtures/functions", name);
    static Deck Load(string rel) => Deck.Load(Path.Combine(Fixtures.RepoRoot, rel));
    static double[] D(params double[] v) => v;

    /// (d) FileManager.GetFunctionType as a truth table of literals: D1 = 0 constant; D1 &lt; 0 tabular F1; D2 &gt; 0 polynomial
    /// F2; D2 &lt; 0 tabular F2 only under a polynomial F1.
    [Theory]
    [InlineData(0, 5, 0, 0)] [InlineData(0, -5, 0, 0)] [InlineData(3, 0, 1, 0)] [InlineData(-3, 0, 2, 0)]
    [InlineData(3, 4, 1, 1)] [InlineData(-3, 4, 2, 1)] [InlineData(3, -4, 1, 2)] [InlineData(-3, -4, 0, 0)]
    public void SignDrivenModeRule(double d1, double d2, int f1, int f2) => Assert.Equal([f1, f2], Functions.Types(d1, d2));

    [Fact]
    public void ClientDeckFunctionsTakeTheirTypeFromE2Signs()
    {
        var fs = Functions.Fdfs(Load("cases/2479/2479_2.LIN"));
        Assert.Equal(13, fs.Count);
        Assert.Equal((3, "F4G DEFAULT", 0, 0), (fs[2].Id, fs[2].Title, fs[2].F1, fs[2].F2));
        Assert.Equal((4, 1, 0), (fs[3].Id, fs[3].F1, fs[3].F2));
        Assert.Equal((7, 2, 0), (fs[6].Id, fs[6].F1, fs[6].F2));
        Assert.Equal(["0", "5000", "0", "0", "0", "0"], fs[3].Subs[0].Values);
        Assert.Equal(["0", "0", "0.25", "25", "0.5", "100", "2", "1000", "3", "1000"], fs[6].Subs[0].Values);
    }

    /// Plot source, constant: D2 across [D0, hi].
    [Fact]
    public void CurvePointsConstant()
    {
        var (x, y) = Functions.CurvePoints(0, D(0.9), 0, 5);
        Assert.Equal(D(0, 5), x);
        Assert.Equal(D(0.9, 0.9), y);
    }

    /// (a) Plot source, polynomial: 101 points, A0 + A1 x + ... + A5 x^5 (EVALFD Horner).
    [Fact]
    public void CurvePointsPolynomial()
    {
        var (x, y) = Functions.CurvePoints(1, D(0, 5000, 0, 0, 0, 0), 0, 3);   // 2479_2 function 4 "F1K RANGE-GROUND"
        Assert.Equal(101, x.Length);
        Assert.Equal((0.0, 0.0), (x[0], y[0]));
        Assert.Equal((1.5, 7500.0), (x[50], y[50]));
        Assert.Equal((3.0, 15000.0), (x[100], y[100]));
        var (cx, cy) = Functions.CurvePoints(1, D(1, 2, 3, 0, 0, 0.5), 0, 2);   // 1 + 2x + 3x^2 + 0.5x^5
        Assert.Equal(2.0, cx[100]);
        Assert.Equal(33.0, cy[100]);
        Assert.Equal(1.0, cy[0]);
        Assert.Equal(1 + 2 * 0.5 + 3 * 0.25 + 0.5 * 0.03125, cy[25]);
        Assert.Equal(33.0, Functions.Poly(D(1, 2, 3, 0, 0, 0.5), 2));
    }

    /// (b) Plot source, tabular: pairs inside (lo, hi) plus both ends valued by evalfd_table.
    [Fact]
    public void CurvePointsTabular()
    {
        var t = D(0, 0, 0.25, 25, 0.5, 100, 2, 1000, 3, 1000);   // 2479_2 function 7 "F1K BODY-BODY"
        var (x, y) = Functions.CurvePoints(2, t, 0, 3);
        Assert.Equal(D(0, 0.25, 0.5, 2, 3), x);
        Assert.Equal(D(0, 25, 100, 1000, 1000), y);
        var (ix, iy) = Functions.CurvePoints(2, t, 0.1, 1.25);   // interior ends are interpolated
        Assert.Equal(D(0.1, 0.25, 0.5, 1.25), ix);
        Assert.Equal(D(10, 25, 100, 550), iy);
    }

    [Theory]
    [InlineData(1.25, 550)] [InlineData(0.375, 62.5)] [InlineData(-0.25, -25)] [InlineData(9, 1000)] [InlineData(2, 1000)]
    public void TableInterpolationFollowsEvalfdTable(double at, double want) =>
        Assert.Equal(want, Functions.Table(D(0, 0, 0.25, 25, 0.5, 100, 2, 1000, 3, 1000), at));

    [Fact]
    public void TableOfOnePairIsY1() => Assert.Equal(7.0, Functions.Table(D(4, 7), 100));

    [Fact]
    public void JointCurveTabular()
    {
        var (x, y) = Functions.JointCurvePoints(1, D(10, 100, 200));   // NTheta 3: grid angles 90, 180
        Assert.Equal(D(10, 90, 180), x);
        Assert.Equal(D(0, 100, 200), y);
        Assert.Equal(D(0, 0), Functions.JointCurvePoints(1, D(0, -5)).Y);   // torque clamped at 0 (FNTERP)
    }

    [Fact]
    public void JointCurvePolynomialInRadians()
    {
        var (x, y) = Functions.JointCurvePoints(-1, D(30, 2, 1));   // G = 2 t + t^2, t = theta - 30 in radians
        Assert.Equal(61, x.Length);
        Assert.Equal((30.0, 0.0), (x[0], y[0]));
        Assert.Equal(180.0, x[60]);
        double t = 150 * Math.PI / 180;
        Assert.Equal(2 * t + t * t, y[60], 12);
        Assert.Equal(12.08987970118393, y[60], 12);
        Assert.All(Functions.JointCurvePoints(-1, D(0, -1)).Y, v => Assert.Equal(0.0, v));
    }

    static IEnumerable<string> AllDecks() => Fixtures.ClientDecks().Concat(Fixtures.VendorSamples())
        .Concat(Directory.GetFiles(Path.Combine(Fixtures.RepoRoot, "app/Atb.Core.Tests/fixtures/functions"), "*.LIN"));

    /// (c) Every E.* function in cases/, corpus/, the vendor samples and the synthetic E.6 / E.7 decks opens (its data has
    /// the count its card says) and saving it unedited through each editor's OK changes zero bytes.
    [Fact]
    public void EveryFunctionOpensAndUneditedSaveChangesZeroBytes()
    {
        int fdf = 0, wind = 0, joint = 0;
        foreach (var p in AllDecks())
        {
            var d = Deck.Load(p);
            var bytes = File.ReadAllBytes(p);
            var before = d.Write();
            foreach (var f in Functions.Fdfs(d))
            {
                for (int s = 0; s < 2; s++)
                {
                    var sub = f.Subs[s];
                    if (sub.Type == 2) Assert.Equal(2 * sub.E4a!.Int(0), sub.Values.Count);
                    if (sub.Type == 0) continue;
                    Assert.Null(Functions.SaveFdfSub(d, f, s, s == 0 ? f.E2.Tokens[0] : null, f.E2.Tokens[s + 1].TrimStart('-'), sub.Values));
                }
                fdf++;
            }
            if (Functions.FdfEnd(d) is { } end && Functions.Fdfs(d) is { Count: > 0 } fs)
                Assert.Equal(d.Lines.IndexOf(fs[^1].Lines[^1]) + 1, d.Lines.IndexOf(end));
            var ws = Functions.Winds(d);
            Assert.Equal(Functions.NWindF(d), ws.Count);
            foreach (var w in ws)
            {
                if (w.C != null) Assert.Equal(w.C.Int(0), w.Rows.Count);
                if (w.C != null) Assert.Null(Functions.SaveWindRows(d, w, w.Rows.Select(r => r.SelectMany(l => l.Tokens).ToArray()).ToList()));
                wind++;
            }
            foreach (var j in Functions.Joints(d))
            {
                Assert.Equal(j.NPhi, j.Rows.Count);
                Assert.Null(Functions.SaveJointRows(d, j, j.Rows.Select(r => r.SelectMany(l => l.Tokens).ToArray()).ToList()));
                joint++;
            }
            Assert.Equal(before, d.Write());
            Assert.All(d.Lines, l => Assert.NotNull(l.Raw));
            Assert.Equal(bytes, Encoding.Latin1.GetBytes(d.Write()));
        }
        Assert.True(fdf > 1000, $"{fdf} FDFs");
        // wind: WindF.lin, ejection.lin, synthetic 2479_2_wind; joint: ejection.lin 1, human.lin 10, synthetic 2479_2_joint 2.
        // No cases/ or corpus/ client deck has an E.6 or E.7 function (NWINDF = 0, no B.4.A < 0).
        Assert.Equal((3, 13), (wind, joint));
    }

    static List<int> Diff(string a, string b)
    {
        var x = a.Split('\n'); var y = b.Split('\n');
        Assert.Equal(x.Length, y.Length);
        return Enumerable.Range(0, x.Length).Where(i => x[i] != y[i]).ToList();
    }

    [Fact]
    public void EditOneTableValueRewritesOnlyThatLine()
    {
        var d = Load("cases/2479/2479_2.LIN"); var before = d.Write();
        var f = Functions.Fdfs(d)[6];
        var v = f.Subs[0].Values; v[5] = "120";
        Assert.Null(Functions.SaveFdfSub(d, f, 0, "0", "3", v));
        Assert.Equal([d.Lines.IndexOf(f.Subs[0].Data[0])], Diff(before, d.Write()));
        Assert.Equal("0    0    0.25    25    0.5    120    ", d.Write().Split("\r\n")[d.Lines.IndexOf(f.Subs[0].Data[0])]);
        Assert.Equal("-3", f.E2.Tokens[1]);   // |D1| keeps the tabular sign
    }

    [Fact]
    public void AddingAPairRegeneratesTheTableAndItsCount()
    {
        var d = Load("cases/2479/2479_2.LIN");
        var f = Functions.Fdfs(d)[6];
        Assert.Null(Functions.SaveFdfSub(d, f, 0, "0", "4", [.. f.Subs[0].Values, "4", "1200"]));
        var g = Functions.Fdfs(d)[6];
        Assert.Equal("6", g.Subs[0].E4a!.Tokens[0]);
        Assert.Equal("-4", g.E2.Tokens[1]);
        var text = d.Write().Split("\r\n");
        int at = d.Lines.IndexOf(g.Subs[0].E4a!);
        Assert.Equal(["6    CARD E.4.a", "0    0    0.25    25    0.5    100    ", "2    1000    3    1000    4    1200    ", "8    \"F3R BODY-BODY\"    CARD E.1"], text[at..(at + 4)]);
        Assert.NotNull(Functions.SaveFdfSub(d, g, 0, "0", "4", ["1", "x"]));
    }

    [Fact]
    public void F1TypeChangeResetsD1AndData()
    {
        var d = Load("cases/2479/2479_2.LIN");
        var f = Functions.Fdfs(d)[3];   // polynomial, D1 = 3
        Assert.True(Functions.SetF1Type(d, f, 2));
        var g = Functions.Fdfs(d)[3];
        Assert.Equal((2, 0, "-3"), (g.F1, g.F2, g.E2.Tokens[1]));
        Assert.Equal("0", g.Subs[0].E4a!.Tokens[0]);
        Assert.True(Functions.SetF1Type(d, g, 0));
        g = Functions.Fdfs(d)[3];
        Assert.Equal(["0", "0", "0", "0", "0"], g.E2.Tokens);
        Assert.Empty(g.Subs[0].Lines);
        Assert.True(Functions.SetF1Type(d, g, 1));   // leaving constant: D1 = 1
        g = Functions.Fdfs(d)[3];
        Assert.Equal((1, "1"), (g.F1, g.E2.Tokens[1]));
        Assert.True(Functions.SetF2Type(d, g, 2));   // D2 = -(|D1| + 1)
        g = Functions.Fdfs(d)[3];
        Assert.Equal((1, 2, "-2"), (g.F1, g.F2, g.E2.Tokens[2]));
        Assert.False(Functions.SetF1Type(d, g, 2));   // F2 is tabular already
        Assert.Equal(13, Functions.Fdfs(d).Count);
    }

    [Fact]
    public void InsertCopyPasteDeleteFdf()
    {
        var d = Load("cases/2479/2479_2.LIN");
        var fs = Functions.Fdfs(d);
        Assert.Equal("0\t7\tF1K BODY-BODY\t0\t-3\t0\t0\t0\t2\t0\r\n", Functions.CopyText(d, Functions.Kind.Fdf, [fs[6].E1]));
        Functions.Insert(d, Functions.Kind.Fdf, fs[0].E1);
        Assert.Equal("-1    \"\"    CARD E.1", d.Write().Split("\r\n")[d.Lines.IndexOf(fs[0].E1) - 2]);
        Assert.Equal(1, Functions.Paste(d, Functions.Kind.Fdf, Functions.CopyText(d, Functions.Kind.Fdf, [fs[6].E1]), fs[6].E1, before: false));
        var gs = Functions.Fdfs(d);
        Assert.Equal(15, gs.Count);
        Assert.Equal((-1, -2), (gs[0].Id, gs[8].Id));
        Assert.Equal(gs[7].Subs[0].Values, gs[8].Subs[0].Values);
        Assert.Equal(-1, Functions.Paste(d, Functions.Kind.Fdf, "", null, false));
        Functions.Delete(d, Functions.Kind.Fdf, [gs[0].E1, gs[8].E1]);
        Assert.Equal(Load("cases/2479/2479_2.LIN").Write(), d.Write());
    }

    [Fact]
    public void WindInsertDeleteKeepsNWindFAndF7InStep()
    {
        var d = Deck.Load(Fx("2479_2_wind.LIN"));
        var w = Functions.Winds(d).Single();
        Assert.Equal((1, "WIND GUST", 3), (w.Id, w.Title, w.Rows.Count));
        Functions.Insert(d, Functions.Kind.Wind, w.A);
        Assert.Equal(2, Functions.NWindF(d));
        Assert.Equal([-1, 1], Functions.Winds(d).Select(x => x.Id));
        Functions.Delete(d, Functions.Kind.Wind, Functions.Heads(d, Functions.Kind.Wind));
        Assert.Equal(0, Functions.NWindF(d));
        Assert.DoesNotContain(d.Lines, l => l.Is("F.7.A") || l.Is("E.6.A"));
        Labeler.Label(Deck.Parse(d.Write()));   // still walks the grammar
    }

    [Fact]
    public void WindRowsAddARow()
    {
        var d = Deck.Load(Fx("2479_2_wind.LIN"));
        var w = Functions.Winds(d).Single();
        Assert.Null(Functions.SaveWindRows(d, w, [["0", "0", "0", "0"], ["0.1", "10", "0", "-5"], ["0.2", "10", "0", "0"], ["0.3", "0", "0", "0"]]));
        var x = Functions.Winds(d).Single();
        Assert.Equal(("4", 4), (x.C!.Tokens[0], x.Rows.Count));
        Assert.Equal("0.3    0    0    0    ", d.Write().Split("\r\n")[d.Lines.IndexOf(x.Rows[3][0])]);
        Functions.SetSpecificHeats(d, x, "1.4");
        Assert.Null(Functions.Winds(d).Single().C);
        Labeler.Label(Deck.Parse(d.Write()));
    }

    [Fact]
    public void JointShapeChangeResetsToZeros()
    {
        var d = Deck.Load(Fx("2479_2_joint.LIN"));
        var js = Functions.Joints(d);
        Assert.Equal([(1, 3, 2, 1), (2, 3, 1, -1)], js.Select(j => (j.Id, j.NTheta, j.NPhi, j.Type)));
        Assert.Equal(["Theta 0", "90", "180"], Functions.JointColumns(js[0]));
        Assert.Equal(["Theta 0", "C1", "C2"], Functions.JointColumns(js[1]));
        Assert.Equal((-180.0, 0.0), (Functions.Phi(js[0], 0), Functions.Phi(js[0], 1)));
        Assert.Equal("NTheta can't be less than 2!", Functions.SetJointShape(d, js[0], 1, 2, 1));
        Assert.Equal("NPhi can't be less than 1!", Functions.SetJointShape(d, js[0], 2, 0, 1));
        Assert.Null(Functions.SetJointShape(d, js[1], 4, 2, -1));
        var j = Functions.Joints(d)[1];
        Assert.Equal(("-4", 2), (j.C.Tokens[0], j.Rows.Count));
        Assert.All(j.Rows.SelectMany(r => r).SelectMany(l => l.Tokens), t => Assert.Equal("0", t));
        Functions.Insert(d, Functions.Kind.Joint, j.A);
        Assert.Equal([1, -1, 2], Functions.Joints(d).Select(x => x.Id));
        Labeler.Label(Deck.Parse(d.Write()));
    }

    [Fact]
    public void FunctionIdMustBeUnusedAmongE1()
    {
        var d = Load("cases/2479/2479_2.LIN");
        var f = Functions.Fdfs(d)[0];
        Assert.Equal("This ID has been used by other functions!", Functions.SetId(d, f.E1, "2"));
        Assert.Equal("Input string was not in correct format!", Functions.SetId(d, f.E1, "x"));
        Assert.Null(Functions.SetId(d, f.E1, "40"));
        Assert.Equal("40", f.E1.Tokens[0]);
    }
}
