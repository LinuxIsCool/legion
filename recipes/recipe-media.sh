#!/usr/bin/env bash
# recipe-media.sh — terminal media tools: kitty, Yazi, mpv, ffmpeg.
# Configs and the imgt/mpvt viewers come from chezmoi (~/.local/bin, ~/.config/yazi, ~/.config/mpv).
# imgt runs through uv (recipe-uv).
source "$(dirname "$0")/../lib/utils.sh"

check() {
    has_cmd kitty && has_cmd yazi && has_cmd mpv && has_cmd ffmpeg
}

install() {
    local pkg
    for pkg in kitty yazi mpv ffmpeg; do
        if has_cmd "$pkg"; then
            log_skip "$pkg"
        else
            install_pacman "$pkg" || return 1
        fi
    done
}

main() {
    if check; then
        log_skip "media"
    else
        install
    fi
}

main "$@"
