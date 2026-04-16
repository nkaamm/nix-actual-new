#!/usr/bin/env bash
set -euo pipefail

FLAKE_PATH="."
FLAKE_ATTR="nixos"
DISKO_CONFIG="./nixos/disko-config.nix"

echo "--- NixOS Installation Script ---"

if [ "$EUID" -ne 0 ]; then
  echo "Error: Please run as root (sudo)."
  exit 1
fi

DISK_TARGET=$(grep 'device =' "$DISKO_CONFIG" | cut -d'"' -f2)
echo "WARNING: This will WIPE EVERYTHING on $DISK_TARGET."
read -r -p "Are you sure you want to proceed? (y/N): " confirm
if [[ $confirm != [yY] ]]; then
  echo "Installation aborted."
  exit 1
fi

echo "Step 1: Partitioning and Mounting disks with Disko..."
nix --extra-experimental-features "nix-command flakes" run github:nix-community/disko -- --mode disko "$DISKO_CONFIG"

echo "Step 2: Installing NixOS..."
nixos-install --flake "$FLAKE_PATH#$FLAKE_ATTR"

echo "--------------------------------------------------"
echo "INSTALLATION COMPLETE!"
echo "--------------------------------------------------"
echo "1. Set a password for your user if you haven't already."
echo "2. Run 'reboot'."
echo "3. UNPLUG the USB stick before it starts back up."
echo "--------------------------------------------------"
