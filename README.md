# NixOS Configuration

This repository contains my personal NixOS configuration, managed as a flake
and including Home Manager.

It is intended to be fully reproducible: cloning this repo and building the flake
should recreate my system.

## Structure

- `flake.nix`  
  Flake entrypoint. Wires together NixOS and Home Manager.

- `configuration.nix`  
  Main system configuration (boot, networking, graphics, users, etc).

- `home.nix`  
  Home Manager configuration for my user (`will`).

- `scripts/`  
  Custom command-line tools managed as Nix packages.
  
  Currently includes:
  - `brain` — dumps a directory (tree + file contents) and copies it to the clipboard
    for pasting into ChatGPT or other tools.

## brain

`brain` is a small utility that:
- walks a directory
- prints a tree
- includes all text files
- skips binaries, caches, and large files
- copies the result to the clipboard

Example:

```bash
brain /etc/nixos

