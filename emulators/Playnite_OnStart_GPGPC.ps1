# Package name of a Android game.
$GamePackageName = "com.aladdinx.suikagame"
# Title of a Android game.
$GameTitle = "スイカゲーム-Aladdin X"

# ----------------------------------------------------------
# Track the playtime of Android games running on Google Play Games on PC (GPGPC).
#
# Google Play Games on PC (GPGPC) 上で動作する Android ゲームのプレイ時間を追跡します。
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

# Track the playtime of Android games running on Google Play Games on PC (GPGPC).
#
# Google Play Games on PC (GPGPC) 上で動作する Android ゲームのプレイ時間を追跡します。
function Start-GPGPCProcess {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory,Position=0)]
        [string]$PackageName,
        [Parameter(Mandatory,Position=1)]
        [Alias("Title")]
        [string]$WindowTitle
    )

    # Define the flag.
    $GPGPCRunning = $false

    # Set a VM program name. (crosvm)
    $VMName = "crosvm"

    # Start a game.
    Start-Process "`"googleplaygames://launch/?id=${PackageName}`""

    # Loop for waiting.
    while ($true)
    {
        # Get the window infomation to check if a game window is open.
        $GPGPC = Get-Windows -Name $VMName -WindowTitle $WindowTitle

        # Write the window information to the information stream.
        $GPGPCInfo = "${GPGPC} = Get-Windows -Name ${VMName} -WindowTitle ${WindowTitle}"
        Write-Information $GPGPCInfo

        # if a game window is open.
        if (-not $GPGPCRunning -and ($GPGPC.Length -ne 0))
        {
            # Set the flag.
            $GPGPCRunning = $true
        }

        # if a game window is closed.
        if ($GPGPCRunning -and ($GPGPC.Length -eq 0))
        {
            # Unset the flag.
            $GPGPCRunning = $false

            # Break the loop.
            break
        }

        # Sleep for a while to not waste CPU.
        Start-Sleep -s 1
    }
}

# Start a game.
Start-GPGPCProcess -PackageName $GamePackageName -Title $GameTitle
