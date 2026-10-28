# Gotenberg Alpine (Hardened Edition)

[![Trivy Scan](https://img.shields.io/badge/Trivy-0%20OS%20CVEs-brightgreen?logo=aquasecurity)](./trivy-report.md)
[![Alpine](https://img.shields.io/badge/Alpine-3.24-0D597F?logo=alpinelinux&logoColor=white)](https://alpinelinux.org)
[![Gotenberg Version](https://img.shields.io/badge/Gotenberg-v8.38.1-blue)](https://github.com/gotenberg/gotenberg/releases/tag/v8.38.1)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](./LICENSE)

A security-hardened, **Alpine Linux** rebuild of [Gotenberg](https://gotenberg.dev/) (`v8.38.1`). Designed as a drop-in replacement for teams whose CI/CD pipelines and container registries enforce strict vulnerability gates via **Trivy**, **Grype**, or **Snyk**.

---

## Table of Contents

- [Why This Image Exists](#why-this-image-exists)
- [Features](#features)
- [Quick Start](#quick-start)
- [Usage](#usage)
- [Build Arguments](#build-arguments)
- [Runtime Environment Variables](#runtime-environment-variables)
- [Supported Conversion Engines](#supported-conversion-engines)
- [Security](#security)
- [Contributing](#contributing)
- [License](#license)

---

## Why This Image Exists

The official `gotenberg/gotenberg:8.38.1` image is built on **Debian 13.7 (Trixie)** and bundles precompiled binaries alongside a legacy Java runtime for `pdftk`. Running a standard Trivy scan against the upstream image reports **1,660+ vulnerabilities** across OS libraries, outdated Chromium packages, Go binaries, and JAR files.

This repository rebuilds Gotenberg and its backing engines from source on **Alpine Linux**, drastically shrinking the attack surface and eliminating known-severity vulnerabilities.

---

## Features

- 🛡️ **Zero fixable OS CVEs** — Built on fully-patched Alpine 3.24; verified with Trivy
- 🔨 **Built from source** — Gotenberg and pdfcpu compiled with the latest Go toolchain and patched transitive dependencies
- 🚫 **No Java / no pdftk** — Legacy Java runtime and `pdftk` JAR removed; replaced by native `qpdf` and `pdfcpu`
- 🔒 **Non-root by default** — Runs as unprivileged `gotenberg` user (UID 1001), OpenShift-compatible
- 🌍 **Full font support** — DejaVu, Liberation, Carlito, Noto (CJK + Emoji) pre-installed for accurate PDF rendering
- 🔁 **Drop-in replacement** — Identical HTTP API to the official `gotenberg/gotenberg` image; no client-side changes required
- 📄 **Multi-format conversion** — HTML→PDF (Chromium), DOCX/XLSX/PPTX→PDF (LibreOffice), PDF merge/split/compress (qpdf + pdfcpu)

---

## Quick Start

### Build Locally

```bash
# Clone the repository
git clone https://github.com/CretanBull/gotenberg-alpine.git
cd gotenberg-alpine

# Build (takes 5–15 minutes on first run)
docker build -t gotenberg-alpine:8.38.1-libreoffice .

# Run
docker run --rm -p 3000:3000 gotenberg-alpine:8.38.1-libreoffice
```

### Docker Compose

```yaml
services:
  gotenberg:
    image: gotenberg-alpine:8.38.1-libreoffice
    ports:
      - "3000:3000"
    restart: unless-stopped
    # Optional: pass Gotenberg flags as command arguments
    command:
      - "gotenberg"
      - "--chromium-disable-javascript=true"
      - "--chromium-allow-list=https://.*"
```

### Verify the service is running

```bash
curl http://localhost:3000/health
```

> For a full list of Gotenberg API endpoints and options, see the [official Gotenberg documentation](https://gotenberg.dev/docs).

---

## Usage

### Start the container

```bash
docker run -d \
  --name gotenberg \
  -p 3000:3000 \
  gotenberg-alpine:8.38.1-libreoffice
```

Verify it is running:

```bash
docker ps | grep gotenberg
docker logs gotenberg
```

### Convert a document to PDF

Use the LibreOffice route to convert any supported office format (`.doc`, `.docx`, `.odt`, `.xlsx`, `.pptx`, `.rtf`, etc.) to PDF:

```bash
curl -X POST http://localhost:3000/forms/libreoffice/convert \
  -F "files=@$HOME/Downloads/your-document.docx" \
  -o output.pdf
```

> **Note:** Use `$HOME` instead of `~` — curl does not expand tilde inside `-F` flags.

### Convert HTML to PDF (Chromium)

```bash
curl -X POST http://localhost:3000/forms/chromium/convert/html \
  -F "files=@$HOME/Downloads/index.html" \
  -o output.pdf
```

### Stop and remove the container

```bash
docker stop gotenberg && docker rm gotenberg
```

> For the full list of API routes and options, see the [official Gotenberg documentation](https://gotenberg.dev/docs).

---

## Build Arguments

These `ARG` values can be overridden at build time with `--build-arg`:

| Argument | Default | Description |
| :--- | :---: | :--- |
| `GOTENBERG_VERSION` | `v8.38.1` | Gotenberg Git tag to clone and build from source |
| `UNOCONVERTER_VERSION` | `v0.5.0` | Unoconverter script version to fetch |
| `GOTENBERG_USER_UID` | `1001` | UID for the unprivileged `gotenberg` runtime user |
| `GOTENBERG_USER_GID` | `1001` | GID for the unprivileged `gotenberg` runtime group |

**Example:**

```bash
docker build \
  --build-arg GOTENBERG_VERSION=v8.39.0 \
  --build-arg GOTENBERG_USER_UID=2000 \
  -t gotenberg-alpine:8.39.0-libreoffice .
```

---

## Runtime Environment Variables

These variables are pre-configured in the image and wire Gotenberg to the correct binary paths. Override them only if you customise the runtime layout.

| Variable | Default Value | Description |
| :--- | :--- | :--- |
| `CHROMIUM_BIN_PATH` | `/usr/bin/chromium-browser` | Path to the Chromium binary |
| `CHROMIUM_HYPHEN_DATA_DIR_PATH` | `/opt/gotenberg/chromium-hyphen-data` | Chromium hyphenation dictionary directory |
| `LIBREOFFICE_BIN_PATH` | `/usr/lib/libreoffice/program/soffice.bin` | Path to the LibreOffice binary |
| `UNOCONVERTER_BIN_PATH` | `/usr/bin/unoconverter` | Path to the unoconverter script |
| `QPDF_BIN_PATH` | `/usr/bin/qpdf` | Path to qpdf |
| `EXIFTOOL_BIN_PATH` | `/usr/bin/exiftool` | Path to ExifTool |
| `PDFCPU_BIN_PATH` | `/usr/bin/pdfcpu` | Path to pdfcpu |
| `PYTHONPATH` | `/usr/lib/libreoffice/program` | Required for pyuno (LibreOffice→PDF Python bridge) |
| `LANG` / `LC_ALL` | `C.UTF-8` | Locale settings for consistent PDF text rendering |
| `OTEL_*_EXPORTER` | `none` | OpenTelemetry exporters disabled by default |

> Additional Gotenberg runtime flags (e.g. `--api-port`, `--chromium-disable-javascript`, `--log-level`) are passed as `CMD` arguments and documented at [gotenberg.dev/docs](https://gotenberg.dev/docs).

---

## Supported Conversion Engines

| Engine | Source | Used For |
| :--- | :--- | :--- |
| **Chromium** | Alpine system package | HTML / URL → PDF |
| **LibreOffice** | Alpine system package | DOCX, XLSX, PPTX, ODT → PDF |
| **qpdf** | Alpine system package | PDF merge, split, flatten, linearise, encrypt |
| **pdfcpu** | Built from source | PDF compress, validate, stamp, watermark |
| **ExifTool** | Alpine system package | PDF metadata read / write |
| **unoconverter** | `v0.5.0` (upstream script) | Python bridge for LibreOffice UNO API |

---

## Security

### Upstream vs. Hardened Comparison (`v8.38.1`)

| Scan Target | `gotenberg/gotenberg:8.38.1` (Debian 13.7) | `gotenberg-alpine:8.38.1-libreoffice` | How It Was Remediated |
| :--- | :---: | :---: | :--- |
| **OS Packages** | 1,618 (1 Critical, 310 High) | **0 Fixable** | Migrated from Debian 13.7 to fully-patched Alpine 3.24 |
| **`usr/bin/gotenberg`** | 23 | **0** | Recompiled from source with latest Go toolchain; `echo/v5` upgraded to v5.4.1 |
| **`usr/bin/pdfcpu`** | 20 | **1 (UNKNOWN, no fix)** | Recompiled from source with patched transitive Go modules; 1 informational advisory remains |
| **`usr/bin/pdftk-all.jar`** | 1 | **Removed** | Stripped legacy Java runtime & `pdftk` JAR; replaced by native `qpdf` and `pdfcpu` |

📋 Full findings and analysis → [trivy-report.md](./trivy-report.md)

To report a security vulnerability privately, please use
[GitHub Security Advisories](https://github.com/CretanBull/gotenberg-alpine/security/advisories/new).
Do **not** open a public issue for security disclosures.

---

## Contributing

Contributions, bug reports, and version-bump PRs are welcome!

Please read [CONTRIBUTING.md](./CONTRIBUTING.md) for:
- Development environment setup and build instructions
- The canonical Trivy scan workflow
- Branch naming and Conventional Commits format
- Pull request checklist and review process

---

## License

Distributed under the [MIT License](./LICENSE).
Copyright © 2026 [Salvino D'sa](https://github.com/CretanBull).

> This project is an independent rebuild and is **not affiliated with** the official
> [Gotenberg project](https://gotenberg.dev/) or its maintainers.