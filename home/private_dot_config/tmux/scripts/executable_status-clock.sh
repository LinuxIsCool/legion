#!/bin/sh
# Bypass tmux's cached timezone and any inherited TZ override.
case "${1:-time}" in
    date) exec /usr/bin/env TZ=:/etc/localtime /usr/bin/date '+%A %B %d %F' ;;
    time) exec /usr/bin/env TZ=:/etc/localtime /usr/bin/date '+%H:%M %Z' ;;
    *) exit 2 ;;
esac
