using Atb.Core.Cards;
using Atb.Core.Lin;
using Xunit;

namespace Atb.Core.Tests;

/// Round 1b renumbering gaps: paste on entity screens, H.11 actuators, F.2.B/F.6/F.9 marks, D.6 Type 5.
/// Expected lines are literals from cases/2479/2479_2.LIN (CRLF). No client deck carries D.6, F.10, H.11,
/// F.2, F.6 or F.9, so those cases splice schema-shaped labelled lines into 2479_2.LIN (Deck.Parse keeps labels).
public class RenumberGapTests
{
    static string Fixture => Path.Combine(Fixtures.RepoRoot, "cases", "2479", "2479_2.LIN");
    static string T(DeckLine l) => string.Join(" ", l.Tokens);
    static string[] All(Deck d, string card) => d.Cards(card).Select(T).ToArray();

    /// 2479_2.LIN with extra lines inserted before the (1-based) original line `before`, and optional line replacements.
    static Deck Spliced(Dictionary<int, string[]> insertBefore, Dictionary<int, string>? replace = null, string[]? append = null)
    {
        var src = File.ReadAllText(Fixture).Split("\r\n").ToList();
        Assert.Equal("", src[^1]);
        src.RemoveAt(src.Count - 1);
        var outp = new List<string>();
        for (int i = 0; i < src.Count; i++)
        {
            if (insertBefore.TryGetValue(i + 1, out var ins)) outp.AddRange(ins);
            outp.Add(replace != null && replace.TryGetValue(i + 1, out var r) ? r : src[i]);
        }
        if (append != null) outp.AddRange(append);
        return Deck.Parse(string.Join("\r\n", outp) + "\r\n");
    }

    // --- (2) paste ---

    [Fact]
    public void PasteTwoSegmentRowsBeforeSegment3_ShiftsRefsBy2_GrowsB1_Validates()
    {
        var deck = Deck.Load(Fixture);
        var cards = new[] { "B.2.A", "B.2.B" };
        const string text = "RN\t112\t53.1\t47.7\t38.1\t2\t2\t2\t0\t0\t0\t0\r\n"
                          + "NEW\t30.86138\t1.4\t1.3\t2.1\t5.3\t8.0\t4.9\t0.35\t0\t1.99\t1\t0\t0\t0\r\n"
                          + "BAD\t1\t2\r\n";
        var res = Deck.ParsePaste(text, cards);
        Assert.Equal(["row 3: expected 12 tokens, found 3"], res.Rejected);   // token-count rejection kept
        Assert.Equal(2, res.Rows.Count);

        var skipped = Renumber.Paste(deck, Entity.Segment, cards, 3, 2, res.Rows);   // MainForm.PasteRows' call

        Assert.Empty(skipped);
        Assert.Equal("19 16 \"\" 0", T(deck.Card("B.1")!));
        Assert.Equal(["\"RN\"", "\"DR\"", "\"RN\"", "\"NEW\"", "\"LT \"", "\"CT \""], deck.Cards("B.2.A").Take(6).Select(l => l.Tokens[0]));
        Assert.Equal(19, deck.Cards("B.2.A").Count());
        Assert.Equal(19, deck.Cards("B.6").Count());
        Assert.Equal(19, deck.Cards("G.3.A").Count());
        var b3 = All(deck, "B.3.A");
        Assert.Contains("\"P \" 5 0 -2.835566 0 -1.744625 -3.676071 0 2.067626 0 0 0", b3);       // was 3
        Assert.Contains("\"RK\" 10 1 1.032551 0.524969 9.106875 0.6786411 -0.493778 -6.133165 0 0 0", b3);   // was 8
        var d5 = All(deck, "D.5");
        Assert.Equal("52 13 15 17 0 0 -1 0 0 0 20 20 20", d5[0]);                                // ellipsoid 50
        Assert.Equal("60 0.75 15 0.75 12.25 0 -12.75 0 0 0 2 2 2", d5[^1]);                      // ellipsoid 58
        var f1b = All(deck, "F.1.B");
        Assert.Equal("1 21 1 52 1 0 1 3 1 -1 0", f1b[0]);                                        // 19->21, 50->52, func 3 kept
        Assert.Equal("1 21 2 53 1 0 1 3 1 -1 0", f1b[2]);                                        // seg 2 < 3 kept, ellip 51 -> 53
        Assert.Equal("2 21 5 5 10 0 11 3 12 -2 0", f1b[8]);                                      // was 2 19 3 3
        Assert.Equal(19, deck.Cards("D.7").Sum(l => l.Count));
        Assert.Empty(deck.Validate());
        Assert.Empty(Deck.Parse(deck.Write()).Validate());
    }

