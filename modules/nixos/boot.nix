{
  pkgs,
  lib,
  config,
  ...
}: let
  cfg = config.teq.nixos;
  inherit (lib) mkDefault;
in {
  options.teq.nixos = {
    boot = lib.mkEnableOption "Teq's NixOS Boot configuration defaults.";
  };
  config = lib.mkIf cfg.boot {
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

      kernelParams = mkDefault [
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
  };
}
