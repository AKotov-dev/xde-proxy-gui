# xde-proxy-gui
# CLI proxy environment
#
# Не экспортировать proxy в графическую сессию.
# Только интерактивные shell.

case "$-" in
    *i*)
        ;;
    *)
        return 0 2>/dev/null || exit 0
        ;;
esac

PROXY_ENV="/usr/libexec/xde-proxy-gui/proxy-env.sh"

if [ -r "$PROXY_ENV" ]; then
    . "$PROXY_ENV"
fi
