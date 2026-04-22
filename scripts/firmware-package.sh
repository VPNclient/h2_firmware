#!/bin/bash
# h2-firmware-asa5506x self-extracting firmware package creator

TARGET_BIN="build/h2-firmware-asa5506x.run"
PAYLOAD_DIR="build/firmware-payload"

mkdir -p "$PAYLOAD_DIR"
mkdir -p "$PAYLOAD_DIR/bin"
mkdir -p "$PAYLOAD_DIR/conf"

# 1. Copy Linux binaries (h2_vpn is already cross-compiled)
cp build/h2_vpn_linux_amd64 "$PAYLOAD_DIR/bin/h2_vpn"
# Note: For ocserv, it's expected to be pre-compiled for linux-amd64.
# For now, we'll assume it's in a location where the installer can find it.
# If not, we'd need to cross-compile it as well (very hard for C/GnuTLS).
if [ -f "build/ocserv_linux_amd64" ]; then
    cp build/ocserv_linux_amd64 "$PAYLOAD_DIR/bin/ocserv"
fi

# 2. Copy configs
cp examples/config-gost.json "$PAYLOAD_DIR/conf/h2_vpn.json"
cp examples/ocserv-backend.conf "$PAYLOAD_DIR/conf/ocserv.conf"

# 3. Create inner installer script
cat <<'INS' > "$PAYLOAD_DIR/install.sh"
#!/bin/bash
echo "[H2-FIRMWARE] Installing Cisco ASA 5506-X update..."
INSTALL_PATH="/opt/h2-vpn"
mkdir -p "$INSTALL_PATH/bin" "$INSTALL_PATH/conf" "$INSTALL_PATH/run"
cp bin/* "$INSTALL_PATH/bin/"
cp conf/* "$INSTALL_PATH/conf/"
chmod +x "$INSTALL_PATH/bin/"*
echo "[H2-FIRMWARE] Installation complete. Start with $INSTALL_PATH/bin/h2_vpn"
INS
chmod +x "$PAYLOAD_DIR/install.sh"

# 4. Create self-extracting archive
tar -czf build/payload.tar.gz -C "$PAYLOAD_DIR" .

cat <<'RUN' > "$TARGET_BIN"
#!/bin/bash
echo "[H2-FIRMWARE] ASA 5506-X Firmware Update Binary"
PAYLOAD_LINE=$(awk '/^__PAYLOAD_BELOW__/ {print NR + 1; exit 0; }' "$0")
tail -n +$PAYLOAD_LINE "$0" | tar -xz -C /tmp
/tmp/install.sh
exit 0
__PAYLOAD_BELOW__
RUN
cat build/payload.tar.gz >> "$TARGET_BIN"
chmod +x "$TARGET_BIN"

echo "[H2-FIRMWARE] Created firmware binary: $TARGET_BIN"
