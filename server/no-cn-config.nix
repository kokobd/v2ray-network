{ pkgs, settings, ... }:

{
  imports = [ ../common/v2ray-service.nix ];
  config = {
    services.v2ray2 = {
      enable = true;
      flavor = "v2fly";
      configJson = ''
        {
          "log": {
            // By default, V2Ray writes access log to stdout.
            // "access": "./log/access",
            // By default, V2Ray write error log to stdout.
            // "error": "./log/error",
            // Log level, one of "debug", "info", "warning", "error", "none"
            "loglevel": "warning"
          },
          // List of inbound proxy configurations.
          "inbounds": [
            {
              "port": ${toString settings.server-no-cn.port},
              "protocol": "vmess",
              "settings": {
                "clients": [
                  {
                    "id": "${settings.userID}",
                    "level": 0
                  }
                ],
                "disableInsecureEncryption": true
              }
            }
          ],
          // List of outbound proxy configurations.
          "outbounds": [
            {
              "tag": "direct",
              "protocol": "freedom"
            },
            {
              "tag": "block",
              "protocol": "blackhole"
            }
          ],
          "routing": {
            "domainStrategy": "AsIs",
            "rules": []
          },
          // Policy controls some internal behavior of how V2Ray handles connections.
          // It may be on connection level by user levels in 'levels', or global settings in 'system.'
          "policy": {
            "system": {
              "statsInboundUplink": true,
              "statsInboundDownlink": true,
              "statsOutboundUplink": true,
              "statsOutboundDownlink": true
            }
          },
          // Stats enables internal stats counter.
          // This setting can be used together with Policy and Api. 
          "stats": {},
          // Api enables gRPC APIs for external programs to communicate with V2Ray instance.
          //"api": {
          //"tag": "api",
          //"services": [
          //  "HandlerService",
          //  "LoggerService",
          //  "StatsService"
          //]
          //},
          // You may add other entries to the configuration, but they will not be recognized by V2Ray.
          "other": {}
        }
      '';
    };
  };
}
