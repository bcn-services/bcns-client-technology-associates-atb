using System.Text;
using System.Text.RegularExpressions;
using Atb.Core.Cards;
using Atb.Core.Lin;
using Xunit;

namespace Atb.Core.Tests;

public class CardGridTests
{
    static string Deck2479 => Fixtures.ClientDecks().Single(p => Path.GetFileName(p) == "2479_2.LIN");
    static readonly Regex Tok = new("\"[^\"]*\"|\\S+");

    [Fact]
    public void Edit_Segment1Weight_SaveDiffersInExactlyThatToken()
    {
        var original = File.ReadAllText(Deck2479, Encoding.Latin1);
        var deck = Deck.Load(Deck2479);
        var seg1 = deck.Cards("B.2.A").First();
        int idx = deck.Lines.IndexOf(seg1);
        const string weight = "123.456";
        Assert.NotEqual(weight, seg1.Tokens[1]);

        Assert.Null(deck.Edit(seg1, 1, weight));

        // Every other line still carries its original text (not reformatted from tokens).
        Assert.Equal([idx], deck.Lines.Select((l, i) => (l, i)).Where(x => x.l.Raw == null).Select(x => x.i));

        var tmp = Path.GetTempFileName();
        try
        {
            deck.Save(tmp);
            var lines = original.Split("\r\n");
            var m = Tok.Matches(lines[idx])[1];                      // the weight token, in place
            lines[idx] = lines[idx][..m.Index] + weight + lines[idx][(m.Index + m.Length)..];
            Assert.Equal(string.Join("\r\n", lines), File.ReadAllText(tmp, Encoding.Latin1));
        }
        finally { File.Delete(tmp); }
    }

    [Theory]
    [InlineData(1, "abc", "'abc' is not a number")]           // Weight: real
    [InlineData(11, "1.5", "'1.5' is not a whole number")]    // Define Rotation: int
    public void Edit_RefusesBadNumber_AndLeavesLineUntouched(int field, string text, string error)
    {
        var deck = Deck.Load(Deck2479);
        var seg1 = deck.Cards("B.2.A").First();
        var before = seg1.Tokens.ToList();
        Assert.Equal(error, deck.Edit(seg1, field, text));
        Assert.Equal(before, seg1.Tokens);
        Assert.NotNull(seg1.Raw);
    }

    [Fact]
    public void Edit_StringField_IsQuoted_AndFortranExponentAccepted()
    {
        var deck = Deck.Load(Deck2479);
        var seg1 = deck.Cards("B.2.A").First();
        Assert.Null(deck.Edit(seg1, 0, "Head"));
        Assert.Equal("\"Head\"", seg1.Tokens[0]);
        Assert.Null(deck.Edit(seg1, 1, "1.5D-3"));
        Assert.Equal("1.5D-3", seg1.Tokens[1]);
    }

    [Fact]
    public void ParsePaste_LabelsRows_AndRejectsWrongTokenCount()
    {
        const string text = "Head\t10\t1\t1\t1\t0.1\t0.1\t0.1\t0\t0\t0\t0\r\n"
                          + "Neck\t2\t1\t1\t1\t0.1\t0.1\t0.1\t0\t0\t0\r\n";          // 11 cells: one short
        var res = Deck.ParsePaste(text, "B.2.A");

        var line = Assert.Single(res.Lines);
        Assert.Equal("CARD B.2.a", line.Label);
        Assert.Equal(["\"Head\"", "10", "1", "1", "1", "0.1", "0.1", "0.1", "0", "0", "0", "0"], line.Tokens);
        Assert.Equal("row 2: expected 12 tokens, found 11", Assert.Single(res.Rejected));
    }

    [Theory]
    [InlineData("1\t36\t35", "H.4", null)]
    [InlineData("2\t36\t35", "H.4", "row 1: expected 1 + 2 x Count tokens, found 3 tokens")]
    [InlineData("Head\t10\t1\t1\t1\t0.1\t0.1\t0.1\t0\t0\t0\t0\t7", "B.2.A", "row 1: 13 cells, more than B.2.A holds")]
    [InlineData("Head\tx\t1\t1\t1\t0.1\t0.1\t0.1\t0\t0\t0\t0", "B.2.A", "row 1: B.2.A field 2: 'x' is not a number")]
    public void ParsePaste_ChecksEachRow(string text, string card, string? rejected)
    {
        var res = Deck.ParsePaste(text, card);
        if (rejected == null) { Assert.Single(res.Lines); Assert.Empty(res.Rejected); }
        else { Assert.Empty(res.Lines); Assert.Equal(rejected, Assert.Single(res.Rejected)); }
    }

    public static IEnumerable<object[]> ClientDecks() => Fixtures.ClientDecks().Select(p => new object[] { p });

