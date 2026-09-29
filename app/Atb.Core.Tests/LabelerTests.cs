using System.Text;
using System.Text.RegularExpressions;
using Atb.Core.Cards;
using Atb.Core.Lin;
using Xunit;

namespace Atb.Core.Tests;

public class LabelerTests
{
    public static IEnumerable<object[]> ClientDecks() => Fixtures.ClientDecks().Select(p => new object[] { p });
    public static IEnumerable<object[]> VendorSamples() => Fixtures.VendorSamples().Select(p => new object[] { p });

    static string[] ReadLines(string path) => File.ReadAllText(path, Encoding.Latin1).Replace("\r\n", "\n").TrimEnd('\n').Split('\n');
    static string[] WrittenLines(Deck d) => d.Write().Replace("\r\n", "\n").TrimEnd('\n').Split('\n');
    static bool IsSchemaLabel(DeckLine l) => l.Card.Length > 0 && CardSchema.Cards.ContainsKey(l.Card);
    static readonly Regex AnyLabel = new(@"(?i)(^|\s+)Cards?\s+[A-Z0-9.]+\s*$");
    static bool Is2479(string path) => Path.GetFileName(path) == "2479_2.LIN";
    const int BugLine = 321;                       // cases/2479/2479_2.LIN: empty H.3.a written as "CARD H.1.a"
    /// ATB 3I's bug row (2479_2 and its sibling decks in corpus/): only the label changes, H.1.a -> H.2.a/H.3.a.
    static bool IsH1BugFix(string raw, string written) =>
        raw.EndsWith("CARD H.1.a") && (written == raw[..^5] + "H.2.a" || written == raw[..^5] + "H.3.a");

    // "Labels completely": every line that carried any label ("Card x", "Cards x", malformed or not)
    // carries a schema label again, Validate() is clean, and the labels match the vendor's own
    // wherever the vendor's was a schema label. Unlabelled data rows (C.3, E.4 pairs, ...) stay unlabelled.
    [Theory, MemberData(nameof(VendorSamples))]
    public void Vendor_StrippedDeck_LabelsCompletely_AndMatchesOriginal(string path)
    {
        var original = Deck.Load(path);
        var raw = ReadLines(path);
        var deck = Deck.Parse(string.Join("\n", raw.Select(l => AnyLabel.Replace(l, ""))));
        Assert.All(deck.Lines, l => Assert.Equal("", l.Label));

        var grammar = Labeler.Label(deck);

        Assert.Empty(deck.Validate());
        int matched = 0;
        for (int i = 0; i < raw.Length; i++)
        {
            // F.8.B is the one card the vendor labels but ATB 3I writes unlabelled (a data row, like E.4 pairs).
            if (original.Lines[i].Card == "F.8.B") { Assert.Null(grammar[i]); Assert.Equal("", deck.Lines[i].Label); continue; }
            if (AnyLabel.IsMatch(raw[i]))
                Assert.True(IsSchemaLabel(deck.Lines[i]), $"line {i + 1} left without a schema label: {raw[i]}");
            if (IsSchemaLabel(original.Lines[i]))
            {
                Assert.True(original.Lines[i].Card == deck.Lines[i].Card, $"line {i + 1}: vendor {original.Lines[i].Card}, labeler {deck.Lines[i].Card}");
                matched++;
            }
            if (grammar[i] != null) Assert.Equal(Labeler.LabelFor(grammar[i]!), deck.Lines[i].Label);
        }
        Assert.True(matched > 100, $"only {matched} vendor schema labels compared");
    }

    [Theory, MemberData(nameof(VendorSamples))]
    public void Vendor_AsShipped_LabelsCleanly(string path)
    {
        var deck = Deck.Load(path);
        Labeler.Label(deck);
        Assert.Empty(deck.Validate());
    }

    [Theory, MemberData(nameof(ClientDecks))]
    public void ClientDeck_LabelThenWrite_UnchangedBytes(string path)
    {
        var raw = ReadLines(path);
        var deck = Deck.Load(path);
        var grammar = Labeler.Label(deck);
        var written = WrittenLines(deck);

        Assert.Equal(raw.Length, written.Length);
        var bugRows = Enumerable.Range(0, raw.Length).Where(i => IsH1BugFix(raw[i], written[i])).ToHashSet();   // pinned exactly by Bug2479
        for (int i = 0; i < raw.Length; i++)
        {
            if (bugRows.Contains(i)) continue;
            Assert.True(raw[i] == written[i], $"line {i + 1} changed: '{raw[i]}' -> '{written[i]}'");
        }
        if (bugRows.Count == 0) Assert.Equal(File.ReadAllBytes(path), Encoding.Latin1.GetBytes(deck.Write()));

        // The grammar walk agrees with ATB 3I's own labels (so it did not desync): the only allowed
        // difference is H.1 continuation rows, which ATB 3I labels H.1.a and the schema calls H.1.B.
        var original = Deck.Load(path);
        for (int i = 0; i < raw.Length; i++)
        {
            var have = original.Lines[i].Card;
            if (grammar[i] == null || bugRows.Contains(i)) continue;
            if (have == "H.1.A" && grammar[i] == "H.1.B") continue;
            Assert.True(have == grammar[i], $"line {i + 1}: deck says {have}, grammar says {grammar[i]}");
        }
    }

