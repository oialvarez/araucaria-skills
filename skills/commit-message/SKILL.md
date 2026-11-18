---
name: commit-message
description: "Oscar's commit message format: title with the Jira key, Problem, Solution as bullets, Jira ticket URL. Read before writing ANY commit message in his repos. Triggers on 'commitea', 'comitea', 'haz el commit', 'commit this', 'write the commit message', 'commit and push', 'amend', 'push', 'haz push'."
---

# Commit message

He creates the PR from the single commit's text, so the message has to stand on its own.
Write it in this shape and nothing more.

## Format

```
<JIRA-KEY>: <Imperative summary of the change>

Problem:
<High level. Two to four sentences. What is wrong or missing, from the user's point of
view. No file paths, no line numbers, no class names.>

Solution:
- <What changed, one bullet per change, shortest form that is still accurate>
- <Next change>

Jira ticket: <JIRA-BASE-URL>/browse/<JIRA-KEY>
```

`<JIRA-BASE-URL>` and the project's key prefixes come from the company overlay
(`~/.gemini/config/company.md`). If it has none, ask once.

Then the `Co-Authored-By` trailer the harness requires, after the Jira line.

## Committing

- Keep the diff to the real change. Never run Prettier on existing files.
- If the repo has `.husky/`, run its coverage gate by hand first (`sh npmw run coverage`, 10-minute
  timeout). If it fails, do not commit; show the failure and fix it.
- Commit with hooks off: `git -c core.hooksPath=/dev/null commit -F -`. Never mention the hook,
  its permissions or `chmod`.
- One commit per story: amend, then `git push --force-with-lease=<branch>:<old sha>`. Push only
  when he asks. Stage only your files, never `.agents/`, `.claude/`, `.gemini/` or `SKILL.md`.
- `gh` is fine for PRs, CI runs and `gh workflow run CI --ref <branch>`, never to create a PR.

## Rules

**Solution is bullets, cut to the bone.** No prose paragraphs. One line per change. If a
bullet needs a "because", keep it to a clause or leave it to a code comment.

**Never add a tests bullet.** No "added tests", no test counts, no suite results, no
coverage or lint status. Tests ship with the change; saying so is noise.

**Nothing beyond the four sections.** No "to look at in review", no "out of scope", no
"production implications", no verification checklist. If a reviewer needs to know
something that is neither Problem nor Solution, say it to him in chat and let him decide
whether it goes in the PR conversation. Never smuggle it into the commit.

**Problem stays high level.** `file:line` belongs in code comments and in Jira Technical
Details, never in the commit body. The reviewer reads the diff for the where.

**One commit per story.** Amend rather than stacking follow-ups, so the PR body stays a
single message.

## Example

```
SHOP-412: Show backordered items separately in the cart total

Problem:
The cart total counts backordered items together with items that ship today, so a
customer cannot tell how much of the order will arrive later. The backorder badge in the
item row also has no tooltip at all.

Solution:
- Split the total into two lines, Ships now / Backordered, each with its own label
- Decide on stock status rather than warehouse, since a drop-shipped item reports
  whatever warehouse the supplier sent
- Give the backorder badge its own tooltip
- Guard the total against the empty payload the cart seeds on first load

Jira ticket: https://example.atlassian.net/browse/SHOP-412
```
