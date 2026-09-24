#!/bin/sh
# Prepara um vídeo ou GIF para ser papel de parede, gastando o mínimo para tocar:
#   - resolução da tela (e já recortado na proporção dela, se for preencher):
#     o decodificador só trabalha nos pixels que aparecem; menor que a tela, não
#     é ampliado aqui (a GPU amplia ao desenhar, quase de graça);
#   - quadros por segundo limitados e quadros repetidos removidos (taxa variável):
#     GIFs seguram o mesmo quadro por vários ciclos, e sem repetição o
#     decodificador fica parado;
#   - H.264 (decodificado por hardware em qualquer GPU com VA-API); sem VA-API,
#     "fastdecode", mais leve na CPU;
#   - sem áudio, GOP longo e começo em quadro-chave, para o loop não saltar;
#   - tarjas pretas (letterbox) detectadas e cortadas: preenche a tela de verdade
#     e não se decodificam pixels pretos;
#   - uma capa (o primeiro quadro), para o modo parado e enquanto carrega.
# O resultado fica em cache: a chave é o arquivo (caminho, tamanho, data) e os
# parâmetros.
#
# Uso: video-wallpaper.sh ENTRADA PASTA LARGURA ALTURA FPS RECORTAR(0|1) HW(0|1) [NÚCLEOS]
# (NÚCLEOS limita as threads do codificador; 0 ou vazio = todas.)
# Saída: linhas "progress <0-100>" e, no fim, "done <vídeo> <capa>" ou "error <texto>".
in=$1 dir=$2 tw=$3 th=$4 cap=$5 crop=$6 hw=$7 threads=${8:-0}

fail() { echo "error $*"; exit 1; }
[ -f "$in" ] || fail "arquivo não encontrado"
command -v ffmpeg >/dev/null && command -v ffprobe >/dev/null || fail "ffmpeg não está instalado"
mkdir -p "$dir" || fail "não foi possível criar a pasta do cache"

key=$(printf '%s|%s|%s' "$in" "$(stat -c '%s %Y' "$in")" "$tw $th $cap $crop $hw v3" | md5sum | cut -c1-16)
out="$dir/$key.mp4"
poster="$dir/$key.jpg"
if [ -s "$out" ] && [ -s "$poster" ]; then
    echo "done $out $poster"
    exit 0
fi

# Largura, altura, taxa média, codec e duração do vídeo de entrada.
info=$(ffprobe -v error -select_streams v:0 -show_entries stream=width,height,avg_frame_rate,r_frame_rate,codec_name:format=duration -of default=nw=1 "$in") || fail "não é um vídeo que o ffmpeg abra"
get() { printf '%s\n' "$info" | sed -n "s/^$1=//p" | head -1; }
sw=$(get width) sh=$(get height) codec=$(get codec_name) dur=$(get duration)
rate=$(get avg_frame_rate); [ "$rate" = "0/0" ] && rate=$(get r_frame_rate)
[ -n "$sw" ] && [ -n "$sh" ] || fail "não achei a imagem do vídeo"

# Tarjas pretas: o cropdetect olha os primeiros segundos e diz a área útil.
# Só vale se cortar algo de verdade (mais de 1% de um lado).
borders=""
detect=$(ffmpeg -hide_banner -nostats -t 4 -i "$in" -map 0:v:0 -vf "cropdetect=limit=20:round=2:reset=0" -f null - 2>&1 | sed -n 's/.*crop=\([0-9]*:[0-9]*:[0-9]*:[0-9]*\).*/\1/p' | tail -1)
if [ -n "$detect" ]; then
    cw=${detect%%:*}; rest=${detect#*:}; ch=${rest%%:*}
    if [ "$cw" -gt 0 ] && [ "$ch" -gt 0 ]; then
        if [ $((cw * 100)) -lt $((sw * 99)) ] || [ $((ch * 100)) -lt $((sh * 99)) ]; then
            borders="crop=$detect,"
            sw=$cw sh=$ch
        fi
    fi
fi

# Conta com awk: fps final, tamanho final (par) e se é animação (GIF/APNG/WebP).
eval "$(awk -v sw="$sw" -v sh="$sh" -v tw="$tw" -v th="$th" -v rate="$rate" -v cap="$cap" -v crop="$crop" 'BEGIN {
    split(rate, r, "/"); fps = (r[2] > 0) ? r[1] / r[2] : cap
    if (fps <= 0 || fps > 240) fps = cap
    if (fps > cap) fps = cap
    if (crop == 1) {
        # Cobre a tela: escala para cobrir e recorta na proporção dela.
        k = (tw / sw > th / sh) ? tw / sw : th / sh
        if (k >= 1) { ow = sw; oh = sw * th / tw; if (oh > sh) { oh = sh; ow = sh * tw / th } }
        else { ow = tw; oh = th }
    } else {
        k = (tw / sw < th / sh) ? tw / sw : th / sh
        if (k > 1) k = 1
        ow = sw * k; oh = sh * k
    }
    ow = int(ow / 2) * 2; oh = int(oh / 2) * 2
    printf "fps=%.3f ow=%d oh=%d\n", fps, ow, oh
}')"

case "$codec" in gif | apng | webp) anim=1 ;; *) anim=0 ;; esac

if [ "$crop" = 1 ]; then
    size="scale=$ow:$oh:force_original_aspect_ratio=increase:flags=lanczos,crop=$ow:$oh"
else
    size="scale=$ow:$oh:flags=lanczos"
fi
# Tira só os quadros praticamente iguais ao anterior (os que um GIF segura) e
# deixa a taxa variável. Os limites são baixos de propósito: um movimento lento
# muda pouco de um quadro para o outro, e cortar esses deixaria o movimento aos
# saltos.
filters="${borders}fps=$fps,mpdecimate=hi=64:lo=32:frac=0.1,$size,format=yuv420p"

tune=""
[ "$anim" = 1 ] && tune="-tune animation"
[ "$hw" = 0 ] && tune="-tune fastdecode"
gop=$(awk -v f="$fps" 'BEGIN { printf "%d", f * 10 }')

tmp="$out.part.mp4"
ffmpeg -y -hide_banner -v error -nostats -progress pipe:1 -i "$in" \
    -an -sn -dn -map 0:v:0 -vf "$filters" -fps_mode vfr \
    -c:v libx264 -preset medium -crf 22 -profile:v high -pix_fmt yuv420p -threads "$threads" \
    -g "$gop" -bf 2 $tune -movflags +faststart "$tmp" 2>"$tmp.log" |
    awk -v dur="$dur" -F= '$1 == "out_time_us" && dur > 0 { p = int($2 / 10000 / dur); if (p > 99) p = 99; if (p >= 0 && p != last) { print "progress " p; fflush(); last = p } }'

if [ ! -s "$tmp" ]; then
    msg=$(tail -1 "$tmp.log")
    rm -f "$tmp" "$tmp.log"
    fail "${msg:-a conversão falhou}"
fi
rm -f "$tmp.log"
mv "$tmp" "$out"
ffmpeg -y -v error -i "$out" -frames:v 1 -q:v 3 "$poster" || fail "não consegui tirar a capa"
echo "progress 100"
echo "done $out $poster"
