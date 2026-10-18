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

   **Never `git pull --rebase` here.** It flattens a `--no-ff` merge commit and
   rewrites every SHA after it, so the close reasons you just wrote point at
   commits that no longer exist. Fast-forward instead, which refuses rather than
   rewrites when the remote has moved. Hit on 2026-10-17 following this very
   checklist, with the hazard already in a bd memory that did not fire because a
   procedure beats a disposition.

   ```bash
   git fetch
   git merge --ff-only origin/main   # if this refuses, resolve it deliberately
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


## Session completion, the tla-puzzles addition

The checklist above is generated and carries a content hash, so anything
written inside it is lost on the next beads sync. This section extends it and
is ours to keep.

### Between "PUSH TO REMOTE" and "Clean up", verify the delivery

```bash
scripts/verify-delivery.sh
```

One command, every channel, writes nothing. It exits 0 when everything that
can be checked is in sync, 3 when a delivery is owed, and 1 when a channel
errors or when a `scripts/deliver-*.sh` exists that it does not know about.

Run it after the push rather than before. The repo is the source of truth and
the push is what settles it, so comparing against an unpushed tree compares
against something nobody else can see.

**When it exits 3**, back up `~/tla-practice` first, then run the delivery for
each channel it named. Never close the gap by editing the source to match the
delivered copy. That reverses the direction the whole channel runs in.

**It prints what it did not check, every run.** Three channels have no verify
mode yet and the bead for them is `tla-mjvx`. A run that said "in sync" while
silently skipping three channels would be the failure this step exists to
catch, wearing the uniform of its own fix.

**Conflicts are not failures.** A delivered file that differs from its
recorded digest is Frank's own work, and the only correct action is to leave
it alone. The script counts those and stays at 0. Measured on 2026-10-18: 93
files across the exercise chapters are his, and a check that failed on them
would have been red every night for a reason nobody can act on.

### Why this is not in cibuild

Frank ruled on 2026-10-18, on bead `tla-mjvx`. CI runs where no delivered tree
exists, so the check would skip there every single run and buy nothing. The
failure this catches is forgetting a step at the end of a session, which makes
the session-close ritual the only place it fires.

The underlying problem, for whoever reads this later: the repo had
`drill --style` for several hours and Frank's copy did not, because three
waves merged without anybody re-delivering. `~/tla-practice` is not a git repo
and no repo-level search reaches it, which is one of the two surfaces named
under Conventions and Patterns below.


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
