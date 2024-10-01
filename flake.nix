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
    userinfo.users = ["teq"];
    forAllSystems = nixpkgs.lib.genAttrs systems; # This is a function that generates an attribute by calling a function you pass to it, with each system as an argument
    inheritSpecialArgs = {
      inherit
        inputs
        outputs
        userinfo
        nixos-hardware
        impermanence
        nix-flatpak
        nixpkgs-wayland
        ;
    };
  in {
    packages = forAllSystems (system: import ./pkgs nixpkgs.legacyPackages.${system}); # Custom packages accessible through 'nix build', 'nix shell', etc
    formatter = forAllSystems (system: nixpkgs.legacyPackages.${system}.alejandra); # Formatter for your nix files, available through 'nix fmt'.
    nixosModules = import ./modules/nixos; # Reusable nixos modules.
    homeManagerModules = import ./modules/home-manager; # Reusable home-manager modules.
    homeManagerConfig = {
      nixpkgs.hostPlatform = nixpkgs.lib.mkDefault "x86_64-linux";
      home-manager.extraSpecialArgs = inheritSpecialArgs;
      home-manager.sharedModules = [
        self.homeManagerModules
        nix-index-database.hmModules.nix-index
        plasma-manager.homeManagerModules.plasma-manager
        {teq.home-manager.enable = true;}
      ];
    };
    commonModules = import ./modules/nixpkgs.nix; # Reusable modules that are not specific to nixos or home-manager.
    nixosConfigurations = {
      # NixOS configuration entrypoint. Available through 'nixos-rebuild --flake .#sedna'
      sedna = nixpkgs.lib.nixosSystem {
        specialArgs = inheritSpecialArgs;
        modules = [
          ./hosts/sedna.nix
          self.commonModules
          self.nixosModules
          chaotic.nixosModules.default
          home-manager.nixosModules.home-manager
          self.homeManagerConfig
        ];
      };
      # sudo nixos-rebuild --flake .#thoughtful switch |& nom
      thoughtful = nixpkgs.lib.nixosSystem {
        specialArgs = inheritSpecialArgs;
        modules = [
          ./nixos/thoughtful.nix
          self.commonModules
          self.nixosModules
          chaotic.nixosModules.default
          home-manager.nixosModules.home-manager
          self.homeManagerConfig
        ];
      };
    };
    homeConfigurations = {
      # home-manager --flake .#teq@somewhere
      "teq@somewhere" = home-manager.lib.homeManagerConfiguration {
        pkgs = nixpkgs.legacyPackages.x86_64-linux; # Home-manager requires 'pkgs' instance
        extraSpecialArgs = {inherit inputs outputs;};
        modules = [
          self.commonModules
          self.homeManagerModules
          nix-index-database.hmModules.nix-index
          plasma-manager.homeManagerModules.plasma-manager
          {
            teq.home-manager.enable = true;
            teq.nixpkgs = true;
          }
        ];
      };
    };
  };
}
