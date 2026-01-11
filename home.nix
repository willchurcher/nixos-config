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

    scripts.cfgclip
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
  
    # keep your settings (writes to ~/.config/git/config in your setup)
   settings = {
      init.defaultBranch = "main";
    };
  
    # ensure ~/.gitconfig includes the XDG config too
    includes = [
      { path = "${config.home.homeDirectory}/.config/git/config"; }
    ];
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

