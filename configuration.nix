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
      echo " ll       ~ list files ~ "
      echo " cfig     ~ opens configuration.nix in nvim ~ "
      echo " wrkspc   ~ changes dirs to where configuration.nix is ~ "
      echo " rib      ~ run it back runs sudo nixos-rebuild switch ~ "
      echo " filecnt  ~ count files in dir ~ "
      echo " mpgToWav ~ convert camcorder footy ~ "
      echo " ranger   ~ file manager ~ "
      echo " cmus     ~ music player ~ "
      echo " git/vim  ~ usual suspects ~ "
      echo " heave    ~ rib then gitbs ~ "
      echo " gitbs    ~ adds configuration.nix ~ "
      echo "gp        ~ this page :o "
      echo ""
    '';
  };

  # video converter - scripts 
  mpgToWav = pkgs.writeShellApplication {
    name = "mpgToWav";
    runtimeInputs = [ pkgs.ffmpeg ];
    text = ''
      dir="''${1:-.}"
      shopt -s nullglob nocaseglob
      files=("$dir"/*.mpg)
      if [ "''${#files[@]}" -eq 0 ]; then
        echo "No .mpg files found in $dir" >&2
        exit 1
      fi
      for f in "''${files[@]}"; do
        out="''${f%.*}.wav"
        echo "converting $(basename "$f") -> $(basename "$out")"
        ffmpeg -nostdin -y -i "$f" -vn -c:a pcm_s16le "$out"
      done
    '';
  };

in


{
  imports = [
    ./hardware-configuration.nix
  ];

  # - config
  nixpkgs.config.allowUnfree = true;

  # Bootloader - util
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # DateTime - config
  time.timeZone = "America/New_York";

  # Keymaps - config
  services.xserver.xkb.layout = "us";
  services.xserver.xkb.options = "caps:escape";

  # Default User - config
  users.defaultUserShell = pkgs.zsh;
  users.users.sasha = {
    isNormalUser = true;
    useDefaultShell = true;
    extraGroups = [ "wheel" "data" ];
    homeMode = "0755";
    packages = with pkgs; [ ];
  };

  # Groups / Access - ark
  systemd.tmpfiles.rules = [
    "d /root/.config 0755 root root -"
    "d /root/.config/nvim 0755 root root -"
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

  # Packages - ark
  environment.systemPackages = with pkgs; [
    gnomepage # util
    mpgToWav # scripts
    vim # utilities
    wget # utilities
    tree # utilities
    eza # utilities
    zsh # shell
    git # version control
    fastfetch # stats
    ghostty # terminal
    cmus # TUI audio player
    ranger # TUI file explorer
    cbonsai # screensaver
    nil # syntax check
  ];

  # Programs

  # aliases/shell - util
  programs.zsh = {
    enable = true;
    shellAliases = {
      ".." = "cd ..";
      "ll" = "ls -lah";
      "gp" = "gnomepage";
      "welcome" = "gnomepage";
      "filecnt" = "ls -1A | wc -l";
      "wrkspc" = "cd ~ && cd ../../etc/nixos";
      "cfig" = "wrkspc && nvim configuration.nix";
      "rib" = "wrkspc && sudo nixos-rebuild switch";
      "gitbs" = "git add configuration.nix";
      "heave" = "rib && gitbs";
      "commit" = "git commit -m ";
    };
    interactiveShellInit = ''
      gnomepage
    '';
  };

  # neovim - util
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    vimAlias = true;

    configure = {
      packages = { };
      extraContent = {
        init = ''
	  :set number
	'';
      };
    };
  };

  # Services

  # Networking - firewall
  networking.firewall.allowedTCPPorts = [
    22 # SSH
    8080 # Qbitt
    2283 # Immich
    8096 # Jellyfin
    25565 # Minecraft
  ];
  networking.hostName = "sasha";
  networking.networkmanager.enable = true;

  # Hoshting local Minecraft Server (Vanilla) - service (local)
  services.minecraft-server = {
    enable = true;
    eula = true;
    jvmOpts = "-Xms4096M -Xmx4096M";
    declarative = true;
    serverProperties = {
      "server-port" = 25565;
    };
  };

  # Hosting Qbit - service
  services.qbittorrent = {
    enable = true;
  };

  # Hosting Photo Browser - service
  services.immich = {
    enable = true;
    host = "0.0.0.0";
  };

  # Hosting Media Server - service
  services.jellyfin = {
    enable = true;
  };

  # Desktop Manager - util
  services.displayManager.gdm.enable = true;
  services.desktopManager.gnome.enable = true;

  # Power Management - util
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

  # Open SSH - ark
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = true;
      KbdInteractiveAuthentication = true;
      PermitRootLogin = "yes";
      AllowUsers = [ "sasha" ];
    };
  };

  # DO NOT TOUCH BELOW THIS
  system.stateVersion = "26.05";
}
 
