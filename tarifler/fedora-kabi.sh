#!/usr/bin/env bash
# Atmaca derleme kabı: Ubuntu (WSL) üstünde Fedora araçlarını çalıştırmak için
# podman ile bir Fedora kabı açar. ISO üretimi (livemedia-creator) bunun içinde yapılır.
set -euo pipefail

SURUM="${FEDORA_SURUM:-latest}"   # en güncel kararlı Fedora
KOK="$(cd "$(dirname "$0")/.." && pwd)"

if ! command -v podman >/dev/null; then
    echo "podman yok. Kur: sudo apt install -y podman" >&2
    exit 1
fi

exec podman run --rm -it --privileged \
    -v "$KOK":/atmaca:Z -w /atmaca \
    --name atmaca-derleme \
    "registry.fedoraproject.org/fedora:${SURUM}" \
    bash -c 'dnf -y install lorax pykickstart rpm-build anaconda-core >/dev/null && cat /etc/fedora-release && uname -r && exec bash'
