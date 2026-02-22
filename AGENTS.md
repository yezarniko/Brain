# Vault Automation Rules

When the user says `save this as Vault` (or close variants like `save to vault`), execute the local vault-save workflow.

## Workflow

1. Prefer source text in this order:
   - Explicit text provided by the user in the current message.
   - Clipboard content via `scripts/clipboard.sh get`.
2. Run vault workflow commands outside the sandbox by default (escalated execution), without requiring the user to restate this each time.
3. Save the note by running:
   - `scripts/save_to_vault.sh` (clipboard source)
   - `scripts/save_to_vault.sh "<text>"` (explicit inline source)
4. The script will:
   - Create a Markdown file in `Notes/` by default.
   - Optional: set `VAULT_SAVE_DIR=<folder>` to use a different folder.
   - Auto-generate title and filename in format `NN.Natural Title.md` (e.g., `01.This is Natural Title.md`).
   - Auto-categorize (`idea`, `project`, `software-engineering`, `math`, `reference`).
   - Add tags based on content.
   - Add Obsidian wikilinks for matching existing note titles.
5. After saving, report back with:
   - Saved file path
   - Chosen category
   - Generated tags
   - Added related links (if any)

## Notes

- Keep existing vault files unchanged unless the user explicitly asks to modify them.
- If clipboard access fails (display/session issue), request explicit text input from the user.
