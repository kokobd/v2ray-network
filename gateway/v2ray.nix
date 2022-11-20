{ pkgs, settings, ... }:

let
  useTrojan = builtins.hasAttr "trojan" settings;
  v2rayOutbound =
    if useTrojan then
      ''
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
      '' else ''
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
        },
        "streamSettings": {
          "sockopt": {
            "mark": 255
          }
        }
      },
    '';
in
{
  imports = [
    ../common/v2ray-service.nix
    ../common/trojan-service.nix
    ./firewall.nix
  ];
  config = {
    services = {
      v2ray2 = {
        enable = true;
        flavor = "xray";
        configJson = ''
          {
            "log": {
              // By default, V2Ray writes access log to stdout.
              // "access": "/var/log/v2ray/access",
              // "access": "/dev/null",
              // By default, V2Ray write error log to stdout.
              // "error": "/var/log/v2ray/error",
              // Log level, one of "debug", "info", "warning", "error", "none"
              "loglevel": "info"
            },
            // List of inbound proxy configurations.
            "inbounds": [
              {
                "tag": "transparent",
                "port": 12345,
                "protocol": "dokodemo-door",
                "settings": {
                  "network": "tcp,udp",
                  "followRedirect": true
                },
                "sniffing": {
                  "enabled": true,
                  "destOverride": [
                    "http",
                    "tls"
                  ],
                  "domainsExcluded": [
                    "mijia cloud"
                  ]
                },
                "streamSettings": {
                  "sockopt": {
                    "tproxy": "tproxy", // 透明代理使用 TPROXY 方式
                    "mark": 255
                  }
                }
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
                },
                "streamSettings": {
                  "sockopt": {
                    "mark": 255
                  }
                }
              },
              {
                "tag": "dns",
                "protocol": "dns",
                "streamSettings": {
                  "sockopt": {
                    "mark": 255
                  }
                }
              },
              {
                "tag": "block",
                "protocol": "blackhole",
                "streamSettings": {
                  "sockopt": {
                    "mark": 255
                  }
                }
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
                    "domain:nigirocloud.com",
                    "domain:s6CDpr2exuznjPB9UszE.ganode.org"
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
                    // "geosite:playstation",
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
                "114.114.114.114",
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
    } // (if useTrojan
    then {
      trojan = {
        enable = true;
        configJson = settings.trojan.configJson;
      };
    } else { });
  };
}
