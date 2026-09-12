using System.Text;
using System.Text.RegularExpressions;

namespace Atb.Core.Lin;

/// A free-format ATB input deck (.LIN) as an ordered list of lines. Untouched lines write back
/// byte-for-byte; edited lines are regenerated in ATB 3I's own layout (4-space joiner, trailing
/// CARD label), so a deck written by ATB 3I survives open -> edit -> save with a minimal diff.
public sealed class Deck
{
    public List<DeckLine> Lines { get; } = new();
    public string? Path { get; set; }

    static readonly Regex TokenRx = new("\"[^\"]*\"|\\S+", RegexOptions.Compiled);
    // Label = the last "CARD x.y" run on the line, any case, preceded by start-of-line or whitespace.
    static readonly Regex LabelRx = new(@"(?i)(?:^|\s)(CARD\s+[A-Z0-9.]+)\s*$", RegexOptions.Compiled);

    public static Deck Load(string path)
    {
        var d = Parse(File.ReadAllText(path, Encoding.Latin1));
        d.Path = path;
        return d;
    }

    public static Deck Parse(string text)
    {
        var d = new Deck();
        var lines = text.Split('\n');
        int n = lines.Length;
        if (n > 0 && lines[n - 1].Length == 0) n--;          // trailing newline
        for (int i = 0; i < n; i++)
        {
            var raw = lines[i].TrimEnd('\r');
            var m = LabelRx.Match(raw);
            string label = "", body = raw;
            if (m.Success) { label = Regex.Replace(m.Groups[1].Value, @"\s+", " "); body = raw[..m.Groups[1].Index]; }
            var toks = TokenRx.Matches(body).Select(x => x.Value);
            d.Lines.Add(new DeckLine(toks, label, raw));
        }
        return d;
    }

    public void Save(string path)
    {
        File.WriteAllText(path, Write(), Encoding.Latin1);
        Path = path;
    }

    /// canonical=true ignores preserved raw text and regenerates every line (used by tests to
    /// prove the writer matches ATB 3I's layout).
    public string Write(bool canonical = false)
    {
        var sb = new StringBuilder();
        string prevCard = "";
        foreach (var l in Lines)
        {
            sb.Append(!canonical && l.Raw != null ? l.Raw : Format(l, prevCard)).Append("\r\n");
            prevCard = l.Card;
        }
        return sb.ToString();
    }

    const string Sep = "    ";

    // Layout rules recovered from ATB 3I FileManager.WriteFile (verified byte-exact on the
    // 12 client decks). Two quirks: B.1 gets a 5-space gap before its label; the H.1-H.3
    // output-selection cards indent their continuation rows ("H.n.b" rows and 2nd+ "H.n.a" rows).
    static string Format(DeckLine l, string prevCard)
    {
        var card = l.Card;
        var body = string.Join(Sep, l.Tokens);
        bool indent = card is "H.1.B" or "H.2.B" or "H.3.B" || (card is "H.1.A" or "H.2.A" or "H.3.A" && card == prevCard);
        var gap = card == "B.1" ? "     " : Sep;
        return (indent ? Sep : "") + body + gap + l.Label;
    }

    /// All lines carrying the given card id (e.g. "B.2.a"), in deck order.
    public IEnumerable<DeckLine> Cards(string card) => Lines.Where(l => l.Is(card));

    public DeckLine? Card(string card) => Lines.FirstOrDefault(l => l.Is(card));

    /// Structural summary straight from the header cards.
    public string Title => Card("A.1.b")?.Str(0) ?? "";
    public int SegmentCount => Card("B.1")?.Int(0) ?? 0;
    public int JointCount => Card("B.1")?.Int(1) ?? 0;
}
