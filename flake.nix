{
  description = "Your new nix config";

  inputs = {
    # Nixpkgs
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    # You can access packages and modules from different nixpkgs revs
    # at the same time. Here's an working example:
    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-25.11";
    # Also see the 'unstable-packages' overlay at 'overlays/default.nix'.

    nix-flatpak.url = "github:gmodena/nix-flatpak";

        quickshell = {
      url = "git+https://git.outfoxxed.me/quickshell/quickshell";
      inputs.nixpkgs.follows = "nixpkgs";

    };
    # Home manager
    home-manager.url = "github:nix-community/home-manager/release-25.11";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    helium = {
    url = "github:schembriaiden/helium-browser-nix-flake";
    inputs.nixpkgs.follows = "nixpkgs";

    };

    millennium.url = "github:SteamClientHomebrew/Millennium?dir=packages/nix";

    dolphin-overlay.url = "github:rumboon/dolphin-overlay";

    fjordlauncher = {
      url = "github:unmojang/FjordLauncher";

      # Optional: Override the nixpkgs input of fjordlauncher to use the same revision as the rest of your flake
      # Note that this may break the reproducibility mentioned above, and you might not be able to access the binary cache
      #
      # inputs.nixpkgs.follows = "nixpkgs";

      };
       fht-compositor = {
      url = "github:nferhat/fht-compositor?rev=0f10c976373d981139935b7bafbfba1dbed8121a";
      inputs.nixpkgs.follows = "nixpkgs";

      # If you make use of flake-parts yourself, override here
      # inputs.flake-parts.follows = "flake-parts";

      # Disable rust-overlay since it's only meant to be here for the devShell provided
      # (IE. only for developement purposes, end users don't care)
      inputs.rust-overlay.follows = "";

  };
    nix-cachyos-kernel = {
      url = "github:xddxdd/nix-cachyos-kernel/master";
    };

  };

  outputs = {
    self,
    nixpkgs,
    home-manager,
    dolphin-overlay,
    fjordlauncher,
    ...
  } @ inputs: let
    # Supported systems for your flake packages, shell, etc.
    systems = [
      "aarch64-linux"
      "i686-linux"
      "x86_64-linux"
      "aarch64-darwin"
      "x86_64-darwin"
    ];
    # This is a function that generates an attribute by calling a function you
    # pass to it, with each system as an argument
    forAllSystems = nixpkgs.lib.genAttrs systems;
  in {
    # Your custom packages
    # Accessible through 'nix build', 'nix shell', etc
    packages = forAllSystems (system: import ./pkgs nixpkgs.legacyPackages.${system});
    # Formatter for your nix files, available through 'nix fmt'
    # Other options beside 'alejandra' include 'nixpkgs-fmt'
    formatter = forAllSystems (system: nixpkgs.legacyPackages.${system}.alejandra);

    # Your custom packages and modifications, exported as overlays
    overlays = import ./overlays {inherit inputs;};
    # Reusable nixos modules you might want to export
    # These are usually stuff you would upstream into nixpkgs
    nixosModules = import ./modules/nixos;
    # Reusable home-manager modules you might want to export
    # These are usually stuff you would upstream into home-manager
    homeManagerModules = import ./modules/home-manager;

    # NixOS configuration entrypoint
    # Available through 'nixos-rebuild --flake .#your-hostname'
nixosConfigurations = {
  nixos = nixpkgs.lib.nixosSystem {
    specialArgs = { inherit inputs; };
modules = [
  ./nixos/configuration.nix

  {

    nixpkgs.overlays = [
      dolphin-overlay.overlays.default
      fjordlauncher.overlays.default
    ];

  }

  ({ pkgs, ... }: {
    environment.systemPackages = [
      pkgs.fjordlauncher
    ];
  })
];
  };
};

    # Standalone home-manager configuration entrypoint
    # Available through 'home-manager --flake .#your-username@your-hostname'
    homeConfigurations = {
      # FIXME replace with your username@hostname
      "mysuvi@nixos" = home-manager.lib.homeManagerConfiguration {
        # Home-manager requires 'pkgs' instance
        pkgs = nixpkgs.legacyPackages.x86_64-linux; # FIXME replace x86_64-linux with your architecure
        extraSpecialArgs = {inherit inputs;};
        modules = [

      ./home-manager/home.nix
        ];
      };
    };
  };
}
