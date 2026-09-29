using Atb.Core.Sa1;
using Atb.App.Viewer;

namespace Atb.App;

static class Program
{
    /// ATB [deck.lin]            open the deck
    /// ATB --smoke [deck] [sa1]  construct the main window (and the viewer on the .sa1) without showing them; exit 0
    [STAThread]
    static int Main(string[] args)
    {
        ApplicationConfiguration.Initialize();
        if (args.Length > 0 && args[0] == "--smoke")
        {
            using var f = new MainForm(args.Length > 1 ? args[1] : null);
            f.CreateControl();
            if (args.Length > 2) { using var v = new AnimationForm(Sa1File.Load(args[2])); v.CreateControl(); }
            return 0;
        }
        Application.Run(new MainForm(args.FirstOrDefault()));
        return 0;
    }
}
