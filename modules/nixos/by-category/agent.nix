{
  config,
  options,
  lib,
  pkgs,
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
  hostName = config.networking.hostName;
  isHub = cfg.hub.enable;
  agentHome = "/var/lib/agent";
  runtimeDir = "/run/user/${toString cfg.uid}";
  mailKeySecret = ../../../secrets + "/mail-key-agent-${hostName}.age";
  hasMailKey = builtins.pathExists mailKeySecret;
  otherUsers = lib.filterAttrs (n: _: n != "agent") config.users.users;
  otherGroups = lib.filterAttrs (
    n: _:
    !(builtins.elem n [
      "agents"
      "mail"
    ])
  ) config.users.groups;

  agentMail = pkgs.python3.pkgs.buildPythonApplication {
    pname = "agent-mail";
    version = "0.1.0";
    format = "other";
    src = ../../../pkgs/agent-mail;
    propagatedBuildInputs = [ pkgs.openssh ];
    installPhase = ''
      mkdir -p $out/bin $out/lib/agent-mail
      cp agent_mail.py $out/lib/agent-mail/
      makeWrapper ${pkgs.python3}/bin/python3 $out/bin/agent-mail \
        --add-flags "$out/lib/agent-mail/agent_mail.py" \
        --prefix PATH : ${lib.makeBinPath [ pkgs.openssh ]}:/run/wrappers/bin
      makeWrapper ${pkgs.python3}/bin/python3 $out/bin/agent-mail-proxy \
        --add-flags "-c 'import sys; sys.path.insert(0, \"$out/lib/agent-mail\"); import agent_mail; sys.exit(agent_mail.proxy_main())'" \
        --prefix PATH : /run/wrappers/bin
      makeWrapper ${pkgs.python3}/bin/python3 $out/bin/agent-mail-deliver \
        --add-flags "-c 'import sys; sys.path.insert(0, \"$out/lib/agent-mail\"); import agent_mail; sys.exit(agent_mail.deliver_main())'"
    '';
    nativeBuildInputs = [ pkgs.makeWrapper ];
    doCheck = true;
    checkPhase = "python3 -B -m unittest discover -s . -v";
  };

  agentMailConfig = pkgs.writeText "agent-mail-config.json" (
    builtins.toJSON {
      mode = if isHub then "local" else "client";
      hub = cfg.hub.address;
      domain = cfg.hub.host;
      identities = lib.optionalAttrs (!isHub && cfg.mailKeyFile != null) { agent = cfg.mailKeyFile; };
      dsn_timeout = 15;
    }
  );

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
        PATH=/etc/profiles/per-user/agent/bin:/run/current-system/sw/bin:/run/wrappers/bin \
        AGENT_LAUNCHED_BY="$(id -un)" \
        ${pkgs.bashInteractive}/bin/bash -c '
          if [ -r /run/agenix/claude-agent ]; then
            CLAUDE_CODE_OAUTH_TOKEN=$(${pkgs.coreutils}/bin/tr -d "[:space:]" < /run/agenix/claude-agent)
            export CLAUDE_CODE_OAUTH_TOKEN
          fi
          exec ${pkgs.systemd}/bin/systemd-run --user --scope --quiet --collect --unit="$0" -- "$@"
        ' "$unit" "$@"
    '';
  };

  harnessWrapper =
    name:
    pkgs.writeShellScriptBin name ''
      if [ "''${AGENT_SELF:-0}" = 1 ]; then
        exec /etc/profiles/per-user/agent/bin/${name} "$@"
      fi
      exec ${agentRun}/bin/agent-run /etc/profiles/per-user/agent/bin/${name} "$@"
    '';

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

  aliasLines =
    lib.mapAttrsToList (name: members: "${name}: ${lib.concatStringsSep ", " members}") cfg.lists
    ++ lib.mapAttrsToList (name: target: "${name}: ${target}") cfg.aliases;

  proxyKeyEntries = lib.foldlAttrs (
    acc: principalHost: key:
    let
      principal = lib.head (lib.splitString "@" principalHost);
      account = lib.head (lib.splitString "+" principal);
    in
    acc
    // {
      ${account} = (acc.${account} or [ ]) ++ [
        ''command="${agentMail}/bin/agent-mail-proxy ${principalHost}",restrict ${key}''
      ];
    }
  ) { } cfg.proxyKeys;
