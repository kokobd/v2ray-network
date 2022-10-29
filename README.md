# v2ray-network

A v2ray network configuration

## Prepare Settings

Create a `settings.nix` file next to `flake.nix`. You need to `mv .git .git.bak` before
running `nix build` or `nixos-rebuild`

```
{
  # generate one with https://www.uuidgenerator.net/version4
  userId = "xxxx-xxxx-xxxx-xxxx-xxxx";

  # Settings for the server outside China
  # Clients connects to this server through VLess protocol
  server = {
    ip = "1.1.1.1";
    port = 443;
    tls = {
      # use the paths to your own certificate files
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

  # Settings for the gateway in your local network
  gateway = {
    # local ip
    ip = "192.168.31.4";
    # prefix length for your local network
    prefixLength = 16;
    # router local ip
    router = "192.168.31.1";
  };
}
```

## Server

Install on a non-NixOS Linux server:

```sh
nix build .#server
nix-env -i ./result
sudo ln -s $HOME/.nix-profile/v2ray.service /etc/systemd/system/v2ray.service
sudo systemctl daemon-reload
```

## Gateway

Install it in a dedicated NixOS machine. You may use a virtual machine.

Remember:
1. Use bridged network.
2. The gateway affects all devices that connects to the same router
3. Set the gateway ip to this server in your router settings


Steps:

Enable nix flakes. Add this line to your `configuration.nix` file
```
nix.settings.experimental-features = [ "nix-command" "flakes" ];
```

Switch to the root user, and change to `/etc` directory
```sh
sudo su
cd /etc
```

Get the sources
```sh
curl TODO
mv nixos nixos-bak
```

Copy your existing `hardware-configuration.nix`

```sh
cp nixos-bak/hardware-configuration.nix nixos/client/gateway
```

Rebuild NixOS
```sh
nixos-rebuild switch
```

## Client

```sh
nix run .#client
```