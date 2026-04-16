#!/usr/bin/env bash

# Exit on error
set -e

# Configuration
FLAKE_PATH="."
FLAKE_ATTR="nixos"
DISKO_CONFIG="./nixos/disko-config.nix"
EXPERIMENTAL_FLAGS="--extra-experimental-features 'nix-command flakes'"

echo "--- NixOS Installation Script ---"

# Check for root
if [ "$EUID" -ne 0 ]; then
  echo "Error: Please run as root (sudo)."
  exit 1
fi

# 1. Safety Check for Disk
DISK_TARGET=$(grep 'device =' "$DISKO_CONFIG" | cut -d'"' -f2)
echo "WARNING: This will WIPE EVERYTHING on $DISK_TARGET."
read -p "Are you sure you want to proceed? (y/N): " confirm
if [[ $confirm != [yY] ]]; then
  echo "Installation aborted."
  exit 1
fi

# 2. Experimental Features Check
echo "Ensuring experimental features are usable..."

# 3. Partitioning with Disko
echo "Step 1: Partitioning and Mounting disks with Disko..."
nix $EXPERIMENTAL_FLAGS run github:nix-community/disko -- --mode disko "$DISKO_CONFIG"

# 4. Installation
echo "Step 2: Installing NixOS..."
nixos-install --flake "$FLAKE_PATH#$FLAKE_ATTR"

echo "--------------------------------------------------"
echo "INSTALLATION COMPLETE!"
echo "--------------------------------------------------"
echo "1. Set a password for your user if you haven't already."
echo "2. Run 'reboot'."
echo "3. UNPLUG the USB stick before it starts back up."
echo "--------------------------------------------------"