in
{
  options.teq.nixos.agent = {
    enable = lib.mkEnableOption "the shared `agent` user: harness launcher, credentials home, mail channel";
    uid = lib.mkOption {
      type = lib.types.int;
      default = 1500;
    };
    harnesses = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [
        "claude"
        "codex"
        "prime-agent"
      ];
      description = "Binary names wrapped so they run as `agent`; each must exist in the agent's per-user profile.";
    };
    harnessPackages = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      default = with pkgs.llm-agents; [
        claude-code
        codex
        prime-agent
      ];
      description = "Packages installed into the agent's profile.";
    };
    extraPackages = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      default = with pkgs; [
        git
        jq
        ripgrep
        python3
        curl
      ];
    };
    launchers = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ "teq" ];
      description = "Human users allowed to become `agent` (sudo, NOPASSWD, only as agent).";
    };
    mailParticipants = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ "teq" ];
      description = "Human users in group `mail` (may use the channel).";
    };
    hub = {
      enable = lib.mkEnableOption "this host is the mail hub (runs local-only Postfix, holds every maildir)";
      host = lib.mkOption {
        type = lib.types.str;
        default = "thoughtful";
        description = "Mail domain part of every address.";
      };
      address = lib.mkOption {
        type = lib.types.str;
        default = "thoughtful";
        description = "ssh destination remote hosts use to reach the hub over the tailnet.";
      };
    };
    lists = lib.mkOption {
      type = lib.types.attrsOf (lib.types.listOf lib.types.str);
      default = { };
      example = {
        "repo-nixos-config" = [
          "teq"
          "agent+claude"
        ];
      };
      description = "Mailing lists (Postfix aliases). Explicit only; never derived from runtime directories.";
    };
    aliases = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = {
        fable = "agent+claude";
        luna = "agent+codex";
        astra = "agent+codex";
      };
    };
    proxyKeys = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = { };
      example = {
        "agent+codex@bubblegum" = "ssh-ed25519 AAAA...";
        "teq@bubblegum" = "ssh-ed25519 AAAA...";
      };
      description = "Hub only: principal@host -> public key allowed to run the mail proxy as that principal's account.";
    };
    mailKeyFile = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = if hasMailKey then "/run/agenix/mail-key-agent" else null;
      defaultText = "/run/agenix/mail-key-agent when secrets/mail-key-agent-<host>.age exists";
      description = "Remote hosts: private key the agent uses to reach the hub (an agenix secret path).";
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
    };
  };

  config = lib.mkIf cfg.enable (
    lib.mkMerge [
      (lib.optionalAttrs (options ? age) {
        age.secrets =
          lib.optionalAttrs (hasMailKey && !isHub) (agentSecret "mail-key-agent" mailKeySecret)
          // lib.optionalAttrs (builtins.pathExists (secretsDir + "/gh-agent.age")) (
            agentSecret "gh-agent" (secretsDir + "/gh-agent.age")
          )
          // fleetSecret "claude-agent"
          // fleetSecret "codex-auth"
          // fleetSecret "prime-auth";
      })
      {
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
          {
            assertion = isHub || cfg.mailKeyFile != null || cfg.proxyKeys == { };
            message = "teq.nixos.agent: non-hub hosts need mailKeyFile for the agent to reach the hub";
          }
          {
            assertion = lib.all (n: builtins.match "[a-z0-9-]+" n != null) (builtins.attrNames cfg.lists);
            message = "teq.nixos.agent: list names must match [a-z0-9-]+";
          }
        ];

        users = {
          groups = {
            agents.gid = cfg.uid;
            mail.members = cfg.mailParticipants ++ [ "agent" ];
          };
          users = lib.mkMerge [
            {
              agent = {
                isNormalUser = true;
                inherit (cfg) uid;
                group = "agents";
                home = agentHome;
                homeMode = "750";
                createHome = true;
                description = "Shared agent identity for coding harnesses";
                shell = pkgs.bashInteractive;
                hashedPassword = "!";
                linger = true;
                packages = cfg.harnessPackages ++ cfg.extraPackages ++ [ agentMail ];
              };
            }
            (lib.mkIf isHub (lib.mapAttrs (_: keys: { openssh.authorizedKeys.keys = keys; }) proxyKeyEntries))
          ];
        };

        systemd = {
          tmpfiles.rules = [
            "d ${agentHome}/.config 0750 agent agents -"
            "d ${agentHome}/.config/nix 0750 agent agents -"
            "d ${agentHome}/.ssh 0700 agent agents -"
          ]
          ++ lib.optional (builtins.pathExists ../../../secrets/gh-agent.age) "f+ ${agentHome}/.config/nix/nix.conf 0640 agent agents - !include /run/agenix/gh-agent\\n";

          services.agent-credentials = {
            description = "Render harness credential files for the agent user from agenix secrets";
            wantedBy = [ "multi-user.target" ];
            after = [ "agenix.service" ];
            serviceConfig = {
              Type = "oneshot";
              RemainAfterExit = true;
            };
            script = ''
              set -eu
              install -d -m 0750 -o agent -g agents ${agentHome}/.codex ${agentHome}/.prime ${agentHome}/.prime/agent
              seed() {
                if [ -r "$1" ] && [ ! -e "$2" ]; then
                  ${pkgs.jq}/bin/jq -e . "$1" >/dev/null
                  install -m 0600 -o agent -g agents "$1" "$2"
                  echo "seeded $2"
                fi
              }
              seed /run/agenix/codex-auth ${agentHome}/.codex/auth.json
              seed /run/agenix/prime-auth ${agentHome}/.prime/agent/auth.json
            '';
          };

          slices."user-${toString cfg.uid}".sliceConfig = {
            CPUWeight = cfg.slice.cpuWeight;
            MemoryHigh = cfg.slice.memoryHigh;
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
            agentMail
          ]
          ++ map harnessWrapper cfg.harnesses;
          etc."agent-mail/config.json".source = agentMailConfig;
          persistence."/persist".users = lib.mkIf (config.teq.nixos.impermanence.enable && isHub) (
            lib.genAttrs cfg.mailParticipants (_: {
              directories = [ "Maildir" ];
            })
          );
        };

        services.openssh.settings.AllowUsers = lib.mkIf isHub [ "agent" ];

        services.postfix = lib.mkIf isHub {
          enable = true;
          enableSmtp = false;
          enableSubmission = false;
          setSendmail = true;
          settings.main = {
            myhostname = cfg.hub.host;
            mydomain = cfg.hub.host;
            myorigin = cfg.hub.host;
            mydestination = [
              cfg.hub.host
              "localhost"
              "localhost.localdomain"
            ];
            mynetworks = [ "127.0.0.0/8" ];
            mailbox_command = "${agentMail}/bin/agent-mail-deliver $RECIPIENT";
            recipient_delimiter = "+";
            inet_interfaces = "loopback-only";
            smtp_dns_support_level = "disabled";
            message_size_limit = 10240000;
          };
          extraAliases = lib.concatStringsSep "\n" aliasLines;
        };
      }
    ]
  );
}
