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
        "emSign ECC Root CA - G3"
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
