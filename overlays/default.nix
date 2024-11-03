# This file defines overlays
{
  # inputs,
  ...
}: {
  # This one brings our custom packages from the 'pkgs' directory
  additions = final: _prev: import ../pkgs final.pkgs;

  # This one contains whatever you want to overlay
  # You can change versions, add patches, set compilation flags, anything really.
  # https://nixos.wiki/wiki/Overlays
  modifications = final: prev: {
    # example = prev.example.overrideAttrs (oldAttrs: rec {
    # ...
    # });
    ffmpeg_7-full = prev.ffmpeg_7-full.override {
      # Required for handbrake
      # The latest xev release has broken the ffmpeg package until 7.1, or until the fix is merged in nixos-unstable.
      # https://github.com/NixOS/nixpkgs/pull/353198
      withXevd = false;
      withXeve = false;
    };
    _7zz = prev._7zz.override { useUasm = true; };  # Hotfixes #353119 ; "Build failure: _7zz" ; https://github.com/NixOS/nixpkgs/issues/353119 ; Resolved by #353272 ; "_7zz: disable UASM properly" ; https://github.com/NixOS/nixpkgs/pull/353272
  };

  # When applied, the unstable nixpkgs set (declared in the flake inputs) will
  # be accessible through 'pkgs.unstable'
  # unstable-packages = final: _prev: {
  #   unstable = import inputs.nixpkgs-unstable {
  #     system = final.system;
  #     config.allowUnfree = true;
  #   };
  # };
}