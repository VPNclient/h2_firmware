# --- Stage 1: Build ocserv (C) ---
FROM alpine:3.20 AS ocserv-builder
RUN apk add --no-cache \
    bash build-base gnutls-dev libev-dev libnl3-dev libseccomp-dev \
    linux-headers lz4-dev meson nettle-dev protobuf-c-dev readline-dev tar xz

WORKDIR /build/ocserv
COPY vendor/ocserv .
RUN meson setup build -Dprefix=/usr -Dlocal-talloc=true -Dlocal-llhttp=true \
    -Dpam=false -Dradius=false -Dgnutls=enabled -Dsystemd=disabled -Dseccomp=enabled -Dutmp=disabled && \
    meson compile -C build

# --- Stage 2: Build h2_vpn (Go) ---
FROM golang:1.24-alpine AS h2vpn-builder
WORKDIR /app
COPY vendor/h2_vpn .
RUN cd cmd/https-vpn && go build -o /app/h2_vpn .

# --- Stage 3: Final Firmware Image ---
FROM alpine:3.20
RUN apk add --no-cache gnutls libev libnl3 libseccomp lz4-dev nettle protobuf-c readline

# Copy binaries
COPY --from=ocserv-builder /build/ocserv/build/src/ocserv /usr/sbin/ocserv
COPY --from=h2vpn-builder /app/h2_vpn /usr/bin/h2_vpn

# Copy default configurations
COPY examples/ocserv-backend.conf /etc/ocserv/ocserv.conf
COPY examples/config-gost.json /etc/h2_vpn/config.json

# Create directories
RUN mkdir -p /var/run/ocserv /etc/ocserv/certs /etc/h2_vpn/certs

# Copy entrypoint script
COPY scripts/entrypoint.sh /usr/bin/entrypoint.sh
RUN chmod +x /usr/bin/entrypoint.sh

EXPOSE 443
ENTRYPOINT ["/usr/bin/entrypoint.sh"]
