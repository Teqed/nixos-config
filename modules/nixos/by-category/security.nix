{
  lib,
  config,
  ...
}:
{
  config = lib.mkIf config.teq.nixos.enable {
    environment.variables = {
      NIX_SSL_CERT_FILE = "/etc/ssl/certs/ca-certificates.crt";
      NODE_OPTIONS = "--use-openssl-ca";
    };
    security = {
      pki.caCertificateBlacklist = [
        "Comodo AAA Services root"
      ];
      sudo.enable = false;
      sudo-rs = {
        enable = true;
        wheelNeedsPassword = true;
        execWheelOnly = true;
        extraConfig = ''
          Defaults timestamp_timeout=480
        '';
      };
    };
  };
}
