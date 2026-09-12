// Win32 interop used to drive the QuickWin solver window. C# 5 (built-in .NET Framework 4.8 csc).
using System;
using System.Collections.Generic;
using System.Runtime.InteropServices;
using System.Text;

namespace ATBRunner
{
    public static class Win32
    {
        public delegate bool EnumWindowsProc(IntPtr hWnd, IntPtr lParam);

        [DllImport("user32.dll")] public static extern bool EnumWindows(EnumWindowsProc cb, IntPtr lParam);
        [DllImport("user32.dll")] public static extern bool EnumChildWindows(IntPtr hWndParent, EnumWindowsProc cb, IntPtr lParam);
        [DllImport("user32.dll")] public static extern uint GetWindowThreadProcessId(IntPtr hWnd, out uint pid);
        [DllImport("user32.dll", CharSet = CharSet.Auto)] public static extern int GetClassName(IntPtr hWnd, StringBuilder sb, int max);
        [DllImport("user32.dll", CharSet = CharSet.Auto)] public static extern int GetWindowText(IntPtr hWnd, StringBuilder sb, int max);
        [DllImport("user32.dll")] public static extern bool IsWindowVisible(IntPtr hWnd);
        [DllImport("user32.dll")] public static extern bool IsWindow(IntPtr hWnd);
        [DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr hWnd, out RECT r);
        [DllImport("user32.dll")] public static extern IntPtr GetParent(IntPtr hWnd);
        [DllImport("user32.dll")] public static extern IntPtr GetForegroundWindow();
        [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr hWnd);
        [DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr hWnd, int cmd);
        [DllImport("user32.dll")] public static extern bool BringWindowToTop(IntPtr hWnd);
        [DllImport("user32.dll")] public static extern IntPtr SetFocus(IntPtr hWnd);
        [DllImport("user32.dll")] public static extern bool AttachThreadInput(uint idAttach, uint idAttachTo, bool fAttach);
        [DllImport("kernel32.dll")] public static extern uint GetCurrentThreadId();
        [DllImport("user32.dll", CharSet = CharSet.Auto)] public static extern bool PostMessage(IntPtr hWnd, uint msg, IntPtr wParam, IntPtr lParam);
        [DllImport("user32.dll", CharSet = CharSet.Auto)] public static extern IntPtr SendMessage(IntPtr hWnd, uint msg, IntPtr wParam, IntPtr lParam);
        [DllImport("user32.dll", CharSet = CharSet.Auto)] public static extern IntPtr SendMessageTimeout(IntPtr hWnd, uint msg, IntPtr wParam, IntPtr lParam, uint flags, uint timeout, out IntPtr result);
        [DllImport("user32.dll")] public static extern bool GetGUIThreadInfo(uint idThread, ref GUITHREADINFO gui);
        [DllImport("user32.dll")] public static extern uint SendInput(uint n, INPUT[] inputs, int size);
        [DllImport("user32.dll")] public static extern IntPtr GetDlgItem(IntPtr hDlg, int id);
        [DllImport("user32.dll")] public static extern bool IsIconic(IntPtr hWnd);
        [DllImport("user32.dll")] public static extern bool AllowSetForegroundWindow(int pid);
        [DllImport("user32.dll")] public static extern bool BlockInput(bool block);

        [DllImport("kernel32.dll", SetLastError = true)] public static extern bool AttachConsole(int pid);
        [DllImport("kernel32.dll", SetLastError = true)] public static extern bool FreeConsole();
        [DllImport("kernel32.dll", SetLastError = true)] public static extern bool AllocConsole();
        [DllImport("kernel32.dll", SetLastError = true, CharSet = CharSet.Auto)]
        public static extern IntPtr CreateFile(string name, uint access, uint share, IntPtr sec, uint disp, uint flags, IntPtr tmpl);
        [DllImport("kernel32.dll", SetLastError = true)] public static extern bool WriteConsoleInput(IntPtr h, INPUT_RECORD[] recs, uint n, out uint written);
        [DllImport("kernel32.dll", SetLastError = true)] public static extern bool CloseHandle(IntPtr h);
        [DllImport("kernel32.dll")] public static extern uint WTSGetActiveConsoleSessionId();
        [DllImport("kernel32.dll")] public static extern bool ProcessIdToSessionId(uint pid, out uint sid);

