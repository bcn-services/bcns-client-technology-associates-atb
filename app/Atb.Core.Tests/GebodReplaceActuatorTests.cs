using Atb.Core.Cards;
using Atb.Core.Lin;
using Xunit;

namespace Atb.Core.Tests;

/// GEBOD Replace of 2479_2 body 2 (segments 3-17, joints 2-16) with a 3-segment body: F.10 actuators on a surplus
/// joint or segment cascade out through Renumber.Delete, and ReplacedReferences lists them and their H.11 entries.
/// No client deck carries F.10/H.11, so they are spliced in as RenumberGapTests does (same 2479_2.LIN line numbers).
public class GebodReplaceActuatorTests
{
    static string Fixture => Path.Combine(Fixtures.RepoRoot, "cases", "2479", "2479_2.LIN");
    static string T(DeckLine l) => string.Join(" ", l.Tokens);
    static string[] All(Deck d, string card) => d.Cards(card).Select(T).ToArray();

    /// Actuator 1 on surplus joint 5, actuator 2 on surplus segment 10, actuator 3 on kept joint 2 / segment 2.
    static Deck ActuatorDeck()
    {
        var src = File.ReadAllText(Fixture).Split("\r\n").ToList();
        src.RemoveAt(src.Count - 1);
        src[128] = "9    0    0    9    0    0    0    0    0    0    0    1    CARD D.1.a";   // line 129: NEXTCD = 1
        src.InsertRange(296, ["5    3    1    1    1    1    CARD F.10", "3    10    1    1    1    1    CARD F.10", "2    2    1    1    1    1    CARD F.10"]);   // before line 297
        src.Insert(129, "3    CARD D.1.b");                                                                                  // before line 130
        src.Add("3    1    -2    3    CARD H.11");
        var d = Deck.Parse(string.Join("\r\n", src) + "\r\n");
        Assert.Empty(d.Validate());
        return d;
    }

    [Fact]
    public void SurplusActuators_AreListedWithTheirH11Entries_AndGoneAfterTheMerge()
    {
        var o = ActuatorDeck();
        var listed = GebodMerge.ReplacedReferences(o, 2, 3);
        Assert.Equal(2, listed.Count(s => s.Label.Contains("F.10", StringComparison.OrdinalIgnoreCase)));   // joint 5, segment 10
        Assert.Equal(2, listed.Count(s => s.Label.Contains("H.11", StringComparison.OrdinalIgnoreCase)));   // entries 1 and -2

        var d = GebodMerge.Merge(o, GebodMergeTests.SmallAin(3), new(GebodMode.Replace, 2), _ => true);
        Assert.Equal(["2 2 1 1 1 1"], All(d, "F.10"));
        Assert.Equal(["1"], All(d, "D.1.B"));
        Assert.Equal(["1 1"], All(d, "H.11"));
        Assert.Empty(d.Validate());
    }

    /// G.3.A is one per segment: Replace keeping a segment that has none throws instead of dropping GEBOD's line.
    [Fact]
    public void KeptSegmentWithoutG3A_Throws()
    {
        var o = Deck.Load(Fixture);
        o.Lines.Remove(o.Cards("G.3.A").Last());
        var ain = File.ReadAllText(Path.Combine(Fixtures.RepoRoot, "app/Atb.Core.Tests/fixtures/gebod-50m.ain"));
        var ex = Assert.Throws<InvalidOperationException>(() => GebodMerge.Merge(o, ain, new(GebodMode.Replace, 2), _ => true));
        Assert.Contains("G.3.A", ex.Message);
    }
}
