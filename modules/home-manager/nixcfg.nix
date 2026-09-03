{
  # inputs,
  lib,
  config,
  pkgs,
  osConfig ? null,
  ...
}:
with lib;
let
  # flakeInputs = filterAttrs (_: isType "flake") inputs;
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
      stateVersion = "24.05"; # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
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
    # nixpkgs config disabled when using home-manager.useGlobalPkgs
    nix = {
      package = mkDefault pkgs.nix; # Required in standalone home-manager
      # osConfig is null in standalone home-manager; mkDefault avoids ISO conflict
      registry = lib.mkIf (osConfig != null) (mkDefault osConfig.nix.registry);
      nixPath = lib.mkIf (osConfig != null) osConfig.nix.nixPath;

      # channel.enable = false; # Opinionated: disable channels # Only available in NixOS
      gc = {
        automatic = mkDefault true;
        persistent = mkDefault true;
        # dates = mkDefault "weekly"; # Not present in home-manager
        options = mkDefault "--delete-older-than 1w";
      };
      # Free up to 1GiB whenever there is less than 100MiB left.
      extraOptions = mkDefault ''
        min-free = ${toString (100 * 1024 * 1024)}
        max-free = ${toString (1024 * 1024 * 1024)}
      '';
      settings = {
        # nix-path = mkForce "nixpkgs=/etc/nix/inputs/nixpkgs";
        nix-path = mkDefault config.nix.nixPath; # Workaround for https://github.com/NixOS/nix/issues/9574
        bash-prompt-prefix = mkDefault "(nix:$name)\040";
        experimental-features = mkDefault [
          "nix-command"
          "flakes"
          "auto-allocate-uids" # Paired with auto-allocate-uids = true below
        ];
        accept-flake-config = mkDefault true; # Whether to accept nix configuration from a flake without prompting.
        allow-dirty = mkDefault true; # Whether to allow dirty Git/Mercurial trees.
        allow-symlinked-store = mkDefault true; # Nix will stop complaining if the store directory (typically /nix/store) contains symlink components.
        # hashedMirrors = mkDefault ["https://tarballs.nixos.org"];
        auto-allocate-uids = mkDefault true; # Whether to select UIDs for builds automatically, instead of using the users in build-users-group.
        use-xdg-base-directories = mkDefault true; # Nix will conform to the XDG Base Directory Specification for files in $HOME.
        system-features = mkDefault [
          "kvm" # use default instead?
          "big-parallel"
          "nixos-test"
          "benchmark"
        ];
        max-jobs = mkDefault "auto"; # default
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
