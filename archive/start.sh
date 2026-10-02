#!/usr/bin/env bash
set -e

BASE="./lab"
IMG_DIR="./chr-images"
DISK_DIR="$BASE/disks"
CONF="./lab.conf"

mkdir -p "$DISK_DIR"

if [ ! -f "$CONF" ]; then
  echo "[!] Missing lab.conf"
  exit 1
fi

declare -A ROUTERS

echo "[+] Loading config..."

while IFS='=' read -r name img; do
  [[ "$name" =~ ^#.*$ || -z "$name" ]] && continue
  ROUTERS[$name]=$img
done < "$CONF"

echo "[+] Preparing disks..."

for r in "${!ROUTERS[@]}"; do
  IMG="${ROUTERS[$r]}"
  SRC="$IMG_DIR/$IMG"
  DST="$DISK_DIR/$r.qcow2"

  if [ ! -f "$SRC" ]; then
    echo "[!] Missing image: $IMG"
    exit 1
  fi

  if [ ! -f "$DST" ]; then
    echo "  -> $r ($IMG)"
    qemu-img convert -f raw -O qcow2 "$SRC" "$DST"
    qemu-img resize "$DST" 256M
  fi
done

run_router() {
  NAME=$1
  DISK=$2
  shift 2

  qemu-system-x86_64 \
    -name "$NAME" \
    -m 256 \
    -smp 1 \
    -drive file="$DISK",format=qcow2 \
    "$@" \
    -nographic \
    > "$BASE/$NAME.log" 2>&1 &
}

echo "[+] Starting lab..."

# Network 1
run_router r1 "$DISK_DIR/r1.qcow2" \
  -netdev user,id=wan,hostfwd=tcp::2221-:22,hostfwd=tcp::8291-:8291,hostfwd=tcp::8721-:8728 \
  -device e1000,netdev=wan \
  -netdev socket,id=lan,listen=:12001 \
  -device e1000,netdev=lan

run_router r2 "$DISK_DIR/r2.qcow2" \
  -netdev socket,id=lan,connect=127.0.0.1:12001 \
  -device e1000,netdev=lan

# Network 2
run_router r3 "$DISK_DIR/r3.qcow2" \
  -netdev user,id=wan,hostfwd=tcp::2222-:22,hostfwd=tcp::8292-:8291,hostfwd=tcp::8722-:8728 \
  -device e1000,netdev=wan \
  -netdev socket,id=lan,listen=:12002 \
  -device e1000,netdev=lan

run_router r4 "$DISK_DIR/r4.qcow2" \
  -netdev socket,id=lan,connect=127.0.0.1:12002 \
  -device e1000,netdev=lan

# Network 3
run_router r5 "$DISK_DIR/r5.qcow2" \
  -netdev user,id=wan,hostfwd=tcp::2223-:22,hostfwd=tcp::8293-:8291,hostfwd=tcp::8723-:8728 \
  -device e1000,netdev=wan \
  -netdev socket,id=lan,listen=:12003 \
  -device e1000,netdev=lan

run_router r6 "$DISK_DIR/r6.qcow2" \
  -netdev socket,id=lan,connect=127.0.0.1:12003 \
  -device e1000,netdev=lan

echo ""
echo "[+] Lab running!"
echo "Edit lab.conf to change RouterOS versions."
