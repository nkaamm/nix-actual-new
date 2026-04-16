#!/usr/bin/env bash
set -euo pipefail

# Configuration
FLAKE_PATH="."
FLAKE_ATTR="nixos"
DISKO_CONFIG="./nixos/disko-config.nix"
MOUNT_POINT="/mnt"



# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
  echo -e "${BLUE}[INFO]${NC} $*"
}

log_success() {
  echo -e "${GREEN}[SUCCESS]${NC} $*"
}

log_warning() {
  echo -e "${YELLOW}[WARNING]${NC} $*"
}

log_error() {
  echo -e "${RED}[ERROR]${NC} $*" >&2
}

# Error handler
trap 'log_error "Installation failed at line $LINENO"; exit 1' ERR

# Cleanup on exit
cleanup() {
  if [ -n "${TEMP_NIX_CONF:-}" ] && [ -f "$TEMP_NIX_CONF" ]; then
    rm -f "$TEMP_NIX_CONF"
  fi
}
trap cleanup EXIT

# ============================================================================
# VALIDATION PHASE
# ============================================================================

log_info "=== NixOS Installation Script ==="

# Check root privilege
if [ "$EUID" -ne 0 ]; then
  log_error "Please run as root (sudo)."
  exit 1
fi

# Check if flake exists
if [ ! -f "flake.nix" ]; then
  log_error "flake.nix not found in current directory. Are you in the repo root?"
  exit 1
fi

# Check if disko config exists
if [ ! -f "$DISKO_CONFIG" ]; then
  log_error "Disko config not found at $DISKO_CONFIG"
  exit 1
fi

# Extract disk target from disko config
DISK_TARGET=$(grep -E 'device\s*=' "$DISKO_CONFIG" | head -n 1 | cut -d'"' -f2)
if [ -z "$DISK_TARGET" ]; then
  log_error "Could not find device in $DISKO_CONFIG"
  exit 1
fi

log_warning "This will WIPE EVERYTHING on $DISK_TARGET"
log_info "Target disk: $DISK_TARGET"
log_info "Mount point: $MOUNT_POINT"
log_info "Flake attribute: $FLAKE_ATTR"

# Confirmation prompt
read -r -p "$(echo -e ${YELLOW})Are you sure you want to proceed? (type 'yes' to confirm): $(echo -e ${NC})" confirm
if [ "$confirm" != "yes" ]; then
  log_info "Installation aborted."
  exit 0
fi

# ============================================================================
# PREPARATION PHASE
# ============================================================================




# ============================================================================
# PARTITIONING PHASE
# ============================================================================

log_info "Step 1: Partitioning and mounting disks with Disko..."

if ! nix --extra-experimental-features "nix-command flakes" run github:nix-community/disko -- \
  --mode disko "$DISKO_CONFIG"; then
  log_error "Disko partitioning failed"
  exit 1
fi

log_success "Disks partitioned and mounted successfully"

# Verify mount
if ! mountpoint -q "$MOUNT_POINT"; then
  log_error "Mount point $MOUNT_POINT is not mounted"
  exit 1
fi

# ============================================================================
# INSTALLATION PHASE
# ============================================================================

log_info "Step 2: Installing NixOS..."
log_info "This may take a while..."

if ! nixos-install --flake "$FLAKE_PATH#$FLAKE_ATTR" --root "$MOUNT_POINT"; then
  log_error "NixOS installation failed"
  exit 1
fi

log_success "NixOS installation completed successfully"

# ============================================================================
# POST-INSTALLATION
# ============================================================================

echo ""
log_success "============================================================"
log_success "         INSTALLATION COMPLETE!"
log_success "============================================================"
echo ""
log_info "Next steps:"
echo "  1. Chroot into the new system and set a password:"
echo "     nixos-enter --root $MOUNT_POINT"
echo "     passwd mysuvi  # or your username"
echo "     exit"
echo ""
echo "  2. Reboot:"
echo "     reboot"
echo ""
echo "  3. UNPLUG the USB stick BEFORE it starts back up"
echo ""
log_warning "DO NOT FORGET TO UNPLUG THE USB STICK!"
echo ""
