#!/usr/bin/env bash
set -euo pipefail

# nu — tiny NixOS rebuild + git helper for your flake repo
#
# Usage:
#   nu switch [nixos-rebuild args...]
#   nu gs
#   nu gc [git commit args...]
#   nu gp [git push args...]
#
# Defaults (override via env):
#   FLAKE_DIR=/etc/nixos
#   FLAKE_HOST=nixos

FLAKE_DIR="${FLAKE_DIR:-/etc/nixos}"
FLAKE_HOST="${FLAKE_HOST:-nixos}"
flake_ref="${FLAKE_DIR}#${FLAKE_HOST}"

cmd="${1:-help}"
shift || true

die() { echo "nu: $*" >&2; exit 1; }

need_root() {
  if [[ "${EUID}" -ne 0 ]]; then
    exec sudo -E "$0" "$cmd" "$@"
  fi
}

in_repo() {
  cd "$FLAKE_DIR" || die "cannot cd to FLAKE_DIR=$FLAKE_DIR"
  if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    die "FLAKE_DIR is not a git repo: $FLAKE_DIR"
  fi
}

case "$cmd" in
  switch)
    need_root "$@"
    echo "==> nixos-rebuild switch --flake ${flake_ref} $*"
    exec nixos-rebuild switch --flake "$flake_ref" "$@"
    ;;

  gs)
    in_repo
    exec git status "$@"
    ;;

  gc)
    in_repo
    exec git commit "$@"
    ;;
  
  ga)
    in_repo
    exec git add "$@"
    ;;

  gp)
    in_repo
    exec git push "$@"
    ;;

  help|*)
    cat <<EOF
nu — NixOS rebuild + git helper

Defaults:
  FLAKE_DIR=$FLAKE_DIR
  FLAKE_HOST=$FLAKE_HOST
  flake ref: $flake_ref

Commands:
  nu switch [args...]   sudo nixos-rebuild switch --flake $flake_ref
  nu gs                 git status (in \$FLAKE_DIR)
  nu gc [args...]       git commit (in \$FLAKE_DIR)
  nu gp [args...]       git push   (in \$FLAKE_DIR)

Examples:
  nu switch
  nu switch --show-trace
  nu gs
  nu gc -am "update"
  nu gp
EOF
    ;;
esac

