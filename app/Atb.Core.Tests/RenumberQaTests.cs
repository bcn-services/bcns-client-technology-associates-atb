using Atb.Core.Cards;
using Atb.Core.Lin;
using Xunit;

namespace Atb.Core.Tests;

/// QA's independent checks for Renumber: every expected line is a literal copied by hand from
/// cases/2479/2479_2.LIN (1-based original line numbers), never computed through Renumber's helpers.
public class RenumberQaTests
{
    static string Fixture => Path.Combine(Fixtures.RepoRoot, "cases", "2479", "2479_2.LIN");
    static string T(DeckLine l) => string.Join(" ", l.Tokens);
    static string Z(int n) => string.Join(" ", Enumerable.Repeat("0", n));

    /// Fixture text with one labelled line replaced (keeps CRLF/LF as the file has it).
    static Deck WithLine(string oldLine, string newLine)
    {
        var text = File.ReadAllText(Fixture);
        Assert.Contains(oldLine, text);
        return Deck.Parse(text.Replace(oldLine, newLine));
    }

    [Fact]
    public void InsertBeforeSegment3_ShiftsRefsAtOrAbove3_LeavesLowerAndUnmarkedAlone()
    {
        var deck = Deck.Load(Fixture);
        // Real fields equal to 3.0 (B.2.b principal angles of segment 3, D.2.b plane-1 point): unmarked, must not move.
        deck.Lines[10].Tokens[0] = "3"; deck.Lines[10].Tokens[1] = "3"; deck.Lines[10].Tokens[2] = "3";
        deck.Lines[130].Tokens[0] = "3"; deck.Lines[130].Tokens[1] = "3"; deck.Lines[130].Tokens[2] = "3";
        var orig = deck.Lines.ToList();
        var before = orig.Select(T).ToList();

        Renumber.Insert(deck, Entity.Segment, 3, Renumber.Copy(deck, Entity.Segment, 3));
        string At(int line) => T(orig[line - 1]);

        Assert.Equal("18 16 \"\" 0", At(7));                                           // B.1 segments +1, joints same
        Assert.Equal("\"HNG\" 1 1 11 0 5 -11 0 0 0 0 0", At(40));                      // B.3.a seg 1 < 3
        Assert.Equal("\"NULL\" 0 0 0 0 0 0 0 0 0 0 0", At(42));
        Assert.Equal("\"P \" 4 0 -2.835566 0 -1.744625 -3.676071 0 2.067626 0 0 0", At(44));
        Assert.Equal("\"RK\" 9 1 1.032551 0.524969 9.106875 0.6786411 -0.493778 -6.133165 0 0 0", At(54));
        Assert.Equal("3 3 3", At(11));                                                 // real 3.0 untouched
        Assert.Equal("3 3 3", At(131));
        Assert.Equal("0 0 0 0 0 0 0 0 -501 0 0.01 0 0 0", At(122));                    // C.2.a refs 0
        Assert.Equal("9 0 0 9 0 0 0 0 0 0 0 0", At(129));                              // D.1.a unchanged
        Assert.Equal("1 \"Floor\"", At(130));                                          // plane id not a segment
        Assert.Equal("51 13 15 17 0 0 -1 0 0 0 20 20 20", At(166));                    // D.5 ellipsoid 50 -> 51
        Assert.Equal("59 0.75 15 0.75 12.25 0 -12.75 0 0 0 2 2 2", At(174));
        Assert.Equal(Z(18), At(175));                                                  // D.7 one more value
        Assert.Equal("5 5 5 5 3 5 5 5 1", At(208));                                    // F.1.a int count 3 untouched
        Assert.Equal("1 20 1 51 1 0 1 3 1 -1 0", At(209));                             // F.1.b func 3 untouched
        Assert.Equal("2 20 4 4 10 0 11 3 12 -2 0", At(217));
        Assert.Equal("3 20 6 6 10 0 11 3 12 -2 0", At(219));                           // plane 3 untouched
        Assert.Equal("6 2 4 4 10 0 11 3 13 1 0", At(232));                             // plane seg 2 < 3
        Assert.Equal("4 0 0 4 4 4 3 4 4 4 3 2 3 1 2 3 1 1", At(248));                  // F.3.a 0 inserted at slot 3
        Assert.Equal("1 59 4 4 10 0 11 3 13 0", At(249));
        Assert.Equal("4 4 15 15 7 0 8 3 9 0", At(253));
        Assert.Equal("7 7 1 59 10 0 11 3 13 0", At(267));
        Assert.Equal(Z(16), At(296));                                                  // F.4.a unchanged
        Assert.Equal("50 0 -17.99 0 0 0 0 0", At(298));                                // G.2
        Assert.Equal("0 0 0 0 0 0 0 0 0 1", At(301));                                  // G.3.a ref 1 < 3
        Assert.Equal("0 -15 0 0 0 0 0 0 0 4", At(303));
        Assert.Equal("0 90 0 0 0 0 0 0 0 17", At(316));
        Assert.Equal("1 20 1 0 0 0 0", At(317));                                       // H.1.a count 1 untouched
        Assert.Equal("2 20 4 0 0 0 0", At(319));                                       // H.2.a count 2, seg 3 -> 4
        Assert.Equal("20 6 0 0 0 0", At(320));
        Assert.Equal("2 20 1 1 2", At(325));                                           // H.6 count 2, segs 1,2 stay
        Assert.Equal("0", At(329));                                                    // H.10.a MCG unchanged

        // Exactly these original lines changed (independent Python oracle over the fixture).
        int[] expected = [7, 44, 46, 48, 50, 52, 54, 56, 58, 60, 62, 64, 66, 68, 70, .. Enumerable.Range(166, 10),
            .. Enumerable.Range(209, 87), .. Enumerable.Range(303, 14), 317, 319, 320, 325];
        var changed = Enumerable.Range(1, orig.Count).Where(i => T(orig[i - 1]) != before[i - 1]).ToArray();
        Assert.Equal(expected, changed);

        Assert.Equal(333, deck.Lines.Count);                                           // B.2.a+b, B.6, G.3.a
        Assert.Equal(18, deck.Cards("B.2.A").Count());
        Assert.Equal(18, deck.Cards("B.6").Count());
        Assert.Equal(18, deck.Cards("G.3.A").Count());
        Assert.Empty(deck.Validate());
    }

