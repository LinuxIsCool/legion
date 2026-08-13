-- Auto-start config
-- if you dont use UWSM add your auto start programs here, otherwise use XDG autostart https://wiki.archlinux.org/title/XDG_Autostart

hl.on("hyprland.start", function ()
    hl.exec_cmd("dbus-update-activation-environment --systemd --all")
    hl.exec_cmd("qs -c noctalia-shell")
    hl.exec_cmd("xhost +SI:localuser:root")
    hl.exec_cmd("LD_PRELOAD=/usr/lib/libgtk4-layer-shell.so python3 /home/shawn/.config/hypr/alttab-overlay.py &")
end)
