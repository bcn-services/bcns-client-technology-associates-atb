// Model > Body... > Body Summary...: ATB 3I's "Body Editing Form" (decomp ATB3I/Body.cs) — General Description, the body
// table, and 3I's seven buttons in 3I's layout, each with 3I's message and buttons.
using Atb.Core.Cards;
using Atb.Core.Lin;

namespace Atb.App;

public sealed class BodyForm : Form
{
    // ATB 3I's messages (Body.cs line numbers); the GEBOD ones are GebodForm's (:990, :1019, :1049).
    public const string InsertCopiedText = "Insert a new copied body before the selected body?\r\nClick NO button will add copied body after the selected body.\r\nATB 3I will cascade update other input cards for segment numbering.\r\nYou can't undo this operation once it proceeds.";   // :627
    public const string AddCopiedText = "Add a new copied body?  ATB 3I will cascade update other input cards for\r\nsegment numbering.  You can't undo this operation once it proceeds.";   // :665
    public const string DeleteText = "You are about to delete the selected body.  ATB 3I will CASCADE DELETE\r\nother input cards referring segments of this body.\r\nYou can't undo this operation once it proceeds.  Continue?";   // :756
    public const string ReplaceCopiedText = "You are about to replace the selected body with data from a copied body.  ATB3I will\r\nADJUST this body's segment numbers referred on other cards for the difference between\r\nreplaced and new bodies.  You can't undo this operation once it proceeds.  Continue?";   // :860
    const string NoRow = "No record/row selected for this operation.", NoClip = "Clipboard doesn't contain any data.";

    /// The deck after the operations done here: 3I writes each one at once ("You can't undo this operation").
    public Deck Deck { get; private set; }
    public bool Changed { get; private set; }
    /// What Copy Body holds (3I's clipboard); MainForm keeps it between openings of the form.
    public Bodies.Copied? Clip { get; private set; }
    /// Set by the GEBOD buttons: the form closes and MainForm opens the GEBOD form at this placement (as 3I does).
    public GebodPlacement? Gebod { get; private set; }

    // 3I's layout (Body.cs InitializeComponent): label (8,8), title (136,8) 150x20, grid (3,40) 290x240,
    // buttons 192x24 at x 296, y 8 / 48 / 88 / 128 / 168 / 208 / 248, client 496x278.
    readonly TextBox title = new() { Location = new Point(136, 8), Size = new Size(150, 20), AccessibleName = "General Description" };
    readonly DataGridView grid = new()
    {
        Location = new Point(3, 40), Size = new Size(290, 236), ReadOnly = true, AllowUserToAddRows = false, AllowUserToDeleteRows = false, MultiSelect = false,
        SelectionMode = DataGridViewSelectionMode.FullRowSelect, RowHeadersVisible = false, AutoSizeColumnsMode = DataGridViewAutoSizeColumnsMode.Fill,
    };
    readonly List<Button> needBody = [];

    public BodyForm(Deck deck, Bodies.Copied? clip)
    {
        Deck = deck; Clip = clip;
        Text = "Body Editing Form"; ClientSize = new Size(496, 278); FormBorderStyle = FormBorderStyle.FixedDialog;
        MaximizeBox = MinimizeBox = false; StartPosition = FormStartPosition.CenterParent;
        foreach (var h in new[] { "BodyID", "Number of Seg", "Number of Jnt" }) grid.Columns.Add(h, h);
        Controls.Add(new Label { Text = "General Description", Location = new Point(8, 8), Size = new Size(128, 16), ForeColor = Color.Green, Font = new Font(Font, FontStyle.Bold) });
        Controls.Add(title); Controls.Add(grid);
        Btn(8, "Copy Body", CopyBody, true);
        Btn(48, "Add/Insert Copied Body", AddCopied, false);
        Btn(88, "Replace Body with Copied Body", ReplaceCopied, true);
        Btn(128, "Add/Insert Body Using GEBOD", GebodAdd, false);
        Btn(168, "Replace Body Using GEBOD", GebodReplace, true);
        Btn(208, "Delete Body", DeleteBody, true);
        Btn(248, "Save && Exit", SaveExit, false);
        title.Text = Deck.Card("B.1") is { Count: 4 } b1 ? b1.Str(2) : "";
        Fill();
    }

