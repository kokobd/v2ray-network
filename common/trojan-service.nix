{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.trojan;
  trojan = import ./trojan.nix (cfg // { inherit pkgs; });
in
{
  options = {
    services.trojan = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = lib.mdDoc ''
          Whether to enable trojan service
        '';
      };

      configJson = mkOption {
        type = types.str;
      };
    };
  };
  config = mkIf cfg.enable {
    systemd.services.trojan = {
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" "nss-lookup.target" ];
      serviceConfig = {
        User = "root";
        CapabilityBoundingSet = [ "CAP_NET_ADMIN" "CAP_NET_BIND_SERVICE" ];
        AmbientCapabilities = [ "CAP_NET_ADMIN" "CAP_NET_BIND_SERVICE" ];
        LimitNOFILE = "1000000";
        NoNewPrivileges = "true";
        ExecStart = "${trojan}/bin/trojan";
        Restart = "on-failure";
        RestartPreventExitStatus = 23;
      };
    };
  };
}
