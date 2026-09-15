namespace Atb.Core.Sa1;

/// Playback clock: pure mapping from elapsed wall time to a frame. No state; the viewer owns the wall clock.
public static class Playback
{
    /// Last frame whose time ≤ times[0] + wallTime·speed (binary search; times strictly increasing), clamped to [0, n−1].
    public static int FrameAt(IReadOnlyList<double> times, double wallTime, double speed)
    {
        if (times.Count == 0) return -1;
        double t = times[0] + wallTime * speed;
        int lo = 0, hi = times.Count - 1;
        while (lo < hi)
        {
            int mid = (lo + hi + 1) / 2;
            if (times[mid] <= t) lo = mid; else hi = mid - 1;
        }
        return lo;
    }
}
