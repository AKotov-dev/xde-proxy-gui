# proxy-sync.sh — подготовка окружения для libproxy/gsettings

case "${XDG_CURRENT_DESKTOP,,}" in
    *xfce*|*lxde*|*lxqt*|*icewm*|*openbox*|*i3*|*budgie*)
        ;;
    *)
        return
        ;;
esac

command -v gsettings >/dev/null 2>&1 || return

[ -z "$DBUS_SESSION_BUS_ADDRESS" ] && return

case "$XDG_CURRENT_DESKTOP" in
    *GNOME*)
        ;;
    *)
        export XDG_CURRENT_DESKTOP="GNOME:${XDG_CURRENT_DESKTOP}"
        ;;
esac
