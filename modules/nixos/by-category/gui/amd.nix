{
  lib,
  config,
  pkgs,
  ...
}: {
  config = lib.mkIf config.teq.nixos.gui.amd {
    environment.systemPackages = with pkgs; [
      clinfo # For confirming OpenCL support
      radeontop # For monitoring AMD GPU usage
    ];
    chaotic.mesa-git.enable = true; # Use the Mesa graphics drivers from the Chaotic-AUR repository.
    chaotic.mesa-git.extraPackages = with pkgs; [
      mesa_git.opencl
      rocmPackages.clr.icd
      amdvlk
      # rocm-opencl-icd
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
