# 🚀 Teleporter — rsync over SSH

A GitHub Action that syncs a directory from your workflow to a remote server with `rsync` over SSH, authenticated with a **private key stored as a secret** — no deploy scripts in your workflows.

---

## ✨ Features

- ✅ Incremental sync with `rsync` (only changed files travel)
- 🪞 Optional mirror mode (`delete: true`) — files removed from the build are removed from the server
- 🔐 Host key pinning via `known_hosts`; the private key lives in a temp dir that is always removed
- 📁 Creates the destination (and its parents) when missing
- 🎯 `exclude` / `include` patterns and free-form extra `rsync` arguments

The **remote server needs `rsync` installed** too (`apt install rsync`).

---

## 📦 Inputs

| Name          | Required | Default   | Description                                                                                         |
|---------------|----------|-----------|-----------------------------------------------------------------------------------------------------|
| `host`        | ✅        |           | SSH host name or IP address                                                                         |
| `username`    | ✅        |           | SSH user name                                                                                       |
| `key`         | ✅        |           | SSH private key (from a secret)                                                                     |
| `destination` | ✅        |           | Remote target directory, absolute or relative to the user's home (`~/site` works)                   |
| `port`        |          | `22`      | SSH port                                                                                            |
| `source`      |          | `./dist`  | Local directory whose **contents** are synced into `destination`                                    |
| `known_hosts` |          |           | Server host key line(s), from `ssh-keyscan -p <port> <host>`. Without it the key is trusted on first use (with a warning) |
| `delete`      |          | `false`   | `true` = delete remote files that are not in `source` (excluded files are kept)                     |
| `exclude`     |          |           | Patterns to skip, separated by spaces or new lines                                                  |
| `include`     |          |           | Patterns always synced even if an `exclude` matches them                                            |
| `args`        |          |           | Extra `rsync` arguments, e.g. `--dry-run` or `--chmod=D755,F644`                                    |

> `source` contents go **into** `destination`: `./dist/index.html` → `/var/www/html/index.html` (not `/var/www/html/dist/index.html`).

---

## 🚀 Example

```yaml
name: Deploy

on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      # ... build into ./dist ...

      - name: Deploy via rsync
        uses: mrfail/teleporter@v2
        with:
          host: ${{ secrets.REMOTE_HOST }}
          port: ${{ secrets.REMOTE_PORT }}
          username: ${{ secrets.REMOTE_USER }}
          key: ${{ secrets.REMOTE_SSH_KEY }}
          known_hosts: ${{ secrets.REMOTE_KNOWN_HOSTS }}
          source: ./dist
          destination: /var/www/html
          delete: true
          exclude: |
            .git
            *.map
          include: |
            .htaccess
```

Get the `known_hosts` value once, from a machine you trust:

```bash
ssh-keyscan -p 22 your.server.com
```

---

## ⬆️ Upgrading from v1

v1 used `scp -r`, which copied the `source` directory itself into `destination` (`/var/www/html/dist/...`). v2 syncs its **contents** (`/var/www/html/...`). If you relied on the old layout, set `destination` to the full path (e.g. `/var/www/html/dist`). The unused `password` input is gone.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
