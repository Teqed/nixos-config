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
      enable = true;
      overrideConfig = true;
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
      #
      # Some high-level settings:
      #
      workspace = {
        # clickItemTo = "open"; # If you liked the click-to-open default from plasma 5
        lookAndFeel = "org.kde.breezedark.desktop";
        cursor = {
          theme = "Bibata-Modern-Classic";
          # size = 32;
        };
        iconTheme = "Papirus-Dark";
        wallpaper = "${pkgs.kdePackages.plasma-workspace-wallpapers}/share/wallpapers/MilkyWay/contents/images/5120x2880.png";
      };

      # hotkeys.commands."launch-konsole" = {
      #   name = "Launch Konsole";
      #   key = "Meta+Alt+K";
      #   command = "konsole";
      # };

      # fonts = {
      #   general = {
      #     family = "Source Sans Pro";
      #     pointSize = 10;
      #   };
      # };

      # panels = [
      # Windows-like panel at the bottom
      # {
      #   location = "bottom";
      #   widgets = [
      #     # We can configure the widgets by adding the name and config
      #     # attributes. For example to add the the kickoff widget and set the
      #     # icon to "nix-snowflake-white" use the below configuration. This will
      #     # add the "icon" key to the "General" group for the widget in
      #     # ~/.config/plasma-org.kde.plasma.desktop-appletsrc.
      #     # {
      #     #   name = "org.kde.plasma.kickoff";
      #     #   config = {
      #     #     General = {
      #     #       icon = "nix-snowflake-white";
      #     #       alphaSort = true;
      #     #     };
      #     #   };
      #     # }
      #     # Or you can configure the widgets by adding the widget-specific options for it.
      #     # See modules/widgets for supported widgets and options for these widgets.
      #     # For example:
      #     {
      #       kickoff = {
      #         sortAlphabetically = true;
      #         icon = "nix-snowflake-white";
      #       };
      #     }
      #     # Adding configuration to the widgets can also for example be used to
      #     # pin apps to the task-manager, which this example illustrates by
      #     # pinning dolphin and konsole to the task-manager by default with widget-specific options.
      #     {
      #       iconTasks = {
      #         launchers = [
      #           "applications:org.kde.dolphin.desktop"
      #           "applications:org.kde.konsole.desktop"
      #         ];
      #       };
      #     }
      #     # Or you can do it manually, for example:
      #     # {
      #     #   name = "org.kde.plasma.icontasks";
      #     #   config = {
      #     #     General = {
      #     #       launchers = [
      #     #         "applications:org.kde.dolphin.desktop"
      #     #         "applications:org.kde.konsole.desktop"
      #     #       ];
      #     #     };
      #     #   };
      #     # }
      #     # If no configuration is needed, specifying only the name of the
      #     # widget will add them with the default configuration.
      #     "org.kde.plasma.marginsseparator"
      #     # If you need configuration for your widget, instead of specifying the
      #     # the keys and values directly using the config attribute as shown
      #     # above, plasma-manager also provides some higher-level interfaces for
      #     # configuring the widgets. See modules/widgets for supported widgets
      #     # and options for these widgets. The widgets below shows two examples
      #     # of usage, one where we add a digital clock, setting 12h time and
      #     # first day of the week to Sunday and another adding a systray with
      #     # some modifications in which entries to show.
      #     {
      #       digitalClock = {
      #         calendar.firstDayOfWeek = "sunday";
      #         time.format = "12h";
      #       };
      #     }
      #     {
      #       systemTray.items = {
      #         # We explicitly show bluetooth and battery
      #         shown = [
      #           "org.kde.plasma.battery"
      #           "org.kde.plasma.bluetooth"
      #         ];
      #         # And explicitly hide networkmanagement and volume
      #         hidden = [
      #           "org.kde.plasma.networkmanagement"
      #           "org.kde.plasma.volume"
      #         ];
      #       };
      #     }
      #   ];
      #   hiding = "dodgewindows";
      # }
      # Application name, Global menu and Song information and playback controls at the top
      # {
      #   location = "top";
      #   height = 26;
      #   widgets = [
      #     {
      #       applicationTitleBar = {
      #         behavior = {
      #           activeTaskSource = "activeTask";
      #         };
      #         layout = {
      #           elements = ["windowTitle"];
      #           horizontalAlignment = "left";
      #           showDisabledElements = "deactivated";
      #           verticalAlignment = "center";
      #         };
      #         overrideForMaximized.enable = false;
      #         titleReplacements = [
      #           {
      #             type = "regexp";
      #             originalTitle = "^Brave Web Browser$";
      #             newTitle = "Brave";
      #           }
      #           {
      #             type = "regexp";
      #             originalTitle = ''\\bDolphin\\b'';
      #             newTitle = "File manager";
      #           }
      #         ];
      #         windowTitle = {
      #           font = {
      #             bold = false;
      #             fit = "fixedSize";
      #             size = 12;
      #           };
      #           hideEmptyTitle = true;
      #           margins = {
      #             bottom = 0;
      #             left = 10;
      #             right = 5;
      #             top = 0;
      #           };
      #           source = "appName";
      #         };
      #       };
      #     }
      #     "org.kde.plasma.appmenu"
      #     "org.kde.plasma.panelspacer"
      #     {
      #       plasmusicToolbar = {
      #         panelIcon = {
      #           albumCover = {
      #             useAsIcon = false;
      #             radius = 8;
      #           };
      #           icon = "view-media-track";
      #         };
      #         preferredSource = "spotify";
      #         musicControls.showPlaybackControls = true;
      #         songText = {
      #           displayInSeparateLines = true;
      #           maximumWidth = 640;
      #           scrolling = {
      #             behavior = "alwaysScroll";
      #             speed = 3;
      #           };
      #         };
      #       };
      #     }
      #   ];
      # }
      # ];

      # window-rules = [
      #   {
      #     description = "Dolphin";
      #     match = {
      #       window-class = {
      #         value = "dolphin";
      #         type = "substring";
      #       };
      #       window-types = ["normal"];
      #     };
      #     # apply = {
      #     #   noborder = {
      #     #     value = true;
      #     #     apply = "force";
      #     #   };
      #     #   # `apply` defaults to "apply-initially"
      #     #   maximizehoriz = true;
      #     #   maximizevert = true;
      #     # };
      #   }
      # ];

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

      #
      # Some mid-level settings:
      #
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

      #
      # Some low-level settings:
      #
      # configFile = {
      #   baloofilerc."Basic Settings"."Indexing-Enabled" = false;
      #   kwinrc."org.kde.kdecoration2".ButtonsOnLeft = "SF";
      #   kwinrc.Desktops.Number = {
      #     value = 8;
      #     # Forces kde to not change this value (even through the settings app).
      #     immutable = true;
      #   };
      #   kscreenlockerrc = {
      #     Greeter.WallpaperPlugin = "org.kde.potd";
      #     # To use nested groups use / as a separator. In the below example,
      #     # Provider will be added to [Greeter][Wallpaper][org.kde.potd][General].
      #     "Greeter/Wallpaper/org.kde.potd/General".Provider = "bing";
      #   };
      # };
    };
  };
}
