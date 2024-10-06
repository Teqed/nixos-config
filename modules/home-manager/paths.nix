{
  lib,
  config,
  pkgs,
  ...
}: let
  cfg = config.teq.home-manager;
  # XDG Base Directory Specification https://specifications.freedesktop.org/basedir-spec/latest/
  XDG_LOCAL_HOME = "${config.home.homeDirectory}/.local"; # ~/.local
  XDG_CACHE_HOME = "${config.home.homeDirectory}/.cache"; # ~/.cache
  XDG_CONFIG_HOME = "${config.home.homeDirectory}/.config"; # ~/.config # $XDG_CONFIG_HOME defines the base directory relative to which user-specific configuration files should be stored.
  XDG_STATE_HOME = "${XDG_LOCAL_HOME}/state"; # ~/.local/state # $XDG_STATE_HOME defines the base directory relative to which user-specific state files should be stored.
  XDG_DATA_HOME = "${XDG_LOCAL_HOME}/share"; # ~/.local/share # $XDG_DATA_HOME defines the base directory relative to which user-specific data files should be stored.
  XDG_BIN_HOME = "${XDG_LOCAL_HOME}/bin"; # ~/.local/bin # $XDG_BIN_HOME defines the base directory relative to which user specific executable files should be stored.
  XDG_RUNTIME_DIR = "/run/user/$UID"; # /run/user/$UID # If $XDG_RUNTIME_DIR is not set applications should fall back to a replacement directory with similar capabilities and print a warning message.
  XDG_USER_DIRS = "${XDG_LOCAL_HOME}/user-dirs"; # ~/.local/user-dirs
  XDG_DESKTOP_DIR = "${XDG_USER_DIRS}/Desktop";
  XDG_DOCUMENTS_DIR = "${XDG_USER_DIRS}/Documents";
  XDG_DOWNLOAD_DIR = "${XDG_USER_DIRS}/Downloads";
  XDG_MUSIC_DIR = "${XDG_USER_DIRS}/Music";
  XDG_PICTURES_DIR = "${XDG_USER_DIRS}/Pictures";
  XDG_PUBLICSHARE_DIR = "${XDG_USER_DIRS}/Public";
  XDG_TEMPLATES_DIR = "${XDG_USER_DIRS}/Templates";
  XDG_VIDEOS_DIR = "${XDG_USER_DIRS}/Videos";
  # Extra XDG-like directories
  XDG_LIB_HOME = "${XDG_LOCAL_HOME}/lib"; # ~/.local/lib
  XDG_OPT_HOME = "${XDG_LOCAL_HOME}/opt"; # ~/.local/opt
  XDG_GAMES_HOME = "${XDG_OPT_HOME}/games"; # ~/.local/opt/games
  XDG_MISC_DIR = "${XDG_USER_DIRS}/Misc"; # ~/.local/user-dirs/Misc
  XDG_REPOS_DIR = "${XDG_USER_DIRS}/Repos"; # ~/.local/user-dirs/Repos
  XDG_SCREENSHOTS_DIR = "${XDG_USER_DIRS}/Pictures/Screenshots"; # ~/.local/user-dirs/Pictures/Screenshots
  global_variables = {
    # NAME = "Timothy Quilling"; # Used by: ??? dpkg-buildpackage (unless overridden by $DEBFULLNAME), git (unless overridden by 'user.name'), hg (via ~/.hgrc 'ui.username'), makepkg (via ~/.makepkg.conf $PACKAGER)
    # EMAIL = "teqed@shatteredsky.net"; # Used by: dpkg-buildpackage (unless overridden by $DEBEMAIL), git (unless overridden by 'user.email'), hg (via ~/.hgrc 'ui.username'), makepkg (via ~/.makepkg.conf $PACKAGER)
    # LD_LIBRARY_PATH = "${XDG_LOCAL_HOME}/lib"; TODO: Prepend to the existing value / LIBPATH
    # XDG
    XDG_LOCAL_HOME = XDG_LOCAL_HOME; # ~/.local
    # XDG_BIN_HOME = XDG_BIN_HOME; # ~/.local/bin
    # XDG_LIB_HOME = XDG_LIB_HOME; # ~/.local/lib
    XDG_GAMES_HOME = XDG_GAMES_HOME; # ~/.local/games
    XDG_OPT_HOME = XDG_OPT_HOME; # ~/.local/opt
    XDG_USER_DIRS = XDG_USER_DIRS; # ~/.local/user-dirs
    XDG_MISC_DIR = XDG_MISC_DIR; # ~/.local/user-dirs/Misc
    XDG_REPOS_DIR = XDG_REPOS_DIR; # ~/.local/user-dirs/Repos
    XDG_SCREENSHOTS_DIR = XDG_SCREENSHOTS_DIR; # ~/.local/user-dirs/Pictures/Screenshots
    # XDG_RUNTIME_DIR = XDG_RUNTIME_DIR; # /run/user/$UID
    # ENVVAR config
    MANPAGER = "sh -c 'col -bx | bat -l man -p'";
    EDITOR = "micro";
    VISUAL = "micro";
    PAGER = "moar";
    LESS = "-RF";
    MOAR = "--statusbar=bold --no-linenumbers";
    DICPATH = "/run/current-system/sw/share/hunspell";
    # General applications / tools
    INPUTRC = "${XDG_CONFIG_HOME}/readline/inputrc";
    # GTK2_RC_FILES = lib.mkForce "${XDG_CONFIG_HOME}/gtk-2.0/gtkrc"; # Override upstream home-manager/modules/misc/gtk.nix
    XCOMPOSEFILE = "${XDG_CONFIG_HOME}/X11/XCompose"; # ~/.config/X11/XCompose
    VIMINIT = ":so ${XDG_CONFIG_HOME}/vim/.vimrc"; # ~/.vimrc
    GVIMINIT = ":so ${XDG_CONFIG_HOME}/vim/.gvimrc"; # ~/.gvimrc
    MPLAYER_HOME = "${XDG_CONFIG_HOME}/mplayer";
    PARALLEL_HOME = "${XDG_CONFIG_HOME}/parallel";
    AWS_SHARED_CREDENTIALS_FILE = "${XDG_CONFIG_HOME}/aws/credentials"; # ~/.aws/credentials
    AWS_CONFIG_FILE = "${XDG_CONFIG_HOME}/aws/config"; # ~/.aws/config
    ANSIBLE_HOME = "${XDG_CONFIG_HOME}/ansible"; # ~/.ansible
    # ZDOTDIR = "${XDG_CONFIG_HOME}/zsh"; # ~/.zsh
    # Cache
    XCOMPOSECACHE = "${XDG_CACHE_HOME}/X11/XCompose"; # ~/.XCompose
    LESSHISTFILE = "${XDG_CACHE_HOME}/less/history";
    # Data
    WINEPREFIX = "${XDG_DATA_HOME}/wine";
    WAKATIME_HOME = "${XDG_DATA_HOME}/wakatime";
    # XCURSOR_PATH = "/usr/share/icons:${XDG_DATA_HOME}/icons";
    # TERMINFO = "${XDG_DATA_HOME}/terminfo";
    # TERMINFO_DIRS = "${XDG_DATA_HOME}/terminfo";
    # History
    HISTFILE = "${XDG_STATE_HOME}/history/histfile"; # ~/.bash_history , ~/.zsh_history -- overwritten later by specific shell
    HISTSIZE = 1000000; # Number of commands to remember in the history
    HISTFILESIZE = 1000000; # Should be controlled by actual shell later
    HISTCONTROL = "ignoreboth"; # Don't put duplicate lines or lines starting with space in the history
    MYSQL_HISTFILE = "${XDG_STATE_HOME}/history/mysql_history"; # ~/.mysql_history
    SQLITE_HISTORY = "${XDG_STATE_HOME}/history/sqlite_history";
    # Programming languages / tools / package managers
    ANDROID_HOME = "${XDG_DATA_HOME}/android";
    DOCKER_CONFIG = "${XDG_CONFIG_HOME}/docker";
    GRADLE_USER_HOME = "${XDG_DATA_HOME}/gradle";
    GOPATH = "${XDG_DATA_HOME}/go";
    M2_HOME = "${XDG_DATA_HOME}/m2";
    _JAVA_OPTIONS = "-Djava.util.prefs.userRoot=${XDG_CONFIG_HOME}/java";
    CARGO_HOME = "${XDG_DATA_HOME}/cargo"; # Rust
    RUSTUP_HOME = "${XDG_DATA_HOME}/rustup"; # Rust
    RBENV_ROOT = "${XDG_DATA_HOME}/rbenv"; # Ruby
    ## npm/node
    NODE_REPL_HISTORY = "${XDG_DATA_HOME}/node_repl_history";
    NPM_CONFIG_USERCONFIG = "${XDG_CONFIG_HOME}/npm/npmrc";
    NPM_CONFIG_PREFIX = "${XDG_DATA_HOME}/npm";
    NPM_CONFIG_CACHE = "${XDG_CACHE_HOME}/npm";
    NPM_CONFIG_TMP = "${XDG_RUNTIME_DIR}/npm";
    ## dotnet
    DOTNET_CLI_HOME = "${XDG_DATA_HOME}/dotnet";
    NUGET_PACKAGES = "${XDG_CACHE_HOME}/NuGetPackages";
    ## Python
    PYTHONSTARTUP = "${XDG_CONFIG_HOME}/python/pythonrc.py";
    PYTHONPYCACHEPREFIX = "${XDG_CACHE_HOME}/python";
    PYTHONUSERBASE = "${XDG_DATA_HOME}/python";
    PYENV_ROOT = "${XDG_DATA_HOME}/pyenv";
    PIP_LOG_FILE = "${XDG_CACHE_HOME}/pip/pip.log";
    PIP_CONFIG_FILE = "${XDG_CONFIG_HOME}/pip/pip.conf";
    MYPY_CACHE_DIR = "${XDG_CACHE_HOME}/mypy";
    IPYTHONDIR = "${XDG_CONFIG_HOME}/ipython";
    JUPYTER_CONFIG_DIR = "${XDG_CONFIG_HOME}/jupyter";
    # To relocate runtime data & IPC sockets:
    XAUTHORITY = "${XDG_RUNTIME_DIR}/Xauthority";
    SCREENDIR = "${XDG_RUNTIME_DIR}/screen";
    TMUX_TMPDIR = "${XDG_RUNTIME_DIR}/tmux";
    ICEAUTHORITY = "${XDG_RUNTIME_DIR}/ICEauthority"; # ~/.ICEauthority
  };
