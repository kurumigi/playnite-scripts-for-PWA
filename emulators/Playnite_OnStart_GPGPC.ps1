# ----------------------------------------------------------
# a tracking script for Android games running on Google Play Games on PC (GPGPC).
# ----------------------------------------------------------

# Package name of a Android game.
$GamePackageName = "com.aladdinx.suikagame"
# Title of a Android game.
$GameTitle = "スイカゲーム-Aladdin X"

# ----------------------------------------------------------

function Get-WindowsByTitle {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]$WindowTitle
    )

    # GPGPC (CROSVM)
    $ClassName = "CROSVM_1"

    return [GetWindowsByTitle]::GetWindows($ClassName, $WindowTitle)
}

function Start-GPGPCProcess {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory,Position=0)]
        [string]$PackageName,
        [Parameter(Mandatory,Position=1)]
        [Alias("Title")]
        [string]$WindowTitle
    )

    $GPGPCRunning = $false

    Start-Process "`"googleplaygames://launch/?id=${PackageName}`""

    while ($true)
    {
        # Check if game window is opening
        $GPGPC = Get-WindowsByTitle($WindowTitle)

        # if game window opened
        if (!$GPGPCRunning -and ($GPGPC.Length -ne 0))
        {
            $GPGPCRunning = $true
        }

        # if game window closed
        if ($GPGPCRunning -and ($GPGPC.Length -eq 0))
        {
            $GPGPCRunning = $false
            break
        }

        # Sleep for a while to not waste CPU
        Start-Sleep -s 1
    }
}

Start-GPGPCProcess -PackageName $GamePackageName -Title $GameTitle
