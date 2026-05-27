# Path of a browser. (Chromium)
$BrowserPath = "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"
# AppID of a PWA site. AppID can be found from chrome://apps.
$GameAppID = "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
# URL of a game.
$GameUrl = "https://unityroom.com/games/dekasugikun"
# Title of a game.
$GameTitle = "出過杉くん | フリーゲーム投稿サイト unityroom"

# ----------------------------------------------------------
# Track the playtime of a specified browser game on the web site installed as Progressive Web Apps (PWA).
# (Example: a game posting site installed as a PWA.)
#
# Progressive Web Apps (PWA) としてインストールされたウェブサイト上のブラウザゲームのプレイ時間を追跡します。
# (例: PWA としてインストールされたゲーム投稿サイトなど)
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
    param (
        [Parameter()]
        [Alias("ProcessPath")]
        [string]$Path,
        [Parameter()]
        [Alias("ProcessName")]
        [string]$Name,
        [Parameter()]
        [string]$ClassName,
        [Parameter()]
        [Alias("Title")]
        [string]$WindowTitle
    )

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

        # If the $Path argument is provided, exclude where $Name isn't the window process path.
        if ($Path -and ($Path -ne $proc.Path))
        {
            return $true
        }

        # If the $Name argument is provided, exclude where $Name isn't the window process name.
        if ($Name -and ($Name -ne $proc.Name))
        {
            return $true
        }

        # If the $ClassName argument is provided, exclude where $ClassName isn't the window class name.
        if ($ClassName -and ($ClassName -ne $class))
        {
            return $true
        }

        # If the $WindowTitle argument is provided, exclude where $WindowTitle isn't matched in the window title.
        if ($WindowTitle -and (-not $title.Contains($WindowTitle)))
        {
            return $true
        }

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

# Track the playtime of a specified browser game on the web site installed as Progressive Web Apps (PWA).
# (Example: a game posting site installed as a PWA.)
#
# Progressive Web Apps (PWA) としてインストールされたウェブサイト上のブラウザゲームのプレイ時間を追跡します。
# (例: PWA としてインストールされたゲーム投稿サイトなど)
function Start-PWAProcess2 {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory,Position=0)]
        [Alias("BrowserPath")]
        [string]$Path,
        [Parameter(Mandatory,Position=1)]
        [string]$AppID,
        [Parameter(Mandatory,Position=2)]
        [string]$Url,
        [Parameter(Mandatory,Position=3)]
        [Alias("Title")]
        [string]$WindowTitle
    )

    # Define the flag.
    $BrowserRunning = $false

    # Set arguments to open a PWA with a specified browser game.
    #
    # --app-launch-url-for-shortcuts-menu-item option from https://peter.sh/experiments/chromium-command-line-switches/#app-launch-url-for-shortcuts-menu-item
    #
    # "Overrides the launch url of an app with the specified url. This is used along with kAppId to launch a given app with the url corresponding to an item in the app's shortcuts menu."
    $ArgumentList = "--app-id=`"${AppId}`" --app-launch-url-for-shortcuts-menu-item=`"${Url}`""

    # Open a PWA with a specified browser game.
    Start-Process -FilePath $Path -ArgumentList $ArgumentList

    # Get filename without extension from full path.
    $Name = [System.IO.Path]::GetFileNameWithoutExtension($Path)

    # Loop for waiting.
    while ($true)
    {
        # Get the window information to check if a game window is open.
        $Browser = Get-Windows -Name $Name -WindowTitle $WindowTitle

        # if a game window is open.
        if (!$BrowserRunning -and ($Browser.Length -ne 0))
        {
            # Set the flag.
            $BrowserRunning = $true

            # Maximize a game window. (3 is SW_MAXIMIZE)
            [void][GetWindowsWin32]::ShowWindowAsync($Browser.MainWindowHandle, 3)
        }

        # if a game window is closed.
        if ($BrowserRunning -and ($Browser.Length -eq 0))
        {
            # Unset the flag.
            $BrowserRunning = $false

            # Break the loop.
            break
        }

        # Sleep for a while to not waste CPU.
        Start-Sleep -s 1
    }
}

# Start a game.
Start-PWAProcess2 -BrowserPath $BrowserPath -AppID $GameAppID -Url $GameUrl -Title $GameTitle
