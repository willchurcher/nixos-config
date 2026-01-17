{ config, pkgs, ... }:

let
  scripts = import ./scripts { inherit pkgs; };
in
{
  home.username = "will";
  home.homeDirectory = "/home/will";
  home.stateVersion = "25.11";

  home.packages = with pkgs; [
    home-manager

    wl-clipboard
    tree
    file

    uv
    python313

    # Your custom scripts (from /etc/nixos/scripts/default.nix)
    scripts.brain
    scripts.nu

    # Apps
    discord
    steam
    spotify
  ];

  home.sessionVariables = {
    XDG_CONFIG_HOME = "${config.home.homeDirectory}/.config";
  };
  xdg.enable = true;

  programs.bash.enable = true;
  programs.zsh.enable = true;

  programs.bash.shellAliases = {
    pbcopy = "wl-copy";
    pbpaste = "wl-paste";
  };

  programs.zsh.shellAliases = {
    pbcopy = "wl-copy";
    pbpaste = "wl-paste";
  };

  programs.git = {
    enable = true;

    settings = {
      init.defaultBranch = "main";
    };
  };

  xdg.userDirs = {
    enable = true;
    createDirectories = true;

    desktop = config.home.homeDirectory;
    templates = config.home.homeDirectory;
    publicShare = config.home.homeDirectory;

    download = "${config.home.homeDirectory}/downloads";
    documents = "${config.home.homeDirectory}/notes";
    pictures = "${config.home.homeDirectory}/media/images";
    music = "${config.home.homeDirectory}/media/audio";
    videos = "${config.home.homeDirectory}/media/video";
  };
}

