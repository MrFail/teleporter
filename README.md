# 🚀 Rsync Over SSH

A GitHub Action to upload files from your workflow to a remote server using `rsync` over SSH, securely using a **private key stored as an environment variable (secret)** — without writing complex scripts in your workflows.

---

## ✨ Features

- ✅ Sync files via `rsync` using SSH
- 📁 Preserves directory structure, timestamps, etc.
- ⚙️ Simple and reusable facade

---

## 📦 Inputs

| Name          | Required | Description                                                                    |
|---------------|----------|--------------------------------------------------------------------------------|
| `host`        | ✅        | SSH hostname or IP address of the remote server                                |
| `username`    | ✅        | Username for SSH login                                                         |
| `key`         | ✅        | The SSH private key (usually passed from a secret)                             |
| `port`        | ✅        | SSH Port of the remote server                                                  |
| `source`      | ✅        | Local directory to copy (default: `./dist`)                                    |
| `destination` | ✅        | Target path on the remote server                                               |

---

## 🚀 Example Usage (in GitHub Actions)

```yaml
name: Deploy to CDN

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - name: Deploy to CDN via rsync
        uses: mrfail/teleporter@v1
        with:
          host: ${{ secrets.REMOTE_HOST }}
          port: ${{ secrets.REMOTE_PORT }}
          username: ${{ secrets.REMOTE_USER }}
          key: ${{ secrets.REMOTE_SSH_KEY }}
          source: "./dist"
          destination: "/var/www/html/"
          exclude: "file.txt,dir"
          include: "file.txt,dir"
```
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
