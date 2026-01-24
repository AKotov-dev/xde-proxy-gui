# proxy-sync.sh — синхронизация CLI с gsettings для текущего пользователя

# Только для этих DE
case "${XDG_CURRENT_DESKTOP,,}" in
  *lxde*|*lxqt*|*xfce*)
    ;;
  *)
    return
    ;;
esac

# gsettings есть только в пользовательской сессии
command -v gsettings >/dev/null 2>&1 || return

# Не пытаться работать без DBUS
[ -z "$DBUS_SESSION_BUS_ADDRESS" ] && return

# Добавляем GNOME в XDG_CURRENT_DESKTOP, если его там нет
if [[ "$XDG_CURRENT_DESKTOP" != *GNOME* ]]; then
  export XDG_CURRENT_DESKTOP="GNOME:${XDG_CURRENT_DESKTOP:+$XDG_CURRENT_DESKTOP}"
fi

# Очистить все переменные прокси
unset http_proxy https_proxy ftp_proxy all_proxy no_proxy
unset HTTP_PROXY HTTPS_PROXY FTP_PROXY ALL_PROXY NO_PROXY

# Прокси включен?
mode=$(gsettings get org.gnome.system.proxy mode | tr -d "'")

if [ "$mode" = "manual" ]; then
    http_host=$(gsettings get org.gnome.system.proxy.http host | tr -d "'")
    http_port=$(gsettings get org.gnome.system.proxy.http port)

    if [ -n "$http_host" ] && [ "$http_port" -gt 0 ]; then
        export http_proxy="http://$http_host:$http_port"
        export ftp_proxy="ftp://$http_host:$http_port"
    fi

    https_host=$(gsettings get org.gnome.system.proxy.https host | tr -d "'")
    https_port=$(gsettings get org.gnome.system.proxy.https port)

    if [ -n "$https_host" ] && [ "$https_port" -gt 0 ]; then
        export https_proxy="http://$https_host:$https_port"
    fi

    socks_host=$(gsettings get org.gnome.system.proxy.socks host | tr -d "'")
    socks_port=$(gsettings get org.gnome.system.proxy.socks port)

    if [ -n "$socks_host" ] && [ "$socks_port" -gt 0 ]; then
        export all_proxy="socks5h://$socks_host:$socks_port"
    fi

    no_proxy=$(gsettings get org.gnome.system.proxy ignore-hosts \
        | tr -d "[]'" | tr ',' '\n' | tr -d ' ' | paste -sd,)

    [ -n "$no_proxy" ] && export no_proxy

    # Дубли в UPPERCASE
    [ -n "$http_proxy"  ] && export HTTP_PROXY="$http_proxy"
    [ -n "$https_proxy" ] && export HTTPS_PROXY="$https_proxy"
    [ -n "$ftp_proxy"   ] && export FTP_PROXY="$ftp_proxy"
    [ -n "$all_proxy"   ] && export ALL_PROXY="$all_proxy"
    [ -n "$no_proxy"    ] && export NO_PROXY="$no_proxy"
fi
