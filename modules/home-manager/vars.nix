{
  lib,
  config,
  pkgs,
  ...
}:
let
  XDG_LOCAL_HOME = "${config.home.homeDirectory}/.local";
  XDG_CACHE_HOME = "${config.home.homeDirectory}/.cache";
  XDG_CONFIG_HOME = "${config.home.homeDirectory}/.config";
  XDG_STATE_HOME = "${XDG_LOCAL_HOME}/state";
  XDG_DATA_HOME = "${XDG_LOCAL_HOME}/share";

  XDG_RUNTIME_DIR = "/run/user/$UID";
  XDG_USER_DIRS = "${XDG_LOCAL_HOME}/user-dirs";
  XDG_DESKTOP_DIR = "${XDG_USER_DIRS}/Desktop";
  XDG_DOCUMENTS_DIR = "${XDG_USER_DIRS}/Documents";
  XDG_DOWNLOAD_DIR = "${XDG_USER_DIRS}/Downloads";
  XDG_MUSIC_DIR = "${XDG_USER_DIRS}/Music";
  XDG_PICTURES_DIR = "${XDG_USER_DIRS}/Pictures";
  XDG_PUBLICSHARE_DIR = "${XDG_USER_DIRS}/Public";
  XDG_TEMPLATES_DIR = "${XDG_USER_DIRS}/Templates";
  XDG_VIDEOS_DIR = "${XDG_USER_DIRS}/Videos";

  XDG_OPT_HOME = "${XDG_LOCAL_HOME}/opt";
  XDG_GAMES_HOME = "${XDG_OPT_HOME}/games";
  XDG_MISC_DIR = "${XDG_USER_DIRS}/Misc";
  XDG_REPOS_DIR = "${XDG_USER_DIRS}/Repos";
  XDG_SCREENSHOTS_DIR = "${XDG_USER_DIRS}/Pictures/Screenshots";
  global_variables = {
    inherit XDG_LOCAL_HOME;

    inherit XDG_GAMES_HOME;
    inherit XDG_OPT_HOME;
    inherit XDG_USER_DIRS;
    inherit XDG_MISC_DIR;
    inherit XDG_REPOS_DIR;
    inherit XDG_SCREENSHOTS_DIR;

    MANPAGER = "sh -c 'col -bx | bat -l man -p'";
    EDITOR = "micro";
    VISUAL = "micro";
    PAGER = "moor";
    LESS = "-RF";
    MOOR = "--statusbar=bold --no-linenumbers";
    DICPATH = "/run/current-system/sw/share/hunspell";

    CLICOLOR = "1";
    LESS_TERMCAP_mb = "\e[01;31m";
    LESS_TERMCAP_md = "\e[01;38;5;74m";
    LESS_TERMCAP_me = "\e[0m";
    LESS_TERMCAP_se = "\e[0m";
    LESS_TERMCAP_so = "\e[38;5;246m";
    LESS_TERMCAP_ue = "\e[0m";
    LESS_TERMCAP_us = "\e[04;38;5;146m";
    GREP_COLORS = "ms=1;32:mc=1;32:ln=33";
    ERROR_COLOR = ";31";
    VERBOSE_COLOR = ";32";
    DEBUG_COLOR = ";34";
    WARNING_COLOR = ";35";
    INFO_COLOR = ";36";
    GCC_COLORS = "error=01;31:warning=01;35:note=01;36:caret=01;32:locus=01:quote=01";

    INPUTRC = "${XDG_CONFIG_HOME}/readline/inputrc";

    XCOMPOSEFILE = "${XDG_CONFIG_HOME}/X11/XCompose";
    VIMINIT = ":so ${XDG_CONFIG_HOME}/vim/.vimrc";
    GVIMINIT = ":so ${XDG_CONFIG_HOME}/vim/.gvimrc";
    MPLAYER_HOME = "${XDG_CONFIG_HOME}/mplayer";
    PARALLEL_HOME = "${XDG_CONFIG_HOME}/parallel";
    AWS_SHARED_CREDENTIALS_FILE = "${XDG_CONFIG_HOME}/aws/credentials";
    AWS_CONFIG_FILE = "${XDG_CONFIG_HOME}/aws/config";
    ANSIBLE_HOME = "${XDG_CONFIG_HOME}/ansible";

    XCOMPOSECACHE = "${XDG_CACHE_HOME}/X11/XCompose";
    LESSHISTFILE = "${XDG_CACHE_HOME}/less/history";

    WINEPREFIX = "${XDG_DATA_HOME}/wine";
    WAKATIME_HOME = "${XDG_DATA_HOME}/wakatime";
    CODEX_HOME = "${XDG_CONFIG_HOME}/codex";

    HISTFILE = "${XDG_STATE_HOME}/history/histfile";
    HISTSIZE = 1000000;
    HISTFILESIZE = 1000000;
    HISTCONTROL = "ignoreboth";
    MYSQL_HISTFILE = "${XDG_STATE_HOME}/history/mysql_history";
    SQLITE_HISTORY = "${XDG_STATE_HOME}/history/sqlite_history";

    ANDROID_HOME = "${XDG_DATA_HOME}/android";
    DOCKER_CONFIG = "${XDG_CONFIG_HOME}/docker";
    GRADLE_USER_HOME = "${XDG_DATA_HOME}/gradle";
    GOPATH = "${XDG_DATA_HOME}/go";
    M2_HOME = "${XDG_DATA_HOME}/m2";
    _JAVA_OPTIONS = "-Djava.util.prefs.userRoot=${XDG_CONFIG_HOME}/java";
    CARGO_HOME = "${XDG_DATA_HOME}/cargo";
    RUSTUP_HOME = "${XDG_DATA_HOME}/rustup";
    RBENV_ROOT = "${XDG_DATA_HOME}/rbenv";

    NODE_REPL_HISTORY = "${XDG_DATA_HOME}/node_repl_history";
    NPM_CONFIG_USERCONFIG = "${XDG_CONFIG_HOME}/npm/npmrc";
    NPM_CONFIG_PREFIX = "${XDG_DATA_HOME}/npm";
    NPM_CONFIG_CACHE = "${XDG_CACHE_HOME}/npm";
    NPM_CONFIG_TMP = "${XDG_RUNTIME_DIR}/npm";

    DOTNET_CLI_HOME = "${XDG_DATA_HOME}/dotnet";
    NUGET_PACKAGES = "${XDG_CACHE_HOME}/NuGetPackages";

    PYTHONSTARTUP = "${XDG_CONFIG_HOME}/python/pythonrc.py";
    PYTHONPYCACHEPREFIX = "${XDG_CACHE_HOME}/python";
    PYTHONUSERBASE = "${XDG_DATA_HOME}/python";
    PYENV_ROOT = "${XDG_DATA_HOME}/pyenv";
    PIP_LOG_FILE = "${XDG_CACHE_HOME}/pip/pip.log";
    PIP_CONFIG_FILE = "${XDG_CONFIG_HOME}/pip/pip.conf";
    MYPY_CACHE_DIR = "${XDG_CACHE_HOME}/mypy";
    IPYTHONDIR = "${XDG_CONFIG_HOME}/ipython";
    JUPYTER_CONFIG_DIR = "${XDG_CONFIG_HOME}/jupyter";

    XAUTHORITY = "${XDG_RUNTIME_DIR}/Xauthority";
    SCREENDIR = "${XDG_RUNTIME_DIR}/screen";
    TMUX_TMPDIR = "${XDG_RUNTIME_DIR}/tmux";
    ICEAUTHORITY = "${XDG_RUNTIME_DIR}/ICEauthority";
  };
