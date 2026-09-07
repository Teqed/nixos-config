{
  pkgs,
  lib,
  config,
  ...
}:
let
  XDG_CONFIG_HOME = "${config.xdg.configHome}";
  aliases = {
    dir = "dir --color=auto";
    vdir = "vdir --color=auto";
    grep = "grep --color=auto";
    fgrep = "LC_ALL=C fgrep --color=auto";
    egrep = "egrep --color=auto";
    ncdu = "ncdu --color dark";

    rm = "rm -i";
    tn5250 = "tn5250 env.TERM=IBM-3477-FC";
    colourify = "grc -es  --colour=auto";
    docker = "colourify docker";
    docker-compose = "colourify docker-compose";
    docker-machine = "colourify docker-machine";
    make = "colourify make";
    "g++" = "colourify g++";
    as = "colourify as";
    gas = "colourify gas";
    journalctl = "colourify journalctl";
    kubectl = "colourify kubectl";
    ld = "colourify ld";
    head = "colourify head";
    tail = "colourify tail";
    semanage = "colourify semanage";
    sockstat = "colourify sockstat";

    whois = "colourify whois";
    wdiff = "colourify wdiff";
    vmstat = "colourify vmstat";
    uptime = "colourify uptime";
    ulimit = "colourify ulimit";
    tune2fs = "colourify tune2fs";
    traceroute = "colourify traceroute";
    traceroute6 = "colourify traceroute6";
    tcpdump = "colourify tcpdump";
    systemctl = "colourify systemctl";
    sysctl = "colourify sysctl";
    stat = "colourify stat";
    ss = "colourify ss";
    sql = "colourify sql";
    showmount = "colourify showmount";
    sensors = "colourify sensors";
    semanageuser = "colourify semanageuser";
    semanagefcontext = "colourify semanagefcontext";
    semanageboolean = "colourify semanageboolean";
    pv = "colourify pv";
    ps = "colourify ps";
    proftpd = "colourify proftpd";
    ping2 = "colourify ping2";
    ping = "colourify ping";
    php = "colourify php";
    ntpdate = "colourify ntpdate";
    nmap = "colourify nmap";
    netstat = "colourify netstat";
    mvn = "colourify mvn";
    mtr = "colourify mtr";
    mount = "colourify mount";
    lspci = "colourify lspci";
    lsof = "colourify lsof";
    lsmod = "colourify lsmod";
    lsblk = "colourify lsblk";
    lsattr = "colourify lsattr";
    ls = "eza";
    lolcat = "colourify lolcat";
    log = "colourify log";
    ldap = "colourify ldap";
    last = "colourify last";
    iwconfig = "colourify iwconfig";
    irclog = "colourify irclog";
    iptables = "colourify iptables";
    iproute = "colourify iproute";
    ipneighbor = "colourify ipneighbor";
    ipaddr = "colourify ipaddr";
    ip = "colourify ip";
    iostat_sar = "colourify iostat_sar";
    ifconfig = "colourify ifconfig";
    id = "colourify id";
    getsebool = "colourify getsebool";
    getfacl = "colourify getfacl";
    gcc = "colourify gcc";
    free = "colourify free -h";
    findmnt = "colourify findmnt";
    fdisk = "colourify fdisk";
    esperanto = "colourify esperanto";
    env = "colourify env";
    du = "colourify du -h";
    dockerversion = "colourify dockerversion";
    dockersearch = "colourify dockersearch";
    dockerpull = "colourify dockerpull";
    dockerps = "colourify dockerps";
    dockernetwork = "colourify dockernetwork";
    docker-machinels = "colourify docker-machinels";
    dockerinfo = "colourify dockerinfo";
    dockerimages = "colourify dockerimages";
    dnf = "colourify dnf";
    dig = "colourify dig";
    diff = "colourify diff";
    df = "colourify df -h";
    cvs = "colourify cvs";
    configure = "colourify ./configure";
    blkid = "colourify blkid";
    ant = "colourify ant";
  };
in
{
  config = lib.mkIf config.teq.home-manager.enable {
    xdg.configFile."atuin/config.toml".force = lib.mkForce true;
    home.shellAliases = aliases;
    programs = {
      home-manager.enable = lib.mkDefault true;
      atuin = {
        enable = lib.mkDefault true;
      };
      starship = {
        enable = true;

        settings = pkgs.lib.importTOML ../sources/.config/starship.toml;
      };
      nushell.enable = lib.mkDefault true;
      bash = {
        enable = lib.mkDefault true;
        enableVteIntegration = lib.mkDefault true;

        historyFile = lib.mkDefault "$HOME/.local/share/history/bash_history";
        historyFileSize = lib.mkDefault 1000000;
        historySize = lib.mkDefault 1000000;

        historyIgnore = lib.mkDefault [
          "[ \t]*"
          "&"
          "[fb]g"
          "rm *"
          "pkill *"
          "ls"
          "cd"
          "exit"
        ];

        initExtra = lib.mkBefore ''
          source "${XDG_CONFIG_HOME}/bash/functions.sh"
          if [[ $(${pkgs.procps}/bin/ps --no-header --pid=$PPID --format=comm) != "fish" && -z ''${BASH_EXECUTION_STRING} ]]
          then
            shopt -q login_shell && LOGIN_OPTION='--login' || LOGIN_OPTION=""
            exec ${pkgs.fish}/bin/fish $LOGIN_OPTION
          fi
        '';

        shellOptions = [
          "checkjobs"
          "checkwinsize"
          "globstar"
          "cdspell"
          "dirspell"
          "dotglob"
          "extglob"
          "nocaseglob"
          "histappend"
        ];
      };

      zsh = {
        enable = lib.mkDefault true;
        autosuggestion.enable = lib.mkDefault true;

        enableVteIntegration = lib.mkDefault true;

        dotDir = lib.mkDefault "${config.xdg.configHome}/zsh";

        history = {
          append = lib.mkDefault true;
          expireDuplicatesFirst = lib.mkDefault true;
          extended = lib.mkDefault true;
          ignorePatterns = lib.mkDefault [
            "rm *"
            "pkill *"
          ];
          path = lib.mkDefault "$HOME/.local/share/history/zsh_history";
          save = lib.mkDefault 1000000;
          size = lib.mkDefault 1000000;
        };
        historySubstringSearch.enable = lib.mkDefault true;

        syntaxHighlighting.enable = lib.mkDefault true;
      };
      fish = {
        enable = lib.mkDefault true;
        interactiveShellInit = ''
          set fish_greeting
          if not set -q COLORTERM
            switch $TERM
              case xterm-ghostty xterm-kitty wezterm '*-256color' '*-direct'
                set -gx COLORTERM truecolor
            end
          end
          if not set -q REMOTE_SEAT; and not set -q SSH_CONNECTION; and set -q WAYLAND_DISPLAY
            set -gx REMOTE_SEAT (uname -n)
          end
          if set -q SSH_CONNECTION; and set -q WAYLAND_DISPLAY
            set -gx XDG_SESSION_TYPE wayland
            set -gx XDG_CURRENT_DESKTOP kde
            set -gx XDG_SESSION_DESKTOP kde
            set -gx DESKTOP_SESSION plasma
            set -gx KDE_SESSION_VERSION 6
            set -gx KDE_FULL_SESSION true
            set -gx _JAVA_AWT_WM_NONREPARENTING 1
            set -gx QT_WAYLAND_RECONNECT 1
          end
        '';
      };
      ion = {
        enable = lib.mkDefault true;
      };
    };
  };
}