    void Btn(int y, string text, Action act, bool needsBody)
    {
        var b = new Button { Text = text, Location = new Point(296, y), Size = new Size(192, 24) };
        b.Click += (_, _) => act();
        Controls.Add(b);
        if (needsBody) needBody.Add(b);
    }

    int Bodies_ => grid.Rows.Count;
    int Selected => grid.CurrentRow?.Index + 1 ?? 0;

    /// 3I FillBodyTable; with no body, Copy / Replace / GEBOD Replace / Delete are disabled.
    void Fill()
    {
        grid.Rows.Clear();
        foreach (var r in Bodies.Summary(Deck)) grid.Rows.Add(r.Body, r.Segments, r.Joints);
        foreach (var b in needBody) b.Enabled = grid.Rows.Count > 0;
    }

    void Warn(string text, string title) => MessageBox.Show(this, text, title, MessageBoxButtons.OK, MessageBoxIcon.Exclamation);
    DialogResult Ask(string text, string title, MessageBoxButtons b) => MessageBox.Show(this, text, title, b, MessageBoxIcon.Question);

    void Apply(Func<Deck> op, string title)
    {
        try { Deck = op(); Changed = true; }
        catch (Exception ex) when (ex is InvalidOperationException or NotSupportedException or ArgumentOutOfRangeException)
        { MessageBox.Show(this, ex.Message, title, MessageBoxButtons.OK, MessageBoxIcon.Error); }
        Fill();
    }

    void CopyBody()
    {
        if (Selected == 0) { Warn(NoRow, "Copy Body Operation Warning"); return; }
        Clip = Bodies.Copy(Deck, Selected);
    }

    /// :627 with bodies (Yes = before the selected body, No = after it), :665 on a deck with none.
    GebodPlacement? Where(string insertText, string addText, string title)
    {
        if (Bodies_ == 0) return Ask(addText, title, MessageBoxButtons.OKCancel) == DialogResult.OK ? new(GebodMode.Add) : null;
        if (Selected == 0) { Warn(NoRow, "Add/Insert Body Operation Warning"); return null; }
        return Ask(insertText, title, MessageBoxButtons.YesNoCancel) switch
        {
            DialogResult.Yes => new(GebodMode.InsertBefore, Selected),
            DialogResult.No => new(GebodMode.InsertAfter, Selected),
            _ => null,
        };
    }

    void AddCopied()
    {
        if (Clip is not { } c) { Warn(NoClip, "Add/Insert Body Operation Warning"); return; }
        if (Where(InsertCopiedText, AddCopiedText, "Add/Insert Copied Body") is { } p) Apply(() => Bodies.Insert(Deck, c, p), "Add/Insert Copied Body");
    }

    void ReplaceCopied()
    {
        if (Selected == 0) { Warn(NoRow, "Replace Body Operation Warning"); return; }
        if (Clip is not { } c) { Warn(NoClip, "Replace Body Operation Warning"); return; }
        int k = Selected;
        if (Ask(ReplaceCopiedText, "Replace Body", MessageBoxButtons.YesNo) == DialogResult.Yes) Apply(() => Bodies.Replace(Deck, k, c), "Replace Body");
    }

    void DeleteBody()
    {
        if (Selected == 0) { Warn(NoRow, "Delete Body Operation Warning"); return; }
        int k = Selected;
        if (Ask(DeleteText, "Delete Body", MessageBoxButtons.YesNo) != DialogResult.Yes) return;
        bool held = Clip is { } c && c.First == GebodMerge.BodyStarts(Deck)[k - 1];
        Apply(() => Bodies.Delete(Deck, k), "Delete Body");
        if (held) Clip = null;                                     // 3I clears the clipboard when it held this body
    }

    void GebodAdd()
    {
        if (Where(GebodForm.InsertText, GebodForm.AddText, "Add/Insert Body Using GEBOD") is { } p) { Gebod = p; Close(); }
    }

    void GebodReplace()
    {
        if (Selected == 0) { Warn(NoRow, "Replace Body Operation Warning"); return; }
        if (Ask(GebodForm.ReplaceText, "Replace Body Using GEBOD", MessageBoxButtons.YesNo) == DialogResult.Yes) { Gebod = new(GebodMode.Replace, Selected); Close(); }
    }

    void SaveExit()
    {
        if (Deck.Card("B.1") is { Count: 4 } b1 && b1.Str(2) != title.Text) { b1.SetStr(2, title.Text); Changed = true; }
        DialogResult = DialogResult.OK;
    }
}
