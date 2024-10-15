{
  pkgs,
  lib,
  config,
  ...
}: {
  config = lib.mkIf config.teq.nixos.enable {
    # services = {
    # };
    # programs = {
    # };
    # environment.systemPackages = with pkgs; [
    # ];
    security = {
      sudo = {
        enable = lib.mkDefault true; # TODO: Disable sudo in favor of doas
        package = pkgs.sudo.override {
          withInsults = true;
        };
        extraConfig = lib.mkDefault ''
          Defaults lecture = never
        '';
        doas = {
          enable = true;
          wheelNeedsPassword = false;
          extraRules = [
            {
              users = ["teq"]; # TODO: Add userinfo list variable
              keepEnv = true;
              persist = true;
            }
          ];
        };
      };
    };
  };
}
