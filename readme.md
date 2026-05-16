# Script for tracking browser games on [Playnite](https://playnite.link/).

## Usage

### Playnite_OnApplicationStart.ps1

Paste to ''Scripts > Application Scripts > Execute on application start'' On Settings.

![Screenshot of Pasted code.](/assets/images/20251204_02.JPG)

### Playnite_OnStart_PWA.ps1

Using for browser games installed as a PWA.

1. From the desktop shortcut of the PWA, check the game title and AppID.
2. Replace $GameTitle and $GameAppID with the game title and AppID.
3. Paste the modified code into the game's play action. Set the type to ''Script.''

### Playnite_OnStart_PWAwithURL.ps1

Using for browser games hosted on a PWA site.
(Example: a game posting site installed as a PWA.)

1. Check the game title and URL.
2. From the desktop shortcut of the PWA, check the site's AppID.
3. Replace $GameTitle, $GameAppID, and $GameUrl with the game title, the site's AppID, and the game's URL.
4. Paste the modified code into the game's play action. Set the type to ''Script.''

### Playnite_OnStart_Webapp.ps1

Using for (non-PWA) browser games.

1. Check the game title and URL.
2. Replace $GameTitle and $GameUrl with the game title and URL.
3. Paste the modified code into the game's play action. Set the type to ''Script.''

![Screenshot of Pasted code.](/assets/images/20251204_01.JPG)
