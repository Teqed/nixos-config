{
  lib,
  config,
  pkgs,
  ...
}: {
  imports = [
    ./amdvlk-348903-fix.nix
  ];
  config = lib.mkIf config.teq.nixos.gui.amd {
    hardware.graphics.extraPackages = with pkgs; [
      rocmPackages.clr.icd
      amdvlk # Modern AMD Graphics Core Next (GCN) GPUs are supported through either radv, which is part of mesa, or the amdvlk package. Adding the amdvlk package to hardware.opengl.extraPackages makes both drivers available for applications and lets them choose.
      rocm-opencl-icd # Modern AMD Graphics Core Next (GCN) GPUs are supported through the rocm-opencl-icd package.
      rocmPackages.rocm-runtime # OpenCL Image support is provided through the non-free rocm-runtime package.
    ];
    hardware.graphics.extraPackages32 = with pkgs; [
      driversi686Linux.amdvlk # The 32-bit AMDVLK drivers can be used in addition to the Mesa RADV drivers.
    ];
    chaotic.mesa-git.enable = true; # Use the Mesa graphics drivers from the Chaotic-AUR repository.
    chaotic.mesa-git.extraPackages = with pkgs; [
      mesa_git.opencl
      rocmPackages.clr.icd
      amdvlk
      rocm-opencl-icd
      rocmPackages.rocm-runtime
    ];
    chaotic.mesa-git.extraPackages32 = with pkgs.pkgsi686Linux; [
      pkgs.mesa32_git.opencl
      driversi686Linux.amdvlk
    ];
    chaotic.mesa-git.fallbackSpecialisation = false; # Whether to generate specialisation with stable Mesa.
    systemd.tmpfiles.rules = [
      "L+    /opt/rocm/hip   -    -    -     -    ${pkgs.rocmPackages.clr}" # Most software has the HIP libraries hard-coded.
    ];
  };
}
