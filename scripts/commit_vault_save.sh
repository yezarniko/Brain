#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  commit_vault_save.sh <note-path>

Behavior:
  - Commits only the provided note path.
  - Commit message format: chore(vault): save <filename>
USAGE
}

main() {
  if [[ "${1:-}" == "-h" || "${1:-}" == "--help" || $# -lt 1 ]]; then
    usage
    exit 0
  fi

  local note_path="$1"
  local script_dir vault_root rel_path filename msg sha

  script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  vault_root="$(cd "${script_dir}/.." && pwd)"

  if ! git -C "${vault_root}" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    echo "COMMIT_STATUS=skipped"
    echo "COMMIT_REASON=not-a-git-repo"
    exit 0
  fi

  if [[ ! -f "$note_path" ]]; then
    echo "COMMIT_STATUS=skipped"
    echo "COMMIT_REASON=note-not-found"
    exit 0
  fi

  rel_path="${note_path#${vault_root}/}"
  filename="$(basename "$note_path")"
  msg="chore(vault): save ${filename}"

  git -C "${vault_root}" add -- "${rel_path}"

  if git -C "${vault_root}" diff --cached --quiet -- "${rel_path}"; then
    echo "COMMIT_STATUS=skipped"
    echo "COMMIT_REASON=no-changes"
    exit 0
  fi

  git -C "${vault_root}" commit -m "${msg}" --only -- "${rel_path}" >/dev/null
  sha="$(git -C "${vault_root}" rev-parse --short HEAD)"

  echo "COMMIT_STATUS=created"
  echo "COMMIT_SHA=${sha}"
  echo "COMMIT_MESSAGE=${msg}"
}

main "$@"
