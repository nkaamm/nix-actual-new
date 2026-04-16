# NixOS Configuration

A personalized NixOS configuration using Flakes, Disko for partitioning, and Home Manager for user-level settings.

## 🚀 Quick Install (Minimal ISO)

If you are on a fresh machine booting from a **NixOS Minimal ISO**, run these commands to install the entire system automatically:

```bash
# 1. Clone the repository
git clone https://github.com/nkaamm/nix-actual-new
cd nix-actual-new

# 2. Run the automated installer
sudo ./install.sh
```

---

## 🛠️ Prerequisites & Warnings

### ⚠️ Disk Wiping
The installer uses [disko-config.nix](nixos/disko-config.nix) which is currently configured for `/dev/nvme0n1`. Running `install.sh` **will wipe the entire drive**. Verify your disk name with `lsblk` before proceeding.

### ❄️ Hardware Compatibility (Zen 4)
This configuration uses the **CachyOS Zen 4 kernel** optimized for Ryzen 7000/9000 series CPUs. 
- If you have a different CPU, you should edit [nixos/configuration.nix](nixos/configuration.nix) to use a standard kernel before installing.

### 🔌 Connectivity
It is highly recommended to use an **Ethernet** connection during installation. 

---

## 🏠 Post-Installation

After rebooting into your new system, log in as `mysuvi` and apply your user-specific configuration (Home Manager):

```bash
home-manager switch --flake .#mysuvi@nixos
```

## 📂 Project Structure
- `nixos/`: System-wide configuration and hardware setup.
- `home-manager/`: User-level applications and dotfiles.
- `modules/`: Reusable Nix modules.
- `pkgs/`: Custom packages.
- `install.sh`: Automated deployment script.
