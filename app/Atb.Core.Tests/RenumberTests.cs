using System.Text;
using Atb.Core.Cards;
using Atb.Core.Lin;
using Xunit;

namespace Atb.Core.Tests;

public class RenumberTests
{
    static string Deck2479 => Fixtures.ClientDecks().Single(p => Path.GetFileName(p) == "2479_2.LIN");
    static string Toks(DeckLine l) => string.Join(" ", l.Tokens);
    const string Zeros15 = "0 0 0 0 0 0 0 0 0 0 0 0 0 0 0";

    static void AssertSameBytesAsFixture(Deck deck)
    {
        var tmp = Path.GetTempFileName();
        try { deck.Save(tmp); Assert.Equal(File.ReadAllBytes(Deck2479), File.ReadAllBytes(tmp)); }
        finally { File.Delete(tmp); }
    }

    /// Every 2479_2.LIN line that inserting a segment before segment 3 changes, keyed by 1-based original
    /// line number (written out, not computed by Renumber). Unmarked 3s (function refs, plane counts, joint
    /// types) keep their value; Contact/Segment Ellip 3 and the ellipsoid ids 50-58 move with the segments.
    static readonly Dictionary<int, string> Seg3 = new()
    {
        [7] = "18 16 \"\" 0",
        [44] = "\"P \" 4 0 -2.835566 0 -1.744625 -3.676071 0 2.067626 0 0 0",
        [46] = "\"W \" 5 0 -2.505203 0 -0.9570769 -0.9472971 0 5.14171 0 0 0",
        [48] = "\"NP\" 6 0 -0.9038637 0 -6.10525 -0.8817869 0 0.9066975 0 0 0",
        [50] = "\"HP\" 7 0 0.4634387 0 -1.828431 -0.9119915 0 1.68329 0 0 0",
        [52] = "\"RH\" 4 0 0.9704475 2.616192 2.538732 0.8656181 -1.818487 -5.764667 0 0 0",
        [54] = "\"RK\" 9 1 1.032551 0.524969 9.106875 0.6786411 -0.493778 -6.133165 0 0 0",
        [56] = "\"RA\" 10 0 0.802995 -0.9686051 9.474138 1.422088 -0.210377 -1.699718 0 0 0",
        [58] = "\"LH\" 4 0 0.9704475 -2.616192 2.538732 0.8656181 1.818487 -5.764667 0 0 0",
        [60] = "\"LK\" 12 1 1.032551 -0.524969 9.106875 0.6786411 0.493778 -6.133165 0 0 0",
        [62] = "\"LA\" 13 0 0.802995 0.9686051 9.474138 1.422088 0.210377 -1.699718 0 0 0",
        [64] = "\"RS\" 6 0 -1.523903 5.756763 -3.866981 -1.019176 -0.4725141 -4.200781 0 0 0",
        [66] = "\"RE\" 15 1 -0.138217 -0.4728221 3.582985 0.2042421 0.21366 -5.746328 0 0 0",
        [68] = "\"LS\" 6 0 -1.523903 -5.756763 -3.866981 -1.019176 0.4725141 -4.200781 0 0 0",
        [70] = "\"LE\" 17 1 -0.138217 0.4728221 3.582985 0.2042421 -0.21366 -5.746328 0 0 0",
        [166] = "51 13 15 17 0 0 -1 0 0 0 20 20 20",
        [167] = "52 11 15 0.75 0 0 0.75 0 0 0 20 20 20",
        [168] = "53 0.75 15 0.75 10.25 0 0.75 0 0 0 2 2 2",
        [169] = "54 0.5 0.5 0.5 -8.5 10.5 17.5 0 0 0 2 2 2",
        [170] = "55 0.5 0.5 0.5 -8.5 -10.5 17.5 0 0 0 2 2 2",
        [171] = "56 0.5 0.5 0.5 10 10.5 17.5 0 0 0 2 2 2",
        [172] = "57 0.5 0.5 0.5 10 -10.5 17.5 0 0 0 2 2 2",
        [173] = "58 0.5 0.5 0.5 -13 -8.5 16 0 0 0 2 2 2",
        [174] = "59 0.75 15 0.75 12.25 0 -12.75 0 0 0 2 2 2",
        [175] = "0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0",
        [209] = "1 20 1 51 1 0 1 3 1 -1 0",
        [210] = "1 20 1 59 4 0 5 3 6 -2 0",
        [211] = "1 20 2 52 1 0 1 3 1 -1 0",
        [212] = "1 20 2 53 4 0 5 3 6 -2 0",
        [213] = "1 20 1 54 4 0 5 3 6 -2 1",
        [214] = "2 20 1 55 4 0 5 3 6 -2 1",
        [215] = "2 20 1 56 4 0 5 3 6 -2 1",
        [216] = "2 20 1 57 4 0 5 3 6 -2 1",
        [217] = "2 20 4 4 10 0 11 3 12 -2 0",
        [218] = "2 20 5 5 10 0 11 3 12 -2 0",
        [219] = "3 20 6 6 10 0 11 3 12 -2 0",
        [220] = "3 20 7 7 10 0 11 3 12 -2 0",
        [221] = "3 20 8 8 10 0 11 3 12 -2 0",
        [222] = "3 20 9 9 10 0 11 3 12 -2 0",
        [223] = "3 20 10 10 10 0 11 3 12 -2 0",
        [224] = "4 20 11 11 10 0 11 3 12 -2 1",
        [225] = "4 20 12 12 10 0 11 3 12 -2 0",
        [226] = "4 20 13 13 10 0 11 3 12 -2 0",
        [227] = "4 20 14 14 10 0 11 3 12 -2 1",
        [228] = "4 20 15 15 10 0 11 3 12 -2 0",
        [229] = "5 20 16 16 10 0 11 3 12 -2 0",
        [230] = "5 20 17 17 10 0 11 3 12 -2 0",
        [231] = "5 20 18 18 10 0 11 3 12 -2 0",
        [232] = "6 2 4 4 10 0 11 3 13 1 0",
        [233] = "6 2 5 5 10 0 11 3 13 1 0",
        [234] = "6 2 6 6 10 0 11 3 13 1 0",
        [235] = "6 2 7 7 10 0 11 3 13 1 0",
        [236] = "6 2 8 8 10 0 11 3 13 1 0",
        [237] = "7 2 9 9 10 0 11 3 13 1 0",
        [238] = "7 2 10 10 10 0 11 3 13 1 0",
        [239] = "7 2 11 11 10 0 11 3 13 1 0",
        [240] = "7 2 12 12 10 0 11 3 13 1 0",
        [241] = "7 2 13 13 10 0 11 3 13 1 0",
        [242] = "8 2 14 14 10 0 11 3 13 1 0",
        [243] = "8 2 15 15 10 0 11 3 13 1 0",
        [244] = "8 2 16 16 10 0 11 3 13 1 0",
        [245] = "8 2 17 17 10 0 11 3 13 1 0",
        [246] = "8 2 18 18 10 0 11 3 13 1 0",
        [247] = "9 20 1 58 1 0 5 3 6 -2 1",
        [248] = "4 0 0 4 4 4 3 4 4 4 3 2 3 1 2 3 1 1",
        [249] = "1 59 4 4 10 0 11 3 13 0",
        [250] = "1 59 5 5 10 0 11 3 13 0",
        [251] = "1 59 6 6 10 0 11 3 13 0",
        [252] = "1 59 8 8 10 0 11 3 13 0",
        [253] = "4 4 15 15 7 0 8 3 9 0",
        [254] = "4 4 16 16 7 0 8 3 9 0",
        [255] = "4 4 17 17 7 0 8 3 9 0",
        [256] = "4 4 18 18 7 0 8 3 9 0",
        [257] = "5 5 15 15 7 0 8 3 9 0",
        [258] = "5 5 16 16 7 0 8 3 9 0",
        [259] = "5 5 17 17 7 0 8 3 9 0",
        [260] = "5 5 18 18 7 0 8 3 9 0",
        [261] = "6 6 4 4 7 0 8 3 9 0",
        [262] = "6 6 9 9 7 0 8 3 9 0",
        [263] = "6 6 16 16 7 0 8 3 9 0",
        [264] = "6 6 18 18 7 0 8 3 9 0",
        [265] = "7 7 16 16 7 0 8 3 9 0",
        [266] = "7 7 18 18 7 0 8 3 9 0",
        [267] = "7 7 1 59 10 0 11 3 13 0",
        [268] = "8 8 15 15 7 0 8 3 9 0",
        [269] = "8 8 16 16 7 0 8 3 9 0",
        [270] = "8 8 17 17 7 0 8 3 9 0",
        [271] = "8 8 18 18 7 0 8 3 9 0",
        [272] = "9 9 6 6 7 0 8 3 9 0",
        [273] = "9 9 12 12 7 0 8 3 9 0",
        [274] = "9 9 13 13 7 0 8 3 9 0",
        [275] = "9 9 16 16 7 0 8 3 9 0",
        [276] = "10 10 4 4 7 0 8 3 9 0",
        [277] = "10 10 12 12 7 0 8 3 9 0",
        [278] = "10 10 13 13 7 0 8 3 9 0",
        [279] = "10 10 14 14 7 0 8 3 9 0",
        [280] = "11 11 12 12 7 0 8 3 9 0",
        [281] = "11 11 13 13 7 0 8 3 9 0",
        [282] = "11 11 14 14 7 0 8 3 9 0",
        [283] = "12 12 16 16 7 0 8 3 9 0",
        [284] = "12 12 18 18 7 0 8 3 9 0",
        [285] = "13 13 16 16 7 0 8 3 9 0",
        [286] = "13 13 18 18 7 0 8 3 9 0",
        [287] = "13 13 4 4 7 0 8 3 9 0",
        [288] = "14 14 9 9 7 0 8 3 9 0",
        [289] = "15 15 17 17 7 0 8 3 9 0",
        [290] = "15 15 18 18 7 0 8 3 9 0",
        [291] = "16 16 9 9 7 0 8 3 9 0",
        [292] = "16 16 10 10 7 0 8 3 9 0",
        [293] = "16 16 18 18 7 0 8 3 9 0",
        [294] = "17 17 16 16 7 0 8 3 9 0",
        [295] = "18 18 10 10 7 0 8 3 9 0",
        [303] = "0 -15 0 0 0 0 0 0 0 4",
        [304] = "0 -15 0 0 0 0 0 0 0 5",
        [305] = "0 7 0 0 0 0 0 0 0 6",
        [306] = "0 7 0 0 0 0 0 0 0 7",
        [307] = "0 30 0 0 0 0 0 0 0 4",
        [308] = "0 -55 0 0 0 0 0 0 0 9",
        [309] = "0 115 0 0 0 0 0 0 0 10",
        [310] = "0 30 0 0 0 0 0 0 0 4",
        [311] = "0 -55 0 0 0 0 0 0 0 12",
        [312] = "0 115 0 0 0 0 0 0 0 13",
        [313] = "0 70 -5 0 0 0 0 0 0 6",
        [314] = "0 90 0 0 0 0 0 0 0 15",
        [315] = "0 70 5 0 0 0 0 0 0 6",
        [316] = "0 90 0 0 0 0 0 0 0 17",
        [317] = "1 20 1 0 0 0 0",
        [319] = "2 20 4 0 0 0 0",
        [320] = "20 6 0 0 0 0",
        [325] = "2 20 1 1 2",
    };

