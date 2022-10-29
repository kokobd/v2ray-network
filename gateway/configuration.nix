{ config, pkgs, settings, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./firewall.nix
    ./v2ray.nix
  ];

  boot.loader = {
    systemd-boot.enable = true;
    efi.canTouchEfiVariables = true;
  };
  time.timeZone = "Asia/Shanghai";
  i18n.defaultLocale = "en_US.UTF-8";

  environment.systemPackages = with pkgs; [
    vim
    nettools
  ];
  programs.vim.defaultEditor = true;
  services.sshd.enable = false;

  users = {
    mutableUsers = false;
    users = {
      nixos = {
        isNormalUser = true;
        extraGroups = [ "networkmanager" "wheel" ];
        # password: 123456
        hashedPassword =
          "$6$6UGWtajWYG5CuWZx$Cs9ay6MriTeZX7t1Z6DMDct9OnAf2hLDZIuKjs0yV6pRURWAWMp1.o7sg1mWx46eC4HfD/BjkSqkdkez/U2Ov/";
      };
    };
  };

  networking =
    {
      hostName = "gateway";

      interfaces.eth0 = {
        useDHCP = false;

        ipv4.addresses = [{
          address = settings.gateway.ip;
          prefixLength = settings.gateway.prefixLength;
        }];
      };

      defaultGateway = settings.gateway.router;
      nameservers = [ "8.8.8.8" ];
    };

  system.stateVersion = "22.05";
}
