{ config, lib, ... }:
let
  cfg = config.programs.dotshell;

  missing =
    enabled: feature: service:
    lib.optional (!enabled) "programs.dotshell: ${feature} need ${service}, which is not enabled.";
in
{
  options.programs.dotshell.enable = lib.mkEnableOption "the system services Dotshell talks to (UPower, power-profiles-daemon, polkit)";

  config = lib.mkIf cfg.enable {
    services.upower.enable = lib.mkDefault true;
    services.power-profiles-daemon.enable = lib.mkDefault (
      !(config.services.tlp.enable || config.services.auto-cpufreq.enable)
    );
    security.polkit.enable = lib.mkDefault true;

    warnings = lib.concatLists [
      (missing config.services.pipewire.enable "volume controls, the volume sound and the visualizer"
        "PipeWire (services.pipewire)"
      )
      (missing config.networking.networkmanager.enable "the Wi-Fi list and toggle"
        "NetworkManager (networking.networkmanager)"
      )
    ];
  };
}
