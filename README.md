# v2ray-network

A v2ray network configuration

## Prepare Settings

Create a `settings.nix` file next to `flake.nix`. You need to `mv .git .git.bak` before
running `nix build` or `nixos-rebuild`

```
{
  # generate one with https://www.uuidgenerator.net/version4
  userID = "xxxx-xxxx-xxxx-xxxx-xxxx";

  # Settings for the server outside China
  # Clients connects to this server through VLess protocol
  server = {
    ip = "1.1.1.1";
    port = 443;
    sitePort = 8080;
    tls = {
      # Use the paths to your own certificate files
      certificateFile = "/etc/letsencrypt/live/site.example.com/fullchain.pem";
      keyFile = "/etc/letsencrypt/live/site.example.com/privkey.pem";
    };
  };

  # Settings for the server inside China
  # Clients connect to this server through VMess protocol
  transit = {
    ip = "2.2.2.2";
    port = 12345;
  };

  # If this is defined, gateway and client will connect to the backup trojan service
  trojan = {
    localPort = 1081;
    configJson = ''
    '';
  };

  # Settings for the gateway in your local network
  gateway = {
    # local ip
    ip = "192.168.31.4";
    # prefix length of your local network
    prefixLength = 16;
    # router local ip
    router = "192.168.31.1";
    localNetworkRange = "192.168.0.0/16";
  };

  client = {
    # The address to listen to. If you want other services on the local network to
    # access it, use the local network ip, such as 192.168.31.110
    ip = "127.0.0.1";
    # port of http proxy
    httpPort = 8118;
    # port of socks proxy
    socksPort = 1080;
  };
}
```

## Server

Install on a non-NixOS Linux server:

```sh
nix build .#server
nix-env -i ./result
sudo ln -s $HOME/.nix-profile/v2ray.service /etc/systemd/system/v2ray.service
sudo ln -s $HOME/.nix-profile/v2ray-site.service /etc/systemd/system/v2ray-site.service
# add v2ray.service to the wants list of multi-uesr.target
# you may use 'systemctl status multi-user.target' to find the location of multi-user.target
sudo ln -s $HOME/.nix-profile/v2ray.service /lib/systemd/system/multi-user.target.wants/v2ray.service
sudo ln -s $HOME/.nix-profile/v2ray-site.service /lib/systemd/system/multi-user.target.wants/v2ray-site.service
sudo systemctl daemon-reload
sudo systemctl start v2ray
sudo systemctl start v2ray-site
```

## Transit

Use `nix build .#transit` to build the systemd service, then follow the steps in [Server](#Server), except
that `v2ray-site.service` is not needed.

## Gateway

Install it in a dedicated NixOS machine. You may use a virtual machine.

Remember:
1. Use bridged network.
2. The gateway affects all devices that connects to the same router
3. Set the gateway ip to this server in your router settings

Import `v2ray-network` in your own flake.

Example:

```nix
{
  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
    v2ray-network.url = "github:kokobd/v2ray-network/gateway-machines";
    v2ray-network.inputs.nixpkgs.follows = "nixpkgs";
  };
  
  outputs = { self, nixpkgs, v2ray-network, ...}: {
    nixosConfigurations.gateway = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = { settings = import ./settings.nix; };
      modules = [ ./configuration.nix v2ray-network.nixosModules.gateway ];
    };
  };
}
```

## Client

```sh
nix run .#client
```

Then configure your system proxy settings to use the provided http or socks proxy.

Example for configuring command line programs:
```
export http_proxy=http://127.0.0.1:8118 https_proxy=$http_proxy
export socks_proxy=socks://127.0.0.1:1080/
```
