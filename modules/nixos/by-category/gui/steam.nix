{
  config,
  pkgs,
  lib,
  ...
}: let
  wine_wayland = pkgs.wineWowPackages.waylandFull;
in {
  config = lib.mkIf config.teq.nixos.gui.steam {
    programs.steam = {
      enable = lib.mkDefault true; #11.8GB / 300MB (mostly mesa libraries)
      remotePlay.openFirewall = true;
      dedicatedServer.openFirewall = true;
      gamescopeSession.enable = true;
      protontricks.enable = true;
      # extest.enable = true; # For using Steam Input on Wayland
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
    # programs.gamescope = {
    #   enable = true;
    #   capSysNice = false;
    # };

    # programs.gamemode = {
    #   enable = true;
    #   enableRenice = true;
    #   settings = {
    #     general = {
    #       renice = 10;
    #     };
    #     gpu = {
    #       apply_gpu_optimisations = "accept-responsibility";
    #       amd_performance_level = "high";
    #     };
    #     cpu = {
    #       park_cores = "no";
    #       pin_cores = "yes";
    #     };
    #     custom = {
    #       start = "${pkgs.libnotify}/bin/notify-send 'GameMode Started'";
    #       end = "${pkgs.libnotify}/bin/notify-send 'GameMode Ended'";
    #     };
    #   };
    # };

    # programs.corectrl.enable = true;

    # hardware.cpu.amd.updateMicrocode = true;
    # hardware.graphics.enable = true;
    # hardware.graphics.enable32Bit = true;
    # hardware.steam-hardware.enable = true;
    # hardware.enableAllFirmware = true;
    # hardware.enableRedistributableFirmware = true; 

    # services.fwupd.enable = true;

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
