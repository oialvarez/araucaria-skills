---
name: ticket-definition
description: "Break a shell ticket into implementable tasks using Oscar's required format (title prefix, description, business value, acceptance criteria, technical details, production implications, story points). Use when asked to 'definir las tareas', 'define the tasks', 'break down this ticket', 'desglosar el ticket', 'reescribir las tareas', or when handed a shell/spike ticket with unrefined scope."
---

# Ticket Definition

Turn a shell ticket into implementable tasks. Output to chat first; never write to Jira without
explicit confirmation for that specific write.

## The ticket is high level. Full stop.

Just enough for someone else to pick it up and implement. Nobody should have to read a wall of
text, and nobody programs in Jira. Description and Business Value have length caps — treat them as
hard. Acceptance Criteria and Technical Details have none: complete beats short. A missing
criterion or path is what comes back from QA.

## The parent decides the scope

The parent bug or story always overrides its tasks, especially tasks we write. Tasks split the
parent's scope; they never narrow it.

Before writing any task, list what the parent asks for:

- Bug: every point of Actual Behavior, Steps to Reproduce and Expected Behavior.
- Story: every acceptance criterion.
- Both: every scope question or decision in the comments, and any question in the body.
- When the parent hands its mechanics to an RFC or design page ("the mechanics are in the RFC"),
  that page counts as parent text: every decision, every row of its delivery table and every
  follow-up it leaves to be ticketed is a parent point. Read the latest version before the code.

Then search the code for every path that touches what changes. For a bug, every place that writes
the affected fields. For a story, every screen, service or job that reads or writes what changes.
Split tasks by path or trigger of the behaviour, not by file.

Read the base branch, and also every open PR or branch already carrying the work (the Jira
Development panel, the RFC delivery table, `git branch -r | grep <KEY>`). Write "today" against
the base branch. In the coverage table, say what each open PR already does, so work in review is
not scoped as if it did not exist.

Before the tasks, show a coverage table in chat (never in the ticket): each parent point and each
path, with the task that covers it or "out of scope" and why. A parent point with no task is a
blocker to raise, not a follow-up.

This applies just the same when handed subtasks that already exist and only need implementing:
run the coverage before writing code, not after QA. When a decision overrides a parent point (for
example the parent expects the real duration and the decision is zero when unknown), list it as a
decision in the table and flag that it has to be recorded on the parent, or QA will test against
the original text.

If you find yourself explaining *why* an implementation choice is right, stop: that belongs in a
code comment or the PR, not the ticket.

## Tone: al hueso

Plain declarative sentences. State what changes and what it is for, nothing else. Cut any clause
that explains a consequence of a consequence, any "which means", "so that", "instead of", "today
the only way is", or scene-setting lead-in. A reader wants the fact, not the story. This applies
equally to Description and Business Value.

Bad: "Room events that reach the platform after their call has already ended are processed like
any other event today, so a late event can silently reopen or overwrite fields that were already
closed out when the call finished."

Good: "Room events for a call that already ended are processed today, and can overwrite its final
state."

If a sentence has more than one comma-joined clause, split it or cut the weaker clause.

## Paste safety

Pasted by hand into the Jira editor, which turns any indented line into its own code block.

- No fenced code blocks in a ticket body, no indented lines, no hard-wrapped sentences.
- One criterion or bullet is one unbroken line, however long.
- No tables or nested lists. No backticks in Acceptance Criteria.
- Separate tasks with a horizontal rule and a bold title line.

One exception: when the task defines or changes a wire contract, the payload example belongs in
the description under its own heading — that is what the consumer on the other side reads to
implement. Paste it as a single code block and nothing else as a code block. It must be the real
contract, copied from the DTOs, never composed from what the field names ought to be.

Any other snippet goes in chat, for a comment.

## Shape

**Title** — `[PREFIX] Imperative summary`. Prefix by where the changed code lives (one prefix
per repo or surface). The project's prefix list lives in the company overlay
(`~/.gemini/config/company.md`, section "ticket-definition"); if there is none, ask for it.

**Story Points** — 1, 2, 3, 5, 8. Risk and unknowns, not line count. 8 means split it.

**Description** — two to four sentences. What changes, in behaviour terms. No file paths. One
sentence if prior work already covers part of the scope.

**Business Value** — one or two plain sentences on what the business gains. Phrase it as the
capability gained, never as the deficiency: "cannot tell", "has no way to", "today the only way
is" all read as a bug report, not as value. No regulatory framing, no cost or risk escalation,
no rhetorical contrasts.

**Acceptance Criteria** — numbered, as many as the covered parent points need. Each one
observable by QA on a screen or in a payload, described in plain words: what the user or the
operator sees, not the identifiers behind it. No enum values, no field names, no class names — the
contract payload already carries the literals. No implementation steps. For a bug, one criterion
restates the parent's reproduction end state for the path this task covers; for a story, each
parent criterion the task covers appears as a criterion.

**Technical Details** — one bullet per path the task touches, each with `file:line`. A pointer,
not an explanation: name the class or migration and stop. These are where to start, not the
scope: the parent is the scope. If an acceptance criterion requires
something to be observable (a count, a status, a signal), one bullet must state it as a checkable
requirement, not a style reference: level, the specific fields it must carry, and whether it fires
once per occurrence or as a batch/periodic count. "Matching file:line" alone is not enough — a
reviewer must be able to look at the diff and say yes/no, not "close enough." Verify the cited
precedent actually has the same shape (per-occurrence vs batch) before citing it — citing the
wrong one is worse than citing none. Include dependencies on other tasks and any decision that has
to be settled first: name the task or the decision, never a person. Drop a dependency bullet if it
does not block or change the work.

**Production Implications** — what could regress, what to watch after deploy. "None" when true;
never omit.

## Rules

- Verify against the code before claiming anything. That is about your confidence, not the text.
- Never cite a `file:line` you have not opened.
- No VERIFIED / UNVERIFIED labels and no commit archaeology in a ticket. Those go in chat.
- Do not invent payloads or fields. A missing contract is stated as missing.
- Tests ship inside the task that changes the behaviour. Never a test-only task, never a tests
  bullet. QA creates its own `[QA] Test design` and `[QA] Story validation` sub-tasks; never
  draft them.
- A criterion that points at a design nobody has made yet ("matches the design", new banner
  wording) is a dependency, not a criterion: give it a `[Design]` task and name it in the
  dependent tasks.
- Use the story's and the UI's words. Grep any term you coined before using it.
- Say in one sentence when prior work already satisfies part of the scope.
- Product or design intent unknowns become a criterion. Scope unknowns (which path, which trigger,
  which cleanup) are answered by searching the code, or asked in chat before output — never
  left implicit.
- Check whether a component, service or job is used by more than one screen or flow; if so, cover
  each one or say why it is out of scope.
- Re-estimate rather than inherit a stale story estimate.
- Before output, reread Description and Business Value against the Tone section above and cut
  anything that reads like narration.
- Never name a teammate anywhere in a ticket. Talk about the artifact, approach, or result — not
  who is building it or whose idea it was.
