{
  config,
  lib,
  pkgs,
  ...
}:

  #Imports

let
  nixvim = import(builtins.fetchGit {
    url = "https://github.com/nix-community/nixvim";
    ref = "nixos-26.05";
    });
in

{
  imports = [
    ./hardware-configuration.nix
    nixvim.nixosModules.nixvim
  ];

  #Configs

  nixpkgs.config.allowUnfree = true;

  #IDE Config
  programs.nixvim = {
    enable = true;
    opts = {
      number = true;
      };
    };

  #Bootloader
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  #DateTime
  time.timeZone = "America/New_York";

  #Keymaps
  services.xserver.xkb.layout = "us";
  services.xserver.xkb.options = "caps:escape";

  #Default User
  users.defaultUserShell = pkgs.zsh;
  users.users.sasha = {
    isNormalUser = true;
    useDefaultShell = true;
    extraGroups = [ "wheel" "data" ];
    homeMode = "0755";
    packages = with pkgs; [
    ];
  };

  #Groups / Access
  users.groups.data = { };
  systemd.tmpfiles.rules = [
    "d /data 0775 root data -"
    "d /data/pictures 2775 sasha data -"
    "d /data/movies 2775 sasha data -"
    "d /data/shows 2775 sasha data -"
    "d /data/music 2775 sasha data -"
    "d /data/books 2775 sasha data -"
    "d /data/xxx 2775 sasha data -"
    "d /data/unsorted 2775 sasha data -"
    "d /data/files 2775 sasha data -"
    "d /data/.Private 2775 sasha data -"
    "d /data/videos 2775 sasha data -"
    ];

  #Packages
  environment.systemPackages = with pkgs; [
    vim # utilites
    wget # utilities
    tree # utilities
    eza # utilites
    zsh # shell
    git # version control
    neovim # text editor QOL
    fastfetch # stats
    ghostty # terminal
    cmus # TUI audio player
    ranger # TUI file explorer
    cbonsai # screensaver
  ];

  #Programs

  #Shell
  programs.zsh = {
    enable = true;
    shellAliases = {
      ".." = "cd ..";
      ll = "ls -lah";
      #ls = "eza --icons=auto";
      filecnt = "ls -1A | wc -l";
    };
  };

 

  #Improved Directory Mobility
  programs.zoxide.enable = true;
  programs.ssh = {
    extraConfig = ''
      	Host myhost
      		Hostname 10.0.0.175
      		Port 22
      		User user
      	'';
  };

  #Services

  #Hosting local Minecraft Server (Vanilla)
  services.minecraft-server = {
    enable = true;
    eula = true;
    jvmOpts = "-Xms4096M -Xmx4096M";
    declarative = true;
    serverProperties = {
      "server-port" = 25565;
    };
  };

  #Hosting "Google Photos"
  services.immich = {
    enable = true;
    host = "0.0.0.0";
  };

  #Hosting "Netflix"
  services.jellyfin = {
    enable = true;
    };

  #Desktop Manager
  services.displayManager.gdm.enable = true;
  services.desktopManager.gnome.enable = true;

  #Power Management
  services.logind.settings.Login = {
    HandleLidSwitch = "ignore";
    HandleLidSwitchDocked = "ignore";
    HandleLidSwitchExternalPower = "ignore";
  };

  systemd.targets = {
    sleep.enable = false;
    suspend.enable = false;
    hibernate.enable = false;
    hybrid-sleep.enable = false;
  };
  systemd.sleep.settings = {
    Sleep = {
      AllowSuspend = "no";
      AllowHibernation = "no";
      AllowHybridSleep = "no";
      AllowSuspendThenHibernate = "no";
    };
  };
  programs.dconf.enable = true;
  programs.dconf.profiles.user.databases = [
    {
      settings = {
        "org/gnome/settings-daemon/plugins/power" = {
          sleep-inactive-ac-type = "nothing";
          sleep-inactive-ac-timeout = lib.gvariant.mkUint32 0;
        };
      };
    }
  ];
  services.udev.extraRules = ''
    ACTION=="add", SUBSYSTEM=="pci", DRIVER=="pcieport", ATTR{power/wakeup}="disabled"
  '';

  #Networking
   networking.firewall.allowedTCPPorts = [
     22 # SSH
     2283 # Immich
     8096 # Jellyfin
     25565 # Minecraft
   ];
  networking.hostName = "sasha";
  networking.networkmanager.enable = true;

  #Open SSH
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = true;
      KbdInteractiveAuthentication = true;
      PermitRootLogin = "yes";
      AllowUsers = [ "sasha" ];
    };
  };

  #DO NOT TOUCH BELOW THIS 
  system.stateVersion = "26.05";
}
