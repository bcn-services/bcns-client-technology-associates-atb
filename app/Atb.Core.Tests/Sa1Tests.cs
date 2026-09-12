using Atb.Core.Sa1;
using Xunit;

namespace Atb.Core.Tests;

public class Sa1Tests
{
    public static IEnumerable<object[]> ClientSa1s() => Fixtures.ClientSa1s().Select(p => new object[] { p });

    [Fact]
    public void Case2479_ParsesKnownStructure()
    {
        var f = Sa1File.Load(Path.Combine(Fixtures.RepoRoot, "cases/2479/2479_2.sa1"));
        Assert.Equal(17, f.Segments.Count);
        Assert.Equal("RN", f.Segments[0].Name);
        Assert.Equal(9, f.Planes.Count);
        Assert.Equal(9, f.ContactEllipsoids.Count);
        Assert.Null(f.Harness);
        Assert.Equal(19, f.NGnd);
        Assert.Equal(401, f.Frames.Count);
        Assert.False(f.Truncated);
        Assert.Equal(0.0, f.Frames[0].Time);
        Assert.Equal(4.0, f.Frames[^1].Time, 6);
        var p = f.Frames[0].Position(0);
        Assert.Equal(50f, p.X); Assert.Equal(0f, p.Y); Assert.Equal(-17.9899998f, p.Z, 5);
        var m = f.Frames[0].Transform(0);
        Assert.Equal(1f, m.M11); Assert.Equal(1f, m.M22); Assert.Equal(1f, m.M33); Assert.Equal(50f, m.M41);
    }

    [Fact]
    public void SledExample_ParsesBeltsAndPlanes()
    {
        var f = Sa1File.Load(Path.Combine(Fixtures.RepoRoot, "example/sledout.sa1"));
        Assert.Equal(15, f.Segments.Count);
        Assert.Equal(12, f.Planes.Count);
        Assert.Equal("SEAT. 6 DEGREE OFF H", f.Planes[0].Name);
        Assert.Equal(16, f.Planes[0].RefSegment);
        Assert.Equal(3, f.ContactEllipsoids.Count);
        Assert.NotNull(f.Harness);
        Assert.Equal(2, f.Harness!.Belts); Assert.Equal(27, f.Harness.Points);
        Assert.Equal(new[] { 12, 15 }, f.Harness.PointsPerBelt);
        Assert.Equal(17, f.NGnd);
        Assert.True(f.Frames.Count > 1);
        Assert.Equal(0.002, f.Frames[1].Time, 6);
        Assert.Equal(new[] { 11, 7 }, f.Frames[0].NPtPly);
        Assert.False(f.Truncated);
    }

    [Theory, MemberData(nameof(ClientSa1s))]
    public void ClientSa1_ParsesCompletely(string path)
    {
        var f = Sa1File.Load(path);
        Assert.True(f.NGnd >= f.Segments.Count, "NGnd covers all segments");
        Assert.True(f.Frames.Count > 1);
        Assert.False(f.Truncated, "file ends on a frame boundary");
        Assert.True(f.Frames.Zip(f.Frames.Skip(1)).All(t => t.Second.Time > t.First.Time), "time strictly increasing");
    }
}
