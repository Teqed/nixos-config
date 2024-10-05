{
  config,
  pkgs,
  lib,
  ...
}: let
  cfg = config.teq.nixos.desktop;
  chromium_policy = ../../home-manager/sources/.config/chromium/policies/managed/defaultExtensions.json;
  brave_policy = ../../home-manager/sources/.config/brave/policies/managed/DisableBraveRewardsWalletAI.json;
in {
  options.teq.nixos.desktop = {
    programs = lib.mkEnableOption "Teq's NixOS Desktop Program configuration defaults.";
  };
  config = lib.mkIf cfg.programs {
    programs = {
      appimage = {
        enable = lib.mkDefault true;
        binfmt = lib.mkDefault true; # NixOS-specific option
        package = pkgs.appimage-run.override {
          extraPkgs = pkgs: [pkgs.ffmpeg pkgs.imagemagick];
        };
      };
      fuse = {
        userAllowOther = lib.mkDefault true; # Allow non-root users to specify the allow_other or allow_root mount options, see mount.fuse3(8). Might not be needed
        mountMax = lib.mkDefault 32000; # Set the maximum number of FUSE mounts allowed to non-root users. Integer between 0 and 32767, default 1000
      };
      virt-manager.enable = lib.mkDefault true;
    };

    environment.systemPackages = with pkgs; [
      solaar # 600MB / 30MB (gtk+3 600MB)
      papirus-icon-theme # Allows icons to be used in the system, like the login screen
      (pkgs.writeShellScriptBin "qemu-system-x86_64-uefi" ''
        qemu-system-x86_64 \
          -bios ${pkgs.OVMF.fd}/FV/OVMF.fd \
          "$@"
      '') # QEMU virtualization with UEFI firmware
    ];

    virtualisation.waydroid.enable = true;
    # boot.binfmt.emulatedSystems = [
    #   "aarch64-linux" # ARM
    #   "riscv64-linux" # RISC-V
    #   "x86_64-windows" # Windows
    #   "x86_64-linux" # Linux
    # ];

    environment.sessionVariables.NIXOS_OZONE_WL = "1"; # Use the Ozone Wayland support in several Electron apps

    environment.etc."vivaldi/policies/managed/defaultExtensions.json".source = chromium_policy;
    environment.etc."chromium/policies/managed/defaultExtensions.json".source = chromium_policy;
    environment.etc."brave/policies/managed/DisableBraveRewardsWalletAI.json".source = brave_policy;
  };
}
