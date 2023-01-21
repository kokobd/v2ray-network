{ pkgs
, nixos
, system
, settings
, ...
}:

let
  eval = nixos {
    inherit system;
    modules = [ ./v2ray.nix ];
    specialArgs = { inherit settings; };
  };
in
pkgs.buildEnv {
  name = "v2ray";
  paths = [
    eval.config.systemd.units."v2ray.service".unit
    eval.config.systemd.units."firewall.service".unit
  ];
}
