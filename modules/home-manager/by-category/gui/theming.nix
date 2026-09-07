{
  lib,
  config,
  pkgs,
  ...
}:
{
  config = lib.mkIf config.teq.home-manager.gui {
    home = {
      pointerCursor = {
        enable = true;
        name = lib.mkDefault "Bibata-Modern-Classic";
        package = lib.mkDefault pkgs.bibata-cursors;
        gtk.enable = lib.mkDefault true;
        x11.enable = lib.mkDefault true;
        x11.defaultCursor = lib.mkDefault "Bibata-Modern-Classic";
      };
    };
    gtk = {
      enable = lib.mkDefault true;
      cursorTheme.name = lib.mkDefault "Bibata-Modern-Classic";
      cursorTheme.size = lib.mkDefault 24;
      font = {
        name = "Inter";
        size = 10;
        package = pkgs.inter;
      };
      iconTheme = {
        name = "Papirus-Dark";
        package = pkgs.papirus-icon-theme;
      };
      gtk4.theme = null;
    };

    programs.plasma = {
      enable = lib.mkDefault false;

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
          size = 24;
        };
        iconTheme = "Papirus-Dark";

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
                  showTooltips = false;
                };
                behavior = {
                  grouping.clickAction = "showTextualList";
                  middleClickAction = "toggleGrouping";
                  showTasks.onlyInCurrentScreen = true;
                };
                launchers = [
                  "preferred://filemanager"
                  "preferred://browser"
                ];
              };
            }
            "org.kde.plasma.marginsseparator"
            "org.kde.plasma.pager"
            {
              systemTray = {
                items = {
                  hidden = [
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

      shortcuts = {
        ksmserver = {
          "Lock Session" = [
            "Screensaver"
            "Meta+Ctrl+Alt+L"
          ];
        };
        kwin = {
          "Alt+" = "Meta+,";

          "Switch Window Down" = [
            "Meta+Alt+J"
            "Meta+Alt+Down"
          ];
          "Switch Window Left" = [
            "Meta+Alt+H"
            "Meta+Alt+Left"
          ];
          "Switch Window Right" = [
            "Meta+Alt+L"
            "Meta+Alt+Right"
          ];
          "Switch Window Up" = [
            "Meta+Alt+K"
            "Meta+Alt+Up"
          ];
          "Window Quick Tile Bottom" = [
            "Meta+J"
            "Meta+Down"
          ];
          "Window Quick Tile Left" = [
            "Meta+H"
            "Meta+Left"
          ];
          "Window Quick Tile Right" = [
            "Meta+L"
            "Meta+Right"
          ];
          "Window Quick Tile Top" = [
            "Meta+K"
            "Meta+Up"
          ];
        };
      };
    };
  };
}