    [Fact]
    public void InsertBeforeSegment3_ShiftsEveryRefAtOrAbove3_AndNothingElse()
    {
        var deck = Deck.Load(Deck2479);
        var seg1 = deck.Cards("B.2.A").First();
        Assert.Null(deck.Edit(seg1, 5, "3.0"));                      // an unmarked real equal to 3.0 must stay
        var orig = deck.Lines.ToList();
        var before = orig.Select(Toks).ToList();

        Renumber.Insert(deck, Entity.Segment, 3, Renumber.Copy(deck, Entity.Segment, 3));

        for (int i = 0; i < orig.Count; i++)
            if (Seg3.TryGetValue(i + 1, out var want)) Assert.Equal($"{i + 1}: {want}", $"{i + 1}: {Toks(orig[i])}");
            else
            {
                Assert.Equal($"{i + 1}: {before[i]}", $"{i + 1}: {Toks(orig[i])}");
                if (orig[i] != seg1) Assert.True(orig[i].Raw != null, $"line {i + 1} was rewritten");
            }
        Assert.Equal("\"RN\" 112 53.1 47.7 38.1 3.0 2 2 0 0 0 0", Toks(seg1));
        Assert.Contains(seg1, deck.Lines);

        var added = deck.Lines.Select((l, i) => (l, i)).Where(x => !orig.Contains(x.l)).Select(x => $"{x.i + 1} {x.l.Label}: {Toks(x.l)}");
        Assert.Equal([
            "10 CARD B.2.a: \"LT \" 30.86138 1.400881 1.299289 2.108249 5.29593 8.04508 4.892385 0.353062 0 1.993187 1",
            "11 CARD B.2.b: 0 0 0",
            "108 CARD B.6: 0.01 0.01 0.01 0.01 0.01 0.01 0.1 0.1 0.1 0.1 0.1 0.01",
            "305 CARD G.3.a: 180 50 0 0 0 0 0 0 0 1",
        ], added);
        Assert.Empty(deck.Validate());
    }

