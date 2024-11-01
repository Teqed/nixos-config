{
  lib,
  config,
  pkgs,
  ...
}: let 
  my_amdvlk = pkgs.amdvlk.override {
    glslang = pkgs.glslang.overrideAttrs (finalAttrs: oldAttrs: {
      version = "15.0.0";
      src = pkgs.fetchFromGitHub {
        owner = "KhronosGroup";
        repo = "glslang";
        rev = "refs/tags/${finalAttrs.version}";
        hash = "sha256-QXNecJ6SDeWpRjzHRTdPJHob1H3q2HZmWuL2zBt2Tlw=";
      };
    # Effectively revert the change seen here:
    # https://github.com/NixOS/nixpkgs/commit/c3948c21ef00fbf8ef02f3c2922e84ba72e8a62b#diff-21ee06ef20d156bedb03da22e28850e6043b04a00706a796e7e427fce44500e9R31
    cmakeFlags = [];
    });
  };
  my_i686_amdvlk = pkgs.driversi686Linux.amdvlk.override {
    glslang = pkgs.glslang.overrideAttrs (finalAttrs: oldAttrs: {
      version = "15.0.0";
      src = pkgs.fetchFromGitHub {
        owner = "KhronosGroup";
        repo = "glslang";
        rev = "refs/tags/${finalAttrs.version}";
        hash = "sha256-QXNecJ6SDeWpRjzHRTdPJHob1H3q2HZmWuL2zBt2Tlw=";
      };
    cmakeFlags = [];
    });
  };
 in {
  config = lib.mkIf config.teq.nixos.gui.amd {
    hardware.graphics.extraPackages = with pkgs; [
      rocmPackages.clr.icd
      my_amdvlk # Modern AMD Graphics Core Next (GCN) GPUs are supported through either radv, which is part of mesa, or the amdvlk package. Adding the amdvlk package to hardware.opengl.extraPackages makes both drivers available for applications and lets them choose.
      rocm-opencl-icd # Modern AMD Graphics Core Next (GCN) GPUs are supported through the rocm-opencl-icd package.
      rocmPackages.rocm-runtime # OpenCL Image support is provided through the non-free rocm-runtime package.
    ];
    hardware.graphics.extraPackages32 = with pkgs; [
      my_i686_amdvlk # The 32-bit AMDVLK drivers can be used in addition to the Mesa RADV drivers.
    ];
    chaotic.mesa-git.enable = true; # Use the Mesa graphics drivers from the Chaotic-AUR repository.
    chaotic.mesa-git.extraPackages = with pkgs; [
      mesa_git.opencl
      rocmPackages.clr.icd
      my_amdvlk
      rocm-opencl-icd
      rocmPackages.rocm-runtime
    ];
    chaotic.mesa-git.extraPackages32 = with pkgs.pkgsi686Linux; [
      pkgs.mesa32_git.opencl
      my_i686_amdvlk
    ];
    chaotic.mesa-git.fallbackSpecialisation = false; # Whether to generate specialisation with stable Mesa.
    systemd.tmpfiles.rules = [
      "L+    /opt/rocm/hip   -    -    -     -    ${pkgs.rocmPackages.clr}" # Most software has the HIP libraries hard-coded.
    ];
  };
}
