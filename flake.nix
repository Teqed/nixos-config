{
  description = "
We still remember, we who dwell
In this far land beneath the trees
The starlight on the Western Seas.
";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nix-cachyos-kernel.url = "github:xddxdd/nix-cachyos-kernel/release";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    nix-flatpak.url = "github:gmodena/nix-flatpak";

    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    nixos-hardware.inputs.nixpkgs.follows = "nixpkgs";
    impermanence.url = "github:nix-community/impermanence";
    impermanence.inputs.nixpkgs.follows = "nixpkgs";
    nix-index-database.url = "github:nix-community/nix-index-database";
    nix-index-database.inputs.nixpkgs.follows = "nixpkgs";
    plasma-manager = {
      url = "github:nix-community/plasma-manager";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };

    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";
    foundryvtt = {
      url = "github:reckenrode/nix-foundryvtt";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    ghostty = {
      url = "github:ghostty-org/ghostty?ref=refs/tags/tip";
    };

    llm-agents.url = "github:numtide/llm-agents.nix";
    vpn-confinement.url = "github:Maroka-chan/VPN-Confinement";
    agenix = {
      url = "github:ryantm/agenix";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        home-manager.follows = "home-manager";
        darwin.follows = "";
      };
    };
    tangled-core.url = "git+https://tangled.org/@tangled.org/core";
    tangled-core.inputs.nixpkgs.follows = "nixpkgs";
    washing-machien = {
      url = "git+https://tangled.org/coil-habdle.ebil.club/washing-machien";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  outputs =
    {
      self,
      nixpkgs,
      home-manager,
      nix-cachyos-kernel,
      nix-flatpak,
      nixos-hardware,
      impermanence,
      nix-index-database,
      plasma-manager,
      disko,
      vpn-confinement,
      agenix,
      tangled-core,
      ...
    }@inputs:
    let
      inherit (self) outputs;
      systems = [
        "aarch64-linux"
        "x86_64-linux"
      ];
      forAllSystems = nixpkgs.lib.genAttrs systems;
      pkgsFor = forAllSystems (
        system:
        import nixpkgs {
          inherit system;
          config.allowUnfree = true;
          overlays = [
            self.overlays.llm-agents
            self.overlays.prime-agent-tweaks
          ];
        }
      );
      inheritSpecialArgs = {
        inherit
          self
          inputs
          outputs
          nixos-hardware
          impermanence
          nix-flatpak
          ;
      };

    in
    {
      checks = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        {
          health = pkgs.runCommand "check-health" { nativeBuildInputs = [ pkgs.python3 ]; } ''
            python3 -B -m unittest discover -s ${./pkgs/health} -v
            touch $out
          '';
          mail-no-listener = pkgs.runCommand "check-mail-no-listener" { } ''
            setup=${pkgs.writeText "postfix-setup.sh" self.nixosConfigurations.thoughtful.config.systemd.services.postfix-setup.script}
            master=$(grep -oE '/nix/store/[^ ]*-postfix-master\.cf' "$setup" | head -1)
            [ -r "$master" ] || { echo "could not locate the generated master.cf" >&2; exit 1; }
            if grep -E '^[a-z0-9._:-]+[[:space:]]+inet' "$master"; then
              echo "hub postfix has a network listener" >&2; exit 1
            fi
            grep -q '^pickup' "$master" && grep -q '^local' "$master" && touch $out
          '';
          agent-proxy-mapping =
            let
              hub = self.nixosConfigurations.thoughtful.config;
              keys = hub.teq.nixos.agent.proxyKeys;
              accountOf =
                ph: builtins.head (nixpkgs.lib.splitString "+" (builtins.head (nixpkgs.lib.splitString "@" ph)));
              entryFor =
                ph: key:
                nixpkgs.lib.any (
                  k: nixpkgs.lib.hasInfix "agent-mail-proxy ${ph}\"" k && nixpkgs.lib.hasSuffix key k
                ) hub.users.users.${accountOf ph}.openssh.authorizedKeys.keys;
              wrongAccount =
                ph:
                nixpkgs.lib.any (
                  acct:
                  acct != accountOf ph
                  && nixpkgs.lib.any (k: nixpkgs.lib.hasInfix "agent-mail-proxy ${ph}\"" k) (
                    hub.users.users.${acct}.openssh.authorizedKeys.keys or [ ]
                  )
                ) (builtins.attrNames hub.users.users);
              problems = nixpkgs.lib.filterAttrs (ph: key: !(entryFor ph key) || wrongAccount ph) keys;
            in
            pkgs.runCommand "check-agent-proxy-mapping" { } ''
              ${
                if problems == { } then
                  "echo 'every proxy key is a forced command in exactly its principal account (${toString (builtins.length (builtins.attrNames keys))} keys)'"
                else
                  "echo 'proxy keys not mapped to their principal account: ${toString (builtins.attrNames problems)}' >&2; exit 1"
              }
              touch $out
            '';
          deploy-guard = pkgs.runCommand "check-deploy-guard" { nativeBuildInputs = [ pkgs.just ]; } ''
            script=$(just --justfile ${./justfile} --dry-run deploy example 2>&1)
            for needle in 'teq.nixos.cachePull' '.enable' '.buildServer' 'uname -n' 'exit 1'; do
              grep -qF "$needle" <<<"$script" || { echo "deploy recipe lost its execution-host guard ($needle)" >&2; exit 1; }
            done
            guard=$(grep -nF 'uname -n' <<<"$script" | head -1 | cut -d: -f1)
            build=$(grep -nF -- '--out-link' <<<"$script" | head -1 | cut -d: -f1)
            [ "$guard" -lt "$build" ] || { echo "deploy recipe builds before checking the execution host" >&2; exit 1; }
            touch $out
          '';
          fmt = pkgs.runCommand "check-fmt" { nativeBuildInputs = [ pkgs.nixfmt ]; } ''
            find ${self} -name '*.nix' -exec nixfmt --check {} + && touch $out
          '';
          statix = pkgs.runCommand "check-statix" { nativeBuildInputs = [ pkgs.statix ]; } ''
            statix check ${self} && touch $out
          '';
          deadnix = pkgs.runCommand "check-deadnix" { nativeBuildInputs = [ pkgs.deadnix ]; } ''
            deadnix --fail ${self} && touch $out
          '';
          shellcheck = pkgs.runCommand "check-shellcheck" { nativeBuildInputs = [ pkgs.shellcheck ]; } ''
            shellcheck --shell=bash ${self}/pkgs/scripts/src/*.sh && touch $out
          '';
        }
      );

      packages = forAllSystems (system: import ./pkgs pkgsFor.${system});

      formatter = forAllSystems (system: nixpkgs.legacyPackages.${system}.nixfmt-tree);

      overlays = import ./overlays { inherit inputs; };

      nixosModules = import ./modules/nixos { flakes = inputs; };

      nixosConfigurations = {
        eris = nixpkgs.lib.nixosSystem {
          specialArgs = inheritSpecialArgs;
          modules = [
            ./hosts/eris.nix
            self.nixosModules.default
            home-manager.nixosModules.home-manager
            nix-flatpak.nixosModules.nix-flatpak
            self.homeManagerConfig
            disko.nixosModules.disko
          ];
        };

        sedna = nixpkgs.lib.nixosSystem {
          specialArgs = inheritSpecialArgs;
          modules = [
            ./hosts/sedna.nix
            self.nixosModules.default
            home-manager.nixosModules.home-manager
            nix-flatpak.nixosModules.nix-flatpak
            self.homeManagerConfig
          ];
        };
        thoughtful = nixpkgs.lib.nixosSystem {
          specialArgs = inheritSpecialArgs;
          system = "x86_64-linux";
          modules = [
            ./hosts/thoughtful.nix
            self.nixosModules.default
            home-manager.nixosModules.home-manager
            nix-flatpak.nixosModules.nix-flatpak
            self.homeManagerConfig
            vpn-confinement.nixosModules.default
            agenix.nixosModules.default
            tangled-core.nixosModules.spindle
            inputs.washing-machien.nixosModules.default
            { nixpkgs.overlays = [ nix-cachyos-kernel.overlays.pinned ]; }
          ];
        };
        bubblegum = nixpkgs.lib.nixosSystem {
          specialArgs = inheritSpecialArgs;
          system = "x86_64-linux";
          modules = [
            ./hosts/bubblegum.nix
            self.nixosModules.default
            home-manager.nixosModules.home-manager
            nix-flatpak.nixosModules.nix-flatpak
            self.homeManagerConfig
            agenix.nixosModules.default
            { nixpkgs.overlays = [ nix-cachyos-kernel.overlays.pinned ]; }
          ];
        };
        jupiter = nixpkgs.lib.nixosSystem {
          specialArgs = inheritSpecialArgs;
          system = "aarch64-linux";
          modules = [
            ./hosts/jupiter.nix
            self.nixosModules.default
            agenix.nixosModules.default
            home-manager.nixosModules.home-manager
            nix-flatpak.nixosModules.nix-flatpak
            self.homeManagerConfig
            disko.nixosModules.disko
            inputs.foundryvtt.nixosModules.foundryvtt
          ];
        };
      };

      homeManagerModules = import ./modules/home-manager { flakes = inputs; };
      homeManagerConfig = _: {
        nixpkgs.hostPlatform = nixpkgs.lib.mkDefault "x86_64-linux";
        home-manager.extraSpecialArgs = inheritSpecialArgs;
        home-manager.sharedModules = [
          self.homeManagerModules.default
          nix-index-database.homeModules.nix-index
          plasma-manager.homeModules.plasma-manager
        ];
      };
      homeConfigurations = {
        "teq@somewhere" = home-manager.lib.homeManagerConfiguration {
          pkgs = pkgsFor.x86_64-linux;
          extraSpecialArgs = { inherit inputs outputs; };
          modules = [
            self.homeManagerModules.default
            nix-index-database.homeModules.nix-index
            plasma-manager.homeModules.plasma-manager
            {
              home.username = "teq";
              home.homeDirectory = "/home/teq";
              targets.genericLinux.enable = true;
              targets.genericLinux.gpu.enable = false;
              teq.home-manager = {
                enable = true;
              };
            }
          ];
        };
      };

      devShells = forAllSystems (system: {
        default = pkgsFor.${system}.mkShell {
          packages = with pkgsFor.${system}; [
            nixfmt
            nixd
            statix
            deadnix
            shellcheck
            bash-language-server
            just
            nix-output-monitor
            inputs.agenix.packages.${system}.default
          ];
        };
      });

      templates = {
        rust = {
          path = ./templates/rust;
          description = "Rust nightly devshell (rust-analyzer, wasm target, Bevy-ready libs) with direnv";
        };
        python = {
          path = ./templates/python;
          description = "Python devshell (uv, ruff, pylint) with direnv";
        };
        go = {
          path = ./templates/go;
          description = "Go devshell (gopls, golangci-lint, delve) with direnv";
        };
        ruby = {
          path = ./templates/ruby;
          description = "Ruby devshell (rubocop, solargraph) with direnv";
        };
      };
    };
}
