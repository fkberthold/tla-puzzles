# TLA+ Practice Puzzles

A 106-puzzle progressive curriculum for learning **TLA+** and **PlusCal** by doing — small, self-contained exercises that each teach one new concept and verify with `tlc` (and, where annotated, `apalache`).

Modeled on the [99 Prolog Problems](https://www.ic.unicamp.br/~meidanis/courses/mc336/2009s2/prolog/problemas/). Designed for engineers who want a hands-on path from "I've heard of TLA+" to "I can specify a distributed system and verify both safety and liveness."

📖 **Browse the rendered curriculum**: [fkberthold.github.io/tla-puzzles](https://fkberthold.github.io/tla-puzzles/)

---

## What this teaches

- **Tier 0 — Prelude (5):** the toolchain. Run TLC, read a counterexample, edit a `.cfg`, understand what `tlc -pcal` does.
- **Tier 1 — PlusCal Basics (8):** variables, processes, labels, loops, nondeterminism (`with`, `either/or`), assertions, the `define` block, TLC as a debugger.
- **Tier 2 — PlusCal Data Structures (20):** records, sequences, functions (constructor / EXCEPT / `@` / function sets), set comprehension, cardinality, CHOOSE, IF/CASE, LET-IN, quantifiers.
- **Tier 3 — Pure TLA+ Pivot (11):** the relational view. Init / Next / Spec, UNCHANGED, action disjunction, the level system, `[A]_v`, weak fairness.
- **Tier 4 — Multi-Process & Synchronization (10):** distinct processes, `await`, ENABLED, producer/consumer, mini-mutex, procedures, cross-tier capstone.
- **Tier 5 — Temporal Logic & Fairness (12):** `<>`, `[]`, `~>`, `[]<>`, `<>[]`, strong fairness, liveness debugging, lasso traces.
- **Tier 6 — Specification Structure & Refinement (13):** CONSTANTS, ASSUME, multi-module specs, INSTANCE, refinement (abstract / concrete / mapping / auxiliary variables / stuttering / debugging), cross-tier capstone.
- **Tier 7 — Production Craft (9):** SYMMETRY, VIEW, model values, `-coverage`, `-simulate`, `-difftrace`, boundary values.
- **Apalache Track (10):** symbolic verification — type annotations, snowcat, `:=` assignments, ApaFoldSet, `--cinit`, joint TLC/Apalache capstone.
- **Judgment Intersticials (7):** *when* to use which technique — records vs separate variables, PlusCal vs pure TLA+, TLC vs Apalache, when to use refinement, fairness types, safety vs liveness, label split vs combine. See [JUDGMENTS.md](JUDGMENTS.md) for the consolidated decision tree.
- **Final Capstone (1):** a distributed counter with refinement, strong fairness, leads-to, and Apalache types — composing eight techniques in one runnable spec.

Full ordered list with concept tags: [CURRICULUM_MAP.md](CURRICULUM_MAP.md).

---

## How to use

Each puzzle lives in `puzzles/<id>-<slug>/` with this layout:

```
puzzles/T01-the-light-switch/
├── README.md                    # lesson + worked example + setup + task + check + expected
└── solution/
    ├── LightSwitch.tla          # PlusCal source (or pure TLA+ from Tier 3 onward)
    └── LightSwitch.cfg          # TLC config
```

Workflow per puzzle:

1. Read `README.md` — internalize the lesson and the worked example.
2. Write your own attempt (don't peek at `solution/`).
3. For PlusCal: `tlc -pcal YourSpec.tla` to translate, then `tlc YourSpec` to model-check.
4. For pure TLA+ (Tier 3+): just `tlc YourSpec`.
5. For Apalache puzzles: `apalache check --inv=<Inv> [--cinit=ConstInit] YourSpec.tla`.
6. Compare your spec to `solution/`. Confirm state counts and outcomes match the README's "Expected Result" section.

---

## Requirements

- **Java 17+** (for both TLC and Apalache)
- **TLA+ tools** — `pcal` and `tlc` on `$PATH`. Get [tla2tools.jar](https://github.com/tlaplus/tlaplus/releases) and wrap it; this repo's author uses `~/bin/tlc`:
  ```bash
  #!/usr/bin/env bash
  JAR="$HOME/lib/tla2tools.jar"
  if [ "$1" = "-pcal" ]; then shift; exec java -cp "$JAR" pcal.trans "$@"
  else exec java -cp "$JAR" tlc2.TLC "$@"; fi
  ```
- **Apalache** *(optional, required for the Apalache track)* — install from [apalache-mc/apalache releases](https://github.com/apalache-mc/apalache/releases). The Apalache puzzles ship the official `Apalache.tla` module locally so both tools resolve `EXTENDS Apalache` to the same file.

---

## Difficulty calibration

- ⭐ — ~15 minutes for someone who solved the immediately preceding puzzle
- ⭐⭐ — ~30 minutes
- ⭐⭐⭐ — ~60+ minutes (capstones, refinement, multi-step composition)

If a puzzle takes you significantly longer, check the prerequisites in CURRICULUM_MAP.md — you may have skipped one.

---

## Quality gate

Every puzzle passes [seven checks](QUALITY_GATE.md) before inclusion: concept uniqueness, minimal novelty, the strip test, the 15-minute test, TLC verification, trace quality, and demonstration-puzzle domain disjointness.

The intent: each puzzle teaches **exactly one** new concept, the lesson's worked example uses a **different domain** from the puzzle setting (so a learner can't shortcut by renaming), and the curriculum is **fully self-contained** (verified end-to-end by a from-scratch learner walk-through).

---

## Repository layout

```
tla-puzzles/
├── README.md                    # this file
├── CURRICULUM_MAP.md            # auto-generated curriculum index
├── QUALITY_GATE.md              # the seven checks every puzzle must pass
├── JUDGMENTS.md                 # consolidated decision tree for the seven J-puzzles
├── LICENSE                      # MIT
├── puzzles/                     # the curriculum
│   ├── T0a-first-run-hello-tlc/
│   ├── T01-the-light-switch/
│   ├── ... (106 dirs)
│   └── T67-distributed-counter/
├── scripts/
│   └── gen-curriculum-map.sh    # regenerates CURRICULUM_MAP.md from bd state
├── docs/                        # MkDocs sources for the rendered site
└── mkdocs.yml                   # site config
```

---

## Contributing a new puzzle

1. Read [QUALITY_GATE.md](QUALITY_GATE.md) — every check must pass.
2. Pick a single concept. If your puzzle teaches two, split it.
3. Author `puzzles/<id>-<slug>/`:
   - `README.md` with lesson (worked example in a different domain) + setup + task + check + expected
   - `solution/<Name>.tla` (PlusCal preferred for Tier 1-2; pure TLA+ from Tier 3)
   - `solution/<Name>.cfg`
4. Verify locally: `tlc -pcal <Name>.tla && tlc <Name>` (or just `tlc <Name>` for pure TLA+).
5. Confirm the README's "Expected Result" matches what TLC actually produces — exact state counts, trace lengths.
6. Submit a PR. CI runs TLC on every puzzle change.

---

## License

MIT — see [LICENSE](LICENSE).
