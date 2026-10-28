# Contributing to gotenberg-alpine

First off — **thank you** for taking the time to contribute! 🎉

`gotenberg-alpine` is a community-maintained, security-hardened Docker image that rebuilds [Gotenberg](https://gotenberg.dev/) from source on Alpine Linux. Every contribution — whether it is a bug report, a dependency version bump, a Dockerfile improvement, or a documentation fix — directly helps teams ship safer software.

This guide will walk you through everything you need to know to make a successful contribution.

---

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Ways to Contribute](#ways-to-contribute)
  - [Reporting Bugs](#reporting-bugs)
  - [Suggesting Enhancements](#suggesting-enhancements)
  - [Updating Gotenberg or Dependency Versions](#updating-gotenberg-or-dependency-versions)
  - [Reporting Security Vulnerabilities](#reporting-security-vulnerabilities)
- [Development Environment Setup](#development-environment-setup)
  - [Prerequisites](#prerequisites)
  - [Building the Image Locally](#building-the-image-locally)
  - [Running a Security Scan](#running-a-security-scan)
- [Contribution Workflow](#contribution-workflow)
  - [1. Fork & Clone](#1-fork--clone)
  - [2. Create a Branch](#2-create-a-branch)
  - [3. Make Your Changes](#3-make-your-changes)
  - [4. Commit Your Changes](#4-commit-your-changes)
  - [5. Open a Pull Request](#5-open-a-pull-request)
- [Dockerfile Contribution Standards](#dockerfile-contribution-standards)
- [Pull Request Guidelines](#pull-request-guidelines)
- [Versioning & Releases](#versioning--releases)
- [License](#license)

---

## Code of Conduct

This project and everyone participating in it is governed by the [Contributor Covenant Code of Conduct v2.1](https://www.contributor-covenant.org/version/2/1/code_of_conduct/). By participating, you are expected to uphold this code.

Please report unacceptable behavior by opening a [GitHub issue](https://github.com/CretanBull/gotenberg-alpine/issues) marked **[CoC]**, or by contacting the maintainer directly via GitHub.

---

## Ways to Contribute

### Reporting Bugs

If something isn't working as expected, please [open a GitHub issue](https://github.com/CretanBull/gotenberg-alpine/issues/new) and include:

- A clear, descriptive title (e.g., `LibreOffice conversion fails with .docx files on ARM64`)
- The exact `docker run` command or `docker-compose` snippet you used
- The full error output or unexpected behavior you observed
- The host OS, CPU architecture (`amd64` / `arm64`), and Docker version
- The image tag you pulled (e.g., `gotenberg-alpine:8.38.1-libreoffice`)

> **Tip:** Run `docker inspect <image>` and include the `Labels` section — it often contains useful version metadata.

---

### Suggesting Enhancements

We welcome thoughtful enhancement ideas. Before opening a feature request, please:

1. Search [existing issues](https://github.com/CretanBull/gotenberg-alpine/issues) to avoid duplicates.
2. Check whether the enhancement is better suited to the [upstream Gotenberg project](https://github.com/gotenberg/gotenberg/issues).

When you're ready, [open a new issue](https://github.com/CretanBull/gotenberg-alpine/issues/new) and describe:

- The problem you are trying to solve
- Your proposed solution and any alternatives you considered
- Any trade-offs (image size, build time, security surface)

---

### Updating Gotenberg or Dependency Versions

Version bump contributions are highly valued — they are the primary mechanism that keeps this image's CVE count at zero. The typical workflow is:

1. Update `GOTENBERG_VERSION` (or `UNOCONVERTER_VERSION`) in the `ARG` block at the top of the `Dockerfile`.
2. Build and scan the image locally (see [Development Environment Setup](#development-environment-setup)).
3. Verify the Gotenberg health endpoint responds correctly after the build.
4. Open a PR following the [Conventional Commits](#4-commit-your-changes) format, e.g.:

   ```
   feat(dockerfile): upgrade Gotenberg to v8.39.0
   ```

---

### Reporting Security Vulnerabilities

> [!CAUTION]
> **Do NOT open a public GitHub issue for security vulnerabilities.**

If you discover a CVE, misconfiguration, or other security issue affecting this image, please disclose it responsibly via **[GitHub Private Security Advisory](https://github.com/CretanBull/gotenberg-alpine/security/advisories/new)**.

Include:
- A description of the vulnerability and its potential impact
- Steps to reproduce (a minimal `docker run` command or Trivy/Grype scan output)
- The affected image version(s)
- Any suggested remediation, if you have one

We aim to acknowledge all security reports within **48 hours** and to publish a patched release within **7 days** of a confirmed vulnerability.

---

## Development Environment Setup

### Prerequisites

| Tool | Minimum Version | Purpose |
|:---|:---|:---|
| [Docker](https://docs.docker.com/get-docker/) | 24.x | Build and run the image |
| [Trivy](https://aquasecurity.github.io/trivy/latest/getting-started/installation/) | 0.50+ | Security scanning (CI gate) |
| Git | 2.x | Version control |

> **Optional:** [Grype](https://github.com/anchore/grype) or [Snyk CLI](https://docs.snyk.io/snyk-cli) can be used as secondary scanners for cross-validation.

---

### Building the Image Locally

```bash
# Clone your fork
git clone https://github.com/<your-username>/gotenberg-alpine.git
cd gotenberg-alpine

# Build the image — tag it with the real version
# (this will take several minutes on first run — Gotenberg and pdfcpu compile from source)
docker build -t gotenberg-alpine:8.38.1-libreoffice .

# Smoke-test: start the container and hit the health endpoint
docker run --rm -d --name gotenberg-test -p 3000:3000 gotenberg-alpine:8.38.1-libreoffice
sleep 5
curl -sf http://localhost:3000/health && echo "✅ Health check passed"
docker stop gotenberg-test
```

> **Note on build time:** The first build compiles Gotenberg, pdfcpu, and fetches Alpine packages. Expect **5–15 minutes** depending on your machine and internet speed. Subsequent builds benefit from Docker's layer cache.

---

### Running a Security Scan

The core mission of this project is a **zero fixable HIGH/CRITICAL CVE** image. All PRs are expected to pass this scan gate before merging.

Run the following steps from the project root:

---

#### Step 1 — Build the image

```bash
docker build -t gotenberg-alpine:8.38.1-libreoffice .
```

---

#### Step 2 — Export to tar

Exporting avoids Docker socket issues across all environments (rootless Docker, Podman, CI runners).

```bash
docker save gotenberg-alpine:8.38.1-libreoffice -o gotenberg-alpine.tar
```

---

#### Step 3 — Scan with Trivy

```bash
docker run --rm \
  -v $HOME/.cache/trivy:/root/.cache/trivy \
  -v $(pwd):/workspace \
  aquasec/trivy:latest image \
  --input /workspace/gotenberg-alpine.tar
```

---

#### Cleanup

```bash
rm gotenberg-alpine.tar
```

A successful scan prints a results table per target. If your changes introduce new HIGH or CRITICAL fixable CVEs, the CI pipeline will fail and the PR will be blocked.

---

## Contribution Workflow

### 1. Fork & Clone

```bash
# Fork the repo on GitHub, then clone your fork
git clone https://github.com/<your-username>/gotenberg-alpine.git
cd gotenberg-alpine

# Add the upstream remote so you can stay in sync
git remote add upstream https://github.com/CretanBull/gotenberg-alpine.git
```

---

### 2. Create a Branch

Branch off `main` with a descriptive name. Use the following convention:

| Type | Branch Pattern | Example |
|:---|:---|:---|
| Bug fix | `fix/<short-description>` | `fix/chromium-arm64-crash` |
| Feature / enhancement | `feat/<short-description>` | `feat/add-font-noto-extra` |
| Dependency / version bump | `deps/<component>-<version>` | `deps/gotenberg-v8.39.0` |
| Documentation | `docs/<short-description>` | `docs/update-quick-start` |
| Security patch | `security/<short-description>` | `security/patch-golang-x-net` |

```bash
git checkout -b feat/your-feature-name
```

---

### 3. Make Your Changes

- Keep changes **focused and minimal** — one logical change per PR.
- If your change touches the `Dockerfile`, follow the [Dockerfile Contribution Standards](#dockerfile-contribution-standards) below.
- Update `README.md` if you are changing a version number, adding/removing a tool, or altering the vulnerability comparison table.

---

### 4. Commit Your Changes

This project follows the **[Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/)** specification. This enables automated changelogs and clean release histories.

**Format:**

```
<type>(<scope>): <short summary>

[optional body]

[optional footer(s)]
```

**Allowed types:**

| Type | When to use |
|:---|:---|
| `feat` | A new capability or tool is added to the image |
| `fix` | A bug, broken behavior, or CVE patch (use `fix(security):` scope for vulnerability fixes) |
| `deps` | A dependency version is updated (Go module, Alpine package, binary) |
| `docs` | Changes to documentation only |
| `chore` | Maintenance tasks (CI config, `.gitignore`, etc.) |
| `refactor` | Dockerfile restructuring with no functional change |
| `perf` | Image size or build time improvements |

**Examples:**

```bash
git commit -m "deps(dockerfile): upgrade Alpine base to 3.25"
git commit -m "fix(security): patch golang.org/x/net to v0.38.0 for CVE-XXXX-XXXX"
git commit -m "feat(fonts): add font-noto-arabic for improved LibreOffice rendering"
git commit -m "fix(env): correct CHROMIUM_BIN_PATH for arm64 Alpine layout"
```

> **Tip:** Keep the subject line under 72 characters. Use the commit body to explain *why*, not *what*.

---

### 5. Open a Pull Request

```bash
# Push your branch to your fork
git push origin feat/your-feature-name
```

Then open a Pull Request against `CretanBull/gotenberg-alpine:main` on GitHub. Fill in the PR template (if prompted) and ensure your PR satisfies the checklist in [Pull Request Guidelines](#pull-request-guidelines).

---

## Dockerfile Contribution Standards

Since the `Dockerfile` is the only source artifact in this project, quality standards for it are especially important.

### Layer Hygiene

- Combine related `RUN` commands with `&&` and `\` continuations to minimize layers.
- Always clean the APK cache in the same `RUN` layer it was populated:

  ```dockerfile
  RUN apk add --no-cache some-package && \
      rm -rf /var/cache/apk/* /tmp/* /var/tmp/*
  ```

- Never leave intermediate build artifacts in the final stage. Use multi-stage builds.

### Build Reproducibility

- **Pin versions** for all `ARG` values (Gotenberg, unoconverter, Alpine base). Avoid `latest` tags.
- When patching Go transitive dependencies with `go get -u <module>`, always follow with `go mod tidy` to keep `go.sum` consistent.
- Use `--depth 1` when cloning source repositories to keep the build layer lean.

### Security Principles

- **Run as a non-root user.** The `gotenberg` unprivileged user must remain the final `USER` directive.
- Do not add `--privileged` or cap additions (`CAP_NET_ADMIN`, etc.) to the image.
- Prefer `apk add --no-cache` over two-step `apk update && apk add` (the latter leaves a cache layer).
- Strip binaries with `-ldflags="-s -w"` when compiling Go binaries to reduce size and remove symbol table information.

### Environment Variables

- All `ENV` keys must be **SCREAMING_SNAKE_CASE**.
- Document the purpose of non-obvious environment variables with an inline `# comment` above the `ENV` block.
- Do not hard-code values that should be configurable — use `ARG` + `ENV` pairs.

### `ARG` vs `ENV`

| Directive | Use for |
|:---|:---|
| `ARG` | Build-time variables (versions, UIDs) that don't need to persist at runtime |
| `ENV` | Runtime configuration (binary paths, locale settings) |

---

## Pull Request Guidelines

### PR Checklist

Before marking your PR as ready for review, please confirm all of the following:

- [ ] `docker build -t gotenberg-alpine:local .` completes without errors
- [ ] `curl http://localhost:3000/health` returns HTTP 200 after `docker run`
- [ ] `trivy image --exit-code 1 --severity HIGH,CRITICAL gotenberg-alpine:local` reports **0** findings
- [ ] Commit messages follow the [Conventional Commits](#4-commit-your-changes) format
- [ ] `README.md` is updated if a version number, tool, or comparison table row changed
- [ ] The PR title follows Conventional Commits format (e.g., `deps(dockerfile): upgrade Gotenberg to v8.39.0`)
- [ ] The PR targets the `main` branch

### What to Expect

- **First response:** Within **48 hours** of opening a PR.
- **Review cycle:** PRs are reviewed on a best-effort basis. Please be patient — this is a community project maintained in spare time.
- **Merge criteria:** All CI checks must pass, and at least one maintainer approval is required.
- **Squash vs. merge:** PRs are merged using **squash merge** to keep the `main` branch history linear and clean.

---

## Versioning & Releases

This project tracks [Semantic Versioning](https://semver.org/) scoped to the **Gotenberg upstream release** it targets:

| Image Tag | Meaning |
|:---|:---|
| `8.38.1-libreoffice` | Tracks Gotenberg `v8.38.1` with LibreOffice, latest hardened build |
| `8.38.1-libreoffice-alpine3.24` | Locked to a specific Alpine version (for reproducibility) |
| `latest` | Points to the most recent stable hardened build |

**Release cadence:**
- A new image version is published when: upstream Gotenberg releases a new version, a HIGH/CRITICAL CVE is patched in a core component, or Alpine releases a new base image.
- Releases are tagged as Git tags matching the Gotenberg version (e.g., `v8.39.0`).

If you would like to propose support for a new upstream Gotenberg version, open a GitHub issue labelled `version-bump` first to coordinate effort.

---

## License

By contributing to this project, you agree that your contributions will be licensed under the same **[MIT License](./LICENSE)** that covers the project.

---

*Thank you again for your interest in making `gotenberg-alpine` better for everyone. We look forward to your contribution!* 🚀
