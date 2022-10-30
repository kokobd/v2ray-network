{
  description = "v2ray configurations";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-22.05";
    flake-utils.url = "github:numtide/flake-utils";
    # agenix = {
    #   url = "github:ryantm/agenix";
    #   inputs.nixpkgs.follows = "nixpkgs";
    # };
  };

  outputs = inputs@{ self, nixpkgs, flake-utils }:
    with flake-utils.lib;
    let
      settings = import ./settings.nix;
      mkClient = system:
        let
          client = import ./client
            {
              pkgs = nixpkgs.legacyPackages."${system}";
              inherit settings;
            };
        in
        {
          type = "app";
          program = "${client}/bin/v2ray";
        };
    in
    {
      nixosConfigurations =
        {
          gateway = nixpkgs.lib.nixosSystem {
            system = system.x86_64-linux;
            specialArgs = { inherit inputs; inherit settings; };
            modules = [ ./gateway/configuration.nix ];
          };
        };

      packages."${system.x86_64-linux}" = {
        server = import ./server
          {
            pkgs = nixpkgs.legacyPackages."${system.x86_64-linux}";
            nixos = nixpkgs.lib.nixosSystem;
            system = system.x86_64-linux;
            inherit settings;
          };

        transit = import ./transit
          {
            pkgs = nixpkgs.legacyPackages."${system.x86_64-linux}";
            nixos = nixpkgs.lib.nixosSystem;
            system = system.x86_64-linux;
            inherit settings;
          };
      };

      apps."${system.x86_64-linux}".client = mkClient system.x86_64-linux;
      apps."${system.aarch64-darwin}".client = mkClient system.aarch64-darwin;
    };
}
