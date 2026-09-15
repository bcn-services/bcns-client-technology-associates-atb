using Atb.Core.Cards;
using Atb.Core.Lin;
using Xunit;

namespace Atb.Core.Tests;

/// S2 parity fixes: first function on an empty list, vehicle list operations through Renumber, grid row count rewrites,
/// the FDF plot's second series, and the non-numeric message — all asserted as written-out literals.
public class S2ParityTests
{
    static Deck Load(string rel) => Deck.Load(Path.Combine(Fixtures.RepoRoot, rel));
    static string[] L(Deck d) => d.Write().Split('\n').Select(l => l.TrimEnd('\r')).ToArray();
    static string[] Added(string[] a, string[] b) => b.Except(a).ToArray();
    static string[] Removed(string[] a, string[] b) => a.Except(b).ToArray();
    static void Valid(Deck d) => Assert.Empty(Deck.Parse(d.Write()).Validate());

    [Fact]
    public void FirstWindAndJointFunctionCreateTheirSectionsAndTerminator()
    {
        var d = Load("cases/2479/2479_2.LIN");
        Assert.Empty(Functions.Winds(d)); Assert.Empty(Functions.Joints(d));
        var a = L(d);
        Functions.Insert(d, Functions.Kind.Wind, null);
        Functions.Insert(d, Functions.Kind.Joint, null);
        var b = L(d);
        Assert.Equal(new[]
        {
            "9    0    0    9    0    0    0    1    0    0    0    0    CARD D.1.a",
            "-1    \"\"    CARD E.6.a",
            "0    0    0    0    0    CARD E.6.b",
            "0    CARD E.6.c",
            "-1    \"\"    CARD E.7.a",
            "0    0    0    0    0    CARD E.7.b",
            "2    1    CARD E.7.c",
            "0    0    ",
            "999    \"\"    CARD E.7.a",
        }, Added(a, b).Where(l => !l.Contains("F.7.a")).ToArray());
        Assert.Equal(["9    0    0    9    0    0    0    0    0    0    0    0    CARD D.1.a"], Removed(a, b));
        // the terminator follows the joint's lines directly
        var t = Array.IndexOf(b, "999    \"\"    CARD E.7.a");
        Assert.Equal(["-1    \"\"    CARD E.7.a", "0    0    0    0    0    CARD E.7.b", "2    1    CARD E.7.c", "0    0    "], b[(t - 4)..t]);
        var r = Deck.Parse(d.Write());
        Assert.Empty(r.Validate());
        Assert.Single(Functions.Winds(r)); Assert.Single(Functions.Joints(r));
        Assert.Equal((-1, 2, 1, 1), (Functions.Joints(r)[0].Id, Functions.Joints(r)[0].NTheta, Functions.Joints(r)[0].NPhi, Functions.Joints(r)[0].Type));
    }

    [Fact]
    public void VehicleInsertGoesThroughRenumber()
    {
        var d = Load("corpus/2645/2645_ATB.LIN"); var a = L(d);
        Vehicles.Insert(d, 1);
        var b = L(d);
        Assert.Equal("\"Inserted Motion\"    CARD C.1", b[Array.IndexOf(b, "\"DOOR\"    CARD C.1") - 2]);
        Assert.Contains("0    0    0    0    0    0    0    0    0    0    0    0    0    16    CARD C.2.a", b);
        Assert.Contains("0    0    0    0    0    0    0    0    -501    0    0.01    0    0    17    CARD C.2.a", b);
        Assert.Contains("0    0    -38.05    0    0    0    18    18    CARD G.2", b);
        Assert.Contains("0    0    -38.05    0    0    0    17    17    CARD G.2", Removed(a, b));
        Assert.Contains("2    19    17    0    0    0    0    Card H.3.a", b);
        Assert.Equal(3, Vehicles.Blocks(d).Count);
        Assert.Equal(a.Length + 2, b.Length);
        Valid(d);
    }

    [Fact]
    public void VehicleDeleteRefusesThePrimaryAndRenumbersOtherwise()
    {
        var d = Load("corpus/2645/2645_ATB.LIN"); var w = d.Write();
        Assert.Equal("You can't delete the primary vehicle.", Vehicles.Delete(d, 2));
        Assert.Equal(w, d.Write());
        var a = L(d);
        Assert.Null(Vehicles.Delete(d, 1));
        var b = L(d);
        Assert.DoesNotContain("\"DOOR\"    CARD C.1", b);
        Assert.Contains("0    0    -38.05    0    0    0    16    16    CARD G.2", b);
        Assert.Contains("1    0    3    0    0    0    0    Card H.3.a", b);
        Assert.Equal(a.Length - 10, b.Length);
        Assert.Single(Vehicles.Blocks(d));
        Valid(d);
    }

