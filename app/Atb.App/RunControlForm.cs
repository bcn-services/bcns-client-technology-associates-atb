// Analysis > Run Control...: ATB 3I's "Run Time Control Parameter Definition" (decomp ATB3I/RunControl.cs), layout from its
// InitializeComponent. Box <-> token mapping is Atb.Core.Cards.RunControl.
using Atb.Core.Cards;
using Atb.Core.Lin;

namespace Atb.App;

public sealed class RunControlForm : Form
{
    /// Working copy: each box writes its one token when left (STANDARDS.md "Sub-editors write as you leave a box"); OK keeps it.
    public Deck Deck { get; }
    readonly TextBox[] boxes = new TextBox[16];
    string entered = "";

    public RunControlForm(Deck src)
    {
        Deck = Deck.Parse(src.Write());
        var text = RunControl.Read(Deck);   // throws when an A card is missing; MainForm reports it
        Text = "Run Time Control Parameter Definition"; ClientSize = new Size(664, 325);
        Font = new Font("Arial", 8.25f, FontStyle.Bold);
        FormBorderStyle = FormBorderStyle.FixedDialog; MaximizeBox = MinimizeBox = false; StartPosition = FormStartPosition.CenterParent;

        // Textbox1-3 with Label1-3 (RunControl.cs:1170-1219, :1348-1388)
        Lbl(this, "Date", 40, 8, 32, 16); Box(this, 0, 80, 8, 89);
        Lbl(this, "Comment1", 8, 40, 72, 24); Box(this, 1, 80, 40, 568);
        Lbl(this, "Comment2", 8, 72, 72, 17); Box(this, 2, 80, 72, 568);
        // four 320x72 groups, three label/box columns each at x 8 / 112 / 216 (Groupbox1, GroupBox2-4)
        Group("Unit Label (4 Characters)", 8, 112, 3, ["Unit of Length", "Unit of Force", "Unit of Time"]);
        Group("Number of Simulation Steps", 336, 112, 6, ["Num of Iteration", "Num of Output", "Output Interval"]);
        Group("Gravity Vector", 8, 200, 9, ["X", "Y", "Z"]);
        Group("Integration Step Size", 336, 200, 12, ["Initial Size", "Maximum Size", "Minimum Size"]);
        Lbl(this, "G", 8, 288, 17, 17); Box(this, 15, 24, 288, 88);   // Label16 / Textbox16

        var def = Btn("Default", 408); def.Click += (_, _) => Defaults();
        var ok = Btn("OK", 496); ok.DialogResult = DialogResult.OK;
        var cancel = Btn("Cancel", 584); cancel.DialogResult = DialogResult.Cancel;
        for (int i = 0; i < 16; i++) boxes[i].Text = text[i];

        void Group(string title, int x, int y, int first, string[] labels)
        {
            var g = new GroupBox { Text = title, Location = new Point(x, y), Size = new Size(320, 72) };
            Controls.Add(g);
            for (int k = 0; k < 3; k++) { Lbl(g, labels[k], 8 + k * 104, 24, 96, 17); Box(g, first + k, 8 + k * 104, 40, 96); }
        }
    }

    static void Lbl(Control p, string text, int x, int y, int w, int h) =>
        p.Controls.Add(new Label { Text = text, Location = new Point(x, y), Size = new Size(w, h) });

    Button Btn(string text, int x)
    {
        var b = new Button { Text = text, Location = new Point(x, 288), Size = new Size(72, 24) };
        Controls.Add(b);
        return b;
    }

    /// One box bound to field i. Textbox7-16 carry 3I's TextBox_Leave number check (RunControl.cs:1899-1910): the warning,
    /// and the text put back.
    void Box(Control p, int i, int x, int y, int w)
    {
        var t = new TextBox { AutoSize = false, Location = new Point(x, y), Size = new Size(w, 19), AccessibleName = RunControl.Fields[i].Name };
        t.Enter += (_, _) => entered = t.Text;
        t.Leave += (_, _) =>
        {
            if (t.Text == entered) return;
            if (RunControl.Set(Deck, i, t.Text) != null)
            {
                MessageBox.Show(this, "Input must be a number!", "Input Warning", MessageBoxButtons.OK, MessageBoxIcon.Exclamation);
                t.Text = entered;
            }
        };
        boxes[i] = t;
        p.Controls.Add(t);
    }

    /// 3I's Default button (btnDefault_Click): all 16 boxes, written through.
    void Defaults()
    {
        var v = RunControl.Defaults(DateTime.Now);
        for (int i = 0; i < 16; i++) { boxes[i].Text = v[i]; RunControl.Set(Deck, i, v[i]); }
    }
}
