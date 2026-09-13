using System.Globalization;
using System.Text;
using System.Text.RegularExpressions;
using Atb.Core.Cards;

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
    internal static readonly Regex LabelRx = new(@"(?i)(?:^|\s)(CARD\s+[A-Z0-9.]+)\s*$", RegexOptions.Compiled);

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

    /// Every labelled line checked against CardSchema: unknown labels and token counts that do
    /// not fit. Unlabelled lines (E.4 data, C.3 decelerations, ...) are skipped. Line is 1-based.
    // ponytail: per-line checks only — cross-card counts (e.g. D.7 total == B.1 Segments) are not checked.
    public List<DeckIssue> Validate()
    {
        var issues = new List<DeckIssue>();
        for (int i = 0; i < Lines.Count; i++)
        {
            var l = Lines[i];
            if (l.Card.Length == 0) continue;
            var reason = global::Atb.Core.Cards.CardSchema.Cards.TryGetValue(l.Card, out var spec)
                ? spec.Check(l.Tokens) : "no schema entry for this card";
            if (reason != null) issues.Add(new DeckIssue(i + 1, l.Card, reason));
            // Cross-card reads the solver does not guard (STANDARDS.md "Delete outcome matches the solver's read").
            if (l.Is("H.11") && l.Count > 0 && int.TryParse(l.Tokens[0], out var ksg) && ksg < 1
                && Card("D.1.B") is { Count: > 0 } b && int.TryParse(b.Tokens[0], out var nrtorq) && nrtorq > 0)
                issues.Add(new DeckIssue(i + 1, l.Card, "Count must be at least 1 while D.1.b has actuators (solver STOP 741, input_h11_cards.for:36-41)"));
            // F.9 segment/ellipsoid refs index SEG()/DELP()/BUOY() with no range check (water_force.for:73,110,117,128, output_water.for:84).
            if (l.Card.StartsWith("F.9.", StringComparison.Ordinal))
                for (int t = 0, skip = CardSchema.Skip(l.Card, l.Count); t < l.Count; t++)
                    if (CardSchema.KindOf(l.Card, t + skip) is Kind.SegRef or Kind.EllipRef && l.Tokens[t] == "0")
                        issues.Add(new DeckIssue(i + 1, l.Card, $"{CardSchema.Header(l.Card, t + skip)} is 0; the solver needs a real segment/ellipsoid"));
        }
        return issues;
    }

    /// Edit API: set token i of line from user text. Rewrites only that line (its Raw is dropped,
    /// every other line keeps its original text). Returns null on success, else why the text was
    /// refused (the line is left unchanged).
    public string? Edit(DeckLine line, int i, string text)
    {
        if (i < 0 || i >= line.Count) return $"{line.Label} has no field {i + 1}";
        var kind = CardSchema.KindOf(line.Card, i + CardSchema.Skip(line.Card, line.Count));
        var token = ToToken(kind, line.Tokens[i].StartsWith('"'), text, out var error);
        if (token == null) return error;
        if (token != line.Tokens[i]) line.Set(i, token);
        return null;
    }

    /// User text -> deck token for a field of the given kind (null kind: keep the old quoting).
    static string? ToToken(Kind? kind, bool quoted, string text, out string? error)
    {
        error = null;
        var v = text.Trim();
        if (kind == Kind.Str || (kind == null && quoted)) return "\"" + text.Replace('"', '\'') + "\"";
        bool whole = kind is Kind.Int or Kind.SegRef or Kind.JointRef or Kind.PlaneRef or Kind.FuncRef or Kind.EllipRef or Kind.ActRef;
        bool ok = whole ? int.TryParse(v, NumberStyles.Integer, CultureInfo.InvariantCulture, out _)
                        : double.TryParse(v.Replace('D', 'E').Replace('d', 'e'), NumberStyles.Float, CultureInfo.InvariantCulture, out _);
        if (ok) return v;
        error = $"'{text}' is not {(whole ? "a whole number" : "a number")}";
        return null;
    }

    /// Rows of a card group (CardSchema.Screen.Cards): each primary line plus the continuation
    /// lines that follow it, aligned to the group (null where a continuation line is absent).
    public List<DeckLine?[]> Rows(IReadOnlyList<string> group)
    {
        var rows = new List<DeckLine?[]>();
        for (int i = 0; i < Lines.Count; i++)
        {
            if (!Lines[i].Is(group[0])) continue;
            var row = new DeckLine?[group.Count];
            row[0] = Lines[i];
            for (int g = 1, j = i + 1; g < group.Count; g++)
                if (j < Lines.Count && Lines[j].Is(group[g])) row[g] = Lines[j++];
            rows.Add(row);
        }
        return rows;
    }

    /// Tab-separated paste text -> deck lines labelled with the group's cards, in deck order.
    /// Each row fills group[0], then each continuation card in turn (fixed cards take their field
    /// count, a variable last card takes the rest; an all-empty continuation block means that line
    /// is absent). A row whose tokens do not fit the schema is rejected whole.
    // ponytail: E.1 group rows skip E.3 only via empty cells; row-to-row counts (B.1, D.1.A) are not updated.
    public static PasteResult ParsePaste(string text, params string[] group)
    {
        var res = new PasteResult(new(), new());
        var rows = text.Replace("\r\n", "\n").Split('\n');
        for (int r = 0; r < rows.Length; r++)
        {
            if (rows[r].Trim().Length == 0) continue;
            var cells = rows[r].Split('\t');
            var lines = new List<DeckLine>();
            string? why = null;
            int pos = 0;
            for (int g = 0; g < group.Length && why == null; g++)
            {
                if (!CardSchema.Cards.TryGetValue(group[g], out var spec)) { why = $"no schema entry for {group[g]}"; break; }
                // fixed card: its field count; variable card (last in a group): every remaining cell
                var chunk = cells.Skip(pos).Take(spec.Fits == null ? spec.Names.Length : cells.Length).ToArray();
                pos += chunk.Length;
                if (g > 0 && chunk.All(c => c.Trim().Length == 0)) continue;       // continuation line absent
                var toks = new List<string>();
                int skip = CardSchema.Skip(spec.Label, chunk.Length);
                for (int i = 0; i < chunk.Length && why == null; i++)
                {
                    var t = ToToken(CardSchema.KindOf(spec.Label, i + skip), false, chunk[i], out var err);
                    if (t == null) why = $"{spec.Label} field {i + 1}: {err}"; else toks.Add(t);
                }
                why ??= spec.Check(toks);
                if (why == null) lines.Add(new DeckLine(toks, Labeler.LabelFor(spec.Label.ToUpperInvariant())));
            }
            if (why == null && cells.Skip(pos).Any(c => c.Trim().Length > 0))
                why = $"{cells.Length} cells, more than {string.Join(" + ", group)} holds";
            if (why == null) { res.Lines.AddRange(lines); res.Rows.Add(lines); } else res.Rejected.Add($"row {r + 1}: {why}");
        }
        return res;
    }

    /// Rows -> tab-separated text in the layout ParsePaste reads back (strings unquoted; an absent
    /// fixed continuation line becomes empty cells).
    public static string ToPasteText(IEnumerable<DeckLine?[]> rows, IReadOnlyList<string> group)
    {
        var sb = new StringBuilder();
        foreach (var row in rows)
        {
            var cells = new List<string>();
            for (int g = 0; g < group.Count; g++)
                if (row[g] is { } l) cells.AddRange(Enumerable.Range(0, l.Count).Select(l.Str));
                else if (CardSchema.Cards.TryGetValue(group[g], out var s) && s.Fits == null && g < group.Count - 1)
                    cells.AddRange(Enumerable.Repeat("", s.Names.Length));
            sb.Append(string.Join('\t', cells)).Append("\r\n");
        }
        return sb.ToString();
    }

    /// Names a reference column shows next to its number: segment n = n-th B.2.a, joint n = n-th
    /// B.3.a, plane/function by their ID field (E.1, then E.6.a, then E.7.a).
    // ponytail: one function namespace across E.1/E.6/E.7 (first match wins) — split per referring card if IDs collide.
    public Dictionary<(Kind, int), string> RefNames()
    {
        var d = new Dictionary<(Kind, int), string>();
        int n = 0;
        foreach (var l in Cards("B.2.A")) if (l.Count > 0) d[(Kind.SegRef, ++n)] = l.Str(0);
        n = 0;
        foreach (var l in Cards("B.3.A")) if (l.Count > 0) d[(Kind.JointRef, ++n)] = l.Str(0);
        void ById(Kind k, string card)
        {
            foreach (var l in Cards(card))
                if (l.Count > 1 && int.TryParse(l.Tokens[0], out var id)) d.TryAdd((k, id), l.Str(1));
        }
        ById(Kind.PlaneRef, "D.2.A"); ById(Kind.FuncRef, "E.1"); ById(Kind.FuncRef, "E.6.A"); ById(Kind.FuncRef, "E.7.A");
        return d;
    }
}

public sealed record DeckIssue(int Line, string Label, string Reason)
{
    /// One "line N (label): reason" row per issue, at most `max` rows plus a trailing "... and N more" row.
    public static List<string> Format(IReadOnlyList<DeckIssue> issues, int max = 20)
    {
        var rows = issues.Take(max).Select(i => $"line {i.Line} ({i.Label}): {i.Reason}").ToList();
        if (issues.Count > max) rows.Add($"... and {issues.Count - max} more");
        return rows;
    }
}

public sealed record PasteResult(List<DeckLine> Lines, List<string> Rejected)
{
    /// Accepted rows, one line list each (Lines flattened): entity screens insert them one entity per row.
    public List<List<DeckLine>> Rows { get; } = new();
}