    [Fact]
    public void VehicleCopyReplaceKeepsTheSegmentNumber()
    {
        var d = Load("corpus/2645/2645_ATB.LIN"); var a = L(d);
        Vehicles.Replace(d, 1, Vehicles.Copy(d, 2));
        var b = L(d);
        Assert.Equal(["0    0    0    0    0    0    0    0    -501    0    0.012    0    0    16    CARD C.2.a"], Added(a, b));
        Assert.DoesNotContain("\"DOOR\"    CARD C.1", b);
        Assert.Equal(2, Vehicles.Blocks(d).Count);
        Valid(d);
    }

    [Fact]
    public void SplineRowAddAndDeleteRewriteC2bToken2()
    {
        var d = Load("cases/2479/2479_2.LIN"); var a = L(d);
        Vehicles.AddRow(d, Vehicles.Blocks(d).First(x => x.Type == 5));
        var b = L(d);
        Assert.Equal(["3    1    4    0    0    0    CARD C.2.b"], Added(a, b));
        Assert.Equal(["3    1    3    0    0    0    CARD C.2.b"], Removed(a, b));
        Assert.Equal(a.Length + 1, b.Length);
        Valid(d);
        Vehicles.DeleteRow(d, Vehicles.Blocks(d).First(x => x.Type == 5), 0);
        Assert.Contains("3    1    3    0    0    0    CARD C.2.b", L(d));
        Assert.Equal(a.Length, L(d).Length);
        Valid(d);
    }

    [Fact]
    public void SixDofRowAddAndDeleteRewriteC2aToken8Negative()
    {
        var d = Load("app/Atb.Core.Tests/fixtures/vehicles/2479_2_sixdof.LIN"); var a = L(d);
        Vehicles.AddRow(d, Vehicles.Blocks(d).First(x => x.Type == 2));
        var b = L(d);
        Assert.Equal(["0    0    0    0    0    0    0    0    -4    0    0.01    0    0    0    CARD C.2.a"], Added(a, b));
        Vehicles.DeleteRow(d, Vehicles.Blocks(d).First(x => x.Type == 2), 0);
        Assert.Contains("0    0    0    0    0    0    0    0    -3    0    0.01    0    0    0    CARD C.2.a", L(d));
        Valid(d);
    }

    [Fact]
    public void DecelerationRowAddAndDeleteRewriteC2aToken8()
    {
        var d = Load("corpus/2210/2210_1.LIN"); var a = L(d);
        Vehicles.AddRow(d, Vehicles.Blocks(d).First(x => x.Type == 1));
        var b = L(d);
        Assert.Equal(["0    0    0    0    0    200    -200    -23.77    44    0    0.25    2    0    0    CARD C.2.a",
                      "0    0    0    0    0    0    0    0    "], Added(a, b));
        Assert.Equal(44, Vehicles.RowCount(Vehicles.Blocks(d).First(x => x.Type == 1)));
        Valid(d);
        Vehicles.DeleteRow(d, Vehicles.Blocks(d).First(x => x.Type == 1), 0);
        Assert.Contains("0    0    0    0    0    200    -200    -23.77    43    0    0.25    2    0    0    CARD C.2.a", L(d));
        Valid(d);
    }

    [Fact]
    public void TitleEditRewritesOnlyC1()
    {
        var d = Load("corpus/2645/2645_ATB.LIN"); var a = L(d);
        Assert.Null(Vehicles.SetTitle(d, Vehicles.Blocks(d)[0], "DOOR"));
        Assert.Equal(string.Join("\n", a), string.Join("\n", L(d)));
        Vehicles.SetTitle(d, Vehicles.Blocks(d)[0], "HATCH");
        Assert.Equal(["\"HATCH\"    CARD C.1"], Added(a, L(d)));
        Assert.Equal(["\"DOOR\"    CARD C.1"], Removed(a, L(d)));
    }

    [Fact]
    public void FdfOtherSeriesComesFromCurvePointsAndIsAbsentWithoutData()
    {
        var f = Functions.Fdfs(Load("cases/2479/2479_2.LIN"))[6];   // F1 tabular, F2 none
        Assert.Null(Functions.OtherCurve(f, 0));
        var o = Functions.OtherCurve(f, 1);
        Assert.NotNull(o);
        var (x, y) = o.Value;
        Assert.Equal(new double[] { 0, 0.25, 0.5, 2, 3 }, x);
        Assert.Equal(new double[] { 0, 25, 100, 1000, 1000 }, y);
    }

    [Fact]
    public void NonNumericMessageAndTitleAreCoreConstants()
    {
        Assert.Equal("Input string was not in correct format!", Functions.FormatError);
        Assert.Equal("ATB 3I", Functions.FormatErrorTitle);
        var d = Load("cases/2479/2479_2.LIN");
        Assert.Equal("Input string was not in correct format!", Functions.SetId(d, Functions.Fdfs(d)[0].E1, "abc"));
    }
}
