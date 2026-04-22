#!/bin/sh
set -e

# --- 1. Start ocserv in background ---
echo "[Firmware] Starting ocserv backend..."
ocserv -c /etc/ocserv/ocserv.conf -f &
OCSERV_PID=$!

# --- 2. Start h2_vpn as frontend ---
echo "[Firmware] Starting h2_vpn frontend (GOST Stealth)..."
/usr/bin/h2_vpn run -c /etc/h2_vpn/config.json &
H2VPN_PID=$!

# --- 3. Monitor both processes ---
# Simple monitor loop
while true; do
    if ! kill -0 $OCSERV_PID 2>/dev/null; then
        echo "[Firmware] ocserv died. Exiting."
        exit 1
    fi
    if ! kill -0 $H2VPN_PID 2>/dev/null; then
        echo "[Firmware] h2_vpn died. Exiting."
        exit 1
    fi
    sleep 5
done
