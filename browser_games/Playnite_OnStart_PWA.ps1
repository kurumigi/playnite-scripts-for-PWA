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
#   Old method (ClassName and WindowTitle / C#):
#     https://stackoverflow.com/questions/16958051/get-chrome-browser-title-using-c-sharp
#     https://raykeymas.com/posts/powershell/get-chrome-window (Japanese)
#   Current method (Program Name and WindowTitle / Powershell):
#     https://qiita.com/Tadataka_Takahashi/items/91c42661ef9559ac5f86 (Japanese)
#     https://note.com/kaito_mishima/n/n99cdce0b72f0 (Japanese)
#   Current method (Program Name and WindowTitle / C#):
#     https://learn.microsoft.com/en-us/powershell/scripting/developer/cmdlet/cmdlet-overview?view=powershell-5.1
#   Imports a cmdlet written in C# within a .ps1 file as a PowerShell module:
#     https://devblogs.microsoft.com/powershell/dynamic-binary-modules/
#     https://gist.github.com/guitarrapc/e398672bcb26814b6328
#
# ----------------------------------------------------------

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