    [Fact]
    public void DeleteLastJoint_ThenReAdd_ReproducesTheFileByteForByte()
    {
        var deck = Deck.Load(Deck2479);
        bool asked = false;
        var data = Renumber.Delete(deck, Entity.Joint, 16, _ => asked = true);

        Assert.False(asked);                                         // nothing refers to joint 16
        Assert.NotNull(data);
        Assert.Equal("17 15 \"\" 0", Toks(deck.Card("B.1")!));
        Assert.Equal(Zeros15, Toks(deck.Card("F.4.A")!));
        Assert.Equal(325, deck.Lines.Count);                         // B.3.a, B.3.b, B.4.a, B.5.a gone
        Assert.Equal("\"LS\"", deck.Cards("B.3.A").Last().Tokens[0]);
        Assert.Empty(deck.Validate());

        Renumber.Insert(deck, Entity.Joint, 16, data!);
        AssertSameBytesAsFixture(deck);
    }

    [Fact]
    public void InsertBeforeSegment1_ShiftsRefsEqualTo1()
    {
        var deck = Deck.Load(Deck2479);
        var orig = deck.Lines.ToList();
        Renumber.Insert(deck, Entity.Segment, 1, Renumber.Copy(deck, Entity.Segment, 1));

        Assert.Equal("18 16 \"\" 0", Toks(orig[6]));
        Assert.Equal("\"HNG\" 2 1 11 0 5 -11 0 0 0 0 0", Toks(orig[39]));      // Seg JNT 1 -> 2, Joint Type 1 stays
        Assert.Equal("\"NULL\" 0 0 0 0 0 0 0 0 0 0 0", Toks(orig[41]));
        Assert.Equal("0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0", Toks(orig[174]));   // D.7: 18 values
        Assert.Equal("1 20 2 51 1 0 1 3 1 -1 0", Toks(orig[208]));             // Plane 1 and F1 1 stay
        Assert.Equal("0 4 0 4 4 4 3 4 4 4 3 2 3 1 2 3 1 1", Toks(orig[247]));  // F.3.A
        Assert.Equal("7 7 2 59 10 0 11 3 13 0", Toks(orig[266]));   // line 267 was 6 6 1 58
        Assert.Equal("0 0 0 0 0 0 0 0 0 0", Toks(orig[299]));                 // Ref Segment 0 stays
        Assert.Equal("0 0 0 0 0 0 0 0 0 2", Toks(orig[300]));
        Assert.Equal("1 20 2 0 0 0 0", Toks(orig[316]));
        Assert.Equal("2 20 2 2 3", Toks(orig[324]));
        Assert.Equal("\"RN\"", deck.Lines[7].Tokens[0]);
        Assert.DoesNotContain(deck.Lines[7], orig);
        Assert.Empty(deck.Validate());
    }

