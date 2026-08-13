-- Input configuration

hl.config({
    input = {
        accel_profile = "flat",
        repeat_rate = 55,    -- was 50 (+10%)
        repeat_delay = 270,  -- was 300 (-10%)
        follow_mouse = 1,   -- focus follows mouse: hovering a window focuses it (keyboard + mouse)
    },
})

hl.gesture({ fingers = 4, direction = "horizontal", action = "workspace" })
hl.gesture({ fingers = 3, direction = "down",       action = "close" })
hl.gesture({ fingers = 3, direction = "up",         action = "fullscreen" })
hl.gesture({ fingers = 3, direction = "left",       action = "float" })
