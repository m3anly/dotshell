{
  description = "Dotshell: a Quickshell desktop shell for niri";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs =
    { self, nixpkgs }:
    let
      forAllSystems = nixpkgs.lib.genAttrs [
        "x86_64-linux"
        "aarch64-linux"
      ];

      mkPackagesWith =
        {
          pkgs,
          niri ? null,
        }:
        let

          fonts = pkgs.google-fonts.override {
            fonts = [
              "Doto"
              "Space Mono"
            ];
          };

          fontsConf = pkgs.writeText "dotshell-fonts.conf" ''
            <?xml version="1.0"?>
            <!DOCTYPE fontconfig SYSTEM "urn:fontconfig:fonts.dtd">
            <fontconfig>
              <include>${./fontconfig/50-dotshell.conf}</include>
              <include ignore_missing="yes">/etc/fonts/fonts.conf</include>
              <dir>${fonts}/share/fonts</dir>
              <dir>${pkgs.nerd-fonts.jetbrains-mono}/share/fonts</dir>
            </fontconfig>
          '';

          runtimeInputs = [
            pkgs.quickshell
            pkgs.libqalculate
            pkgs.sqlite
            pkgs.pipewire
            pkgs.wl-clipboard
            pkgs.brightnessctl
            pkgs.cava
            pkgs.glib
            pkgs.coreutils
            pkgs.bash
            pkgs.gnugrep
            pkgs.networkmanager
            pkgs.systemd
          ]
          ++ pkgs.lib.optional (niri != null) niri;

          mkLauncher =
            name: shellPath:
            pkgs.writeShellApplication {
              inherit name runtimeInputs;
              text = ''
                base=${shellPath}
                tree="''${XDG_RUNTIME_DIR:-/tmp}/dotshell/$(printf '%s' "$base" | md5sum | cut -c1-12)"
                starts=true
                for arg in "$@"; do
                  case "$arg" in
                    -*) continue ;;
                    ipc | list | kill | log | msg) starts=false ;;
                  esac
                  break
                done
                if $starts; then
                  DOTSHELL_PLUGINS="$(bash ${./nix/plugin-tree.sh} "$base" "''${XDG_CONFIG_HOME:-$HOME/.config}/dotshell/plugins" "$tree")"
                  export DOTSHELL_PLUGINS
                fi
                config="$base"
                if [ -e "$tree/shell.qml" ]; then
                  config="$tree"
                fi
                export FONTCONFIG_FILE=${fontsConf}
                export QS_CONFIG_PATH="$config"
                export DOTSHELL_VOLUME_SOUND=${pkgs.sound-theme-freedesktop}/share/sounds/freedesktop/stereo/audio-volume-change.oga
                exec quickshell "$@"
              '';
            };

          dotshell = mkLauncher "dotshell" ./shell;

          dev = mkLauncher "dotshell-dev" ''"''${DOTSHELL_DIR:-$PWD/shell}"'';

          lint = pkgs.writeShellApplication {
            name = "dotshell-lint";
            runtimeInputs = [
              pkgs.kdePackages.qtdeclarative
              pkgs.coreutils
              pkgs.findutils
              pkgs.gnugrep
              pkgs.gnused
            ];
            text = builtins.readFile ./tools/lint.sh;
            runtimeEnv = {
              QUICKSHELL_QML = "${pkgs.quickshell}/lib/qt-6/qml";
              QT_QML = "${pkgs.kdePackages.qtdeclarative}/lib/qt-6/qml";
            };
          };
        in
        {
          inherit
            dotshell
            fonts
            dev
            lint
            ;
          default = dotshell;
        };

      mkPackages = pkgs: mkPackagesWith { inherit pkgs; };
    in
    {
      lib = { inherit mkPackages mkPackagesWith; };

      packages = forAllSystems (system: mkPackages nixpkgs.legacyPackages.${system});

      apps = forAllSystems (
        system:
        let
          inherit (self.packages.${system}) dev lint;
        in
        {
          dev = {
            type = "app";
            program = "${dev}/bin/dotshell-dev";
            meta.description = "Run the working tree with the packaged environment";
          };
          lint = {
            type = "app";
            program = "${lint}/bin/dotshell-lint";
            meta.description = "Run qmllint against the Quickshell and Qt type info";
          };
          default = self.apps.${system}.dev;
        }
      );

      homeModules.default = import ./nix/home-manager.nix self;

      nixosModules.default = import ./nix/nixos.nix;
    };
}