    static Deck WithJointOutputs() => Deck.Parse(File.ReadAllText(Deck2479, Encoding.Latin1)
        .Replace("0    Card H.7", "3    5    8    12    Card H.7").Replace("0    Card H.9", "2    19    8    3    12    Card H.9"));

    [Fact]
    public void DeleteMiddleJoint_AsksFirst_ThenDropsItsOutputEntriesAndShiftsTheRest()
    {
        var deck = WithJointOutputs();
        var text = deck.Write();
        IReadOnlyList<RefSite>? seen = null;
        Assert.Null(Renumber.Delete(deck, Entity.Joint, 8, r => { seen = r; return false; }));
        Assert.Equal([new RefSite(326, "Card H.7", "Joint 2"), new RefSite(328, "Card H.9", "Joint")], seen);
        Assert.Equal(text, deck.Write());                            // declined: nothing changed

        var orig = deck.Lines.ToList();
        Assert.NotNull(Renumber.Delete(deck, Entity.Joint, 8, _ => true));
        Assert.Equal("17 15 \"\" 0", Toks(deck.Card("B.1")!));
        Assert.Equal(Zeros15, Toks(deck.Card("F.4.A")!));
        Assert.Equal("2 5 11", Toks(deck.Card("H.7")!));
        Assert.Equal("1 3 11", Toks(deck.Card("H.9")!));             // pair (19, joint 8) gone; Ref Segment 3 is not a joint
        int[] gone = [54, 55, 79, 95];                               // RK's B.3.a, B.3.b, B.4.a, B.5.a
        Assert.Equal(gone, Enumerable.Range(1, orig.Count).Where(n => !deck.Lines.Contains(orig[n - 1])));
        Assert.Equal("\"RA\"", deck.Cards("B.3.A").ElementAt(7).Tokens[0]);
        Assert.Empty(deck.Validate());
    }

