# xde-proxy-gui
# CLI proxy environment

# Не экспортировать proxy в графическую сессию.
# Только интерактивные shell.

case "$-" in
*i*)
;;
*)
return 0 2>/dev/null || exit 0
;;
esac

# Если proxy уже пришёл из родительского environment
# (например, через su -p) — ничего не переопределяем.
if [ -n "$http_proxy" ] ||
   [ -n "$https_proxy" ] ||
   [ -n "$ftp_proxy" ] ||
   [ -n "$all_proxy" ]; then
    return 0
fi

PROXY_ENV="/usr/libexec/xde-proxy-gui/proxy-env.sh"

if [ -r "$PROXY_ENV" ]; then
    . "$PROXY_ENV"
fi
