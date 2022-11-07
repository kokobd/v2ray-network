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
      (pkgs.buildGo118Module
        rec {
          pname = "v2ray";
          version = "4.45.2";

          src = pkgs.fetchFromGitHub {
            owner = "v2fly";
            repo = "v2ray-core";
            rev = "v${version}";
            sha256 = "sha256-0K9S5r3Bp39Egu6p9PTse9KcaqP5SDDsKEROcM2iPX0=";
          };

          vendorSha256 = "sha256-TbWMbIT578I8xbNsKgBeSP4MewuEKpfh62ZbJIeHgDs=";
          subPackages = [ "main" ];
        })
    else
      (pkgs.buildGo118Module rec {
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
