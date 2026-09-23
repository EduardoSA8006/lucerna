#!/bin/sh
# Estado das GPUs, uma por linha:
#   card|fabricante|pci|estado|nome|uso%|temp°C|freq MHz|freq máx MHz
# Campos desconhecidos ficam vazios. Não acorda uma GPU NVIDIA em repouso:
# o nvidia-smi só roda se o runtime PM disser que a placa já está ativa.

for card in /sys/class/drm/card[0-9]*; do
    case "$card" in *-*) continue ;; esac
    dev="$card/device"
    [ -r "$dev/vendor" ] || continue
    pci="$(basename "$(readlink -f "$dev")")"
    state="$(cat "$dev/power/runtime_status" 2>/dev/null)"
    [ "$state" = suspended ] && state=suspended || state=active
    name="" usage="" temp="" freq="" max=""

    case "$(cat "$dev/vendor")" in
    0x10de)
        vendor=nvidia
        name="$(sed -n 's/^Model:[[:space:]]*//p' "/proc/driver/nvidia/gpus/$pci/information" 2>/dev/null)"
        if [ "$state" = active ] && command -v nvidia-smi >/dev/null 2>&1; then
            IFS=', ' read -r usage temp freq max <<-END
$(nvidia-smi -i "$pci" --query-gpu=utilization.gpu,temperature.gpu,clocks.gr,clocks.max.gr --format=csv,noheader,nounits 2>/dev/null)
END
        fi
        ;;
    0x1002)
        vendor=amd
        usage="$(cat "$dev/gpu_busy_percent" 2>/dev/null)"
        t="$(cat "$dev"/hwmon/hwmon*/temp1_input 2>/dev/null | head -n1)"
        [ -n "$t" ] && temp=$((t / 1000))
        ;;
    0x8086)
        vendor=intel
        freq="$(cat "$card/gt_act_freq_mhz" 2>/dev/null || cat "$dev/tile0/gt0/freq0/act_freq" 2>/dev/null)"
        max="$(cat "$card/gt_RP0_freq_mhz" 2>/dev/null || cat "$dev/tile0/gt0/freq0/rp0_freq" 2>/dev/null)"
        ;;
    *) continue ;;
    esac

    echo "$(basename "$card")|$vendor|$pci|$state|$name|$usage|$temp|$freq|$max"
done
