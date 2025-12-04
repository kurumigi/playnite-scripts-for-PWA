# ----------------------------------------------------------
# Script for tracking browser games.
# ----------------------------------------------------------

# Path of a browser (Chromium)
$BrowserPath = "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"
# URL of a game
$GameUrl = "http://slither.io/"
# Title of a game
$GameTitle = "slither.io"

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
        [Alias("Url")]
        [string]$ArgumentList,
        [Parameter(Mandatory,Position=2)]
        [Alias("Title")]
        [string]$WindowTitle
    )

    $BrowserRunning = $false

    Start-Process -FilePath $FilePath -ArgumentList "--app=`"${ArgumentList}`""

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
Start-PWAProcess -BrowserPath $BrowserPath -Url $GameUrl -Title $GameTitle
