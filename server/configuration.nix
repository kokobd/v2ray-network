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
            "loglevel": "warning"
          },
          "dns": {
            "servers": [
              "https+local://1.1.1.1/dns-query",
              "localhost"
            ]
          },
          "routing": {
            "domainStrategy": "AsIs",
            "rules": [
              {
                "type": "field",
                "ip": [
                  "geoip:private"
                ],
                "outboundTag": "block"
              }
            ]
          },
          "inbounds": [
            {
              "port": ${toString settings.server.port},
              "protocol": "vless",
              "settings": {
                "clients": [
                  {
                    "id": "${settings.userID}",
                    "level": 0,
                    "email": "contact@zelinf.net"
                  }
                ],
                "decryption": "none",
                "fallbacks": [
                  {
                    "dest": "site:8080"
                  }
                ]
              },
              "streamSettings": {
                "network": "tcp",
                "security": "tls",
                "tlsSettings": {
                  "allowInsecure": false,
                  "minVersion": "1.2",
                  "alpn": [
                    "http/1.1"
                  ],
                  "certificates": [
                    {
                      "certificateFile": "${settings.server.tls.certificateFile}",
                      "keyFile": "${settings.server.tls.keyFile}"
                    }
                  ]
                }
              }
            }
          ],
          "outbounds": [
            {
              "tag": "direct",
              "protocol": "freedom"
            },
            {
              "tag": "block",
              "protocol": "blackhole"
            }
          ]
        }
      '';
    };
  };
}
