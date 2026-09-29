using Atb.Core.Cards;
using Atb.Core.Lin;
using Xunit;

namespace Atb.Core.Tests;

/// ATB 3I's cascade warning on segment / joint grid insert and delete (TableForm.cs:412-440).
public class CascadeWarningTests
{
    static string Deck2479 => Fixtures.ClientDecks().Single(p => Path.GetFileName(p) == "2479_2.LIN");

    [Fact]
    public void Texts_AreAtb3IStrings()
    {
        Assert.Equal("You have inserted/deleted segments and this requires CASCADE UPDATE/DELETE\r\nother input cards referring these segments.  Continue?", Renumber.SegmentCascadeText);
        Assert.Equal("Cascade Update of Segment ID Number", Renumber.SegmentCascadeTitle);
        Assert.Equal("You have inserted/deleted joints and this requires CASCADE UPDATE/DELETE\r\nother input cards referring these joints.  Continue?", Renumber.JointCascadeText);
        Assert.Equal("Cascade Update of Joint ID Number", Renumber.JointCascadeTitle);
    }

    [Fact]
    public void No_IsNotConfirmed()
    {
        Assert.False(Renumber.CascadeConfirmed(Entity.Segment, null, (_, _) => false));
        Assert.False(Renumber.CascadeConfirmed(Entity.Joint, "refs", (_, _) => false));
    }

    [Fact]
    public void Asks_3IText_WithDeleteListBelow_OnlyForSegmentsAndJoints()
    {
        var asked = new List<(string Text, string Title)>();
        bool Yes(string t, string ti) { asked.Add((t, ti)); return true; }
        Assert.True(Renumber.CascadeConfirmed(Entity.Segment, null, Yes));
        Assert.True(Renumber.CascadeConfirmed(Entity.Joint, "Joint 2 is still referenced", Yes));
        foreach (var e in new[] { Entity.Plane, Entity.Vehicle, Entity.Actuator }) Assert.True(Renumber.CascadeConfirmed(e, "x", Yes));
        Assert.Equal([(Renumber.SegmentCascadeText, Renumber.SegmentCascadeTitle),
                      (Renumber.JointCascadeText + "\r\n\r\nJoint 2 is still referenced", Renumber.JointCascadeTitle)], asked);
    }

    /// 3I inserts the segment alone: no joint is added, and Validate has no joint-count rule to trip.
    [Fact]
    public void InsertSegment_LeavesJointsAlone_ValidatesClean()
    {
        var d = Deck.Load(Deck2479);
        int joints = d.JointCount, jointCards = Renumber.Count(d, Entity.Joint), segs = d.SegmentCount;
        Renumber.Insert(d, Entity.Segment, 3, Renumber.Copy(d, Entity.Segment, 2));
        Assert.Equal(segs + 1, d.SegmentCount);
        Assert.Equal((joints, jointCards), (d.JointCount, Renumber.Count(d, Entity.Joint)));
        Assert.Empty(d.Validate());
    }
}
