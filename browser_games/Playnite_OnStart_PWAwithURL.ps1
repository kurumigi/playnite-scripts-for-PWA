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
Start-PWAProcess2 -BrowserPath $BrowserPath -AppID $GameAppID -Url $GameUrl -Title $GameTitle
