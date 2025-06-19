#!/usr/bin/env bash
set -euo pipefail

echo "Configuring UFW to Only SSH"

# Install ufw if missing
if ! command -v ufw >/dev/null 2>&1; then
  echo "Installing ufw..."
  sudo apt install -y ufw
fi

# Reset rules (careful: wipes existing ufw config)
echo "Resetting existing UFW rules..."
sudo ufw --force reset

# Default policies
sudo ufw default deny incoming
sudo ufw default allow outgoing

# Allow only SSH
sudo ufw allow ssh

# Enable firewall (force yes to skip prompt)
echo "Enabling UFW..."
sudo ufw --force enable

echo "UFW configured: only SSH allowed."
