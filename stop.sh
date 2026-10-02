#!/usr/bin/env bash

PID_FILE="./lab/lab.pid"

if [ ! -f "$PID_FILE" ]; then
  echo "[!] No running lab found"
  exit 1
fi

echo "[+] Stopping lab..."

while read -r pid; do
  kill "$pid" 2>/dev/null || true
done < "$PID_FILE"

rm -f "$PID_FILE"

echo "[+] Lab stopped."
