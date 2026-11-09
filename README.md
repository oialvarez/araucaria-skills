# araucaria-skills

My portable agent harness for Claude Code and Gemini / Antigravity: the global instructions and
the skills that would still be useful at another company. Nothing company-specific lives here.

## Layout

| Path | What it is |
|---|---|
| `AGENTS.md` | Global instructions. `~/.claude/CLAUDE.md` and `~/.gemini/GEMINI.md` are symlinks to it. |
| `skills/<name>/SKILL.md` | Portable skills, symlinked one by one into `~/.gemini/config/skills/`. |
| `docs/retired-pipeline.md` | Why the old SDLC phase pipeline was retired, so it is not rebuilt. |
| `claude/settings.json` | Claude Code settings, copied on install if none exist. |
| `install.sh` | Creates every link. Safe to re-run. |

## Two layers

```
~/workspace/araucaria-skills/      portable, versioned here
  AGENTS.md  ───────────────────── imports ──┐
  skills/sdlc-*, commit-message, ...         │
                                             ▼
~/.gemini/config/                  company layer, not versioned here
  company.md                       systems, URLs, prefixes, company skill list
  skills/                          merged folder: symlinks to portable skills
                                   + real folders for company skills
  skills-retired/

~/.claude/skills, ~/.gemini/antigravity/skills  ──▶  ~/.gemini/config/skills
```

Portable skills read company details (Jira base URL, ticket prefixes, gold examples) from
`company.md` instead of hard-coding them.

## New machine or new company

```bash
git clone git@github.com:oialvarez/araucaria-skills.git ~/workspace/araucaria-skills
~/workspace/araucaria-skills/install.sh
```

Then write the new company's `~/.gemini/config/company.md` and add its domain skills as real
folders in `~/.gemini/config/skills/`. When leaving a company, delete that overlay and its
skill folders; this repo stays.

`AGENTS.md` imports the overlay by absolute path (`@~/.gemini/config/company.md`), so keep that
location. Clone the repo anywhere; `install.sh` links from wherever it runs.

## Third-party skills (not copied here)

Installed with the `skills` CLI into `~/.agents/skills` (tracked in `~/.agents/.skill-lock.json`):

| Skill | Source |
|---|---|
| `find-skills` | vercel-labs/skills |
| `vercel-react-best-practices` | vercel-labs/agent-skills |
| `supabase-postgres-best-practices` | supabase/agent-skills |
| `brainstorming`, `writing-plans`, `executing-plans` | obra/superpowers |
