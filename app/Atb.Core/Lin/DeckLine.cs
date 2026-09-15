using System.Globalization;

namespace Atb.Core.Lin;

/// One physical line of a free-format (.LIN) ATB deck: whitespace-separated tokens plus an
/// optional trailing "CARD x.y" label. Quoted strings stay quoted inside Tokens so that a
/// deck writes back exactly as read; use Str/SetStr for the unquoted value.
public sealed class DeckLine
{
    public List<string> Tokens { get; }
    public string Label { get; set; }          // e.g. "CARD B.2.a" (verbatim case) or ""
    public string? Raw { get; private set; }   // original text while untouched; null once edited

    public DeckLine(IEnumerable<string> tokens, string label = "", string? raw = null)
    {
        Tokens = tokens.ToList();
        Label = label;
        Raw = raw;
    }

    /// Card id without the "CARD " prefix, upper-cased: "B.2.A". Empty for unlabeled lines.
    public string Card => Label.Length > 5 ? Label[5..].ToUpperInvariant() : "";

    public bool Is(string card) => string.Equals(Card, card, StringComparison.OrdinalIgnoreCase);

    public int Count => Tokens.Count;

    public string Str(int i)
    {
        var t = Tokens[i];
        return t.Length >= 2 && t[0] == '"' && t[^1] == '"' ? t[1..^1] : t;
    }

    public double Num(int i) => ParseNum(Tokens[i]);

    public int Int(int i) => (int)Math.Round(Num(i));

    public void Set(int i, string rawToken) { Tokens[i] = rawToken; Raw = null; }
    /// Labeler hook: new label plus the text to write back (null = regenerate from tokens).
    internal void Relabel(string label, string? raw) { Label = label; Raw = raw; }
    /// Renumber hook: replace every token; the line is regenerated only if a token actually changed.
    internal void SetTokens(IReadOnlyList<string> toks)
    {
        if (toks.SequenceEqual(Tokens)) return;
        Tokens.Clear(); Tokens.AddRange(toks); Raw = null;
    }
    public void SetStr(int i, string s) => Set(i, "\"" + s + "\"");
    public void SetNum(int i, double v) => Set(i, FormatNum(v));
    public void SetInt(int i, int v) => Set(i, v.ToString(CultureInfo.InvariantCulture));

    /// Fortran list-directed numerics: accepts D exponents ("1.5D-3") as well as E.
    public static double ParseNum(string t)
    {
        var s = t.Trim().Replace('D', 'E').Replace('d', 'e');
        return double.Parse(s, NumberStyles.Float, CultureInfo.InvariantCulture);
    }

    public static string FormatNum(double v) => v.ToString("R", CultureInfo.InvariantCulture);

    public override string ToString() => string.Join(" ", Tokens) + (Label.Length > 0 ? "  " + Label : "");
}
