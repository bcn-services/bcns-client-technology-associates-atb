using Atb.Core.Cards;

namespace Atb.Core.Lin;

/// Assigns CARD labels to a bare or mislabelled deck by walking the ATB 3I input grammar
/// (FileManager.ReadFile order and counts). Lines already carrying a schema label are never
/// touched; the one exception is ATB 3I's own writer bug, which labels an empty H.2/H.3 first
/// row "CARD H.1.a" (FileManager.WriteFile H section). Data rows ATB writes unlabelled (C.3
/// decelerations, E.4 X-Y pairs, E.6 time rows, E.7 theta rows) stay unlabelled.
public static class Labeler
{
    /// Labels deck in place. Returns, per line, the card key the grammar assigned (upper case,
    /// e.g. "B.2.A"), or null for blank lines and unlabelled data rows (C.3, E.4 pairs, E.6/E.7 rows, F.8.B).
    /// Throws FormatException naming the last card understood when the grammar cannot walk the deck.
    public static string?[] Label(Deck deck) => new Walk(deck).Run();

    /// "B.2.A" -> "CARD B.2.a", "F.8.D1" -> "CARD F.8.d1", "A.3" -> "CARD A.3".
    public static string LabelFor(string key)
    {
        var p = key.Split('.');
        for (int i = 2; i < p.Length; i++) p[i] = p[i].ToLowerInvariant();
        return "CARD " + string.Join('.', p);
    }

    sealed class Walk(Deck deck)
    {
        readonly List<DeckLine> lines = deck.Lines;
        readonly string?[] grammar = new string?[deck.Lines.Count];
        int pos;
        string last = "(nothing - deck is empty)";
        int lastLine;