    [Fact]
    public void DeleteReferencedSegment_ListsReferencingLines_ThenCascadesLikeAtb3i()
    {
        var deck = Deck.Load(Deck2479);
        var text = deck.Write();
        IReadOnlyList<RefSite>? seen = null;
        Assert.Null(Renumber.Delete(deck, Entity.Segment, 3, r => { seen = r; return false; }));
        Assert.Equal([44, 52, 58, 217, 232, 249, 253, 254, 255, 256, 261, 276, 287, 303, 307, 310, 319], seen!.Select(s => s.Line).Distinct());
        Assert.Equal(new RefSite(44, "CARD B.3.a", "Seg JNT"), seen![0]);
        Assert.Equal(text, deck.Write());

        Assert.NotNull(Renumber.Delete(deck, Entity.Segment, 3, _ => true));
        Assert.Equal("16 16 \"\" 0", Toks(deck.Card("B.1")!));
        var b3 = deck.Cards("B.3.A").Select(l => l.Tokens[0] + " " + l.Tokens[1]);
        Assert.Equal(["\"HNG\" 1", "\"NULL\" 0", "\"P \" -1", "\"W \" 3", "\"NP\" 4", "\"HP\" 5", "\"RH\" -1", "\"RK\" 7",
                      "\"RA\" 8", "\"LH\" -1", "\"LK\" 10", "\"LA\" 11", "\"RS\" 4", "\"RE\" 13", "\"LS\" 4", "\"LE\" 15"], b3);
        Assert.Equal("0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0", Toks(deck.Card("D.7")!));
        Assert.Equal("49 13 15 17 0 0 -1 0 0 0 20 20 20", Toks(deck.Card("D.5")!));
        Assert.Equal("5 4 5 5 3 4 5 5 1", Toks(deck.Card("F.1.A")!));
        Assert.Equal(37, deck.Cards("F.1.B").Count());
        Assert.Equal("2 18 3 3 10 0 11 3 12 -2 0", Toks(deck.Cards("F.1.B").ElementAt(8)));
        Assert.Equal("3 0 4 3 3 4 4 3 3 2 2 1 2 3 1 1", Toks(deck.Card("F.3.A")!));
        Assert.Equal(39, deck.Cards("F.3.B").Count());
        Assert.Equal(["0 -15 0 0 0 0 0 0 0 0", "0 -15 0 0 0 0 0 0 0 3"], deck.Cards("G.3.A").Skip(2).Take(2).Select(Toks));
        Assert.Equal("2 18 0 0 0 0 0", Toks(deck.Card("H.2.A")!));
        Assert.Equal("18 4 0 0 0 0", Toks(deck.Card("H.2.B")!));
        Assert.Empty(deck.Validate());
    }

