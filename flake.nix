{
  description = "v2ray configurations";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = inputs@{ self, nixpkgs, flake-utils }:
    with flake-utils.lib;
    {
      lib = settings:
        {
          nixosConfigurations =
            {
              gateway-hyperV = nixpkgs.lib.nixosSystem {
                system = system.x86_64-linux;
                specialArgs = { inherit settings; };
                modules = [ ./gateway/machines/hyper-v.nix ];
              };

              gateway-respberryPi3BP = nixpkgs.lib.nixosSystem {
                system = system.aarch64-linux;
                specialArgs = { inherit settings; };
                modules = [ ./gateway/machines/raspberryPi3BP.nix ];
              };
            };
          nixosModules = {
            gateway = import ./gateway/v2ray.nix;
          };
        } //
        eachDefaultSystem (system:
          let
            mkClient = system: name: path:
              let
                client = import path
                  {
                    pkgs = nixpkgs.legacyPackages."${system}";
                    inherit settings;
                  };
              in
              {
                type = "app";
                program = "${client}/bin/${name}";
              };
          in
          {
            packages =
              let
                params = {
                  pkgs = nixpkgs.legacyPackages.${system};
                  nixos = nixpkgs.lib.nixosSystem;
                  system = system;
                  inherit settings;
                };
              in
              {
                server = import ./server params;

                server-no-cn = import ./server/no-cn.nix params;

                gateway = import ./gateway/env.nix params;

                transit = import ./transit params;
              };
            apps = {
              client = mkClient system "v2ray" ./client;
            };
          }
        );
    };
}
