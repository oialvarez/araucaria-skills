---
name: teammate-comments
description: "Write paste-ready text that Oscar posts to teammates: Confluence comments, RFC review answers ('Confirmation needed'), Slack messages, PR review replies, Jira comments. Final form on the first pass, in the channel's language, sounding like a dev typing, not like an AI. Use when asked for 'comentarios', 'comentario en confluence', 'responde el RFC', 'confirmation needed', 'answers', 'mensaje para', 'slack', 'respuesta al PR', 'reply', 'más humano', 'que no parezca IA', 'pásame lo que pego'."
---

# Teammate Comments

Text Oscar copies and pastes to people who have the code open. It has to be postable as is:
no second pass through another reviewer to make it sound human, no translation.

Not for: Jira tickets/subtasks (use `ticket-definition`), Confluence page bodies (plain
language, no code blocks, tables over prose), commit messages (`commit-message`).

## Deliver final form, once

- Write in the language of the destination channel. Confluence, Jira, PRs and the team Slack
  are English, even when the conversation with Oscar is in Spanish.
- No report first and a rewrite later. Do the verification, then output the comments
  themselves. The chat wrapper around them is one line in Oscar's language, or nothing.
- One comment per item asked about, labelled only with its reference: **4.1**, **Q-3**,
  **PR line 120**. Never restate the question as a heading.

## Facts first, tone second

- Every technical claim is verified against code, logs or the source doc before it goes into
  a comment (global Verification Protocol). Unverified means it is not in the comment, or it
  is phrased as a question.
- When reworking tone, never change a fact. Compare each sentence against the verified
  version. A softened "uses the CALL_ENDED time" that becomes "uses now" is a regression.
- At most one `file:line` per comment, and only when it is the evidence for a gap or a
  correction. Everything else is named in plain words: the class, the job, the table.

## Shape

- 1 to 4 sentences per comment. Lead with the verdict: "Confirmed.", "+1.", "Agreed, but…",
  "I'd…", "Not quite:". Then the one fact or gap that matters. Stop.
- Lengths vary because content varies. If every comment has the same skeleton (verdict,
  bullets, closing line), rewrite until they don't.
- Bullets only for three or more truly parallel items. Two items are a sentence with "and".
- No headings inside a comment, no bold except the reference label, no code blocks, no
  backticks unless the reader will search for that exact string.
- Don't explain what the reader already knows from the doc they wrote. Don't recap the
  question. Don't add a closing summary or an offer ("let me know if…").

## Voice

First person, contractions, opinions stated as opinions ("I'd skip the script"). Short
connectors a dev actually types: "Heads up:", "One gap:", "Fine by me". Keep it flat: no
dramatic lead-ins ("Bigger catch:", "Big one:"), and no extra finding nobody asked about unless
it is verified end to end. A loose lead goes to Oscar in chat, not into the comment.

Never use these AI tells:

- em dashes or en dashes as punctuation (use a period, a colon or parentheses)
- "ensure", "make sure", "worth noting", "note that", "it's important to", "keep in mind"
- "straightforward", "seamless", "robust", "leverage", "comprehensive", "definitely"
- "Great question", "Looks good!", exclamation marks
- symmetrical triads ("fast, safe and simple"), "not only… but also"
- the section sign character; name sections by number ("4.1", "section 11")

## Self-check before output

1. Could Oscar paste every comment without editing a word?
2. Does each comment still say exactly what was verified, no more?
3. Scan for the banned list above. Scan for repeated skeletons.
4. Cut any sentence the reader would answer with "I know".

## Gold example

The real gold example lives in the company overlay (`~/.gemini/config/company.md`, section
"teammate-comments") because it quotes project code. Read it before writing. If there is no
overlay, the rules above are enough.