    [Fact]
    public void Bug2479_OnlyTheEmptyH3Row_IsRelabelled()
    {
        var path = Fixtures.ClientDecks().Single(Is2479);
        var raw = ReadLines(path);
        Assert.Equal("0    0    0    0    0    0    0    CARD H.1.a", raw[BugLine - 1]);

        var deck = Deck.Load(path);
        var grammar = Labeler.Label(deck);
        var written = WrittenLines(deck);

        var diffs = Enumerable.Range(0, raw.Length).Where(i => raw[i] != written[i]).Select(i => i + 1).ToList();
        Assert.Equal(new[] { BugLine }, diffs);
        Assert.Equal("0    0    0    0    0    0    0    CARD H.3.a", written[BugLine - 1]);
        Assert.Equal("H.3.A", grammar[BugLine - 1]);
        Assert.Equal("H.3.B", grammar[BugLine]);                // the "0    Card H.3.b" line that follows
        Assert.Empty(deck.Validate());
    }

    [Fact]
    public void SyntheticEmptyH2_WithH1Label_IsRelabelledH2a()
    {
        var raw = ReadLines(Fixtures.ClientDecks().Single(Is2479)).ToList();
        int first = raw.FindIndex(l => l.EndsWith("H.2.a", StringComparison.OrdinalIgnoreCase));
        int end = raw.FindIndex(first, l => Regex.IsMatch(l, @"(?i)card h\.3\.")) - 1;   // keep the H.3 bug row
        raw.RemoveRange(first, end - first);
        raw.InsertRange(first, ["0    0    0    0    0    0    0    CARD H.1.a", "    0    Card H.2.b"]);
        var deck = Deck.Parse(string.Join("\r\n", raw) + "\r\n");
        int h1Rows = deck.Cards("H.1.a").Count();

        var grammar = Labeler.Label(deck);

        Assert.Equal("CARD H.2.a", deck.Lines[first].Label);
        Assert.Equal("0    0    0    0    0    0    0    CARD H.2.a", deck.Lines[first].Raw);
        Assert.Equal("H.2.B", grammar[first + 1]);
        Assert.Equal(h1Rows - 2, deck.Cards("H.1.a").Count());     // the H.2 row and the H.3 bug row, nothing else
        Assert.Empty(deck.Validate());
    }

    [Fact]
    public void TruncatedMidCard_Throws_NamingLastCardUnderstood()
    {
        var raw = ReadLines(Fixtures.ClientDecks().Single(Is2479));
        int k = Array.FindIndex(raw, l => l.EndsWith("B.3.a", StringComparison.OrdinalIgnoreCase));
        var halfB3 = string.Join("    ", raw[k].Split(' ', StringSplitOptions.RemoveEmptyEntries).Take(5));
        var deck = Deck.Parse(string.Join("\r\n", raw.Take(k).Append(halfB3)) + "\r\n");
        var lastGood = deck.Lines[k - 1].Label;                    // the final B.2.a/B.2.b before the joints

        var ex = Assert.Throws<FormatException>(() => Labeler.Label(deck));

        Assert.Contains($"last card understood: {lastGood} at line {k}", ex.Message);
        Assert.Contains("B.3.A", ex.Message);
    }

    [Fact]
    public void WellFormedWrongLabel_IsLeftAlone()
    {
        var raw = ReadLines(Fixtures.ClientDecks().Single(Is2479));
        int k = Array.FindIndex(raw, l => l.EndsWith("B.5.a", StringComparison.OrdinalIgnoreCase));
        raw[k] = Regex.Replace(raw[k], @"(?i)B\.5\.a$", "B.4.a");
        int h = Array.FindIndex(raw, l => l.EndsWith("H.2.a", StringComparison.OrdinalIgnoreCase));
        raw[h] = Regex.Replace(raw[h], @"(?i)H\.2\.a$", "H.1.a");   // a non-empty H.2 row wearing H.1.a: not the bug, keep it
        var text = string.Join("\r\n", raw) + "\r\n";
        var deck = Deck.Parse(text);

        var grammar = Labeler.Label(deck);

        Assert.Equal("B.5.A", grammar[k]);
        Assert.Equal("B.4.A", deck.Lines[k].Card);
        Assert.Equal("H.2.A", grammar[h]);
        Assert.Equal("H.1.A", deck.Lines[h].Card);
        var written = WrittenLines(deck);
        Assert.Equal(raw[k], written[k]);
        Assert.Equal(raw[h], written[h]);
    }
}
