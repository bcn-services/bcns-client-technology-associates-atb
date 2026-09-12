using System.Globalization;
using Atb.Core.Lin;

namespace Atb.Core.Cards;

public enum Entity { Segment, Joint, Plane, Vehicle }

/// One field that refers to an entity: 1-based deck line, that line's label, the schema field name.
public sealed record RefSite(int Line, string Label, string Field);

/// An entity's own lines and its per-entity list values (D.7, F.3.A, ...), as Delete took them out
/// or Copy made them. Insert puts exactly these lines back, so Delete then Insert is lossless.
public sealed class EntityData
{
    internal List<List<DeckLine>> Groups { get; } = new();   // one per owned group, in Groups(e) order
    internal List<string> Values { get; } = new();           // one per Lists(e) card
}

/// Insert or delete a segment, joint, plane or vehicle and renumber every reference to it, using
/// the reference kinds marked in CardSchema (an unmarked field is never touched). Behaviour copies
/// ATB 3I ATBUpdate.UpdateSegmentID / UpdateJointID / UpdatePlaneID (decomp ATB3I.Util/ATBUpdate.cs):
/// insert shifts refs >= n up by one; delete removes rows of the cascade cards that refer to n,
/// clears the other refs to n, and shifts refs > n down by one. Count cards follow by exactly one.
public static class Renumber
{
    static string[][] Groups(Entity e) => e switch
    {
        Entity.Segment => [["B.2.A", "B.2.B"], ["B.6"], ["G.3.A"]],
        Entity.Joint => [["B.3.A", "B.3.B", "B.3.C"], ["B.4.A", "B.4.B"], ["B.5.A", "B.5.B", "B.5.C"]],
        Entity.Plane => [["D.2.A", "D.2.B", "D.2.C", "D.2.D"]],
        _ => [["C.1"]],                                       // a vehicle is its whole C.1..C.5 block
    };

    /// Cards holding one value per entity, 18 to a line.
    static string[] Lists(Entity e) => e switch
    {
        Entity.Segment => ["D.7", "F.3.A", "F.7.A"],
        Entity.Joint => ["F.4.A"],
        Entity.Plane => ["F.1.A"],
        _ => [],
    };

    // Ellipsoid numbers share the segment numbering, and a vehicle is a segment numbered after the body's.
    static Kind[] Kinds(Entity e) => e switch
    {
        Entity.Joint => [Kind.JointRef],
        Entity.Plane => [Kind.PlaneRef],
        _ => [Kind.SegRef, Kind.EllipRef],
    };

    static string Owner(Entity e) => e switch { Entity.Segment => "B.2.A", Entity.Joint => "B.3.A", Entity.Plane => "D.2.A", _ => "C.1" };

    /// Rows ATB 3I deletes with the entity (delCascade = true) and the count each one is tallied in.
    /// Index -1: the count is a list value, indexed by the row's first field (F.1.B Plane, F.3.B Segment A, F.4.B Joint).
    static Dictionary<string, (string Card, int Index)> Cascade(Entity e) => e switch
    {
        Entity.Joint => new() { ["F.10"] = ("D.1.B", 0), ["F.4.B"] = ("F.4.A", -1) },
        Entity.Plane => new() { ["F.1.B"] = ("F.1.A", -1) },
        _ => new()
        {
            ["D.5"] = ("D.1.A", 3), ["D.6"] = ("D.1.A", 4), ["D.8"] = ("D.1.A", 5), ["D.9"] = ("D.1.A", 9),
            ["F.1.B"] = ("F.1.A", -1), ["F.3.B"] = ("F.3.A", -1), ["F.10"] = ("D.1.B", 0),
        },
    };

    /// Output lists whose entries are removed (and the leading count dropped) instead of cleared: key = index of the count.
    /// H.1-H.3 rows span lines and are reflowed by DropH13Rows instead.
    static readonly Dictionary<string, int> CountLed = new(StringComparer.OrdinalIgnoreCase)
    { ["H.4"] = 0, ["H.5"] = 0, ["H.6"] = 0, ["H.7"] = 0, ["H.8"] = 0, ["H.9"] = 0, ["H.10.B"] = 1 };

    // ATB 3I noDataMark for the non-cascade tables: B3B4B5M and C1C2a use -1, the others 0.
    static string Blank(string card) => card is "B.3.A" or "C.2.A" ? "-1" : "0";

    public static int Count(Deck d, Entity e) => d.Cards(Owner(e)).Count();

