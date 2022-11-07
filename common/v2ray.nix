# This is a home-manager module for v2ray

{ pkgs ? import <nixpkgs> { }
, flavor ? "v2fly"
, configJson ? ""
, ...
}:

with pkgs.lib;

let
  v2ray =
    if flavor == "v2fly"
    then
      (pkgs.buildGo119Module
        rec {
          pname = "v2ray";
          version = "5.1.0";

          src = pkgs.fetchFromGitHub {
            owner = "v2fly";
            repo = "v2ray-core";
            rev = "v${version}";
            sha256 = "sha256-87BtyaJN6qbinZQ+6MAwaK62YzbVnncj4qnEErG5tfA=";
          };

          vendorSha256 = "sha256-RuDCAgTzqwe5fUwa9ce2wRx4FPT8siRLbP7mU8/jg/Y=";
          subPackages = [ "main" ];
        })
    else
      (pkgs.buildGo119Module rec {
        pname = "v2ray";
        version = "1.6.3";

        src = pkgs.fetchFromGitHub {
          owner = "XTLS";
          repo = "Xray-core";
          rev = "v${version}";
          sha256 = "sha256-akJFqWKDwTsKz3wXDuQRIZf5in15+68PXKbUcyoH+YA=";
        };

        vendorSha256 = "sha256-tMF2Xmatj4LRFodi5/vovjGx0S4+42NtK1FNrc0PxR0=";
        subPackages = [ "main" ];
      });

  assets = pkgs.symlinkJoin {
    name = "v2ray-assets";
    paths = [ pkgs.v2ray-geoip pkgs.v2ray-domain-list-community ];
  };
  configFile = pkgs.writeTextFile {
    name = "config.json";
    text = configJson;
  };
  wrapper = pkgs.writeScriptBin "v2ray" ''
    #!${pkgs.bash}/bin/bash

    export V2RAY_LOCATION_ASSET=${assets}/share/v2ray
    export XRAY_LOCATION_ASSET=${assets}/share/v2ray
    ${v2ray}/bin/main -c ${configFile}
  '';
in
wrapper
