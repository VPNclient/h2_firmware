# Specifications: h2-firmware

> Version: 1.0  
> Status: DRAFT  
> Last Updated: 2026-04-22  
> Requirements: [01-requirements.md](01-requirements.md)

## Overview

Implement a Cisco-compatible VPN firmware that combines `ocserv` for session management and standard AnyConnect protocol handling with `h2_vpn` for advanced HTTP/2 transport and Russian national cryptography (GOST).

The architecture uses `h2_vpn` as a high-performance, stealthy frontend (Reverse Proxy) that handles the complex TLS/GOST handshake and HTTP/2 framing, while `ocserv` provides the robust VPN backend (IP allocation, authentication, routing).

## Affected Systems

| System | Impact | Notes |
|--------|--------|-------|
| `vendor/ocserv` | Configure / Run | Build with local-only listener mode |
| `vendor/h2_vpn` | Modify / Integrate | Add "AnyConnect Proxy" mode to forward to `ocserv` |
| `flows/sdd-h2-firmware/` | Create | New SDD for the unified project |
| `src/main.go` | Create | New entry point for the firmware bundle (if applicable) |

## Architecture

### Component Diagram

```
┌───────────────────────────────────────────────────────────┐
│                     h2-firmware (Device)                  │
├───────────────────────────────────────────────────────────┤
│                                                           │
│   Incoming Client Connection (443/TCP)                    │
│   (AnyConnect Client with GOST Support)                   │
│               │                                           │
│               ▼                                           │
│   ┌──────────────────────────────┐                        │
│   │        h2_vpn (Go)           │                        │
│   │  (Frontend Stealth Proxy)    │                        │
│   ├──────────────────────────────┤                        │
│   │ - GOST TLS 1.3 Handshake     │                        │
│   │ - HTTP/2 CONNECT handling    │                        │
│   │ - TLS Decryption/Re-encryption│                       │
│   └───────────────┬──────────────┘                        │
│                   │                                       │
│                   │ Local Proxy (UNIX Socket or 127.0.0.1)│
│                   ▼                                       │
│   ┌──────────────────────────────┐                        │
│   │         ocserv (C)           │                        │
│   │   (AnyConnect Backend)       │                        │
│   ├──────────────────────────────┤                        │
│   │ - CSTP/AnyConnect Logic      │                        │
│   │ - Authentication (local)     │                        │
│   │ - IP Pool Management (TUN)   │                        │
│   │ - Kernel Routing             │                        │
│   └──────────────────────────────┘                        │
│                                                           │
└───────────────────────────────────────────────────────────┘
```

### Data Flow

1. **Handshake Phase**: 
   - Client initiates TLS 1.3 connection.
   - `h2_vpn` performs GOST handshake using `crypto/ru/gost` primitives.
   - Negotiated cipher is `TLS_GOSTR341112_256_WITH_KUZNYECHIK_MGM_L`.
2. **Tunnel Phase**:
   - Client sends HTTP CONNECT request (AnyConnect style).
   - `h2_vpn` strips HTTP/2 framing and forwards raw CSTP traffic to `ocserv`.
   - `ocserv` performs AnyConnect session negotiation (XML config, auth).
3. **Data Phase**:
   - Encapsulated IP packets flow from Client -> `h2_vpn` (GOST) -> `ocserv` -> TUN device -> Internet.

## Interfaces

### h2_vpn Proxy Interface

`h2_vpn` must be extended to support a "Transparent AnyConnect Proxy" mode.

```go
// core/proxy.go (Proposed in h2_vpn)
type OcservProxy struct {
    BackendAddr string // e.g., "127.0.0.1:8443" or "/var/run/ocserv.sock"
}

func (p *OcservProxy) ServeHTTP(w http.ResponseWriter, r *http.Request) {
    if r.Method == "CONNECT" || r.Header.Get("Upgrade") == "anyconnect" {
        p.proxyToOcserv(w, r)
    }
}
```

### ocserv Configuration

`ocserv` should be configured to trust the frontend proxy and potentially receive client IP information.

```ini
# ocserv.conf
listen-host = 127.0.0.1
listen-port = 8443
# Use a simple authentication for integration phase
auth = "plain[passwd=./sample.passwd]"
```

## Data Models

### GOST Integration

Re-use the data models from `vendor/h2_vpn/flows/sdd-https-cisco-firmware-compatibility/02-specifications.md`:
- `GOSTCertificate`
- `TLS_GOSTR341112_256_WITH_KUZNYECHIK_MGM_L`
- `BlockCipher` (Kuznyechik/Magma)

## Behavior Specifications

### Happy Path

1. **Start**: Firmware starts both `ocserv` and `h2_vpn`.
2. **Connect**: Cisco client connects to `h2_vpn` on port 443.
3. **Handshake**: GOST TLS 1.3 successful.
4. **Auth**: `h2_vpn` proxies auth request to `ocserv`; `ocserv` validates credentials.
5. **Tunnel**: `ocserv` assigns IP `192.168.10.10` to the client.
6. **Traffic**: Bidirectional traffic flows between client and Internet.

### Edge Cases

| Case | Trigger | Expected Behavior |
|------|---------|-------------------|
| ocserv backend down | h2_vpn can't connect to backend | h2_vpn returns 502 Bad Gateway or 503 Service Unavailable |
| Non-GOST client | Client doesn't support GOST | `h2_vpn` rejects or falls back to AES depending on config |
| MTU mismatch | Backend MTU < Frontend MTU | `ocserv` sends ICMP fragmentation needed or handles MSS clamping |

## Dependencies

### Internal

- `vendor/h2_vpn/crypto/ru`: GOST primitives.
- `vendor/ocserv`: AnyConnect protocol backend.

### External

- **GnuTLS** (for `ocserv` base).
- **Go 1.21+** (for `h2_vpn`).

## Integration Points

- **Proxy Layer**: The point where `h2_vpn` hands off the raw stream to `ocserv`.
- **IP Management**: `ocserv` manages the TUN device; `h2_vpn` remains purely at the application layer.

## Testing Strategy

### Unit Tests
- Re-use GOST test vectors in `h2_vpn`.
- Test `h2_vpn` proxy logic with a mock `ocserv` backend.

### Integration Tests
- Full end-to-end connection: `OpenConnect (GOST)` -> `h2_vpn` -> `ocserv`.
- Benchmark throughput of the combined stack.

## Open Design Questions

- [ ] Should we use UNIX sockets for communication between `h2_vpn` and `ocserv` to avoid TCP overhead?
- [ ] How to synchronize certificates? (e.g., `h2_vpn` needs the GOST cert for TLS, while `ocserv` might need it for client-side cert auth).

---

## Approval

- [ ] Reviewed by: [name]
- [ ] Approved on: [date]
- [ ] Notes: [any conditions or clarifications]
