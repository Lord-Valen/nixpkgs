{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.ddns-updater;

  filteredEnvironment = lib.filterAttrs (_: v: v != null) cfg.environment;

  settingsFormat = pkgs.formats.json { };
  configFile = settingsFormat.generate "config.json" cfg.settings;
in
{
  options.services.ddns-updater = {
    enable = lib.mkEnableOption "ddns-updater";

    package = lib.mkPackageOption pkgs "ddns-updater" { };

    environment = lib.mkOption {
      type = lib.types.submodule {
        freeformType = lib.types.attrsOf lib.types.str;

        options.CONFIG = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          default = null;
          description = "Configuration as a single environment variable. Takes precedence over config.json.";
        };

        options.DATADIR = lib.mkOption {
          type = lib.types.str;
          default = "%S/ddns-updater";
          description = "Data directory for ddns-updater. Defaults to the systemd state directory.";
        };
      };
      description = "Environment variables for ddns-updater, see <https://github.com/qdm12/ddns-updater#environment-variables> for supported values.";
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
      environment = filteredEnvironment;
      # CONFIG and settings must not be mutually exclusive: users may set
      # `CONFIG = builtins.toJSON cfg.settings` to pass structured settings
      # via environment variable instead of a file.
      preStart = lib.mkIf (cfg.environment.CONFIG == null && cfg.settings != { }) ''
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
