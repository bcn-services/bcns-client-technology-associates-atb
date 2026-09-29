using Atb.Core.Cards;
using Atb.Core.Lin;
using Xunit;

namespace Atb.Core.Tests;

/// GEBOD Replace on every body of every client deck under cases/ (read-only) with a shorter, equal-ish and full
/// 15-segment GEBOD body: Swap's missing-group throw must never fire on a valid deck, and the result still validates.
public class GebodReplaceClientDeckQaTests
{
    public static IEnumerable<object[]> Decks() =>
        Directory.GetFiles(Path.Combine(Fixtures.RepoRoot, "cases"), "*.LIN", SearchOption.AllDirectories).OrderBy(x => x).Select(p => new object[] { Path.GetRelativePath(Fixtures.RepoRoot, p) });

    [Theory, MemberData(nameof(Decks))]
    public void ReplaceEveryBody_NeverThrows_AndValidates(string rel)
    {
        var o = Deck.Load(Path.Combine(Fixtures.RepoRoot, rel));
        if (o.Card("B.1") is not { } b1 || b1.Int(3) != 0) return;   // flexible bodies: Merge refuses by design
        int nb = GebodMerge.BodyStarts(o).Count;
        foreach (int n in new[] { 2, 3, 15 })
            for (int k = 1; k <= nb; k++)
            {
                var ain = n == 15 ? File.ReadAllText(Path.Combine(Fixtures.RepoRoot, "app/Atb.Core.Tests/fixtures/gebod-50m.ain")) : GebodMergeTests.SmallAin(n);
                var d = GebodMerge.Merge(o, ain, new(GebodMode.Replace, k), _ => true);
                Assert.True(d.Validate().Count() == 0, $"{rel} body {k} n={n}: {string.Join("; ", d.Validate())}");
                Assert.Equal(nb, GebodMerge.BodyStarts(d).Count);
            }
    }
}
