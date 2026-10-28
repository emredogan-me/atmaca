#!/usr/bin/env bash
# Kickstart'tan canlı ISO üretir.  Kullanım: ./tarifler/iso-uret.sh [kde|gnome]
set -euo pipefail

# Loop aygıtı (sanal disk) bağlamak root ister; kullanıcı podman'ı (rootless) yetmez.
if [ "$EUID" -ne 0 ]; then
    exec sudo "$0" "$@"
fi

MASAUSTU="${1:-kde}"
KOK="$(cd "$(dirname "$0")/.." && pwd)"
IMAJ=atmaca-derleme:44
CIKTI="$KOK/build/iso-$MASAUSTU"

podman image exists "$IMAJ" || podman build -t "$IMAJ" -f "$KOK/tarifler/Containerfile" "$KOK/tarifler"

# %include'ları çözülmüş tek dosya (livemedia-creator buna ihtiyaç duyar)
mkdir -p "$KOK/build"
podman run --rm -v "$KOK":/atmaca:Z "$IMAJ" \
    ksflatten -c "kickstart/atmaca-$MASAUSTU.ks" -o "build/atmaca-$MASAUSTU.ks"

rm -rf "$CIKTI"
podman run --rm --privileged -v /dev:/dev -v "$KOK":/atmaca:Z "$IMAJ" \
    livemedia-creator --make-iso --no-virt \
        --ks "build/atmaca-$MASAUSTU.ks" \
        --resultdir "build/iso-$MASAUSTU" \
        --project "Atmaca" --releasever 44 \
        --volid "Atmaca-44-$MASAUSTU" \
        --iso-name "atmaca-$MASAUSTU.iso" \
        --logfile "build/livemedia-$MASAUSTU.log"

echo "Hazır: $CIKTI/atmaca-$MASAUSTU.iso"
