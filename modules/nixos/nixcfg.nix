{
  inputs,
  lib,
  config,
  options,
  outputs,
  pkgs,
  ...
}:
with lib;
let
  flakeInputs = filterAttrs (_: isType "flake") (removeAttrs inputs [ "self" ]);
  caches = import ../shared-caches.nix;
  cacheUrls = map (u: lib.head (lib.splitString "?" u)) (
    lib.filter (u: lib.hasInfix "binarycache" u) caches.substituters
  );
  cacheHost = u: lib.head (lib.splitString "/" (lib.last (lib.splitString "://" u)));
  firstLabel = h: lib.head (lib.splitString "." h);
  labelsUnique = lib.allUnique (map (u: firstLabel (cacheHost u)) cacheUrls);
  cacheEndpointName =
    u:
    "cache-"
    + (
      if labelsUnique then
        firstLabel (cacheHost u)
      else
        lib.replaceStrings [ "." ":" ] [ "-" "-" ] (cacheHost u)
    );
  defaultLang = "en_US.UTF-8";
  inherit (lib) mkDefault;
in
{
  options.teq.nixos = {
    enable = lib.mkEnableOption "Teq's NixOS configuration defaults.";
    gui = {
      enable = lib.mkEnableOption "Teq's NixOS GUI configuration defaults.";
      amd = lib.mkEnableOption "Teq's NixOS AMD configuration defaults.";
      steam = lib.mkEnableOption "Teq's NixOS Steam configuration defaults.";
    };
    blocklist = lib.mkEnableOption "Enable host blocklist defaults.";
    samba = lib.mkEnableOption "Enable Samba/SMB interop (server, WS-Discovery, NetBIOS name resolution).";
  };
  config = lib.mkIf config.teq.nixos.enable (
    {
      assertions = [
        {
          assertion = lib.allUnique (map cacheEndpointName cacheUrls);
          message = "Binary cache endpoints in shared-caches.nix produce duplicate health check names: ${lib.concatStringsSep " " (map cacheEndpointName cacheUrls)}";
        }
      ];
      teq.nixos.health = {
        jobs.nix-gc = lib.mkIf config.nix.gc.automatic { maxSuccessAge = 192 * 3600; };
        jobs.nixos-upgrade = lib.mkIf config.system.autoUpgrade.enable { };
        checks."github.token".command = [
          "${pkgs.python3}/bin/python3"
          "${../../pkgs/health/check-github.py}"
          "${pkgs.nix}/bin/nix"
        ];
        endpoints = builtins.listToAttrs (
          map (url: {
            name = cacheEndpointName url;
            value = url + "/nix-cache-info";
          }) cacheUrls
        );
      };
      system.stateVersion = lib.mkOverride 1100 "24.05";
      environment.enableAllTerminfo = mkDefault true;
      nixpkgs = {
        config = {
          allowUnfree = true;

          permittedInsecurePackages = [
            "pnpm-10.29.2"
          ];
        };

        overlays = [
          outputs.overlays.modifications
          outputs.overlays.llm-agents
          outputs.overlays.prime-agent-tweaks
        ];
      };
      nix = {
        registry = mapAttrs (_: flake: { inherit flake; }) flakeInputs;
        nixPath = mkDefault (mapAttrsToList (key: value: "${key}=${value.to.path}") config.nix.registry);

        gc = {
          automatic = mkDefault true;
          persistent = mkDefault true;
          dates = mkDefault "weekly";
          options = mkDefault "--delete-older-than 7d";
        };

        optimise = {
          automatic = mkDefault true;
          dates = mkDefault [ "weekly" ];
        };

        extraOptions = mkDefault (
          ''
            min-free = ${toString (100 * 1024 * 1024)}
            max-free = ${toString (1024 * 1024 * 1024)}
          ''
          + lib.optionalString (options ? age) ''
            !include ${config.age.secrets."gh".path}
          ''
        );
        settings = {
          nix-path = mkDefault config.nix.nixPath;
          bash-prompt-prefix = mkDefault "(nix:$name)\040";
          experimental-features = mkDefault [
            "nix-command"
            "flakes"
            "auto-allocate-uids"
          ];
          accept-flake-config = mkDefault true;
          allow-dirty = mkDefault true;
          allow-symlinked-store = mkDefault true;

          auto-allocate-uids = mkDefault true;
          use-xdg-base-directories = mkDefault true;
          system-features = mkDefault [
            "kvm"
            "big-parallel"
            "nixos-test"
            "benchmark"
          ];
          max-jobs = mkDefault "auto";
          builders-use-substitutes = mkDefault true;
          inherit (caches) substituters;
          trusted-substituters = caches.substituters;
          trusted-users = mkForce [
            "root"
            "teq"
            "@wheel"
          ];
          trusted-public-keys = caches.trustedPublicKeys;
        };
      };

      system.autoUpgrade = {
        enable = mkDefault ((inputs.self.rev or "dirty") != "dirty");
        flake = mkDefault "git+https://tangled.org/@quilling.dev/nixos-config";
        flags = mkDefault [
          "-L"
          "--refresh"
        ];
        randomizedDelaySec = mkDefault "30min";
        dates = mkDefault "04:00";
        allowReboot = mkDefault false;
      };

      systemd.services.nixos-upgrade = lib.mkIf config.system.autoUpgrade.enable {
        onFailure = lib.optional config.teq.nixos.notify.failureTemplate.enable "notify-fail@%n.service";
        startLimitIntervalSec = 3600;
        startLimitBurst = 6;
        serviceConfig = {
          Restart = "on-failure";
          RestartSec = "60";
          CPUSchedulingPolicy = "idle";
          IOSchedulingClass = "idle";
        };
      };

      time = {
        timeZone = mkDefault "America/New_York";
      };
      i18n = {
        defaultLocale = mkDefault "${defaultLang}";
        supportedLocales = mkDefault [
          "${defaultLang}/UTF-8"
          "C.UTF-8/UTF-8"
        ];
        extraLocaleSettings = {
          LC_ADDRESS = mkDefault "${defaultLang}";
          LC_IDENTIFICATION = mkDefault "${defaultLang}";
          LC_MEASUREMENT = mkDefault "${defaultLang}";
          LC_MONETARY = mkDefault "${defaultLang}";
          LC_NAME = mkDefault "${defaultLang}";
          LC_NUMERIC = mkDefault "${defaultLang}";
          LC_PAPER = mkDefault "${defaultLang}";
          LC_TELEPHONE = mkDefault "${defaultLang}";
          LC_TIME = mkDefault "${defaultLang}";
        };
      };
    }

    // lib.optionalAttrs (options ? age) {
      age.secrets."gh" = {
        file = ../../secrets/gh.age;
        mode = "0440";
        group = "wheel";
      };
    }
  );
}
