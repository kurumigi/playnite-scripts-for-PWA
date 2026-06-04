# Package name of a Android game.
$PackageName = "jp.uuum.blueman"

# ----------------------------------------------------------
# Track the playtime of Android games running on Windows Subsystem for Android (WSA).
#
# Windows Subsystem for Android (WSA) 上で動作する Android ゲームのプレイ時間を追跡します。
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

        # Write the window information to the information stream.
        $WSAInfo = "${WSA} = Get-Windows -Name ${Name} -ClassName ${PackageName}"
        Write-Information $WSAInfo

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
