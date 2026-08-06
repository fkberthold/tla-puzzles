# Dispatched-agents rule (tla-puzzles)

Loom's shipped conventions say to read this file before any dispatch. It is a
**fork** of loom's canonical `.claude/rules/dispatched-agents.md`, carrying the
battery in the form brief authors here need plus the hazards this project has and
loom does not. Lineage footer at the bottom.

Written 2026-08-06 after the v2 harness wave (`tla-kl5.4/.9/.10`), where the whole
battery was hand-copied into three briefs because this file did not exist. Three
copies, drifting from the moment they were written. That is what this file ends.

---

## Pre-flight smoke battery

**Run these as the FIRST bash calls of every dispatched-worker session, before
touching any file.** Abort and report if any check fails.

**Run each step as its OWN separate Bash call. This battery is not one pasteable
block.** The worktree-isolation harness statically verifies that every command
stays inside the worktree and refuses anything it cannot prove. Command
substitution (`$(...)`), brace grouping, and multi-statement `if … fi` blocks all
come back as *"too complex to verify that it stays inside the worktree; break it
into plain, separate commands. Refusing to run it."* A worker handed one big block
improvises a split nobody reviewed.

Each step is a plain command whose **output the worker reads and compares**. The
comparison is the agent's job, not the shell's — that inversion is what keeps
every step runnable under the harness.

**Step 0 — constitution.**

```bash
cat .claude/project-constitution.md
```

Information, not action. It tells you this project's runtime is `bash` and that
`canonical_commands` is **deliberately empty** — see the hazard below before you
reach for a test command.

**Step 1 — repo identity.**

```bash
git remote -v
```

The checkout you are in must BE the repo your brief names. `isolation: "worktree"`
worktrees the **dispatching session's** repo, whatever the brief claims — it does
not read the brief, and no parameter selects a different repo. The remote must
resolve to `tla-puzzles`. **If it names a different repo, ABORT and report. Do not
proceed, do not adapt, do not write anything.**

This is the one case where relative-path discipline turns against you: in a
wrong-repo worktree a relative path resolves to *that* repo's real file of the same
name, so obeying the brief is what does the damage.

**Step 2 — worktree, not main.**

```bash
git rev-parse --show-toplevel
```

Expect a path under `.claude/worktrees/agent-*`. **A bare `/home/frank/repos/tla-puzzles`
means you are in the MAIN tree** — the dispatcher omitted `isolation: "worktree"`,
and anything you commit lands on `main`. Abort and report.

Note why a `pwd == toplevel` check does not catch this: in the main tree, pwd *does*
equal toplevel. The discriminating signal is the path shape, not the equality.

**Step 3 — branch.**

```bash
git branch --show-current
```

Must not be `main`.

**Step 4 — bead state.**

```bash
bd list -n 1
```

Corroborates identity — ids must read `tla-…`. **Read-class only.** Do not run any
`bd` command that mutates state; beads are owned centrally by the dispatcher, and a
worker in a parallel wave that claims or closes will collide with its siblings.

**Step 5 — toolchain.**

```bash
tlc
```

Must report `TLC2 Version 2026.03.04.183147`. Every empirical constant in
`V2-PLAN.md` §5 — the exit-code table, the frozen-mapping probe, the
`total == 0` dead-action predicate — was verified against exactly this build. A
different version means the constants are hypotheses again; say so rather than
assuming they carried.

---

## Hazard — the beads pre-commit hook, and why `--no-verify` is required here

**This project inverts a prohibition other projects have.** `.git/hooks/pre-commit`
runs `bd hooks run pre-commit`, which re-exports `.beads/issues.jsonl`. In a
parallel wave every worker's commit would then carry that file, and every sibling
would collide on it — a guaranteed conflict on a file none of them meant to touch.

So, in this project, dispatched workers:

```
git add <explicit paths>     # NEVER `git add -A`
git commit --no-verify
```

`forbidden:` in `.claude/project-constitution.md` is empty, so `--no-verify` is
permitted here. Do not generalize that to other repos — liza_base, for one,
forbids it outright.

