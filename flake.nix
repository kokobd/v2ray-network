{
  description = "v2ray configurations";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = inputs@{ self, nixpkgs, flake-utils }:
    with flake-utils.lib;
    let
      settings = import ./settings.nix;
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

      packages."${system.x86_64-linux}" =
        let
          params = {
            pkgs = nixpkgs.legacyPackages."${system.x86_64-linux}";
            nixos = nixpkgs.lib.nixosSystem;
            system = system.x86_64-linux;
            inherit settings;
          };
        in
        {
          server = import ./server params;

          server-no-cn = import ./server/no-cn.nix params;

          transit = import ./transit params;
        };

      apps."${system.x86_64-linux}" = {
        client = mkClient system.x86_64-linux "v2ray" ./client;
      };
      apps."${system.aarch64-darwin}" = {
        client = mkClient system.aarch64-darwin "v2ray" ./client;
      };
    };
}
