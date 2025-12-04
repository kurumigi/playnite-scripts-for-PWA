# ----------------------------------------------------------
# Get a list of windows with specific class name/window title by PowerShell.
#
# PowerShell で、特定のクラス名/ウィンドウタイトルを持つウィンドウの一覧を取得します。
#
# Reference:
#   https://stackoverflow.com/questions/16958051/get-chrome-browser-title-using-c-sharp
#   https://raykeymas.com/posts/powershell/get-chrome-window (Japanese)
# ----------------------------------------------------------
Add-Type @"
using System;
using System.Collections;
using System.Collections.Generic;
using System.Diagnostics.CodeAnalysis;
using System.Runtime.InteropServices;
using System.Security;
using System.Text;

    // A class to get a list of windows with a specific class name.
    //
    // あるクラス名を持つウィンドウの一覧を取得するクラス
    public class GetWindowsByClassName
    {
        public delegate bool EnumWindowsDelegate(IntPtr hWnd, IntPtr lparam);

        [DllImport("user32.dll", SetLastError = true, CharSet = CharSet.Auto)]
        public static extern int GetClassName(IntPtr hWnd, StringBuilder lpClassName, int nMaxCount);

        [DllImport("user32.dll")]
        [return: MarshalAs(UnmanagedType.Bool)]
        public extern static bool EnumWindows(EnumWindowsDelegate lpEnumFunc, IntPtr lparam);

        [DllImport("User32", CharSet=CharSet.Auto, SetLastError=true)]
        public static extern int GetWindowText(IntPtr windowHandle, StringBuilder stringBuilder, int nMaxCount);

        [DllImport("user32.dll", EntryPoint = "GetWindowTextLength", SetLastError = true)]
        internal static extern int GetWindowTextLength(IntPtr hwnd);

        /// <summary>Find the windows matching the specified class name.</summary>

        private GetWindowsByClassName(string className)
        {
            _className = className;
            EnumWindows(callback, IntPtr.Zero);
        }

        private bool callback(IntPtr hWnd, IntPtr lparam)
        {
            if (GetClassName(hWnd, _apiResult, _apiResult.Capacity) != 0)
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
                int length = GetWindowTextLength(windowHandle);
                StringBuilder sb = new StringBuilder(length + 1);
                GetWindowText(windowHandle, sb, sb.Capacity);
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
"@
