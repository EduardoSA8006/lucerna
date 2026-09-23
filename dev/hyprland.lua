-- Configuração do Hyprland aninhado usado para testar o Lucerna.
-- Mod é ALT para não conflitar com os atalhos do KDE no host.

hl.monitor({
    output   = "",
    mode     = "1600x900",
    position = "auto",
    scale    = 1,
})

hl.on("hyprland.start", function()
    hl.exec_cmd("qs -c lucerna")
end)

hl.config({
    general = {
        gaps_in     = 4,
        gaps_out    = 10,
        border_size = 2,
    },
    input = {
        kb_layout = "br",
    },
    misc = {
        disable_hyprland_logo    = true,
        disable_splash_rendering = true,
        force_default_wallpaper  = 0,
    },
    ecosystem = {
        no_update_news  = true,
        no_donation_nag = true,
    },
})

local mod = "ALT"
local ipc = "qs -c lucerna ipc call "

hl.bind(mod .. " + Return",    hl.dsp.exec_cmd("kitty"))
hl.bind(mod .. " + Q",         hl.dsp.window.close())
hl.bind(mod .. " + SHIFT + R", hl.dsp.exec_cmd("pkill -x qs; qs -c lucerna"))
hl.bind(mod .. " + SHIFT + E", hl.dsp.exit())

-- Lucerna
hl.bind(mod .. " + Space",  hl.dsp.exec_cmd(ipc .. "panels toggle launcher"))
hl.bind(mod .. " + D",      hl.dsp.exec_cmd(ipc .. "panels toggle dashboard"))
hl.bind(mod .. " + S",      hl.dsp.exec_cmd(ipc .. "panels toggle settings"))
hl.bind(mod .. " + N",      hl.dsp.exec_cmd(ipc .. "sidebar toggle notifications"))
hl.bind(mod .. " + C",      hl.dsp.exec_cmd(ipc .. "sidebar toggle \"\""))
hl.bind(mod .. " + T",      hl.dsp.exec_cmd(ipc .. "panels toggle themes"))
hl.bind(mod .. " + Escape", hl.dsp.exec_cmd(ipc .. "panels toggle power"))
hl.bind(mod .. " + L",      hl.dsp.exec_cmd(ipc .. "session lock"))

-- Volume e brilho (as teclas de mídia costumam ficar com o KDE do host)
hl.bind(mod .. " + Up",    hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"), { repeating = true })
hl.bind(mod .. " + Down",  hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),      { repeating = true })
hl.bind(mod .. " + M",     hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"))
hl.bind(mod .. " + Right", hl.dsp.exec_cmd(ipc .. "brightness up"),   { repeating = true })
hl.bind(mod .. " + Left",  hl.dsp.exec_cmd(ipc .. "brightness down"), { repeating = true })
hl.bind("XF86AudioRaiseVolume",  hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"), { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume",  hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),      { locked = true, repeating = true })
hl.bind("XF86AudioMute",         hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),     { locked = true })
hl.bind("XF86MonBrightnessUp",   hl.dsp.exec_cmd(ipc .. "brightness up"),   { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd(ipc .. "brightness down"), { locked = true, repeating = true })

for i = 1, 5 do
    hl.bind(mod .. " + " .. i,         hl.dsp.focus({ workspace = i }))
    hl.bind(mod .. " + SHIFT + " .. i, hl.dsp.window.move({ workspace = i }))
end
hl.bind(mod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mod .. " + mouse_up",   hl.dsp.focus({ workspace = "e-1" }))
