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

    public static IEnumerable<object[]> AllSa1s() =>
        Fixtures.ClientSa1s().Append(Path.Combine(Fixtures.RepoRoot, "example/sledout.sa1")).Select(p => new object[] { p });

    [Theory, MemberData(nameof(AllSa1s))]
    public void Sa1_Load_StrictlyIncreasingTimesAndOneTransformPerSegmentPerFrame(string path)
    {
        var f = Sa1File.Load(path);
        Assert.True(f.Frames.Count > 1);
        Assert.False(f.Truncated);
        Assert.True(f.NGnd >= f.Segments.Count, "every segment has a frame entry");
        for (int i = 0; i < f.Frames.Count; i++)
        {
            Assert.Equal(f.NGnd * 12, f.Frames[i].Data.Length);
            Assert.All(f.Frames[i].Data, v => Assert.True(double.IsFinite(v)));
            if (i > 0) Assert.True(f.Frames[i].Time > f.Frames[i - 1].Time, $"frame {i} time {f.Frames[i].Time} not after {f.Frames[i - 1].Time}");
        }
    }

    [Fact]
    public void SledExample_BeltStrandsFrame0_LieInsideSledAboveSeat()
    {
        var f = Sa1File.Load(Path.Combine(Fixtures.RepoRoot, "example/sledout.sa1"));
        var strands = f.BeltStrands(0);
        Assert.Equal(new[] { 11, 7 }, strands.Select(s => s.Length).ToArray());
        // Sled box written out from the sled's plane corners in sledout.sa1 (all planes ref entry 16, which is
        // at identity on frame 0): x −7.77..60 (side panels, floor/firewall), y ±12 (floor), z −48.97 (back panels)
        // down to the seat pan's top edge z = −10 (SEAT P0) — belts lie on the occupant, above the seat (z down).
        foreach (var (s, b) in strands.Select((s, b) => (s, b)))
            foreach (var p in s)
            {
                Assert.InRange(p.X, -7.77f, 60f);
                Assert.InRange(p.Y, -12f, 12f);
                Assert.True(p.Z >= -48.97f && p.Z <= -10f, $"strand {b} point {p} z outside sled box −48.97..−10");
            }
    }

    static readonly double[] Times = { 0.0, 0.5, 1.0, 2.0, 4.0 };

    [Fact]
    public void Playback_FirstTime_IsFrame0() => Assert.Equal(0, Playback.FrameAt(Times, 0, 2));

    [Fact]
    public void Playback_LastTime_IsLastFrameAndClamps()
    {
        Assert.Equal(4, Playback.FrameAt(Times, 2.0, 2));    // 2 s wall × 2 = 4 s
        Assert.Equal(4, Playback.FrameAt(Times, 100, 2));
    }

    [Fact]
    public void Playback_MidTime_IsLastFrameAtOrBefore()
    {
        Assert.Equal(2, Playback.FrameAt(Times, 0.75, 2));   // 1.5 s → frame at 1.0
        Assert.Equal(2, Playback.FrameAt(Times, 10, 0.1));   // 1.0 s exactly
        Assert.Equal(1, Playback.FrameAt(Times, 1.5, 0.5));  // 0.75 s → frame at 0.5
    }

    [Fact]
    public void Playback_Case2479_FirstMidLast()
    {
        var times = Sa1File.Load(Path.Combine(Fixtures.RepoRoot, "cases/2479/2479_2.sa1")).Frames.Select(x => x.Time).ToArray();
        Assert.Equal(0, Playback.FrameAt(times, 0, 0.1));
        Assert.Equal(200, Playback.FrameAt(times, 2.005, 1));  // 401 frames, 0.01 s apart
        Assert.Equal(400, Playback.FrameAt(times, 40.5, 0.1));
    }
}
