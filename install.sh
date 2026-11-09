#!/usr/bin/env bash
# Wire this harness into Claude Code and Gemini / Antigravity. Safe to re-run.
#
#   ~/.claude/CLAUDE.md, ~/.gemini/GEMINI.md, ~/.gemini/config/GEMINI.md -> AGENTS.md
#   ~/.gemini/config/skills/<name>                                   -> skills/<name>
#   ~/.claude/skills, ~/.gemini/antigravity/skills                    -> ~/.gemini/config/skills
#
# Existing regular files are moved aside as <file>.bak-<timestamp>; real skill folders
# with the same name as a portable skill are left alone and reported.
set -euo pipefail

REPO="$(cd "$(dirname "$0")" && pwd)"
MERGED="$HOME/.gemini/config/skills"
OVERLAY="$HOME/.gemini/config/company.md"
STAMP="$(date +%Y%m%d-%H%M%S)"

link() { # link <source> <target>
  local src="$1" dst="$2"
  mkdir -p "$(dirname "$dst")"
  if [ -L "$dst" ]; then
    [ "$(readlink "$dst")" = "$src" ] && return
    rm "$dst"
  elif [ -e "$dst" ]; then
    if [ -d "$dst" ]; then
      echo "skip  $dst is a real directory, not replacing it" >&2
      return
    fi
    mv "$dst" "$dst.bak-$STAMP"
    echo "saved $dst.bak-$STAMP"
  fi
  ln -s "$src" "$dst"
  echo "link  $dst -> $src"
}

# Global instructions
link "$REPO/AGENTS.md" "$HOME/.claude/CLAUDE.md"
link "$REPO/AGENTS.md" "$HOME/.gemini/GEMINI.md"
link "$REPO/AGENTS.md" "$HOME/.gemini/config/GEMINI.md"

# Portable skills into the merged folder
mkdir -p "$MERGED"
for skill in "$REPO"/skills/*/; do
  skill="${skill%/}"
  link "$skill" "$MERGED/$(basename "$skill")"
done

# Drop links to skills that were renamed or removed from this repo
for entry in "$MERGED"/*; do
  if [ -L "$entry" ] && [ ! -e "$entry" ] && [[ "$(readlink "$entry")" == "$REPO"/* ]]; then
    rm "$entry"
    echo "unlink $entry (gone from repo)"
  fi
done

# Each agent reads the merged folder
link "$MERGED" "$HOME/.claude/skills"
[ -d "$HOME/.gemini/antigravity" ] && link "$MERGED" "$HOME/.gemini/antigravity/skills"

# The overlay AGENTS.md imports must exist, even if empty
if [ ! -e "$OVERLAY" ]; then
  printf '# Company overlay\n\nNothing company-specific yet. See the araucaria-skills README.\n' > "$OVERLAY"
  echo "made  $OVERLAY"
fi

# Claude settings are copied, not linked: Claude rewrites the file in place
[ -e "$HOME/.claude/settings.json" ] || { cp "$REPO/claude/settings.json" "$HOME/.claude/settings.json"; echo "copy  ~/.claude/settings.json"; }

echo "done"