        public const uint WM_CHAR = 0x0102, WM_KEYDOWN = 0x0100, WM_KEYUP = 0x0101, WM_COMMAND = 0x0111, WM_CLOSE = 0x0010,
                          WM_GETTEXT = 0x000D, WM_GETTEXTLENGTH = 0x000E, BM_CLICK = 0x00F5, WM_SYSCOMMAND = 0x0112;
        public const int IDYES = 6, IDOK = 1, IDNO = 7, SW_RESTORE = 9, SW_SHOW = 5, SW_SHOWNORMAL = 1;
        public const uint SMTO_ABORTIFHUNG = 0x0002;
        public const ushort VK_RETURN = 0x0D;
        public const uint KEYEVENTF_KEYUP = 0x0002, KEYEVENTF_UNICODE = 0x0004, INPUT_KEYBOARD = 1;
        public const uint GENERIC_READ = 0x80000000, GENERIC_WRITE = 0x40000000, FILE_SHARE_READ = 1, FILE_SHARE_WRITE = 2, OPEN_EXISTING = 3;

        [StructLayout(LayoutKind.Sequential)] public struct RECT { public int Left, Top, Right, Bottom; }
        [StructLayout(LayoutKind.Sequential)]
        public struct GUITHREADINFO
        {
            public int cbSize; public int flags; public IntPtr hwndActive, hwndFocus, hwndCapture, hwndMenuOwner, hwndMoveSize, hwndCaret; public RECT rcCaret;
        }
        [StructLayout(LayoutKind.Sequential)] public struct KEYBDINPUT { public ushort wVk, wScan; public uint dwFlags, time; public IntPtr dwExtraInfo; }
        [StructLayout(LayoutKind.Sequential)] public struct MOUSEINPUT { public int dx, dy; public uint mouseData, dwFlags, time; public IntPtr dwExtraInfo; }
        [StructLayout(LayoutKind.Explicit)] public struct INPUTUNION { [FieldOffset(0)] public MOUSEINPUT mi; [FieldOffset(0)] public KEYBDINPUT ki; }
        // Sequential + union: the CLR computes the platform-correct offset (4 on x86, 8 on x64)
        [StructLayout(LayoutKind.Sequential)] public struct INPUT { public uint type; public INPUTUNION u; }
        // INPUT_RECORD for WriteConsoleInput (KEY_EVENT_RECORD only)
        [StructLayout(LayoutKind.Explicit, Size = 20)]
        public struct INPUT_RECORD
        {
            [FieldOffset(0)] public ushort EventType;
            [FieldOffset(4)] public int bKeyDown;
            [FieldOffset(8)] public ushort wRepeatCount;
            [FieldOffset(10)] public ushort wVirtualKeyCode;
            [FieldOffset(12)] public ushort wVirtualScanCode;
            [FieldOffset(14)] public char UnicodeChar;
            [FieldOffset(16)] public uint dwControlKeyState;
        }

        public class WinInfo
        {
            public IntPtr H; public IntPtr Parent; public string Class; public string Title; public bool Visible; public RECT R; public int Depth; public uint Tid;
            public override string ToString()
            {
                return string.Format("hwnd=0x{0:X} parent=0x{1:X} depth={2} class=\"{3}\" title=\"{4}\" vis={5} rect=({6},{7},{8},{9}) tid={10}",
                    H.ToInt64(), Parent.ToInt64(), Depth, Class, Title, Visible, R.Left, R.Top, R.Right, R.Bottom, Tid);
            }
        }

        public static string ClassOf(IntPtr h) { var sb = new StringBuilder(256); GetClassName(h, sb, 256); return sb.ToString(); }
        public static string TitleOf(IntPtr h) { var sb = new StringBuilder(512); GetWindowText(h, sb, 512); return sb.ToString(); }

        public static WinInfo Info(IntPtr h, int depth)
        {
            var w = new WinInfo(); w.H = h; w.Parent = GetParent(h); w.Class = ClassOf(h); w.Title = TitleOf(h); w.Visible = IsWindowVisible(h); w.Depth = depth;
            GetWindowRect(h, out w.R); uint pid; w.Tid = GetWindowThreadProcessId(h, out pid); return w;
        }

        public static List<WinInfo> TopWindowsOf(int pid)
        {
            var list = new List<WinInfo>();
            EnumWindows(delegate(IntPtr h, IntPtr lp) { uint p; GetWindowThreadProcessId(h, out p); if (p == pid) list.Add(Info(h, 0)); return true; }, IntPtr.Zero);
            return list;
        }

        public static List<WinInfo> AllWindowsOf(int pid)
        {
            var list = new List<WinInfo>();
            foreach (var t in TopWindowsOf(pid)) { list.Add(t); AddChildren(t.H, 1, list); }
            return list;
        }

