# T0d: pcal — The Translator ⭐

**Tier 0 prelude.** No new concept. The goal is to understand what `tlc -pcal` actually does to your file: it's a deterministic source-to-source translator that turns PlusCal into ordinary TLA+. No magic.

## What this puzzle is

A pre-written PlusCal spec — the smallest possible: a single boolean `on` that gets toggled exactly once. You will translate it, then read both halves of the output file side-by-side and map each PlusCal construct to the TLA+ it became.

## The spec

Save these two files into a working directory.

`Switch.tla`:

```
---- MODULE Switch ----

(*--algorithm Switch {
  variables on = FALSE;

  fair process (toggler = "Toggler") {
    flip:
      on := ~on;
  }
}
*)
\* BEGIN TRANSLATION
\* END TRANSLATION
====
```

`Switch.cfg`:

```
SPECIFICATION Spec
```

## Run it

From the directory containing both files:

```bash
cat Switch.tla        # see the original — about 13 lines, with empty markers
tlc -pcal Switch.tla
cat Switch.tla        # see what got filled in — about 30 more lines between the markers
tlc Switch
```

The first `cat` shows your input: a `(*--algorithm Switch { ... } *)` block sitting inside a TLA+ comment, plus an empty `\* BEGIN TRANSLATION` / `\* END TRANSLATION` placeholder. The second `cat` shows the input *unchanged*, with the empty placeholder now filled in by pcal. The TLC run uses only the translated part.

Expected: TLC reports 2 distinct states (`on=FALSE`, then `on=TRUE`) with no errors.

## What pcal generated

After `tlc -pcal`, the file contains your original 11-line PlusCal program plus a translation block. Walk through the mapping line by line:

### Variables

PlusCal:
```
variables on = FALSE;
```
Translation:
```
VARIABLES pc, on
...
Init == /\ on = FALSE
        /\ pc = [self \in ProcSet |-> "flip"]
```

pcal added `pc` — a hidden "program counter" that tracks which label each process is at. Every PlusCal program gets one. The initial value of `pc` is `"flip"` because that's the first label of the only process.

### The label

PlusCal:
```
flip:
  on := ~on;
```
Translation:
```
flip == /\ pc["Toggler"] = "flip"
        /\ on' = ~on
        /\ pc' = [pc EXCEPT !["Toggler"] = "Done"]
```

A label becomes a TLA+ definition. The body says: "we can take this step when `pc` is at `flip`. Taking it sets `on'` (the next-state value) to `~on`, and advances `pc` to `Done`." The single PlusCal statement `on := ~on` becomes `on' = ~on`. The `:=` is procedural; the `'` is relational. Same intent, different formalism.

### The process

PlusCal:
```
fair process (toggler = "Toggler") { ... }
```
Translation:
```
toggler == flip

Spec == /\ Init /\ [][Next]_vars
        /\ WF_vars(toggler)
```

Each process becomes the disjunction of its labels — here just `flip`, since there's only one. `fair` becomes `WF_vars(toggler)` — weak fairness, "the process eventually takes a step if it can." Without `fair`, that line would not be there.

### The boilerplate

```
Terminating == ... UNCHANGED vars
Next == toggler \/ Terminating
Termination == <>(\A self \in ProcSet: pc[self] = "Done")
```

Three pieces every translation gets for free:

- **`Terminating`** — a self-loop step that fires when every process is at `Done`. Without this, TLC would deadlock at the end (no step possible) and report a deadlock error. T32 covers stuttering in detail.
- **`Next`** — the disjunction of all process actions plus `Terminating`. Defines "what step can happen next."
- **`Termination`** — auto-generated property you can pass to `PROPERTY` in the cfg.

## What to take away

- `tlc -pcal` is a pure text transformation. It reads the `(*--algorithm ...*)` block and writes a `\* BEGIN TRANSLATION ... \* END TRANSLATION` block immediately after. Nothing else changes.
- TLC ignores PlusCal entirely. It reads only the translated TLA+. PlusCal is sugar.
- Every PlusCal construct has a precise TLA+ counterpart: variables → `Init`, labels → action definitions, `:=` → primed equality, `fair process` → `WF_vars(...)`, `process` → disjunction.
- If you re-run `tlc -pcal` after editing the PlusCal block, pcal regenerates the translation block. The old `.old` file (gitignored) is the previous version.
- If you ever need to write TLA+ that pcal can't express, you can edit *outside* the TRANSLATION block. Anything between `\* END TRANSLATION` and the closing `====` of the module is your territory. Tier 3 leaves PlusCal behind entirely.

Done with T0d. Next is T0e (Module Anatomy), which maps the structural skeleton of a TLA+ module. After that, Tier 1 begins at T01.

## Hints

??? hint "💡 Hint 1 — The translation is pure text transformation"
    `tlc -pcal` reads your `(*--algorithm ...*)` block and writes a `\* BEGIN TRANSLATION ... \* END TRANSLATION` block. It doesn't modify anything outside those marks. So you can always see the original PlusCal side-by-side with its translation in the same file.

??? hint "💡 Hint 2 — Every PlusCal construct maps to TLA+"
    A label becomes an action definition. A variable assignment `:=` becomes a primed equality `'`. A process becomes a disjunction. The `fair` keyword becomes `WF_vars(...)`. Can you trace which part of the translation corresponds to each piece of the original?

??? hint "💡 Hint 3 — The program counter is hidden"
    PlusCal adds a hidden variable `pc` to track where each process is. When a label fires, it updates `pc` to point to the next label (or "Done" at the end). This is how TLA+ encodes procedural flow without if-then-else in every step.
