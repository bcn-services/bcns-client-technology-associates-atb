using System.Windows;
using System.Windows.Controls;
using System.Windows.Media.Media3D;
using Atb.Core.Sa1;
using Brushes = System.Windows.Media.Brushes;
using Color = System.Windows.Media.Color;
using Colors = System.Windows.Media.Colors;
using Int32Collection = System.Windows.Media.Int32Collection;
using Mat = System.Numerics.Matrix4x4;
using MouseEventArgs = System.Windows.Input.MouseEventArgs;
using Point = System.Windows.Point;
using SolidColorBrush = System.Windows.Media.SolidColorBrush;
using Vec = System.Numerics.Vector3;

namespace Atb.App.Viewer;

/// WPF Viewport3D scene for one .sa1. Conventions copied from ATB 3I (Animation.cs / FileManager.cs):
/// ATB world → view via the fixed remap (x,y,z)→(x,−z,y) (z-down → y-up); every entry's 12 numbers
/// are position + row-vector DCM, so local→world is System.Numerics Vector3.Transform / Matrix3D as-is.
public sealed class Sa1Scene
{
    public readonly Border Root = new() { Background = Brushes.White };
    public readonly List<(string Name, Model3D Model)> Objects = new();
    /// Entry index (0-based) whose position the camera follows; −1 = fixed.
    public int CameraSegment = -1;

    readonly Sa1File sa1;
    readonly Viewport3D viewport = new();
    readonly Model3DGroup root;
    readonly MatrixTransform3D[] entry;
    readonly Model3DGroup[] entryGroup;
    readonly Dictionary<Model3D, Model3DGroup> parentOf = new();
    readonly List<MeshGeometry3D> belts = new();
    readonly PerspectiveCamera cam = new() { FieldOfView = 45, UpDirection = new Vector3D(0, 1, 0) };
    Point3D target; double dist = 100, yaw = 0.7, pitch = 0.3, beltR = 0.3;
    Point lastMouse; int frame;

    static readonly Matrix3D Axis = new(1, 0, 0, 0, 0, 0, 1, 0, 0, -1, 0, 0, 0, 0, 0, 1);
    static readonly Color[] Palette =
    [
        Color.FromRgb(200, 60, 60), Color.FromRgb(60, 120, 200), Color.FromRgb(60, 170, 90), Color.FromRgb(220, 160, 40),
        Color.FromRgb(150, 80, 190), Color.FromRgb(40, 170, 180), Color.FromRgb(190, 110, 60), Color.FromRgb(120, 120, 120),
    ];

    public Sa1Scene(Sa1File file)
    {
        sa1 = file;
        int n = file.NGnd;
        entry = new MatrixTransform3D[n]; entryGroup = new Model3DGroup[n];
        root = new Model3DGroup { Transform = new MatrixTransform3D(Axis) };
        root.Children.Add(new AmbientLight(Color.FromRgb(90, 90, 90)));
        root.Children.Add(new DirectionalLight(Colors.White, new Vector3D(-1, 1, -2)));
        root.Children.Add(new DirectionalLight(Color.FromRgb(120, 120, 120), new Vector3D(1, -1, 1)));

        var sphere = Sphere();
        // Contact ellipsoid whose Id1 names a segment replaces that segment's own ellipsoid (ATB 3I replaceSeg).
        var replaced = file.ContactEllipsoids.Where(c => c.Id1 >= 1 && c.Id1 <= n).Select(c => c.Id1 - 1).ToHashSet();
        for (int i = 0; i < n; i++)
        {
            entry[i] = new MatrixTransform3D();
            entryGroup[i] = new Model3DGroup { Transform = entry[i] };
            root.Children.Add(entryGroup[i]);
            if (i >= file.Segments.Count || replaced.Contains(i)) continue;
            var s = file.Segments[i];
            var g = new GeometryModel3D(sphere, Solid(Palette[i % Palette.Length]));
            g.Transform = new Transform3DGroup { Children = { Scale(s.SemiAxes), Translate(s.Offset) } };
            Add(entryGroup[i], g, s.Name.Trim());
        }
        foreach (var c in file.ContactEllipsoids)
        {
            int att = c.Id1 >= 1 && c.Id1 <= n ? c.Id1 : c.Id0;     // 1-based, as ATB 3I reads them
            if (att < 1 || att > n) continue;
            var g = new GeometryModel3D(Sphere(c.Power), Solid(Color.FromRgb(230, 120, 120)));
            // Same as ATB 3I UISub.MakeCntacElipXFrm: roll about x, then pitch about y, then yaw about z, then offset (degrees).
            g.Transform = new Transform3DGroup
            {
                Children =
                {
                    Scale(c.SemiAxes),
                    new RotateTransform3D(new AxisAngleRotation3D(new Vector3D(1, 0, 0), c.Ypr.Z)),
                    new RotateTransform3D(new AxisAngleRotation3D(new Vector3D(0, 1, 0), c.Ypr.Y)),
                    new RotateTransform3D(new AxisAngleRotation3D(new Vector3D(0, 0, 1), c.Ypr.X)),
                    Translate(c.Offset),
                },
            };
            Add(entryGroup[att - 1], g, c.Name.Trim());
        }
        foreach (var p in file.Planes)
        {
            var mesh = new MeshGeometry3D();
            foreach (var v in new[] { p.P0, p.P1, p.P3, p.P2 }) mesh.Positions.Add(P(v));
            mesh.TriangleIndices = new Int32Collection([0, 1, 2, 0, 2, 3]);
            var m = Solid(Color.FromArgb(160, 150, 160, 180));
            var g = new GeometryModel3D(mesh, m) { BackMaterial = m };
            int r = p.RefSegment - 1;
            Add(r >= 0 && r < n ? entryGroup[r] : root, g, p.Name.Trim());
        }
        if (file.Harness is { } h)
            for (int b = 0; b < h.Belts; b++)
            {
                var mesh = new MeshGeometry3D();
                var m = Solid(Color.FromRgb(40, 40, 40));
                var g = new GeometryModel3D(mesh, m) { BackMaterial = m };
                belts.Add(mesh);
                Add(root, g, $"Belt {b + 1}");
            }

        viewport.Camera = cam;
        viewport.Children.Add(new ModelVisual3D { Content = root });
        Root.Child = viewport;
        Root.MouseLeftButtonDown += (_, e) => { lastMouse = e.GetPosition(Root); Root.CaptureMouse(); };
        Root.MouseLeftButtonUp += (_, _) => Root.ReleaseMouseCapture();
        Root.MouseMove += OnMouseMove;
        Root.MouseWheel += (_, e) => { dist *= e.Delta > 0 ? 0.85 : 1.18; UpdateCamera(); };

        ViewAll();
        if (file.Frames.Count > 0) SetFrame(0);
    }

