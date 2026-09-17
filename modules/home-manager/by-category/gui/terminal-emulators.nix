{
  lib,
  pkgs,
  config,
  inputs,
  ...
}:
let
  ghostty-tip = inputs.ghostty.packages.x86_64-linux.default;
  ghostty-pinned = inputs.ghostty-pinned.packages.x86_64-linux.default;

  probe = lib.fileContents (pkgs.callPackage ./ghostty-shader-probe.nix { ghostty = ghostty-tip; });

  ghostty =
    if probe == "fixed" then
      lib.warn "ghostty tip (${ghostty-tip.version}) passes the custom-shader probe; drop the ghostty-pinned input and the probe from terminal-emulators.nix" ghostty-tip
    else if probe == "broken" then
      ghostty-pinned
    else
      lib.warn "ghostty custom-shader probe was inconclusive for ${ghostty-tip.version}; keeping ghostty-pinned" ghostty-pinned;
in
{
  config = lib.mkIf config.teq.home-manager.gui {
    home.packages = [
      (lib.hiPrio ghostty)
    ];
  };
}
