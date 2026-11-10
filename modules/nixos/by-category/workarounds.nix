{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
let
  cfg = config.teq.nixos.workarounds;
  sources = config.teq.nixos.workaroundSources;

  sourcePkgs = lib.mapAttrs (
    _: src:
    import src {
      inherit (pkgs.stdenv.hostPlatform) system;
      inherit (config.nixpkgs) config;
    }
  ) sources;

  recipePath =
    name: from:
    if from.path != null then
      from.path
    else
      "pkgs/by-name/${lib.toLower (lib.substring 0 2 name)}/${name}/package.nix";

  sourceOf =
    name: from:
    sources.${from.source}
      or (throw "teq.nixos.workarounds.${name}: unknown source ${from.source} (known: ${lib.concatStringsSep ", " (lib.attrNames sources)})");

  recipeFile =
    name: from:
    let
      file = "${sourceOf name from}/${recipePath name from}";
    in
    if builtins.pathExists file then
      file
    else
      throw "teq.nixos.workarounds.${name}: no ${recipePath name from} in source ${from.source}; set from.path";

  fromSource =
    final: name: from:
    if from.mode == "package" then
      lib.getAttrFromPath (lib.splitString "." (if from.attr != null then from.attr else name)) (
        sourcePkgs.${from.source} or (sourceOf name from)
      )
    else
      let
        result = final.callPackage (recipeFile name from) { };
      in
      if from.attr != null then result.${from.attr} else result;

  replacement =
    final: prev: name: w:
    (
      if (w.fix == null) == (w.from == null) then
        throw "teq.nixos.workarounds.${name}: set exactly one of fix and from"
      else if w.from != null then
        fromSource final name w.from
      else
        w.fix prev.${name}
    ).overrideAttrs
      (old: {
        passthru = (old.passthru or { }) // {
          workaroundUpstream = prev.${name};
        };
      });

  upstreamOf = name: pkgs.${name}.passthru.workaroundUpstream;

  retireCheck =
    name: w:
    let
      upstream = builtins.tryEval (builtins.unsafeDiscardStringContext (upstreamOf name).outPath);
      upstreamVersion = (upstreamOf name).version or "";
      current = pkgs.${name}.version or "";
    in
    if !upstream.success then
      ''
        echo "upstream does not evaluate; still needed"
      ''
    else if w.retire == "evaluates" then
      ''
        echo "upstream evaluates again; remove it (${w.reason})"
        exit 1
      ''
    else if w.retire == "version" then
      if lib.versionAtLeast upstreamVersion current then
        ''
          echo "upstream ${upstreamVersion} >= ${current}; remove it (${w.reason})"
          exit 1
        ''
      else
        ''
          echo "upstream ${upstreamVersion} < ${current}; still needed"
        ''
    else
      ''
        hash=$(${pkgs.coreutils}/bin/basename ${upstream.value} | ${pkgs.coreutils}/bin/cut -c1-32)
        code=$(${pkgs.curl}/bin/curl -s -o /dev/null -w '%{http_code}' --max-time 15 "${w.cache}/$hash.narinfo")
        case "$code" in
          200) echo "upstream is cached again; remove it (${w.reason})"; exit 1 ;;
          404) echo "upstream not cached; still needed"; exit 0 ;;
          *) echo "${w.cache} answered HTTP $code"; exit 3 ;;
        esac
      '';

  check =
    name: w:
    pkgs.writeShellScript "workaround-${name}" (
      lib.optionalString (w.expires != null) ''
        if [[ "$(${pkgs.coreutils}/bin/date +%F)" > "${w.expires}" ]]; then
          echo "review date ${w.expires} passed (${w.reason})"
          exit 1
        fi
      ''
      + retireCheck name w
    );

  fromSubmodule = lib.types.submodule {
    options = {
      source = lib.mkOption {
        type = lib.types.str;
        description = "Key in teq.nixos.workaroundSources.";
      };
      mode = lib.mkOption {
        type = lib.types.enum [
          "recipe"
          "package"
        ];
        default = "recipe";
        description = "recipe: callPackage the source's file with this system's pkgs, sharing its glibc and drivers. package: the source's own build.";
      };
      path = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "recipe mode: path within the source. Default: the pkgs/by-name location.";
      };
      attr = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "recipe mode: attribute of the file's result. package mode: dotted attribute path, default the workaround name.";
      };
    };
  };
in
{
  options.teq.nixos = {
    workaroundSources = lib.mkOption {
      type = lib.types.attrsOf lib.types.path;
      default = lib.mapAttrs' (n: v: lib.nameValuePair (lib.removePrefix "nixpkgs-" n) v) (
        lib.filterAttrs (n: _: lib.hasPrefix "nixpkgs-" n) inputs
      );
      description = "nixpkgs trees to take packages from. Default: each flake input nixpkgs-<name>, as <name>.";
    };

    workarounds = lib.mkOption {
      default = { };
      description = "Temporary package replacements. Each overrides pkgs.<name> and gets a health check that warns once it can go.";
      type = lib.types.attrsOf (
        lib.types.submodule {
          options = {
            reason = lib.mkOption {
              type = lib.types.str;
              description = "Why it exists; shown when the health check asks for removal.";
            };
            fix = lib.mkOption {
              type = lib.types.nullOr (lib.types.functionTo lib.types.package);
              default = null;
              description = "Upstream package to replacement. Exclusive with from.";
            };
            from = lib.mkOption {
              type = lib.types.nullOr fromSubmodule;
              default = null;
              description = "Take the package from another nixpkgs tree. Exclusive with fix.";
            };
            retire = lib.mkOption {
              type = lib.types.enum [
                "cached"
                "evaluates"
                "version"
              ];
              default = "cached";
              description = "When the health check asks for removal. cached: upstream is in the binary cache. evaluates: upstream exists again. version: upstream's version reaches the replacement's.";
            };
            cache = lib.mkOption {
              type = lib.types.str;
              default = "https://cache.nixos.org";
              description = "Binary cache probed for retire = cached.";
            };
            expires = lib.mkOption {
              type = lib.types.nullOr lib.types.str;
              default = null;
              description = "YYYY-MM-DD; after it the health check asks for a review, whatever retire says.";
            };
          };
        }
      );
    };
  };

  config = lib.mkIf (cfg != { }) {
    nixpkgs.overlays = [ (final: prev: lib.mapAttrs (replacement final prev) cfg) ];
    teq.nixos.health.checks = lib.mapAttrs' (
      name: w: lib.nameValuePair "workaround.${name}" { command = [ "${check name w}" ]; }
    ) cfg;
  };
}
