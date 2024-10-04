{
  lib,
  config,
  pkgs,
  ...
}: let
  cfg = config.teq.home-manager;
in {
  options.teq.home-manager = {
    theming = lib.mkEnableOption "Teq's NixOS Theming configuration defaults.";
  };
  config = lib.mkIf cfg.theming {
    # home = {
    #   pointerCursor = {
    #     name = lib.mkDefault "Bibata-Modern-Classic";
    #     package = lib.mkDefault pkgs.bibata-cursors;
    #     gtk.enable = lib.mkDefault true;
    #     x11.enable = lib.mkDefault true;
    #     x11.defaultCursor = lib.mkDefault "Bibata-Modern-Classic";
    #   };
    # };
    # gtk = {
    #   enable = lib.mkDefault true;
    #   cursorTheme.name = lib.mkDefault "Bibata-Modern-Classic";
    #   # cursorTheme.size = lib.mkDefault 24; # Default 16
    #   # font = "Noto Sans,  10"; null or (submodule)
    #   # iconTheme = "Papirus-Dark"; # null or (submodule)
    # };

    programs.plasma = {
      enable = true; # Set initial state
      overrideConfig = false; # TODO: Make Plasma more declarative

      fonts = {
        general = {
          family = "Inter";
          pointSize = 10;
        };
        fixedWidth = {
          family = "JetBrainsMono Nerd Font";
          pointSize = 10;
        };
        small = {
          family = "Inter";
          pointSize = 8;
        };
        toolbar = {
          family = "Inter Display";
          pointSize = 10;
        };
        menu = {
          family = "Inter Display";
          pointSize = 10;
        };
        windowTitle = {
          family = "Inter Display";
          pointSize = 10;
        };
      };
      workspace = {
        lookAndFeel = "org.kde.breezedark.desktop";
        cursor = {
          theme = "Bibata-Modern-Classic";
          # size = 32;
        };
        iconTheme = "Papirus-Dark";
        # wallpaperPictureOfTheDay.provider = "bing";
        wallpaper = "${pkgs.kdePackages.plasma-workspace-wallpapers}/share/wallpapers/MilkyWay/contents/images/5120x2880.png";
      };
      panels = [
        {
          location = "bottom";
          height = 40;
          floating = true;
          widgets = [
            {
              kickoff = {
                icon = "nix-snowflake";
                showButtonsFor = "powerAndSession";
                showActionButtonCaptions = false;
                compactDisplayStyle = true;
                favoritesDisplayMode = "list";
                applicationsDisplayMode = "list";
              };
            }
            "org.kde.plasma.marginsseparator"
            {
              iconTasks = {
                appearance = {
                  showTooltips = false; # Whether to show tooltips when hovering task buttons.
                };
                behavior = {
                  grouping.clickAction = "showTextualList"; # What happens when clicking on a grouped task.
                  middleClickAction = "toggleGrouping"; # What to do on middle-mouse click on a task button.
                  showTasks.onlyInCurrentScreen = true; # Whether to show only window tasks that are on the same screen as the widget.
                };
                launchers = let
                  # Auto switch terminal application desktop file
                  terminal =
                    if builtins.hasAttr "TERMINAL" config.home.sessionVariables # TODO: Properly set
                    then "${config.home.sessionVariables.TERMINAL}"
                    else "org.kde.konsole";
                in [
                  "applications:${terminal}.desktop"
                  "preferred://filemanager"
                  # "applications:krita.desktop" # TODO: Properly set
                  "preferred://browser" # TODO: Properly set
                  # "applications:emacsclient.desktop"
                  # "applications:writer.desktop"
                ];
              };
            }
            "org.kde.plasma.marginsseparator"
            "org.kde.plasma.pager"
            {
              systemTray = {
                items = {
                  hidden = [
                    # "sunshine" # TODO: Properly set
                    "org.kde.plasma.networkmanagement"
                    "org.kde.plasma.devicenotifier"
                  ];
                };
              };
            }
            {
              digitalClock = {
                date = {
                  enable = true;
                };
              };
            }
            "org.kde.plasma.showdesktop"
          ];
        }
      ];
      kscreenlocker.appearance = {
        # alwaysShowClock = false;
        # showMediaControls = false;
        wallpaperPictureOfTheDay.provider = "bing";
      };

      powerdevil = {
        AC = {
          powerButtonAction = "lockScreen";
          autoSuspend = {
            action = "hibernate";
            idleTimeout = 10000;
          };
          turnOffDisplay = {
            idleTimeout = 1000;
            idleTimeoutWhenLocked = 60;
          };
        };
        battery = {
          powerButtonAction = "sleep";
          whenSleepingEnter = "standbyThenHibernate";
        };
        lowBattery = {
          whenLaptopLidClosed = "hibernate";
        };
      };

      # kwin = {
      #   edgeBarrier = 0; # Disables the edge-barriers introduced in plasma 6.1
      #   cornerBarrier = false;

      #   # scripts.polonium = {
      #   #   enable = true;
      #   #   settings.layout.engine = "kwin";
      #   # };
      # };

      # kscreenlocker = {
      #   lockOnResume = true;
      #   timeout = 10;
      # };

      shortcuts = {
        ksmserver = {
          "Lock Session" = [
            "Screensaver"
            "Meta+Ctrl+Alt+L" # Rebind default lock shortcut Meta+L to prevent conflicts with window switching
          ];
        };
        kwin = {
          "Alt+" = "Meta+,"; # Show all windows; Related: Expose, ExposeAll
          # Use HJKL for window switching
          "Switch Window Down" = ["Meta+Alt+J" "Meta+Alt+Down"];
          "Switch Window Left" = ["Meta+Alt+H" "Meta+Alt+Left"];
          "Switch Window Right" = ["Meta+Alt+L" "Meta+Alt+Right"];
          "Switch Window Up" = ["Meta+Alt+K" "Meta+Alt+Up"];
          "Window Quick Tile Bottom" = ["Meta+J" "Meta+Down"];
          "Window Quick Tile Left" = ["Meta+H" "Meta+Left"];
          "Window Quick Tile Right" = ["Meta+L" "Meta+Right"];
          "Window Quick Tile Top" = ["Meta+K" "Meta+Up"];
        };
      };
    };
  };
}
