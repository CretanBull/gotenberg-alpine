# Trivy Security Scan Report

> **Image:** `gotenberg-alpine:8.38.1` &nbsp;·&nbsp; **Scanned:** 2026-10-24 &nbsp;·&nbsp; **Trivy:** v0.76 &nbsp;·&nbsp; **Base OS:** Alpine 3.24.3

---

## Scan Summary

| Target | Type | Vulnerabilities |
| :--- | :--- | :---: |
| `/workspace/gotenberg-alpine.tar` (alpine 3.24.3) | alpine | ✅ 0 |
| `usr/bin/gotenberg` | gobinary | ✅ 0 |
| `usr/bin/pdfcpu` | gobinary | ⚠️ 1 (UNKNOWN) |

---

## Findings

### ✅ Alpine 3.24.3 — OS Packages

**No vulnerabilities detected.** All Alpine base packages are fully patched. Migration from Debian 13.7 (upstream) to Alpine 3.24 eliminated 1,618 OS-level findings including 1 Critical and 310 High severity issues.

---

### ✅ `usr/bin/gotenberg` — Go Binary

**No vulnerabilities detected.**

> **Previously reported:** An earlier build identified 4 findings in `github.com/labstack/echo/v5 v5.4.0`:
> - `GHSA-cxf3-9h37-7rr8` — 🔴 CRITICAL: Rejected WebSocket upgrades bypass route-level access controls
> - `GHSA-9969-6676-49h5` — 🟠 HIGH: WebSocket proxy retains connections after client disconnect
> - `GHSA-h53f-rm2w-w7rg` — 🟡 MEDIUM: X-Real-IP extractor trusts header value over sending peer
> - `GHSA-x9ff-22gv-65f4` — 🟡 MEDIUM: BodyDump discards BodyLimit overflow errors
>
> **Resolution:** The `Dockerfile` was patched to force-upgrade `echo/v5` to `v5.4.1` during the Gotenberg source build (`go get github.com/labstack/echo/v5@v5.4.1`). All 4 findings are resolved in the current image.

---

### ⚠️ `usr/bin/pdfcpu` — Go Binary

**Total: 1 (UNKNOWN: 1, LOW: 0, MEDIUM: 0, HIGH: 0, CRITICAL: 0)**

| Library | Advisory | Severity | Status | Installed | Fixed | Description |
| :--- | :--- | :---: | :---: | :---: | :---: | :--- |
| `golang.org/x/crypto` | [GO-2026-5932](https://pkg.go.dev/vuln/GO-2026-5932) | ⬜ UNKNOWN | affected | v0.58.0 | — | The `openpgp` sub-package is unmaintained and unsafe by design |

**Analysis:**

This is an **informational advisory**, not an exploitable vulnerability. The Go team has flagged the `golang.org/x/crypto/openpgp` sub-package as deprecated because it is unmaintained and has design-level weaknesses. Key facts:

- `pdfcpu` links against `golang.org/x/crypto` for cryptographic primitives used in **PDF encryption** (AES, RC4), **not** for OpenPGP operations.
- The `openpgp` sub-package is not imported or called by `pdfcpu` at runtime.
- There is **no fixed version available** upstream; the advisory recommends migrating to the `github.com/ProtonMail/go-crypto` fork, which is a `pdfcpu` upstream concern.
- Severity is rated `UNKNOWN` because no CVSS score has been assigned — it is a deprecation notice, not a CVE.

**This finding does not affect Gotenberg's PDF conversion functionality.**

---

## Severity Legend

| Icon | Severity | Meaning |
| :---: | :--- | :--- |
| 🔴 | CRITICAL | Remote code execution or full system compromise possible |
| 🟠 | HIGH | Significant data exposure or privilege escalation |
| 🟡 | MEDIUM | Limited impact, typically requires specific conditions to exploit |
| 🔵 | LOW | Minimal real-world risk; theoretical or negligible impact |
| ⬜ | UNKNOWN | No CVSS score assigned; typically a deprecation or design advisory |
| ✅ | Clean | No vulnerabilities detected in this target |

---

## How to Reproduce

Run the following commands from the project root:

```bash
# Step 1 — Build the image
docker build -t gotenberg-alpine:8.38.1 .

# Step 2 — Export to tar (avoids Docker socket issues on all environments)
docker save gotenberg-alpine:8.38.1 -o gotenberg-alpine.tar

# Step 3 — Scan with Trivy
docker run --rm \
  -v $HOME/.cache/trivy:/root/.cache/trivy \
  -v $(pwd):/workspace \
  aquasec/trivy:latest image \
  --input /workspace/gotenberg-alpine.tar

# Cleanup
rm gotenberg-alpine.tar
```

> For the full contributing and scanning workflow, see [CONTRIBUTING.md](./CONTRIBUTING.md).
