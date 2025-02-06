{
  pkgs,
  lib,
  config,
  ...
}: let
  inherit (lib) mkDefault;
in {
  options.teq.nixos = {
    cachyos = lib.mkEnableOption "Enable CachyOS kernel.";
  };
  config = lib.mkIf config.teq.nixos.enable {
    systemd.services.systemd-udev-settle.enable = mkDefault false; # don't wait for udev to settle on boot
    systemd.services.NetworkManager-wait-online.enable = mkDefault false; # don't wait for network to be up on boot
    boot = {
      initrd = {
        systemd = {
          enable = mkDefault true;
        };
        # network = {
        #   flushBeforeStage2 = mkDefault true;
        #   enable = mkDefault true;
        #   ssh.enable = mkDefault false; # Optional SSH in the initrd
        #   ssh.ignoreEmptyHostKeys = mkDefault true;
        # };
        verbose = mkDefault false; # Remove extra NixOS logging from the initrd
      };
      plymouth = {
        enable = mkDefault true;
        theme = mkDefault "hud_3";
        themePackages = mkDefault [
          (pkgs.adi1090x-plymouth-themes.override {selected_themes = ["hud_3"];})
        ];
      };
      kernelParams = [
        "boot.shell_on_fail" # Drop to root shell on boot failure
        "quiet" # Silences boot messages
        "rd.systemd.show_status=false" # Silences successful systemd messages from the initrd
        "rd.udev.log_level=3" # Silence systemd version number in initrd
        "udev.log_priority=3" # Silence systemd version number
        "boot.shell_on_fail" # If booting fails drop us into a shell where we can investigate
        "splash" # Show a splash screen
        "bgrt_disable" # Don't display the OEM logo after loading the ACPI tables
        "plymouth.use-simpledrm" # Use simple DRM backend for Plymouth
      ];
      consoleLogLevel = mkDefault 3; # Silence dmesg
    };
    services.kmscon = {
      enable = mkDefault true; # Use kmscon as the virtual console instead of gettys.
      fonts = [
        {
          name = "Noto Sans Mono";
          package = pkgs.noto-fonts-lgc-plus;
        }
      ];
      extraOptions = mkDefault "--term xterm-256color";
      extraConfig = mkDefault "font-size=10";
      # hwRender = mkDefault true; # Whether to use 3D hardware acceleration to render the console.
    };
    nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
    boot.kernelPackages =
      if config.teq.nixos.cachyos
      then pkgs.linuxPackages_cachyos # Use the CachyOS kernel
      else pkgs.linuxPackages_latest; # Use the default kernel # linux-6.11 500MB
    boot.kernel.sysctl = {
      "vm.max_map_count" = 2147483642; # Required for some games
    };
    services.scx.enable = true; # by default uses scx_rustland scheduler
    services.scx.scheduler = "scx_lavd";
    services.irqbalance.enable = lib.mkDefault true;
    services.ananicy.enable = true;
    services.ananicy.rulesProvider = pkgs.ananicy-rules-cachyos;
  };
}
