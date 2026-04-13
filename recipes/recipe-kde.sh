#!/usr/bin/env bash
# recipe-kde.sh — configure KDE Plasma 6 settings via kwriteconfig6
source "$(dirname "$0")/../lib/utils.sh"

check() {
    # Check a representative setting
    local scale
    scale="$(kreadconfig6 --file kwinrc --group Xwayland --key Scale 2>/dev/null)"
    [[ "$scale" == "1.25" ]]
}

install() {
    if ! has_cmd kwriteconfig6; then
        log_fail "kwriteconfig6 not found — is KDE Plasma installed?"
        return 1
    fi

    log_info "Configuring KDE Plasma settings"

    # Display scale
    kwriteconfig6 --file kwinrc --group Xwayland --key Scale 1.25

    # Window tiling
    kwriteconfig6 --file kwinrc --group Tiling --key Enabled true

    # Default terminal
    kwriteconfig6 --file kdeglobals --group General --key TerminalApplication alacritty
    kwriteconfig6 --file kdeglobals --group General --key TerminalService Alacritty.desktop

    # Mouse natural scrolling (for trackpad machines)
    # This is per-device and may need manual config via System Settings

    # Theme
    kwriteconfig6 --file kdeglobals --group KDE --key LookAndFeelPackage "org.kde.breezedark.desktop"

    # Key repeat — fast repeat speed (140ms delay, 40 chars/sec)
    kwriteconfig6 --file kcminputrc --group Keyboard --key RepeatDelay 140
    kwriteconfig6 --file kcminputrc --group Keyboard --key RepeatRate 40

    # Disable splash screen
    kwriteconfig6 --file ksplashrc --group KSplash --key Engine none
    kwriteconfig6 --file ksplashrc --group KSplash --key Theme None

    log_info "Restart KDE or log out/in to apply changes"
    log_ok "kde"
}

main() {
    if check; then
        log_skip "kde"
    else
        install
    fi
}

main "$@"
