-- Legion Hub desktop app.
--
-- The compositor owns the keybind: an app cannot grab a global key on
-- Wayland, so we invert the relationship -- Hyprland dispatches into the
-- app. SUPER+H is already taken (config/keybinds.lua:21, cross-workspace
-- focus nav), so this uses SUPER+B.
local mainMod = "SUPER"
local launchPrefix = "uwsm app -- " -- matches config/keybinds.lua; empty string if not using UWSM

hl.bind(mainMod .. " + B", hl.dsp.exec_cmd(launchPrefix .. "legion-hub-app --toggle"))

-- TILED, deliberately: the hub window takes a split alongside whatever is
-- already on the workspace -- it must never float over the terminal you are
-- working in. Do not change this to float = true or add a center/size rule.
-- (config/windowrules.lua's global suppress-maximize-events rule, class =
-- ".*", already covers this window too -- no separate suppress rule needed.)
--
-- Matches TWO classes until Task 5 lands:
--   legion-hub                        -- the real Tauri binary's window class (permanent)
--   brave-127\.0\.0\.1__-Default      -- the interim shim: Brave ignores --class
--                                         under native Wayland and self-assigns
--                                         an app_id from the URL host + profile
--                                         dir instead (confirmed by launch test).
-- Delete the second alternative (and this comment block) once Task 5's
-- Tauri binary replaces the shim and sets its own class natively.
local hubClass = "^(legion-hub|brave-127\\.0\\.0\\.1__-Default)$"

hl.window_rule({ match = { class = hubClass }, float = false })

-- Workspace 5 is Legion. The full scheme lives in config/windowrules.lua:
--   1=terminal  2=browser  3=messaging  4=media/recording  5=legion
-- Kept HERE rather than there so the whole Legion Hub window contract is one
-- file -- when the Tauri binary replaces the Brave shim, only this file changes.
hl.window_rule({ match = { class = hubClass }, workspace = 5 })
