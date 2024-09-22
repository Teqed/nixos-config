{
  description = "
We still remember, we who dwell
In this far land beneath the trees
The starlight on the Western Seas.
";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-24.05";
    chaotic.url = "github:chaotic-cx/nyx/nyxpkgs-unstable";
    alejandra.url = "github:kamadorueda/alejandra/3.0.0";
    alejandra.inputs.nixpkgs.follows = "nixpkgs";
    wezterm-flake.url = "github:wez/wezterm/main?dir=nix";
    wezterm-flake.inputs.nixpkgs.follows = "nixpkgs";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    nix-flatpak.url = "github:gmodena/nix-flatpak";
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
  };
  outputs = {
    self,
    nixpkgs,
    home-manager,
    alejandra,
    chaotic,
    nix-flatpak,
    nixos-hardware,
    ...
  } @ inputs: let
    inherit (self) outputs;
    systems = [
      # Supported systems for your flake packages, shell, etc.
      "aarch64-linux"
      "i686-linux"
      "x86_64-linux"
      "aarch64-darwin"
      "x86_64-darwin"
    ];
    forAllSystems = nixpkgs.lib.genAttrs systems; # This is a function that generates an attribute by calling a function you pass to it, with each system as an argument
  in {
    packages = forAllSystems (system: import ./pkgs nixpkgs.legacyPackages.${system}); # Your custom packages accessible through 'nix build', 'nix shell', etc
    formatter = forAllSystems (system: nixpkgs.legacyPackages.${system}.alejandra); # Formatter for your nix files, available through 'nix fmt'. Other options beside 'alejandra' include 'nixpkgs-fmt'
    # formatter.x86_64-linux = alejandra.defaultPackage.x86_64-linux;
    overlays = import ./overlays {inherit inputs;}; # Your custom packages and modifications, exported as overlays
    nixosModules = import ./modules/nixos; # Reusable nixos modules you might want to export. These are usually stuff you would upstream into nixpkgs
    homeManagerModules = import ./modules/home-manager; # Reusable home-manager modules you might want to export. These are usually stuff you would upstream into home-manager
    nixosConfigurations = {
      # NixOS configuration entrypoint. Available through 'nixos-rebuild --flake .#eris'
      eris = nixpkgs.lib.nixosSystem {
        specialArgs = {inherit inputs outputs;};
        modules = [
          nix-flatpak.nixosModules.nix-flatpak
          ./nixos/hosts/common.nix
          ./nixos/hosts/eris.nix
          chaotic.nixosModules.default
        ];
      };
      sedna = nixpkgs.lib.nixosSystem {
        specialArgs = {inherit inputs outputs;};
        modules = [
          nix-flatpak.nixosModules.nix-flatpak
          ./nixos/hosts/common.nix
          ./nixos/hosts/sedna.nix
          chaotic.nixosModules.default
        ];
      };
      thoughtful = nixpkgs.lib.nixosSystem {
        # sudo nixos-rebuild --flake .#thoughtful switch |& nom
        specialArgs = {inherit inputs outputs;};
        modules = [
          nix-flatpak.nixosModules.nix-flatpak
          ./nixos/hosts/common.nix
          ./nixos/hosts/thoughtful.nix
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.users.teq = import ./hosts/home-manager/teq/home.nix;
          }
          nixos-hardware.nixosModules.common-cpu-amd
          nixos-hardware.nixosModules.common-gpu-amd
          nixos-hardware.nixosModules.common-pc
          nixos-hardware.nixosModules.common-pc-ssd
          chaotic.nixosModules.default
        ];
      };
    };
    homeConfigurations = {
      # Standalone home-manager configuration entrypoint. Available through 'home-manager --flake .#teq'
      "teq" = home-manager.lib.homeManagerConfiguration {
        pkgs = nixpkgs.legacyPackages.x86_64-linux; # Home-manager requires 'pkgs' instance
        extraSpecialArgs = {inherit inputs outputs;};
        modules = [
          ./home-manager/teq/home.nix
        ];
      };
    };
  };
}
