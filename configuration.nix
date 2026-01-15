{ config, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
  ];

  # Enable flakes + nix command
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Bootloader
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Hostname
  networking.hostName = "nixos";

  # Firmware for Wi-Fi, GPUs, etc
  hardware.enableRedistributableFirmware = true;

  # Allow proprietary software (NVIDIA, VSCode, etc)
  nixpkgs.config.allowUnfree = true;

  # Networking
  networking.networkmanager.enable = true;

  # TP-Link Archer T3U (Realtek RTL8812BU)
  boot.kernelModules = [ "88x2bu" ];
  boot.extraModulePackages = with config.boot.kernelPackages; [
    rtl88x2bu
  ];

  # Bluetooth (Realtek USB dongle uses btusb + firmware; enable BlueZ)
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
  };

  # Optional GUI tray/app for Bluetooth
  services.blueman.enable = false;

  # Time & locale
  time.timeZone = "Europe/London";
  i18n.defaultLocale = "en_GB.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_GB.UTF-8";
    LC_IDENTIFICATION = "en_GB.UTF-8";
    LC_MEASUREMENT = "en_GB.UTF-8";
    LC_MONETARY = "en_GB.UTF-8";
    LC_NAME = "en_GB.UTF-8";
    LC_NUMERIC = "en_GB.UTF-8";
    LC_PAPER = "en_GB.UTF-8";
    LC_TELEPHONE = "en_GB.UTF-8";
    LC_TIME = "en_GB.UTF-8";
  };

  # Keyboard
  services.xserver.xkb = {
    layout = "gb";
    variant = "mac";
  };
  console.keyMap = "uk";

  # Graphical system
  services.xserver.enable = true;

  services.displayManager.sddm.enable = true;
  services.desktopManager.plasma6.enable = true;

  # You currently force X11 sessions here.
  # If you want Plasma Wayland sessions, set this to true later.
  services.displayManager.sddm.wayland.enable = false;

  # Modern graphics stack
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  # NVIDIA
  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.nvidia = {
    modesetting.enable = true;
    nvidiaSettings = true;
    powerManagement.enable = false;
    powerManagement.finegrained = false;
    open = false;
  };

  # Keep your existing NVIDIA param, and also disable USB autosuspend to reduce
  # USB Wi-Fi/Bluetooth breaking after sleep/resume.
  # (usbcore.autosuspend=-1 is a common, documented kernel option for this.) :contentReference[oaicite:2]{index=2}
  boot.kernelParams = [
    "nvidia_drm.modeset=1"
    "usbcore.autosuspend=-1"
  ];

  # HARD DISABLE SUSPEND/HIBERNATE SYSTEM-WIDE
  # This ensures "sleep" doesn't power down the machine, so games keep running.
  # KDE can still turn the screen off (DPMS) without suspending. :contentReference[oaicite:3]{index=3}
  systemd.sleep.extraConfig = ''
    AllowSuspend=no
    AllowHibernation=no
    AllowHybridSleep=no
    AllowSuspendThenHibernate=no
  '';

  # Printing
  services.printing.enable = true;

  # Audio (PipeWire)
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  # User
  users.users.will = {
    isNormalUser = true;
    description = "Will Churcher";
    extraGroups = [ "networkmanager" "wheel" ];
    packages = with pkgs; [
      kdePackages.kate
    ];
  };

  # Browser
  programs.firefox.enable = true;

  # System tools
  environment.systemPackages = with pkgs; [
    usbutils
    vim
    vscode
    git

    # KDE Bluetooth UI bits (fixes missing QML modules)
    kdePackages.bluedevil
    kdePackages.bluez-qt

    # File transfer over Bluetooth
    openobex
    obexftp
  ];

  system.stateVersion = "25.11";
}

