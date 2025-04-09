# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

let
  lib = pkgs.lib;  # Importing lib from pkgs
  home-manager = builtins.fetchTarball https://github.com/nix-community/home-manager/archive/master.tar.gz;
in

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
      (import "${home-manager}/nixos")
    ];

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  # Enable BBR congestion control
    boot.kernelModules = [ "tcp_bbr" ];
    boot.kernel.sysctl."net.ipv4.tcp_congestion_control" = "bbr";
    boot.kernel.sysctl."net.core.default_qdisc" = "fq"; # see https://news.ycombinator.com/item?id=14814530

    # Increase TCP window sizes for high-bandwidth WAN connections, assuming
    # 10 GBit/s Internet over 200ms latency as worst case.
    #
    # Choice of value:
    #     BPP         = 10000 MBit/s / 8 Bit/Byte * 0.2 s = 250 MB
    #     Buffer size = BPP * 4 (for BBR)                 = 1 GB
    # Explanation:
    # * According to http://ce.sc.edu/cyberinfra/workshops/Material/NTP/Lab%208.pdf
    #   and other sources, "Linux assumes that half of the send/receive TCP buffers
    #   are used for internal structures", so the "administrator must configure
    #   the buffer size equals to twice" (2x) the BPP.
    # * The article's section 1.3 explains that with moderate to high packet loss
    #   while using BBR congestion control, the factor to choose is 4x.
    #
    # Note that the `tcp` options override the `core` options unless `SO_RCVBUF`
    # is set manually, see:
    # * https://stackoverflow.com/questions/31546835/tcp-receiving-window-size-higher-than-net-core-rmem-max
    # * https://bugzilla.kernel.org/show_bug.cgi?id=209327
    # There is an unanswered question in there about what happens if the `core`
    # option is larger than the `tcp` option; to avoid uncertainty, we set them
    # equally.
    boot.kernel.sysctl."net.core.wmem_max" = 1073741824; # 1 GiB
    boot.kernel.sysctl."net.core.rmem_max" = 1073741824; # 1 GiB
    boot.kernel.sysctl."net.ipv4.tcp_rmem" = "4096 87380 1073741824"; # 1 GiB max
    boot.kernel.sysctl."net.ipv4.tcp_wmem" = "4096 87380 1073741824"; # 1 GiB max
    # We do not need to adjust `net.ipv4.tcp_mem` (which limits the total
    # system-wide amount of memory to use for TCP, counted in pages) because
    # the kernel sets that to a high default of ~9% of system memory, see:
    # * https://github.com/torvalds/linux/blob/a1d21081a60dfb7fddf4a38b66d9cef603b317a9/net/ipv4/tcp.c#L4116

    boot.extraModulePackages = [
      # For being able to flip/mirror my webcam.
      config.boot.kernelPackages.v4l2loopback
    ];

    boot.plymouth = {
      enable = true;
      theme = "Nordic-darker";
    };

    # Register a v4l2loopback device at boot
    #boot.kernelModules = [
    # "v4l2loopback"
    #];

    # For mounting many cameras.
    # Need to set `users.users.alice.extraGroups = ["camera"];` for each user allowed.
    programs.gphoto2.enable = true;

  networking.hostName = "mahd-nixos"; # Define your hostname.
  #networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Enable networking
  networking.networkmanager.enable = true;
  networking.firewall.allowedTCPPorts = [ 445 548 ];

  # Set your time zone.
  time.timeZone = "Europe/Berlin";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "de_DE.UTF-8";
    LC_IDENTIFICATION = "de_DE.UTF-8";
    LC_MEASUREMENT = "de_DE.UTF-8";
    LC_MONETARY = "de_DE.UTF-8";
    LC_NAME = "de_DE.UTF-8";
    LC_NUMERIC = "de_DE.UTF-8";
    LC_PAPER = "de_DE.UTF-8";
    LC_TELEPHONE = "de_DE.UTF-8";
    LC_TIME = "de_DE.UTF-8";
  };

  # Enable the X11 windowing system.
  #services.xserver.enable = true;

  # Enable the XFCE Desktop Environment.
  #services.xserver.displayManager.lightdm.enable = true;

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "de";
    variant = "nodeadkeys";
  };

  # Configure console keymap
  console.keyMap = "de-latin1-nodeadkeys";

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Enable sound with pipewire.
  #hardware.alsa.enable = true;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    audio.enable= true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # If you want to use JACK applications, uncomment this
    jack.enable = true;

    # use the example session manager (no others are packaged yet so this is enabled by default,
    # no need to redefine it in your config for now)
    #media-session.enable = true;
  };

  # Enable touchpad support (enabled default in most desktopManager).
   services.libinput.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  home-manager.useUserPackages = true;
  home-manager.useGlobalPkgs = true;
  users.users = {
    mahd = {
      isNormalUser = true;
      description = "mcpeaps_HD";
      password = "fabian66";
      shell = "/run/current-system/sw/bin/zsh";
      createHome = true;
      extraGroups = [ "networkmanager" "wheel" "camera" ];
      packages = with pkgs; [
      #  thunderbird
      ];
      expires = null;
    };
    root = {
      isSystemUser = true;
      #description = "mcpeaps_HD (root)";
      password = "fabian66";
      shell = "/run/current-system/sw/bin/zsh";
      extraGroups = ["networkmanager" "wheel" "camera"];
      expires = null;
    };
  };
    home-manager.users.mahd = { pkgs, ... }: {
    #home.packages = [ pkgs.atool pkgs.httpie ];
    # programs.bash.enable = true;

    # The state version is required and should stay at the version you
    # originally installed.
    home.stateVersion = "25.05";
  };
  # Install firefox.
  programs = {
    zsh = {
	enable = true;
	enableCompletion = true;
	enableLsColors = true;
    };
    firefox = {
      enable = true;
      languagePacks = [
	"en-US"
	"de"
      ];
    };
    git = {
      enable = true;
      lfs = {
        enable = true;
        enablePureSSHTransfer = true;
      };
    };
  };

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