    public void SetFrame(int i)
    {
        frame = i;
        var f = sa1.Frames[i];
        for (int e = 0; e < entry.Length; e++) entry[e].Matrix = M3D(f.Transform(e));
        if (sa1.Harness is { } h && f.Bar != null && f.Nl != null && f.NPtPly != null)
        {
            var world = new Point3D[h.Points];
            for (int k = 0; k < h.Points; k++)
            {
                int seg = h.Ibar[2 * k] - 1;
                var local = new Vec((float)(f.Bar[9 * k + 3] + f.Bar[9 * k + 6]), (float)(f.Bar[9 * k + 4] + f.Bar[9 * k + 7]), (float)(f.Bar[9 * k + 5] + f.Bar[9 * k + 8]));
                world[k] = P(seg >= 0 && seg < entry.Length ? Vec.Transform(local, f.Transform(seg)) : local);
            }
            int np = 0;
            for (int b = 0; b < belts.Count; b++)
            {
                var mesh = belts[b];
                mesh.Positions.Clear(); mesh.TriangleIndices.Clear();
                Point3D? prev = null;
                for (int j = 0; j < f.NPtPly[b] && np < f.Nl.Length / 2; j++, np++)
                {
                    int idx = f.Nl[2 * np] - 1;
                    if (idx < 0 || idx >= world.Length) continue;
                    if (prev is { } a) AddTube(mesh, a, world[idx], beltR);
                    prev = world[idx];
                }
            }
        }
        if (CameraSegment >= 0) UpdateCamera();
    }

    public void SetVisible(int index, bool visible)
    {
        var (_, m) = Objects[index];
        var parent = parentOf[m];
        if (visible && !parent.Children.Contains(m)) parent.Children.Add(m);
        else if (!visible) parent.Children.Remove(m);
    }

    public void ViewAll()
    {
        if (sa1.Frames.Count == 0) return;
        var f = sa1.Frames[0];
        var pts = Enumerable.Range(0, entry.Length).Select(i => View(P(f.Position(i)))).ToList();
        var lo = new Point3D(pts.Min(p => p.X), pts.Min(p => p.Y), pts.Min(p => p.Z));
        var hi = new Point3D(pts.Max(p => p.X), pts.Max(p => p.Y), pts.Max(p => p.Z));
        double semi = sa1.Segments.Count == 0 ? 1 : sa1.Segments.Max(s => Math.Max(s.SemiAxes.X, Math.Max(s.SemiAxes.Y, s.SemiAxes.Z)));
        target = new Point3D((lo.X + hi.X) / 2, (lo.Y + hi.Y) / 2, (lo.Z + hi.Z) / 2);
        double radius = Math.Max((hi - lo).Length / 2 + semi, 1);
        dist = radius * 2.6; beltR = Math.Max(0.05, radius * 0.006);
        UpdateCamera();
    }

