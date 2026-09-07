{
  lib,
  config,
  pkgs,
  ...
}:
{
  config = lib.mkIf config.teq.nixos.gui.amd {
    environment.systemPackages = with pkgs; [
      clinfo
      radeontop
      vulkan-tools
    ];

    hardware.graphics.extraPackages = with pkgs; [
      rocmPackages.clr.icd
    ];

    systemd.tmpfiles.rules = [
      "L+    /opt/rocm/hip   -    -    -     -    ${pkgs.rocmPackages.clr}"
    ];
  };
}