    [Fact]
    public void InsertBeforeSegment1_ShiftsEveryPositiveSegmentRef()
    {
        var deck = Deck.Load(Fixture);
        var orig = deck.Lines.ToList();
        Renumber.Insert(deck, Entity.Segment, 1, Renumber.Copy(deck, Entity.Segment, 1));
        string At(int line) => T(orig[line - 1]);

        Assert.Equal("18 16 \"\" 0", At(7));
        Assert.Equal("\"HNG\" 2 1 11 0 5 -11 0 0 0 0 0", At(40));
        Assert.Equal("\"NULL\" 0 0 0 0 0 0 0 0 0 0 0", At(42));                         // 0 is "none", not segment 0
        Assert.Equal("1 20 2 51 1 0 1 3 1 -1 0", At(209));
        Assert.Equal("6 3 4 4 10 0 11 3 13 1 0", At(232));
        Assert.Equal("0 4 0 4 4 4 3 4 4 4 3 2 3 1 2 3 1 1", At(248));
        Assert.Equal("2 59 4 4 10 0 11 3 13 0", At(249));
        Assert.Equal("0 0 0 0 0 0 0 0 0 0", At(300));
        Assert.Equal("0 0 0 0 0 0 0 0 0 2", At(301));
        Assert.Equal("2 20 2 2 3", At(325));
        Assert.Equal("9 0 0 9 0 0 0 0 0 0 0 0", At(129));
        Assert.Equal("\"RN\" 112 53.1 47.7 38.1 2 2 2 0 0 0 0", T(deck.Cards("B.2.A").First()));
        Assert.Empty(deck.Validate());
    }

    [Fact]
    public void InsertBeforePlane1_BumpsNplAndPlaneRefs()
    {
        var deck = Deck.Load(Fixture);
        var orig = deck.Lines.ToList();
        Renumber.Insert(deck, Entity.Plane, 1, Renumber.Copy(deck, Entity.Plane, 1));
        string At(int line) => T(orig[line - 1]);

        Assert.Equal("10 0 0 9 0 0 0 0 0 0 0 0", At(129));                             // NPL 9 -> 10
        Assert.Equal("17 16 \"\" 0", At(7));
        Assert.Equal("2 \"Floor\"", At(130));
        Assert.Equal("10 \"Wall bracket\"", At(162));
        Assert.Equal("0 5 5 5 5 3 5 5 5 1", At(208));
        Assert.Equal("2 19 1 50 1 0 1 3 1 -1 0", At(209));                             // seg refs untouched
        Assert.Equal("10 19 1 57 1 0 5 3 6 -2 1", At(247));
        Assert.Equal("1 \"Floor\"", T(deck.Cards("D.2.A").First()));
        Assert.Empty(deck.Validate());
    }