#fonts
  fonts = {
    packages = [] ++ builtins.filter lib.attrsets.isDerivation (builtins.attrValues pkgs.nerd-fonts);
    fontconfig = {
      enable = true;
      defaultFonts = {
	serif = ["Caskaydia Cove Nerd Font"];
	sansSerif = ["Caskaydia Cove Nerd Font Propo"];
	monospace = ["Caskaydia Cove Nerd Font Mono"];
      };
    };
  };
# List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
  #  vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
    wget
    stow
    git
    git-lfs
    git-lfs-transfer
    gitAndTools.gh
    gcc
    btop
    neovim
    vscode
    fastfetch
    zellij
    zsh
    ghostty
    rofi
    feh
    solaar
#    vivaldi
    nordic
    picom
    nordzy-icon-theme
    nordzy-cursor-theme
    papirus-nord
    papirus-folders
  ];

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
   programs.mtr.enable = true;
   programs.gnupg.agent = {
     enable = true;
     enableSSHSupport = true;
   };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
   services.openssh.enable = true;
  # Samba
  # services.samba.enable = true;
   services.samba = {
    enable = true;
    openFirewall = true;
    smbd.enable = true;
    nmbd.enable = true;
    #wsdd.enable = true;
    #windbindd.enable = true;
    settings = {
      "public" = {
        "path" = "/public";
        "read only" = "yes";
        "browseable" = "yes";
        "guest ok" = "yes";
        "comment" = "Public samba share.";
	"public" = "yes";
	"writable" = "yes";
	"force create mode" = "0777";
	"force directory mode" = "0777";
      };
      "hdd" = {
        "path" = "/hdd";
        "browseable" = "yes";
        "guest ok" = "no";
        "comment" = "meine Festplatten";
	"writable" = "yes";
	"force create mode" = "0777";
	"force directory mode" = "0777";
      };
      "hdd-1tb" = {
        "path" = "/hdd/hdd-1tb";
        "browseable" = "yes";
        "guest ok" = "no";
        "comment" = "meine 1TB Festplatte";
	"writable" = "yes";
	"force create mode" = "0777";
	"force directory mode" = "0777";
	"vfs objects" = "catia fruit streams_xattr";
	"fruit:time machine" ="yes";
      };
      "hdd-256gb" = {
        "path" = "/hdd/hdd-256gb";
        "browseable" = "yes";
        "guest ok" = "no";
        "comment" = "meine 256 GB Festplatte";
	"writable" = "yes";
	"force create mode" = "0777";
	"force directory mode" = "0777";
	"vfs objects" = "catia fruit streams_xattr";
	"fruit:time machine" ="yes";
      };
    };
  };
  services.avahi = {
    enable = true;
    publish = {
      enable = true;
      userServices = true;
    };
    extraServiceFiles = {
      smb = ''
	<?xml version="1.0" standalone='no'?><!--*-nxml-*-->
	<!DOCTYPE service-group SYSTEM "avahi-service.dtd">
	<service-group>
	  <name replace-wildcards="yes">%h</name>
          <service>
	    <type>_smb._tcp</type>
            <port>445</port>
          </service>
	  <service>
            <type>_device-info._tcp</type>
            <port>9</port>
            <txt-record>model=Xserve1,1</txt-record>
          </service>
	  <service>
            <type>_adisk._tcp</type>
            <port>548</port>
            <txt-record>dk0=adVN=hdd-1tb,adVF=0x82</txt-record>
            <txt-record>sys=adVF=0x100</txt-record>
          </service>
	  <service>
            <type>_adisk._tcp</type>
            <port>548</port>
            <txt-record>dk0=adVN=hdd-256gb,adVF=0x82</txt-record>
            <txt-record>sys=adVF=0x100</txt-record>
          </service>
	</service-group>
      '';
    };
  };
  services.flatpak.enable = true;
  xdg.portal.enable = true;
  xdg.portal.extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
  xdg.portal.config.common.default = "gtk";
  #services.xserver.desktopManager.xfce.enable = true;
  services.xserver = {
    enable = true;
    displayManager = {
      lightdm = {
        enable = true;
        greeters.gtk = {
          enable = true;
          theme.name = "Nordic-darker";
          iconTheme.name = "Nordic-green";
	  cursorTheme.name = "Nordic-cursors";
	  clock-format = "KW%V,%A,%0d/%m/%Y|%H:%M:%S";
        };
      };
      #defaultSession = "xfce+i3";
    };
    desktopManager = {
    xterm.enable=false;
    xfce.enable = true;
    };
    windowManager.i3 = {
      enable = true;
      extraPackages = with pkgs; [
        i3status
	i3lock
	i3blocks
        autotiling
        xfce.xfce4-i3-workspaces-plugin
	xfce.xfce4-windowck-plugin
	xfce.xfce4-whiskermenu-plugin
	xfce.xfce4-weather-plugin
	xfce.xfce4-volumed-pulse
	xfce.xfce4-verve-plugin
	xfce.xfce4-timer-plugin
	xfce.xfce4-time-out-plugin
	xfce.xfce4-systemload-plugin
	xfce.xfce4-sensors-plugin
	xfce.xfce4-pulseaudio-plugin
	xfce.xfce4-notes-plugin
	xfce.xfce4-netload-plugin
	xfce.xfce4-mpc-plugin
	xfce.xfce4-mailwatch-plugin
	xfce.xfce4-genmon-plugin
	xfce.xfce4-fsguard-plugin
	xfce.xfce4-eyes-plugin
	xfce.xfce4-docklike-plugin
	xfce.xfce4-dockbarx-plugin
	xfce.xfce4-datetime-plugin
	xfce.xfce4-cpugraph-plugin
	xfce.xfce4-cpufreq-plugin
	xfce.xfce4-clipman-plugin
	xfce.xfce4-battery-plugin
	xfce.thunar-media-tags-plugin
	xfce.thunar-archive-plugin
      ];
      package = pkgs.i3-gaps;
    };
  };
  #services.xserver.enable = true;
  services.displayManager.defaultSession = "xfce+i3";
  services.picom = {
    enable = true;
    settings = {
      backend = "glx";
      fade = true;
      fade-delta = 5;
      active-opacity = 1.0;  # Float-Wert (0.0 - 1.0)
      inactive-opacity = 0.8; # Float-Wert (0.0 - 1.0)
      opacity-rule = [
        "80:class_g = 'Rofi'"
        "90:class_g = 'ghostty' && focused"
        "80:class_g = 'ghostty' && !focused"
      ];
      shadow = true;
      shadow-opacity = 0.75;
      blur-background = true;
      blur-method = "dual_kawase";
      blur-strength = 6;
      unredir-if-possible = true; # Optional für Performance
      vsync = true;
    };
  };

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
   networking.firewall.enable = true;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "25.05"; # Did you read the comment?

}
