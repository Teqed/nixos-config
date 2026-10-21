{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.teq.nixos.workarounds;
  upstreamPath =
    name: builtins.unsafeDiscardStringContext pkgs.${name}.passthru.workaroundUpstream.outPath;
  check =
    name: w:
    pkgs.writeShellScript "workaround-${name}" ''
      hash=$(${pkgs.coreutils}/bin/basename ${upstreamPath name} | ${pkgs.coreutils}/bin/cut -c1-32)
      code=$(${pkgs.curl}/bin/curl -s -o /dev/null -w '%{http_code}' --max-time 15 "${w.cache}/$hash.narinfo")
      case "$code" in
        200) echo "${name}: upstream builds again (${w.reason}); remove the workaround"; exit 1 ;;
        404) echo "${name}: upstream still broken, workaround in use"; exit 0 ;;
        *) echo "${name}: cache answered HTTP $code"; exit 3 ;;
      esac
    '';
in
{
  options.teq.nixos.workarounds = lib.mkOption {
    default = { };
    description = "Temporary package fixes. Each one overrides pkgs.<name> and adds a health check that warns once the unmodified upstream package is in the binary cache again.";
    type = lib.types.attrsOf (
      lib.types.submodule {
        options = {
          reason = lib.mkOption { type = lib.types.str; };
          fix = lib.mkOption {
            type = lib.types.functionTo lib.types.package;
            description = "Takes the upstream package and returns the fixed one.";
          };
          cache = lib.mkOption {
            type = lib.types.str;
            default = "https://cache.nixos.org";
          };
        };
      }
    );
  };

  config = lib.mkIf (cfg != { }) {
    nixpkgs.overlays = [
      (
        _: prev:
        lib.mapAttrs (
          name: w:
          (w.fix prev.${name}).overrideAttrs (old: {
            passthru = (old.passthru or { }) // {
              workaroundUpstream = prev.${name};
            };
          })
        ) cfg
      )
    ];
    teq.nixos.health.checks = lib.mapAttrs' (
      name: w: lib.nameValuePair "workaround.${name}" { command = [ "${check name w}" ]; }
    ) cfg;
  };
}