    [Fact]
    public void DeleteLastJoint_ThenReAdd_IsByteIdenticalOnDisk()
    {
        var deck = Deck.Load(Fixture);
        bool asked = false;
        var data = Renumber.Delete(deck, Entity.Joint, 16, _ => asked = true);
        Assert.NotNull(data);
        Assert.False(asked);                                                           // nothing refers to joint 16
        Assert.Equal("17 15 \"\" 0", T(deck.Card("B.1")!));
        Assert.Equal(Z(15), T(deck.Card("F.4.A")!));
        Assert.Equal(15, deck.Cards("B.3.A").Count());
        Assert.Equal(15, deck.Cards("B.4.A").Count());
        Assert.Equal(15, deck.Cards("B.5.A").Count());
        Assert.Equal(329 - 4, deck.Lines.Count);

        Renumber.Insert(deck, Entity.Joint, 16, data!);
        var tmp = Path.GetTempFileName();
        try { deck.Save(tmp); Assert.Equal(File.ReadAllBytes(Fixture), File.ReadAllBytes(tmp)); }
        finally { File.Delete(tmp); }
    }

    const string H7 = "0    Card H.7";
    const string H9 = "0    Card H.9";

    [Fact]
    public void DeleteMiddleJoint8_ConfirmGetsEveryReferencingLine()
    {
        var text = File.ReadAllText(Fixture).Replace(H7, "2    8    12    Card H.7").Replace(H9, "2    5    8    6    12    Card H.9");
        var deck = Deck.Parse(text);
        IReadOnlyList<RefSite>? got = null;
        Renumber.Delete(deck, Entity.Joint, 8, r => { got = r; return false; });
        Assert.Equal(["326 Card H.7", "328 Card H.9"], got!.Select(r => $"{r.Line} {r.Label}").ToArray());
    }

    [Fact]
    public void DeleteReferencedJoint_Declined_LeavesDeckUnchanged()
    {
        var text = File.ReadAllText(Fixture).Replace(H7, "1    8    Card H.7");   // one referencing line
        var deck = Deck.Parse(text);
        Renumber.Delete(deck, Entity.Joint, 8, _ => false);
        Assert.Equal(Deck.Parse(text).Write(), deck.Write());
    }

    [Fact]
    public void DeleteMiddleJoint8_Accepted_DropsEntriesShiftsHigherAndCounts()
    {
        var deck = WithLine(H7, "2    8    12    Card H.7");
        var h9 = deck.Lines.Single(l => l.Is("H.9"));
        h9.Tokens.Clear(); h9.Tokens.AddRange(["2", "5", "8", "6", "12"]);
        var data = Renumber.Delete(deck, Entity.Joint, 8, _ => true);
        Assert.NotNull(data);
        Assert.Equal("1 11", T(deck.Lines.Single(l => l.Is("H.7"))));
        Assert.Equal("1 6 11", T(deck.Lines.Single(l => l.Is("H.9"))));
        Assert.Equal("17 15 \"\" 0", T(deck.Card("B.1")!));
        Assert.DoesNotContain(deck.Cards("B.3.A"), l => l.Tokens[0] == "\"RK\"");
        Assert.Equal("\"RA\" 9 0 0.802995 -0.9686051 9.474138 1.422088 -0.210377 -1.699718 0 0 0", T(deck.Cards("B.3.A").ElementAt(7)));
        Assert.Equal("0 7 0 0.7 35 0 10 0 0.7 26", T(deck.Cards("B.4.A").ElementAt(7)));   // old joint 9's B.4.a
        Assert.Equal(Z(15), T(deck.Card("F.4.A")!));
        Assert.Equal(325, deck.Lines.Count);
        Assert.Empty(deck.Validate());
    }

