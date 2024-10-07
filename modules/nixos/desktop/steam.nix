{
  config,
  pkgs,
  lib,
  ...
}: let
  cfg = config.teq.nixos.desktop;
  wine_wayland = pkgs.wineWowPackages.waylandFull;
in {
  options.teq.nixos.desktop = {
    steam = lib.mkEnableOption "Teq's NixOS Steam configuration defaults.";
  };
  config = lib.mkIf cfg.steam {
    programs.steam = {
      enable = lib.mkDefault true; #11.8GB / 300MB (mostly mesa libraries)
      remotePlay.openFirewall = true;
      dedicatedServer.openFirewall = true;
      gamescopeSession.enable = true;
      protontricks.enable = true;
      extraCompatPackages = with pkgs; [
        proton-ge-bin # 1GB
        proton-ge-custom # 1GB
        luxtorpeda # 70MB
      ];
      extraPackages = with pkgs; [
        gamescope
        # gamescope-wsi32_git	
        # gamescope-wsi_git
        # gamescope_git
      ];
    };

    # programs.gamemode.enable = true;

    environment.systemPackages = [
      pkgs.openvr_git
      pkgs.winetricks
      pkgs.wineasio
      wine_wayland
    ];
    boot.binfmt.registrations.wine = {
      recognitionType = "magic";
      magicOrExtension = "MZ";
      interpreter = lib.getExe wine_wayland;
    };
    boot.kernel.sysctl = {
      # Enable usage of performance data from Intel GPUs by non-admin programs, enabled for Wine
      # <https://wiki.archlinux.org/title/Intel_graphics#Enable_performance_support>
      "dev.i915.perf_stream_paranoid" = 0;
    };
  };
}
