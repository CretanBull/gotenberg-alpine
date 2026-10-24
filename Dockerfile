# =============================================================================
# Stage 1: Build Gotenberg v8.38.1 & pdfcpu from Source with Patched Go Deps
# =============================================================================
FROM golang:1.27-alpine AS builder

ARG GOTENBERG_VERSION=v8.38.1
ARG UNOCONVERTER_VERSION=v0.5.0

# Allow Go to automatically fetch newer patch toolchains if required by go.mod
ENV CGO_ENABLED=0 \
    GOTOOLCHAIN=auto

RUN apk update && apk upgrade --no-cache && \
    apk add --no-cache git ca-certificates curl sed

WORKDIR /src

# Clone Gotenberg v8.38.1
RUN git clone --depth 1 --branch ${GOTENBERG_VERSION} https://github.com/gotenberg/gotenberg.git .

# Remove the pdftk module registration so Gotenberg does not require PDFTK_BIN_PATH or Java
RUN sed -i '/pdftk/d' pkg/standard/imports.go

# Force upgrade echo/v5 to v5.4.1+ and patch all transitive Go dependencies
RUN go get -u github.com/labstack/echo/v5@v5.4.1 && \
    go get -u \
    golang.org/x/net \
    golang.org/x/crypto \
    golang.org/x/sys \
    golang.org/x/text \
    golang.org/x/sync \
    google.golang.org/protobuf \
    google.golang.org/grpc || true && \
    go mod tidy

# Statically compile Gotenberg with version metadata injected
RUN go build \
    -ldflags="-s -w -X 'github.com/gotenberg/gotenberg/v8/cmd.Version=${GOTENBERG_VERSION#v}'" \
    -o /out/gotenberg ./cmd/gotenberg

# Build pdfcpu from source, update its crypto/openpgp dependencies, and tidy
WORKDIR /pdfcpu-src
RUN git clone --depth 1 https://github.com/pdfcpu/pdfcpu.git . && \
    go get -u golang.org/x/image golang.org/x/crypto golang.org/x/text golang.org/x/net || true && \
    go mod tidy && \
    go build -ldflags="-s -w" -o /out/pdfcpu ./cmd/pdfcpu

# Fetch Gotenberg's official unoconverter script (upstream filename is 'unoconv')
RUN curl -fsSL -o /out/unoconverter \
    "https://raw.githubusercontent.com/gotenberg/unoconverter/${UNOCONVERTER_VERSION}/unoconv" && \
    chmod +x /out/unoconverter

# =============================================================================
# Stage 2: Hardened Alpine Runtime Image
# =============================================================================
FROM alpine:3.24

ARG GOTENBERG_VERSION=8.38.1
ARG GOTENBERG_USER_GID=1001
ARG GOTENBERG_USER_UID=1001

# 1. Upgrade all base Alpine packages and install runtime conversion engines
#    (pyuno is bundled inside libreoffice-common on Alpine)
RUN apk update && \
    apk upgrade --no-cache && \
    apk add --no-cache \
      bash \
      ca-certificates \
      curl \
      tini \
      python3 \
      chromium \
      nss \
      freetype \
      harfbuzz \
      libreoffice \
      qpdf \
      perl-image-exiftool \
      fontconfig \
      ttf-dejavu \
      ttf-liberation \
      font-crosextra-carlito \
      font-noto \
      font-noto-cjk \
      font-noto-emoji && \
    ln -sf /usr/bin/python3 /usr/bin/python && \
    rm -rf /var/cache/apk/* /tmp/* /var/tmp/*

# 2. Configure unprivileged Gotenberg user and OpenShift-compatible permissions
RUN addgroup -g ${GOTENBERG_USER_GID} gotenberg && \
    adduser -u ${GOTENBERG_USER_UID} -G gotenberg -s /bin/bash -D -H -h /home/gotenberg gotenberg && \
    mkdir -p /home/gotenberg /opt/gotenberg/versions /opt/gotenberg/chromium-hyphen-data && \
    chown -R gotenberg:gotenberg /home/gotenberg /opt/gotenberg && \
    chmod -R 770 /home/gotenberg /opt/gotenberg

# 3. Copy font config, hyphenation data, and version scripts from Gotenberg repo
COPY --from=builder /src/build/fonts.conf /etc/fonts/conf.d/100-gotenberg.conf
COPY --from=builder --chown=gotenberg:gotenberg /src/build/chromium-hyphen-data /opt/gotenberg/chromium-hyphen-data
COPY --from=builder /src/build/capture-version.sh /opt/gotenberg/capture-version.sh

# 4. Copy compiled binaries and scripts
COPY --from=builder /out/gotenberg /usr/bin/gotenberg
COPY --from=builder /out/pdfcpu /usr/bin/pdfcpu
COPY --from=builder /out/unoconverter /usr/bin/unoconverter

# 5. Set required Gotenberg 8.38.1 environment variables + PYTHONPATH for pyuno
ENV LANG=C.UTF-8 \
    LC_ALL=C.UTF-8 \
    PYTHONPATH=/usr/lib/libreoffice/program \
    CHROMIUM_BIN_PATH=/usr/bin/chromium-browser \
    CHROMIUM_HYPHEN_DATA_DIR_PATH=/opt/gotenberg/chromium-hyphen-data \
    LIBREOFFICE_BIN_PATH=/usr/lib/libreoffice/program/soffice.bin \
    UNOCONVERTER_BIN_PATH=/usr/bin/unoconverter \
    QPDF_BIN_PATH=/usr/bin/qpdf \
    EXIFTOOL_BIN_PATH=/usr/bin/exiftool \
    PDFCPU_BIN_PATH=/usr/bin/pdfcpu \
    GOTENBERG_VERSIONS_DIR_PATH=/opt/gotenberg/versions \
    OTEL_TRACES_EXPORTER=none \
    OTEL_METRICS_EXPORTER=none \
    OTEL_LOGS_EXPORTER=none

# 6. Capture backing binary versions (required by Gotenberg 8.38+ telemetry/health)
RUN fc-cache -f && \
    bash /opt/gotenberg/capture-version.sh "$GOTENBERG_VERSIONS_DIR_PATH" chromium "$CHROMIUM_BIN_PATH" --version && \
    bash /opt/gotenberg/capture-version.sh "$GOTENBERG_VERSIONS_DIR_PATH" libreoffice-api "$LIBREOFFICE_BIN_PATH" --version && \
    bash /opt/gotenberg/capture-version.sh "$GOTENBERG_VERSIONS_DIR_PATH" qpdf "$QPDF_BIN_PATH" --version && \
    bash /opt/gotenberg/capture-version.sh "$GOTENBERG_VERSIONS_DIR_PATH" exiftool "$EXIFTOOL_BIN_PATH" -ver && \
    bash /opt/gotenberg/capture-version.sh "$GOTENBERG_VERSIONS_DIR_PATH" pdfcpu "$PDFCPU_BIN_PATH" version && \
    chown -R gotenberg:gotenberg "$GOTENBERG_VERSIONS_DIR_PATH"

USER gotenberg
WORKDIR /home/gotenberg

EXPOSE 3000

ENTRYPOINT ["/sbin/tini", "--"]
CMD ["gotenberg"]