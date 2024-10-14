{
  pkgs,
  lib,
  config,
  ...
}: let
  XDG_CONFIG_HOME = "${config.xdg.configHome}";
  aliases = {
    dir = "dir --color=auto";
    vdir = "vdir --color=auto";
    grep = "grep --color=auto";
    fgrep = "LC_ALL=C fgrep --color=auto";
    egrep = "egrep --color=auto";
    ncdu = "ncdu --color dark";
    # bat = "bat --paging=never --style=plain";
    rm = "rm -i";
    tn5250 = "tn5250 env.TERM=IBM-3477-FC"; # ssl:localhost
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
in {
  config = lib.mkIf config.teq.home-manager.enable {
    home.shellAliases = aliases;
    programs = {
      home-manager.enable = lib.mkDefault true;
      atuin = {
        # Replacement for a shell history
        enable = lib.mkDefault true;
        # settings = { };
      };
      starship = {
        # Minimal, blazing fast, and extremely customizable prompt for any shell
        enable = true;
        # enableTransience = true;
        settings = pkgs.lib.importTOML ../sources/.config/starship.toml;
      };
      nushell.enable = lib.mkDefault true;
      bash = {
        enable = lib.mkDefault true;
        enableVteIntegration = lib.mkDefault true;
        # historyControl = # one of "erasedups", "ignoredups", "ignorespace", "ignoreboth"
        historyFile = lib.mkDefault "$HOME/.local/share/history/bash_history"; # "${config.xdg.dataHome}/zsh/zsh_history"
        historyFileSize = lib.mkDefault 1000000;
        historySize = lib.mkDefault 1000000;
        # Ignore some controlling instructions
        # HISTIGNORE is a colon-delimited list of patterns which should be excluded.
        # The '&' is a special pattern which suppresses duplicate entries.
        # export HISTIGNORE=$'[ \t]*:&:[fb]g:exit'
        historyIgnore = lib.mkDefault ["[ \t]*" "&" "[fb]g" "rm *" "pkill *" "ls" "cd" "exit"];
        # blesh, a full-featured line editor written in pure Bash
        initExtra = lib.mkBefore ''
          source ${pkgs.blesh}/share/blesh/ble.sh
          # set -h # Enable 'hash' builtin
          source "${XDG_CONFIG_HOME}/bash/functions.sh"; # Functions
          if [[ $(${pkgs.procps}/bin/ps --no-header --pid=$PPID --format=comm) != "fish" && -z ''${BASH_EXECUTION_STRING} ]]
          then
            shopt -q login_shell && LOGIN_OPTION='--login' || LOGIN_OPTION=""
            exec ${pkgs.fish}/bin/fish $LOGIN_OPTION
          fi
        '';
        # shellAliases = aliases;
        shellOptions = [
          "checkjobs"
          "checkwinsize" # check the window size after each command and, if necessary, update the values of LINES and COLUMNS.
          "globstar" # If set, the pattern "**" used in a pathname expansion context will match all files and zero or more directories and subdirectories.
          "cdspell" # If set, minor errors in the spelling of a directory component in a cd command will be corrected. The errors checked for are transposed characters, a missing character, and a character too many.
          "dirspell" # If set, Bash attempts spelling correction on directory names during word completion if the directory name initially supplied does not exist.
          "dotglob" # If set, Bash includes filenames beginning with a ‘.’ in the results of filename expansion.
          "extglob" # If set, the extended pattern matching features are enabled.
          "nocaseglob" # Use case-insensitive filename globbing
          "histappend" # Make bash append rather than overwrite the history on disk
        ];
      };
      # ssh.enable = true; # Enabled elsewhere
      # dircolors.enable = true; # Enabled elsewhere
      zsh = {
        enable = lib.mkDefault true;
        autosuggestion.enable = lib.mkDefault true;
        # Add to your system configuration to get completion for system packages (e.g. systemd).
        # environment.pathsToLink = [ "/share/zsh" ];
        enableVteIntegration = lib.mkDefault true;
        # dirHashes = {
        #   docs  = "$XDG_DOCUMENTS_DIR";
        #   vids  = "$XDG_VIDEOS_DIR";
        #   dl    = "$XDG_DOWNLOADS_DIR";
        # };
        dotDir = lib.mkDefault ".config/zsh";
        # envExtra = "" # Extra commands that should be added to .zshenv.
        history = {
          append = lib.mkDefault true;
          expireDuplicatesFirst = lib.mkDefault true;
          extended = lib.mkDefault true;
          ignorePatterns = lib.mkDefault ["rm *" "pkill *"];
          path = lib.mkDefault "$HOME/.local/share/history/zsh_history"; # "${config.xdg.dataHome}/zsh/zsh_history"
          save = lib.mkDefault 1000000;
          size = lib.mkDefault 1000000;
        };
        historySubstringSearch.enable = lib.mkDefault true;
        # initExtraFirst = "" # Commands that should be added to top of .zshrc.
        # initExtra = "" # Extra commands that should be added to .zshrc.
        # localVariables = {} # Extra local variables defined at the top of .zshrc.
        # loginExtra = " " # Extra commands that should be added to .zlogin.
        # logoutExtra = " " # Extra commands that should be added to .zlogout.
        # oh-my-zsh ... Options to configure oh-my-zsh.
        # plugins = [] # Plugins to source in .zshrc.
        # prezto ... Options to configure prezto.
        # profileExtra = " " # Extra commands that should be added to .zprofile.
        # sessionVariables = { } # Environment variables that will be set for zsh session.
        # shellAliases = aliases;
        # shellGlobalAliases # Similar to programs.zsh.shellAliases, but are substituted anywhere on a line.
        syntaxHighlighting.enable = lib.mkDefault true;
        # zplug ... Options to configure zplug.
        # zprof.enable = true; # zsh manager for profiling.
        # zsh-abbr.enable = true; # zsh manager for auto-expanding abbreviations.

        # Use XDG
        # interactiveShellInit = ''
        #   export HISTFILE=$HOME/.local/share/history/zsh_history
        #   export HISTSIZE=100000
        #   export SAVEHIST=100000
        # '';
        # loginShellInit
        # ohMyZsh ...
        # promptInit
        # setOptions
      };
      fish = {
        enable = lib.mkDefault true;
        interactiveShellInit = ''
          set fish_greeting # Disable greeting
        '';
        # loginShellInit = "";
        # shellInit = "";
        # useBabelfish = true; NixOS-only option
        # preferAbbrs = true; # If enabled, abbreviations will be preferred over aliases when other modules define aliases for fish.
        # shellAbbrs = { };
        # shellAliases = aliases;
        # functions = { };
        # plugins = [ ]; # The plugins to source in conf.d/99plugins.fish.
      };
      ion = {
        enable = lib.mkDefault true;
        # initExtra
        # shellAliases = aliases;
      };
    };
  };
}