    /// Every field outside the entity's own lines that refers to entity n.
    public static List<RefSite> References(Deck d, Entity e, int n)
    {
        Check(d, e, n, insert: false);
        var own = Owned(d, e, n).SelectMany(g => g).ToHashSet();
        int num = Number(d, e, n);
        var sites = new List<RefSite>();
        for (int li = 0; li < d.Lines.Count; li++)
        {
            var l = d.Lines[li];
            if (own.Contains(l)) continue;
            foreach (var i in Marked(l, Kinds(e)))
                if (Ref(l, i, l.Tokens[i]) == num) sites.Add(new(li + 1, l.Label, CardSchema.Header(l.Card, i + CardSchema.Skip(l.Card, l.Count))));
        }
        return sites;
    }

    /// Fresh copies of entity n's lines (the grid's "add row, copy of selected"). The per-entity list
    /// values start at 0, as ATB 3I's new D7 row does: F.1.A/F.3.A/F.4.A/F.7.A count contact rows the copy does not get.
    public static EntityData Copy(Deck d, Entity e, int n)
    {
        Check(d, e, n, insert: false);
        var data = new EntityData();
        foreach (var g in Owned(d, e, n)) data.Groups.Add(g.Select(l => new DeckLine(l.Tokens, l.Label)).ToList());
        foreach (var _ in Lists(e)) data.Values.Add("0");
        return data;
    }

    /// Delete entity n. When anything still refers to it, confirm gets the list first and a false
    /// answer leaves the deck untouched (returns null). Returns what was removed, for Insert.
    public static EntityData? Delete(Deck d, Entity e, int n, Func<IReadOnlyList<RefSite>, bool> confirm)
    {
        Check(d, e, n, insert: false);
        if (e == Entity.Vehicle && n == Count(d, e))
            throw new InvalidOperationException("The primary (last) vehicle cannot be deleted.");   // ATB 3I Vehicle.cs btnDelete
        var refs = References(d, e, n);
        if (refs.Count > 0 && !confirm(refs)) return null;

        int num = Number(d, e, n);
        var kinds = Kinds(e);
        var data = new EntityData();
        data.Groups.AddRange(Owned(d, e, n));
        var gone = data.Groups.SelectMany(g => g).ToHashSet();
        var lists = new Dictionary<string, List<string>>();
        List<string>? List(string c) => lists.TryGetValue(c, out var v) ? v : ReadList(d, c) is { } r ? lists[c] = r : null;

        var cascade = Cascade(e);
        for (int li = 0; li < d.Lines.Count; li++)
        {
            var l = d.Lines[li];
            if (gone.Contains(l) || !cascade.TryGetValue(l.Card, out var cnt) || !Marked(l, kinds).Any(i => Ref(l, i, l.Tokens[i]) == num)) continue;
            gone.Add(l);
            // ponytail: a Type 5 constraint's unlabelled second D.6 line goes with it — layout unverified (no corpus deck).
            if (l.Is("D.6") && Num(l.Tokens[0]) == 5 && li + 1 < d.Lines.Count && d.Lines[li + 1].Card.Length == 0) gone.Add(d.Lines[li + 1]);
            if (cnt.Index >= 0) Bump(d, cnt.Card, cnt.Index, -1);
            else if (List(cnt.Card) is { } v && Num(l.Tokens[0]) is int s && s >= 1 && s <= v.Count && Num(v[s - 1]) is int c)
                v[s - 1] = Str(c - 1);
        }
        foreach (var c in Lists(e))
            if (List(c) is { } v && n <= v.Count) { data.Values.Add(v[n - 1]); v.RemoveAt(n - 1); }
            else data.Values.Add("0");

        d.Lines.RemoveAll(gone.Contains);
        foreach (var (c, v) in lists) WriteList(d, c, v);

        var drop = new HashSet<DeckLine>();
        if (e != Entity.Joint && e != Entity.Plane) DropH13Rows(d, num, drop);
        for (int li = 0; li < d.Lines.Count; li++)
        {
            var l = d.Lines[li];
            if (drop.Contains(l)) continue;
            var idx = Marked(l, kinds).ToList();
            if (idx.Count == 0) continue;
            var t = l.Tokens.ToList();
            var hit = new List<int>();
            foreach (var i in idx)
                if (Num(t[i]) is int v && Ref(l, i, t[i]) is int a) { if (a == num) hit.Add(i); else if (a > num) t[i] = Str(Math.Sign(v) * (a - 1)); }
            if (hit.Count > 0 && CountLed.TryGetValue(l.Card, out int lead))
            {
                var spec = CardSchema.Cards[l.Card];
                int first = spec.Names.Length - spec.Tail;
                foreach (var g in hit.Select(i => first + (i - first) / spec.Tail * spec.Tail).Distinct().OrderDescending())
                {
                    t.RemoveRange(g, spec.Tail);
                    t[lead] = Str(Num(t[lead])!.Value - 1);
                }
                if (l.Is("H.10.B") && Num(t[lead]) == 0)
                {
                    drop.Add(l);
                    if (li + 1 < d.Lines.Count && d.Lines[li + 1].Is("H.10.C")) drop.Add(d.Lines[li + 1]);
                    Bump(d, "H.10.A", 0, -1);
                }
            }
            else foreach (var i in hit) t[i] = Blank(l.Card);
            l.SetTokens(t);
        }
        d.Lines.RemoveAll(drop.Contains);
        BumpCount(d, e, -1);
        return data;
    }

