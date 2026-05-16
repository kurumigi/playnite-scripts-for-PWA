# ----------------------------------------------------------
# A tracking script for browser games hosted on a PWA site.
# (Example: a game posting site installed as a PWA.)
# ----------------------------------------------------------

# Path of a browser (Chromium)
$BrowserPath = "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"
# AppID of a PWA site. AppID can be found from the desktop shortcut.
$GameAppID = "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
# URL of a game
$GameUrl = "https://unityroom.com/games/dekasugikun"
# Title of a game
$GameTitle = "出過杉くん | フリーゲーム投稿サイト unityroom"

# ----------------------------------------------------------

function Get-WindowsByTitle {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]$WindowTitle
    )

    # Window class name of Chromium browsers.
    $ClassName = "Chrome_WidgetWin_1"

    return [GetWindowsByTitle]::GetWindows($ClassName, $WindowTitle)
}

function Start-PWAProcess {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory,Position=0)]
        [Alias("BrowserPath")]
        [string]$FilePath,
        [Parameter(Mandatory,Position=1)]
        [string]$AppID,
        [Parameter(Mandatory,Position=2)]
        [string]$Url,
        [Parameter(Mandatory,Position=3)]
        [Alias("Title")]
        [string]$WindowTitle
    )

    $BrowserRunning = $false

    # --app-launch-url-for-shortcuts-menu-item option from https://peter.sh/experiments/chromium-command-line-switches/#app-launch-url-for-shortcuts-menu-item
    #
    # "Overrides the launch url of an app with the specified url. This is used along with kAppId to launch a given app with the url corresponding to an item in the app's shortcuts menu."
    $ArgumentList = "--app-id=`"${AppId}`" --app-launch-url-for-shortcuts-menu-item=`"${Url}`""

    Start-Process -FilePath $FilePath -ArgumentList $ArgumentList

    while ($true)
    {
        # Check if game window is opening
        $Browser = Get-WindowsByTitle($WindowTitle)

        # if game window opened
        if (!$BrowserRunning -and ($Browser.Length -ne 0))
        {
            $BrowserRunning = $true
            [Win32Functions]::ShowWindowAsync($Browser.Item2, 3) # SW_MAXIMIZE
        }

        # if game window closed
        if ($BrowserRunning -and ($Browser.Length -eq 0))
        {
            $BrowserRunning = $false
            break
        }

        # Sleep for a while to not waste CPU
        Start-Sleep -s 1
    }
}

# Start a game
Start-PWAProcess -BrowserPath $BrowserPath -AppID $GameAppID -Url $GameUrl -Title $GameTitle
