local mod = "SUPER"
local menu = "wofi --show drun"
local terminal = "konsole"
local screenshot = "grimblast --freeze copy area"

hl.on("hyprland.start", function()
    hl.exec_cmd("nm-applet --indicator")
    hl.exec_cmd("blueman-applet")
    hl.exec_cmd("trevbar")
end)

hl.env("QT_QPA_PLATFORMTHEME", "qt5ct")

-- Display configuration
hl.monitor({
    output = "eDP-1",
    mode = "preferred",
    position = "auto",
    scale = 1,
})

hl.monitor({
    output = "desc:XXX Beyond TV 0x00010000",
    mode = "3840x2160@120",
    position = "auto",
    scale = 2,
})

hl.monitor({
    output = "desc:Dell Inc. DELL S2725QS 4TYKT84",
    mode = "3840x2160@60",
    position = "auto",
    scale = "auto",
})

hl.monitor({
    output = "desc:Philips Consumer Electronics Company PHL 221V8LB UK02442041972",
    mode = "1920x1080@100",
    position = "auto",
    scale = "auto",
})

hl.monitor({
    output = "desc:Dell Inc. DELL S2725QS 137GT84",
    mode = "3840x2160@120",
    position = "auto",
    scale = "auto",
})

hl.monitor({
    output = "desc:Dell Inc. DELL S2725QS JGKHT84",
    mode = "3840x2160@120",
    position = "auto",
    scale = "auto",
})

hl.monitor({
    output = "",
    mode = "preferred",
    position = "auto",
    scale = "auto",
})

hl.config({
    xwayland = {
        force_zero_scaling = true,
    },
    general = {
        gaps_in = 5,
        gaps_out = 20,
        border_size = 2,
        col = {
            active_border = {
                colors = { "rgba(33ccffee)", "rgba(00ff99ee)" },
                angle = 45,
            },
            inactive_border = "rgba(595959aa)",
        },
        layout = "master",
        allow_tearing = false,
    },
    decoration = {
        rounding = 10,
        blur = {
            enabled = true,
            size = 3,
            passes = 1,
        },
    },
    animations = {
        enabled = true,
    },
    master = {
        mfact = 0.5,
    },
    misc = {
        force_default_wallpaper = 0,
    },
    input = {
        kb_layout = "us",
        follow_mouse = 1,
    },
    group = {
        col = {
            border_active = {
                colors = { "rgba(ff9900ee)", "rgba(ff1a00ee)" },
                angle = 45,
            },
            border_inactive = "rgba(595959aa)",
        },
        groupbar = {
            enabled = false,
            font_size = 14,
            col = {
                active = "rgba(1e1e2eee)",
                inactive = "rgba(11111bee)",
            },
        },
    },
    binds = {
        scroll_event_delay = 100,
    },
})

hl.curve("myBezier", {
    type = "bezier",
    points = {
        { 0.05, 0.9 },
        { 0.1, 1.05 },
    },
})

hl.animation({ leaf = "windows", enabled = true, speed = 7, bezier = "myBezier" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 7, bezier = "default", style = "popin 80%" })
hl.animation({ leaf = "border", enabled = true, speed = 10, bezier = "default" })
hl.animation({ leaf = "borderangle", enabled = true, speed = 8, bezier = "default" })
hl.animation({ leaf = "fade", enabled = true, speed = 7, bezier = "default" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 6, bezier = "default" })

hl.bind(mod .. " + C", hl.dsp.window.close())
hl.bind(mod .. " + SPACE", hl.dsp.exec_cmd(menu))
hl.bind(mod .. " + V", hl.dsp.window.float({ action = "toggle" }))
hl.bind(mod .. " + G", hl.dsp.layout("swapwithmaster"))
hl.bind(mod .. " + S", hl.dsp.exec_cmd(screenshot))
hl.bind(mod .. " + T", hl.dsp.group.toggle())
hl.bind(mod .. " + F", hl.dsp.window.fullscreen())

for workspace = 1, 9 do
    local key = tostring(workspace)

    hl.bind(mod .. " + " .. key, hl.dsp.focus({ workspace = key }))
    hl.bind(mod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = key }))
end

hl.bind(mod .. " + SHIFT + left", hl.dsp.focus({ workspace = "r-1" }))
hl.bind(mod .. " + SHIFT + right", hl.dsp.focus({ workspace = "r+1" }))

hl.bind(mod .. " + mouse_down", hl.dsp.group.prev())
hl.bind(mod .. " + mouse_up", hl.dsp.group.next())

hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl set 5%-"))
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("brightnessctl set 5%+"))

hl.bind(mod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind(mod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })
