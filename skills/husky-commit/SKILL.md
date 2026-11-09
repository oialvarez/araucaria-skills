---
name: husky-commit
description: "How to commit or push in Oscar's repos that have a .husky/ directory: run the pre-commit's coverage gate by hand, never let Prettier reformat whole files, keep the diff to the real change. Use for EVERY git commit, amend or push in such a repo. Triggers on 'commitea', 'comitea', 'haz el commit', 'commit this', 'amend', 'push', 'haz push'."
---

# Husky commit

In Oscar's checkouts `.husky/pre-commit` and `npmw` are tracked as `100644`, so git skips the
hook with "hook was ignored because it's not set as executable". He knows. **Never mention it,
never tell him to `chmod`.**

Do **not** enable the hook. Its first step is `lint-staged`, which runs `prettier --write` on
every staged file as a whole. The committed Java is not Prettier-clean, so any touched file gets
rewritten (imports reordered, lines rewrapped) and a 10-line change shows up as 200 lines in the
PR. The PR must show the precise change.

## How

1. Never run Prettier on existing files. Keep the diff to the lines the change needs.
2. Run the hook's useful step by hand, the Jest coverage gate (10-minute timeout):

   ```bash
   sh npmw run coverage
   ```

   If it fails, the commit does not happen: show him the output and fix the cause.
3. Commit with hooks off, so nothing rewrites the staged files:

   ```bash
   git -c core.hooksPath=/dev/null commit -F - <<'EOF'
   <message from the commit-message skill>
   EOF
   ```

4. Check `git diff --stat origin/master HEAD`: the line counts must match the real change. If
   they look inflated, something reformatted a file; rebuild it from master with only the edit.

- The message format is the `commit-message` skill. Load it first.
- Stage only the files you changed. Never stage `.agents/`, `.claude/`, `.gemini/` or `SKILL.md`.
- One commit per story: amend rather than stack, then `git push --force-with-lease=<branch>:<old sha>`.

## After the commit

The next step is **push only**: `git push -u origin <branch>`. Do not offer to open a PR and do
not give `gh` instructions — `gh` is not installed and he opens PRs himself from the commit text.
Push only when he asks for it.
