using System.Text;
using System.Text.RegularExpressions;
using Atb.Core.Cards;
using Atb.Core.Lin;
using Xunit;

namespace Atb.Core.Tests;

public class CardSchemaTests
{
    public static IEnumerable<object[]> ClientDecks() => Fixtures.ClientDecks().Select(p => new object[] { p });

    /// docs/TIER2-SCOPE.md §2 cards, expanded to the concrete labels the decks carry.
    static readonly string[] ScopeLabels =
    [
        "A.1.A", "A.1.B", "A.1.C", "A.3", "A.4", "A.5",
        "B.1", "B.2.A", "B.2.B", "B.3.A", "B.3.B", "B.3.C", "B.4.A", "B.4.B", "B.5.A", "B.5.B", "B.5.C", "B.6",
        "C.1", "C.2.A", "C.2.B", "C.3", "C.4", "C.5",
        "D.2.A", "D.2.B", "D.2.C", "D.2.D", "D.5", "D.6", "D.7", "D.8", "D.9",
        "E.1", "E.2", "E.3", "E.4.A", "E.6.A", "E.6.B", "E.6.C", "E.7.A", "E.7.B", "E.7.C",
        "F.1.B", "F.3.B", "F.4.B", "F.7.B", "F.7.C", "F.8.A", "F.8.C", "F.8.D1", "F.8.D2", "F.10",
        "G.1", "G.2", "G.3.A",
        "H.1.A", "H.1.B", "H.2.A", "H.2.B", "H.3.A", "H.3.B", "H.4", "H.5", "H.6", "H.7", "H.8", "H.9",
        "H.10.A", "H.10.B", "H.10.C", "H.11", "H.12.A", "H.12.B",
    ];

    [Theory, MemberData(nameof(ClientDecks))]
    public void ClientDeck_Validates_Clean(string path) => Assert.Empty(Deck.Load(path).Validate());

    [Theory, MemberData(nameof(ClientDecks))]
    public void ClientDeck_EveryLabel_HasSchemaEntry(string path)
    {
        var missing = Deck.Load(path).Lines.Select(l => l.Card).Where(c => c.Length > 0 && !CardSchema.Cards.ContainsKey(c)).Distinct();
        Assert.Empty(missing);
    }

    [Fact]
    public void EveryScopeCard_HasSchemaEntry()
    {
        var missing = ScopeLabels.Where(l => !CardSchema.Cards.ContainsKey(l)).ToArray();   // failure names each missing label
        Assert.Empty(missing);
    }

    [Fact]
    public void EveryEntry_HasOneKindPerName()
    {
        Assert.Empty(CardSchema.Cards.Values.Where(c => c.Names.Length != c.Kinds.Length || c.Names.Length == 0).Select(c => c.Label));
        Assert.Empty(CardSchema.Cards.Values.Where(c => (c.Rule == null) != (c.Fits == null)).Select(c => c.Label));
    }

    [Fact]
    public void CorruptedTokenCount_ReportsLabelLineAndReason()
    {
        var path = Fixtures.ClientDecks().Single(p => p.EndsWith("2479_2.LIN"));
        var text = File.ReadAllText(path, Encoding.Latin1);
        int idx = Deck.Parse(text).Lines.FindIndex(l => l.Card == "B.2.A");
        var lines = text.Split('\n');
        // drop the token right before the label (Define Rotation)
        lines[idx] = new Regex(@"\s+\S+(?=\s+CARD\s)", RegexOptions.IgnoreCase).Replace(lines[idx], "", 1);

        var issue = Assert.Single(Deck.Parse(string.Join('\n', lines)).Validate());
        Assert.Equal(new DeckIssue(idx + 1, "B.2.A", "expected 12 tokens, found 11"), issue);
    }

    [Theory]
    [InlineData("1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19    CARD D.7", "D.7", "expected 1-18 values per line (18 per line, last line holds the remainder), found 19 tokens")]
    [InlineData("2    36    35    CARD H.4", "H.4", "expected 1 + 2 x Count tokens, found 3 tokens")]
    [InlineData("3    1    2    CARD H.7", "H.7", "expected 1 + Count tokens, found 3 tokens")]
    [InlineData("1    2    3    CARD H.1.b", "H.1.B", "expected 0, 1 or 6 tokens, found 3 tokens")]
    [InlineData("1    2    CARD Z.9", "Z.9", "no schema entry for this card")]
    public void VariableAndUnknownCards_AreReported(string line, string label, string reason) =>
        Assert.Equal(new DeckIssue(2, label, reason), Assert.Single(Deck.Parse("\"x\"    CARD A.1.a\n" + line + "\n").Validate()));

    [Fact]
    public void VariableCards_AcceptValidCounts()
    {
        const string deck = "2    36    35    36    5    CARD H.4\n0    Card H.7\n    Card H.2.b\n    36    5    0    0    0    0    Card H.1.a\n1    2    3    4    CARD H.10.b\n";
        Assert.Empty(Deck.Parse(deck).Validate());
    }

    [Fact]
    public void Header_KeepsWorkingForMainForm()
    {
        Assert.Equal("Define Rotation", CardSchema.Header("B.2.A", 11));
        Assert.Equal("EllipID", CardSchema.Header("d.5", 0));
        Assert.Equal("Value 13", CardSchema.Header("B.2.A", 12));
        Assert.Equal("Value 1", CardSchema.Header("NOPE", 0));
    }
}
