using Atb.Core.Solver;
using Xunit;

namespace Atb.Core.Tests;

public sealed class GebodTests
{
    [Fact]
    public void Answers_PercentilePath_AdultMale_AllDims()
    {
        var r = new GebodRequest("50TH MALE", Subject: 3, Dim: 3,
            Weight: new(3, 50), Height: new(3, 95), HandSeparated: true, DetailedJoint: false);
        Assert.Equal(new[]
        {
            "50TH MALE", // PLEASE ENTER A DESCRIPTION OF THE SUBJECT
            "3",         // ENTER NUMBER CORRESPONDING TO DESIRED SUBJECT TYPE (adult male)
            "3",         // PREDICTING DIMENSION(S): 3 ALL OF THE ABOVE
            "3",         // SELECT UNITS FOR weight: 3 %-TILE
            "50.0",      // ENTER DESIRED PERCENTILE FOR weight
            "3",         // SELECT UNITS FOR height: 3 %-TILE
            "95.0",      // ENTER DESIRED PERCENTILE FOR height
            "2",         // LOWER ARM: 2 FOREARM AND HAND SEPARATED
            "1",         // JOINT PROPERTY: 1 STANDARD JOINT PROPERTY
            "1",         // SELECT UNITS FOR OUTPUT: 1 ENGLSH
        }, Gebod.Answers(r));
    }

    [Fact]
    public void Answers_MeasuredValuesPath_Child_AllDims_MetricOutput()
    {
        var r = new GebodRequest("6 YR CHILD", Subject: 1, Dim: 3,
            Age: new(2, 6), Weight: new(1, 45.5), Height: new(1, 45), MetricOutput: true);
        Assert.Equal(new[]
        {
            "6 YR CHILD", "1",
            "3",          // 3 ALL OF THE ABOVE (child list is 0 AGE .. 3)
            "2", "6.0",   // age: 2 YEARS, value
            "1", "45.5",  // weight: 1 LB., value
            "1", "45.0",  // height: 1 IN., value
            "2",          // output 2 METRIC (no lower-arm/joint prompts for the child)
        }, Gebod.Answers(r));
    }

    [Fact]
    public void Answers_MeasuredValuesPath_UserSupplied_Unit1File()
    {
        var r = new GebodRequest("USER BODY", Subject: 4, DimensionFile: "BODYDIM.DAT", MetricInput: true);
        Assert.Equal(new[]
        {
            "USER BODY", "4",
            "Y",           // HAS THE ABOVE BEEN SATISFIED (Y/N) ?
            "BODYDIM.DAT", // FULL PATH NAME OF THE FILE CONTAINING THE USER-DEFINED DATA?
            "2",           // input data units: 2 METRIC
            "1",           // output units: 1 ENGLSH
        }, Gebod.Answers(r));
    }

    [Fact]
    public void Answers_SingleDim_AndDummy()
    {
        Assert.Equal(new[] { "F", "2", "1", "2", "600.0", "1", "1", "1" },
            Gebod.Answers(new GebodRequest("F", 2, Dim: 1, Weight: new(2, 600))));
        Assert.Equal(new[] { "HYBRID III", "5", "2" }, Gebod.Answers(new GebodRequest("HYBRID III", 5, MetricOutput: true)));
    }

    [Theory]
    [InlineData(3, 0)]    // adults are not offered "0) Age"
    [InlineData(1, 4)]
    public void Answers_RejectsDimNotOffered(int subject, int dim) =>
        Assert.Throws<ArgumentException>(() => Gebod.Answers(new GebodRequest("X", subject, dim, new(1, 5), new(1, 50), new(1, 40))));

    [Theory]
    [InlineData(1.0)]
    [InlineData(100.0)]
    public void Answers_RejectsPercentileTheExeWouldReAsk(double p) =>
        Assert.Throws<ArgumentException>(() => Gebod.Answers(new GebodRequest("X", 2, 1, Weight: new(3, p))));

    [Fact]
    public void Answers_RejectsChildPercentile_AndLongPath()
    {
        Assert.Throws<ArgumentException>(() => Gebod.Answers(new GebodRequest("X", 1, 1, Weight: new(3, 50))));
        Assert.Throws<ArgumentException>(() => Gebod.Answers(new GebodRequest("X", 4, DimensionFile: new string('a', 43))));
    }

    [Fact]
    public void DimensionFileText_ThreeBlankColumnsThenFourLinesOfEightF10()
    {
        var dims = Enumerable.Range(1, 32).Select(i => i * 0.5).ToArray();
        var lines = Gebod.DimensionFileText(dims).Split("\r\n");
        Assert.Equal(5, lines.Length);   // 4 records + trailing empty
        Assert.Equal("          0.5       1.0       1.5       2.0       2.5       3.0       3.5       4.0", lines[0]);
        Assert.Equal("       4.5       5.0       5.5       6.0       6.5       7.0       7.5       8.0", lines[1]);
        Assert.Equal(80, lines[3].Length);
    }

    [Fact]
    public void AtbFig_MatchesInstallerLayout()
    {
        Assert.Equal(" 23 \r\nC:\\Users\\Public\\ATBRun\\\r\n 11 \r\nC:\\Windows\\\r\n", Gebod.AtbFig(@"C:\Users\Public\ATBRun", @"C:\Windows"));
        Assert.Throws<ArgumentException>(() => Gebod.AtbFig(new string('d', 40), "t"));
    }
}
