-- Configuração do Hyprland aninhado usado para testar o Lucerna.
-- Mod é ALT para não conflitar com os atalhos do KDE no host.

hl.monitor({
    output   = "",
    mode     = "1600x900",
    position = "auto",
    scale    = 1,
})

hl.on("hyprland.start", function()
    hl.exec_cmd("quickshell -c lucerna")
end)

hl.config({
    input = {
        kb_layout = "br",
    },
    misc = {
        disable_hyprland_logo    = true,
        disable_splash_rendering = true,
        force_default_wallpaper  = 0,
    },
    ecosystem = {
        no_update_news   = true,
        no_donation_nag  = true,
    },
})

local mod = "ALT"

hl.bind(mod .. " + Return",    hl.dsp.exec_cmd("kitty"))
hl.bind(mod .. " + Q",         hl.dsp.window.close())
hl.bind(mod .. " + SHIFT + R", hl.dsp.exec_cmd("pkill -x quickshell; quickshell -c lucerna"))
hl.bind(mod .. " + SHIFT + E", hl.dsp.exit())

for i = 1, 4 do
    hl.bind(mod .. " + " .. i,         hl.dsp.focus({ workspace = i }))
    hl.bind(mod .. " + SHIFT + " .. i, hl.dsp.window.move({ workspace = i }))
end
