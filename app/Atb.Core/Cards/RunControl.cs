// Analysis > Run Control...: ATB 3I's "Run Time Control Parameter Definition" (decomp ATB3I/RunControl.cs). Its 16 boxes
// are one UpdateRec("A1A3A4") row (:1867); here each box is one deck token on A.1.A / A.1.B / A.1.C / A.3 / A.4.
using System.Globalization;
using Atb.Core.Lin;

namespace Atb.Core.Cards;

public static class RunControl
{
    /// One 3I box: its 3I field name, the card and token it holds, and whether 3I's TextBox_Leave number check applies.
    public sealed record Field(string Name, string Card, int Token, bool Number);

    /// 3I's Textbox1..Textbox16, in that order (RunControl_Load :1812-1827).
    public static readonly Field[] Fields =
    [
        new("Date", "A.1.A", 0, false), new("Comment1", "A.1.B", 0, false), new("Comment2", "A.1.C", 0, false),
        new("Unit of Length", "A.3", 0, false), new("Unit of Force", "A.3", 1, false), new("Unit of Time", "A.3", 2, false),
        new("Num of Iteration", "A.4", 0, true), new("Num of Output", "A.4", 1, true), new("Output Interval", "A.4", 2, true),
        new("Gravity X", "A.3", 3, true), new("Gravity Y", "A.3", 4, true), new("Gravity Z", "A.3", 5, true),
        new("Initial Size", "A.4", 3, true), new("Maximum Size", "A.4", 4, true), new("Minimum Size", "A.4", 5, true),
        new("G", "A.3", 6, true),
    ];

    public static DeckLine Line(Deck d, int field) =>
        d.Card(Fields[field].Card) ?? throw new InvalidOperationException($"The deck has no {Fields[field].Card} card");

    /// The 16 box texts (quotes stripped from the string cards).
    public static string[] Read(Deck d) => Fields.Select((f, i) => Line(d, i).Str(f.Token)).ToArray();

    /// Writes one box into its token (Deck.Edit: only that line changes, and not at all when the token is the same).
    /// Returns null, or why the text was refused.
    public static string? Set(Deck d, int field, string text) => d.Edit(Line(d, field), Fields[field].Token, text);

    /// 3I's Default button (btnDefault_Click :1873-1890); the date is VB's DateAndTime.DateString, MM-dd-yyyy.
    public static string[] Defaults(DateTime today) =>
    [
        today.ToString("MM-dd-yyyy", CultureInfo.InvariantCulture), "", "", "IN.", "LB.", "SEC.",
        "4", "0", "0.002", "0", "0", "386.088", "0.0005", "0.001", "0.0000625", "0",
    ];
}
