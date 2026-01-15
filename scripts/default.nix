{ pkgs }:

{
  brain = pkgs.writeShellApplication {
    name = "brain";

    runtimeInputs = with pkgs; [
      wl-clipboard
      tree
      file
      findutils
      coreutils
      gnugrep
    ];

    text = builtins.readFile ./brain.sh;
  };

  nu = pkgs.writeShellApplication {
    name = "nu";

    runtimeInputs = with pkgs; [
      git
      nix
      coreutils
    ];

    text = builtins.readFile ./nu.sh;
  };
}

