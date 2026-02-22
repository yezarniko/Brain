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

try_clipboard_cmd() {
  # Run a clipboard backend; if it fails (e.g. missing DISPLAY), try next.
  if "$@" 2>/dev/null; then
    return 0
  fi
  return 1
}

get_clipboard() {
  if has pbpaste; then
    if try_clipboard_cmd pbpaste; then
      return 0
    fi
  fi
  if has wl-paste; then
    if try_clipboard_cmd wl-paste --no-newline; then
      return 0
    fi
  fi
  if has xclip; then
    if try_clipboard_cmd xclip -selection clipboard -o; then
      return 0
    fi
  fi
  if has xsel; then
    if try_clipboard_cmd xsel --clipboard --output; then
      return 0
    fi
  fi
  if has powershell.exe; then
    if try_clipboard_cmd powershell.exe -NoProfile -Command 'Get-Clipboard'; then
      return 0
    fi
  fi

  echo "Failed to read clipboard with available tools." >&2
  echo "If running in Linux, ensure DISPLAY/WAYLAND_DISPLAY and auth are available in this shell." >&2
  exit 1
}

set_clipboard() {
  local input
  if [[ $# -gt 0 ]]; then
    input="$*"
  else
    input="$(cat)"
  fi

  if has pbcopy; then
    if printf '%s' "$input" | pbcopy 2>/dev/null; then
      return 0
    fi
  fi
  if has wl-copy; then
    if printf '%s' "$input" | wl-copy 2>/dev/null; then
      return 0
    fi
  fi
  if has xclip; then
    if printf '%s' "$input" | xclip -selection clipboard 2>/dev/null; then
      return 0
    fi
  fi
  if has xsel; then
    if printf '%s' "$input" | xsel --clipboard --input 2>/dev/null; then
      return 0
    fi
  fi
  if has clip.exe; then
    if printf '%s' "$input" | clip.exe 2>/dev/null; then
      return 0
    fi
  fi

  echo "Failed to write clipboard with available tools." >&2
  echo "If running in Linux, ensure DISPLAY/WAYLAND_DISPLAY and auth are available in this shell." >&2
  exit 1
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
