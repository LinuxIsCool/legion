#!/usr/bin/env bash
# recipe-services.sh — enable Legion systemd user services
source "$(dirname "$0")/../lib/utils.sh"

check() {
    systemctl --user is-enabled legion.target &>/dev/null
}

install() {
    log_info "Reloading systemd user daemon"
    systemctl --user daemon-reload

    # Enable the main target (which pulls in all core services)
    log_info "Enabling legion.target"
    systemctl --user enable legion.target

    # Enable timers
    local timers=(
        btrfs-balance-reminder.timer
        legion-pageindex-refresh.timer
        legion-transcribe.timer
        rhythm-morning-brief.timer
        rhythm-midday-brief.timer
        rhythm-evening-brief.timer
        rhythm-comms-pulse.timer
        rhythm-comms-digest.timer
        rhythm-capacity-review.timer
        rhythm-weekly-evaluation.timer
    )

    for timer in "${timers[@]}"; do
        if systemctl --user cat "$timer" &>/dev/null; then
            systemctl --user enable "$timer"
            log_info "Enabled: ${timer}"
        fi
    done

    # Start everything
    log_info "Starting legion.target"
    systemctl --user start legion.target

    # Start timers
    for timer in "${timers[@]}"; do
        if systemctl --user is-enabled "$timer" &>/dev/null; then
            systemctl --user start "$timer" 2>/dev/null || true
        fi
    done

    log_ok "services"
}

main() {
    if check; then
        log_skip "services"
    else
        install
    fi
}

main "$@"
