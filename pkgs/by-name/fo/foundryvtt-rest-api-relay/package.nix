{
  lib,
  buildGoModule,
  fetchFromGitHub,
}:
buildGoModule (finalAttrs: {
  pname = "foundryvtt-rest-api-relay";
  version = "3.4.1";
  src = fetchFromGitHub {
    owner = "ThreeHats";
    repo = "foundryvtt-rest-api-relay";
    tag = finalAttrs.version;
    hash = "sha256-PWawR1iE9Q+EUOTbyC5HbcrcgcvqaPds7aOx8ANfABQ=";
  };
  patches = [ ./route-prefix.patch ];
  modRoot = "go-relay";
  vendorHash = "sha256-3rKrfpek+VkTV+WAk1gSKYc/mJeBwIxSKXl1FRb/Ikw=";
  subPackages = [ "cmd/server" ];
  env.CGO_ENABLED = 0;
  ldflags = [
    "-s"
    "-w"
  ];
  postInstall = ''
    mv $out/bin/server $out/bin/foundryvtt-rest-api-relay
  '';
  meta = {
    description = "WebSocket relay exposing a REST API for Foundry VTT worlds";
    homepage = "https://github.com/ThreeHats/foundryvtt-rest-api-relay";
    license = lib.licenses.mit;
    mainProgram = "foundryvtt-rest-api-relay";
  };
})
