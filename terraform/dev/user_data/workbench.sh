#!/bin/bash
# First-boot setup for the workbench (Amazon Linux 2023, x86). Docker, Compose, git and Task, so
# `git clone` + `task up` runs the full stack here.
set -euxo pipefail
dnf install -y docker git
systemctl enable --now docker
usermod -aG docker ssm-user || true
mkdir -p /usr/local/lib/docker/cli-plugins
curl -fsSL https://github.com/docker/compose/releases/download/v5.5.1/docker-compose-linux-x86_64 \
  -o /usr/local/lib/docker/cli-plugins/docker-compose
chmod +x /usr/local/lib/docker/cli-plugins/docker-compose
curl -fsSL https://github.com/go-task/task/releases/download/v3.53.1/task_linux_amd64.tar.gz |
  tar -xz -C /usr/local/bin task
if [ ! -f /swapfile ]; then
  fallocate -l 4G /swapfile && chmod 600 /swapfile && mkswap /swapfile && swapon /swapfile
  echo '/swapfile none swap sw 0 0' >> /etc/fstab
fi
