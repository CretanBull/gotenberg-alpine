# Trivy Vulnerability Report — `gotenberg-alpine:8.38.1-libreoffice`

> Last Scan: 2026-10-28

## Scan Command

```bash
docker run --rm \
  -v /run/user/1000/docker.sock:/var/run/docker.sock \
  -v $HOME/.cache/trivy:/root/.cache/trivy \
  aquasec/trivy:latest image gotenberg-alpine:8.38.1-libreoffice
```

> **Note:** The socket path `/run/user/1000/docker.sock` is specific to rootless Docker.
> The `$HOME/.cache/trivy` volume mount caches the vulnerability DB so it is not re-downloaded on every scan.

---

## Report Summary

| Target | Type | Vulnerabilities | Secrets |
|--------|------|-----------------|---------|
| `gotenberg-alpine:8.38.1-libreoffice` (alpine 3.24.3) | alpine | **0** | - |
| `usr/bin/gotenberg` | gobinary | **0** | - |
| `usr/bin/pdfcpu` | gobinary | **1** | - |

---

## `usr/bin/pdfcpu` — Remaining Finding

| Library | Advisory | Severity | Status | Installed | Fixed At | Title |
|---------|----------|----------|--------|-----------|----------|-------|
| `golang.org/x/crypto` | GO-2026-5932 | UNKNOWN | affected | v0.58.0 | *(none)* | `golang.org/x/crypto/openpgp` is unmaintained, unsafe by design |

### Why this cannot be fixed

`golang.org/x/crypto/openpgp` has been declared **unmaintained by the Go team** and is unsafe by design. There is no patched version — the `Fixed Version` column is empty. This dependency is pulled in by `pdfcpu` upstream. The only permanent fix would require pdfcpu to remove the `openpgp` import entirely, which is an upstream responsibility.

**Risk assessment:** UNKNOWN severity (not HIGH or CRITICAL). This is a design advisory, not an exploitable CVE in the context of Gotenberg's PDF processing workload. **Accepted risk.**

### Suppression

To suppress this advisory in future scans, add a `.trivyignore` file to the project root:

```
# pdfcpu uses golang.org/x/crypto/openpgp which is unmaintained by design.
# No upstream fix available — accepted risk.
GO-2026-5932
```

Then add `--ignorefile /output/.trivyignore` to the scan command.
