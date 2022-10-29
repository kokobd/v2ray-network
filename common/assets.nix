{ pkgs }:

let
  assets = pkgs.symlinkJoin
    {
      name = "v2ray-assets";
      paths = [ pkgs.v2ray-geoip pkgs.v2ray-domain-list-community ];
    };
in
"${assets}/share/v2ray"
