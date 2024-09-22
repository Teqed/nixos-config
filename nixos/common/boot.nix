{pkgs, ...}: {
  boot = {
    plymouth = {
      enable = true;
      theme = "hud_3";
      themePackages = [pkgs.adi1090x-plymouth-themes.override {selected_themes = ["hud_3"];}];
    };
    kernelParams = [
      "boot.shell_on_fail" # Drop to root shell on boot failure
      "quiet" # Silences boot messages
      "rd.systemd.show_status=false" # Silences successfull systemd messages from the initrd
      "rd.udev.log_level=3" # Silence systemd version number in initrd
      "udev.log_priority=3" # Silence systemd version number
      "boot.shell_on_fail" # If booting fails drop us into a shell where we can investigate
      "splash" # Show a splash screen
      "bgrt_disable" # Don't display the OEM logo after loading the ACPI tables
    ];
    consoleLogLevel = 3; # Silence dmesg
    initrd.verbose = false; # Remove extra NixOS logging from the initrd
  };
}
