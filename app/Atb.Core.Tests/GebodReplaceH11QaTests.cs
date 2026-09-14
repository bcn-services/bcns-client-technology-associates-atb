using Atb.Core.Cards;
using Atb.Core.Lin;
using Xunit;

namespace Atb.Core.Tests;

/// GEBOD Replace of 2479_2 body 2 with a 3-segment body when every H.11 entry names a surplus actuator while a kept
/// actuator remains: ReplacedReferences carries the STOP 741 warning, as Renumber.Delete's confirm list does.
public class GebodReplaceH11QaTests
{
    static Deck D()
    {
        var src = File.ReadAllText(Path.Combine(Fixtures.RepoRoot, "cases", "2479", "2479_2.LIN")).Split("\r\n").ToList();
        src.RemoveAt(src.Count - 1);
        src[128] = "9    0    0    9    0    0    0    0    0    0    0    1    CARD D.1.a";
        src.InsertRange(296, ["5    3    1    1    1    1    CARD F.10", "3    10    1    1    1    1    CARD F.10", "2    2    1    1    1    1    CARD F.10"]);
        src.Insert(129, "3    CARD D.1.b");
        src.Add("2    1    -2    CARD H.11");
        var d = Deck.Parse(string.Join("\r\n", src) + "\r\n");
        Assert.Empty(d.Validate());
        return d;
    }

    [Fact]
    public void AllH11EntriesSurplus_ListsStop741Warning()
    {
        var listed = GebodMerge.ReplacedReferences(D(), 2, 3);
        Assert.Contains(listed, s => s.Label == "H.11" && s.Field.Contains("STOP 741"));
    }
}
