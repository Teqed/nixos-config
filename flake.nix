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
    # nix-flatpak.inputs.nixpkgs.follows = "nixpkgs"; #
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    # nixos-hardware.inputs.nixpkgs.follows = "nixpkgs"; #
    impermanence.url = "github:nix-community/impermanence?rev=63f4d0443e32b0dd7189001ee1894066765d18a5";
    # impermanence.inputs.nixpkgs.follows = "nixpkgs"; #
    nixpkgs-wayland.url = "github:nix-community/nixpkgs-wayland";
    nixpkgs-wayland.inputs.nixpkgs.follows = "nixpkgs"; #
    nixpkgs-unfree.url = "github:numtide/nixpkgs-unfree";
    nixpkgs-unfree.inputs.nixpkgs.follows = "nixpkgs";
    nix-index-database.url = "github:nix-community/nix-index-database";
    nix-index-database.inputs.nixpkgs.follows = "nixpkgs";
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
    nixpkgs-unfree,
    nix-index-database,
    ...
  } @ inputs: let
    inherit (self) outputs;
    systems = [
      "aarch64-linux"
      "i686-linux"
      "x86_64-linux"
      "aarch64-darwin"
      "x86_64-darwin"
    ];
    userinfo.users = ["teq"];
    forAllSystems = nixpkgs.lib.genAttrs systems; # This is a function that generates an attribute by calling a function you pass to it, with each system as an argument
  in {
    packages = forAllSystems (system: import ./pkgs nixpkgs.legacyPackages.${system}); # Your custom packages accessible through 'nix build', 'nix shell', etc
    formatter = forAllSystems (system: nixpkgs.legacyPackages.${system}.alejandra); # Formatter for your nix files, available through 'nix fmt'. Other options beside 'alejandra' include 'nixpkgs-fmt'
    # formatter.x86_64-linux = alejandra.defaultPackage.x86_64-linux;
    overlays = import ./overlays {inherit inputs;}; # Your custom packages and modifications, exported as overlays
    nixosModules = import ./modules/nixos; # Reusable nixos modules you might want to export. These are usually stuff you would upstream into nixpkgs
    homeManagerModules = import ./modules/home-manager; # Reusable home-manager modules you might want to export. These are usually stuff you would upstream into home-manager
    commonModules = import ./modules/nixpkgs.nix; # Reusable modules that are not specific to nixos or home-manager
    nixosConfigurations = {
      # NixOS configuration entrypoint. Available through 'nixos-rebuild --flake .#sedna'
      sedna = nixpkgs.lib.nixosSystem {
        specialArgs = {inherit inputs outputs userinfo;};
        modules = [
          ./nixos/sedna.nix
          self.commonModules
          self.nixosModules
          chaotic.nixosModules.default
          home-manager.nixosModules.home-manager
        ];
        home-manager.sharedModules = [
          self.homeManagerModules
          {teq.home-manager.all = true;} # Enable all of Teq's Home-Manager configuration defaults.
          nix-index-database.hmModules.nix-index
        ];
      };
      # sudo nixos-rebuild --flake .#thoughtful switch |& nom
      thoughtful = nixpkgs.lib.nixosSystem {
        specialArgs = {inherit inputs outputs userinfo;};
        modules = [
          ./nixos/thoughtful.nix
          self.commonModules
          self.nixosModules
          chaotic.nixosModules.default
          home-manager.nixosModules.home-manager
        ];
        home-manager.sharedModules = [
          self.homeManagerModules
          {teq.home-manager.all = true;} # Enable all of Teq's Home-Manager configuration defaults.
          nix-index-database.hmModules.nix-index
        ];
      };
    };
    homeConfigurations = {
      # Standalone home-manager configuration entrypoint. Available through 'home-manager --flake .#teq@somewhere'
      "teq@somewhere" = home-manager.lib.homeManagerConfiguration {
        pkgs = nixpkgs.legacyPackages.x86_64-linux; # Home-manager requires 'pkgs' instance
        extraSpecialArgs = {inherit inputs outputs;};
        modules = [
          self.commonModules
          self.homeManagerModules
          {
            teq.home-manager.all = true; # Enable Teq's Nixpkgs configuration defaults.
            teq.nixpkgs = true;
          }
          nix-index-database.hmModules.nix-index
        ];
      };
    };
  };
}