        public string?[] Run()
        {
            // A: title and run control
            Line("A.1.A", skipBlank: false); Line("A.1.B", skipBlank: false); Line("A.1.C", skipBlank: false);
            Take("A.3", 7); Take("A.4", 6);
            var a5 = Take("A.5", 36);

            // B: segments and joints
            var b1 = Take("B.1", 4);
            int nSeg = I(b1, 0, "B.1"), nJnt = I(b1, 1, "B.1"), flex = I(b1, 3, "B.1");
            for (int s = 0; s < nSeg; s++)
                if (I(Take("B.2.A", 12), 11, "B.2.A") == 1) Take("B.2.B", 3);
            var spin = new bool[nJnt];
            int num5 = 1;                                  // ReadFile: 1 + joints with Seg JNT == 0
            for (int j = 0; j < nJnt; j++)
            {
                var a = Take("B.3.A", 12);
                spin[j] = IsSpin(I(a, 2, "B.3.A"), I(a, 9, "B.3.A"));
                if (I(a, 1, "B.3.A") == 0) num5++;
                Take("B.3.B", 15);
                // ponytail: B.3.C placement (after each B.3.B) unverified — no flexible-body deck in the corpus.
                if (flex > 0) Take("B.3.C", 6);
            }
            bool jointFuncs = false;                       // any B.4.A[0] < 0 -> E.7 section present
            for (int j = 0; j < nJnt; j++)
            {
                if (N(Take("B.4.A", 10), 0, "B.4.A") < 0) jointFuncs = true;
                if (spin[j]) Take("B.4.B", 8);
            }
            for (int j = 0; j < nJnt; j++)
            {
                Take("B.5.A", 7);
                if (spin[j]) { Take("B.5.B", 7); Take("B.5.C", 7); }
            }
            for (int s = 0; s < nSeg; s++) Take("B.6", 12);

            // C: vehicle motion, one block per vehicle until C.2.A Vehicle Segment == 0
            while (true)
            {
                Line("C.1", skipBlank: false);
                var c = Take("C.2.A", 14);
                int interp = I(c, 8, "C.2.A");
                if (interp > 0) Take(null, interp);        // C.3 decelerations, unlabelled
                else if (interp < 0)
                {
                    var cb = Take("C.2.B", 6);
                    int spline = I(cb, 0, "C.2.B");
                    if (spline == 0) for (int k = 0; k < -interp; k++) Take("C.4", 6);
                    else if (spline > 0) for (int k = 0; k < spline - 1 + I(cb, 2, "C.2.B"); k++) Take("C.5", 7);
                }
                if (I(c, 13, "C.2.A") == 0) break;
            }

            // D: contact surfaces and restraints
            var d1 = Take("D.1.A", 12);
            int npl = I(d1, 0, "D.1.A"), nblt = I(d1, 1, "D.1.A"), nbag = I(d1, 2, "D.1.A"), nelp = I(d1, 3, "D.1.A"),
                nq = I(d1, 4, "D.1.A"), nsd = I(d1, 5, "D.1.A"), nhrn = I(d1, 6, "D.1.A"), nwind = I(d1, 7, "D.1.A"),
                nforce = I(d1, 9, "D.1.A"), nwater = I(d1, 10, "D.1.A"), nrt = 0;
            if (I(d1, 11, "D.1.A") != 0) nrt = I(Take("D.1.B", 1), 0, "D.1.B");
            for (int k = 0; k < npl; k++) { Line("D.2.A"); Take("D.2.B", 3); Take("D.2.C", 3); Take("D.2.D", 3); }
            // ponytail: D.3/D.4 (belts/airbags), F.2/F.6 and F.9 (water) have no schema entry and no corpus deck — throw.
            if (nblt > 0 || nbag > 0) throw Err("D.1.A NBLT/NBAG > 0: belt and airbag cards (D.3/D.4) are not supported");
            for (int k = 0; k < nelp; k++) Take("D.5", 13);
            for (int k = 0; k < nq; k++) Take("D.6", 9);   // one line per constraint, any KQTYPE (src/input_contraints.for:29)
            Take("D.7", nSeg);
            for (int k = 0; k < nsd; k++) Take("D.8", 13);
            for (int k = 0; k < nforce; k++) Take("D.9", 8);

            // E: functions, terminated by an E.1 with FunctionID >= 51 (conventionally 999)
            while (true)
            {
                if (I(Line("E.1"), 0, "E.1") >= 51) break;
                var e2 = Line("E.2");                      // ReadFile: ParseStr(ReadLine()), one record
                foreach (var slot in FunctionType(N(e2, 1, "E.2"), N(e2, 2, "E.2")))
                    if (slot == 1) Take("E.3", 6);
                    else if (slot == 2) Take(null, 2 * I(Take("E.4.A", 1), 0, "E.4.A"));   // X-Y pairs, unlabelled
            }
            for (int w = 0; w < nwind; w++)
            {
                Line("E.6.A");
                var b = Take("E.6.B", 5);
                if (b.Count == 0 || N(b, 0, "E.6.B") == 0)
                    for (int k = I(Take("E.6.C", 1), 0, "E.6.C"); k > 0; k--) Take(null, 4);   // Time Fx Fy Fz, unlabelled
            }
            if (jointFuncs)
                while (true)
                {
                    if (I(Line("E.7.A"), 0, "E.7.A") >= 51) break;
                    Take("E.7.B", 5);
                    var c = Take("E.7.C", 2);
                    int nTheta = Math.Abs(I(c, 0, "E.7.C")), nPhi = I(c, 1, "E.7.C");
                    for (int k = 0; k < nPhi; k++) Take(null, nTheta);                       // one theta row per phi, unlabelled
                }

            // F: contact allocation
            if (npl > 0) for (int k = Sum(Take("F.1.A", npl), "F.1.A"); k > 0; k--) Take("F.1.B", 11);
            for (int k = Sum(Take("F.3.A", nSeg), "F.3.A"); k > 0; k--) Take("F.3.B", 10);
            if (nJnt > 0) for (int k = Sum(Take("F.4.A", nJnt), "F.4.A"); k > 0; k--) Take("F.4.B", 9);
            if (nwind > 0)
                for (int k = Sum(Take("F.7.A", nSeg), "F.7.A"); k > 0; k--)
                {
                    var b = Take("F.7.B", 7);
                    int blocking = I(b, 6, "F.7.B");
                    if (N(b, 0, "F.7.B") < 0 && blocking > 0) Take("F.7.C", 2 * blocking);
                }
            if (nhrn > 0)
            {
                var a = Take("F.8.A", 7);
                for (int h = 0; h < nhrn && h < 5; h++)
                {
                    int belts = I(a, h, "F.8.A");
                    if (belts <= 0) continue;
                    // F.8.B (points per belt): ATB 3I WriteFile writes it unlabelled, so it stays a data row.
                    var points = Take(null, belts);
                    for (int b = 0; b < belts; b++)
                    {
                        Take("F.8.C", 6);
                        for (int p = I(points, b, "F.8.B"); p > 0; p--) { Take("F.8.D1", 12); Take("F.8.D2", 6); }
                    }
                }
            }
            if (nwater > 0) throw Err("D.1.A NWATER > 0: water cards (F.9) are not supported");
            for (int k = 0; k < nrt; k++) Take("F.10", 6);

            // G: initial conditions
            if (nSeg > 0)
            {
                Take("G.1", 2);
                for (int k = 0; k < num5; k++) Take("G.2", 8);
                for (int k = 0; k < nSeg; k++) Take("G.3.A", 10);
            }

            // H: output selection
            for (int n = 1; n <= 3; n++)
            {
                int count = I(HFirstRow(n), 0, $"H.{n}.A");
                if (count <= 1) Line($"H.{n}.B");
                else for (int k = 1; k < count; k++) Line($"H.{n}.B");
            }
            foreach (var key in new[] { "H.4", "H.5", "H.6", "H.7", "H.8", "H.9" }) Line(key);
            for (int k = I(Take("H.10.A", 1), 0, "H.10.A"); k > 0; k--) { Line("H.10.B"); Take("H.10.C", 10); }
            if (nrt > 0) Line("H.11");
            int nprt4 = I(a5, 3, "A.5");
            if (num5 > 0 && nprt4 != 0 && nprt4 != 4)
                // ponytail: NHIC > 1 assumed wrapped as 3-value H.12.B lines; ATB 3I writes them on one line — not in corpus.
                for (int k = I(Take("H.12.A", 5), 0, "H.12.A") - 1; k > 0; k--) Take("H.12.B", 3);

            for (; pos < lines.Count; pos++)
                if (lines[pos].Count > 0) throw Err("unexpected data after the last card");
            return grammar;
        }