    /// Copy (ToPasteText) then paste (ParsePaste) reproduces every screen's rows on every client deck.
    [Theory, MemberData(nameof(ClientDecks))]
    public void CopyThenPaste_RoundTripsEveryScreen(string path)
    {
        var deck = Deck.Load(path);
        foreach (var s in CardSchema.Screens)
        {
            var rows = deck.Rows(s.Cards);
            var res = Deck.ParsePaste(Deck.ToPasteText(rows, s.Cards), s.Cards);
            Assert.True(res.Rejected.Count == 0, $"{s.Name}: {string.Join("; ", res.Rejected)}");
            var want = rows.SelectMany(r => r.OfType<DeckLine>()).Where(l => l.Count > 0);   // empty H.n.b placeholders don't paste
            Assert.Equal(want.Select(l => l.Card + " " + string.Join(" ", l.Tokens)), res.Lines.Select(l => l.Card + " " + string.Join(" ", l.Tokens)));
        }
    }

    [Fact]
    public void Rows_GroupContinuationCardsAsExtraColumns()
    {
        var deck = Deck.Load(Deck2479);
        var rows = deck.Rows(["B.2.A", "B.2.B"]);
        Assert.Equal(deck.SegmentCount, rows.Count);
        foreach (var r in rows)
            Assert.Equal(r[0]!.Int(11) != 0, r[1] != null);             // B.2.b present exactly when Define Rotation != 0
    }

    [Fact]
    public void RefNames_NameSegmentsByPosition()
    {
        var deck = Deck.Load(Deck2479);
        var refs = deck.RefNames();
        Assert.Equal(deck.Cards("B.2.A").First().Str(0), refs[(Kind.SegRef, 1)]);
        Assert.Equal(deck.Cards("B.3.A").Last().Str(0), refs[(Kind.JointRef, deck.JointCount)]);
    }

    static IEnumerable<(string File, Deck Deck)> ClientAndLabelledVendorDecks()
    {
        foreach (var p in Fixtures.ClientDecks()) yield return (Path.GetFileName(p), Deck.Load(p));
        foreach (var p in Fixtures.VendorSamples()) { var d = Deck.Load(p); Labeler.Label(d); yield return (Path.GetFileName(p), d); }
    }

    /// Every token of every labelled line has a schema header; variable cards end on a whole
    /// repeat group (so a dropped name inside a repeated pair also shows up).
    [Fact]
    public void EveryDeckColumn_HasSchemaHeader()
    {
        var missing = new List<string>();
        foreach (var (file, deck) in ClientAndLabelledVendorDecks())
            for (int n = 0; n < deck.Lines.Count; n++)
            {
                var l = deck.Lines[n];
                if (l.Card.Length == 0) continue;
                int skip = CardSchema.Skip(l.Card, l.Count);
                for (int i = 0; i < l.Count; i++)
                    if (CardSchema.TryHeader(l.Card, i + skip) == null) missing.Add($"{file}:{n + 1} {l.Card} column {i + skip + 1}");
                if (CardSchema.Cards.TryGetValue(l.Card, out var s) && s.Tail > 0 && l.Count > s.Names.Length - s.Tail
                    && (l.Count - (s.Names.Length - s.Tail)) % s.Tail != 0)
                    missing.Add($"{file}:{n + 1} {l.Card} ends mid-group ({l.Count} tokens)");
            }
        Assert.Empty(missing);
    }

    /// Pins the header total so dropping a name the decks cannot expose (e.g. H.7 Count) goes red.
    [Fact]
    // 470 + 43 round-1b names: F.2.A 1, F.2.B 9, F.6 4, F.9.F 10, F.9.G 6, F.9.I 5, F.9.J1 7, F.9.M 1.
    public void SchemaHeaderTotal_IsPinned() => Assert.Equal(513,CardSchema.Cards.Values.Sum(c => c.Names.Length));

    [Fact]
    public void Screens_UseScopeTableTitles_AndCoverTheScopeCards()
    {
        var doc = File.ReadAllText(Path.Combine(Fixtures.RepoRoot, "docs/TIER2-SCOPE.md"));
        Assert.Empty(CardSchema.Screens.Where(s => !doc.Contains("| " + s.Title)).Select(s => s.Title));
        Assert.Empty(CardSchema.Screens.SelectMany(s => s.Cards).Where(c => !CardSchema.Cards.ContainsKey(c)).ToList());
        Assert.Empty(CardSchema.Screens.Where(s => s.Cards[..^1].Any(c => CardSchema.Cards[c].Fits != null)).Select(s => s.Name));
        // B.1 belongs to the Body Summary screen, C.3 rows are written unlabelled: both are their own LANE items.
        var onScreen = CardSchema.Screens.SelectMany(s => s.Cards).ToHashSet();
        Assert.Empty(CardSchemaTests.ScopeLabels.Except(["B.1", "C.3"]).Where(l => !onScreen.Contains(l)).ToList());
    }

    [Fact]
    public void Header_RepeatsVariableGroups()
    {
        Assert.Equal("Ref Segment 2", CardSchema.Header("H.4", 3));
        Assert.Equal("Segment or Joint 2", CardSchema.Header("H.4", 4));
        Assert.Equal("Symmetry Option 3", CardSchema.Header("D.7", 2));
        Assert.Equal(Kind.SegRef, CardSchema.KindOf("H.4", 5));
        Assert.Null(CardSchema.TryHeader("B.2.A", 12));
    }
}
