namespace Atb.Core.Cards;

public enum Kind { Str, Int, Real, SegRef, JointRef, PlaneRef, FuncRef }

/// One CARD label: field names and kinds in token order, when the card appears, and (for cards
/// whose token count varies) the rule the count must satisfy. Fixed cards: count == Names.Length.
public sealed record CardSpec(string Label, string[] Names, Kind[] Kinds, string Appears,
                              string? Rule = null, Func<IReadOnlyList<string>, bool>? Fits = null)
{
    /// null when the tokens fit this card, else the reason they do not.
    public string? Check(IReadOnlyList<string> t) => Fits == null
        ? (t.Count == Names.Length ? null : $"expected {Names.Length} tokens, found {t.Count}")
        : (Fits(t) ? null : $"expected {Rule}, found {t.Count} tokens");
}

/// Schema for every .LIN card. Field order from the solver READ statements (src/input_*.for);
/// names are the ATB 3I column titles (ATB3iData.mdb) where one exists, else the solver variable;
/// appearance conditions from ATB 3I FileManager.WriteFile.
public static class CardSchema
{
    // Field spec "k:Name": s=Str i=Int r=Real g=SegRef j=JointRef p=PlaneRef f=FuncRef.
    static readonly Dictionary<char, Kind> KindCode = new()
    { ['s'] = Kind.Str, ['i'] = Kind.Int, ['r'] = Kind.Real, ['g'] = Kind.SegRef, ['j'] = Kind.JointRef, ['p'] = Kind.PlaneRef, ['f'] = Kind.FuncRef };

    static int Lead(IReadOnlyList<string> t, int i = 0) =>
        t.Count > i && int.TryParse(t[i], out var n) && n >= 0 ? n : -1;

    const string Per18 = "1-18 values per line (18 per line, last line holds the remainder)";
    static bool UpTo18(IReadOnlyList<string> t) => t.Count is >= 1 and <= 18;
    static bool CountPairs(IReadOnlyList<string> t) => Lead(t) >= 0 && t.Count == 1 + 2 * Lead(t);
    static bool CountList(IReadOnlyList<string> t) => Lead(t) >= 0 && t.Count == 1 + Lead(t);

    static string[] Seq(string spec, int n) => Enumerable.Range(1, n).Select(i => spec.Replace("#", i.ToString())).ToArray();
    static string[] Cat(params string[][] parts) => parts.SelectMany(p => p).ToArray();

    static readonly string[] H13 = ["i:Count", "g:Ref Segment", "g:Segment", "r:Point Loc - X", "r:Point Loc - Y", "r:Point Loc - Z", "i:Accelerometer"];
    static readonly string[] H4_9 = ["i:Count", "g:Ref Segment", "g:Segment or Joint"];
    static readonly string[] H7_11 = ["i:Count", "j:Joint or Actuator"];
    static readonly string[] FiveFuncs = ["f:F1 (FDF)", "f:F2 (Spike)", "f:F3 (R Factor)", "f:F4 (G Factor)", "f:Friction"];
    static readonly string[] XYZ = ["X", "Y", "Z"];
    static string[] Xyz(string kind, string name) => XYZ.Select(a => $"{kind}:{name} - {a}").ToArray();

    public static readonly IReadOnlyDictionary<string, CardSpec> Cards = Build();

