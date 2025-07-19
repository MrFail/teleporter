# 🚀 Rsync Over SSH

A GitHub Action to upload files from your workflow to a remote server using `rsync` over SSH, securely using a **private key stored as an environment variable (secret)** — without writing complex scripts in your workflows.

---

## ✨ Features

- ✅ Sync files via `rsync` using SSH
- 📁 Preserves directory structure, timestamps, etc.
- ⚙️ Simple and reusable facade

---

## 📦 Inputs

| Name       | Required | Description                                        |
|------------|----------|----------------------------------------------------|
| `host`     | ✅        | SSH hostname or IP address of the remote server    |
| `port`     | ✅        | SSH Port of the remote server                      |
| `username` | ✅        | Username for SSH login                             |
| `path`     | ✅        | Target path on the remote server                   |
| `source`   | ❌        | Local directory to copy (default: `./dist`)        |
| `key`      | ✅        | The SSH private key (usually passed from a secret) |

---

## 🚀 Example Usage (in GitHub Actions)

```yaml
name: Deploy to CDN

on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: Build project
        run: npm run build

      - name: Deploy to CDN via rsync
        uses: your-username/rsync-ssh-action@v1
        with:
          host: ${{ secrets.CDN_HOST }}
          user: ${{ secrets.CDN_USER }}
          path: /var/www/cdn/
          key: ${{ secrets.CDN_SSH_KEY }}
```
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
