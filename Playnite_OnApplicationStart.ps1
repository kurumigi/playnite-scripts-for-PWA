# ----------------------------------------------------------
# Get a list of main windows to record playtime of browser games and more.
#
# ブラウザゲームなどのプレイ時間を記録するために、メインウィンドウの一覧を取得します。
# ----------------------------------------------------------
#
# Reference / Source:
#   Old method (ClassName and WindowTitle):
#     https://stackoverflow.com/questions/16958051/get-chrome-browser-title-using-c-sharp
#     https://raykeymas.com/posts/powershell/get-chrome-window (Japanese)
#   Current method (Program Name and WindowTitle):
#     https://qiita.com/Tadataka_Takahashi/items/91c42661ef9559ac5f86 (Japanese)
#     https://note.com/kaito_mishima/n/n99cdce0b72f0 (Japanese)
#
# ----------------------------------------------------------

# Define Win32 APIs to get window information
#
# ウィンドウ情報を取得するために使用する Win32 API を定義します。
Add-Type @"
using System;
using System.Runtime.InteropServices;
using System.Text;

    public static class GetWindowsWin32
    {
        // A callback function used with the EnumWindows function.
        public delegate bool EnumWindowsProc(IntPtr hWnd, IntPtr lParam);

        // Enumerates all top-level windows on the screen
        [DllImport("user32.dll")]
        [return: MarshalAs(UnmanagedType.Bool)]
        public static extern bool EnumWindows(EnumWindowsProc lpEnumFunc, IntPtr lParam);

        // Determines the visibility state of the specified window.
        [DllImport("user32.dll")]
        [return: MarshalAs(UnmanagedType.Bool)]
        public static extern bool IsWindowVisible(IntPtr hWnd);

        // Retrieves the text of the specified window's title bar
        [DllImport("user32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
        public static extern int GetWindowText(IntPtr hWnd, StringBuilder lpString, int nMaxCount);

        // Retrieves the length of the specified window's title bar text
        [DllImport("user32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
        public static extern int GetWindowTextLength(IntPtr hwnd);

        // Retrieves the name of the class to which the specified window belongs.
        [DllImport("user32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
        public static extern int GetClassName(IntPtr hWnd, StringBuilder lpClassName, int nMaxCount);

        // Retrieves the identifier of the thread that created the specified window and the identifier of the process that created the window.
        [DllImport("user32.dll")]
        public static extern uint GetWindowThreadProcessId(IntPtr hWnd, out uint lpdwProcessId);

        // Sets the show state of a window without waiting for the operation to complete.
        [DllImport("user32.dll")]
        [return: MarshalAs(UnmanagedType.Bool)]
        public static extern bool ShowWindowAsync(IntPtr hWnd, int nCmdShow);
    }
"@
