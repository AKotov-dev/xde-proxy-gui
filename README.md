# XDE-Proxy-GUI

Lightweight proxy manager with GNOME-compatible live switching.  
  
**Supported environments**
- X11 (not Wayland)
- XFCE, LXDE and LXQt — officially supported
- Optional WM support — IceWM, Openbox, i3 (requires `DesktopNames` setting)

![](https://github.com/AKotov-dev/xde-proxy-gui/blob/main/Screenshot1.png)

## Dependencies

**Mageia**
- gsettings-desktop-schemas dconf dconf-editor lib64proxy-gnome gtk2  

**Fedora**
- gsettings-desktop-schemas dconf dconf-editor libproxy gtk2  

**Ubuntu / XUbuntu**
- gsettings-desktop-schemas dconf-cli libproxy1v5 libproxy1-plugin-gsettings libgtk2.0-0  

**Note:**  
Packages for Mageia 9/10 are built using the *Portable RPM* approach with [RPMCreator](https://github.com/AKotov-dev/RPMCreator).  
  
For Fedora you can build your own package by loading the [project file](https://github.com/AKotov-dev/xde-proxy-gui/raw/refs/heads/main/xde-proxy-gui/package-project/RPM-(Fedora)-xde-proxy-gui.prj) into `RPMCreator`.  
  
`dconf-editor` is **not required**, but it is a convenient tool for inspecting the actual proxy settings and may be useful for further development.

---

## What is this?

**XDE-Proxy-GUI** is a simple graphical tool for managing **system-wide proxy settings** in XFCE and LXDE.  
  
It allows changing proxy settings:
- **immediately for GUI applications** (browsers, etc.)
- **for CLI applications** after opening a new terminal (wget, curl, etc.)

The tool uses **libproxy** together with **dconf / gsettings**, providing
GNOME/MATE-like system-wide proxy behavior on XFCE, LXDE and LXQt.  
  

---
### Important note

- To implement the system proxy function, you need to click the **"Apply"** button at least once.
- After installing or removing the package, you must log out and log in again (or reboot). Once this is done, the tool works continuously.

---
## How does it work?

**/etc/profile.d/proxy-sync.sh**

The key idea is exporting a **fake desktop identifier**:

```
export XDG_CURRENT_DESKTOP="GNOME:${XDG_CURRENT_DESKTOP}"
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

During operation, **XDE-Proxy-GUI adds the following lines to** ~/.bashrc:
```
[ -r /etc/profile.d/proxy-sync.sh ] && source /etc/profile.d/proxy-sync.sh
[ -r /etc/profile.d/xde-proxy-env.sh ] && source /etc/profile.d/xde-proxy-env.sh
```

An additional section is created for **LXDE** in ~/.config/lxsession/LXDE/desktop.conf:
```
[Environment_variable]
XDG_CURRENT_DESKTOP=GNOME:LXDE
```
An additional section is created for **LXQt** in ~/.config/lxqt/session.conf:
```
[Environment]
XDG_CURRENT_DESKTOP=GNOME:LXDE
```
Layered diagram:
```
GUI
 │
 ├── gsettings/libproxy
 │      ↑
 │   proxy-sync.sh
 │
 └── CLI environment
        ↑
   xde-proxy-env.sh
        ↑
   proxy-env.sh
```

---
### Tested on
+ Mageia 9 / 10 (XFCE, LXDE, LXQt, Chromium, Firefox, wget, etc)
+ Fedora 43 (XFCE, LXDE, LXQt, Brave-browser, Firefox, wget, etc)
+ XUbuntu 25.04 (XFCE, LXDE, LXQt, Brave-browser, Firefox (not snap), wget, etc)

---

### Optional (for those who prefer something more exotic)

Starting with **xde-proxy-gui v0.3**, the application also works with the **IceWM**, **Openbox** and **i3** window managers, provided that the session correctly declares `DesktopNames`.

#### IceWM
In IceWM, the `DesktopNames` parameter is usually already set.

Check the file: `/usr/share/xsessions/icewm-session.desktop`  
It should contain, for example: `DesktopNames=ICEWM`

#### Openbox
For Openbox, the `DesktopNames` parameter may be missing and must be specified manually.  
Session file: `/usr/share/xsessions/openbox.desktop`  
Add the following line: `DesktopNames=Openbox`

#### i3
In i3, the `DesktopNames` parameter is usually already set (i3.desktop).

Check the files: `/usr/share/xsessions/{i3.desktop,i3-with-shmlog.desktop}`  
It should contain, for example: `DesktopNames=i3`

---
## Disclaimer

This project was created to address the long-standing absence of a convenient system-wide proxy solution in lightweight desktop environments such as XFCE, LXDE and LXQt.  
  
The software is provided "as is", without any warranties. The author assumes no responsibility for any consequences arising from improper configuration or usage.
