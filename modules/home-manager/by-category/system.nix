{
  pkgs,
  lib,
  config,
  ...
}: let
  # XDG_CONFIG_HOME = "${config.xdg.configHome}";
in {
  config = lib.mkIf config.teq.home-manager.enable {
    home.packages = with pkgs; [
      clinfo # For confirming OpenCL support
      radeontop # For monitoring AMD GPU usage
    ];
    btop = {
      enable = lib.mkDefault true;
      # settings = { };
      # extraConfig = " ";
      package = pkgs.btop.override {rocmSupport = true;};
    };
  };
}