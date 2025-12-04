# Script for tracking browser games on [Playnite](https://playnite.link/).

## Usage

### Playnite_OnApplicationStart.ps1

Paste to ''Scripts > Application Scripts > Execute on application start'' On Settings.

![Screenshot of Pasted code.](/assets/images/20251204_02.JPG)

### Playnite_OnStart_PWA.ps1

Using for PWA browser games.

1. Find the game title and AppID from a desktop shortcut of PWA.
2. Modify $GameTitle and $GameAppID to your game's title and AppID.
3. Paste the modified code to your game's play action. Set the type to ''Script.''

### Playnite_OnStart_Webapp.ps1

Using for non-PWA browser games.

1. Check the game title and URL.
2. Modify $GameTitle and $GameUrl to your game's title and URL.
3. Paste the modified code to your game's play action. Set the type to ''Script.''

![Screenshot of Pasted code.](/assets/images/20251204_01.JPG)
