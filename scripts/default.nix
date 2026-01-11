{ pkgs }:

{
  cfgclip = pkgs.writeShellApplication {
    name = "brain";

    # These are available at runtime when you execute cfgclip.
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
}

