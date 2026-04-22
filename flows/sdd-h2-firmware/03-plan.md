# Plan: h2-firmware

> Version: 1.0  
> Status: DRAFT  
> Last Updated: 2026-04-22  
> Specifications: [02-specifications.md](02-specifications.md)

## Overview

The implementation plan is divided into four phases: Build Environment, Backend Setup (ocserv), Frontend Setup (h2_vpn), and Integration/Packaging.

## Phase 1: Build Environment (Infrastructure)

Establish the tools and environment needed to build both C and Go components.

- **Task 1.1**: Setup `ocserv` build system (Meson/Autotools).
- **Task 1.2**: Setup `h2_vpn` Go build environment.
- **Task 1.3**: Create a top-level `Makefile` or `justfile` to orchestrate both builds.

## Phase 2: Backend Setup (ocserv)

Configure `ocserv` to operate in "Backend Mode".

- **Task 2.1**: Compile `ocserv` with minimal dependencies (GnuTLS, libtasn1, nettle).
- **Task 2.2**: Create a specialized `ocserv.conf` for local-only listening.
- **Task 2.3**: Verify `ocserv` can start and manage a TUN device locally.

## Phase 3: Frontend Setup (h2_vpn)

Implement the proxy logic and GOST TLS support.

- **Task 3.1**: Integrate GOST primitives from `crypto/ru` (imported from `https_vpn`).
- **Task 3.2**: Implement the `AnyConnectProxy` handler in Go.
- **Task 3.3**: Configure `h2_vpn` to use GOST TLS 1.3 for incoming connections.
- **Task 3.4**: Implement "Protocol Stripping" to forward raw CSTP to `ocserv`.

## Phase 4: Integration & Packaging

Unify the components into a single firmware image/bundle.

- **Task 4.1**: Create a supervisor script (or use `systemd`/`procd`) to manage both processes.
- **Task 4.2**: Implement unified logging (both processes logging to a single sink).
- **Task 4.3**: Create a build script for Docker/Alpine image (Firmware Prototype).
- **Task 4.4**: End-to-end testing with `OpenConnect` client.

## File Changes

| Phase | File | Action | Description |
|-------|------|--------|-------------|
| 1 | `Makefile` | Create | Root orchestration |
| 2 | `examples/ocserv-backend.conf` | Create | Backend configuration |
| 3 | `vendor/h2_vpn/core/proxy.go` | Modify | Add proxy handler |
| 3 | `vendor/h2_vpn/main.go` | Modify | Add flag for backend address |
| 4 | `scripts/run-firmware.sh` | Create | Startup script |

## Testing Strategy

- **Step 1**: Unit test GOST primitives (ensure no regressions during integration).
- **Step 2**: Test `h2_vpn` proxying to `nc -l 8443` (verify raw data forwarding).
- **Step 3**: Test `ocserv` with `openconnect` locally (verify backend logic).
- **Step 4**: Full end-to-end test with GOST-enabled client.

## Rollback Considerations

- Since this is additive, rollback involves simply using standard `ocserv` directly.

## Open Questions / Risks

- **Risk**: Performance bottleneck in the Go-to-C proxying layer.
- **Mitigation**: Use UNIX sockets instead of TCP for local communication.

---

## Approval

- [ ] Reviewed by: [name]
- [ ] Approved on: [date]
- [ ] Notes: [any conditions or clarifications]
