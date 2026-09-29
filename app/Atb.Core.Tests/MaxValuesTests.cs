using Atb.Core.Cards;
using Xunit;

namespace Atb.Core.Tests;

/// File > Setting (ATB 3I Maximum Value List). Expected rows written out by hand from
/// `mdb-export ATB3iData.mdb Setting` (ID,Value,FileID,ZzzKey,Name), sorted by ID as 3I's " ORDER BY ID ASC".
public class MaxValuesTests
{
    [Fact]
    public void Rows_AreTheSettingTableInIdOrder()
    {
        (int, string, int)[] want =
        [
            (1, "Max Segment", 80), (2, "Max Joint", 80), (3, "Max Vehicle", 6), (4, "Max Function", 50),
            (5, "Max Veh Pts Opt2", 99), (6, "Max Veh Intrp Pts", 501), (7, "Max Veh Pts Opt4", 501),
            (8, "Max Harness", 5), (9, "Max Belt", 20), (10, "Max Ttl Belt Pts", 100), (11, "Max Pts/Harness", 50),
            (12, "Max Pts/Belt", 25), (13, "Max Plane", 100), (14, "Max Plane/Seg", 400), (15, "Max Seg/Seg", 150),
            (16, "Max Contact/Set", 5), (17, "Max Ellipsoid", 80), (18, "Max SD", 20), (19, "Max AppF", 5),
            (20, "Balance Force", 2), (21, "Balance Accel", 1),
        ];
        Assert.Equal(want, MaxValues.Rows.Select(r => (r.Id, r.Name, r.Value)));
    }
}
