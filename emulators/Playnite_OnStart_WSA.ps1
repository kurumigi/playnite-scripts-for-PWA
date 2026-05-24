# ----------------------------------------------------------
# a tracking script for Android games running on Windows Subsystem for Android (WSA).
# ----------------------------------------------------------

# Package name of a Android game.
$PackageName = "jp.uuum.blueman"

# ----------------------------------------------------------

function Get-WindowByClassName {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]$ClassName
    )

    return [GetWindowsByClassName]::GetWindows($ClassName)
}

function Start-WSAProcess {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]$PackageName
    )

    $WSARunning = $false

    Start-Process -FilePath "WsaClient" -ArgumentList "/launch wsa://${PackageName}"

    while ($true)
    {
        # Check if game window is opening
        $WSA = Get-WindowByClassName($PackageName)

        # if game window opened
        if (!$WSARunning -and ($WSA.Length -ne 0))
        {
            $WSARunning = $true
        }

        # if game window closed
        if ($WSARunning -and ($WSA.Length -eq 0))
        {
            $WSARunning = $false
            break
        }

        # Sleep for a while to not waste CPU
        Start-Sleep -s 1
    }
}

Start-WSAProcess -PackageName $PackageName