    /// Insert data as entity n (1..Count+1; a vehicle goes before vehicle n, never after the primary).
    /// data's lines go into the deck as they are, so do not insert the same EntityData twice.
    public static void Insert(Deck d, Entity e, int n, EntityData data)
    {
        Check(d, e, n, insert: true);
        int num = Number(d, e, n);
        var kinds = Kinds(e);
        foreach (var l in d.Lines)
        {
            var t = l.Tokens.ToList();
            foreach (var i in Marked(l, kinds))
                if (Num(t[i]) is int v && Ref(l, i, t[i]) is int a && a >= num) t[i] = Str(Math.Sign(v) * (a + 1));
            l.SetTokens(t);
        }
        var groups = Groups(e);
        for (int g = 0; g < groups.Length && g < data.Groups.Count; g++)
            d.Lines.InsertRange(e == Entity.Vehicle ? d.Lines.IndexOf(Owned(d, e, n)[0][0]) : InsertAt(d, groups[g], n), data.Groups[g]);
        var lists = Lists(e);
        for (int c = 0; c < lists.Length && c < data.Values.Count; c++)
            if (ReadList(d, lists[c]) is { } v) { v.Insert(n - 1, data.Values[c]); WriteList(d, lists[c], v); }
            // ponytail: a list card absent from the deck (e.g. F.4.A with no joints) is not created — add when a deck needs it.
        BumpCount(d, e, +1);

        var own = data.Groups.SelectMany(g => g);
        if (e == Entity.Plane && own.FirstOrDefault(l => l.Is("D.2.A")) is { Count: > 0 } p) SetToken(p, 0, n);
        if (e == Entity.Vehicle && own.FirstOrDefault(l => l.Is("C.2.A")) is { Count: 14 } c2) SetToken(c2, 13, num);
    }

    // --- helpers ---

    static void Check(Deck d, Entity e, int n, bool insert)
    {
        int max = Count(d, e) + (insert && e != Entity.Vehicle ? 1 : 0);
        if (n < 1 || n > max) throw new ArgumentOutOfRangeException(nameof(n), $"{e} {n} is outside 1..{max}");
    }

    /// The number references use: a vehicle's segment number follows the body segments (src/input_vehicle.for NVEH).
    static int Number(Deck d, Entity e, int n) => e == Entity.Vehicle ? d.SegmentCount + n : n;

    static List<List<DeckLine>> Owned(Deck d, Entity e, int n)
    {
        if (e == Entity.Vehicle)
        {
            var starts = d.Lines.Select((l, i) => (l, i)).Where(x => x.l.Is("C.1")).Select(x => x.i).ToList();
            int a = starts[n - 1], b = n < starts.Count ? starts[n] : d.Lines.FindIndex(a, l => l.Is("D.1.A"));
            return [d.Lines.GetRange(a, (b < 0 ? d.Lines.Count : b) - a)];
        }
        return Groups(e).Select(g => d.Rows(g) is var rows && n <= rows.Count ? rows[n - 1].OfType<DeckLine>().ToList() : []).ToList();
    }

    static int InsertAt(Deck d, string[] group, int n)
    {
        var rows = d.Rows(group);
        if (rows.Count == 0) throw new InvalidOperationException($"No {group[0]} line to place the new one next to.");
        return n <= rows.Count ? d.Lines.IndexOf(rows[n - 1][0]!) : d.Lines.IndexOf(rows[^1].Last(l => l != null)!) + 1;
    }

    /// Token indexes of l whose schema kind is one of kinds.
    static IEnumerable<int> Marked(DeckLine l, Kind[] kinds)
    {
        if (l.Card.Length == 0) yield break;
        int skip = CardSchema.Skip(l.Card, l.Count);
        for (int i = 0; i < l.Count; i++)
            if (CardSchema.KindOf(l.Card, i + skip) is { } k && kinds.Contains(k)) yield return i;
    }

    static int? Num(string tok) =>
        double.TryParse(tok.Replace('D', 'E').Replace('d', 'e'), NumberStyles.Float, CultureInfo.InvariantCulture, out var v) && v == Math.Floor(v) && Math.Abs(v) < int.MaxValue
            ? (int)v : null;

