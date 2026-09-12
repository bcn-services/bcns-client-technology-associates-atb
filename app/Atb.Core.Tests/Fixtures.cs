namespace Atb.Core.Tests;

static class Fixtures
{
    /// Repo root = nearest ancestor of the test binary that contains cases/.
    public static string RepoRoot
    {
        get
        {
            var d = new DirectoryInfo(AppContext.BaseDirectory);
            while (d != null && !Directory.Exists(Path.Combine(d.FullName, "cases"))) d = d.Parent;
            return d?.FullName ?? throw new InvalidOperationException("cases/ not found above " + AppContext.BaseDirectory);
        }
    }

    public static IEnumerable<string> ClientDecks() =>
        Directory.GetFiles(Path.Combine(RepoRoot, "cases"), "*.LIN", SearchOption.AllDirectories).OrderBy(x => x);

    public static IEnumerable<string> ClientSa1s() =>
        Directory.GetFiles(Path.Combine(RepoRoot, "cases"), "*.sa1", SearchOption.AllDirectories).OrderBy(x => x);

    /// General Dynamics sample decks shipped in the ATB 3I installer (hand-written layout, not ATB 3I output).
    public static IEnumerable<string> VendorSamples() =>
        Directory.GetFiles(Path.Combine(RepoRoot, "app/Atb.Core.Tests/fixtures/vendor"), "*.lin").OrderBy(x => x);
}