    [Fact]
    public void DeleteSegment3_ListsReferencingCardsBeforeMutating()
    {
        var deck = Deck.Load(Fixture);
        var before = deck.Write();
        IReadOnlyList<RefSite>? got = null;
        Assert.Null(Renumber.Delete(deck, Entity.Segment, 3, r => { got = r; return false; }));
        var lines = got!.Select(r => $"{r.Line} {r.Label}").Distinct().ToList();
        Assert.Contains("44 CARD B.3.a", lines);
        Assert.Contains("52 CARD B.3.a", lines);
        Assert.Contains("217 CARD F.1.b", lines);
        Assert.Contains("253 CARD F.3.b", lines);
        Assert.Contains("303 CARD G.3.a", lines);
        Assert.Contains("319 Card H.2.a", lines);
        Assert.DoesNotContain("40 CARD B.3.a", lines);
        Assert.Equal(before, deck.Write());
    }

    // --- Delta (fix d2ff7e6): sign-carrying H fields. Fortran: H.1-H.8 Segment/Joint read as ABS(MSG)
    // (heding_hcards.for:103, heding_ang_displ.for:82, heding_wind.for:72, heding_jnt_parm.for:72);
    // KREF (Ref Segment) and H.9's joint (heding_joint_forces.for:51 JRF = MSG(II,9)) have no ABS.

    [Fact]
    public void InsertBeforeSegment3_NegativeH4Segment_ShiftsKeepingSign_NegativeRefSegmentUntouched()
    {
        var deck = WithLine("0    Card H.4", "2    -3    4    0    -5    Card H.4");   // pairs (Ref -3, Seg 4), (Ref 0, Seg -5)
        Renumber.Insert(deck, Entity.Segment, 3, Renumber.Copy(deck, Entity.Segment, 3));
        Assert.Equal("2 -3 5 0 -6", T(deck.Lines.Single(l => l.Is("H.4"))));
    }

    [Fact]
    public void InsertBeforeJoint3_NegativeH7JointShifts_NegativeH9JointUntouched()
    {
        var text = File.ReadAllText(Fixture).Replace(H7, "1    -8    Card H.7").Replace(H9, "1    0    -8    Card H.9");
        var deck = Deck.Parse(text);
        Renumber.Insert(deck, Entity.Joint, 3, Renumber.Copy(deck, Entity.Joint, 3));
        Assert.Equal("1 -9", T(deck.Lines.Single(l => l.Is("H.7"))));
        Assert.Equal("1 0 -8", T(deck.Lines.Single(l => l.Is("H.9"))));
    }

    // input_h1_h3_cards.for: .a = KSG KREF MSG X Y Z NODPR (always 7 values); KSG <= 1 -> one dummy .b; else KSG-1 .b rows.
    [Fact]
    public void DeleteSegment3_H1LoneNegativeRow_CountZeroRowAndDummyB_H2DropsToOne()
    {
        var deck = WithLine("1    19    1    0    0    0    0    Card H.1.a", "1    19    -3    0    0    0    0    Card H.1.a");
        Assert.NotNull(Renumber.Delete(deck, Entity.Segment, 3, _ => true));
        var h = deck.Lines.SkipWhile(l => !l.Is("H.1.A")).Take(7).ToList();
        Assert.Equal(["0 0 0 0 0 0 0", "0", "1 18 4 0 0 0 0", "0", "0 0 0 0 0 0 0", "0", "0"], h.Select(T));
        Assert.Equal(["Card H.1.a", "Card H.1.b", "Card H.2.a", "Card H.2.b", "CARD H.1.a", "Card H.3.b", "Card H.4"], h.Select(l => l.Label));
        Assert.Empty(deck.Validate());
    }

    [Fact]
    public void DeleteSegment3_H2FirstRowByRefSegment_Dropped_NextRowPromotedIntoA()
    {
        var text = File.ReadAllText(Fixture)
            .Replace("2    19    3    0    0    0    0    Card H.2.a", "3    3    1    0.5    0    0    0    Card H.2.a")
            .Replace("    19    5    0    0    0    0    Card H.2.b",
                     "    19    5    0    0    0    0    Card H.2.b\r\n    4    -7    1.5    0    0    2    Card H.2.b");
        var deck = Deck.Parse(text);
        Assert.Empty(deck.Validate());
        Assert.NotNull(Renumber.Delete(deck, Entity.Segment, 3, _ => true));
        var h = deck.Lines.SkipWhile(l => !l.Is("H.2.A")).Take(3).ToList();
        Assert.Equal(["2 18 4 0 0 0 0", "3 -6 1.5 0 0 2", "0 0 0 0 0 0 0"], h.Select(T));   // row (3,1) gone, count 3 -> 2
        Assert.Empty(deck.Validate());
    }
}