    // --- (3) H.11 actuators ---

    static readonly Dictionary<int, string> WithActuators = new() { [129] = "9    0    0    9    0    0    0    0    0    0    0    1    CARD D.1.a" };

    static Deck ActuatorDeck(int nrtorq, string[] f10, string h11) => Spliced(
        new() { [130] = [$"{nrtorq}    CARD D.1.b"], [297] = f10.Select(r => r + "    CARD F.10").ToArray() },
        WithActuators, [h11 + "    CARD H.11"]);

    static readonly string[] ThreeActuators = ["5    3    1    1    1    1", "6    2    1    1    1    1", "7    2    1    1    1    1"];

    [Fact]
    public void DeleteActuator2_DropsItFromH11_ShiftsLater_UpdatesCount()
    {
        var deck = ActuatorDeck(3, ThreeActuators, "3    1    -3    2");
        Assert.Empty(deck.Validate());

        Assert.NotNull(Renumber.Delete(deck, Entity.Actuator, 2, _ => true));

        Assert.Equal(["2 1 -2"], All(deck, "H.11"));                                             // 2 dropped, -3 -> -2 (sign kept)
        Assert.Equal(["2"], All(deck, "D.1.B"));
        Assert.Equal(["5 3 1 1 1 1", "7 2 1 1 1 1"], All(deck, "F.10"));
        Assert.Empty(deck.Validate());
    }

    [Fact]
    public void DeleteJoint5_CascadesItsF10Row_H11Follows()
    {
        var deck = ActuatorDeck(3, ThreeActuators, "3    1    -3    2");

        Assert.NotNull(Renumber.Delete(deck, Entity.Joint, 5, _ => true));

        Assert.Equal(["5 2 1 1 1 1", "6 2 1 1 1 1"], All(deck, "F.10"));                         // actuator 1 cascaded, joints 6,7 -> 5,6
        Assert.Equal(["2 -2 1"], All(deck, "H.11"));                                             // 1 dropped, -3 -> -2, 2 -> 1
        Assert.Equal(["2"], All(deck, "D.1.B"));
        Assert.Empty(deck.Validate());
    }

    [Fact]
    public void DeleteLastActuator_RemovesH11Line()
    {
        var deck = ActuatorDeck(1, ["5    3    1    1    1    1"], "1    1");

        Assert.NotNull(Renumber.Delete(deck, Entity.Actuator, 1, _ => true));

        Assert.Empty(All(deck, "F.10"));
        Assert.Equal(["0"], All(deck, "D.1.B"));
        Assert.Empty(All(deck, "H.11"));
    }

    [Fact]
    public void InsertActuatorAt1_ShiftsH11_GrowsNrtorq()
    {
        var deck = ActuatorDeck(3, ThreeActuators, "3    1    -3    2");

        Renumber.Insert(deck, Entity.Actuator, 1, Renumber.Copy(deck, Entity.Actuator, 3));

        Assert.Equal(["3 2 -4 3"], All(deck, "H.11"));
        Assert.Equal(["4"], All(deck, "D.1.B"));
        Assert.Equal(["7 2 1 1 1 1", "5 3 1 1 1 1", "6 2 1 1 1 1", "7 2 1 1 1 1"], All(deck, "F.10"));
    }

    // --- (4) F.2.B / F.6 / F.9 marks ---

