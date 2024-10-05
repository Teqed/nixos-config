{
  description = "
We still remember, we who dwell
In this far land beneath the trees
The starlight on the Western Seas.
";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    chaotic.url = "github:chaotic-cx/nyx/nyxpkgs-unstable";
    alejandra.url = "github:kamadorueda/alejandra/3.0.0";
    alejandra.inputs.nixpkgs.follows = "nixpkgs";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    nix-flatpak.url = "github:gmodena/nix-flatpak";
    # nix-flatpak.inputs.nixpkgs.follows = "nixpkgs"; #
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    # nixos-hardware.inputs.nixpkgs.follows = "nixpkgs"; #
    impermanence.url = "github:nix-community/impermanence?rev=63f4d0443e32b0dd7189001ee1894066765d18a5";
    # impermanence.inputs.nixpkgs.follows = "nixpkgs"; #
    nixpkgs-wayland.url = "github:nix-community/nixpkgs-wayland";
    nixpkgs-wayland.inputs.nixpkgs.follows = "nixpkgs"; #
    nix-index-database.url = "github:nix-community/nix-index-database";
    nix-index-database.inputs.nixpkgs.follows = "nixpkgs";
    plasma-manager = {
      url = "github:nix-community/plasma-manager";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };
    sddmSugarCandy4Nix = {
      url = "github:MOIS3Y/sddmSugarCandy4Nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";
  };
  outputs = {
    self,
    nixpkgs,
    home-manager,
    alejandra,
    chaotic,
    nix-flatpak,
    nixos-hardware,
    impermanence,
    nixpkgs-wayland,
    nix-index-database,
    plasma-manager,
    disko,
    ...
  } @ inputs: let
    inherit (self) outputs;
    systems = [
      # "aarch64-linux"
      # "i686-linux"
      "x86_64-linux"
      # "aarch64-darwin"
      # "x86_64-darwin"
    ];
    forAllSystems = nixpkgs.lib.genAttrs systems; # This is a function that generates an attribute by calling a function you pass to it, with each system as an argument
    inheritSpecialArgs = {
      inherit
        self
        inputs
        outputs
        nixos-hardware
        impermanence
        nix-flatpak
        nixpkgs-wayland
        ;
    };
    # <system> is something like "x86_64-linux", "aarch64-linux", "i686-linux", "x86_64-darwin"
    # <name> is an attribute name like "hello".
    # <flake> is a flake name like "nixpkgs".
    # <store-path> is a /nix/store.. path
  in {
    # # Executed by `nix flake check`
    # checks."<system>"."<name>" = derivation;

    # # Executed by `nix build .#<name>`
    # packages."<system>"."<name>" = derivation;
    packages = forAllSystems (system: import ./pkgs nixpkgs.legacyPackages.${system}); # Custom packages accessible through 'nix build', 'nix shell', etc

    # # Executed by `nix build .`
    # packages."<system>".default = derivation;

    # # Executed by `nix run .#<name>`
    # apps."<system>"."<name>" = {
    #   type = "app";
    #   program = "<store-path>";
    # };

    # # Executed by `nix run . -- <args?>`
    # apps."<system>".default = {
    #   type = "app";
    #   program = "...";
    # };

    # # Formatter (alejandra, nixfmt or nixpkgs-fmt)
    # formatter."<system>" = derivation;
    formatter = forAllSystems (system: nixpkgs.legacyPackages.${system}.alejandra); # Formatter for your nix files, available through 'nix fmt'.

    # # Used for nixpkgs packages, also accessible via `nix build .#<name>`
    # legacyPackages."<system>"."<name>" = derivation;

    # # Overlay, consumed by other flakes
    # overlays."<name>" = final: prev: {};

    # # Default overlay
    # overlays.default = final: prev: {};

    # # Nixos module, consumed by other flakes
    # nixosModules."<name>" = {config, ...}: {
    #   options = {};
    #   config = {};
    # };

    # # Default module
    # nixosModules.default = {config, ...}: {
    #   options = {};
    #   config = {};
    # };
    nixosModules = import ./modules/nixos {flakes = inputs;}; # Reusable nixos modules.

    # # Used with `nixos-rebuild switch --flake .#<hostname>`
    # # nixosConfigurations."<hostname>".config.system.build.toplevel must be a derivation
    # nixosConfigurations."<hostname>" = {};
    nixosConfigurations = {
      eris = nixpkgs.lib.nixosSystem {
        specialArgs = inheritSpecialArgs;
        modules = [
          ./hosts/eris.nix
          self.nixosModules.default
          chaotic.nixosModules.default
          home-manager.nixosModules.home-manager
          nix-flatpak.nixosModules.nix-flatpak
          self.homeManagerConfig
          disko.nixosModules.disko
        ];
      };
      # NixOS configuration entrypoint. Available through 'nixos-rebuild --flake .#sedna'
      sedna = nixpkgs.lib.nixosSystem {
        specialArgs = inheritSpecialArgs;
        modules = [
          ./hosts/sedna.nix
          self.nixosModules.default
          chaotic.nixosModules.default
          home-manager.nixosModules.home-manager
          nix-flatpak.nixosModules.nix-flatpak
          self.homeManagerConfig
        ];
      };
      thoughtful = nixpkgs.lib.nixosSystem {
        specialArgs = inheritSpecialArgs;
        modules = [
          ./hosts/thoughtful.nix
          self.nixosModules.default
          chaotic.nixosModules.default
          home-manager.nixosModules.home-manager
          nix-flatpak.nixosModules.nix-flatpak
          self.homeManagerConfig
        ];
      };
    };

    # # Used by `nix develop .#<name>`
    # devShells."<system>"."<name>" = derivation;

    # # Used by `nix develop`
    # devShells."<system>".default = derivation;

    # # Hydra build jobs
    # hydraJobs."<attr>"."<system>" = derivation;

    # # Used by `nix flake init -t <flake>#<name>`
    # templates."<name>" = {
    #   path = "<store-path>";
    #   description = "template description goes here?";
    # };
    # # Used by `nix flake init -t <flake>`
    # templates.default = {
    #   path = "<store-path>";
    #   description = "";
    # };

    homeManagerModules = import ./modules/home-manager {flakes = inputs;}; # Reusable home-manager modules.
    homeManagerConfig = {...}: {
      nixpkgs.hostPlatform = nixpkgs.lib.mkDefault "x86_64-linux";
      home-manager.extraSpecialArgs = inheritSpecialArgs;
      home-manager.sharedModules = [
        self.homeManagerModules.default # My custom modules
        nix-index-database.hmModules.nix-index # nix-index-database
        plasma-manager.homeManagerModules.plasma-manager # plasma-manager
      ];
    };
    homeConfigurations = {
      # home-manager --flake .#teq@somewhere
      "teq@somewhere" = home-manager.lib.homeManagerConfiguration {
        pkgs = nixpkgs.legacyPackages.x86_64-linux; # Home-manager requires 'pkgs' instance
        extraSpecialArgs = {inherit inputs outputs;};
        modules = [
          self.homeManagerModules.default # My custom modules
          nix-index-database.hmModules.nix-index # nix-index-database
          {
            teq.home-manager = {
              enable = true;
              fonts = false;
            };
          }
        ];
      };
    };
  };
}
