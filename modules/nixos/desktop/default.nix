{
  lib,
  config,
  pkgs,
  # nixpkgs-wayland,
  ...
}: let
  cfg = config.teq.nixos.desktop;
in {
  options.teq.nixos.desktop = {
    enable = lib.mkEnableOption "Teq's NixOS Desktop configuration defaults.";
  };
  imports = [
    ./steam.nix
    ./pipewire.nix
  ];
  config = lib.mkIf cfg.enable {
    teq.nixos.desktop.audio.enable = lib.mkDefault true; # Enable audio defaults.
    teq.nixos.desktop.steam.enable = lib.mkDefault true; # Enable Steam defaults.
    services = {
      xserver = {
        enable = true; # You can disable the X11 windowing system if you're only using the Wayland session.
        xkb = {
          # Configure keymap in X11
          layout = "us";
          variant = "";
        };
        # libinput.enable = true; # Enable touchpad support (enabled default in most desktopManager).
      };
      # Enable the KDE Plasma Desktop Environment.
      displayManager.sddm.enable = true;
      displayManager.sddm.theme = "${pkgs.sddm-sugar-candy}"; # <-- it's string interpolation
      displayManager.sddm.extraPackages = with pkgs; [
        libsForQt5.qt5.qtgraphicaleffects # <-- if suddenly sugar-candy does not find dependencies
      ];
      desktopManager.plasma6.enable = true;
    };
    # nixpkgs.overlays = [nixpkgs-wayland.overlay]; # Automated, pre-built, (potentially) pre-release packages for Wayland (sway/wlroots) tools for NixOS.
    hardware.graphics.enable32Bit = true; # On 64-bit systems, whether to support Direct Rendering for 32-bit applications (such as Wine). This is currently only supported for the nvidia and ati_unfree drivers, as well as Mesa.
    hardware.graphics.extraPackages = with pkgs; [
      rocmPackages.clr.icd
      amdvlk # Modern AMD Graphics Core Next (GCN) GPUs are supported through either radv, which is part of mesa, or the amdvlk package. Adding the amdvlk package to hardware.opengl.extraPackages makes both drivers available for applications and lets them choose.
      rocm-opencl-icd # Modern AMD Graphics Core Next (GCN) GPUs are supported through the rocm-opencl-icd package.
      rocmPackages.rocm-runtime # OpenCL Image support is provided through the non-free rocm-runtime package.
    ];
    hardware.graphics.extraPackages32 = with pkgs; [
      driversi686Linux.amdvlk # The 32-bit AMDVLK drivers can be used in addition to the Mesa RADV drivers.
    ];
    hardware.enableRedistributableFirmware = true; # Whether to enable firmware with a license allowing redistribution.
    hardware.enableAllFirmware = true; # Whether to enable all firmware regardless of license.
    chaotic.mesa-git.enable = true; # Use the Mesa graphics drivers from the Chaotic-AUR repository.
    systemd.tmpfiles.rules = [
      "L+    /opt/rocm/hip   -    -    -     -    ${pkgs.rocmPackages.clr}" # Most software has the HIP libraries hard-coded.
    ];
  };
}
