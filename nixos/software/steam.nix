{pkgs, ...}: {
  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = true;
    gamescopeSession.enable = true;
    extraCompatPackages = with pkgs; [
      proton-ge-bin
      proton-ge-custom
      luxtorpeda
    ];
    extraPackages = with pkgs; [
      gamescope
      # gamescope-wsi_git
    ];
  };

  programs.gamemode.enable = true;

  environment.systemPackages = with pkgs; [
    openvr_git
  ];
}
