# Requirements: h2-firmware

> Version: 1.0  
> Status: DRAFT  
> Last Updated: 2026-04-22

## Problem Statement

Cisco AnyConnect is a standard for enterprise VPNs, but standard firmware often lacks support for regional cryptographic standards like GOST (Russian national cryptography). There is a need for a high-performance, secure, and compliant VPN firmware that maintains backward compatibility with Cisco AnyConnect/OpenConnect while providing modern HTTP/2 performance and GOST crypto support.

This project combines the established `ocserv` (C) codebase for protocol compatibility and session management with the modern `h2_vpn` (Go) project for high-performance HTTP/2 transport and GOST crypto primitives.

## User Stories

### Primary

**As a** Network Administrator in a GOST-regulated environment  
**I want** to deploy a VPN firmware that supports Cisco AnyConnect protocol with GOST TLS  
**So that** my users can connect securely using compliant cryptography without changing their client software.

### Secondary

**As a** Security Auditor  
**I want** a firmware with a clear, auditable implementation of national cryptography  
**So that** I can verify compliance with local regulations.

**As a** Remote User  
**I want** my VPN connection to be fast (HTTP/2) and hard to detect (stealth transport)  
**So that** I can work reliably even on restricted networks.

## Acceptance Criteria

### Must Have

1. **AnyConnect Compatibility**: Full support for Cisco AnyConnect (CSTP/AnyConnect) protocol via `ocserv`.
2. **Target Profile**: Support for **Cisco ASA 5506-X** and **Cisco ISR 4331** emulation profiles (XML headers, banner, and protocol quirks), as these are the most widespread models in RU medical infrastructure.
3. **GOST Crypto Support**: Integration of GOST R 34.10-2012, 34.11-2012, and 34.12-2015 for TLS handshakes and data encryption.
3. **HTTP/2 Transport**: High-performance transport layer leveraging `h2_vpn`'s HTTP/2 implementation.
4. **Unified Firmware**: A single build/packaging system that produces a runnable firmware image or bundle.
5. **Cisco Client Compatibility**: Ability for standard OpenConnect or GOST-enabled Cisco clients to connect.

### Should Have

1. **Dual Stack Support**: Ability to negotiate either standard (AES/RSA) or national (GOST) crypto depending on client capabilities.
2. **Stealth Mode**: Integration of `h2_vpn`'s "browser-identical" traffic profiling to evade DPI.
3. **Web-based Management**: Simple interface to configure `ocserv` and `h2_vpn` components.

### Won't Have (This Iteration)

1. **Non-AnyConnect protocols**: Support for IKEv2/IPsec is out of scope.
2. **Complex RADIUS/LDAP integration**: Initial focus is on local certificate/password authentication.

## Constraints

- **Base Components**: Must use `vendor/ocserv` and `vendor/h2_vpn`.
- **Performance**: Must not introduce significant latency compared to standard `ocserv`.
- **Portability**: Target architecture should include x86_64 and potentially ARM for embedded use.

## Open Questions

- [ ] Will `h2_vpn` act as a frontend (reverse proxy) for `ocserv`, or will they be merged at the source level?
- [ ] How will IP allocation and routing be shared between the two components?
- [ ] What is the target OS for the "firmware" (e.g., Alpine Linux, OpenWRT)?

## References

- [vendor/ocserv/README.md](../../vendor/ocserv/README.md)
- [vendor/h2_vpn/flows/sdd-https-cisco-firmware-compatibility/01-requirements.md](../../vendor/h2_vpn/flows/sdd-https-cisco-firmware-compatibility/01-requirements.md)
- [RFC 9189 - GOST Cipher Suites for TLS 1.3](https://www.rfc-editor.org/rfc/rfc9189.html)

---

## Approval

- [ ] Reviewed by: [name]
- [ ] Approved on: [date]
- [ ] Notes: [any conditions or clarifications]
