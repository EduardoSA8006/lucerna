#!/bin/sh
# Contadores brutos de uso das GPUs, lidos do fdinfo do DRM (sem root: só dos
# processos do próprio usuário). A primeira linha é o instante da leitura, em ns
# (a média do começo e do fim, que a leitura leva ~100 ms); depois, uma linha por
# cliente (a fd repetida do mesmo cliente sai uma vez):
#   T|ns
#   driver|pdev|client-id|chave=valor,chave=valor
# As chaves são as do fdinfo sem o "drm-": i915 dá engine-<classe> (ns ocupados);
# xe dá cycles-<classe> e total-cycles-<classe>. A conta fica no SystemStats.
# Ler o fdinfo não acorda a GPU. Sem nenhuma linha de cliente, o kernel não o expõe.

t0="$(date +%s%N)"
out="$(grep -s -H -E '^drm-(driver|client-id|pdev|engine-|cycles-|total-cycles-)' /proc/[0-9]*/fdinfo/* 2>/dev/null |
    awk -F'[\t ]+' '
    function flush() { if (drv != "" && cid != "" && !((pdev, cid) in seen)) { seen[pdev, cid] = 1; print drv "|" pdev "|" cid "|" vals }; drv = cid = pdev = vals = "" }
    {
        split($1, a, ":"); file = a[1]
        if (file != last) { flush(); last = file }
        key = a[2]; val = $2
        if (key == "drm-driver") drv = val
        else if (key == "drm-client-id") cid = val
        else if (key == "drm-pdev") pdev = val
        else { sub(/^drm-/, "", key); vals = vals (vals == "" ? "" : ",") key "=" val }
    }
    END { flush() }')"
t1="$(date +%s%N)"
echo "T|$(( (t0 + t1) / 2 ))"
[ -n "$out" ] && echo "$out"
exit 0
