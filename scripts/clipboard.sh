#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  clipboard.sh get
  clipboard.sh set [text]
  clipboard.sh set    # reads text from stdin

Examples:
  clipboard.sh get
  clipboard.sh set "hello"
  echo "hello" | clipboard.sh set
USAGE
}

has() {
  command -v "$1" >/dev/null 2>&1
}

get_clipboard() {
  if has pbpaste; then
    pbpaste
  elif has wl-paste; then
    wl-paste --no-newline
  elif has xclip; then
    xclip -selection clipboard -o
  elif has xsel; then
    xsel --clipboard --output
  elif has powershell.exe; then
    powershell.exe -NoProfile -Command 'Get-Clipboard'
  else
    echo "No supported clipboard tool found." >&2
    echo "Install one of: wl-clipboard, xclip, xsel (Linux)" >&2
    exit 1
  fi
}

set_clipboard() {
  local input
  if [[ $# -gt 0 ]]; then
    input="$*"
  else
    input="$(cat)"
  fi

  if has pbcopy; then
    printf '%s' "$input" | pbcopy
  elif has wl-copy; then
    printf '%s' "$input" | wl-copy
  elif has xclip; then
    printf '%s' "$input" | xclip -selection clipboard
  elif has xsel; then
    printf '%s' "$input" | xsel --clipboard --input
  elif has clip.exe; then
    printf '%s' "$input" | clip.exe
  else
    echo "No supported clipboard tool found." >&2
    echo "Install one of: wl-clipboard, xclip, xsel (Linux)" >&2
    exit 1
  fi
}

main() {
  local cmd="${1:-}"
  case "$cmd" in
    get)
      get_clipboard
      ;;
    set)
      shift || true
      set_clipboard "$@"
      ;;
    -h|--help|help|"")
      usage
      ;;
    *)
      echo "Unknown command: $cmd" >&2
      usage >&2
      exit 1
      ;;
  esac
}

main "$@"
