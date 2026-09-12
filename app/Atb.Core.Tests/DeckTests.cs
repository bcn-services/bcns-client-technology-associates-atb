using System.Text;
using Atb.Core.Lin;
using Xunit;

namespace Atb.Core.Tests;

public class DeckTests
{
    public static IEnumerable<object[]> ClientDecks() => Fixtures.ClientDecks().Select(p => new object[] { p });
    public static IEnumerable<object[]> VendorSamples() => Fixtures.VendorSamples().Select(p => new object[] { p });

    [Theory, MemberData(nameof(ClientDecks))]
    public void ClientDeck_RoundTrips_ByteExact_PreservingRaw(string path)
    {
        var bytes = File.ReadAllBytes(path);
        var deck = Deck.Load(path);
        Assert.Equal(bytes, Encoding.Latin1.GetBytes(deck.Write()));
    }

    [Theory, MemberData(nameof(ClientDecks))]
    public void ClientDeck_RoundTrips_ByteExact_Canonical(string path)
    {
        // Every line regenerated from tokens: proves the writer reproduces ATB 3I's own layout.
        var bytes = File.ReadAllBytes(path);
        var deck = Deck.Load(path);
        Assert.Equal(bytes, Encoding.Latin1.GetBytes(deck.Write(canonical: true)));
    }

    [Theory, MemberData(nameof(ClientDecks))]
    public void ClientDeck_HeaderCards_Parse(string path)
    {
        var deck = Deck.Load(path);
        Assert.True(deck.SegmentCount > 0);
        Assert.Equal(deck.SegmentCount, deck.Cards("B.2.a").Count());
        Assert.Equal(deck.JointCount, deck.Cards("B.3.a").Count());
        Assert.NotEmpty(deck.Title);
        var a4 = deck.Card("A.4")!;
        Assert.True(a4.Num(2) > 0);   // output interval
    }

    [Theory, MemberData(nameof(VendorSamples))]
    public void VendorSample_RoundTrips_Semantically(string path)
    {
        // Hand-laid-out decks: text differs after a canonical write, tokens and labels must not.
        var a = Deck.Load(path);
        var b = Deck.Parse(a.Write(canonical: true));
        Assert.Equal(a.Lines.Count, b.Lines.Count);
        for (int i = 0; i < a.Lines.Count; i++)
        {
            Assert.Equal(a.Lines[i].Tokens, b.Lines[i].Tokens);
            Assert.Equal(a.Lines[i].Card, b.Lines[i].Card);
        }
    }

    [Fact]
    public void Edit_RegeneratesOnlyTheEditedLine()
    {
        var path = Fixtures.ClientDecks().First();
        var deck = Deck.Load(path);
        var seg = deck.Cards("B.2.a").First();
        var before = deck.Write().Split("\r\n");
        seg.SetNum(1, 123.5);                       // weight
        Assert.Equal("123.5", seg.Tokens[1]);
        var after = deck.Write().Split("\r\n");
        Assert.Equal(before.Length, after.Length);
        var changed = Enumerable.Range(0, before.Length).Where(i => before[i] != after[i]).ToList();
        Assert.Single(changed);
        Assert.Contains("123.5    ", after[changed[0]]);
    }

    [Fact]
    public void Tokenizer_HandlesQuotedStringsAndFortranExponents()
    {
        var d = Deck.Parse("\"ATB Gas Range Fall\"    CARD A.1.b\r\n1.5D-3    6.25E-05    \"\"    Card X.1\r\n0    0    2    150    \r\n");
        Assert.Equal("ATB Gas Range Fall", d.Lines[0].Str(0));
        Assert.Equal("A.1.B", d.Lines[0].Card);
        Assert.Equal(0.0015, d.Lines[1].Num(0), 12);
        Assert.Equal(6.25e-5, d.Lines[1].Num(1), 12);
        Assert.Equal("", d.Lines[1].Str(2));
        Assert.Equal("", d.Lines[2].Card);
        Assert.Equal(4, d.Lines[2].Count);
    }
}
