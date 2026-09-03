{
  lib,
  config,
  ...
}:
{
  config = lib.mkIf config.teq.home-manager.enable {
    programs = {
      # btop = {
      #   enable = lib.mkDefault true;
      #   # settings = { };
      #   # extraConfig = " ";
      #   # package = pkgs.btop.override {rocmSupport = true;};
      # };
    };
  };
}