    void UpdateCamera()
    {
        var c = target;
        if (CameraSegment >= 0 && CameraSegment < entry.Length && frame < sa1.Frames.Count)
            c = View(P(sa1.Frames[frame].Position(CameraSegment)));   // ponytail: follows position only; ATB 3I also rotates with the segment
        var dir = new Vector3D(Math.Cos(pitch) * Math.Sin(yaw), Math.Sin(pitch), Math.Cos(pitch) * Math.Cos(yaw));
        cam.Position = c + dir * dist;
        cam.LookDirection = -dir;
    }

    void OnMouseMove(object sender, MouseEventArgs e)
    {
        if (!Root.IsMouseCaptured) return;
        var p = e.GetPosition(Root);
        yaw -= (p.X - lastMouse.X) * 0.01;
        pitch = Math.Clamp(pitch + (p.Y - lastMouse.Y) * 0.01, -1.5, 1.5);
        lastMouse = p;
        UpdateCamera();
    }

    void Add(Model3DGroup parent, Model3D m, string name) { parent.Children.Add(m); parentOf[m] = parent; Objects.Add((name, m)); }

    static Point3D View(Point3D atb) => Axis.Transform(atb);
    static Point3D P(Vec v) => new(v.X, v.Y, v.Z);
    static ScaleTransform3D Scale(Vec v) => new(v.X, v.Y, v.Z);
    static TranslateTransform3D Translate(Vec v) => new(v.X, v.Y, v.Z);
    static DiffuseMaterial Solid(Color c) => new(new SolidColorBrush(c));
    static Matrix3D M3D(Mat m) => new(m.M11, m.M12, m.M13, m.M14, m.M21, m.M22, m.M23, m.M24, m.M31, m.M32, m.M33, m.M34, m.M41, m.M42, m.M43, m.M44);

    /// Unit superquadric, as ATB 3I UISub.MakeHyperElip: p_i = sign(u_i)·|u_i|^(2/n_i) with u on the unit sphere;
    /// power (2,2,2) is the plain sphere. A zero y/z power falls back to the x power, as the original does.
    static MeshGeometry3D Sphere(Vec? power = null, int slices = 24, int stacks = 12)
    {
        var n = power ?? new Vec(2, 2, 2);
        if (n.Y == 0) n.Y = n.X; if (n.Z == 0) n.Z = n.X;
        if (n.X <= 0) n = new Vec(2, 2, 2);
        static double Sq(double u, double e) => Math.Sign(u) * Math.Pow(Math.Abs(u), 2 / e);
        var m = new MeshGeometry3D();
        for (int i = 0; i <= stacks; i++)
        {
            double phi = Math.PI * i / stacks, y = Math.Cos(phi), r = Math.Sin(phi);
            for (int j = 0; j <= slices; j++)
            {
                double th = 2 * Math.PI * j / slices;
                var nrm = new Vector3D(r * Math.Cos(th), y, r * Math.Sin(th));
                m.Positions.Add(new Point3D(Sq(nrm.X, n.X), Sq(nrm.Y, n.Y), Sq(nrm.Z, n.Z))); m.Normals.Add(nrm);
            }
        }
        for (int i = 0; i < stacks; i++)
            for (int j = 0; j < slices; j++)
            {
                int a = i * (slices + 1) + j, b = a + slices + 1;
                m.TriangleIndices.Add(a); m.TriangleIndices.Add(a + 1); m.TriangleIndices.Add(b);
                m.TriangleIndices.Add(a + 1); m.TriangleIndices.Add(b + 1); m.TriangleIndices.Add(b);
            }
        m.Freeze();
        return m;
    }

    static void AddTube(MeshGeometry3D mesh, Point3D a, Point3D b, double r)
    {
        var d = b - a; if (d.Length < 1e-9) return; d.Normalize();
        var u = Vector3D.CrossProduct(d, Math.Abs(d.Y) < 0.9 ? new Vector3D(0, 1, 0) : new Vector3D(1, 0, 0)); u.Normalize();
        var v = Vector3D.CrossProduct(d, u);
        int b0 = mesh.Positions.Count;
        foreach (var p in new[] { a, b })
            foreach (var (s, t) in new[] { (1, 0), (0, 1), (-1, 0), (0, -1) }) mesh.Positions.Add(p + (u * s + v * t) * r);
        for (int k = 0; k < 4; k++)
        {
            int k2 = (k + 1) % 4;
            mesh.TriangleIndices.Add(b0 + k); mesh.TriangleIndices.Add(b0 + 4 + k); mesh.TriangleIndices.Add(b0 + 4 + k2);
            mesh.TriangleIndices.Add(b0 + k); mesh.TriangleIndices.Add(b0 + 4 + k2); mesh.TriangleIndices.Add(b0 + k2);
        }
    }
}
