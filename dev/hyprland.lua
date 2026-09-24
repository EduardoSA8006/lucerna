-- Configuração do Hyprland aninhado usado para testar o Lucerna.
-- Mod é ALT para não conflitar com os atalhos do KDE no host.

hl.monitor({
    output   = "",
    mode     = "1920x1080",
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

-- Os atalhos do Lucerna (painéis, bloqueio, som, mídia e brilho) ficam com o
-- próprio shell: Configurações → Atalhos. Aqui, só os do Hyprland.

-- Volume e brilho sem teclas de mídia (no host, elas ficam com o KDE)
hl.bind(mod .. " + Up",    hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"), { repeating = true })
hl.bind(mod .. " + Down",  hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),      { repeating = true })
hl.bind(mod .. " + M",     hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"))
hl.bind(mod .. " + Right", hl.dsp.exec_cmd(ipc .. "brightness up"),   { repeating = true })
hl.bind(mod .. " + Left",  hl.dsp.exec_cmd(ipc .. "brightness down"), { repeating = true })

for i = 1, 5 do
    hl.bind(mod .. " + " .. i,         hl.dsp.focus({ workspace = i }))
    hl.bind(mod .. " + SHIFT + " .. i, hl.dsp.window.move({ workspace = i }))
end
hl.bind(mod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mod .. " + mouse_up",   hl.dsp.focus({ workspace = "e-1" }))

-- Arranjo de monitores salvo pelo Lucerna (Configurações → Monitores →
-- "Usar o arranjo desde o login"). Sem o arquivo, não faz nada.
pcall(dofile, os.getenv("HOME") .. "/.config/hypr/lucerna-monitors.lua")
