{
  config,
  options,
  lib,
  pkgs,
  inputs,
  ...
}:
let
  cfg = config.teq.nixos.agent;
  secretsDir = ../../../secrets;
  agentSecret = name: file: {
    ${name} = {
      inherit file;
      owner = "agent";
      group = "agents";
      mode = "0400";
    };
  };
  fleetSecret =
    name:
    lib.optionalAttrs (builtins.pathExists (secretsDir + "/${name}.age")) (
      agentSecret name (secretsDir + "/${name}.age")
    );
  agentHome = "/var/lib/agent";
  runtimeDir = "/run/user/${toString cfg.uid}";
  otherUsers = lib.filterAttrs (n: _: n != "agent") config.users.users;
  otherGroups = lib.filterAttrs (n: _: n != "agents") config.users.groups;

  agentEnv = {
    PATH = "/run/wrappers/bin:/etc/profiles/per-user/agent/bin:/run/current-system/sw/bin";
    ANDROID_ADB_SERVER_PORT = "5038";
    NIX_SSL_CERT_FILE = "/etc/ssl/certs/ca-certificates.crt";
    NODE_OPTIONS = "--use-openssl-ca";
  }
  // lib.optionalAttrs config.virtualisation.docker.rootless.enable {
    DOCKER_HOST = "unix://${runtimeDir}/docker.sock";
  };

  albedoPackage =
    let
      albedoPkgs = inputs.albedo.packages.${pkgs.stdenv.hostPlatform.system};
      kernelDeps =
        map
          (
            dep:
            lib.replaceStrings [ "_" "." ] [ "-" "-" ] (
              lib.toLower (lib.head (builtins.match "[[:space:]]*([A-Za-z0-9_.-]+).*" dep))
            )
          )
          (builtins.fromTOML (builtins.readFile "${inputs.albedo}/python/pyproject.toml"))
          .project.dependencies;
      pyEnv = pkgs.python3.withPackages (
        ps:
        map (name: ps.${name}) (lib.unique kernelDeps)
        ++ (with ps; [
          numpy
          pandas
          polars
          pyarrow
          duckdb
          scipy
          scikit-learn
          sympy
          networkx
          matplotlib
          seaborn
          requests
          httpx
          beautifulsoup4
          lxml
          pyyaml
          openpyxl
          tomli-w
          xmltodict
          jsonschema
          python-dateutil
          chardet
          pillow
          imageio
          opencv4
          pygame
          rich
          tqdm
          attrs
          psutil
          tabulate
          markdown-it-py
        ])
      );
      daemon' = albedoPkgs.daemon.override { kernelPython = pyEnv; };
      tui' = albedoPkgs.albedo-client.override { daemon = daemon'; };
      server' = pkgs.symlinkJoin {
        name = "albedo-server-${daemon'.version}";
        paths = [ daemon' ];
        nativeBuildInputs = [ pkgs.makeBinaryWrapper ];
        postBuild = ''
          makeBinaryWrapper ${tui'}/libexec/albedo/albedo-server $out/bin/albedo-server \
            --set-default ALBEDO_DAEMON ${daemon'}/bin/albedo-daemon
        '';
        meta = daemon'.meta // {
          mainProgram = "albedo-server";
        };
      };
    in
    albedoPkgs.albedo.override {
      daemon = daemon';
      tui = tui';
      server = server';
    };

  agentRun = pkgs.writeShellApplication {
    name = "agent-run";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.systemd
    ];
    text = ''
      if [ "$(id -u)" = "${toString cfg.uid}" ]; then
        exec "$@"
      fi
      unit="agent-$(basename "$1")-$$"
      exec sudo -u agent -H env -i \
        TERM="''${TERM:-xterm}" COLORTERM="''${COLORTERM-}" LANG="''${LANG:-C.UTF-8}" LC_ALL="''${LC_ALL-}" \
        HOME=${agentHome} USER=agent LOGNAME=agent SHELL=${pkgs.bashInteractive}/bin/bash \
        XDG_RUNTIME_DIR=${runtimeDir} DBUS_SESSION_BUS_ADDRESS=unix:path=${runtimeDir}/bus \
        ${lib.concatStringsSep " " (lib.mapAttrsToList (n: v: "${n}=${lib.escapeShellArg v}") agentEnv)} \
        ${pkgs.systemd}/bin/systemd-run --user --scope --quiet --collect --unit="$unit" -- "$@"
    '';
  };

  harnessWrapper =
    name:
    pkgs.writeShellScriptBin name ''
      if [ "''${AGENT_SELF:-0}" = 1 ]; then
        exec /etc/profiles/per-user/agent/bin/${name} "$@"
      fi
      if [ "$(id -u)" != "${toString cfg.uid}" ] && ! /run/wrappers/bin/sudo -n -u agent ${pkgs.coreutils}/bin/test -r "$PWD" -a -x "$PWD" 2>/dev/null; then
        here=$PWD
        if [ -t 0 ] && [ -t 1 ]; then
          echo "${name}: the agent user cannot read $here" >&2
          if [ -d "$here/.git" ]; then
            printf '  1) run as yourself   2) adopt into ${srcTree} and run as agent   3) cancel  [1/2/3] ' >&2
          else
            printf '  1) run as yourself   3) cancel  [1/3] ' >&2
          fi
          read -r choice
          case "$choice" in
            1) exec /etc/profiles/per-user/agent/bin/${name} "$@" ;;
            2)
              [ -d "$here/.git" ] || exit 77
              (cd / && ${srcAdopt}/bin/agent-src-adopt "$here") || exit 77
              cd "$here" || exit 77
              ;;
            *) exit 77 ;;
          esac
        else
          echo "${name}: the agent user cannot read $here" >&2
          echo "  move the project into the shared tree:  agent-src-adopt $here" >&2
          echo "  or run as yourself:                      AGENT_SELF=1 ${name}" >&2
          exit 77
        fi
      fi
      exec ${agentRun}/bin/agent-run /etc/profiles/per-user/agent/bin/${name} "$@"
    '';

  statusLine = pkgs.writeShellApplication {
    name = "claude-statusline";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.jq
      pkgs.git
    ];
    text = builtins.readFile ../../../pkgs/harness/statusline.sh;
  };

  agentSkills = {
    reader = ../../../pkgs/harness/skills/reader;
    mbx = "${inputs.mr-boxington}/skills/mbx";
    tg = pkgs.linkFarm "tg-skill" [
      {
        name = "SKILL.md";
        path = "${inputs.tg}/SKILL.md";
      }
    ];
  };

  webfetchGuard = pkgs.writeShellApplication {
    name = "claude-webfetch-guard";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.jq
    ];
    text = builtins.readFile ../../../pkgs/harness/webfetch-guard.sh;
  };

  managedSettings = pkgs.writeText "claude-managed-settings.json" (
    builtins.toJSON {
      permissions.deny = [
        "Bash(git push:*)"
        "Bash(git push :*)"
        "Bash(cargo publish:*)"
        "WebFetch"
      ];
      hooks.PreToolUse = [
        {
          matcher = "WebFetch";
          hooks = [
            {
              type = "command";
              command = "${webfetchGuard}/bin/claude-webfetch-guard";
              timeout = 10;
            }
          ];
        }
      ];
      env = {
        CLAUDE_BASH_MAINTAIN_PROJECT_WORKING_DIR = "1";
        DISABLE_BUG_COMMAND = "1";
        DISABLE_ERROR_REPORTING = "1";
        MAX_MCP_OUTPUT_TOKENS = "40000";
        RUST_BACKTRACE = "1";
      };
      attribution = {
        commit = "";
        pr = "";
        sessionUrl = false;
      };
      statusLine = {
        type = "command";
        command = "${statusLine}/bin/claude-statusline";
        padding = 0;
      };
    }
  );

  srcTree = cfg.sourceTree.path;
  memoryRoot = "${srcTree}/.claude/memory";
  nixDirenv = pkgs.nix-direnv.override { nix = config.nix.package; };

  srcAdopt = pkgs.writeShellApplication {
    name = "agent-src-adopt";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.acl
      pkgs.git
      pkgs.findutils
    ];
    text = ''
      die() { echo "agent-src-adopt: $*" >&2; exit 1; }
      [ $# -eq 1 ] || die "usage: agent-src-adopt <repo-dir>"
      id -nG | tr ' ' '\n' | grep -qx agents || die "you are not in group agents in this login; log in again"
      given=$(realpath -m "$1")
      real=$(realpath "$given" 2>/dev/null || true)
      [ -n "$real" ] || die "$given does not exist"
      name=$(basename "$real")
      dest=${srcTree}/$name
      old=""
      case "$real" in
        ${srcTree}/*) [ "$real" = "$dest" ] || die "$real is nested inside the tree; adopt top-level repos only" ;;
        *)
          old=$real
          [ -d "$old/.git" ] || die "$old is not a git working tree"
          case "$(realpath "$PWD")" in "$old"|"$old"/*) die "run this from outside $old" ;; esac
          if [ -e "$dest" ]; then
            die "$dest already exists; remove or rename one of them, then rerun"
          fi
          mv "$old" "$dest"
          ln -s "$dest" "$old"
          echo "moved: $old -> $dest"
          ;;
      esac
      [ -d "$dest/.git" ] || die "$dest is not a git working tree"
      me=$(id -un)
      find "$dest" -user "$me" ! -group agents -exec chgrp agents {} +
      find "$dest" -user "$me" ! -perm -g+rw -exec chmod g+rwX {} +
      find "$dest" -user "$me" -type d ! -perm -g+s -exec chmod g+s {} +
      setfacl -R -m g:agents:rwX -m d:g:agents:rwX "$dest"
      git -C "$dest" config core.sharedRepository group
      key=$(printf '%s' "$dest" | tr '/.' '--')
      mem=${memoryRoot}/$key
      install -d -m 2770 -g agents "$mem"
      setfacl -m g:agents:rwX -m d:g:agents:rwX "$mem"
      link_memory() {
        local projects=$1 mem=$2 key=$3 k
        shift 3
        for k in "$@"; do
          if [ -d "$projects/$k/memory" ] && [ ! -L "$projects/$k/memory" ]; then
            cp -an "$projects/$k/memory/." "$mem/"
            rm -rf "$projects/$k/memory"
          fi
        done
        mkdir -p "$projects/$key"
        [ "$(readlink "$projects/$key/memory" 2>/dev/null)" = "$mem" ] || ln -sfn "$mem" "$projects/$key/memory"
      }
      oldkeys=""
      for p in "$old" "$given"; do
        [ -n "$p" ] && [ "$p" != "$dest" ] && oldkeys="$oldkeys $(printf '%s' "$p" | tr '/.' '--')"
      done
      # shellcheck disable=SC2086
      link_memory "$HOME/.claude/projects" "$mem" "$key" $oldkeys
      /run/wrappers/bin/sudo -n -u agent -H ${pkgs.bash}/bin/bash -c "$(declare -f link_memory); link_memory ${agentHome}/.claude/projects '$mem' '$key' $oldkeys"
      find "$mem" -user "$me" ! -group agents -exec chgrp agents {} +
      find "$mem" -user "$me" ! -perm -g+rw -exec chmod g+rwX {} +
      if [ -f "$dest/.envrc" ]; then
        /run/wrappers/bin/sudo -n -u agent -H ${pkgs.direnv}/bin/direnv allow "$dest"
      fi
      /run/wrappers/bin/sudo -n -u agent ${pkgs.coreutils}/bin/test -w "$dest" || die "agent still cannot write $dest"
      echo "ok: $dest  (memory: $mem)"
    '';
  };

  launchTest = pkgs.writeShellApplication {
    name = "agent-launch-test";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.gnugrep
    ];
    text = ''
      set +e
      fail=0
      ok() { echo "[ OK ] $1"; }
      bad() { echo "[FAIL] $1"; fail=1; }
      who=$(${agentRun}/bin/agent-run id -un)
      if [ "$who" = agent ]; then ok "runs as agent"; else bad "runs as $who"; fi
      leaked=$(SSH_AUTH_SOCK=/x GITHUB_TOKEN=x GH_TOKEN=x NIX_CONFIG=x GIT_ASKPASS=x GIT_SSH_COMMAND=x \
        AWS_SECRET_ACCESS_KEY=x ANTHROPIC_API_KEY=x OPENAI_API_KEY=x \
        ${agentRun}/bin/agent-run env | grep -E '^(SSH_AUTH_SOCK|GITHUB_TOKEN|GH_TOKEN|NIX_CONFIG|GIT_ASKPASS|GIT_SSH_COMMAND|AWS_|ANTHROPIC_API_KEY|OPENAI_API_KEY)')
      if [ -z "$leaked" ]; then ok "no human credentials in environment"; else bad "leaked: $leaked"; fi
      home=$(${agentRun}/bin/agent-run printenv HOME)
      if [ "$home" = ${agentHome} ]; then ok "HOME=${agentHome}"; else bad "HOME=$home"; fi
      slice=$(${agentRun}/bin/agent-run cat /proc/self/cgroup | grep -o 'user-${toString cfg.uid}.slice' | head -1)
      if [ -n "$slice" ]; then ok "scope under user-${toString cfg.uid}.slice"; else bad "not in agent slice"; fi
      if ${agentRun}/bin/agent-run ls /home/"$(id -un)"/.ssh >/dev/null 2>&1; then bad "agent can read your ~/.ssh"; else ok "agent cannot read your ~/.ssh"; fi
      exit "$fail"
    '';
  };

  launcherRules = [
    {
      users = cfg.launchers;
      runAs = "agent";
      commands = [
        {
          command = "ALL";
          options = [
            "NOPASSWD"
            "SETENV"
          ];
        }
      ];
    }
  ];

in
{
  options.teq.nixos.agent = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = config.teq.nixos.enable;
      defaultText = lib.literalExpression "config.teq.nixos.enable";
      description = "The shared `agent` account: a locked-password user that the fleet's agents can reach over SSH.";
    };
    harness = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = config.teq.nixos.gui.enable;
        defaultText = lib.literalExpression "config.teq.nixos.gui.enable";
        description = "Install the coding harnesses for `agent` on this host, with their launcher, credentials and shared source tree.";
      };
    };
    uid = lib.mkOption {
      type = lib.types.int;
      default = 1500;
    };
    authorizedKeys = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHn+uE4orHeGUUI+n3EackJ82rcimIEcOVR6RejK6ulf agent@thoughtful"
      ];
      description = "Public keys that may log in as `agent` on every host.";
    };
    manageUnits = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      example = [ "foundry-relay.service" ];
      description = "System units members of `agents` may start, stop and restart through polkit without a password.";
    };
    harnesses = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [
        "claude"
        "albedo"
      ];
      description = "Binary names wrapped so they run as `agent`; each must exist in the agent's per-user profile.";
    };
    harnessPackages = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      default = with pkgs.llm-agents; [
        claude-code
        albedoPackage
      ];
      description = "Packages installed into the agent's profile.";
    };
    extraPackages = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      default =
        (with pkgs; [
          gh
          python3
          ffmpeg-headless
          file
          tree
          unzip
          zip
          openssl
          dnsutils
          sqlite
          shellcheck
          nvd
          nix-diff
        ])
        ++ (with inputs.nix-index-database.packages.${pkgs.stdenv.hostPlatform.system}; [
          comma-with-db
          nix-index-with-db
        ])
        ++ [
          inputs.tg.packages.${pkgs.stdenv.hostPlatform.system}.tg
          (inputs.mr-boxington.packages.${pkgs.stdenv.hostPlatform.system}.mbx.overrideAttrs (old: {
            nativeBuildInputs = old.nativeBuildInputs ++ [ pkgs.pkg-config ];
            buildInputs = (old.buildInputs or [ ]) ++ [
              pkgs.zstd
              pkgs.aws-lc
            ];
          }))
        ];
    };
    extraGroups = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [
        "systemd-journal"
        "render"
        "video"
        "kvm"
        "dialout"
        "media"
      ]
      ++ lib.optional (config.users.groups ? adbusers) "adbusers";
    };
    launchers = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ "teq" ];
      description = "Human users allowed to become `agent` (sudo, NOPASSWD, only as agent).";
    };
    sourceTree = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Group-shared working tree where humans and the agent edit the same checkouts.";
      };
      path = lib.mkOption {
        type = lib.types.str;
        default = "/usr/local/src";
      };
    };
    slice = {
      cpuWeight = lib.mkOption {
        type = lib.types.int;
        default = 50;
      };
      memoryHigh = lib.mkOption {
        type = lib.types.str;
        default = "70%";
      };
      memoryMax = lib.mkOption {
        type = lib.types.str;
        default = "85%";
      };
      ioWeight = lib.mkOption {
        type = lib.types.int;
        default = 50;
      };
      tasksMax = lib.mkOption {
        type = lib.types.int;
        default = 8192;
      };
    };
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.enable {
      assertions = [
        {
          assertion = !(lib.any (u: (u.uid or null) == cfg.uid) (lib.attrValues otherUsers));
          message = "teq.nixos.agent: uid ${toString cfg.uid} is already used by another user";
        }
        {
          assertion = !(lib.any (g: (g.gid or null) == cfg.uid) (lib.attrValues otherGroups));
          message = "teq.nixos.agent: gid ${toString cfg.uid} is already used by another group";
        }
        {
          assertion = !(builtins.elem "agent" (config.nix.settings.trusted-users or [ ]));
          message = "teq.nixos.agent: agent must not be a Nix trusted user";
        }
      ];

      users = {
        groups.agents.gid = cfg.uid;
        users.agent = {
          isNormalUser = true;
          inherit (cfg) uid extraGroups;
          group = "agents";
          home = agentHome;
          homeMode = "750";
          createHome = true;
          description = "Shared agent identity";
          shell = pkgs.bashInteractive;
          hashedPassword = "!";
          linger = true;
          openssh.authorizedKeys.keys = cfg.authorizedKeys;
        };
      };

      systemd.tmpfiles.rules = [ "d ${agentHome}/.ssh 0700 agent agents -" ];

      services.openssh.settings.AllowUsers = lib.mkIf config.services.openssh.enable [ "agent" ];

      security.polkit = lib.mkIf (cfg.manageUnits != [ ]) {
        enable = true;
        extraConfig = ''
          polkit.addRule(function (action, subject) {
            if (action.id != "org.freedesktop.systemd1.manage-units" || !subject.isInGroup("agents")) {
              return polkit.Result.NOT_HANDLED;
            }
            var unit = action.lookup("unit");
            var verb = action.lookup("verb");
            var allowed = ${builtins.toJSON cfg.manageUnits};
            if (allowed.indexOf(unit) >= 0 && ["start", "stop", "restart"].indexOf(verb) >= 0) {
              return polkit.Result.YES;
            }
            return polkit.Result.NOT_HANDLED;
          });
        '';
      };
    })
    (lib.mkIf (cfg.enable && cfg.harness.enable) (
      lib.mkMerge [
        (lib.optionalAttrs (options ? age) {
          age.secrets = fleetSecret "gh-agent";
        })
        (lib.optionalAttrs (options ? home-manager) {
          home-manager.users.agent = {
            imports = [ inputs.albedo.homeModules.default ];
            home.stateVersion = "26.05";
            home.preferXdgDirectories = true;
            teq.home-manager = {
              cli = true;
              shell = true;
            };
            systemd.user.sessionVariables = agentEnv;
            home.sessionVariables = removeAttrs agentEnv [ "PATH" ];
            home.file = {
              ".gitconfig".text = "[safe]\n\tdirectory = *\n";
            }
            // lib.concatMapAttrs (name: source: {
              ".claude/skills/${name}".source = source;
              ".agents/skills/${name}".source = source;
            }) agentSkills;
            xdg.configFile = {
              "jj/config.toml".text = "[user]\nname = \"teq\"\nemail = \"teqed@shatteredsky.net\"\n";
              "mbx/config.toml".text = "[target]\nviews = false\n";
            };
            programs = {
              direnv.nix-direnv.package = nixDirenv;
              nix-index.enable = false;
              nix-index-database.comma.enable = false;
            };
            fonts.fontconfig.enable = false;
            services.albedo = {
              enable = true;
              package = albedoPackage;
              web.enable = true;
            };
          };
        })
        {
          users = {
            users = lib.mkMerge [
              {
                agent = {
                  packages = cfg.harnessPackages ++ cfg.extraPackages;
                };
              }
              (lib.mkIf cfg.sourceTree.enable (
                lib.genAttrs cfg.launchers (_: {
                  extraGroups = [ "agents" ];
                })
              ))
            ];
          };

          systemd = {
            tmpfiles.rules = [
              "d ${agentHome}/.config 0750 agent agents -"
              "d ${agentHome}/.config/nix 0750 agent agents -"
              "d ${agentHome}/.agents 0750 agent agents -"
              "d ${agentHome}/.claude 0750 agent agents -"
              "d ${agentHome}/.albedo 0700 agent agents -"
            ]
            ++ lib.optionals cfg.sourceTree.enable [
              "d ${srcTree} 2775 root agents -"
              "a+ ${srcTree} - - - - g:agents:rwx,d:g:agents:rwx"
              "d ${srcTree}/.claude 2770 agent agents -"
              "d ${memoryRoot} 2770 agent agents -"
              "A+ ${srcTree}/.claude - - - - g:agents:rwx,d:g:agents:rwx"
              "d ${agentHome}/.claude/projects 0750 agent agents -"
            ]
            ++ lib.optional (builtins.pathExists ../../../secrets/gh-agent.age) "f+ ${agentHome}/.config/nix/nix.conf 0640 agent agents - !include /run/agenix/gh-agent\\n";

            services.agent-credentials = {
              description = "Render the agent's gh credentials from agenix";
              wantedBy = [ "multi-user.target" ];
              after = [ "agenix.service" ];
              serviceConfig = {
                Type = "oneshot";
                RemainAfterExit = true;
              };
              script = ''
                set -eu
                if [ -r /run/agenix/gh-agent ]; then
                  install -d -m 0700 -o agent -g agents ${agentHome}/.config/gh
                  token=$(sed -n 's/.*github\.com=\([^ ]*\).*/\1/p' /run/agenix/gh-agent)
                  printf 'github.com:\n    oauth_token: %s\n    git_protocol: https\n' "$token" \
                    | install -m 0600 -o agent -g agents /dev/stdin ${agentHome}/.config/gh/hosts.yml
                fi
              '';
            };

            slices."user-${toString cfg.uid}".sliceConfig = {
              CPUWeight = cfg.slice.cpuWeight;
              MemoryHigh = cfg.slice.memoryHigh;
              MemoryMax = cfg.slice.memoryMax;
              IOWeight = cfg.slice.ioWeight;
              TasksMax = cfg.slice.tasksMax;
            };
          };

          security = {
            sudo.extraRules = lib.mkIf config.security.sudo.enable launcherRules;
            sudo-rs.extraRules = lib.mkIf config.security.sudo-rs.enable launcherRules;
          };

          environment = {
            systemPackages = [
              agentRun
              launchTest
            ]
            ++ lib.optional cfg.sourceTree.enable srcAdopt
            ++ map harnessWrapper cfg.harnesses;
            etc."claude-code/managed-settings.json".source = managedSettings;
            persistence = lib.mkIf config.teq.nixos.impermanence.enable {
              "/persist".directories = lib.mkIf cfg.sourceTree.enable [
                {
                  directory = srcTree;
                  user = "root";
                  group = "agents";
                  mode = "2775";
                }
              ];
            };
          };

          programs.git = lib.mkIf cfg.sourceTree.enable {
            enable = true;
            config = {
              safe.directory = [ "${srcTree}/*" ];
              includeIf."gitdir:${srcTree}/".path =
                pkgs.writeText "gitconfig-shared" "[core]\n\tsharedRepository = group\n";
            };
          };

        }
      ]
    ))
  ];
}
