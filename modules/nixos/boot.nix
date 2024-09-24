{
  pkgs,
  lib,
  ...
}: let
  inherit (lib) mkDefault;
in {
  boot = {
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
    ];

    consoleLogLevel = mkDefault 3; # Silence dmesg
    initrd.verbose = mkDefault false; # Remove extra NixOS logging from the initrd
  };
}