The re-export still happens in the worker's tree as an unstaged change. Leave it.
It dies with the worktree.

---

## Hazard — `canonical_commands` is deliberately empty

`scripts/` holds eight loom-scaffolded stubs whose bodies are all `exit 2`. The
constitution records `canonical_commands` as empty **on purpose**, because filling
in `scripts/test` while it fails by design would assert a canonical command that
lies. See bead `tla-xme`.

**Consequence for you: do NOT run `scripts/test`.** It will fail and tell you
nothing. Run the specific suite your bead owns. The v2 harness suites that exist
today, all runnable offline:

```
./harness/test-verdict.sh
./harness/comment-gate.sh --self-test
./harness/screen.sh --selftest
```

---

## Hazard — centrally-owned shared files

Some files are owned by the dispatcher precisely because two parallel beads would
otherwise both write them. **Treat them as read-only unless your brief explicitly
grants them.**

| File | Owner | Why |
|---|---|---|
| `harness/Gate.tla` | central | shared postcondition guards; §5.3 and §5.4 both consume it |
| `harness/verdict.sh` | `tla-kl5.4` | every component's TLC invocation goes through it |

If you need a shared file changed, **report it — do not edit it.** A brief that
grants you a file names it in your footprint; silence is not a grant.

---

## Hazard — `docs/` is generated

`docs/` is gitignored build output, produced by `scripts/build-docs.sh` from
`module-docs/`. Never edit it; edits are destroyed on the next build. Edit
`module-docs/` instead.

---

## Hazard — `puzzles/` is v1 and out of scope for v2 work

v2 replaces the content, not the infrastructure. `puzzles/` holds the v1 curriculum
and stays untouched by v2 beads. **Copy** fixtures out of it if you need real
specs; do not modify anything under it. The one exception is bead `tla-kl5.20`,
which rewrites `JUDGMENTS.md` and the `J01`–`J07` puzzles by design.

---

## On the way out — verify your own footprint

```bash
git diff --stat main HEAD
```

Never a `git -C <main-path>` redirect — the isolation harness refuses it. Compare
the result against your bead's declared `Files:` line and **report any deviation**,
including additions you think are obviously fine. `isolation: "worktree"` sets your
cwd; it does **not** sandbox the filesystem, so Edit/Write accept any absolute path
and an absolute path leaks into the shared checkout. Relative paths only.

---

## Claim provenance in your return

Every load-bearing claim carries **either** a citation — the command you ran and its
result, or a `file:line` — **or** the literal marker `INFERRED`. Never neither.

A citation is a **pointer, not a rationale**: it says where to look, not why to
believe, so no justifying sentence belongs in the slot. Reasoning stays wherever
your report already keeps it.

A report that blends verified claims with unverified ones at uniform confidence
lets the verified lend their credibility to the rest. You know the difference while
you are writing; state it then.

**Watch each test fail before you believe it.** A test that never failed is not
evidence. If a check contradicts what the brief or `V2-PLAN.md` told you to expect,
**do not silently adapt to match** — record the exact command and output and report
it as a discrepancy. Findings about the plan are worth more than a green test. The
`tla-kl5.4` wave produced three such corrections to §5.1, and each one was a real
defect in the plan.

---

## Lineage

Loom-side lineage for the sections adapted here: `loom-g5k` (smoke battery),
`loom-ta1w` (separate-calls battery, worker-side leak check), `loom-stdi` (repo
identity via `git remote -v`), `loom-ld4` (constitution as battery step 0),
`loom-myhi` (claim provenance), `loom-li8h` (background dispatch default). The
canonical copies live in loom's own `.claude/rules/dispatched-agents.md`; this file
is a **tla-puzzles fork** carrying local hazards loom does not have.

The main-tree-detection wording in step 2 comes from a liza_base finding
(2026-06-21): a dispatcher omitted `isolation: "worktree"`, the worker ran correctly
and committed to `main`, and the worker's own pre-flight passed because in the main
tree `pwd` does equal `toplevel`. Trust the *value* a worker reports from
`git rev-parse --show-toplevel`, never its prose self-description of where it is.

Filed as bead `tla-f4h`.