        static void AddChildren(IntPtr parent, int depth, List<WinInfo> list)
        {
            var kids = new List<IntPtr>();
            EnumChildWindows(parent, delegate(IntPtr h, IntPtr lp) { if (GetParent(h) == parent) kids.Add(h); return true; }, IntPtr.Zero);
            foreach (var k in kids) { list.Add(Info(k, depth)); AddChildren(k, depth + 1, list); }
        }

        public static IntPtr FocusWindowOfThread(uint tid)
        {
            var g = new GUITHREADINFO(); g.cbSize = Marshal.SizeOf(typeof(GUITHREADINFO));
            if (!GetGUIThreadInfo(tid, ref g)) return IntPtr.Zero;
            return g.hwndFocus;
        }
        public static IntPtr ActiveWindowOfThread(uint tid)
        {
            var g = new GUITHREADINFO(); g.cbSize = Marshal.SizeOf(typeof(GUITHREADINFO));
            if (!GetGUIThreadInfo(tid, ref g)) return IntPtr.Zero;
            return g.hwndActive;
        }

        // ---- keystroke delivery primitives ----
        public static void PostChar(IntPtr h, char c)
        {
            PostMessage(h, WM_CHAR, (IntPtr)c, (IntPtr)1);
        }
        public static void PostKeyAndChar(IntPtr h, char c)
        {
            // WM_KEYDOWN(vk) + WM_CHAR + WM_KEYUP(vk); vk from the char (letters/digits upper-case VK codes)
            ushort vk = (c == '\r') ? VK_RETURN : (ushort)char.ToUpperInvariant(c);
            uint scan = MapVirtualKey(vk, 0);
            PostMessage(h, WM_KEYDOWN, (IntPtr)vk, (IntPtr)(1 | (scan << 16)));
            PostMessage(h, WM_CHAR, (IntPtr)c, (IntPtr)(1 | (scan << 16)));
            PostMessage(h, WM_KEYUP, (IntPtr)vk, (IntPtr)unchecked((int)(0xC0000001u | (scan << 16))));
        }
        [DllImport("user32.dll")] public static extern uint MapVirtualKey(uint code, uint mapType);

        public static int InputSize { get { return Marshal.SizeOf(typeof(INPUT)); } }

        public static void SendInputText(string s)
        {
            var list = new List<INPUT>();
            foreach (char c in s)
            {
                if (c == '\r')
                {
                    var d = new INPUT(); d.type = INPUT_KEYBOARD; d.u.ki.wVk = VK_RETURN; d.u.ki.wScan = (ushort)MapVirtualKey(VK_RETURN, 0); list.Add(d);
                    var u = d; u.u.ki.dwFlags = KEYEVENTF_KEYUP; list.Add(u);
                }
                else
                {
                    var d = new INPUT(); d.type = INPUT_KEYBOARD; d.u.ki.wScan = c; d.u.ki.dwFlags = KEYEVENTF_UNICODE; list.Add(d);
                    var u = d; u.u.ki.dwFlags = KEYEVENTF_UNICODE | KEYEVENTF_KEYUP; list.Add(u);
                }
            }
            var arr = list.ToArray();
            SendInput((uint)arr.Length, arr, InputSize);
        }

        public static bool WriteConIn(string s, out string err)
        {
            err = "";
            IntPtr h = CreateFile("CONIN$", GENERIC_READ | GENERIC_WRITE, FILE_SHARE_READ | FILE_SHARE_WRITE, IntPtr.Zero, OPEN_EXISTING, 0, IntPtr.Zero);
            if (h == IntPtr.Zero || h.ToInt64() == -1) { err = "CreateFile(CONIN$) failed, gle=" + Marshal.GetLastWin32Error(); return false; }
            var recs = new List<INPUT_RECORD>();
            foreach (char c in s)
            {
                ushort vk = (c == '\r') ? VK_RETURN : (ushort)char.ToUpperInvariant(c);
                var d = new INPUT_RECORD(); d.EventType = 1; d.bKeyDown = 1; d.wRepeatCount = 1; d.wVirtualKeyCode = vk; d.wVirtualScanCode = (ushort)MapVirtualKey(vk, 0); d.UnicodeChar = c; recs.Add(d);
                var u = d; u.bKeyDown = 0; recs.Add(u);
            }
            uint written; bool ok = WriteConsoleInput(h, recs.ToArray(), (uint)recs.Count, out written);
            if (!ok) err = "WriteConsoleInput failed, gle=" + Marshal.GetLastWin32Error();
            CloseHandle(h);
            return ok;
        }
    }
}
