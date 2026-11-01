# roadmap{
  # *jellyfin
  # *photo host
  # *minecraft server
  # *nvim auto set number
  # seafile
  # live TV (playlists with downloaded ads)
  # HTB ez deploy vm partially persistant
  # SSO all services
  # homepage w/ hyperlinks and admin controls
  # remote access (cloudflare tunnel? vpn?)
  # caps->esc keybind
  # configure router for pihole / other ad blocker
  #
  #mullvad{
  #   find some good form of indexing that allows for playlist creation
  # prowlarr -> qbittorrent -> data
  #}
  # data -> seafile -> jellyfin
#};

{
  config,
  lib,
  pkgs,
  ...
}:

let

  # gnomepage tui - util
  gnomepage = pkgs.writeShellApplication {
    name = "gnomepage";
    runtimeInputs = with pkgs; [ fastfetch cbonsai ncurses ];
    text = ''
      clear
      cbonsai -p
      echo "hello sasha :p"
      echo ""
      echo "          ~ some options for my favorite baby bing ~ "
      echo " cfig     ~ opens configuration.nix in nvim ~ "
      echo " wrkspc   ~ changes dirs to where configuration.nix is ~ "
      echo " ll       ~ list files ~ "
      echo " filecnt  ~ count files in dir ~ "
      echo " ranger   ~ file manager ~ "
      echo " cmus     ~ music player ~ "
      echo " rib      ~ run it back runs sudo nixos-rebuild switch ~ "
      echo " gitbs    ~ adds configuration.nix ~ "
      echo " heave    ~ rib then gitbs ~ "
      echo " tidy     ~ source zsh ~ "
      echo " scrub    ~ collect nix garbage and source zsh ~ "
      echo " gp       ~ this page :o "
      echo ""
    '';
  };

in


{
  imports = [
    ./hardware-configuration.nix
  ];

#Initialization
  # bootloader - util
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

#Config
  nixpkgs.config.allowUnfree = true;
  services.xserver.xkb.layout = "us";
  time.timeZone = "America/New_York";


  # user - config
  users.defaultUserShell = pkgs.zsh;
  users.users.sasha = {
    isNormalUser = true;
    useDefaultShell = true;
    extraGroups = [ "wheel" "data" ];
    homeMode = "0755";
    packages = with pkgs; [ ];
  };

  # commands - config
  programs.zsh = {
    enable = true;
    shellAliases = {
      ".." = "cd ..";
      "ll" = "ls -lah";
      "gp" = "gnomepage";
      "filecnt" = "ls -1A | wc -l";
      "wrkspc" = "cd ~ && cd ../../etc/nixos";
      "cfig" = "wrkspc && nvim configuration.nix";
      "rib" = "wrkspc && sudo nixos-rebuild switch";
      "gitbs" = "git add configuration.nix";
      "heave" = "rib && gitbs";
      "commit" = "git commit -m ";
      "tidy" = "cd ~ && source ~/.zshrc";
      "scrub" = "tidy && sudo nix-collect-garbage";
      "gs" = "'+set number'";
      "nvim" = "nvim '+set number'";
    };
    interactiveShellInit = ''
      gnomepage
    '';
  };

  # file management - arc
  systemd.tmpfiles.rules = [
    "d /data 0775 root data -"
    "d /data/pictures 2775 sasha data -"
    "d /data/movies 2775 sasha data -"
    "d /data/shows 2775 sasha data -"
    "d /data/music 2775 sasha data -"
    "d /data/books 2775 sasha data -"
    "d /data/unsorted 2775 sasha data -"
    "d /data/files 2775 sasha data -"
    "d /data/.Private 2775 sasha data -"
    "d /data/videos 2775 sasha data -"
  ];

  # packages - arc
  environment.systemPackages = with pkgs; [
    gnomepage # util
    neovim # util
    wget # utilities
    tree # utilities
    eza # utilities
    git # version control
    fastfetch # stats
    ghostty # terminal
    cmus # TUI audio player
    ranger # TUI file explorer
    cbonsai # screensaver
  ];

  # SSH - arc
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = true;
      KbdInteractiveAuthentication = true;
      PermitRootLogin = "yes";
      AllowUsers = [ "sasha" ];
    };
  };

  # firewall - arc
  networking.firewall.allowedTCPPorts = [
    22 # SSH
    8080 # Qbitt
    2283 # Immich
    8096 # Jellyfin
    25565 # Minecraft
  ];
  networking.hostName = "sasha";
  networking.networkmanager.enable = true;

# Services

  # minecraft - service
  services.minecraft-server = {
    enable = true;
    eula = true;
    jvmOpts = "-Xms4096M -Xmx4096M";
    declarative = true;
    serverProperties = {
      "server-port" = 25565;
    };
  };

  # qbit - service
  services.qbittorrent = {
    enable = true;
  };

  # photo browser - service
  services.immich = {
    enable = true;
    host = "0.0.0.0";
  };

  # media server - service
  services.jellyfin = {
    enable = true;
  };

#Util

  # desktop manager - util
  services.displayManager.gdm.enable = true;
  services.desktopManager.gnome.enable = true;

  # power management - util
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


# DO NOT TOUCH BELOW THIS
  system.stateVersion = "26.05";
}
 
