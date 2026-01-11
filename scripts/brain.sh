#!/usr/bin/env bash
# brain — dump a folder (tree + file contents) and copy to Wayland clipboard via wl-copy.
#
# Usage:
#   brain              # dumps current dir
#   brain /etc/nixos   # dumps given dir
#
# Env:
#   CFGCLIP_MAX_BYTES=262144   # max bytes per file (default 256 KiB)
#   CFGCLIP_KEEP=1             # keep temp dump file and print its path (default 0)

set -euo pipefail

if ! command -v wl-copy >/dev/null 2>&1; then
  echo "brain: wl-copy not found. On NixOS install: wl-clipboard" >&2
  exit 1
fi

root="${1:-$PWD}"
max_bytes="${CFGCLIP_MAX_BYTES:-262144}"
keep="${CFGCLIP_KEEP:-0}"

if command -v realpath >/dev/null 2>&1; then
  root="$(realpath "$root")"
fi

if [[ ! -d "$root" ]]; then
  echo "brain: not a directory: $root" >&2
  exit 1
fi

base="$(basename "$root")"
ts="$(date +%Y%m%d-%H%M%S)"
tmp="$(mktemp -t "brain-${base}-${ts}.XXXXXX.txt")"

prune_dirs=(
  .git .hg .svn
  result result-*
  node_modules
  .direnv .venv venv
  __pycache__ .mypy_cache .pytest_cache .ruff_cache
  .cache
  .idea .vscode
  dist build target
  .terraform .tox
)

skip_ext=(
  csv tsv
  parquet arrow feather
  sqlite db
  bin exe dll so dylib o a
  zip tar gz bz2 xz 7z rar
  pdf
  png jpg jpeg gif webp svg ico
  mp3 wav flac ogg mp4 mkv mov
  ttf otf woff woff2
)

skip_name_globs=(
  "*.pem" "*.key" "*.p12" "*.pfx"
  ".env" ".env.*"
)

{
  echo "### brain"
  echo "root: $root"
  echo "generated: $(date -Iseconds)"
  echo "max_bytes_per_file: $max_bytes"
  echo
} > "$tmp"

if command -v tree >/dev/null 2>&1; then
  tree_ignore="$(IFS='|'; echo "${prune_dirs[*]}")"
  {
    echo "### tree"
    tree -a -F -I "$tree_ignore" "$root" || true
    echo
  } >> "$tmp"
else
  {
    echo "### tree"
    echo "(missing 'tree' command; on NixOS add pkgs.tree)"
    echo
  } >> "$tmp"
fi

find_prune=()
for d in "${prune_dirs[@]}"; do
  find_prune+=( -path "*/$d" -o -path "*/$d/*" -o )
done

while IFS= read -r -d '' f; do
  rel="${f#"$root"/}"

  if [[ -L "$f" ]]; then
    {
      echo "===== FILE: $rel ====="
      echo "(skipped: symlink -> $(readlink "$f" || true))"
      echo
    } >> "$tmp"
    continue
  fi

  bn="$(basename "$f")"
  for g in "${skip_name_globs[@]}"; do
    # Intentionally allow glob matching like *.pem, .env.*
    # shellcheck disable=SC2053
    if [[ "$bn" == $g ]]; then
      continue 2
    fi
  done

  ext="${f##*.}"
  if [[ "$ext" != "$f" ]]; then
    ext="${ext,,}"
    for e in "${skip_ext[@]}"; do
      if [[ "$ext" == "$e" ]]; then
        continue 2
      fi
    done
  fi

  size="$(stat -c%s "$f" 2>/dev/null || stat -f%z "$f" 2>/dev/null || echo 0)"
  if [[ "$size" -gt "$max_bytes" ]]; then
    {
      echo "===== FILE: $rel ====="
      echo "(skipped: too large: ${size} bytes > ${max_bytes})"
      echo
    } >> "$tmp"
    continue
  fi

  if command -v file >/dev/null 2>&1; then
    if file --brief --mime "$f" | grep -qiE 'charset=binary|application/octet-stream'; then
      {
        echo "===== FILE: $rel ====="
        echo "(skipped: binary file detected)"
        echo
      } >> "$tmp"
      continue
    fi
  fi

  {
    echo "===== FILE: $rel ====="
    echo
    if command -v nl >/dev/null 2>&1; then
      nl -ba "$f" || cat "$f"
    else
      cat "$f"
    fi
    echo
    echo
  } >> "$tmp"
done < <(
  find "$root" \( "${find_prune[@]}" -false \) -prune -o -type f -print0
)

wl-copy < "$tmp"

bytes="$(wc -c < "$tmp" | tr -d ' ' || echo "?")"

if [[ "$keep" == "1" ]]; then
  echo "brain: copied ${bytes} bytes to clipboard from: $tmp"
else
  rm -f "$tmp"
  echo "brain: copied ${bytes} bytes to clipboard"
fi
