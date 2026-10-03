# Project Instructions for AI Agents

This file provides instructions and context for AI coding agents working on this project.

<!-- BEGIN BEADS INTEGRATION v:1 profile:minimal hash:ca08a54f -->
## Beads Issue Tracker

This project uses **bd (beads)** for issue tracking. Run `bd prime` to see full workflow context and commands.

### Quick Reference

```bash
bd ready              # Find available work
bd show <id>          # View issue details
bd update <id> --claim  # Claim work
bd close <id>         # Complete work
```

### Rules

- Use `bd` for ALL task tracking — do NOT use TodoWrite, TaskCreate, or markdown TODO lists
- Run `bd prime` for detailed command reference and session close protocol
- Use `bd remember` for persistent knowledge — do NOT use MEMORY.md files

## Session Completion

**When ending a work session**, you MUST complete ALL steps below. Work is NOT complete until `git push` succeeds.

**MANDATORY WORKFLOW:**

1. **File issues for remaining work** - Create issues for anything that needs follow-up
2. **Run quality gates** (if code changed) - Tests, linters, builds
3. **Update issue status** - Close finished work, update in-progress items
4. **PUSH TO REMOTE** - This is MANDATORY:
   ```bash
   git pull --rebase
   if bd dolt remote list --json 2>/dev/null | grep -q '"name"'; then
     bd dolt push
   else
     echo "(solo bd workspace; no Dolt remote — skipping bd dolt push)"
   fi
   git push
   git status  # MUST show "up to date with origin"
   ```
5. **Clean up** - Clear stashes, prune remote branches
6. **Verify** - All changes committed AND pushed
7. **Hand off** - Provide context for next session

**CRITICAL RULES:**
- Work is NOT complete until `git push` succeeds
- NEVER stop before pushing - that leaves work stranded locally
- NEVER say "ready to push when you are" - YOU must push
- If push fails, resolve and retry until it succeeds
<!-- END BEADS INTEGRATION -->


## Build & Test

_Add your build and test commands here_

```bash
# Example:
# npm install
# npm test
```

## Architecture Overview

_Add a brief overview of your project architecture_

## Conventions & Patterns

### A claim of absence or completeness names its search

Before writing that something doesn't exist, isn't used, or is the whole set, say
which surfaces you looked at. Then ask the question that actually catches it: which
surface would I expect this in that I didn't check?

This is a procedure, not a disposition. Four separate errors in one session on
2026-10-02 had this shape. A general instruction to be careful with recalled facts
was already in place and it didn't fire.

- "The reaction log has no home." It's at `~/tla-practice/REACTIONS.md`, since 09-05.
- "The load vector is locked and not reopened." `PRACTICE-PLAN.md:166` retires it.
- A delivery manifest guessed rather than found. It deleted 39 delivered files, then
  three shipped starters.
- `bd update --notes` written over a note that said the opposite. Only bd's
  after-the-fact warning caught it.

The first two are claims about absence. The second two are claims about a complete
set. All four came from searching a real surface and stopping there.

**The surfaces this project has, and the two that get missed:**

| surface | how to search it |
|---|---|
| the repo | `git ls-files`, `grep -r` |
| the tracker | `bd search`, `bd list --limit 0` |
| decision drawers | `mempalace_search` scoped to wing `tla_puzzles` |
| tribal one-liners | `bd memories <keyword>` |
| **the delivered practice tree** | `find ~/tla-practice` |
| **the live plan against the drawer that locked a decision** | both, not either |

`~/tla-practice/` is not a git repo and no repo-level search reaches it. It holds the
delivered problems, the attempt logs, `REACTIONS.md` and the backups.

A drawer is an append-only claim about its own date. It never says it was
superseded, so its silence is not evidence. When a decision came from a drawer,
check it against the live plan file before building on it.

### Read before you write over

`bd update --notes` replaces and warns afterwards. Use `--append-notes`. The same
holds for `mempalace_update_drawer`, which takes the whole body, and for any file
you're about to overwrite. Recovery for a bead note is
`git show <sha>:.beads/issues.jsonl`, which is one reason that export stays
committed and fresh.

## Loom's shipped conventions

Loom's project-agnostic working conventions — dispatch defaults, the
`Files:` / `RED:` / `AUTOFAN-EXCLUDE:` bead lines, the splitting
heuristic, drawer-first capture, gate-don't-advise, and the
explore → design → build ladder — live in
[`.claude/rules/loom-conventions.md`](.claude/rules/loom-conventions.md).

**Do not edit that file.** Loom owns it and overwrites it in place on
every resync (`/audit-project --apply-drift`). Project-specific rules
belong here in `CLAUDE.md` and in your own `.claude/rules/*.md`, which
loom never touches.
