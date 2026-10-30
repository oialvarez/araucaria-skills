# araucaria-skills

General-purpose agent skills (not tied to any one company or codebase).

Each folder is linked from `~/.gemini/config/skills/<name>`, which Claude reads via `~/.claude/skills`
and Gemini via `~/.gemini/antigravity/skills`.

## Own skills

- `sdlc-architect`, `sdlc-discovery`, `sdlc-qa-engineer`
- `sdlc-developer-frontend`
- `sdlc-code-reviewer-backend`, `sdlc-code-reviewer-frontend`
- `sdlc-security-gate`, `sdlc-dba`, `sdlc-observability`
- `java-version-management`

## Third-party skills (not copied here)

Installed with the `skills` CLI into `~/.agents/skills` (tracked in `~/.agents/.skill-lock.json`):

| Skill | Source |
|---|---|
| `find-skills` | vercel-labs/skills |
| `vercel-react-best-practices` | vercel-labs/agent-skills |
| `supabase-postgres-best-practices` | supabase/agent-skills |
| `brainstorming`, `writing-plans`, `executing-plans` | obra/superpowers |
