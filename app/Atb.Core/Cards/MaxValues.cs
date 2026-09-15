namespace Atb.Core.Cards;

/// ATB 3I's "Maximum Value List" (File > Setting, decomp MainMenu.cs:4296-4317): the `Setting` table of ATB3iData.mdb,
/// copied from `mdb-export ATB3iData.mdb Setting` and listed as 3I's grid shows it (" ORDER BY ID ASC").
/// Read-only here: the app never opens the .mdb and never changes these limits.
public static class MaxValues
{
    public sealed record Row(int Id, string Name, int Value);   // 3I's Value column is Single; every row is whole

    public static readonly IReadOnlyList<Row> Rows =
    [
        new(1, "Max Segment", 80), new(2, "Max Joint", 80), new(3, "Max Vehicle", 6), new(4, "Max Function", 50),
        new(5, "Max Veh Pts Opt2", 99), new(6, "Max Veh Intrp Pts", 501), new(7, "Max Veh Pts Opt4", 501),
        new(8, "Max Harness", 5), new(9, "Max Belt", 20), new(10, "Max Ttl Belt Pts", 100), new(11, "Max Pts/Harness", 50),
        new(12, "Max Pts/Belt", 25), new(13, "Max Plane", 100), new(14, "Max Plane/Seg", 400), new(15, "Max Seg/Seg", 150),
        new(16, "Max Contact/Set", 5), new(17, "Max Ellipsoid", 80), new(18, "Max SD", 20), new(19, "Max AppF", 5),
        new(20, "Balance Force", 2), new(21, "Balance Accel", 1),
    ];
}
