# proxy-env.sh — экспорт proxy-переменных только в текущий shell
#
# Использование:
#   source ~/.local/bin/proxy-env.sh
#
# Рекомендуется подключать из ~/.bashrc.
#
# ВАЖНО:
#   Скрипт НЕ должен находиться в /etc/profile.d/
#   и НЕ должен выполняться при старте графической сессии.
#   Он изменяет environment только текущего shell.

# gsettings нужен только внутри пользовательской сессии
command -v gsettings >/dev/null 2>&1 || return

# Не пытаемся работать без DBus
[ -n "$DBUS_SESSION_BUS_ADDRESS" ] || return

# ------------------------------------------------------------
# Сначала всегда очищаем старое состояние
# ------------------------------------------------------------

unset http_proxy https_proxy ftp_proxy all_proxy no_proxy
unset HTTP_PROXY HTTPS_PROXY FTP_PROXY ALL_PROXY NO_PROXY

# ------------------------------------------------------------
# Получаем текущее состояние системного proxy
# ------------------------------------------------------------

mode=$(gsettings get org.gnome.system.proxy mode 2>/dev/null | tr -d "'")

# ------------------------------------------------------------
# Если proxy выключен — оставляем environment чистым
# ------------------------------------------------------------

[ "$mode" = "manual" ] || return

# ------------------------------------------------------------
# HTTP / FTP
# ------------------------------------------------------------

http_host=$(gsettings get org.gnome.system.proxy.http host 2>/dev/null | tr -d "'")
http_port=$(gsettings get org.gnome.system.proxy.http port 2>/dev/null)

if [ -n "$http_host" ] && [ "$http_port" -gt 0 ] 2>/dev/null; then
    export http_proxy="http://$http_host:$http_port"
    export ftp_proxy="ftp://$http_host:$http_port"
fi

# ------------------------------------------------------------
# HTTPS
# ------------------------------------------------------------

https_host=$(gsettings get org.gnome.system.proxy.https host 2>/dev/null | tr -d "'")
https_port=$(gsettings get org.gnome.system.proxy.https port 2>/dev/null)

if [ -n "$https_host" ] && [ "$https_port" -gt 0 ] 2>/dev/null; then
    export https_proxy="http://$https_host:$https_port"
fi

# ------------------------------------------------------------
# SOCKS
# ------------------------------------------------------------

socks_host=$(gsettings get org.gnome.system.proxy.socks host 2>/dev/null | tr -d "'")
socks_port=$(gsettings get org.gnome.system.proxy.socks port 2>/dev/null)

if [ -n "$socks_host" ] && [ "$socks_port" -gt 0 ] 2>/dev/null; then
    export all_proxy="socks5h://$socks_host:$socks_port"
fi

# ------------------------------------------------------------
# Исключения
# ------------------------------------------------------------

no_proxy=$(
    gsettings get org.gnome.system.proxy ignore-hosts 2>/dev/null |
    tr -d "[]'" |
    tr ',' '\n' |
    tr -d ' ' |
    paste -sd,
)

[ -n "$no_proxy" ] && export no_proxy

# ------------------------------------------------------------
# Дубли в UPPERCASE
# ------------------------------------------------------------

[ -n "$http_proxy"  ] && export HTTP_PROXY="$http_proxy"
[ -n "$https_proxy" ] && export HTTPS_PROXY="$https_proxy"
[ -n "$ftp_proxy"   ] && export FTP_PROXY="$ftp_proxy"
[ -n "$all_proxy"   ] && export ALL_PROXY="$all_proxy"
[ -n "$no_proxy"    ] && export NO_PROXY="$no_proxy"
