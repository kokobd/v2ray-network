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
                    "dest": "127.0.0.1:${toString settings.server.sitePort}"
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

    systemd.services.v2ray-site =
      let
        indexHtml = pkgs.writeTextFile {
          name = "index.html";
          text = ''
            <!DOCTYPE html>
            <html lang="en">

            <head>
              <meta charset="UTF-8">
              <meta http-equiv="X-UA-Compatible" content="IE=edge">
              <meta name="viewport" content="width=device-width, initial-scale=1.0">
              <title>Hello</title>
            </head>

            <body>
              <div>The site is still under construction. Main page is not accessible. Please access specific paths directly.</div>
            </body>

            </html>
          '';
        };

        site = pkgs.writeScriptBin "v2ray-site" ''
          #!${pkgs.bash}/bin/bash

          ${pkgs.miniserve}/bin/miniserve -i 127.0.0.1 -p ${toString settings.server.sitePort} ${indexHtml}
        '';
      in
      {
        wantedBy = [ "multi-user.target" ];
        after = [ "network.target" "nss-lookup.target" ];
        serviceConfig = {
          User = "root";
          NoNewPrivileges = "true";
          ExecStart = "${site}/bin/v2ray-site";
          Restart = "on-failure";
        };
      };
  };
}
