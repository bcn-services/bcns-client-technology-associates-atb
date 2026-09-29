using Atb.Core.Cards;
using Atb.Core.Lin;
using Xunit;

namespace Atb.Core.Tests;

/// Vehicle Motion (§2 #10): 3I's VehicleType rule over every client deck, one-line edits of C.3 / C.4 / C.5 rows,
/// and the Data Plot's points from Vehicles.PlotPoints.
public class VehiclesTests
{
    static string Fx(string name) => Path.Combine(Fixtures.RepoRoot, "app/Atb.Core.Tests/fixtures/vehicles", name);
    static Deck Load(string rel) => Deck.Load(Path.Combine(Fixtures.RepoRoot, rel));

    /// 3I Vehicle.cs:975-994 as a truth table of written-out literals.
    [Theory]
    [InlineData(0, 0, 0)] [InlineData(0, 3, 0)] [InlineData(43, 0, 1)] [InlineData(1, 9, 1)]
    [InlineData(-3, 0, 2)] [InlineData(-501, 1, 3)] [InlineData(-501, 2, 4)] [InlineData(-501, 3, 5)]
    [InlineData(-5, 4, 0)] [InlineData(-5, -1, 0)]
    public void VehicleTypeRule(int nATAB, int lType, int want) => Assert.Equal(want, Vehicles.VehicleType(nATAB, lType));

    [Theory]
    [InlineData(0, "VehOpt1")] [InlineData(1, "VehOpt2")] [InlineData(2, "VehOpt34")] [InlineData(3, "VehOpt34")] [InlineData(4, "VehOpt34")] [InlineData(5, "VehOpt34")]
    public void EditorPerType(int type, string form) => Assert.Equal(form, Vehicles.Editor(type));

    [Fact]
    public void SplineDegreeItemsPerType()
    {
        Assert.Equal([2, 3], Vehicles.SplineDegrees(3));
        Assert.Equal([1, 2, 3], Vehicles.SplineDegrees(4));
        Assert.Equal([0, 1, 2, 3], Vehicles.SplineDegrees(5));
        Assert.Empty(Vehicles.SplineDegrees(2));
        // every client deck's C.2.B degree is one of its type's items (else the combo shows blank)
        foreach (var p in Fixtures.ClientDecks())
            foreach (var b in Vehicles.Blocks(Deck.Load(p)).Where(v => v.Type >= 3))
                Assert.Contains(b.C2b!.Int(1), Vehicles.SplineDegrees(b.Type));
    }

    /// Every client deck: each vehicle's type is the rule applied to its own C.2.A token 8 and C.2.B token 0, the walk
    /// ends at the primary vehicle (Vehicle Segment 0), and the block's data lines are the next lines, just before D.1.A.
    [Fact]
    public void EveryClientDeckVehicleOpensItsRuleEditor()
    {
        var seen = new SortedDictionary<int, int>();
        foreach (var p in Fixtures.ClientDecks())
        {
            var d = Deck.Load(p);
            var bs = Vehicles.Blocks(d);
            Assert.True(bs.Count > 0, p);
            foreach (var b in bs)
            {
                int n = b.C2a.Int(8), l = b.C2b?.Int(0) ?? 0;
                int want = n == 0 ? 0 : n > 0 ? 1 : l == 0 ? 2 : l == 1 ? 3 : l == 2 ? 4 : l == 3 ? 5 : 0;
                Assert.Equal(want, b.Type);
                Assert.Equal(want == 0 ? "VehOpt1" : want == 1 ? "VehOpt2" : "VehOpt34", Vehicles.Editor(b.Type));
                seen[b.Type] = seen.GetValueOrDefault(b.Type) + 1;
            }
            Assert.Equal(0, bs[^1].C2a.Int(13));
            var last = bs[^1].Data.Count > 0 ? bs[^1].Data[^1] : bs[^1].C2b ?? bs[^1].C2a;
            Assert.True(d.Lines[d.Lines.IndexOf(last) + 1].Is("D.1.A"), p + ": vehicle walk does not end before D.1.A");
        }
        // The analyzer's census, as literals: 4 unidirectional (corpus/2210), 9 spline-velocity, 147 spline-acceleration.
        Assert.Equal(new Dictionary<int, int> { [1] = 4, [4] = 9, [5] = 147 }, seen);
    }

