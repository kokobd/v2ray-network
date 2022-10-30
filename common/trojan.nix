# This is a home-manager module for v2ray

{ pkgs ? import <nixpkgs> { }
, configJson ? ""
, ...
}:

with pkgs.lib;

let
  trojan = pkgs.stdenv.mkDerivation rec {
    pname = "trojan";
    version = "1.16.0";

    src = pkgs.fetchFromGitHub {
      owner = "trojan-gfw";
      repo = "trojan";
      rev = "v${version}";
      sha256 = "sha256-fCoZEXQ6SL++QXP6GlNYIyFaVhQ8EWelJ33VbYiHRGw=";
    };

    buildInputs = with pkgs; [
      cmake
      boost
      openssl.dev
      libmysqlclient.dev
    ];

    configurePhase = ''
      mkdir build
      cd build
      cmake -DMYSQL_INCLUDE_DIR=${pkgs.libmysqlclient.dev}/include/mysql ..
    '';

    buildPhase = ''
      make -j
    '';

    installPhase = ''
      mkdir -p $out/bin
      mv trojan $out/bin
    '';
  };
  configFile = pkgs.writeTextFile {
    name = "config.json";
    text = configJson;
  };
in
pkgs.writeScriptBin "trojan" ''
  #!${pkgs.bash}/bin/bash 
  ${trojan}/bin/trojan -c ${configFile}
''
