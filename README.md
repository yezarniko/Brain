# Brain

Personal knowledge base and automation playground for the vault workflow described in `AGENTS.md`.

## Layout
- `Notes/` holds curated markdown reflections and writeups numbered for Obsidian-style navigation.
- `resources/` stores any collateral (screenshots, downloads, data dumps) that support those notes.
- `scripts/` contains helper utilities that glue clipboard content to the vault (see next section).
- `AGENTS.md` documents the rules to follow when adding or syncing content.

## Vault automation
1. Always refer back to `AGENTS.md` before saving anything new; it defines the workflow and categories.
2. Capture ideas by copying the text you want to save and running `scripts/save_to_vault.sh` (it pulls from the clipboard). When you already have the text, pass it inline: `scripts/save_to_vault.sh "<your note text>"`.
3. After the script runs it will categorize, tag, and link the note according to existing titles; the resulting Markdown lands in `Notes/` with an auto-generated filename.
4. Use `scripts/clipboard.sh get` if you need to confirm what text is currently in the clipboard before running the saver script.
5. `scripts/commit_vault_save.sh` wraps the save workflow with a git commit; use it whenever you want to checkpoint the vault and keep the `Notes/` directory tidy.

## Working with the repo
- Keep `.git` history clean; commit new notes and resource additions as separate logical steps when possible.
- This repository already targets `git@github.com:yezarniko/Brain.git` on `main`. Push changes via `git push` once you have commits ready.
- If you ever need to recreate the vault on a new machine, clone the repo, re-establish any needed remotes, and the scripts will continue to work as long as you have a clipboard utility in your shell.
