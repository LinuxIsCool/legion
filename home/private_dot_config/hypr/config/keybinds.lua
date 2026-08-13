local mainMod = "SUPER"
local noctCall = "qs -c noctalia-shell ipc call "
local launchPrefix = "uwsm app -- " -- if you are not using UWSM, make this empty (e.g. "")

---------------------------
---- WINDOW MANAGEMENT ----
---------------------------

hl.bind(mainMod .. " + Escape",      hl.dsp.exec_cmd("hyprctl kill"))
hl.bind(mainMod .. " + Q",           hl.dsp.window.close())
hl.bind(mainMod .. " + ALT + Space", hl.dsp.window.float({ action = "toggle" }))
hl.bind(mainMod .. " + D",           hl.dsp.window.fullscreen({ mode = 1 }))
hl.bind(mainMod .. " + F",           hl.dsp.window.fullscreen())
hl.bind("F11",                       hl.dsp.window.fullscreen())
hl.bind(mainMod .. " + backslash",   hl.dsp.layout("togglesplit"))
hl.bind(mainMod .. " + ALT + L",     hl.dsp.exec_cmd(noctCall .. " lockScreen lock"))
hl.bind(mainMod .. " + ALT + C",     hl.dsp.exec_cmd(noctCall .. " sessionMenu toggle"))

-- Change focus
-- hjkl = window nav WITHIN the current workspace only. Spatial step first; at a true
-- edge it wraps to the far window on that axis, like panes in a tmux window.
-- Workspace switching lives on Super+N/P, Super+Left/Right and Super+[0-9].
hl.bind(mainMod .. " + H",     hl.dsp.exec_cmd("/home/shawn/.config/hypr/super-nav.sh nav left"))
hl.bind(mainMod .. " + L",     hl.dsp.exec_cmd("/home/shawn/.config/hypr/super-nav.sh nav right"))
hl.bind(mainMod .. " + K",     hl.dsp.exec_cmd("/home/shawn/.config/hypr/super-nav.sh nav up"))
hl.bind(mainMod .. " + J",     hl.dsp.exec_cmd("/home/shawn/.config/hypr/super-nav.sh nav down"))

-- Unstick keyboard focus after the launcher (exclusiveKeyboard) + Escape orphans it.
-- Replays the proven focus right-then-left nudge in one key (Hyprland binds fire even when stuck).
hl.bind(mainMod .. " + U", hl.dsp.exec_cmd("bash -c '/home/shawn/.config/hypr/super-nav.sh focus right; /home/shawn/.config/hypr/super-nav.sh focus left'"))

-- Arrows: Left/Right = prev/next workspace; Up/Down = scroll windows in the current workspace.
-- (SHIFT moves the active window: Left/Right = to prev/next workspace, Up/Down = within workspace.)
hl.bind(mainMod .. " + Left",          hl.dsp.focus({ workspace = "e-1" }))
hl.bind(mainMod .. " + Right",         hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + Up",            hl.dsp.exec_cmd("/home/shawn/.config/hypr/super-nav.sh cycle prev"))
hl.bind(mainMod .. " + Down",          hl.dsp.exec_cmd("/home/shawn/.config/hypr/super-nav.sh cycle next"))
hl.bind(mainMod .. " + SHIFT + Left",  hl.dsp.window.move({ workspace = "e-1", follow = true }))
hl.bind(mainMod .. " + SHIFT + Right", hl.dsp.window.move({ workspace = "e+1", follow = true }))
hl.bind(mainMod .. " + SHIFT + Up",    hl.dsp.window.move({ direction = "u" }))
hl.bind(mainMod .. " + SHIFT + Down",  hl.dsp.window.move({ direction = "d" }))
hl.bind("ALT + Tab",         hl.dsp.exec_cmd("python3 /home/shawn/.config/hypr/alttab-cmd.py open"))
hl.bind("ALT + SHIFT + Tab", hl.dsp.exec_cmd("python3 /home/shawn/.config/hypr/alttab-cmd.py prev"))

-- Move the active window WITHIN the current workspace: rearrange the existing split.
-- Never crosses workspaces. To send a window to another workspace use SHIFT+N/P,
-- SHIFT+Left/Right, or SHIFT+[0-9].
hl.bind(mainMod .. " + SHIFT + H", hl.dsp.window.move({ direction = "l" }))
hl.bind(mainMod .. " + SHIFT + L", hl.dsp.window.move({ direction = "r" }))
hl.bind(mainMod .. " + SHIFT + K", hl.dsp.window.move({ direction = "u" }))
hl.bind(mainMod .. " + SHIFT + J", hl.dsp.window.move({ direction = "d" }))
hl.bind(mainMod .. " + CONTROL + SHIFT + L", hl.dsp.window.move({ workspace = "r+1" }))
hl.bind(mainMod .. " + CONTROL + SHIFT + H", hl.dsp.window.move({ workspace = "r-1" }))

-- Move & Resize with mouse
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag())
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize())

------------------
---- LAUNCHER ----
------------------

