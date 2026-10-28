#!/usr/bin/env bash
# ISO derlemeden önce kickstart'ın paket listesini dnf ile çözer (hiçbir şey kurmaz).
# Kaç paket gideceğini, indirme boyutunu ve bağımlılığı bozulan paketleri gösterir.
# Kullanım: ./tarifler/paket-kontrol.sh [kde|gnome]
set -euo pipefail

MASAUSTU="${1:-kde}"
KOK="$(cd "$(dirname "$0")/.." && pwd)"
mkdir -p "$KOK/build"

podman run --rm -v "$KOK":/atmaca:Z atmaca-derleme:44 bash -c "
ksflatten -c kickstart/atmaca-$MASAUSTU.ks -o /tmp/k.ks >/dev/null && ksvalidator /tmp/k.ks >/dev/null
python3 - > /tmp/args <<'PY'
from pykickstart.parser import KickstartParser
from pykickstart.version import makeVersion
p = KickstartParser(makeVersion()); p.readKickstart('/tmp/k.ks')
pk = p.handler.packages
print(' '.join(['@' + g.name for g in pk.groupList] + pk.packageList))
print(' '.join('--exclude=' + e for e in pk.excludedList))
PY
dnf -y --installroot=/tmp/kok --releasever=44 --use-host-config \$(sed -n 2p /tmp/args) \
    --assumeno install --skip-broken \$(sed -n 1p /tmp/args) > build/paket-cozumu-$MASAUSTU.txt 2>&1 || true
"

cd "$KOK/build"
grep -E "Total size|After this" "paket-cozumu-$MASAUSTU.txt"
echo "Paket sayısı: $(grep -E '^ [a-z]' "paket-cozumu-$MASAUSTU.txt" | awk '{print $1}' | sort -u | wc -l)"
if grep -q "^Skipping packages with broken" "paket-cozumu-$MASAUSTU.txt"; then
    echo "UYARI — bağımlılığı bozulan paketler (dışlama listesi bir şeyi kırıyor):"
    sed -n '/^Skipping packages with broken/,/^$/p' "paket-cozumu-$MASAUSTU.txt"
    exit 1
fi
echo "Tamam: bozuk bağımlılık yok."
