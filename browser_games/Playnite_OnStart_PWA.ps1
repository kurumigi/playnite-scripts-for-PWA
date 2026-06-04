# Path of a browser. (Chromium)
$BrowserPath = "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"
# AppID of a PWA game. AppID can be found from chrome://apps.
$GameAppID = "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
# Title of a game.
$GameTitle = "GeoGuessr"

# ----------------------------------------------------------
# Track the playtime of browser games installed as Progressive Web Apps (PWA).
#
# Progressive Web Apps (PWA) としてインストールされたブラウザゲームのプレイ時間を追跡します。
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
        $len = [GetWindowsWin32]::GetWindowTextLength($hWnd)

        # Exclude windows without window titles.
        if ($len -le 0)
        {
            return $true
        }

        # Get a window title.
        $sbTitle = [System.Text.StringBuilder]::new($len + 1)
        [void][GetWindowsWin32]::GetWindowText($hWnd, $sbTitle, $sbTitle.Capacity)
        $title = $sbTitle.ToString()

        # Get a class name.
        $sbClass = [System.Text.StringBuilder]::new(256)
        [void][GetWindowsWin32]::GetClassName($hWnd, $sbClass, $sbClass.Capacity)
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

# Track the playtime of browser games installed as PWA.
#
# PWA としてインストールされたブラウザゲームのプレイ時間を追跡します。
function Start-PWAProcess {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory,Position=0)]
        [Alias("BrowserPath")]
        [string]$Path,
        [Parameter(Mandatory,Position=1)]
        [Alias("AppID")]
        [string]$ArgumentList,
        [Parameter(Mandatory,Position=2)]
        [Alias("Title")]
        [string]$WindowTitle
    )

    # Define the flag.
    $BrowserRunning = $false

    # Open a PWA.
    Start-Process -FilePath $Path -ArgumentList "--app-id=`"${ArgumentList}`""

    # Get filename without extension from full path.
    $Name = [System.IO.Path]::GetFileNameWithoutExtension($Path)

    # Loop for waiting.
    while ($true)
    {
        # Get the window information to check if a game window is open.
        $Browser = Get-Windows -Name $Name -WindowTitle $WindowTitle

        # Write the window information to the information stream.
        $BrowserInfo = "${Browser} = Get-Windows -Name ${Name} -WindowTitle ${WindowTitle}"
        Write-Information $BrowserInfo

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
Start-PWAProcess -BrowserPath $BrowserPath -AppID $GameAppID -Title $GameTitle