    static Deck MarksDeck() => Spliced(new()
    {
        [297] =
        [
            "2    CARD F.2.a",
            "1    3    5    55    1    2    3    0    0    CARD F.2.b",
            "1    2    2    2    3    3    3    0    1    CARD F.2.b",
            "1    2    3    53    1    50    CARD F.6",
            "53    3    1    1    0    0    0    0    0    0    CARD F.9.f",
            "3    53    0    0    3    51    CARD F.9.g",
            "1    0    0    3    3    CARD F.9.i",
            "3    0    0    0    0    0    3    CARD F.9.j1",
            "53    CARD F.9.m",
        ],
    });

    [Fact]
    public void InsertSegmentBefore3_ShiftsF2bF6F9Refs_LeavesUnmarkedAlone()
    {
        var deck = MarksDeck();
        Assert.Empty(deck.Validate());

        Renumber.Insert(deck, Entity.Segment, 3, Renumber.Copy(deck, Entity.Segment, 3));

        Assert.Equal(["2"], All(deck, "F.2.A"));
        Assert.Equal(["1 4 6 56 1 2 3 0 0", "1 2 2 2 3 3 3 0 1"], All(deck, "F.2.B"));          // belt no. and funcs 3 kept
        Assert.Equal(["1 2 4 54 1 51"], All(deck, "F.6"));                                        // airbag no. 1 and count 2 kept
        Assert.Equal(["54 4 1 1 0 0 0 0 0 0"], All(deck, "F.9.F"));
        Assert.Equal(["4 54 0 0 3 52"], All(deck, "F.9.G"));                                     // real offset 3 kept
        Assert.Equal(["1 0 0 3 4"], All(deck, "F.9.I"));                                         // PFDWT(4) real 3 kept
        Assert.Equal(["4 0 0 0 0 0 3"], All(deck, "F.9.J1"));
        Assert.Equal(["54"], All(deck, "F.9.M"));
    }

    [Fact]
    public void DeleteSegment3_DropsF2bRowAndF6Pair_ClearsF9Refs()
    {
        var deck = MarksDeck();

        Assert.NotNull(Renumber.Delete(deck, Entity.Segment, 3, _ => true));

        Assert.Equal(["1"], All(deck, "F.2.A"));                                                  // belt 1 lost its seg-3 row
        Assert.Equal(["1 2 2 2 3 3 3 0 1"], All(deck, "F.2.B"));
        Assert.Equal(["1 1 1 49"], All(deck, "F.6"));                                             // (3,53) pair dropped, NK 2 -> 1
        Assert.Equal(["52 0 1 1 0 0 0 0 0 0"], All(deck, "F.9.F"));                              // delCascade false: 0, >3 down
        Assert.Equal(["0 52 0 0 3 50"], All(deck, "F.9.G"));
        Assert.Equal(["1 0 0 3 0"], All(deck, "F.9.I"));
        Assert.Equal(["0 0 0 0 0 0 3"], All(deck, "F.9.J1"));
        Assert.Equal(["52"], All(deck, "F.9.M"));
        // The zeroed refs would index SEG(0) (water_force.for:73,110,117,128), so Validate blocks Save/Run.
        Assert.Equal(["F.9.F Contact SegID", "F.9.G Mouth SegID", "F.9.I Ref SegID", "F.9.J1 PFD SegID"],
            deck.Validate().Select(i => i.Label + " " + i.Reason.Split(" is 0")[0]));
    }

    [Fact]
    public void DeleteSegment3_ZeroedF9EllipRef_ValidateFlags()
    {
        var deck = Spliced(new() { [297] = ["3    CARD F.9.m"] });
        Assert.Empty(deck.Validate());

        Assert.NotNull(Renumber.Delete(deck, Entity.Segment, 3, _ => true));

        Assert.Equal(["0"], All(deck, "F.9.M"));
        var issue = Assert.Single(deck.Validate());
        Assert.Equal("F.9.M", issue.Label);
        Assert.Equal("EllipID is 0; the solver needs a real segment/ellipsoid", issue.Reason);
    }

    // --- review: H.11 emptied while actuators remain (input_h11_cards.for:36-41 STOP 741) ---

