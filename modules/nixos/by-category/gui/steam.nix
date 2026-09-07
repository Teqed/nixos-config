{
  config,
  pkgs,
  lib,
  ...
}:
let
  wine_package = pkgs.wineWow64Packages.staging;
in
{
  config = lib.mkIf config.teq.nixos.gui.steam {
    programs.steam = {
      enable = lib.mkDefault true;
      remotePlay.openFirewall = true;
      dedicatedServer.openFirewall = true;
      gamescopeSession.enable = true;
      protontricks.enable = true;

      extraCompatPackages = with pkgs; [
        proton-ge-bin
      ];
      extraPackages = with pkgs; [
        gamescope
      ];
    };

    environment.systemPackages = [
      pkgs.r2modman
      pkgs.openvr
      pkgs.winetricks
      pkgs.wineasio
      wine_package
    ];
    boot.binfmt.registrations.wine = {
      recognitionType = "magic";
      magicOrExtension = "MZ";
      interpreter = lib.getExe wine_package;
    };
    boot.kernel.sysctl = {
      "dev.i915.perf_stream_paranoid" = 0;
    };
  };
}
