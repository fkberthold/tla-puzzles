---
# Project constitution — YAML front-matter
#
# Captured 2026-08-05 by /loom-adopt P5 (audit-project --check=constitution).
# Front-matter is agent-detected + human-confirmed field by field.
# The prose body below is a [HUMAN AUTHOR] stub — loom never writes it.

shell:
  # No devbox.json and no flake.nix at the project root.
  enter: ""
  run_prefix: ""

# Detector reported `none` (no lockfile, no manifest). Corrected to `pip`
# on 2026-08-05: docs-requirements.txt pins mkdocs-material and
# mkdocs-awesome-pages-plugin, so the docs toolchain is pip-installed.
# The detector's `requirements*.txt` glob does not match the
# `docs-requirements.txt` filename.
package_manager: pip

language:
  # Primary runtime is shell: build-docs.sh, verify-puzzle.sh,
  # test-verify-puzzle.sh, gen-curriculum-map.sh, and the whole v2
  # harness/ tree. TLA+/PlusCal is the subject matter, not a schema
  # runtime value.
  #
  # python3 is a SECONDARY runtime, approved by Frank 2026-08-07.
  # Originally the two build-*.py docs helpers; now also a real
  # dependency of harness/refinement.sh, which parses TLC's
  # -dumpTrace JSON to tell an initial-state probe violation from
  # genuine movement. That parsing is why it is worth the dependency:
  # the alternative is scraping TLC's console text, which this project
  # forbids itself (V2-PLAN.md §5.1 — verdicts come from exit codes,
  # never from stdout). Guarded with an explicit up-front check so a
  # missing interpreter fails loudly rather than midway.
  runtime: bash
  version: ""

# Not auto-detected — a human authors these when a lock-in posture exists.
forbidden: []

canonical_commands:
  # FILLED IN 2026-08-07 by bead tla-xme. All 8 loom script/ stubs are now
  # either wired or explicitly N/A — none is still an `exit 2` stub — so the
  # verbs below name commands that do what they say.
  #
  # What each verb points at, and what is still deliberately empty:
  #
  #   build  — EMPTY. There is no scripts/build entry point; the real build
  #            (scripts/build-docs.sh + mkdocs build) is phase 4 of
  #            scripts/cibuild, which is where CI should call it. Promote it
  #            to a verb only if a standalone scripts/build ever exists.
  #   gen    — scripts/gen-curriculum-map.sh: regenerates CURRICULUM_MAP.md
  #            from bd state. FILLED 2026-08-07 by bead tla-1hf, which removed
  #            the blocker recorded here. It used to hardcode
  #            `cd /home/frank/repos/tla-puzzles` at line 5, so running it from
  #            a worktree wrote CURRICULUM_MAP.md into the MAIN checkout — a
  #            silent cross-tree write, and the reason tla-xme could not fill
  #            this verb. The cd now resolves from ${BASH_SOURCE[0]}, so the
  #            script writes into whichever checkout it is invoked from and is
  #            safe for a dispatched worker to run.
  #   test   — all ten suites, 292 harness assertions, ~121 s. `--fast` trims
  #            it to a 4 s tier, but the canonical command is the whole gate;
  #            recording the fast tier here would name a command that runs 37%
  #            of the assertions, which is the same class of lie as naming one
  #            that fails by design.
  #   lint   — shellcheck over scripts/ + harness/, at default severity.
  #            HONEST STATUS: green since 2026-08-07. tla-5r7 closed all 26
  #            findings, and seven sites carry a per-site disable with the
  #            reason above it. Re-verified 2026-08-08, 28 files clean. Keep
  #            it green by fixing the finding or justifying the one site,
  #            never by lowering severity or adding a blanket exclude.
  #   dev    — scripts/server: regenerates docs/ then `mkdocs serve`.
  #   deploy — was "mkdocs gh-deploy" (migrated from the legacy workflow.json
  #            .deploy hint, loom-oxs.4 item-23). Now points at scripts/deploy,
  #            which runs build-docs.sh first — bare gh-deploy would publish a
  #            stale docs/ tree. NOTE: scripts/deploy REFUSES without --yes, on
  #            purpose. Routine deploys happen by pushing to main
  #            (.github/workflows/pages.yml); gh-deploy force-pushes a gh-pages
  #            branch that this repo does not currently serve from.
  #
  # Not represented here because loom's schema has no verb for them:
  # scripts/bootstrap (prerequisite check), scripts/setup (pinned TLA+
  # toolchain + docs deps), scripts/update (delegates to setup),
  # scripts/cibuild (the CI superset).
  build: ""
  test: "bash scripts/test"
  lint: "bash scripts/lint"
  gen: "bash scripts/gen-curriculum-map.sh"
  dev: "bash scripts/server"
  deploy: "bash scripts/deploy"

# Not auto-detected — a human authors these.
bypass_patterns: []

# No architectural invariant declared yet. Uncomment and adapt when one
# is agreed. Candidate for v2: forbid direct edits under docs/, which is
# generated build output overwritten on every scripts/build-docs.sh run.
#
# invariants:
#   - id: no-direct-generated-docs-edit
#     applies_to:
#       - Write
#       - Edit
#       - MultiEdit
#     deny_pattern: "/docs/"
#     message: "docs/ is generated build output — edit module-docs/ and run scripts/build-docs.sh."
---

# tla-puzzles — project constitution

> [HUMAN AUTHOR] TODO: One-paragraph statement of what this constitution
> is for and who reads it. Ground it in the project's mission — building
> fluency in thinking in TLA+/PlusCal — rather than leaving it floating.

## Tooling choices

> [HUMAN AUTHOR] TODO: Explain *why* the front-matter values are what
> they are. Points worth covering:
>
> - **Shell**: no wrapper — why plain shell is sufficient here.
> - **Package manager**: `pip`, but only for the docs toolchain. Is that
>   the intended long-term story, or does v2's problem-generation and
>   validation tooling change it?
> - **Language**: `bash` primary. Does that hold if the v2 validation
>   harness (blind-solver + TLC gate) is written in Python?
> - **Canonical commands**: filled in 2026-08-07 (bead tla-xme) — no
>   longer empty. `gen` followed on 2026-08-07 (bead tla-1hf). `build`
>   is still blank for the reason the front-matter comment records.
>   Worth saying in prose why `test` is
>   the whole ~2-minute gate rather than the 4-second fast tier.

## Forbidden patterns

> [HUMAN AUTHOR] TODO: `forbidden` is empty. If a lock-in posture is
> wanted (e.g. forbidding direct `tlc` invocation in favor of
> scripts/verify-puzzle.sh so every check goes through one harness),
> declare it here and name the failure mode it guards against.

## Bypass patterns

> [HUMAN AUTHOR] TODO: `bypass_patterns` is empty. Add entries only if a
> `forbidden` rule needs a documented escape hatch.

## Lineage

> [HUMAN AUTHOR] TODO: Beads and decision drawers that informed these
> choices. Starting points:
>
> - Captured by `/loom-adopt` P5, 2026-08-05.
> - Audit findings: `drawer_tla_puzzles_decisions_c773a45acf4d1912dc2673bb`
> - 35 `provenance:mined` decision drawers filed into `tla_puzzles/decisions`
>   the same day, covering the v1 curriculum's design rationale.
> - `tla-9ic` — bd preflight runs Go-hardcoded checks here.
