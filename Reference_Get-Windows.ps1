# ----------------------------------------------------------
# Get a list of main windows.
#
# メインウィンドウの一覧を取得します。
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

# Define Win32 APIs to get window information if it hasn't been defined yet.
# (It's a debugging feature.)
#
# まだ定義されていなければ、ウィンドウ情報を取得するために使用する Win32 API を定義します。
# (これはデバッグ用の機能です。)
if (-not ([System.Management.Automation.PSTypeName]'GetWindowsWin32').Type)
{
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
"@
}

# Get a list of main windows.
#
# メインウィンドウの一覧を取得します。
function Get-Windows {
    [CmdletBinding()]

    # Create a list to store windows informations.
    $MainWindowList = [System.Collections.Generic.List[object]]::new()

    # Define a callback function.
    $CallbackFunc = [GetWindowsWin32+EnumWindowsProc]{
        param(
            $hWnd,
            $lParam
        )

        # Exclude hidden windows.
        if (-not [GetWindowsWin32]::IsWindowVisible($hWnd))
        {
            return $true
        }

        # Get a length of a window title.
        $len = [GetWindowsWin32]::GetWindowTextLengthA($hWnd)

        # Exclude windows without window titles.
        if ($len -le 0)
        {
            return $true
        }

        # Get a window title.
        $sbTitle = [System.Text.StringBuilder]::new($len + 1)
        [void][GetWindowsWin32]::GetWindowTextA($hWnd, $sbTitle, $sbTitle.Capacity)
        $title = $sbTitle.ToString()

        # Get a class name.
        $sbClass = [System.Text.StringBuilder]::new(256)
        [void][GetWindowsWin32]::GetClassNameA($hWnd, $sbClass, $sbClass.Capacity)
        $class = $sbClass.ToString()

        # Get a process id.
        [uint32]$procId = 0
        [void][GetWindowsWin32]::GetWindowThreadProcessId($hWnd, [ref]$procId)

        # Get a process information.
        $proc = Get-Process -Id $procId -ErrorAction SilentlyContinue

        # Exclude windows without process information.
        if (-not $proc)
        {
            return $true
        }

        # -------------------------------------------------------
        # If any items want to be excluded, add code here.
        #
        # 追加で除外したい項目がある場合は、ここにコードを追加します。
        # -------------------------------------------------------

        # Add window information to the list. A little similar to Get-Process.
        $MainWindowList.Add([pscustomobject]@{
            Id                  = $procId
            Name                = $proc.Name
            ProcessName         = $proc.ProcessName
            Path                = $proc.Path
            MainWindowHandle    = $hWnd
            MainWindowTitle     = $title
            MainWindowClassName = $class
        }) | Out-Null

        return $true
    }

    # Enumerate main windows and get a list of window information.
    [void][GetWindowsWin32]::EnumWindows($CallbackFunc, [IntPtr]::Zero)

    # Return a list of window information.
    return $MainWindowList
}
