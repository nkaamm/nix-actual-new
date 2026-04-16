# This is your system's configuration file.
# Use this to configure your system environment (it replaces /etc/nixos/configuration.nix)
{
  inputs,
  lib,
  config,
  pkgs,
  ...
}: {
  # You can import other NixOS modules here
  imports = [
    # If you want to use modules your own flake exports (from modules/nixos):
    # inputs.self.nixosModules.example

    # Or modules from other flakes (such as nixos-hardware):
    # inputs.hardware.nixosModules.common-cpu-amd
    # inputs.hardware.nixosModules.common-ssd

    # You can also split up your configuration and import pieces of it here:
    # ./users.nix



    # Import your generated (nixos-generate-config) hardware configuration
    ./hardware-configuration.nix
    ./nvidia.nix
    ./disko-config.nix
    inputs.fht-compositor.nixosModules.default
  ];

  networking.hostName = "nixos"; # Define your hostname.

nixpkgs = {
overlays = [
  inputs.self.overlays.additions
  inputs.self.overlays.modifications
  inputs.self.overlays.unstable-packages
  inputs.millennium.overlays.default
  inputs.nix-cachyos-kernel.overlays.pinned






  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

      # Or define it inline, for example:
      # (final: prev: {
      #   hi = final.hello.overrideAttrs (oldAttrs: {
      #     patches = [ ./change-hello-to-hi.patch ];
      #   });
      # })
    ];
    # Configure your nixpkgs instance
    config = {
      # Disable if you don't want unfree packages
      allowUnfree = true;
    };
  };



  # linux Kernel
  #boot.kernelPackages = pkgs.linuxPackages_zen;
  boot.kernelPackages = pkgs.cachyosKernels.linuxPackages-cachyos-latest-lto-zen4;


  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;


  #kernel
  # Set your time zone.
  time.timeZone = "Europe/Vilnius";

nix = let
  flakeInputs = lib.filterAttrs (_: lib.isType "flake") inputs;
in {
  settings = {
    trusted-users = [ "root" "@wheel" ];
    substituters = [ 
      "https://aseipp-nix-cache.global.ssl.fastly.net"
      "https://attic.xuyh0120.win/lantian" 
      "https://cache.garnix.io"
    ];
    trusted-public-keys = [ 
      "lantian:EeAUQ+W+6r7EtwnmYjeVwx5kOGEBpjlBfPlzGlTNvHc=" 
      "cache.garnix.io:CTFPyKSLcx5RMJKfLo5EEPUObbA78b0YQ2DTCJXqr9g="
    ];

    experimental-features = [ "nix-command" "flakes" ];
    flake-registry = "";
    nix-path = config.nix.nixPath;
    system-features = [
      "benchmark"
      "big-parallel"
      "kvm"
      "nixos-test"
    ];
  };

  channel.enable = false;
  registry = lib.mapAttrs (_: flake: { inherit flake; }) flakeInputs;
  nixPath = lib.mapAttrsToList (n: _: "${n}=flake:${n}") flakeInputs;
};

  services.flatpak.enable = true;


  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  # Enable the X11 windowing system.
  # You can disable this if you're only using the Wayland session.
  services.xserver.enable = true;

  # Enable the KDE Plasma Desktop Environment.
  services.displayManager.sddm.enable = true;
#  services.desktopManager.plasma6.enable = true; #nope, disabled

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Enable sound with pipewire.
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # If you want to use JACK applications, uncomment this
    #jack.enable = true;

    # use the example session manager (no others are packaged yet so this is enabled by default,
    # no need to redefine it in your config for now)
    #media-session.enable = true;
  };

  # Enable touchpad support (enabled default in most desktopManager).
  # services.xserver.libinput.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.mysuvi = {
    isNormalUser = true;
    description = "mysuvi";
    extraGroups = [ "networkmanager" "wheel" "video"];
    packages = with pkgs; [
      kdePackages.kate
    #  thunderbird
    ];
    shell = pkgs.fish;
  };

  networking.nameservers = [
    "1.1.1.1"
    "1.0.0.1"
    "2606:4700:4700::1111"
    "2606:4700:4700::1001"
  ];

  # Install firefox.
programs = {
  #firefox = {
    #enable = true;
  #};

  steam = {
    enable = true;
  };
};

programs.hyprland.enable = true;

programs.niri.enable = true;

programs.fht-compositor.enable = true;



programs.dms-shell = {
  enable = true;
  quickshell.package = inputs.quickshell.packages.${pkgs.stdenv.hostPlatform.system}.quickshell;

    systemd = {
    enable = true;             # Systemd service for auto-start
    restartIfChanged = true;   # Auto-restart dms.service when dms-shell changes
  };
    enableSystemMonitoring = true;     # System monitoring widgets (dgop)
  enableVPN = true;                  # VPN management widget
  enableDynamicTheming = true;       # Wallpaper-based theming (matugen)
  enableAudioWavelength = true;      # Audio visualizer (cava)
  enableCalendarEvents = true;       # Calendar integration (khal)
  enableClipboardPaste = true;       # Pasting from the clipboard history (wtype)

};

    programs.fish.enable = true;
  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
  fastfetch
  inputs.helium.packages.${system}.default
  kitty
  kdePackages.dolphin
  kdePackages.qtsvg
  kdePackages.ark
  pkgs.kdePackages.qt6ct
  pkgs.wlr-randr
  pkgs.qbittorrent-enhanced
  pkgs.musikcube
  pkgs.antigravity
  pkgs.mangowc
  pkgs.brave-origin-nightly
#  inputs.noctalia.packages.${pkgs.stdenv.hostPlatform.system}.default
  #  vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
  #  wget
  ];

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  # services.openssh.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "26.05"; # Did you read the comment?
    programs.git.enable = true;





}
