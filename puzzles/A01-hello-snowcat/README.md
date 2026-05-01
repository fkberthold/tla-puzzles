# A01: Apalache — Hello, Snowcat ⭐

## Lesson: Type Annotations for Apalache

Apalache is a symbolic model checker for TLA+. Unlike TLC, which enumerates concrete states, Apalache encodes the spec as SMT constraints. To do that, every variable needs a *type*.

You give Apalache a type by writing a special comment immediately above each `VARIABLE` declaration:

```tla
\* @type: Int;
VARIABLE foo
```

The annotation is just a `\*` comment, so TLC ignores it. Apalache's type checker — nicknamed **Snowcat** — reads these comments and verifies the rest of the spec is consistent with them.

The base types you'll use most often:

- `Int` — integer
- `Bool` — boolean
- `Str` — string

**Worked example — a thermostat.**

A thermostat tracks a room temperature (an integer) and whether the heater is on (a boolean). Here is the full pure-TLA+ spec, type-annotated for Apalache:

```tla
---- MODULE Thermostat ----
EXTENDS Integers

\* @type: Int;
VARIABLE temp

\* @type: Bool;
VARIABLE heater

vars == << temp, heater >>

Init ==
  /\ temp = 60
  /\ heater = FALSE

Heat ==
  /\ heater = FALSE
  /\ heater' = TRUE
  /\ temp' = temp + 1

Cool ==
  /\ heater = TRUE
  /\ heater' = FALSE
  /\ temp' = temp - 1

Next == Heat \/ Cool

Spec == Init /\ [][Next]_vars

TypeOK == temp \in 50..70 /\ heater \in BOOLEAN
====
```

The annotations sit in two TLA+ comments, one per variable. To run Snowcat:

```bash
apalache-mc typecheck Thermostat.tla
```

Snowcat prints `Type checker [OK]` if the annotations are consistent with how the variables are used. If you wrote `\* @type: Bool;` above `VARIABLE temp` and then assigned `temp = 60`, Snowcat would reject the spec with a clear error pointing at the inconsistency.

**The key idea.** TLC infers types from values it sees during exploration. Apalache needs the types written down before exploration even starts — that's the price of symbolic checking. The annotations are tiny but mandatory.

## Setup

A vending machine tracks two things: how much money has been deposited (cents, an integer), and whether a snack has been dispensed (boolean). The customer can deposit a coin, and once at least 100 cents are in, dispense the snack.

## Task

Write a pure-TLA+ spec `VendingMachine.tla` with:

- A variable `deposit` annotated as `Int`, initialized to `0`
- A variable `dispensed` annotated as `Bool`, initialized to `FALSE`
- An action `Insert` that adds 25 to `deposit`, leaving `dispensed` unchanged, only fires if not yet dispensed and `deposit < 100`
- An action `Dispense` that fires only when `deposit >= 100` and `~dispensed`, sets `dispensed' = TRUE`, leaves `deposit` unchanged
- A terminal-stutter action `Done` that fires when `dispensed = TRUE` and leaves all variables unchanged (`UNCHANGED vars`); include it in `Next` so TLC does not report a deadlock at the terminal state
- A `Spec == Init /\ [][Next]_vars` formula
- A `TypeOK` invariant: `deposit \in 0..200 /\ dispensed \in BOOLEAN`

Annotate **both** variables with `\* @type:` comments above their `VARIABLE` lines.

## Check

```bash
cd solution
tlc VendingMachine          # verifies TypeOK in TLC (annotations are just comments to TLC)
```

If you have Apalache installed:

```bash
apalache-mc typecheck VendingMachine.tla    # should print: Type checker [OK]
apalache-mc check --inv=TypeOK --length=10 VendingMachine.tla
```

## Expected Result

- TLC: 6 distinct states, no error. (deposit walks 0 → 25 → 50 → 75 → 100, then `Dispense` sets `dispensed = TRUE`. The `Done` action stutters after that.)
- Apalache `typecheck`: `Type checker [OK]`.
- The annotations are TLA+ comments, so TLC ignores them entirely. Their *only* effect is to make the spec legible to Snowcat.

## What you learned

- The `\* @type: T;` comment goes immediately above each `VARIABLE` declaration.
- Base types: `Int`, `Bool`, `Str`.
- Snowcat is Apalache's type checker, runnable independently with `apalache-mc typecheck`.
- Annotations have no effect on TLC behavior — they are pure TLA+ comments.

## Hints

??? hint "💡 Hint 1 — Where do the annotations go?"
    The lesson shows that type annotations are written as special `\*` comments. Look carefully at the worked example: what exact syntax appears immediately above each `VARIABLE` line?

??? hint "💡 Hint 2 — Annotations for both variables"
    You have two variables to annotate: one holds a number (how much money), the other holds a true/false state. The base types `Int` and `Bool` are your answer — but both lines need the comment.

??? hint "💡 Hint 3 — Multi-line VARIABLES block"
    The lesson groups variables with a single `VARIABLES` keyword, then annotates each one with a comment above it. Notice the syntax: `\* @type: T;` immediately above the variable name, all within one `VARIABLES` block.
