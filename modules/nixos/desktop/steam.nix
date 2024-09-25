{
  config,
  pkgs,
  options,
  lib,
  ...
}: let
  cfg = config.teq.nixos.desktop.steam;
in {
  options.teq.nixos.desktop.steam = {
    enable = lib.mkEnableOption "Teq's NixOS Steam configuration defaults.";
  };
  config = lib.mkIf cfg.enable {
    programs.steam = {
      # enable = lib.mkDefault true; #11.8GB / 300MB (mostly mesa libraries)
      remotePlay.openFirewall = true;
      dedicatedServer.openFirewall = true;
      gamescopeSession.enable = true;
      extraCompatPackages = with pkgs; [
        proton-ge-bin # 1GB
        proton-ge-custom # 1GB
        luxtorpeda # 70MB
      ];
      extraPackages = with pkgs; [
        gamescope
        # gamescope-wsi_git
      ];
    };

    # programs.gamemode.enable = true;

    environment.systemPackages = with pkgs; [
      openvr_git
    ];
  };
}
