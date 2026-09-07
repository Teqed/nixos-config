{
  config,
  options,
  lib,
  ...
}:
let
  cfg = config.teq.nixos.tailscale;
  authSecret = ../../../secrets/tailscale-auth.age;
  hasAuth = (options ? age) && builtins.pathExists authSecret;
in
{
  options.teq.nixos.tailscale = {
    loginServer = lib.mkOption {
      type = lib.types.str;
      default = "https://headscale.shatteredsky.net";
      description = "Headscale control server every host enrolls with.";
    };
  };

  config = lib.mkIf config.teq.nixos.enable (
    lib.mkMerge [
      {
        services.tailscale.extraUpFlags = [ "--login-server=${cfg.loginServer}" ];
      }
      (lib.optionalAttrs hasAuth {
        age.secrets.tailscale-auth = {
          file = authSecret;
          mode = "0400";
        };
        services.tailscale.authKeyFile = config.age.secrets.tailscale-auth.path;
      })
    ]
  );
}
