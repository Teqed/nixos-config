{outputs, ...}: {
  nixpkgs = {
    config = {
      # allowBroken = true;
      allowUnfree = true;
      # allowUnsupportedSystem = true;
    };
    # You can add overlays here
    overlays = [
      # Add overlays your own flake exports (from overlays and pkgs dir):
      outputs.overlays.additions
      outputs.overlays.modifications
      outputs.overlays.stable-packages

      # You can also add overlays exported from other flakes:
      # neovim-nightly-overlay.overlays.default
      # inputs.nixpkgs-wayland.overlay # We only want to use these overlays in Wayland

      # Or define it inline, for example:
      # (final: prev: {
      #   hi = final.hello.overrideAttrs (oldAttrs: {
      #     patches = [ ./change-hello-to-hi.patch ];
      #   });
      # })
    ];
  };
}
