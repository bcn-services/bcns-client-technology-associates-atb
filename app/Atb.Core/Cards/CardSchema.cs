namespace Atb.Core.Cards;

/// Field names per CARD label, in token order. Seed set verified against the client decks and
/// the ATB 3I column titles; LANE item "Card schema" completes it from the user guide.
public static class CardSchema
{
    public static readonly Dictionary<string, string[]> Fields = new(StringComparer.OrdinalIgnoreCase)
    {
        ["A.1.A"] = ["Date"],
        ["A.1.B"] = ["Comment 1"],
        ["A.1.C"] = ["Comment 2"],
        ["A.3"]   = ["Unit of Length", "Unit of Force", "Unit of Time", "Gravity X", "Gravity Y", "Gravity Z", "G"],
        ["A.4"]   = ["Num of Iteration", "Num of Output", "Output Interval", "Initial Size", "Maximum Size", "Minimum Size"],
        ["B.1"]   = ["Segments", "Joints", "Body Name", "Symmetry"],
        ["B.2.A"] = ["Name", "Weight", "Ixx", "Iyy", "Izz", "Ellip Semi - X", "Ellip Semi - Y", "Ellip Semi - Z",
                     "Ellip Center - X", "Ellip Center - Y", "Ellip Center - Z", "Define Rotation"],
        ["B.2.B"] = ["Principal Yaw", "Principal Pitch", "Principal Roll"],
        ["D.2"]   = ["Title", "Point1 - X", "Point1 - Y", "Point1 - Z", "Point2 - X", "Point2 - Y", "Point2 - Z",
                     "Point3 - X", "Point3 - Y", "Point3 - Z"],
        ["D.5"]   = ["Ellip Semi - X", "Ellip Semi - Y", "Ellip Semi - Z", "Ellip Center - X", "Ellip Center - Y", "Ellip Center - Z",
                     "Ellip Yaw", "Ellip Pitch", "Ellip Roll", "Ellip Power - X", "Ellip Power - Y", "Ellip Power - Z"],
        ["G.2"]   = ["Ref Seg Position - X", "Ref Seg Position - Y", "Ref Seg Position - Z",
                     "Ref Seg Velocity - X", "Ref Seg Velocity - Y", "Ref Seg Velocity - Z", "SegID - Velocity Based On", "SegID - Position Given In"],
    };

    /// Header for token i of a card: schema name, else "Value i+1".
    public static string Header(string card, int i) =>
        Fields.TryGetValue(card, out var f) && i < f.Length ? f[i] : $"Value {i + 1}";
}
