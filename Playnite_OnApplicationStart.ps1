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
#   Current method (Program Path and WindowTitle):
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

// Old method code
using System.Collections;
using System.Collections.Generic;
using System.Diagnostics.CodeAnalysis;
using System.Security;
// Old method code

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
        [DllImport("user32.dll", SetLastError = true)]
        public static extern int GetWindowTextA(IntPtr hWnd, StringBuilder lpString, int nMaxCount);

        // Retrieves the length of the specified window's title bar text
        [DllImport("user32.dll", SetLastError = true)]
        public static extern int GetWindowTextLengthA(IntPtr hwnd);

        // Retrieves the name of the class to which the specified window belongs.
        [DllImport("user32.dll", SetLastError = true)]
        public static extern int GetClassNameA(IntPtr hWnd, StringBuilder lpClassName, int nMaxCount);

        // Retrieves the identifier of the thread that created the specified window and the identifier of the process that created the window.
        [DllImport("user32.dll")]
        public static extern uint GetWindowThreadProcessId(IntPtr hWnd, out uint lpdwProcessId);

        // Sets the show state of a window without waiting for the operation to complete.
        [DllImport("user32.dll")]
        [return: MarshalAs(UnmanagedType.Bool)]
        public static extern bool ShowWindowAsync(IntPtr hWnd, int nCmdShow);
    }

// Old method code
    // A class to get a list of windows with a specific class name.
    //
    // あるクラス名を持つウィンドウの一覧を取得するクラス
    public class GetWindowsByClassName
    {

        private GetWindowsByClassName(string className)
        {
            _className = className;
            GetWindowsWin32.EnumWindows(callback, IntPtr.Zero);
        }

        private bool callback(IntPtr hWnd, IntPtr lparam)
        {
            if (GetWindowsWin32.GetClassNameA(hWnd, _apiResult, _apiResult.Capacity) != 0)
            {
                if (string.CompareOrdinal(_apiResult.ToString(), _className) == 0)
                {
                    _result.Add(hWnd);
                }
            }

            return true;
        }

        public static IEnumerable<Tuple<string, IntPtr>> GetWindows(string className)
        {
            foreach (var windowHandle in GetWindowHandles(className))
            {
                int length = GetWindowsWin32.GetWindowTextLengthA(windowHandle);
                StringBuilder sb = new StringBuilder(length + 1);
                GetWindowsWin32.GetWindowTextA(windowHandle, sb, sb.Capacity);
                yield return new Tuple<string, IntPtr>(sb.ToString(), windowHandle);
            }
        }

        public static List<IntPtr> GetWindowHandles(string className)
        {
            if (string.IsNullOrWhiteSpace(className))
                throw new ArgumentOutOfRangeException("className", className, "className can't be null or blank.");

            return new GetWindowsByClassName(className)._result;
        }

        private readonly string _className;
        private readonly List<IntPtr> _result = new List<IntPtr>();
        private readonly StringBuilder _apiResult = new StringBuilder(1024);
    }

    // A class to get a list of windows with a specific class name and window title.
    //
    // あるクラス名とタイトルを持つウィンドウの一覧を取得するクラス
    public class GetWindowsByTitle
    {
        public static IEnumerable<Tuple<string, IntPtr>> GetWindows(string className, string titlePrefix)
        {
            // Check window title
            foreach (var tuple in GetWindowsByClassName.GetWindows(className))
                if (tuple.Item1.Contains(titlePrefix))
                    yield return new Tuple<string, IntPtr>(tuple.Item1, tuple.Item2);
        }
    }
// Old method code
"@
