{
  buildGoModule,
  src,
}:
buildGoModule {
  pname = "atlogin";
  version = "0-unstable-2026-04-02";
  inherit src;
  vendorHash = "sha256-bmoNRyzxIKZmz7hzDKhMSulYZ67PmqpnDzYxtTQhI0o=";
  subPackages = [ "cmd/atlogin" ];
  env.CGO_ENABLED = 0;
  meta.mainProgram = "atlogin";
}
