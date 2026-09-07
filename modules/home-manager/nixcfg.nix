{
  lib,
  config,
  pkgs,
  osConfig ? null,
  ...
}:
with lib;
let

  caches = import ../shared-caches.nix;
  defaultLang = "en_US.UTF-8";
  inherit (lib) mkDefault;
in
{
  options.teq.home-manager = {
    enable = lib.mkEnableOption "Enable Teq's Home-Manager configuration defaults.";
    gui = lib.mkEnableOption "Enable GUI configuration.";
    dev = lib.mkEnableOption "Enable development toolchains and dev-adjacent tools.";
    tts = lib.mkEnableOption "Enable speech synthesis (speech-dispatcher).";
  };
  config = lib.mkIf config.teq.home-manager.enable {
    home = {
      stateVersion = "24.05";
      extraOutputsToInstall = [
        "info"
        "man"
        "share"
        "icons"
        "doc"
      ];
      keyboard.layout = mkDefault "us";
      language = {
        base = mkDefault "${defaultLang}";
        ctype = mkDefault "${defaultLang}";
        numeric = mkDefault "${defaultLang}";
        time = mkDefault "${defaultLang}";
        collate = mkDefault "${defaultLang}";
        monetary = mkDefault "${defaultLang}";
        messages = mkDefault "${defaultLang}";
        paper = mkDefault "${defaultLang}";
        name = mkDefault "${defaultLang}";
        address = mkDefault "${defaultLang}";
        telephone = mkDefault "${defaultLang}";
        measurement = mkDefault "${defaultLang}";
      };
    };

    nix = {
      package = mkDefault pkgs.nix;

      registry = lib.mkIf (osConfig != null) (mkDefault osConfig.nix.registry);
      nixPath = lib.mkIf (osConfig != null) osConfig.nix.nixPath;

      gc = {
        automatic = mkDefault true;
        persistent = mkDefault true;

        options = mkDefault "--delete-older-than 7d";
      };

      extraOptions = mkDefault ''
        min-free = ${toString (100 * 1024 * 1024)}
        max-free = ${toString (1024 * 1024 * 1024)}
      '';
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
        substituters = mkDefault caches.substituters;
        trusted-substituters = mkDefault caches.substituters;
        trusted-users = mkForce [
          "root"
          "teq"
          "@wheel"
        ];
        trusted-public-keys = mkDefault caches.trustedPublicKeys;
      };
    };
  };
}
