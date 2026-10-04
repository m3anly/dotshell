self:
{
  config,
  lib,
  pkgs,
  ...
}@args:
let
  cfg = config.programs.dotshell;
  osConfig = args.osConfig or { };
  systemNiri = osConfig.programs.niri.enable or false;
  json = pkgs.formats.json { };
  inherit (lib) mkOption types;

  nullable =
    type: description:
    mkOption {
      type = types.nullOr type;
      default = null;
      inherit description;
    };

  withoutNulls =
    value:
    if lib.isAttrs value then
      lib.filterAttrs (_: v: v != null && v != { }) (lib.mapAttrs (_: withoutNulls) value)
    else
      value;
in
{
  options.programs.dotshell = {
    enable = lib.mkEnableOption "Dotshell, a Quickshell desktop shell for niri";

    package = mkOption {
      type = types.package;
      default =
        (self.lib.mkPackagesWith {
          inherit pkgs;
          niri = cfg.niriPackage;
        }).dotshell;
      defaultText = lib.literalExpression "(dotshell.lib.mkPackagesWith { inherit pkgs; niri = config.programs.dotshell.niriPackage; }).dotshell";
      description = "The Dotshell package, built from the consuming configuration's nixpkgs so Qt and Mesa match the system graphics drivers.";
    };

    niriPackage = mkOption {
      type = types.nullOr types.package;
      default = if systemNiri then osConfig.programs.niri.package else null;
      defaultText = lib.literalMD "`osConfig.programs.niri.package` when the NixOS niri module is enabled, otherwise `null`";
      description = ''
        The niri whose `niri msg` the shell uses. It must match the running compositor,
        since the IPC protocol changes between versions. `null` takes `niri` from `PATH`.
      '';
    };

    systemd.enable = mkOption {
      type = types.bool;
      default = true;
      description = "Start Dotshell with the graphical session as a systemd user service.";
    };

    niri = {
      rules = mkOption {
        type = types.bool;
        default = true;
        description = ''
          Write the niri rules the shell relies on (a transparent workspace background, the
          wallpaper in the backdrop, the floating settings window) to
          `$XDG_CONFIG_HOME/niri/dotshell/rules.kdl`. Add `include "dotshell/rules.kdl"` to the
          niri config.
        '';
      };

      binds = mkOption {
        type = types.bool;
        default = true;
        description = ''
          Write the default binds to `$XDG_CONFIG_HOME/niri/dotshell/binds.kdl`. Add
          `include "dotshell/binds.kdl"` to the niri config before your own binds: a later bind
          on the same key replaces it.
        '';
      };
    };

    settings = mkOption {
      default = { };
      description = ''
        Written to `$XDG_CONFIG_HOME/dotshell/config.json`. Unset options keep the
        shell's built-in defaults or the value chosen in the settings window; options
        set here are locked in that window. The shell reloads the file when it changes.
      '';
      type = types.submodule {
        freeformType = json.type;
        options = {
          blur = nullable types.bool "Request compositor background blur behind glass surfaces.";
          gameMode = {
            enabled = nullable types.bool "Game mode: turn off the parts below that are on.";
            animations = nullable types.bool "Game mode turns off springs, staggers, fades and other motion.";
            blur = nullable types.bool "Game mode turns off compositor blur, making glass opaque, and the blurred wallpaper in the overview.";
            widgets = nullable types.bool "Game mode unloads the desktop clock.";
            visualizer = nullable types.bool "Game mode stops the cava visualizer.";
          };
          lockOnLogind = nullable types.bool "Lock when logind asks the session to lock (`loginctl lock-session`, idle daemons).";
          power = {
            confirm =
              nullable
                (types.listOf (
                  types.enum [
                    "lock"
                    "suspend"
                    "logout"
                    "reboot"
                    "poweroff"
                  ]
                ))
                "Actions in the quick settings power row that fire only after a hold. An empty list turns the hold off.";
            holdMs = nullable types.ints.positive "How long those actions must be held, in milliseconds.";
          };
          polkitAgent = nullable types.bool "Register as the session's polkit authentication agent. Turn off when another agent runs.";
          wallpaper = nullable types.str ''
            Default wallpaper image path (`~/` is expanded). A path set at runtime with
            `dotshell ipc call wallpaper set <path>` takes precedence until `wallpaper clear`.
          '';
          wallpaperTransition =
            nullable
              (types.enum [
                "fade"
                "wipe"
                "circle"
                "dots"
              ])
              "How a new wallpaper replaces the old one: a crossfade, a soft wipe from the left, a circle growing from the center, or dots growing outward from the center.";
          wallpaperFolder = nullable types.str "Folder whose images the settings window offers as wallpapers (`~/` is expanded).";
          commands = {
            settings = nullable (types.listOf types.str) "Command run by the quick settings Settings button instead of opening the settings window.";
            lock = nullable (types.listOf types.str) "Command run by the Lock action instead of the built-in lock screen.";
          };
          keyboardLayouts = nullable (types.attrsOf types.str) ''
            Short labels for niri keyboard layout names, for example `{ "English (US)" = "US"; }`.
            Layouts without a label show their first two letters.
          '';
          urgentColor = nullable types.str "Color of urgent workspace dots in the bar, as `#rrggbb`.";
          clock.caption = nullable types.bool "Show the line under the desktop clock that names its mode and the tap that switches it.";
          bar = {
            position = nullable (types.enum [
              "top"
              "bottom"
            ]) "The screen edge the bar sits on. Panels, tooltips and tray menus open from it.";
            height = nullable (types.ints.between 28 56) "Bar height in logical pixels.";
            edgeScroll = nullable types.bool "Scrolling in the outermost 4 px of the bar steps the volume (right) or brightness (left).";
            show = {
              workspaceCounter = nullable types.bool "Show the `n/N` workspace counter.";
              focusedWindow = nullable types.bool "Show the focused window's app and title.";
              tray = nullable types.bool "Show the system tray.";
              layout = nullable types.bool "Show the keyboard layout.";
              battery = nullable types.bool "Show the battery bay.";
              notifications = nullable types.bool "Show the notifications bay.";
              quickSettings = nullable types.bool "Show the quick settings button.";
            };
          };
          notifications = {
            position = nullable (types.enum [
              "top-left"
              "top-right"
              "bottom-left"
              "bottom-right"
            ]) "The screen corner notification popups appear in.";
            maxPopups = nullable types.ints.positive "How many popups show at once.";
            timeout = nullable types.ints.positive "Seconds a popup stays when the app gives no timeout, or always when `respectAppTimeout` is off.";
            respectAppTimeout = nullable types.bool "Keep a popup as long as its app asks, at least 3 s.";
            criticalTimeout = nullable types.ints.unsigned "Seconds a critical popup stays; 0 keeps it until dismissed.";
          };
          audio.step = nullable types.ints.positive "Volume step in percent per wheel notch over the OSD and at the right edge of the bar. Keys pass their own step in the niri bind.";
          brightness.step = nullable types.ints.positive "Brightness step in percent per wheel notch over the OSD and at the left edge of the bar.";
          osd = {
            lockKeys = nullable types.bool "Show the OSD when Caps Lock, Num Lock or Scroll Lock toggles.";
            layout = nullable types.bool "Show the OSD when the keyboard layout switches.";
            radios = nullable types.bool "Show the OSD when Wi-Fi or Bluetooth is turned on or off outside quick settings.";
            powerMode = nullable types.bool "Show the OSD when the power profile changes outside the battery panel.";
            timeout = nullable types.ints.positive "Milliseconds the OSD stays after the last change.";
            position = nullable (types.enum [
              "bottom"
              "top"
            ]) "The screen edge the OSD appears at.";
          };
          sounds.volumeChange = nullable types.bool "Play a short sound at the new level on volume keys, scrolling over the OSD and while dragging a volume slider.";
          weather = {
            enabled = nullable types.bool "Show the weather in the bar.";
            location = nullable types.str "City for the weather, optionally with a country after a comma (`Paris, France`), or `lat,lon`. Unset hides the weather.";
            units = nullable (types.enum [
              "celsius"
              "fahrenheit"
            ]) "Temperature units.";
            windUnit = nullable (types.enum [
              "auto"
              "kmh"
              "ms"
              "mph"
              "kn"
            ]) "Wind speed units; `auto` follows the temperature units.";
            refreshMinutes = nullable types.ints.positive "Minutes between weather refreshes (at least 5).";
            hideAfterHours = nullable types.ints.positive "Hours after which an old reading is hidden from the bar.";
          };
          launcher = {
            currency = nullable types.bool "Read `10eur usd`, `10k eur usd` or `1.5kk usd to eur` in the launcher as currency conversions, and let qalc refresh its exchange rates over the network when they are stale.";
            showFrequent = nullable types.bool "List the most used apps while the query is empty.";
            frequentCount = nullable types.ints.positive "How many frequent apps to list.";
            appResults = nullable types.ints.positive "How many apps to show for a query.";
            clipboardResults = nullable types.ints.unsigned "How many clipboard matches to show in Search mode.";
            usageHalfLifeDays = nullable types.ints.positive "Days after which an app's launch score halves, so old habits fade from the frequent list.";
          };
          clipboard = {
            enabled = nullable types.bool "Record the clipboard history. Off keeps what is stored.";
            maxEntries = nullable types.ints.positive "Unpinned entries kept.";
            maxTextMiB = nullable types.ints.positive "Largest text entry, in MiB.";
            maxImageMiB = nullable types.ints.positive "Largest image entry, in MiB.";
            ignoreApps = nullable (types.listOf types.str) "App names or ids whose copies are dropped from the history.";
          };
          battery = {
            notifyLow = nullable types.bool "Send a notification when the battery gets low while discharging.";
            notifyAt = nullable (types.ints.between 1 100) "Charge in percent for the low battery notification.";
            criticalAt = nullable (types.ints.between 1 100) "Charge in percent for the critical battery notification.";
            lowThreshold = nullable (types.ints.between 1 100) "Charge in percent at or below which the battery panel shows red while discharging.";
          };
          calendar.weekStart = nullable (types.enum [
            "monday"
            "sunday"
          ]) "First day of the week in the calendar.";
          trayGlyphs = nullable (types.attrsOf types.str) ''
            Tray item ids mapped to dot glyph names. Replaces the built-in map; other items
            show their own icon, desaturated.
          '';
        };
      };
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ cfg.package ];

    xdg.configFile."dotshell/config.json".source = json.generate "dotshell-config.json" (
      withoutNulls cfg.settings
    );

    xdg.configFile."niri/dotshell/rules.kdl" = lib.mkIf cfg.niri.rules {
      source = ../niri/rules.kdl;
    };

    xdg.configFile."niri/dotshell/binds.kdl" = lib.mkIf cfg.niri.binds {
      source = ../niri/binds.kdl;
    };

    systemd.user.services.dotshell = lib.mkIf cfg.systemd.enable {
      Unit = {
        Description = "Dotshell desktop shell";
        PartOf = [ "graphical-session.target" ];
        After = [ "graphical-session.target" ];
      };
      Service = {
        ExecStart = lib.getExe cfg.package;
        Restart = "on-failure";
      };
      Install.WantedBy = [ "graphical-session.target" ];
    };
  };
}
