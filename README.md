# XDE-Proxy-GUI

![](https://github.com/AKotov-dev/xde-proxy-gui/blob/main/Screenshot1.png)

Lightweight proxy manager with GNOME-compatible live switching for XDE (XFCE, LXDE) & WMs (IceWM, Openbox).

## Dependencies

**Mageia**
- gsettings-desktop-schemas dconf dconf-editor lib64proxy-gnome gtk2  

**Fedora**
- gsettings-desktop-schemas dconf dconf-editor libproxy gtk2  

**Ubuntu / XUbuntu**
- gsettings-desktop-schemas dconf-cli libproxy1v5 libproxy1-plugin-gsettings libgtk2.0-0  

**Note:**  
Packages for Mageia 9/10 are built using the *Portable RPM* approach with [RPMCreator](https://github.com/AKotov-dev/RPMCreator).  
  
For Fedora you can build your own package by loading the [project file](https://github.com/AKotov-dev/xfce-proxy-gui/blob/main/xfce-proxy-gui/package-project/RPM-(Fedora)-xfce-proxy-gui.prj) into `RPMCreator`.  
  
`dconf-editor` is **not required**, but it is a convenient tool for inspecting the actual proxy settings and may be useful for further development.

---

## What is this?

**XDE-Proxy-GUI** is a simple graphical tool for managing **system-wide proxy settings** in XFCE and LXDE.  
  
It allows changing proxy settings:
- **immediately for GUI applications** (browsers, etc.)
- **for CLI applications** after opening a new terminal (wget, curl, etc.)

The tool uses **libproxy** together with **dconf / gsettings**, providing
GNOME/MATE-like system-wide proxy behavior on XFCE and LXDE.  
  
Unlike `Chromium-based` browsers, `Firefox` does not support **system-wide proxy** settings on Linux. Firefox uses its own proxy configuration and must be configured separately (for example, via `about:preferences → Network Settings` or using environment variables for specific launches).

---
### Important note

After installing or removing the package, you must log out and log in again (or reboot). Once this is done, the tool works continuously.

---
## How does it work?

**/etc/profile.d/proxy-sync.sh**

The key idea is exporting a **fake desktop identifier**:

```
export XDG_CURRENT_DESKTOP="GNOME:${XDG_CURRENT_DESKTOP:+$XDG_CURRENT_DESKTOP}"
```
This enables full interaction with `libproxy` via `gsettings`, allowing GUI
applications (for example, web browsers) to react to proxy changes immediately.

Additionally, the script exports environment variables:
```
http_proxy / https_proxy / ftp_proxy / all_proxy / no_proxy
HTTP_PROXY / HTTPS_PROXY / FTP_PROXY / ALL_PROXY / NO_PROXY
```
These variables are used by CLI applications. Because environment variables cannot be updated in already running shells, **a new terminal must be opened** after changing proxy settings.  

---
### Additional notes

During operation, **XDE-Proxy-GUI adds the following line to** ~/.bashrc:
```
[ -r /etc/profile.d/proxy-sync.sh ] && source /etc/profile.d/proxy-sync.sh
```

This is required for `XUbuntu`, whose shell initialization behavior differs from canonical XFCE implementations (Mageia, Fedora).  
  
  
An additional section is created for **LXDE** in ~/.config/lxsession/LXDE/desktop.conf:
```
[Environment_variable]
XDG_CURRENT_DESKTOP=GNOME:LXDE
```
---
### Tested on
+ Mageia 9 / 10 (XFCE, LXDE, Chromium, wget, etc)
+ Fedora 43 (XFCE, Brave-browser, wget, etc)
+ XUbuntu 25.04 (XFCE, Brave-browser, wget, etc)

---
### LXQt limitation

LXQt forcibly sets certain desktop environment variables (including XDG_CURRENT_DESKTOP) in its session startup scripts (startlxqt / lxqt-session), overriding any values defined in user profiles, system-wide environment configuration, or display manager scripts.  
  
Because of this, it is not possible to reliably inject or override environment-based configuration (such as system-wide proxy settings) for the entire LXQt graphical session without patching or replacing LXQt startup scripts.

---
### Optional (for those who prefer something more exotic)

Starting with **xde-proxy-gui v0.2**, the application also works with the **IceWM** and **Openbox** window managers, provided that the session correctly declares `DesktopNames`.

#### IceWM
In IceWM, the `DesktopNames` parameter is usually already set.

Check the file: `/usr/share/xsessions/icewm-session.desktop`  
It should contain, for example: `DesktopNames=ICEWM`

#### Openbox
For Openbox, the `DesktopNames` parameter may be missing and must be specified manually.  
Session file: `/usr/share/xsessions/openbox.desktop`  
Add the following line: `DesktopNames=Openbox`

---
## Disclaimer

This project was created to address the long-standing absence of a convenient system-wide proxy solution in lightweight desktop environments such as XFCE and LXDE.  
  
The software is provided "as is", without any warranties. The author assumes no responsibility for any consequences arising from improper configuration or usage.