    // The solver reads these "Segment"/"Joint" fields as SEG(ABS(MSG)) / JNT(ABS(MSG)); the sign picks an output option
    // (src/heding_hcards.for:103, output_hcards.for:72, heding_ang_displ.for:82, heding_wind.for:72, heding_jnt_parm.for:72).
    // Ref Segment (KREF) gets no ABS and must be >= 0 (input_h4_h9_cards.for:113); H.9's joint has no ABS (heding_joint_forces.for:51).
    static readonly HashSet<string> SignedCards = new(StringComparer.OrdinalIgnoreCase)
    { "H.1.A", "H.1.B", "H.2.A", "H.2.B", "H.3.A", "H.3.B", "H.4", "H.5", "H.6", "H.7", "H.8" };

    /// The entity number token i refers to: |value| in a sign-carrying H field, else the value.
    static int? Ref(DeckLine l, int i, string tok) =>
        Num(tok) is int v && SignedCards.Contains(l.Card) && !CardSchema.Header(l.Card, i + CardSchema.Skip(l.Card, l.Count)).StartsWith("Ref ")
            ? Math.Abs(v) : Num(tok);

    /// H.1-H.3: drop every selection row whose Segment (|MSG|) or Ref Segment is num, as CountLed does for H.4-H.9, so no
    /// row is left pointing at SEG(0) or silently at the vehicle frame (heding_hcards.for:103-105). Layout per
    /// src/input_h1_h3_cards.for: the .a line is Count + row 1; Count <= 1 is followed by one dummy .b line, else one .b per further row.
    /// The .b lines are the ones right after the .a line (a deck's labels can be off: 2479_2.LIN's H.3.a says H.1.a).
    static void DropH13Rows(Deck d, int num, HashSet<DeckLine> drop)
    {
        static bool IsB(DeckLine l) => l.Card is "H.1.B" or "H.2.B" or "H.3.B";
        for (int li = 0; li < d.Lines.Count; li++)
        {
            var a = d.Lines[li];
            // ponytail: a 6-token .a line (no Count) is not reflowed and falls back to clearing the ref — no deck has one.
            if (a.Card is not ("H.1.A" or "H.2.A" or "H.3.A") || a.Count != 7) continue;
            var bs = new List<DeckLine>();
            for (int k = li + 1; k < d.Lines.Count && IsB(d.Lines[k]); k++) bs.Add(d.Lines[k]);
            var rows = new List<List<string>> { a.Tokens.GetRange(1, 6) };
            rows.AddRange(bs.Where(b => b.Count == 6).Select(b => b.Tokens.ToList()));
            var keep = rows.Where(r => Num(r[0]) != num && (Num(r[1]) is not int s || Math.Abs(s) != num)).ToList();
            if (keep.Count == rows.Count) continue;
            a.SetTokens([Str(keep.Count), .. keep.Count > 0 ? keep[0] : Enumerable.Repeat("0", 6)]);
            List<List<string>> bLines = keep.Count <= 1 ? [["0"]] : keep.Skip(1).ToList();
            for (int k = 0; k < bs.Count; k++)
                if (k < bLines.Count) bs[k].SetTokens(bLines[k]); else drop.Add(bs[k]);
        }
    }

    static string Str(int v) => v.ToString(CultureInfo.InvariantCulture);

    static void SetToken(DeckLine l, int i, int v) { var t = l.Tokens.ToList(); t[i] = Str(v); l.SetTokens(t); }

    static void Bump(Deck d, string card, int i, int delta)
    {
        if (d.Card(card) is { } l && i < l.Count && Num(l.Tokens[i]) is int v) SetToken(l, i, v + delta);
    }

    static void BumpCount(Deck d, Entity e, int delta)
    {
        if (e == Entity.Segment) Bump(d, "B.1", 0, delta);
        else if (e == Entity.Joint) Bump(d, "B.1", 1, delta);
        else if (e == Entity.Plane) Bump(d, "D.1.A", 0, delta);
    }

    static List<string>? ReadList(Deck d, string card)
    {
        var ls = d.Cards(card).ToList();
        return ls.Count == 0 ? null : ls.SelectMany(l => l.Tokens).ToList();
    }

    /// Repack a list card 18 values per line, touching only the lines whose values change.
    static void WriteList(Deck d, string card, List<string> vals)
    {
        var ls = d.Cards(card).ToList();
        var chunks = vals.Chunk(18).ToList();
        int at = d.Lines.IndexOf(ls[^1]) + 1;
        for (int i = 0; i < Math.Max(ls.Count, chunks.Count); i++)
            if (i >= chunks.Count) d.Lines.Remove(ls[i]);
            else if (i < ls.Count) ls[i].SetTokens(chunks[i]);
            else d.Lines.Insert(at++, new DeckLine(chunks[i], ls[0].Label));
    }
}