        /// First row of H.1/H.2/H.3. Fixes ATB 3I's writer bug: an empty H.2/H.3 selection is
        /// written as seven zeros labelled "CARD H.1.a" (FileManager.WriteFile H section).
        List<string> HFirstRow(int n)
        {
            SkipBlanks();
            if (pos < lines.Count)
            {
                var l = lines[pos];
                if (n > 1 && l.Card == "H.1.A" && l.Count > 0 && N(l.Tokens, 0, "H.1.A") == 0)
                    SetLabel(l, LabelFor($"H.{n}.A"), l.Count);
            }
            return Line($"H.{n}.A");
        }

        /// Reads n values in Fortran list-directed style: whole lines until n values are in hand,
        /// the rest of the last line ignored. key == null consumes unlabelled data rows untouched.
        List<string> Take(string? key, int n)
        {
            var vals = new List<string>(Math.Max(n, 0));
            while (vals.Count < n)
            {
                if (pos >= lines.Count) throw Err($"deck ends while reading {key ?? "data rows"} ({vals.Count} of {n} values)");
                var l = lines[pos];
                if (l.Count == 0 && l.Label.Length == 0) { pos++; continue; }
                int keep = Math.Min(l.Count, n - vals.Count);
                vals.AddRange(l.Tokens.Take(keep));
                if (key != null) { grammar[pos] = key; Apply(l, key, keep); }
                pos++;
            }
            if (key != null && n > 0) Understood();
            return vals;
        }

