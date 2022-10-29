{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.v2ray2;
  v2ray = import ./v2ray.nix (cfg // { inherit pkgs; });
in
{
  options = {
    services.v2ray2 = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = lib.mdDoc ''
          Whether to enable v2ray service
        '';
      };

      flavor = mkOption {
        type = types.str;
        default = "v2fly";
        example = [ "v2fly" "xray" ];
      };

      configJson = mkOption {
        type = types.str;
      };
    };
  };
  config = mkIf cfg.enable {
    systemd.services.v2ray = {
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" "nss-lookup.target" ];
      serviceConfig = {
        User = "root";
        CapabilityBoundingSet = [ "CAP_NET_ADMIN" "CAP_NET_BIND_SERVICE" ];
        AmbientCapabilities = [ "CAP_NET_ADMIN" "CAP_NET_BIND_SERVICE" ];
        LimitNOFILE = "1000000";
        NoNewPrivileges = "true";
        ExecStart = "${v2ray}/bin/v2ray";
        Restart = "on-failure";
        RestartPreventExitStatus = 23;
      };
    };
  };
}
