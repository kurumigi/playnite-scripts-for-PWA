# Package name of a Android game.
$PackageName = "jp.uuum.blueman"

# ----------------------------------------------------------
# Track the playtime of Android games running on Windows Subsystem for Android (WSA).
#
# Windows Subsystem for Android (WSA) 上で動作する Android ゲームのプレイ時間を追跡します。
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

# Track the playtime of Android games running on Windows Subsystem for Android (WSA).
#
# Windows Subsystem for Android (WSA) 上で動作する Android ゲームのプレイ時間を追跡します。
function Start-WSAProcess {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]$PackageName
    )

    # Define the flag.
    $WSARunning = $false

    # Set a program name.
    $Name = "WsaClient"

    # Start a game.
    Start-Process -FilePath $Name -ArgumentList "/launch wsa://${PackageName}"

    # Loop for waiting.
    while ($true)
    {
        # Get the window infomation to check if a game window is open.
        $WSA = Get-Windows -Name $Name -ClassName $PackageName

        # if a game window is open.
        if (-not $WSARunning -and ($WSA.Length -ne 0))
        {
            # Set the flag.
            $WSARunning = $true
        }

        # if a game window is closed.
        if ($WSARunning -and ($WSA.Length -eq 0))
        {
            # Unset the flag.
            $WSARunning = $false

            # Break the loop.
            break
        }

        # Sleep for a while to not waste CPU.
        Start-Sleep -s 1
    }
}

# Start a game.
Start-WSAProcess -PackageName $PackageName