    static Dictionary<string, CardSpec> Build()
    {
        var d = new Dictionary<string, CardSpec>(StringComparer.OrdinalIgnoreCase);
        void F(string label, string appears, params string[] f) => V(label, appears, null, null, f);
        void V(string label, string appears, string? rule, Func<IReadOnlyList<string>, bool>? fits, params string[] f) =>
            d.Add(label, new CardSpec(label, f.Select(x => x[2..]).ToArray(), f.Select(x => KindCode[x[0]]).ToArray(), appears, rule, fits));

        // A: title, units, integration control, print control
        F("A.1.A", "always", "s:Date");
        F("A.1.B", "always", "s:Comment 1");
        F("A.1.C", "always", "s:Comment 2");
        F("A.3", "always", "s:Unit of Length", "s:Unit of Force", "s:Unit of Time", "r:Gravity X", "r:Gravity Y", "r:Gravity Z", "r:G");
        F("A.4", "always", "i:Num of Iteration", "i:Num of Output", "r:Output Interval", "r:Initial Size", "r:Maximum Size", "r:Minimum Size");
        F("A.5", "always", Seq("i:NPRT(#)", 36));

        // B: segments and joints
        F("B.1", "always", "i:Segments", "i:Joints", "s:Body Name", "i:Flexible Bodies");
        F("B.2.A", "one per segment (B.1 Segments)", "s:Name", "r:Weight", "r:Ixx", "r:Iyy", "r:Izz",
          "r:Ellip Semi - X", "r:Ellip Semi - Y", "r:Ellip Semi - Z", "r:Ellip Center - X", "r:Ellip Center - Y", "r:Ellip Center - Z", "i:Define Rotation");
        F("B.2.B", "after B.2.A when Define Rotation != 0", "r:Principal Yaw", "r:Principal Pitch", "r:Principal Roll");
        F("B.3.A", "one per joint (B.1 Joints)", Cat(["s:Name", "g:Seg JNT", "i:Joint Type"],
          Xyz("r", "Location").Select(x => x + " in Seg JNT").ToArray(), Xyz("r", "Location").Select(x => x + " in Seg J+1").ToArray(),
          ["i:IEULER", "r:Tension Lock Force", "r:Compression Lock Force"]));
        F("B.3.B", "after each B.3.A", "r:Z Rotation in Seg JNT", "r:Y Rotation in Seg JNT", "r:X Rotation in Seg JNT",
          "r:Z Rotation in Seg J+1", "r:Y Rotation in Seg J+1", "r:X Rotation in Seg J+1",
          "r:Precession Center (Deg)", "r:Nutation Center (Deg)", "r:Spin Center (Deg)",
          "i:1st Rotation in Seg JNT", "i:2nd Rotation in Seg JNT", "i:3rd Rotation in Seg JNT",
          "i:1st Rotation in Seg J+1", "i:2nd Rotation in Seg J+1", "i:3rd Rotation in Seg J+1");
        F("B.3.C", "after B.3.B when B.1 Flexible Bodies > 0", Seq("i:NODJ(#)", 6));
        F("B.4.A", "one per joint", "r:Flexural Linear Coef", "r:Flexural Quad Coef", "r:Flexural Cubic Coef", "r:Flexural Energy Dissip", "r:Flexural Joint Stop",
          "r:Torsional Linear Coef", "r:Torsional Quad Coef", "r:Torsional Cubic Coef", "r:Torsional Energy Dissip", "r:Torsional Joint Stop");
        F("B.4.B", "after B.4.A when Joint Type is 304 or 104-110", "r:Spin Linear Coef", "r:Spin Quad Coef", "r:Spin Cubic Coef", "r:Spin Energy Dissip", "r:Spin Joint Stop",
          "r:Precession Initial Angle", "r:Nutation Initial Angle", "r:Spin Initial Angle");
        F("B.5.A", "one per joint", "r:Viscous Coef", "r:Coulomb Fric Coef", "r:Coulomb Fric Ang Vel", "r:Max Lock Torque", "r:Min Unlock Torque", "r:Min Unlock Angular Vel", "r:Restitution Coef");
        F("B.5.B", "after B.5.A when Joint Type is 304 or 104-110", "r:Nutation Viscous Coef", "r:Nutation Coul Fric Coef", "r:Nutat Coul Fric Ang Vel",
          "r:Nutat Max Lock Torque", "r:Nutat Min Unlock Torque", "r:Nutat Min Unlock Ang Vel", "r:Nutat Restitution Coef");
        F("B.5.C", "after B.5.B", "r:Spin Viscous Coef", "r:Spin Coulomb Fric Coef", "r:Spin Coul Fric Ang Vel",
          "r:Spin Max Lock Torque", "r:Spin Min Unlock Torque", "r:Spin Min Unlock Ang Vel", "r:Spin Restitution Coef");
        F("B.6", "always", "r:Angular Vel Test Value", "r:Angular Vel Abs Error", "r:Angular Vel Rel Error", "r:Vel Test Value", "r:Vel Abs Error", "r:Vel Rel Error",
          "r:Angular Acc Test Value", "r:Angular Acc Abs Error", "r:Angular Acc Rel Error", "r:Acc Test Value", "r:Acc Abs Error", "r:Acc Rel Error");

        // C: vehicle motion
        F("C.1", "always", "s:Vehicle Title");
        F("C.2.A", "always", Cat(["r:Angle1", "r:Angle2", "r:Angle3", "r:Initial Velocity", "r:Time Duration"], Xyz("r", "Vehicle Origin"),
          ["i:Interpolated Points", "r:Start Time", "r:Interval", "i:Motion Reference", "g:Reference Segment", "g:Vehicle Segment"]));
        F("C.2.B", "after C.2.A when Interpolated Points < 0", "i:Spline Data Type", "i:Spline Degree", "i:Number of Data Points", "r:Angular Vx", "r:Angular Vy", "r:Angular Vz");
        V("C.3", "after C.2.A when Interpolated Points > 0 (written unlabelled)", "1-12 values per line", t => t.Count is >= 1 and <= 12, "r:Deceleration");
        F("C.4", "after C.2.B when Spline Data Type = 0", Cat(Xyz("r", "Linear"), Xyz("r", "Angular")));
        F("C.5", "after C.2.B when Spline Data Type > 0", Cat(["r:Time"], Xyz("r", "Linear"), Xyz("r", "Angular")));

        // D: contact surfaces and restraints
        F("D.1.A", "always", "i:NPL", "i:NBLT", "i:NBAG", "i:NELP", "i:NQ", "i:NSD", "i:NHRNSS", "i:NWINDF", "i:NJNTFOLD", "i:NFORCE", "i:NWATER", "i:NEXTCD");
        F("D.1.B", "when D.1.A NEXTCD = 1", "i:NRTORQ");
        F("D.2.A", "one set per plane (D.1.A NPL)", "i:PlaneID", "s:Title");
        F("D.2.B", "after D.2.A", Xyz("r", "Point1"));
        F("D.2.C", "after D.2.B", Xyz("r", "Point2"));
        F("D.2.D", "after D.2.C", Xyz("r", "Point3"));
        F("D.5", "one per extra ellipsoid (D.1.A NELP)", Cat(["i:EllipID"], Xyz("r", "Ellip Semi"), Xyz("r", "Ellip Center"),
          ["r:Ellip Yaw", "r:Ellip Pitch", "r:Ellip Roll"], Xyz("r", "Ellip Power")));
        // ponytail: Type 5 constraints carry a second D.6 line (effective masses, spring, damping, ref length) — not
        // in the corpus, so its layout is unverified; the count check here covers the first line only.
        F("D.6", "one per constraint (D.1.A NQ)", Cat(["i:Type", "g:Segment A ID", "g:Segment B ID"], Xyz("r", "Point on A"), Xyz("r", "Point on B")));
        V("D.7", "always, one value per segment", Per18, UpTo18, "i:Symmetry Option");
        F("D.8", "one per spring-damper (D.1.A NSD)", Cat(["g:Segment M ID", "g:Segment N ID"], Xyz("r", "Point on M"), Xyz("r", "Point on N"),
          ["r:Coef D0", "r:Coef A1", "r:Coef A2", "r:Coef B1", "r:Coef B2"]));
        F("D.9", "one per applied force (D.1.A NFORCE)", Cat(["g:Applied SegID", "f:Force Function ID"], Xyz("r", "Force Location"),
          ["r:Force Axis Yaw", "r:Force Axis Pitch", "r:Force Axis Roll"]));

        // E: functions (E.1 FunctionID 999 ends the list)
        F("E.1", "one per function", "i:FunctionID", "s:Title");
        F("E.2", "after E.1", "r:D0", "r:D1", "r:D2", "r:D3", "r:D4");
        F("E.3", "after E.2 when the function is polynomial", Seq("r:Coef", 6));
        F("E.4.A", "after E.2 when the function is tabular; unlabelled X Y lines follow", "i:NPI");
        F("E.6.A", "one per wind function", "i:FunctionID", "s:Title");
        F("E.6.B", "after E.6.A", "r:Specific Heats", "r:Sound Speed", "r:Absolute Pressure", "g:Velocity SegID", "g:Reference SegID");
        F("E.6.C", "after E.6.B; unlabelled Time Fx Fy Fz lines follow", "i:NTMPTS");
        F("E.7.A", "one per joint-torque function", "i:FunctionID", "s:Title");
        F("E.7.B", "after E.7.A", "r:D0", "r:D1", "r:D2", "r:D3", "r:D4");
        F("E.7.C", "after E.7.B", "i:NTheta", "i:NPhi");

        // F: contact allocation
        V("F.1.A", "always, one value per plane", Per18, UpTo18, "i:MNPL");
        F("F.1.B", "sum of F.1.A lines", Cat(["p:Plane", "g:Plane Segment", "g:Contact Segment", "i:Contact Ellip"], FiveFuncs, ["i:Edge Test", "i:Output"]));   // solver: ..., NX, NOUT
        V("F.3.A", "always, one value per segment", Per18, UpTo18, "i:MNSEG");
        F("F.3.B", "sum of F.3.A lines", Cat(["g:Segment A", "i:Segment A Ellip", "g:Segment B", "i:Segment B Ellip"], FiveFuncs, ["i:Output"]));
        V("F.4.A", "always, one value per joint", Per18, UpTo18, "i:IGLOB");
        F("F.4.B", "one per joint with F.4.A IGLOB != 0", "j:Joint", "i:Not Used 1", "i:Not Used 2", "i:Not Used 3",
          "f:F1 (Torq-Def)", "f:F2 (Herron Eq)", "f:F3 (R)", "f:F4 (G)", "f:Friction");
        V("F.7.A", "when D.1.A NWINDF > 0, one value per segment", Per18, UpTo18, "i:MWSEG");
        F("F.7.B", "one per wind contact", "g:Contact Segment", "i:Contact Ellip", "g:Wind Plane Segment", "p:Wind Plane",
          "f:Wind Function", "f:Drag Coef Function", "i:Blocking");
        V("F.7.C", "after F.7.B when Blocking != 0", "1-18 segment/ellipsoid pairs", t => t.Count is >= 2 and <= 36 && t.Count % 2 == 0,
          "g:Blocking Segment", "i:Blocking Ellip");
        F("F.8.A", "one per harness (D.1.A NHRNSS)", Cat(Seq("i:Belts in Harness #", 5), ["i:Max Iteration", "r:Max Strain Convergence"]));
        F("F.8.C", "one per harness belt", "f:Strain F1", "f:Strain F2", "f:Strain F3", "f:Strain F4", "i:Not Used", "r:Initial Slack");
        F("F.8.D1", "one per belt point", Cat(["g:Ref Point Segment", "i:Ref Point Ellip", "i:Preferred Direction", "r:Delta R"], FiveFuncs, Xyz("r", "Point Loc")));
        F("F.8.D2", "after F.8.D1", Cat(Xyz("r", "Offset"), Xyz("r", "Direction Vec")));
        F("F.10", "one per actuator (D.1.B NRTORQ)", "j:Joint ID", "g:Base SegID", "f:Target Angle Function",
          "f:Proportional Gain Function", "f:Derivative Gain Function", "f:Integral Gain Function");

        // G: initial conditions
        F("G.1", "always", "i:Not Used", "i:Velocity Data Source");
        F("G.2", "always", Cat(Xyz("r", "Ref Seg Position"), Xyz("r", "Ref Seg Velocity"), ["g:SegID - Velocity Based On", "g:SegID - Position Given In"]));
        F("G.3.A", "one per segment", Cat(["r:Rotation - Z", "r:Rotation - Y", "r:Rotation - X"], Xyz("r", "Angular Velocity"),
          ["i:1st Rotation", "i:2nd Rotation", "i:3rd Rotation", "g:Ref Segment"]));

        // H: output selection. H.1-H.3: first row leads with Count (7 tokens), each further row drops it (6).
        foreach (var n in new[] { 1, 2, 3 })
        {
            V($"H.{n}.A", "always; first row of the selection", "7 tokens (first row) or 6 (continuation row)", t => t.Count is 7 or 6, H13);
            V($"H.{n}.B", "continuation rows; a lone 0 or empty row when Count <= 1", "0, 1 or 6 tokens", t => t.Count is 0 or 1 or 6, H13[1..]);
        }
        foreach (var n in new[] { 4, 5, 6, 8, 9 })
            V($"H.{n}", "always", "1 + 2 x Count tokens", CountPairs, H4_9);
        V("H.7", "always", "1 + Count tokens", CountList, H7_11);
        V("H.11", "always", "1 + Count tokens", CountList, H7_11);
        F("H.10.A", "always", "i:MCG");
        V("H.10.B", "one per total body (H.10.A MCG)", "2 + Segments in Body tokens", t => Lead(t, 1) >= 0 && t.Count == 2 + Lead(t, 1),
          "i:Total Body ID", "i:Segment Count", "g:Segments in Body");
        F("H.10.C", "after H.10.B", Cat(Xyz("r", "Body Axis Origin"), ["r:Body Axis Rotation - Z", "r:Body Axis Rotation - Y", "r:Body Axis Rotation - X",
          "i:1st Rotation", "i:2nd Rotation", "i:3rd Rotation", "i:Option"]));
        F("H.12.A", "when A.5 NPRT(4) is not 0 or 4", "i:NHIC", "r:Span", "i:JHDATA 1", "i:JHDATA 2", "i:JHDATA 3");
        F("H.12.B", "after H.12.A, one per further HIC set", "i:JHDATA 1", "i:JHDATA 2", "i:JHDATA 3");
        return d;
    }

    /// Field names per label (derived from Cards), kept for callers that only need headers.
    public static readonly Dictionary<string, string[]> Fields =
        Cards.ToDictionary(kv => kv.Key, kv => kv.Value.Names, StringComparer.OrdinalIgnoreCase);

    /// Header for token i of a card: schema name, else "Value i+1".
    public static string Header(string card, int i) =>
        Fields.TryGetValue(card, out var f) && i < f.Length ? f[i] : $"Value {i + 1}";
}
