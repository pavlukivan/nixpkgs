{ config, lib, pkgs, ... }:

let
  cfg = config.networking.modemmanager;
  packages = [ pkgs.modemmanager ];

  /*
    [modem-manager]
    Identity=unix-group:networkmanager
    Action=org.freedesktop.ModemManager*
    ResultAny=yes
    ResultInactive=no
    ResultActive=yes
  */
  polkitConf = ''
    polkit.addRule(function(action, subject) {
      if (subject.isInGroup("networkmanager") && action.id.indexOf("org.freedesktop.ModemManager") == 0) {
        return polkit.Result.YES;
      }
    });
  '';

in
{

  meta = {
    maintainers = lib.teams.freedesktop.members;
  };

  options.networking.modemmanager = {
    enable = lib.mkEnableOption "ModemManager" // {
      default = config.networking.networkmanager.enable;
      defaultText = lib.literalExpression "config.networking.networkmanager.enable";
    };

    fccUnlockScripts = lib.mkOption {
      type = lib.types.listOf (lib.types.submodule {
        options = {
          id = lib.mkOption {
            type = lib.types.str;
            description = lib.mdDoc "vid:pid of either the PCI or USB vendor and product ID";
          };
          path = lib.mkOption {
            type = lib.types.path;
            description = lib.mdDoc "Path to the unlock script";
          };
        };
      });
      default = [ ];
      example = lib.literalExpression ''[{ name = "03f0:4e1d"; script = "''${pkgs.modemmanager}/share/ModemManager/fcc-unlock.available.d/03f0:4e1d"; }]'';
      description = lib.mdDoc ''
        List of FCC unlock scripts to enable on the system, behaving as described in
        https://modemmanager.org/docs/modemmanager/fcc-unlock/#integration-with-third-party-fcc-unlock-tools.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    environment.etc =
      builtins.listToAttrs (map
        ({ id, path }: lib.nameValuePair "ModemManager/fcc-unlock.d/${id}" {
          source = path;
        })
        cfg.fccUnlockScripts);

    # use networkmanager group for compatibility with old NixOS configurations
    # (and to save 1 gid in ids.gids)
    users.groups.networkmanager.gid = config.ids.gids.networkmanager;

    systemd.services.ModemManager.aliases = [ "dbus-org.freedesktop.ModemManager1.service" ];

    security.polkit.enable = true;
    security.polkit.extraConfig = polkitConf;

    environment.systemPackages = packages;
    systemd.packages = packages;
    services.udev.packages = packages;
  };
}
