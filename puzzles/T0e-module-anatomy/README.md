# T0e: Anatomy of a TLA+ Module ⭐

**Tier 0 prelude.** No new concept beyond syntax. The goal is to recognize every part of a TLA+ source file so you can write one yourself in T01.

## Why this puzzle exists

T0a–T0d ran a pre-written file end-to-end. T01 will ask you to *write* a spec from scratch. Between those two, you need to know what a `.tla` file actually looks like — its required wrapper, what goes where, and which parts are PlusCal versus pure TLA+. This puzzle dissects a working module to make those pieces explicit.

## A complete TLA+ module — annotated

Save this as `Counter.tla`:

```
---- MODULE Counter ----            ◀ (1) MODULE header — name MUST match filename
EXTENDS Integers                    ◀ (2) standard-library imports

(*--algorithm Counter {             ◀ (3) PlusCal block — opens with this exact comment
  variables n = 0;                  ◀ (4) PlusCal-level variable declaration

  define {                          ◀ (5) named operators (TLA+ definitions)
    TypeOK == n \in 0..3
  }

  fair process (counter = "Counter") {
    bump:                           ◀ (6) label — atomic step
      while (n < 3) {
        n := n + 1;
      }
  }
}
*)                                  ◀ (7) PlusCal block close

\* BEGIN TRANSLATION (...)          ◀ (8) pcal will append the translation here
\* ... TLA+ Init / Next / Spec ...
\* END TRANSLATION

====                                ◀ (9) MODULE close — exactly four equals
```

And its `Counter.cfg`:

```
SPECIFICATION Spec
INVARIANT TypeOK
```

### The nine module elements

1. **Module header**: `---- MODULE <Name> ----`. The dashes are at least four; conventional is exactly four. The name **must** match the filename. `Counter.tla` ↔ `MODULE Counter`. Mismatch is the most common "why won't TLC parse this?" mistake.

2. **EXTENDS** (optional): brings in standard-library modules. Common imports: `Integers`, `Naturals`, `Sequences`, `FiniteSets`, `TLC`. Multiple imports comma-separated: `EXTENDS Integers, Sequences`. Always sits near the top, right after `MODULE`.

3. **PlusCal block opener**: `(*--algorithm <Name> {`. The `(*` is a TLA+ block-comment opener; from TLA+'s perspective the entire PlusCal block is *just a comment*. The `--algorithm` keyword is what `tlc -pcal` looks for. The `<Name>` here is conventionally the module name.

4. **`variables`** (PlusCal): declares mutable state. Initial values can be assigned inline (`n = 0`) or left to a non-deterministic choice (`n \in 0..3`). Lives INSIDE the PlusCal block.

5. **`define { ... }`** (PlusCal): named TLA+ operators that are visible everywhere in the module. Pcal copies them out into the translation. T06 covers this in detail.

6. **Labels**: an identifier ending in `:` marks an atomic step. Code between two labels happens as one indivisible action. Labels are how PlusCal expresses the granularity of concurrency. T04 covers label boundaries.

7. **PlusCal block closer**: `*)`. This closes the TLA+ block-comment that started with `(*` in (3).

8. **`\* BEGIN TRANSLATION` / `\* END TRANSLATION`**: pcal's auto-generated TLA+ goes here. **Do not edit between these markers** — pcal regenerates them every run. If you need custom TLA+ helpers, put them *outside* the markers (above `BEGIN TRANSLATION` or below `END TRANSLATION`).

9. **Module close**: `====`. Four equals signs. Whatever comes after this line in the file is ignored. Forgetting it is a parse error.

## Module-level vs PlusCal-internal declarations

Some declarations belong INSIDE the `(*--algorithm ... *)` block, some belong OUTSIDE (at the module level). The distinction matters:

- **Inside** the PlusCal block:
  - `variables` (PlusCal style)
  - `define { ... }` for operators visible in PlusCal code
  - `fair process`, labels, statements
- **Outside** the PlusCal block (at module level):
  - `EXTENDS` (always at top)
  - `CONSTANT` declarations — parameters the cfg fills in (T0c showed this with `MaxTicks`; T50 covers it)
  - Hand-written TLA+ operators that don't reference primed variables (you can also put these in `define`; outside is needed for stateless helpers used at the module level)
  - `ASSUME` clauses (T50)
  - `INSTANCE` clauses (T52)

When you reach Tier 3 you'll write specs without the PlusCal block at all — just `Init`, `Next`, `Spec`, and your invariants directly between `MODULE` and `====`. T0d showed you what that translated TLA+ looks like. T26 onward writes it directly.

## Run it (sanity check)

From the directory containing `Counter.tla` and `Counter.cfg`:

```bash
tlc -pcal Counter.tla
tlc Counter
```

Expected: 5 distinct states (initial + 3 bumps + done), no errors. The point isn't the count — it's that you now recognize every line of what just ran.

## What to take away

- A `.tla` file is `MODULE` + `EXTENDS` + body + `====`. The wrapper is non-negotiable; forgetting it gives parse errors.
- The PlusCal block sits inside a TLA+ comment `(* ... *)`. To TLA+ semantics, your PlusCal source is *invisible* — only the translation block (8) matters at check time.
- Pcal owns the `\* BEGIN TRANSLATION` block. Hands off.
- Module-level vs PlusCal-internal placement matters: `CONSTANT` outside, `variables` inside.
- The filename must match the module name.

You now have the structural literacy to write your own spec. T01 starts that.

## Hints

??? hint "💡 Hint 1 — The single most common parse error"
    If TLC says "module Foo not found" or "expected ====", check the very first line and the very last line of your file. They're the wrapper and they MUST be there. Filename and module name must match exactly (case-sensitive).

??? hint "💡 Hint 2 — Where does CONSTANT go?"
    T0c showed `CONSTANT MaxTicks` at the top of the file, OUTSIDE the `(*--algorithm ... *)` block. CONSTANTs are parameters the cfg fills in — they're at the module's interface, not part of the algorithm. Inside the PlusCal block, you use `variables` for mutable state.

??? hint "💡 Hint 3 — Don't edit between the TRANSLATION markers"
    `\* BEGIN TRANSLATION ... \* END TRANSLATION` is pcal's territory. Every `tlc -pcal` run regenerates it. If you need custom TLA+ that pcal can't express, put it ABOVE the BEGIN line or BELOW the END line — not in between.