hl.bind(mainMod .. " + Return",     hl.dsp.exec_cmd(launchPrefix .. TERMINAL))
hl.bind(mainMod .. " + E",          hl.dsp.exec_cmd(launchPrefix .. FILE_MANAGER))
hl.bind(mainMod .. " + T",          hl.dsp.exec_cmd(launchPrefix .. EDITOR))
hl.bind(mainMod .. " + C",          hl.dsp.exec_cmd(launchPrefix .. CALCULATOR))
hl.bind(mainMod .. " + W",          hl.dsp.exec_cmd(launchPrefix .. BROWSER))
hl.bind("CONTROL + SHIFT + Escape", hl.dsp.exec_cmd(launchPrefix .. TERMINAL .. " -e btop"))
hl.bind(mainMod .. " + Z",          hl.dsp.exec_cmd(noctCall .. "settings toggle"))
hl.bind(mainMod .. " + X",          hl.dsp.exec_cmd(noctCall .. "controlCenter toggle"))
hl.bind(mainMod .. " + Space",      hl.dsp.exec_cmd(noctCall .. "launcher toggle"))
hl.bind(mainMod .. " + Super_L",   hl.dsp.exec_cmd(noctCall .. "launcher toggle"), { release = true })
hl.bind(mainMod .. " + period",     hl.dsp.exec_cmd(noctCall .. "launcher emoji"))

---------------------------
---- HARDWARE CONTROLS ----
---------------------------

-- Audio
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd(noctCall .. "volume increase"),   { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd(noctCall .. "volume decrease"),   { locked = true, repeating = true })
hl.bind("XF86AudioMute",        hl.dsp.exec_cmd(noctCall .. "volume muteOutput"), { locked = true, repeating = true })
hl.bind("XF86AudioMicMute",     hl.dsp.exec_cmd(noctCall .. "volume muteInput"),  { locked = true, repeating = true })

-- Media
hl.bind("XF86AudioPlay",  hl.dsp.exec_cmd(noctCall .. "media playPause"), { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd(noctCall .. "media playPause"), { locked = true })
hl.bind("XF86AudioNext",  hl.dsp.exec_cmd(noctCall .. "media next"),      { locked = true })
hl.bind("XF86AudioPrev",  hl.dsp.exec_cmd(noctCall .. "media previous"),  { locked = true })

-- Brightness
hl.bind("XF86MonBrightnessUp",   hl.dsp.exec_cmd(noctCall .. "brightness increase"), { repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd(noctCall .. "brightness decrease"), { repeating = true })

-------------------
---- UTILITIES ----
-------------------

-- Screen Capture
hl.bind("CONTROL + Print",     hl.dsp.exec_cmd(noctCall .. "plugin:screen-toolkit annotateWindow"))
hl.bind(mainMod .. " + Print", hl.dsp.exec_cmd(noctCall .. "plugin:screen-toolkit colorPicker"))
hl.bind("Print",               hl.dsp.exec_cmd(noctCall .. "plugin:screen-toolkit annotate"))
hl.bind(mainMod .. " + R",     hl.dsp.exec_cmd(noctCall .. "plugin:screen-toolkit toggle"))
-- Home-row screenshots (→ Wayland clipboard via ~/.local/bin/hr-screenshot)
hl.bind(mainMod .. " + G",           hl.dsp.exec_cmd("/home/shawn/.local/bin/hr-screenshot window"))  -- active window, NO mouse
hl.bind(mainMod .. " + SHIFT + G",   hl.dsp.exec_cmd("/home/shawn/.local/bin/hr-screenshot area"))    -- drag-select region (needs pointer)
hl.bind(mainMod .. " + CONTROL + G", hl.dsp.exec_cmd("/home/shawn/.local/bin/hr-screenshot full"))    -- whole monitor

-- Theming and Wallpaper
hl.bind(mainMod .. " + SHIFT + W", hl.dsp.exec_cmd(noctCall .. " wallpaper toggle"))

-- Clipboard
hl.bind(mainMod .. " + V", hl.dsp.exec_cmd(noctCall .. "launcher clipboard"))

-- Cheat sheet
hl.bind(mainMod .. " + slash", hl.dsp.exec_cmd("kitty --title hypr-cheatsheet sh -c 'python3 ~/.config/hypr/cheatsheet.py | less -R'"))

--------------------
---- WORKSPACES ----
--------------------

for i = 1, 10 do
    local key = i % 10
    hl.bind(mainMod .. " + " .. key,         hl.dsp.focus({ workspace = i }))
    hl.bind(mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i, follow = true }))
    hl.bind(mainMod .. " + ALT + " .. key,   hl.dsp.window.move({ workspace = i, follow = false }))
end

-- N/P = go to next/prev workspace. SHIFT = take the active window along.
hl.bind(mainMod .. " + N",                  hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + P",                  hl.dsp.focus({ workspace = "e-1" }))
hl.bind(mainMod .. " + SHIFT + N",          hl.dsp.window.move({ workspace = "e+1", follow = true }))
hl.bind(mainMod .. " + SHIFT + P",          hl.dsp.window.move({ workspace = "e-1", follow = true }))
hl.bind(mainMod .. " + CONTROL + L",       hl.dsp.focus({ workspace = "r+1" }))
hl.bind(mainMod .. " + CONTROL + H",       hl.dsp.focus({ workspace = "r-1" }))
hl.bind(mainMod .. " + CONTROL + J",       hl.dsp.focus({ workspace = "empty" }))
hl.bind(mainMod .. " + CONTROL + ALT + L", hl.dsp.window.move({ workspace = "r+1" }))
hl.bind(mainMod .. " + CONTROL + ALT + H", hl.dsp.window.move({ workspace = "r-1" }))

-- Scroll through existing workspaces
hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + mouse_up",   hl.dsp.focus({ workspace = "e-1" }))

-- Special workspace (scratchpad)
hl.bind(mainMod .. " + SHIFT + S", hl.dsp.window.move({ workspace = "special" }))
hl.bind(mainMod .. " + S",         hl.dsp.workspace.toggle_special())

-----------------------
---- NOTIFICATIONS ----
-----------------------

hl.bind(mainMod .. " + A", hl.dsp.exec_cmd(noctCall .. "notifications toggleHistory"))
