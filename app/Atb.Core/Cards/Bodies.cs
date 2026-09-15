using Atb.Core.Lin;

namespace Atb.Core.Cards;

/// Whole-body operations of ATB 3I's "Body Editing Form" (decomp ATB3I/Body.cs): the body table, Copy Body,
/// Add/Insert Copied Body, Replace Body with Copied Body and Delete Body. Each returns a new deck; the one passed in is
/// never touched. Segments and joints go in and out through Renumber (via GebodMerge.AddBody / ReplaceBody, shared
/// with GEBOD); Renumber.CopyBody / Place carry the copy's references through those inserts and deletes.
public static class Bodies
{
    /// One row of 3I's body table (FillBodyTable): body number, segments, joints (the body's own NULL joint excluded).
    public sealed record Row(int Body, int Segments, int Joints);

    /// What Copy Body puts on 3I's clipboard (Body.cs:698-731): the body's segments First..First+Segments-1 and its
    /// joints First..First+Segments-2. The lines are read when the copy is added or replaces a body, as 3I does.
    public sealed record Copied(int First, int Segments);

    public static List<Row> Summary(Deck d)
    {
        var starts = GebodMerge.BodyStarts(d);
        int nseg = Renumber.Count(d, Entity.Segment);
        return starts.Select((a, i) => (a, s: (i + 1 < starts.Count ? starts[i + 1] : nseg + 1) - a))
            .Select((x, i) => new Row(i + 1, x.s, x.s - 1)).ToList();
    }

    public static Copied Copy(Deck d, int k)
    {
        var rows = Summary(d);
        if (k < 1 || k > rows.Count) throw new ArgumentOutOfRangeException(nameof(k), $"Body {k} is outside 1..{rows.Count}.");
        return new Copied(GebodMerge.BodyStarts(d)[k - 1], rows[k - 1].Segments);
    }

    /// Add/Insert Copied Body at p (Add, InsertBefore = Body.cs:627 Yes, InsertAfter = No): the copy's segments, joints
    /// and every per-segment / per-joint card (B.2, B.6, G.3.A; B.3-B.5) go in at the new body's place, a blank G.2 row
    /// is added, and each segment number inside the copy that named the copied body names the copy.
    public static Deck Insert(Deck deck, Copied c, GebodPlacement p)
    {
        var d = GebodMerge.Editable(deck);
        int s0 = GebodMerge.Start(d, p);
        var (segs, joints) = Take(d, c);
        return Renumber.Place(d, segs, joints, () => GebodMerge.AddBody(d, s0, segs, joints));
    }

    /// Replace Body with Copied Body (Body.cs:860): body k takes the copy by position through GebodMerge.ReplaceBody,
    /// the same function GEBOD Replace uses: references to body k's i-th segment or joint stay, surplus positions are
    /// dropped (Renumber.Delete), the rest of the deck shifts by the size difference.
    public static Deck Replace(Deck deck, int k, Copied c)
    {
        var d = GebodMerge.Editable(deck);
        var starts = GebodMerge.BodyStarts(d);
        if (k < 1 || k > starts.Count) throw new ArgumentOutOfRangeException(nameof(k), $"Body {k} is outside 1..{starts.Count}.");
        var (segs, joints) = Take(d, c);
        return Renumber.Place(d, segs, joints, () => GebodMerge.ReplaceBody(d, k, segs, joints, _ => true));   // 3I asks Body.cs:860 only
    }

    /// ATB 3I DeleteBody (Body.cs:1078-1124): segments a..b-1; joints a..b-1 (the next body's NULL joint b-1, so body
    /// k's own NULL joint roots the next body), or for the last body its NULL joint and joints a-1..NJNT; highest first
    /// through Renumber.Delete (cascade, as 3I's :756 warns), then body k's G.2 row (UpdateDueToBody, bdyChange < 0).
    public static Deck Delete(Deck deck, int k)
    {
        var d = GebodMerge.Editable(deck);
        var starts = GebodMerge.BodyStarts(d);
        int nb = starts.Count, nseg = Renumber.Count(d, Entity.Segment), njnt = Renumber.Count(d, Entity.Joint);
        if (k < 1 || k > nb) throw new ArgumentOutOfRangeException(nameof(k), $"Body {k} is outside 1..{nb}.");
        int a = starts[k - 1], b = k < nb ? starts[k] : nseg + 1;
        var (j0, j1) = k < nb ? (a, b - 1) : (Math.Max(a - 1, 1), njnt);
        if (d.Cards("G.2").ElementAtOrDefault(k - 1) is { } g2) d.Lines.Remove(g2);
        for (int j = j1; j >= j0; j--) Renumber.Delete(d, Entity.Joint, j, _ => true);
        for (int s = b - 1; s >= a; s--) Renumber.Delete(d, Entity.Segment, s, _ => true);
        return d;
    }

    /// The copied body's lines (Renumber.CopyBody), if it is still in the deck.
    static (List<EntityData>, List<EntityData>) Take(Deck d, Copied c)
    {
        if (c.Segments < 1 || c.First < 1 || c.First + c.Segments - 1 > Renumber.Count(d, Entity.Segment))
            throw new InvalidOperationException("The copied body is no longer in the deck.");
        return Renumber.CopyBody(d, c.First, c.Segments);
    }
}
