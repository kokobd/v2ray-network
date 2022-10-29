{ config, pkgs, ... }:

let
  ipCmd = "${pkgs.iproute2}/bin/ip";
  iptablesCmd = "${pkgs.iptables}/bin/iptables";
in
{
  networking.firewall = {
    enable = true;
    trustedInterfaces = [ "eth0" "lo" ];

    extraCommands = ''
      # 设置策略路由
      ${ipCmd} rule del fwmark 1 table 100 || true
      ${ipCmd} rule add fwmark 1 table 100
      ${ipCmd} route del local 0.0.0.0/0 dev lo table 100 || true
      ${ipCmd} route add local 0.0.0.0/0 dev lo table 100

      ${iptablesCmd} -t mangle -F
      # 代理局域网设备
      ${iptablesCmd} -t mangle -N V2RAY || true
      ${iptablesCmd} -t mangle -A V2RAY -d 127.0.0.1/32 -j RETURN
      ${iptablesCmd} -t mangle -A V2RAY -d 224.0.0.0/4 -j RETURN 
      ${iptablesCmd} -t mangle -A V2RAY -d 255.255.255.255/32 -j RETURN 
      ${iptablesCmd} -t mangle -A V2RAY -d 192.168.0.0/16 -p tcp -j RETURN # 直连局域网，避免 V2Ray 无法启动时无法连网关的 SSH，如果你配置的是其他网段（如 10.x.x.x 等），则修改成自己的
      ${iptablesCmd} -t mangle -A V2RAY -d 192.168.0.0/16 -p udp ! --dport 53 -j RETURN # 直连局域网，53 端口除外（因为要使用 V2Ray 的 DNS)
      ${iptablesCmd} -t mangle -A V2RAY -j RETURN -m mark --mark 0xff    # 直连 SO_MARK 为 0xff 的流量(0xff 是 16 进制数，数值上等同与上面V2Ray 配置的 255)，此规则目的是解决v2ray占用大量CPU（https://github.com/v2ray/v2ray-core/issues/2621）
      ${iptablesCmd} -t mangle -A V2RAY -p udp -j TPROXY --on-ip 127.0.0.1 --on-port 12345 --tproxy-mark 1 # 给 UDP 打标记 1，转发至 12345 端口
      ${iptablesCmd} -t mangle -A V2RAY -p tcp -j TPROXY --on-ip 127.0.0.1 --on-port 12345 --tproxy-mark 1 # 给 TCP 打标记 1，转发至 12345 端口
      ${iptablesCmd} -t mangle -A PREROUTING -j V2RAY # 应用规则

      # 代理网关本机
      ${iptablesCmd} -t mangle -N V2RAY_MASK || true
      ${iptablesCmd} -t mangle -A V2RAY_MASK -d 224.0.0.0/4 -j RETURN 
      ${iptablesCmd} -t mangle -A V2RAY_MASK -d 255.255.255.255/32 -j RETURN 
      ${iptablesCmd} -t mangle -A V2RAY_MASK -d 192.168.0.0/16 -p tcp -j RETURN # 直连局域网
      ${iptablesCmd} -t mangle -A V2RAY_MASK -d 192.168.0.0/16 -p udp ! --dport 53 -j RETURN # 直连局域网，53 端口除外（因为要使用 V2Ray 的 DNS）
      ${iptablesCmd} -t mangle -A V2RAY_MASK -j RETURN -m mark --mark 0xff    # 直连 SO_MARK 为 0xff 的流量(0xff 是 16 进制数，数值上等同与上面V2Ray 配置的 255)，此规则目的是避免代理本机(网关)流量出现回环问题
      ${iptablesCmd} -t mangle -A V2RAY_MASK -p udp -j MARK --set-mark 1   # 给 UDP 打标记，重路由
      ${iptablesCmd} -t mangle -A V2RAY_MASK -p tcp -j MARK --set-mark 1   # 给 TCP 打标记，重路由
      ${iptablesCmd} -t mangle -A OUTPUT -j V2RAY_MASK # 应用规则

      # 新建 DIVERT 规则，避免已有连接的包二次通过 TPROXY，理论上有一定的性能提升
      ${iptablesCmd} -t mangle -N DIVERT || true
      ${iptablesCmd} -t mangle -A DIVERT -j MARK --set-mark 1
      ${iptablesCmd} -t mangle -A DIVERT -j ACCEPT
      ${iptablesCmd} -t mangle -I PREROUTING -p tcp -m socket -j DIVERT
    '';
  };
}
