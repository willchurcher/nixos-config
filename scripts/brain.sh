#!/usr/bin/env bash
# brain — dump a folder (tree + file contents) and copy to Wayland clipboard via wl-copy.
#
# Usage:
#   brain              # dumps current dir
#   brain /etc/nixos   # dumps given dir
#
# Env:
#   CFGCLIP_MAX_BYTES=262144         # max bytes per file (default 256 KiB)
#   CFGCLIP_MAX_TOTAL_BYTES=10485760 # max total dump bytes (default 10 MiB; 0 = unlimited)
#   CFGCLIP_KEEP=1                   # keep temp dump file and print its path (default 0)
#   CFGCLIP_TREE=1                   # include tree output (default 1)
#   CFGCLIP_NL=1                     # line-number files (default 1)

set -euo pipefail

if ! command -v wl-copy >/dev/null 2>&1; then
  echo "brain: wl-copy not found. On NixOS install: wl-clipboard" >&2
  exit 1
fi

root="${1:-/etc/nixos}"
max_bytes="${CFGCLIP_MAX_BYTES:-262144}"
max_total_bytes="${CFGCLIP_MAX_TOTAL_BYTES:-10485760}"
keep="${CFGCLIP_KEEP:-0}"
do_tree="${CFGCLIP_TREE:-1}"
do_nl="${CFGCLIP_NL:-1}"

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

# ─────────────────────────────────────────────────────────────
# Pruning rules
# ─────────────────────────────────────────────────────────────

# Directories excluded from file-content dumping (but may appear in tree)
dump_prune_dirs=(
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

# Directories hidden entirely from tree output
# NOTE: we include .git here so it won't be expanded; we’ll add a single ".git/" line manually.
tree_prune_dirs=(
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

# ─────────────────────────────────────────────────────────────
# Header
# ─────────────────────────────────────────────────────────────

{
  echo "### brain"
  echo "root: $root"
  echo "generated: $(date -Iseconds)"
  echo "max_bytes_per_file: $max_bytes"
  echo "max_total_bytes: $max_total_bytes"
  echo
} > "$tmp"

# ─────────────────────────────────────────────────────────────
# Tree output
# ─────────────────────────────────────────────────────────────

if [[ "$do_tree" == "1" ]]; then
  if command -v tree >/dev/null 2>&1; then
    tree_ignore="$(IFS='|'; echo "${tree_prune_dirs[*]}")"
    {
      echo "### tree"
      tree -a -F -I "$tree_ignore" "$root" || true

      # Show that .git exists, without expanding it
      if [[ -d "$root/.git" ]]; then
        echo " .git/"
        echo
        echo "(note: .git exists and is excluded from file dump)"
      fi

      echo
    } >> "$tmp"
  else
    {
      echo "### tree"
      echo "(missing 'tree' command; on NixOS add pkgs.tree)"
      echo
    } >> "$tmp"
  fi
fi

# ─────────────────────────────────────────────────────────────
# Build prune expression for find
# ─────────────────────────────────────────────────────────────

find_prune=()
for d in "${dump_prune_dirs[@]}"; do
  find_prune+=( -name "$d" -o )
done
unset 'find_prune[${#find_prune[@]}-1]'

# ─────────────────────────────────────────────────────────────
# File dumping
# ─────────────────────────────────────────────────────────────

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

  # Robust binary detection (NUL byte check)
  if dd if="$f" bs=8192 count=1 status=none 2>/dev/null \
    | od -An -tx1 -v \
    | grep -qE '(^|[[:space:]])00([[:space:]]|$)'; then
    {
      echo "===== FILE: $rel ====="
      echo "(skipped: binary file detected)"
      echo
    } >> "$tmp"
    continue
  fi

  {
    echo "===== FILE: $rel ====="
    echo
    if [[ "$do_nl" == "1" ]] && command -v nl >/dev/null 2>&1; then
      nl -ba "$f" || cat "$f"
    else
      cat "$f"
    fi
    echo
    echo
  } >> "$tmp"

  if [[ "$max_total_bytes" != "0" ]]; then
    current_bytes="$(wc -c < "$tmp" | tr -d ' ' || echo 0)"
    if [[ "$current_bytes" -gt "$max_total_bytes" ]]; then
      {
        echo "### (stopped: total dump exceeded ${max_total_bytes} bytes)"
        echo
      } >> "$tmp"
      break
    fi
  fi
done < <(
  find "$root" \
    \( -type l -o \( "${find_prune[@]}" \) \) -prune -o \
    -type f -print0
)

# ─────────────────────────────────────────────────────────────
# Clipboard + cleanup
# ─────────────────────────────────────────────────────────────

wl-copy < "$tmp"
bytes="$(wc -c < "$tmp" | tr -d ' ' || echo "?")"

if [[ "$keep" == "1" ]]; then
  echo "brain: copied ${bytes} bytes to clipboard from: $tmp"
else
  rm -f "$tmp"
  echo "brain: copied ${bytes} bytes to clipboard"
fi

