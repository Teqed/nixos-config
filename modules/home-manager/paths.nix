{
  lib,
  config,
  pkgs,
  ...
}: let
  cfg = config.teq.home-manager;
  XDG_CACHE_HOME = config.xdg.cacheHome;
  XDG_CONFIG_HOME = config.xdg.configHome;
  XDG_DATA_HOME = config.xdg.dataHome;
  # XDG_STATE_HOME = config.xdg.stateHome;
  XDG_RUNTIME_DIR = config.home.sessionVariables.XDG_RUNTIME_DIR;
  extraXDG = config.xdg.userDirs.extraConfig;
in {
  options.teq.home-manager = {
    paths = lib.mkEnableOption "Teq's NixOS Paths configuration defaults.";
  };
  config = lib.mkIf cfg.paths {
    home = {
      packages = with pkgs; [xdg-ninja]; # A shell script which checks your $HOME for unwanted files and directories.
      preferXdgDirectories = lib.mkDefault true;
      sessionPath = lib.mkDefault ["$HOME/.local/bin"];
      sessionVariables = {
        # General applications / tools
        LESSHISTFILE = "${XDG_CACHE_HOME}/less/history";
        WINEPREFIX = "${XDG_DATA_HOME}/wine";
        MPLAYER_HOME = "${XDG_CONFIG_HOME}/mplayer";
        WAKATIME_HOME = "${XDG_DATA_HOME}/wakatime";
        SQLITE_HISTORY = "${XDG_CACHE_HOME}/sqlite_history";
        PARALLEL_HOME = "${XDG_CONFIG_HOME}/parallel";
        # Programming languages / tools / package managers
        ANDROID_HOME = "${XDG_DATA_HOME}/android";
        DOCKER_CONFIG = "${XDG_CONFIG_HOME}/docker";
        GRADLE_USER_HOME = "${XDG_DATA_HOME}/gradle";
        GOPATH = "${XDG_DATA_HOME}/go";
        M2_HOME = "${XDG_DATA_HOME}/m2";
        _JAVA_OPTIONS = "-Djava.util.prefs.userRoot=${XDG_CONFIG_HOME}/java";
        CARGO_HOME = "${XDG_DATA_HOME}/cargo";
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
        MYPY_CACHE_DIR = "${XDG_CACHE_HOME}/mypy";
        IPYTHONDIR = "${XDG_CONFIG_HOME}/ipython";
        JUPYTER_CONFIG_DIR = "${XDG_CONFIG_HOME}/jupyter";
      };
      shellAliases = {
        wget = "wget --hsts-file='\${XDG_DATA_HOME}/wget-hsts'";
      };
      configFile = {
        "npm/npmrc".text = ''
          prefix=${XDG_DATA_HOME}/npm
          cache=${XDG_CACHE_HOME}/npm
          tmp=${XDG_RUNTIME_DIR}/npm
          init-module=${XDG_CONFIG_HOME}/npm/config/npm-init.js
        '';

        "python/pythonrc.py".text = ''
          def is_vanilla() -> bool:
              import sys
              return not hasattr(__builtins__, '__IPYTHON__') and 'bpython' not in sys.argv[0]


          def setup_history():
              import os
              import atexit
              import readline
              from pathlib import Path

              if state_home := os.environ.get('XDG_STATE_HOME'):
                  state_home = Path(state_home)
              else:
                  state_home = Path.home() / '.local' / 'state'

              history: Path = state_home / 'python_history'

              # https://github.com/python/cpython/issues/105694
              if not history.is_file():
                readline.write_history_file(str(history)) # breaks on macos + python3 without this.

              readline.read_history_file(str(history))
              atexit.register(readline.write_history_file, str(history))


          if is_vanilla():
              setup_history()
        '';
      };
      # username = "teq"; # "$USER" by default
      # homeDirectory = "/home/teq"; "$HOME" by default
      # sessionVariables = {
      #   EDITOR = "emacs";
      #   GS_OPTIONS = "-sPAPERSIZE=a4";
      #   FOO = "Hello";
      #   BAR = "${config.home.sessionVariables.FOO} World!";
      # };
      # This option should only be used to manage simple aliases that are compatible across all shells. If you need to use a shell specific feature then make sure to use a shell specific option, for example programs.bash.shellAliases for Bash.
      # shellAliases = {
      #   g = "git";
      #   "..." = "cd ../..";
      # };
    };
    xdg = {
      enable = lib.mkDefault true;
      cacheHome = lib.mkDefault "${config.home.homeDirectory}/.cache"; # ~/.cache XDG_CACHE_HOME
      configHome = lib.mkDefault "${config.home.homeDirectory}/.config"; # ~/.config XDG_CONFIG_HOME
      dataHome = lib.mkDefault "${extraXDG.XDG_LOCAL_HOME}/share"; # ~/.local/share XDG_DATA_HOME
      stateHome = lib.mkDefault "${extraXDG.XDG_LOCAL_HOME}/state"; # ~/.local/state XDG_STATE_HOME
      userDirs = {
        enable = lib.mkDefault true;
        createDirectories = lib.mkDefault true;
        desktop = lib.mkDefault "${extraXDG.XDG_USER_DIRS}/Desktop"; # XDG_DESKTOP_DIR
        documents = lib.mkDefault "${extraXDG.XDG_USER_DIRS}/Documents"; # XDG_DOCUMENTS_DIR
        downloads = lib.mkDefault "${extraXDG.XDG_USER_DIRS}/Downloads"; # XDG_DOWNLOAD_DIR
        music = lib.mkDefault "${extraXDG.XDG_USER_DIRS}/Music"; # XDG_MUSIC_DIR
        pictures = lib.mkDefault "${extraXDG.XDG_USER_DIRS}/Pictures"; # XDG_PICTURES_DIR
        publicShare = lib.mkDefault "${extraXDG.XDG_USER_DIRS}/Public"; # XDG_PUBLICSHARE_DIR
        templates = lib.mkDefault "${extraXDG.XDG_USER_DIRS}/Templates"; # XDG_TEMPLATES_DIR
        videos = lib.mkDefault "${extraXDG.XDG_USER_DIRS}/Videos"; # XDG_VIDEOS_DIR
        extraConfig = {
          XDG_LOCAL_HOME = lib.mkDefault "${config.home.homeDirectory}/.local";
          XDG_BIN_HOME = lib.mkDefault "${extraXDG.XDG_LOCAL_HOME}/bin";
          XDG_LIB_HOME = lib.mkDefault "${extraXDG.XDG_LOCAL_HOME}/lib";
          XDG_GAMES_HOME = lib.mkDefault "${extraXDG.XDG_LOCAL_HOME}/games";
          XDG_OPT_HOME = lib.mkDefault "${extraXDG.XDG_LOCAL_HOME}/opt";
          XDG_USER_DIRS = lib.mkDefault "${extraXDG.XDG_LOCAL_HOME}/user-dirs";
          XDG_MISC_DIR = lib.mkDefault "${extraXDG.XDG_LOCAL_HOME}/Misc";
          XDG_SCREENSHOTS_DIR = lib.mkDefault "${config.xdg.userDirs.pictures}/Screenshots";
          XDG_RUNTIME_DIR = lib.mkDefault "/run/user/$UID";
        };
      };
    };

    # thing = mkMerge [
    #   (mkIf (!config.home.preferXdgDirectories) {
    #     home.file.".inputrc".text = finalConfig;
    #   })
    #   (mkIf config.home.preferXdgDirectories {
    #     xdg.configFile.inputrc.text = finalConfig;
    #     home.sessionVariables.INPUTRC = "${config.xdg.configHome}/inputrc";
    #   })
    # ];
    # xdg.configFile."nixpkgs/config.nix".source = ./.config/nixpkgs/config.nix;
    # xdg.configFile."nix/nix.conf".source = ./.config/nix/nix.conf;
  };
}
