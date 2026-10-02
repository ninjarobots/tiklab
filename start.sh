#!/usr/bin/env bash
set -e

BASE="./lab"
IMG_DIR="./chr-images"
DISK_DIR="$BASE/disks"
CONF="./lab.conf"
PID_FILE="$BASE/lab.pid"

mkdir -p "$DISK_DIR"
rm -f "$PID_FILE"

PORT_BASE=2200
SOCK_BASE=12000

port_counter=1
sock_counter=1

run_router() {
  NAME=$1
  shift

  echo "[+] Starting $NAME"
  "$@" &
  echo $! >> "$PID_FILE"
}

build_disk() {
  NAME=$1
  IMG=$2

  SRC="$IMG_DIR/$IMG"
  DST="$DISK_DIR/$NAME.qcow2"

  if [ ! -f "$DST" ]; then
    echo "  -> Creating disk for $NAME"
    qemu-img convert -f raw -O qcow2 "$SRC" "$DST"
    qemu-img resize "$DST" 256M
  fi
}

echo "[+] Building dynamic lab..."

while IFS=':' read -r EDGE IMG DEPTH; do
  [[ -z "$EDGE" || "$EDGE" =~ ^# ]] && continue

  build_disk "$EDGE" "$IMG"

  SSH_PORT=$((PORT_BASE + port_counter))
  WINBOX_PORT=$((8290 + port_counter))
  API_PORT=$((8720 + port_counter))
  SOCK_PORT=$((SOCK_BASE + sock_counter))

  # EDGE ROUTER
  run_router "$EDGE" qemu-system-x86_64 \
    -name "$EDGE" \
    -m 256 \
    -drive file="$DISK_DIR/$EDGE.qcow2",format=qcow2 \
    -netdev user,id=wan,hostfwd=tcp::$SSH_PORT-:22,hostfwd=tcp::$WINBOX_PORT-:8291,hostfwd=tcp::$API_PORT-:8728 \
    -device e1000,netdev=wan \
    -netdev socket,id=lan,listen=:$SOCK_PORT \
    -device e1000,netdev=lan \
    -nographic

  echo "  -> $EDGE exposed on SSH:$SSH_PORT Winbox:$WINBOX_PORT API:$API_PORT"

  PREV="$EDGE"

  # INTERNAL CHAIN
  for ((i=1; i<=DEPTH; i++)); do
    NODE="${EDGE}n$i"

    build_disk "$NODE" "$IMG"

    NEXT_SOCK=$((SOCK_BASE + sock_counter + 1))

    run_router "$NODE" qemu-system-x86_64 \
      -name "$NODE" \
      -m 256 \
      -drive file="$DISK_DIR/$NODE.qcow2",format=qcow2 \
      -netdev socket,id=up,connect=127.0.0.1:$SOCK_PORT \
      -device e1000,netdev=up \
      -netdev socket,id=down,listen=:$NEXT_SOCK \
      -device e1000,netdev=down \
      -nographic

    SOCK_PORT=$NEXT_SOCK
    PREV="$NODE"
  done

  port_counter=$((port_counter + 1))
  sock_counter=$((sock_counter + 10))

done < "$CONF"

echo ""
echo "[+] Lab started dynamically."