    [Fact]
    public void ClientBlocksMatchKnownDecks()
    {
        var t5 = Vehicles.Blocks(Load("cases/2479/2479_2.LIN"));
        Assert.Equal(["TARGET VEHICLE"], t5.Select(b => b.Title));
        Assert.Equal((5, 2, 3), (t5[0].Type, t5[0].InitialRows, Vehicles.RowCount(t5[0])));
        var t1 = Vehicles.Blocks(Load("corpus/2210/2210_1.LIN")).Single();
        Assert.Equal((1, 43), (t1.Type, Vehicles.RowCount(t1)));
        var t4 = Vehicles.Blocks(Load("corpus/2107/2107_A2.LIN"));
        Assert.Contains(t4, b => b.Type == 4 && b.InitialRows == 1);
    }

    [Fact]
    public void SyntheticFixturesCoverTheTypesNoClientDeckHas()
    {
        Assert.Equal(0, Vehicles.Blocks(Deck.Load(Fx("2479_2_halfsine.LIN"))).Single().Type);
        Assert.Equal(2, Vehicles.Blocks(Deck.Load(Fx("2479_2_sixdof.LIN"))).Single().Type);
        Assert.Equal(3, Vehicles.Blocks(Deck.Load(Fx("2479_2_splinepos.LIN"))).Single().Type);
    }

    /// Changed line indexes between two writes of the same deck.
    static List<int> Diff(string a, string b)
    {
        var x = a.Split('\n'); var y = b.Split('\n');
        Assert.Equal(x.Length, y.Length);
        return Enumerable.Range(0, x.Length).Where(i => x[i] != y[i]).ToList();
    }

    /// Editing one time-history cell rewrites that C.3 / C.4 / C.5 line and no other.
    [Theory]
    [InlineData("corpus/2210/2210_1.LIN", 20, 1, "C.3")]
    [InlineData("app/Atb.Core.Tests/fixtures/vehicles/2479_2_sixdof.LIN", 1, 3, "C.4")]
    [InlineData("cases/2479/2479_2.LIN", 1, 2, "C.5")]
    [InlineData("corpus/2107/2107_A2.LIN", 0, 1, "C.5")]
    [InlineData("app/Atb.Core.Tests/fixtures/vehicles/2479_2_splinepos.LIN", 2, 1, "C.5")]
    public void EditRowRewritesOnlyThatLine(string rel, int row, int col, string card)
    {
        var d = Load(rel); var before = d.Write();
        var b = Vehicles.Blocks(d).First(v => v.Type != 0);
        var (line, tok) = Vehicles.Cell(b, row, col)!.Value;
        Assert.Null(Vehicles.EditCell(d, b, row, col, "7.25"));
        Assert.Equal("7.25", line.Str(tok));
        var changed = Diff(before, d.Write());
        Assert.Equal([d.Lines.IndexOf(line)], changed);
        Assert.True(line.Is(card) || (card == "C.3" && line.Label == ""), $"edited line is {line.Label}");
        Assert.NotNull(Vehicles.EditCell(d, b, row, col, "abc"));   // refused, nothing written
        Assert.Equal(changed, Diff(before, d.Write()));
    }

    [Fact]
    public void ComputedTimeIsNotEditable()
    {
        var d = Deck.Load(Fx("2479_2_sixdof.LIN")); var before = d.Write();
        var b = Vehicles.Blocks(d).Single();
        Assert.NotNull(Vehicles.EditCell(d, b, 0, 0, "5"));
        Assert.Equal(before, d.Write());
    }

    [Fact]
    public void PlotPointsSplinePosition()
    {
        var b = Vehicles.Blocks(Deck.Load(Fx("2479_2_splinepos.LIN"))).Single();
        var (x, y) = Vehicles.PlotPoints(b, 1);
        Assert.Equal([0f, 0.1f, 0.2f, 0.3f], x);
        Assert.Equal([0f, 1f, 3f, 6f], y);
    }

    [Fact]
    public void PlotPointsSixDofUseStartTimePlusRowTimesInterval()
    {
        var b = Vehicles.Blocks(Deck.Load(Fx("2479_2_sixdof.LIN"))).Single();
        var (x, y) = Vehicles.PlotPoints(b, 1);   // Linear - X
        Assert.Equal([0f, 0.01f, 0.02f], x);
        Assert.Equal([0f, 1f, 2f], y);
    }

    [Fact]
    public void PlotPointsFollowAnEditedRow()
    {
        var d = Load("corpus/2210/2210_1.LIN");
        var b = Vehicles.Blocks(d).Single();
        Assert.Null(Vehicles.EditCell(d, b, 3, 1, "-12.5"));
        var (x, y) = Vehicles.PlotPoints(b, 1);
        Assert.Equal(43, x.Length);
        Assert.Equal(-12.5f, y[3]);
        Assert.Equal((float)(b.C2a.Num(9) + 3 * b.C2a.Num(10)), x[3]);
    }
}
