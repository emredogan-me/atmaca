#!/usr/bin/env bash
# GitHub'a göndermeden önce yerel sınama: Atmaca paketlerini derler, kickstart'ı doğrular ve
# ISO'ya girecek paket listesini dnf ile çözer (hiçbir şey kurmaz). Çakışma varsa gösterir.
# Kullanım (repo kökünde):
#   podman run --rm -v $PWD:/atmaca:z registry.fedoraproject.org/fedora:44 bash /atmaca/tarifler/yerel-sina.sh [kde]
set -euo pipefail
MASAUSTU="${1:-kde}"
cd /atmaca
dnf -y -q install pykickstart ImageMagick >/dev/null 2>&1
mkdir -p build
bash tarifler/marka-derle.sh > build/marka-derle.log 2>&1 || { echo "MARKA PAKETLERİ DERLENEMEDİ:"; tail -40 build/marka-derle.log; exit 1; }
echo "=== Atmaca paketleri"; ls build/depo/*.rpm | xargs -n1 basename
ksflatten -c kickstart/atmaca-$MASAUSTU.ks -o /tmp/k.ks >/dev/null && ksvalidator /tmp/k.ks >/dev/null && echo "kickstart geçerli"
python3 - > /tmp/args <<'PY'
from pykickstart.parser import KickstartParser
from pykickstart.version import makeVersion
p = KickstartParser(makeVersion()); p.readKickstart('/tmp/k.ks')
pk = p.handler.packages
print(' '.join(['@' + g.name for g in pk.groupList] + pk.packageList))
print(' '.join('--exclude=' + e for e in pk.excludedList))
PY
dnf -y --installroot=/tmp/kok --releasever=44 --use-host-config \
  --repofrompath=atmaca,file:///atmaca/build/depo --setopt=atmaca.gpgcheck=0 --setopt=atmaca.priority=10 \
  $(sed -n 2p /tmp/args) --assumeno install $(sed -n 1p /tmp/args) > build/paket-cozumu-$MASAUSTU.txt 2>&1 || true
grep -E "Total size|After this|Problem" build/paket-cozumu-$MASAUSTU.txt || true
grep -A6 "^Problem" build/paket-cozumu-$MASAUSTU.txt | grep requires | head -10 || true
echo "Paket sayısı: $(grep -E '^ [a-zA-Z0-9]' build/paket-cozumu-$MASAUSTU.txt | awk '{print $1}' | sort -u | wc -l)"
echo "=== Atmaca paketleri listede:"; grep -E "^ atmaca-" build/paket-cozumu-$MASAUSTU.txt | awk '{print $1, $3}'