        /// Reads one physical line as the given card (ATB 3I ParseStr / single-record reads).
        List<string> Line(string key, bool skipBlank = true)
        {
            if (skipBlank) SkipBlanks();
            if (pos >= lines.Count) throw Err($"deck ends before {key}");
            var l = lines[pos];
            grammar[pos] = key;
            Apply(l, key, l.Count);
            pos++;
            Understood();
            return l.Tokens;
        }


        void SkipBlanks() { while (pos < lines.Count && lines[pos].Count == 0 && lines[pos].Label.Length == 0) pos++; }

        void Understood() { last = lines[pos - 1].Label; lastLine = pos; }

        /// Labels line l as key, keeping its first `keep` tokens. Never touches a line that
        /// already carries a schema label (the H.1.a bug is handled in HFirstRow).
        static void Apply(DeckLine l, string key, int keep)
        {
            if (l.Card.Length > 0 && CardSchema.Cards.ContainsKey(l.Card)) return;
            SetLabel(l, LabelFor(key), keep);
        }

        static void SetLabel(DeckLine l, string label, int keep)
        {
            if (keep < l.Count) { l.Tokens.RemoveRange(keep, l.Count - keep); l.Relabel(label, null); return; }
            var raw = l.Raw;
            if (raw == null) { l.Relabel(label, null); return; }
            var m = Deck.LabelRx.Match(raw);
            l.Relabel(label, m.Success
                ? raw[..m.Groups[1].Index] + label + raw[(m.Groups[1].Index + m.Groups[1].Length)..]
                : raw.TrimEnd() + "    " + label);
        }

        FormatException Err(string msg) =>
            new($"{msg} at line {Math.Min(pos + 1, lines.Count)}; last card understood: {last}" + (lastLine > 0 ? $" at line {lastLine}" : ""));

        double N(IReadOnlyList<string> t, int i, string key)
        {
            if (i >= t.Count) throw Err($"{key} is missing value {i + 1}");
            try { return DeckLine.ParseNum(t[i]); }
            catch (FormatException) { throw Err($"{key} value {i + 1} '{t[i]}' is not a number"); }
        }

        int I(IReadOnlyList<string> t, int i, string key) => (int)Math.Round(N(t, i, key));

        int Sum(IReadOnlyList<string> t, string key) => Enumerable.Range(0, t.Count).Sum(i => Math.Max(I(t, i, key), 0));
    }

    /// ATB 3I FileManager.GetFunctionType: E.2 D1/D2 -> function slot types (1 = E.3 polynomial, 2 = E.4 table).
    public static int[] FunctionType(double d1, double d2) =>
        d1 == 0 ? [0, 0]
        : d2 == 0 ? [d1 < 0 ? 2 : 1, 0]
        : d2 > 0 ? [d1 < 0 ? 2 : 1, 1]
        : d1 > 0 ? [1, 2]
        : [0, 0];

    /// A joint whose type carries B.4.B / B.5.B / B.5.C lines (Joint Type 304 or 104-110).
    internal static bool IsSpin(int pin, int slip) =>
        JointType(pin, slip) is var type && (type == "304" || (int.TryParse(type, out var t) && t is >= 104 and <= 110));

    /// ATB 3I FileManager.GetJointType(pin = B.3.A Joint Type, slip = IEULER), ported verbatim.
    static string JointType(int pin, int slip)
    {
        if (Math.Abs(pin) > 10) return "2";
        int num = Math.Sign(pin) + 2;
        if (num == 2 || (num == 3 && Math.Abs(pin) > 7)) return "2";
        var result = num + (Math.Abs(pin) >= 10 ? "" : "0") + Math.Abs(pin);
        if (Math.Abs(slip) > 1) return "2";
        num = Math.Sign(slip) + 2;
        if (num == 2 || Math.Abs(pin) < 5 || Math.Abs(pin) > 7) return result;
        return result + num + Math.Abs(slip);
    }
}
