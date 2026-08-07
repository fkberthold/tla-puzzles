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
  # DELIBERATELY EMPTY (2026-08-05). /loom-adopt P2 scaffolded the 8
  # canonical script/ stubs into scripts/, but every one is still the
  # unedited `exit 2` "not implemented" body. Recording `scripts/test`
  # here would assert a canonical command that fails by design — the
  # exact lying-config failure the audit exists to prevent. Fill each
  # verb in as its script is actually wired (bead tla-xme).
  build: ""
  test: ""
  lint: ""
  gen: ""
  dev: ""
  # Migrated from the legacy workflow.json `.deploy` hint (loom-oxs.4
  # item-23 migration). This is a real, working command today.
  deploy: "mkdocs gh-deploy"

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
> - **Canonical commands**: currently empty by choice — see the
>   front-matter comment. Name which script each verb should point at
>   once wired.

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
