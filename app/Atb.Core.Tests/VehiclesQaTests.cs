using Atb.Core.Cards;
using Atb.Core.Lin;
using Xunit;

namespace Atb.Core.Tests;

/// QA: a time-history edit changes exactly one line against the ORIGINAL FILE BYTES (not a re-write of the same deck),
/// for every vehicle of every multi-vehicle client deck, and spot types per deck as written-out literals.
public class VehiclesQaTests
{
    static string[] FileLines(string p) => File.ReadAllText(p).Replace("\r\n", "\n").TrimEnd('\n').Split('\n');
    static string[] OutLines(Deck d) => d.Write().Replace("\r\n", "\n").TrimEnd('\n').Split('\n');

    static void EditOneAgainstFile(string path, int vehicle, int row, int col)
    {
        var orig = FileLines(path);
        var d = Deck.Load(path);
        Assert.Equal(orig, OutLines(d));   // untouched deck writes back byte-identical
        var b = Vehicles.Blocks(d)[vehicle];
        var (line, _) = Vehicles.Cell(b, row, col)!.Value;
        Assert.Null(Vehicles.EditCell(d, b, row, col, "7.25"));
        var after = OutLines(d);
        Assert.Equal(orig.Length, after.Length);
        Assert.Equal([d.Lines.IndexOf(line)], Enumerable.Range(0, orig.Length).Where(i => orig[i] != after[i]));
        Assert.Contains("7.25", after[d.Lines.IndexOf(line)]);
    }

    [Theory]
    [InlineData("corpus/2210/2210_1.LIN", 0, 20, 1)]
    [InlineData("app/Atb.Core.Tests/fixtures/vehicles/2479_2_sixdof.LIN", 0, 1, 3)]
    [InlineData("cases/2479/2479_2.LIN", 0, 1, 2)]
    [InlineData("app/Atb.Core.Tests/fixtures/vehicles/2479_2_splinepos.LIN", 0, 2, 1)]
    public void EditRewritesOneLineAgainstFileBytes(string rel, int vehicle, int row, int col) =>
        EditOneAgainstFile(Path.Combine(Fixtures.RepoRoot, rel), vehicle, row, col);

    /// Every vehicle (not just the first) of every client deck with more than one vehicle.
    [Fact]
    public void EveryVehicleOfMultiVehicleDecksEditsOneLine()
    {
        int multi = 0;
        foreach (var p in Fixtures.ClientDecks())
        {
            var bs = Vehicles.Blocks(Deck.Load(p));
            if (bs.Count < 2) continue;
            multi++;
            for (int v = 0; v < bs.Count; v++)
                if (Vehicles.RowCount(bs[v]) > 0) EditOneAgainstFile(p, v, Vehicles.RowCount(bs[v]) - 1, 1);
        }
        Assert.True(multi > 0, "no multi-vehicle client deck found");
    }

    /// Pins Cell with literals so an off-by-one can't hide behind tests that take the expected line from Cell itself:
    /// C.3 row 20 = 2nd value line (12 per line) token 8; C.5 accel row 1 col 2 = Data[2 C5a + 1] token 2.
    [Theory]
    [InlineData("corpus/2210/2210_1.LIN", 20, 1, 1, 8)]
    [InlineData("cases/2479/2479_2.LIN", 1, 2, 3, 2)]
    public void CellAddressesAsLiterals(string rel, int row, int col, int dataIndex, int token)
    {
        var b = Vehicles.Blocks(Deck.Load(Path.Combine(Fixtures.RepoRoot, rel)))[0];
        var (line, tok) = Vehicles.Cell(b, row, col)!.Value;
        Assert.Equal((dataIndex, token), (b.Data.IndexOf(line), tok));
    }

    [Theory]
    [InlineData("cases/2479/2479_2.LIN", new[] { 5 })]
    [InlineData("corpus/2210/2210_1.LIN", new[] { 1 })]
    public void DeckTypesAsLiterals(string rel, int[] types) =>
        Assert.Equal(types, Vehicles.Blocks(Deck.Load(Path.Combine(Fixtures.RepoRoot, rel))).Select(b => b.Type));
}
