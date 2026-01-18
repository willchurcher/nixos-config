{ config, pkgs, ... }:

let
  scripts = import ./scripts { inherit pkgs; };
in
{
  home.username = "will";
  home.homeDirectory = "/home/will";
  home.stateVersion = "25.11";

  home.packages = with pkgs; [
    # Nixos
    home-manager
    
    # CMD
    wl-clipboard
    tree
    file

    # Python
    uv
    python313

    # Custom scripts
    scripts.brain
    scripts.nu

    # Apps
    discord
    steam
    spotify

    # Utils
    proton-pass
    obsidian
    claude-code
    (zed-editor.overrideAttrs (_: { doCheck = false; }))
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
  
    # I don't want to see these
    desktop = "${config.home.homeDirectory}/.local/desktop";
    templates = "${config.home.homeDirectory}/.local/desktop";
    publicShare = "${config.home.homeDirectory}/.local/publicShare";
  
    # Directories in root
    download = "${config.home.homeDirectory}/inbox";
    documents = "${config.home.homeDirectory}/notes";
    pictures = "${config.home.homeDirectory}/media/images";
    music = "${config.home.homeDirectory}/media/audio";
    videos = "${config.home.homeDirectory}/media/video";
  };
}

