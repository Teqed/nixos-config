{
  pkgs ? import <nixpkgs> {},
  lib ? pkgs.lib,
  stdenv ? pkgs.stdenv,
  ...
}:
# All it does is it copies all the scripts from src
with pkgs;
  stdenv.mkDerivation {
    pname = "Scripts";
    version = "1";
    src = ./src; # Folder src inside current folder that contains the script
    dontBuild = true; # No build required
    nativeBuildInputs = [makeWrapper coreutils];
    # buildInputs = [ <your dependencies> ];
    installPhase = ''
      # Create output directory in /nix/store
      mkdir -p $out/bin
      # Copy all things in ./src to output directory
      install -t $out/bin ./*
    '';
  }