in {
  options.teq.home-manager = {
    paths = lib.mkEnableOption "Teq's NixOS Paths configuration defaults.";
  };
  config = lib.mkIf cfg.paths {
    programs.bash.sessionVariables = global_variables;
    programs.zsh.sessionVariables = global_variables;
    systemd.user.sessionVariables = global_variables;
    home = {
      packages = with pkgs; [xdg-ninja]; # A shell script which checks your $HOME for unwanted files and directories.
      preferXdgDirectories = true;
      # sessionPath = [XDG_BIN_HOME];
      sessionVariables = global_variables;
      shellAliases = {
        wget = "wget --hsts-file='\${XDG_STATE_HOME}/history/wget_history'";
      };
      # configFile = {
      #   "npm/npmrc".text = ''
      #     prefix=${XDG_DATA_HOME}/npm
      #     cache=${XDG_CACHE_HOME}/npm
      #     tmp=${XDG_RUNTIME_DIR}/npm
      #     init-module=${XDG_CONFIG_HOME}/npm/config/npm-init.js
      #   '';

      #   "python/pythonrc.py".text = ''
      #     def is_vanilla() -> bool:
      #         import sys
      #         return not hasattr(__builtins__, '__IPYTHON__') and 'bpython' not in sys.argv[0]

      #     def setup_history():
      #         import os
      #         import atexit
      #         import readline
      #         from pathlib import Path

      #         if state_home := os.environ.get('XDG_STATE_HOME'):
      #             state_home = Path(state_home)
      #         else:
      #             state_home = Path.home() / '.local' / 'state'

      #         history: Path = state_home / 'python_history'

      #         # https://github.com/python/cpython/issues/105694
      #         if not history.is_file():
      #           readline.write_history_file(str(history)) # breaks on macos + python3 without this.

      #         readline.read_history_file(str(history))
      #         atexit.register(readline.write_history_file, str(history))

      #     if is_vanilla():
      #         setup_history()
      #   '';
      # };
    };
    xdg = {
      enable = true;
      # cacheHome = XDG_CACHE_HOME; # ~/.cache
      # configHome = XDG_CONFIG_HOME; # ~/.config
      # dataHome = XDG_DATA_HOME; # ~/.local/share
      # stateHome = XDG_STATE_HOME; # ~/.local/state
      configFile."user-dirs.dirs" = lib.mkIf config.xdg.userDirs.enable {force = true;};
      userDirs = {
        enable = true;
        createDirectories = true;
        desktop = XDG_DESKTOP_DIR; # ~/.local/user-dirs/Desktop
        documents = XDG_DOCUMENTS_DIR; # ~/.local/user-dirs/Documents
        download = XDG_DOWNLOAD_DIR; # ~/.local/user-dirs/Downloads
        music = XDG_MUSIC_DIR; # ~/.local/user-dirs/Music
        pictures = XDG_PICTURES_DIR; # ~/.local/user-dirs/Pictures
        publicShare = XDG_PUBLICSHARE_DIR; # ~/.local/user-dirs/Public
        templates = XDG_TEMPLATES_DIR; # ~/.local/user-dirs/Templates
        videos = XDG_VIDEOS_DIR; # ~/.local/user-dirs/Videos
        extraConfig = {
          XDG_LOCAL_HOME = XDG_LOCAL_HOME; # ~/.local
          # XDG_BIN_HOME = XDG_BIN_HOME; # ~/.local/bin
          # XDG_LIB_HOME = XDG_LIB_HOME; # ~/.local/lib
          XDG_GAMES_HOME = XDG_GAMES_HOME; # ~/.local/games
          XDG_OPT_HOME = XDG_OPT_HOME; # ~/.local/opt
          XDG_USER_DIRS = XDG_USER_DIRS; # ~/.local/user-dirs
          XDG_MISC_DIR = XDG_MISC_DIR; # ~/.local/user-dirs/Misc
          XDG_REPOS_DIR = XDG_REPOS_DIR; # ~/.local/user-dirs/Repos
          XDG_SCREENSHOTS_DIR = XDG_SCREENSHOTS_DIR; # ~/.local/user-dirs/Pictures/Screenshots
          # XDG_RUNTIME_DIR = XDG_RUNTIME_DIR; # /run/user/$UID
        };
      };
    };
  };
}
