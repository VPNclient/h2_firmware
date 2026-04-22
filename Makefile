# h2-firmware Makefile

OCSERV_DIR = vendor/ocserv
H2VPN_DIR = vendor/h2_vpn
BUILD_DIR = $(CURDIR)/build
OCSERV_BUILD_DIR = $(BUILD_DIR)/ocserv
H2VPN_BIN = $(BUILD_DIR)/h2_vpn

.PHONY: all clean ocserv h2_vpn build-dirs

all: h2_vpn

build-dirs:
	mkdir -p $(BUILD_DIR)

# h2_vpn build using go
h2_vpn: build-dirs
	@echo "Building h2_vpn..."
	cd $(H2VPN_DIR)/cmd/https-vpn && go build -o $(H2VPN_BIN) .

# ocserv build note: requires meson and several C dependencies
# recommended to build in an Alpine-based container for firmware consistency
ocserv:
	@echo "Building ocserv requires meson and C libraries."
	@echo "Local meson not found. Please ensure it is installed or use a build container."

clean:
	rm -rf $(BUILD_DIR)
