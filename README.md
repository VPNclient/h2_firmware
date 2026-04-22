# h2-firmware (Cisco AnyConnect + GOST VPN Prototype)

This project provides a unified "firmware" bundle for a high-performance, stealthy VPN server. It integrates **ocserv (C)** for full Cisco AnyConnect compatibility with **h2_vpn (Go)** for advanced HTTP/2 transport and Russian national cryptography (GOST).

## Key Features

- **Cisco Compatibility**: Emulates **Cisco ASA 5506-X** and **Cisco ISR 4331** profiles, widely used in RU medical infrastructure.
- **GOST Support**: Full integration of GOST R 34.10-2012, 34.11-2012, and 34.12-2015 via `h2_vpn/crypto/ru`.
- **Stealth Transport**: Uses a "browser-identical" HTTP/2 profile to evade Deep Packet Inspection (DPI).
- **AnyConnect XML Profile**: Automatically serves `AnyConnectProfile.xml` for seamless client auto-configuration.
- **Unified Image**: A single Docker/Alpine-based image containing both frontend and backend.

## Architecture

```
Incoming Connection (443) -> h2_vpn (Frontend, GOST TLS 1.3) -> ocserv (Backend, 127.0.0.1:8443)
```

1.  **h2_vpn** handles the complex GOST handshake and HTTP/2 framing.
2.  **ocserv** manages VPN sessions, IP allocation (TUN), and AnyConnect protocol negotiation.

## Quick Start (Build & Run)

### 1. Build the Firmware Bundle
Ensure you have Docker installed and the `ocserv` and `h2_vpn` submodules initialized in `vendor/`.

\`\`\`bash
# Build the unified firmware image
docker build -t h2-firmware .
\`\`\`

### 2. Configure Certificates
Place your GOST-enabled certificates in the `certs/` directory:
- `certs/server-cert.pem`
- `certs/server-key.pem`

### 3. Run the Firmware
\`\`\`bash
docker run --privileged -p 443:443 -v $(pwd)/certs:/etc/ocserv/certs:ro h2-firmware
\`\`\`
*Note: `--privileged` and `/dev/net/tun` mapping are required for the `ocserv` TUN device.*

## Configuration

- **h2_vpn Config**: `examples/config-gost.json`
- **ocserv Config**: `examples/ocserv-backend.conf`

## Project Documentation (SDD)

Full requirements, specifications, and implementation plans are available in the `flows/sdd-h2-firmware/` directory.

---

## Technical Details

- **Frontend**: Go 1.24+ using custom GOST TLS 1.3 implementation.
- **Backend**: ocserv 1.5.0 (C) with GnuTLS.
- **Protocol**: CSTP (Cisco SSL Tunneling Protocol) over HTTP/2.
