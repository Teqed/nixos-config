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
    nix fmt

# Update flake inputs
update *inputs:
    nix flake update {{inputs}}

# Build a cachePull host and have it pull the result now; must run on that host's configured build server
deploy target:
    #!/usr/bin/env bash
    set -euo pipefail
    if [[ ! "{{target}}" =~ ^[A-Za-z0-9][A-Za-z0-9-]*$ ]]; then
      echo "deploy: target must be a plain hostname (letters, digits, hyphens)" >&2
      exit 1
    fi
    cfg=".#nixosConfigurations.{{target}}.config.teq.nixos.cachePull"
    if [[ "$(nix eval --json "$cfg.enable" 2>/dev/null)" != "true" ]]; then
      echo "deploy: {{target}} does not use cachePull; switch it directly instead" >&2
      exit 1
    fi
    server="$(nix eval --raw "$cfg.buildServer")"
    server="${server##*@}"
    if [[ "$(uname -n)" != "${server%%.*}" ]]; then
      echo "deploy: {{target}} pulls result-builds/{{target}} from $server, not from $(uname -n)." >&2
      echo "deploy: run this recipe on $server; a build here would never be seen by {{target}}." >&2
      exit 1
    fi
    attr=".#nixosConfigurations.{{target}}.config.system.build.toplevel"
    mkdir -p result-builds
    if [[ -t 1 ]] && command -v nom >/dev/null 2>&1; then
      nom build "$attr" --out-link "result-builds/{{target}}"
    else
      nix build "$attr" --out-link "result-builds/{{target}}"
    fi
    ssh -t "{{target}}" sudo systemctl start cache-pull
    ssh "{{target}}" journalctl -u cache-pull -n 3 --no-pager
