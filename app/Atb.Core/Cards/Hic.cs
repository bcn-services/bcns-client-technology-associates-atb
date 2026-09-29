// Output > HIC...: ATB 3I's "HIC and CSI Definition" (decomp HIC.cs): a Span box over [H12a1] and a grid over [H12a2]
// (BodyID, HIC Source, CSI Source; MainMenu.cs:3701-3716, ORDER BY BodyID, both sources drop-down type 11 = the H.1 rows by RID,
// ATB3I.Util/DropDownList.cs:102-103). Deck side, as 3I writes it (FileManager.cs:2234-2248): NHIC, Span, then BodyID HIC CSI
// per set on one line — "CARD H.12" when [H12a2] has sets, 3I's default "Card H.12.a" line otherwise.
// Menu enablement is OutputControl.HicEnabled (the one NPRT(4) test).
using Atb.Core.Lin;

namespace Atb.Core.Cards;

public static class Hic
{
    public static readonly string[] Columns = ["BodyID", "HIC Source", "CSI Source"];

    public static bool IsHead(DeckLine l) => l.Is("H.12.A") || l.Is("H.12");
    public static bool IsLine(DeckLine l) => IsHead(l) || l.Is("H.12.B");

    public static DeckLine Head(Deck d) => d.Lines.FirstOrDefault(IsHead)
        ?? throw new InvalidOperationException("The deck has no H.12 card: set Unit 8 (HIC) Output (NPRT 4) to a value other than 0 or 4");

    public static string Span(Deck d) => Head(d).Str(1);

    /// Deck.Edit on the Span token (only it, nothing when unchanged). Null, or why the text was refused.
    public static string? SetSpan(Deck d, string text) => d.Edit(Head(d), 1, text);

    /// One (line, first token) per HIC set: the head line's triples after NHIC and Span, then each H.12.B line.
    // ponytail: H.12.B lines are Labeler's unverified multi-HIC guess (Labeler.cs:177); 3I writes every set on the head line
    // and its own reader takes only one (FileManager.cs:1033). No deck has NHIC > 1 — revisit when one turns up.
    public static List<(DeckLine Line, int At)> Rows(Deck d)
    {
        var h = Head(d);
        var rows = new List<(DeckLine, int)>();
        for (int t = 2; t + 2 < h.Count; t += 3) rows.Add((h, t));
        foreach (var b in d.Cards("H.12.B")) if (b.Count >= 3) rows.Add((b, 0));
        return rows;
    }

    public static string Cell(Deck d, int row, int col)
    {
        var (l, at) = Rows(d)[row];
        return l.Str(at + col);
    }

    public static string? Set(Deck d, int row, int col, string text)
    {
        var (l, at) = Rows(d)[row];
        return d.Edit(l, at + col, text);
    }

    /// Drop-down values for HIC/CSI Source: the H.1 rows 1..N (H.1.a's count), plus any value the deck already holds
    /// (3I's default line has 0) so the cell can show it.
    public static List<string> Choices(Deck d)
    {
        int n = d.Card("H.1.A") is { Count: > 0 } h1 ? h1.Int(0) : 0;
        var held = Rows(d).SelectMany(r => new[] { r.Line.Str(r.At + 1), r.Line.Str(r.At + 2) });
        return Enumerable.Range(1, Math.Max(n, 0)).Select(i => i.ToString()).Union(held)
            .OrderBy(v => double.TryParse(v, System.Globalization.CultureInfo.InvariantCulture, out var x) ? x : double.MaxValue).ToList();
    }
}
