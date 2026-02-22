#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VAULT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
SAVE_DIR_NAME="${VAULT_SAVE_DIR:-Notes}"
OUT_DIR="${VAULT_ROOT}/${SAVE_DIR_NAME}"

mkdir -p "${OUT_DIR}"

usage() {
  cat <<'USAGE'
Usage:
  save_to_vault.sh [text]

Behavior:
  - If text argument is provided, uses it as note content.
  - Otherwise reads clipboard via scripts/clipboard.sh get.
USAGE
}

sanitize_natural_title() {
  local s="$1"
  # Keep natural readability while removing filesystem-problematic characters.
  s="$(printf '%s' "$s" | sed -E 's#[/\\:*?"<>|]# #g; s/[[:space:]]+/ /g; s/^[[:space:]]+//; s/[[:space:]]+$//')"
  if [[ -z "$s" ]]; then
    s="Quick Note"
  fi
  printf '%s' "$s"
}

next_note_number() {
  local max_num
  max_num="$(find "${OUT_DIR}" -maxdepth 1 -type f -name '*.md' \
    | sed -E 's#.*/##; s#^([0-9]+)\..*#\1#' \
    | awk '/^[0-9]+$/ {n=$1+0; if (n>m) m=n} END {if (m=="") m=0; print m}')"
  printf '%02d' $((max_num + 1))
}

trim() {
  sed -E 's/^[[:space:]]+//; s/[[:space:]]+$//'
}

extract_title() {
  local text="$1"
  local title

  title="$(printf '%s\n' "$text" \
    | awk 'NF {print; exit}' \
    | sed -E 's/^#{1,6}[[:space:]]*//' \
    | sed -E 's/^[-*][[:space:]]+//' \
    | sed -E 's/^>+[[:space:]]*//' \
    | trim)"

  if [[ -z "$title" ]]; then
    title="Quick Note"
  fi

  if [[ ${#title} -gt 80 ]]; then
    title="${title:0:80}"
    title="$(printf '%s' "$title" | sed -E 's/[[:space:]]+[[:alnum:]]*$//')"
  fi

  if [[ -z "$title" ]]; then
    title="Quick Note"
  fi

  printf '%s' "$title"
}

categorize() {
  local lc="$1"

  if grep -Eiq '\b(software engineering|system design|design pattern|clean architecture|refactor|code quality|unit test|integration test|e2e|api design|scalability|reliability|devops|ci/cd|git workflow)\b' <<<"$lc"; then
    printf 'software-engineering'
  elif grep -Eiq '\b(todo|task|deadline|milestone|deliverable|roadmap|sprint|next steps?|action items?)\b' <<<"$lc"; then
    printf 'project'
  elif grep -Eiq '\b(learn|learning|study|tutorial|guide|concept|explain|understand)\b' <<<"$lc"; then
    printf 'learning'
  elif grep -Eiq '\b(idea|brainstorm|hypothesis|maybe|experiment|vision)\b' <<<"$lc"; then
    printf 'idea'
  else
    printf 'reference'
  fi
}

build_tags() {
  local lc="$1"
  local -a tags=()

  grep -Eiq '\b(ai|llm|gpt|codex|automation|agent)\b' <<<"$lc" && tags+=(ai)
  grep -Eiq '\b(obsidian|vault|markdown|md)\b' <<<"$lc" && tags+=(obsidian)
  grep -Eiq '\b(script|bash|shell|python|javascript|code|cli)\b' <<<"$lc" && tags+=(coding)
  grep -Eiq '\b(software engineering|system design|design pattern|clean architecture|refactor|code quality|unit test|integration test|e2e|api design|scalability|reliability|devops|ci/cd|git workflow)\b' <<<"$lc" && tags+=(software-engineering)
  grep -Eiq '\b(project|plan|roadmap|milestone|deliverable|task|todo)\b' <<<"$lc" && tags+=(project)
  grep -Eiq '\b(learn|learning|study|tutorial|guide|concept)\b' <<<"$lc" && tags+=(learning)
  grep -Eiq '\b(idea|brainstorm|hypothesis|experiment)\b' <<<"$lc" && tags+=(idea)

  if [[ ${#tags[@]} -eq 0 ]]; then
    tags=(inbox)
  fi

  local unique
  unique="$(printf '%s\n' "${tags[@]}" | awk '!seen[$0]++')"
  printf '%s\n' "$unique"
}

find_related_links() {
  local lc="$1"
  local new_filename="$2"
  local f
  local -a links=()

  while IFS= read -r f; do
    local base title lowered
    base="$(basename "$f")"
    [[ "$base" == "$new_filename" ]] && continue

    title="${base%.md}"
    [[ -z "$title" ]] && continue
    [[ ${#title} -lt 4 ]] && continue

    lowered="$(printf '%s' "$title" | tr '[:upper:]' '[:lower:]')"

    # Match exact title phrase in text, case-insensitive.
    if grep -Fqi "$lowered" <<<"$lc"; then
      links+=("[[${title}]]")
    fi

    [[ ${#links[@]} -ge 8 ]] && break
  done < <(find "${VAULT_ROOT}" -type f -name '*.md' ! -path '*/.obsidian/*' | sort)

  if [[ ${#links[@]} -eq 0 ]]; then
    return 0
  fi

  printf '%s\n' "${links[@]}" | awk '!seen[$0]++'
}

main() {
  if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
    usage
    exit 0
  fi

  local raw_text
  if [[ $# -gt 0 ]]; then
    raw_text="$*"
  else
    raw_text="$("${SCRIPT_DIR}/clipboard.sh" get)"
  fi

  raw_text="$(printf '%s' "$raw_text" | tr -d '\r')"

  if [[ -z "$(printf '%s' "$raw_text" | tr -d '[:space:]')" ]]; then
    echo "Error: no text found (argument and clipboard were empty)." >&2
    exit 1
  fi

  local title natural_title number filename out_path
  local created_at lc_text category tags related

  title="$(extract_title "$raw_text")"
  natural_title="$(sanitize_natural_title "$title")"
  number="$(next_note_number)"
  filename="${number}.${natural_title}.md"
  out_path="${OUT_DIR}/${filename}"

  created_at="$(date -Iseconds)"
  lc_text="$(printf '%s' "$raw_text" | tr '[:upper:]' '[:lower:]')"
  category="$(categorize "$lc_text")"
  tags="$(build_tags "$lc_text")"
  related="$(find_related_links "$lc_text" "$filename" || true)"

  {
    echo "---"
    echo "title: \"${title}\""
    echo "created: ${created_at}"
    echo "category: ${category}"
    echo "tags:"
    while IFS= read -r t; do
      [[ -n "$t" ]] && echo "  - ${t}"
    done <<<"$tags"
    echo "source: clipboard"
    echo "---"
    echo
    echo "$raw_text"

    if [[ -n "$related" ]]; then
      echo
      echo "## Related"
      while IFS= read -r link; do
        [[ -n "$link" ]] && echo "- ${link}"
      done <<<"$related"
    fi
  } > "$out_path"

  echo "SAVED_PATH=${out_path}"
  echo "CATEGORY=${category}"
  echo "TAGS=$(printf '%s' "$tags" | paste -sd ',' -)"
  if [[ -n "$related" ]]; then
    echo "RELATED=$(printf '%s' "$related" | paste -sd ',' -)"
  else
    echo "RELATED="
  fi
}

main "$@"