in
{
  config = lib.mkIf config.teq.home-manager.enable {
    programs.bash.sessionVariables = global_variables;
    programs.zsh.sessionVariables = global_variables;
    systemd.user.sessionVariables = global_variables;
    home = {
      packages = with pkgs; [ xdg-ninja ];
      preferXdgDirectories = true;

      sessionVariables = lib.mkDefault global_variables;
      shellAliases = {
        wget = "wget --hsts-file='\${XDG_STATE_HOME}/history/wget_history'";
      };
    };
    xdg = {
      enable = true;

      configFile."user-dirs.dirs" = lib.mkIf config.xdg.userDirs.enable { force = true; };
      userDirs = {
        enable = true;
        createDirectories = true;
        setSessionVariables = false;
        desktop = XDG_DESKTOP_DIR;
        documents = XDG_DOCUMENTS_DIR;
        download = XDG_DOWNLOAD_DIR;
        music = XDG_MUSIC_DIR;
        pictures = XDG_PICTURES_DIR;
        publicShare = XDG_PUBLICSHARE_DIR;
        templates = XDG_TEMPLATES_DIR;
        videos = XDG_VIDEOS_DIR;
        extraConfig = {
          inherit XDG_LOCAL_HOME;

          inherit XDG_GAMES_HOME;
          inherit XDG_OPT_HOME;
          inherit XDG_USER_DIRS;
          MISC = XDG_MISC_DIR;
          REPOS = XDG_REPOS_DIR;
          SCREENSHOTS = XDG_SCREENSHOTS_DIR;
        };
      };
    };
  };
}