    [Fact]
    public void DeleteActuator2_WhenH11ListsOnlyIt_ConfirmWarns_ValidateFlags()
    {
        var deck = ActuatorDeck(3, ThreeActuators, "1    2");
        Assert.Empty(deck.Validate());
        IReadOnlyList<RefSite>? seen = null;

        Assert.NotNull(Renumber.Delete(deck, Entity.Actuator, 2, r => { seen = r; return true; }));

        Assert.Contains(seen!, s => s.Label == "H.11" && s.Field.Contains("STOP 741"));
        Assert.Equal(["0"], All(deck, "H.11"));
        Assert.Equal(["2"], All(deck, "D.1.B"));
        var issue = Assert.Single(deck.Validate(), i => i.Label == "H.11");
        Assert.Contains("STOP 741", issue.Reason);
    }

    [Fact]
    public void DeleteJoint5_CascadedActuatorEmptiesH11_ConfirmWarns_CancelLeavesDeck()
    {
        var deck = ActuatorDeck(3, ThreeActuators, "1    1");
        var before = deck.Write();
        IReadOnlyList<RefSite>? seen = null;

        Assert.Null(Renumber.Delete(deck, Entity.Joint, 5, r => { seen = r; return false; }));

        Assert.Contains(seen!, s => s.Label == "H.11" && s.Field.Contains("STOP 741"));
        Assert.Equal(before, deck.Write());
    }

    [Fact]
    public void DeleteActuator2_H11KeepsAnotherEntry_NoWarning()
    {
        var deck = ActuatorDeck(3, ThreeActuators, "2    1    2");
        IReadOnlyList<RefSite>? seen = null;

        Assert.NotNull(Renumber.Delete(deck, Entity.Actuator, 2, r => { seen = r; return true; }));

        Assert.DoesNotContain(seen!, s => s.Field.Contains("STOP 741"));
        Assert.Empty(deck.Validate());
    }

    // --- review: joint paste keeps the template's spin class (Labeler.cs:61,66) ---

    [Fact]
    public void PasteSpinJointRow_OnNonSpinTemplate_IsRejected_DeckUnchanged()
    {
        var deck = Deck.Load(Fixture);
        var before = deck.Write();
        var cards = new[] { "B.3.A", "B.3.B", "B.3.C" };
        // Joint Type 4 -> JointType "304": a spin joint; template joint 2 ("NULL") has Joint Type 0.
        const string text = "PX\t3\t4\t-2.835566\t0\t-1.744625\t-3.676071\t0\t2.067626\t0\t0\t0\t0\t0\t0\t0\t5\t0\t0\t0\t0\t0\t0\t0\t0\t0\t0\r\n";
        var res = Deck.ParsePaste(text, cards);
        Assert.Single(res.Rows);

        Assert.Equal(["row 1: Joint Type needs different B.4/B.5 lines than joint 2"], Renumber.Paste(deck, Entity.Joint, cards, 3, 2, res.Rows));
        Assert.Equal(before, deck.Write());
    }

    // --- (5) D.6 Type 5 ---

    static Deck Type5Deck() => Spliced(
        new() { [175] = ["5    3    4    0    0    0    0    0    0    CARD D.6", "1    1    2    0    0    0    0    0    0"] },
        new() { [129] = "9    0    0    9    2    0    0    0    0    0    0    0    CARD D.1.a" });

    [Fact]
    public void DeleteType5Constraint_RemovesExactlyOneLine()
    {
        var deck = Type5Deck();
        int at = deck.Lines.FindIndex(l => l.Is("D.6"));
        var next = deck.Lines[at + 1];                                                           // the second constraint, unlabelled

        Assert.NotNull(Renumber.Delete(deck, Entity.Segment, 3, _ => true));

        Assert.Empty(All(deck, "D.6"));
        Assert.Contains(next, deck.Lines);
        Assert.Equal("1 1 2 0 0 0 0 0 0", T(next));
        Assert.Equal("9 0 0 9 1 0 0 0 0 0 0 0", T(deck.Card("D.1.A")!));
    }

    [Fact]
    public void Labeler_Type5Constraint_IsOneLine_NextLineIsTheNextD6()
    {
        var deck = Type5Deck();
        var grammar = Labeler.Label(deck);
        int at = deck.Lines.FindIndex(l => l.Is("D.6"));
        Assert.Equal("D.6", grammar[at + 1]);
        Assert.Equal("D.7", grammar[at + 2]);
    }
}
