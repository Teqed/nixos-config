{
  description = "Rust nightly devshell: rust-analyzer, wasm target, Bevy-ready native libs";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  outputs =
    { nixpkgs, rust-overlay, ... }:
    let
      forAllSystems = nixpkgs.lib.genAttrs [
        "x86_64-linux"
        "aarch64-linux"
      ];
    in
    {
      devShells = forAllSystems (
        system:
        let
          pkgs = import nixpkgs {
            inherit system;
            overlays = [ (import rust-overlay) ];
          };
          rust = pkgs.rust-bin.selectLatestNightlyWith (
            toolchain:
            toolchain.default.override {
              extensions = [
                "rust-src"
                "rust-analyzer"
              ];
              targets = [ "wasm32-unknown-unknown" ];
            }
          );
          buildInputs = with pkgs; [
            udev
            alsa-lib
            vulkan-loader
            libx11
            libxcursor
            libxi
            libxrandr
            libxkbcommon
            wayland
            openssl
            pkg-config
            gcc
            rust
            bacon
            clippy
          ];
        in
        {
          default = pkgs.mkShell {
            inherit buildInputs;
            LD_LIBRARY_PATH = pkgs.lib.makeLibraryPath buildInputs;
            RUST_BACKTRACE = 1;
          };
        }
      );
    };
}
