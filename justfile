host := `uname -n`

[private]
default:
    @just --list

# Rebuild and switch this host
switch:
    #!/usr/bin/env bash
    set -euo pipefail
    sudo true
    if [[ -t 1 ]] && command -v nom >/dev/null 2>&1; then
      sudo nixos-rebuild switch --flake ".#{{host}}" --log-format internal-json -v |& nom --json
    else
      sudo nixos-rebuild switch --flake ".#{{host}}"
    fi

# Build a host without switching
build target=host:
    #!/usr/bin/env bash
    set -euo pipefail
    attr=".#nixosConfigurations.{{target}}.config.system.build.toplevel"
    if [[ -t 1 ]] && command -v nom >/dev/null 2>&1; then
      nom build "$attr"
    else
      nix build "$attr"
    fi

# Run flake checks
check:
    nix flake check

# Format nix files
fmt:
    nix fmt .

# Update flake inputs
update *inputs:
    nix flake update {{inputs}}
