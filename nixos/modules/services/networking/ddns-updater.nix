{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.ddns-updater;

  settingsFormat = pkgs.formats.json { };
  configFile = settingsFormat.generate "config.json" cfg.settings;
in
{
  options.services.ddns-updater = {
    enable = lib.mkEnableOption "ddns-updater";

    package = lib.mkPackageOption pkgs "ddns-updater" { };

    environment = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      description = "Environment variables to be set for the ddns-updater service. DATADIR is ignored to enable using systemd DynamicUser. For full list see <https://github.com/qdm12/ddns-updater>";
      default = { };
    };

    settings = lib.mkOption {
      type = settingsFormat.type;
      description = "Configuration for ddns-updater, see <https://github.com/qdm12/ddns-updater#configuration> for supported values.";
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.services.ddns-updater = {
      description = "DDNS-updater service";
      wantedBy = [ "multi-user.target" ];
      wants = [ "network-online.target" ];
      after = [ "network-online.target" ];
      environment = cfg.environment // {
        DATADIR = "%S/ddns-updater";
      };
      preStart = lib.mkIf (cfg.settings != { }) ''
        ln -sf ${configFile} "$DATADIR/config.json"
      '';
      serviceConfig = {
        TimeoutSec = "5min";
        ExecStart = lib.getExe cfg.package;
        RestartSec = 30;
        DynamicUser = true;
        StateDirectory = "ddns-updater";
        Restart = "on-failure";
      };
    };
  };

  meta.maintainers = with lib.maintainers; [ lord-valen ];
}