    [Fact]
    public void DeleteSegment_CascadesAnEllipsoidOnIt_AndDecrementsNelp()
    {
        var deck = Deck.Parse(File.ReadAllText(Deck2479, Encoding.Latin1).Replace("50    13    15    17", "17    13    15    17"));
        Assert.NotNull(Renumber.Delete(deck, Entity.Segment, 17, _ => true));
        Assert.Equal("9 0 0 8 0 0 0 0 0 0 0 0", Toks(deck.Card("D.1.A")!));   // NELP 9 -> 8
        Assert.Equal(8, deck.Cards("D.5").Count());
        Assert.Equal("50 11 15 0.75 0 0 0.75 0 0 0 20 20 20", Toks(deck.Cards("D.5").First()));   // was 51
        Assert.Equal("16 16 \"\" 0", Toks(deck.Card("B.1")!));
        Assert.Empty(deck.Validate());
    }

    [Fact]
    public void InsertVehicle_TakesTheNextSegmentNumber_AndDeletingItRestoresTheFile()
    {
        var deck = Deck.Load(Deck2479);
        Assert.Throws<InvalidOperationException>(() => Renumber.Delete(deck, Entity.Vehicle, 1, _ => true));   // primary vehicle

        Renumber.Insert(deck, Entity.Vehicle, 1, Renumber.Copy(deck, Entity.Vehicle, 1));
        Assert.Equal(["0 0 0 0 0 0 0 0 -501 0 0.01 0 0 18", "0 0 0 0 0 0 0 0 -501 0 0.01 0 0 0"], deck.Cards("C.2.A").Select(Toks));
        Assert.Equal("17 16 \"\" 0", Toks(deck.Card("B.1")!));
        Assert.Equal("1 20 1 51 1 0 1 3 1 -1 0", Toks(deck.Card("F.1.B")!));
        Assert.Equal("2 20 1 1 2", Toks(deck.Card("H.6")!));
        Assert.Empty(deck.Validate());

        Assert.NotNull(Renumber.Delete(deck, Entity.Vehicle, 1, _ => throw new Exception("nothing refers to vehicle 1")));
        AssertSameBytesAsFixture(deck);
    }

    [Fact]
    public void InsertPlaneBeforePlane1_RenumbersPlaneIds_AndDeletingItRestoresTheFile()
    {
        var deck = Deck.Load(Deck2479);
        Renumber.Insert(deck, Entity.Plane, 1, Renumber.Copy(deck, Entity.Plane, 9));

        Assert.Equal("10 0 0 9 0 0 0 0 0 0 0 0", Toks(deck.Card("D.1.A")!));
        Assert.Equal(["1 \"Wall bracket\"", "2 \"Floor\"", "10 \"Wall bracket\""], deck.Cards("D.2.A").Where((_, i) => i is 0 or 1 or 9).Select(Toks));
        Assert.Equal("0 5 5 5 5 3 5 5 5 1", Toks(deck.Card("F.1.A")!));
        Assert.Equal(["2 19 1 50 1 0 1 3 1 -1 0", "10 19 1 57 1 0 5 3 6 -2 1"], new[] { deck.Cards("F.1.B").First(), deck.Cards("F.1.B").Last() }.Select(Toks));
        Assert.Empty(deck.Validate());

        Assert.NotNull(Renumber.Delete(deck, Entity.Plane, 1, _ => throw new Exception("nothing refers to plane 1")));
        AssertSameBytesAsFixture(deck);
    }
}
