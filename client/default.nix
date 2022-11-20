{ pkgs, settings, ... }:

let
  v2rayOutbound =
    if trojan == null
    then ''
      {
        "tag": "primary",
        "protocol": "vmess",
        "settings": {
          "vnext": [
            {
              "address": "${settings.transit.ip}",
              "port": ${toString settings.transit.port},
              "users": [
                {
                  "id": "${settings.userID}",
                  "alterId": 0,
                  "security": "auto",
                  "level": 0
                }
              ]
            }
          ]
        }
      },
    '' else ''
    {
      "tag": "primary",
      "protocol": "socks",
      "settings": {
        "servers": [
          {
            "address": "127.0.0.1",
            "port": ${toString settings.trojan.localPort}
          }
        ]
      }
    },
  '';

  v2ray = import ../common/v2ray.nix
    {
      inherit pkgs;
      flavor = "v2fly";
      configJson = ''
        // Config file of V2Ray. This file follows standard JSON format, with comments support.
        // Uncomment entries below to satisfy your needs. Also read our manual for more detail at
        // https://www.v2fly.org/
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
              "listen": "${settings.client.ip}",
              "port": ${toString settings.client.socksPort},
              "protocol": "socks",
              "settings": {
                "auth": "noauth",
                "udp": true,
                "userLevel": 0
              }
            },
            {
              "listen": "${settings.client.ip}",
              "port": ${toString settings.client.httpPort},
              "protocol": "http"
            }
          ],
          // List of outbound proxy configurations.
          "outbounds": [
            ${v2rayOutbound}
            {
              "tag": "direct",
              "protocol": "freedom",
              "settings": {
                "domainStrategy": "UseIP"
              }
            },
            {
              "tag": "dns",
              "protocol": "dns"
            },
            {
              "tag": "block",
              "protocol": "blackhole"
            }
          ],
          "routing": {
            "domainStrategy": "IPOnDemand",
            "domainMatcher": "mph",
            "rules": [
              { // 劫持 53 端口 UDP 流量，使用 V2Ray 的 DNS
                "type": "field",
                "inboundTag": [
                  "transparent"
                ],
                "port": 53,
                "network": "udp",
                "outboundTag": "dns"
              },
              { // 直连 123 端口 UDP 流量（NTP 协议）
                "type": "field",
                "inboundTag": [
                  "transparent"
                ],
                "port": 123,
                "network": "udp",
                "outboundTag": "direct"
              },
              {
                "type": "field",
                "ip": [
                  // 设置 DNS 配置中的国内 DNS 服务器地址直连，以达到 DNS 分流目的
                  "223.5.5.5",
                  "114.114.114.114"
                ],
                "outboundTag": "direct"
              },
              {
                "type": "field",
                "ip": [
                  // 设置 DNS 配置中的国外 DNS 服务器地址走代理，以达到 DNS 分流目的
                  "8.8.8.8",
                  "1.1.1.1"
                ],
                "outboundTag": "primary"
              },
              { // BT 流量直连
                "type": "field",
                "protocol": [
                  "bittorrent"
                ],
                "outboundTag": "direct"
              },
              {
                // 机场直连
                "type": "field",
                "domains": [
                  "domain:nigirocloud.com"
                ],
                "outboundTag": "direct"
              },
              {
                "type": "field",
                "ip": [
                  "74.211.99.199" // my v2ray server
                ],
                "outboundTag": "direct"
              },
              {
                "domainMatcher": "mph",
                "type": "field",
                "ip": [
                  "geoip:cn",
                  "geoip:private"
                ],
                "outboundTag": "direct"
              },
              {
                "type": "field",
                "domainMatcher": "mph",
                "domains": [
                  "geosite:cn",
                  "domain:bytedance.net",
                  "domain:byted.org",
                  "domain:bytedance.com",
                  "domain:bwg.net"
                ],
                "outboundTag": "direct"
              }
            ]
          },
          "dns": {
            "servers": [
              "8.8.8.8", // Google DNS
              "1.1.1.1", // Cloudflare DNS
              "114.114.114.114", // 114 的 DNS (备用)
              {
                "address": "223.5.5.5", //中国大陆域名使用阿里的 DNS
                "port": 53,
                "domains": [
                  "geosite:cn",
                  "domain:ntp.org",
                  "domain:nigirocloud.com"
                ]
              }
            ]
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
  trojan =
    if builtins.hasAttr "trojan" settings
    then
      import ../common/trojan.nix
        {
          inherit pkgs;
          configJson = settings.trojan.configJson;
        } else null;
in
if trojan != null
then pkgs.writeScriptBin "v2ray" 
''
  ${trojan}/bin/trojan &
  P1=$!
  ${v2ray}/bin/v2ray
  kill $P1
''
else v2ray