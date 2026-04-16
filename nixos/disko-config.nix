{ lib, ... }: {
  disko.devices = {
    disk = {
      main = {
        type = "disk";
        device = "/dev/nvme0n1"; # Change this to your actual disk, e.g., /dev/sda
        content = {
          type = "gpt";
          partitions = {
            ESP = {
              size = "2G";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
                mountOptions = [ "fmask=0077" "dmask=0077" ];
              };
            };
            root = {
              size = "100%";
              content = {
                type = "btrfs";
                extraArgs = [ "-f" ]; # Override existing partition
                subvolumes = {
                  "@" = {
                    mountpoint = "/";
                    mountOptions = [ "compress=zstd" "noatime" ];
                  };
                  "@home" = {
                    mountpoint = "/home";
                    mountOptions = [ "compress=zstd" "noatime" ];
                  };
                  "@nix" = {
                    mountpoint = "/nix";
                    mountOptions = [ "compress=zstd" "noatime" ];
                  };
                  "@log" = {
                    mountpoint = "/var/log";
                    mountOptions = [ "compress=zstd" "noatime" ];
                  };
                };
              };
            };
          };
        };
      };
    };
  };

  # Resolve conflicts with hardware-configuration.nix
  fileSystems."/".device = lib.mkForce "/dev/disk/by-partlabel/disk-main-root";
  fileSystems."/".fsType = lib.mkForce "btrfs";
  fileSystems."/".options = lib.mkForce [ "subvol=@" "compress=zstd" "noatime" ];
  
  fileSystems."/home".device = lib.mkForce "/dev/disk/by-partlabel/disk-main-root";
  fileSystems."/home".fsType = lib.mkForce "btrfs";
  fileSystems."/home".options = lib.mkForce [ "subvol=@home" "compress=zstd" "noatime" ];
  
  fileSystems."/nix".device = lib.mkForce "/dev/disk/by-partlabel/disk-main-root";
  fileSystems."/nix".fsType = lib.mkForce "btrfs";
  fileSystems."/nix".options = lib.mkForce [ "subvol=@nix" "compress=zstd" "noatime" ];
  
  fileSystems."/var/log".device = lib.mkForce "/dev/disk/by-partlabel/disk-main-root";
  fileSystems."/var/log".fsType = lib.mkForce "btrfs";
  fileSystems."/var/log".options = lib.mkForce [ "subvol=@log" "compress=zstd" "noatime" ];

  fileSystems."/boot".device = lib.mkForce "/dev/disk/by-partlabel/disk-main-ESP";
}
