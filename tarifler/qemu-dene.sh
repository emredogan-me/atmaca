#!/usr/bin/env bash
# GitHub'daki son başarılı derlemenin ISO'sunu indirir ve QEMU'da (pencereli) açar.
# ISO WSL'in içine değil Windows diskine (varsayılan C:\Atmaca) kaydedilir:
# WSL'in sanal diski şişmez. Zip ara dosyası tutulmaz; indirirken açılır.
# Kullanım: ./tarifler/qemu-dene.sh [hedef-klasör]
set -euo pipefail
command -v bsdtar >/dev/null || { echo "Önce: sudo apt install -y libarchive-tools" >&2; exit 1; }

HEDEF="${1:-/mnt/c/Atmaca}"
DEPO=emredogan-me/atmaca
ISO="$HEDEF/atmaca-kde.iso"
TOKEN=$(sed -n 's#https://[^:]*:\([^@]*\)@github.com.*#\1#p' ~/.git-credentials | head -1)
API() { curl -fsSL -H "Authorization: Bearer $TOKEN" "https://api.github.com/repos/$DEPO/$1"; }

mkdir -p "$HEDEF"
if [ ! -f "$ISO" ]; then
    BOS=$(df --output=avail -B1G "$HEDEF" | tail -1)
    [ "$BOS" -lt 3 ] && { echo "Hedefte ${BOS} GB boş; en az 3 GB gerekli." >&2; exit 1; }
    ID=$(API "actions/artifacts?name=atmaca-kde-iso&per_page=1" | python3 -c "import sys,json;print(json.load(sys.stdin)['artifacts'][0]['id'])")
    echo "ISO indiriliyor (2,6 GB) → $ISO"
    curl -fL -H "Authorization: Bearer $TOKEN" \
         "https://api.github.com/repos/$DEPO/actions/artifacts/$ID/zip" \
      | bsdtar -xOf - atmaca-kde.iso > "$ISO.part"
    mv "$ISO.part" "$ISO"
fi

echo "QEMU açılıyor (pencere birkaç saniye içinde gelir)…"
exec qemu-system-x86_64 -enable-kvm -m 4096 -smp 4 -machine q35 \
    -cdrom "$ISO" -boot d \
    -vga virtio -display gtk \
    -nic user,model=virtio-net-pci \
    -audiodev pa,id=ses -device intel-hda -device hda-duplex,audiodev=ses
