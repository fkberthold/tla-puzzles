# J02: Judgment — PlusCal vs Pure TLA+ ⭐

**Judgment puzzle.** No new syntax. The goal is the *reflex*: when you pick up a new spec, do you reach for PlusCal or for pure TLA+?

## The choice

Tier 1 wrote PlusCal. Tier 3 pivots to pure TLA+. The two are both legitimate — and a real spec will use one or the other (rarely both). The question is which one *fits the system you're modeling*.

- **Side A — PlusCal.** Algorithmic notation. You write `process { label1: ... ; label2: ... }`, `while`, `if/else`, `either/or`. `pcal` translates it into pure TLA+ before TLC sees it.
- **Side B — Pure TLA+.** Relational notation. You define `Init`, then a `Next` that is a disjunction of named *actions* (`Action1 \/ Action2 \/ ...`), each a primed-state predicate.

Both produce the same kind of state-transition system. The notations highlight different things.

## Side A — PlusCal feels right

Open `solution/Sequential.tla` (or click the 🔒 spoiler below). A vending machine inserts a coin, picks an item, dispenses. Three steps in *order*.

```
fair process (machine = "Vending") {
  insert:    coins := 1;
  choose:    either { chosen := "snack"; } or { chosen := "drink"; };
  dispense:  dispensed := TRUE; coins := 0;
}
```

Run it:

```bash
tlc -pcal Sequential.tla && tlc Sequential
```

6 distinct states. The PlusCal source reads as a small program: insert *then* choose *then* dispense. The control-flow is the structure.

## Side B — Pure TLA+ feels right

Open `solution/Relational.tla` (or click the 🔒 spoiler below). A small key-value store: at any time, any client may put a value at any key, or delete any existing key. There is no fixed order; the system is a *set of allowed transitions*.

```
Put(k, v) ==
  /\ v \in Values
  /\ store' = [store EXCEPT ![k] = v]

Delete(k) ==
  /\ store[k] # "<absent>"
  /\ store' = [store EXCEPT ![k] = "<absent>"]

Next ==
  \/ \E k \in Keys, v \in Values : Put(k, v)
  \/ \E k \in Keys              : Delete(k)
```

Run it:

```bash
tlc Relational
```

(No `-pcal` — there is no PlusCal source. The TLA+ is the source.)

9 distinct states. The system is described as "Put OR Delete, on any key" — no `pc`, no labels, no while loop. Trying to write this in PlusCal would mean inventing a process and a label structure that doesn't really exist in the problem.

## When to choose PlusCal (Side A)

- The system has **clear sequential structure**: do step 1, then step 2, then step 3.
- A **process metaphor** fits: workers, clients, threads, requests doing their thing.
- You'd naturally describe it in pseudocode. `while`, `if`, `either/or`, `await` map directly.
- Multiple processes interleaving: PlusCal's `process` set + labels make atomicity boundaries explicit and graded (one label = one atomic step).
- You want pcal to handle the bookkeeping (`pc`, `Done`, `vars`, `UNCHANGED` clauses, `Termination`).

## When to choose pure TLA+ (Side B)

- The system is **inherently relational**: at any moment, any of N actions may fire. There's no canonical "next step."
- Examples: a database (any key, any operation, any time), a network (any node sends/receives), a state machine described by *transitions*, not by *programs*.
- You want **named actions** (`Put`, `Delete`, `Send`, `Crash`) that you can mention by name in fairness conditions, properties, or refinement mappings (`SF_vars(Send)`, `Spec => Higher!Send`).
- You're doing **refinement** (Tier 6): refinement mappings between specs are smoother in pure TLA+ where each level's actions are first-class.
- You want to skip the `pc` variable and the auxiliary state PlusCal injects.

## The trade-off

**PlusCal** wins on *familiarity* and *step granularity*. If you can write the algorithm in pseudocode, you can write it in PlusCal almost line for line, and labels give you atomicity for free. Cost: pcal injects a `pc` variable and stuttering-termination machinery; the control flow you wrote becomes the structure of the spec, even when the *system* doesn't have that control flow.

**Pure TLA+** wins on *expressiveness* and *match to relational systems*. Distributed protocols, databases, networks, and refinement chains read naturally as a disjunction of named actions over an `\E` of parameters. Cost: you write `UNCHANGED` and primed-variable predicates by hand, and there's no built-in process/label scaffold — sequential ordering is something *you* enforce with auxiliary state.

A useful rule of thumb:

> **If you'd describe it as "a program that does X then Y," reach for PlusCal. If you'd describe it as "a set of things any actor can do at any time," reach for pure TLA+.**

## Mini-classification exercise

For each of the following, decide PlusCal or pure TLA+. There are no certified answers — but the *first answer that pops into your head* is the reflex this judgment is building. Compare with the rule of thumb.

1. A coffee shop barista who serves cups until a daily limit, then closes.
2. A leader-election protocol where any node can propose, vote, or step down at any time.
3. A two-process producer/consumer with a bounded queue.
4. A Paxos-style consensus algorithm where messages cross between any pair of replicas.
5. The lifecycle of a single HTTP request: parse, route, handle, respond.
6. A bank with N accounts where any pair can transfer money to each other.

Compare your answers to the patterns in this lesson. (Roughly: 1, 3, 5 are PlusCal-shaped; 2, 4, 6 are pure-TLA+-shaped. But 1 and 3 *can* be done in pure TLA+ if you prefer named actions; and 6 *can* be done in PlusCal with a process per account. Both are legal — the question is which feels less forced.)

## What to take away

- The two notations express the same kind of system. Picking well is about which notation reduces the *friction* between the system and the spec.
- PlusCal: "what does the program *do*?" Pure TLA+: "what transitions are *possible*?"
- When a spec starts to fight you — when you keep adding labels for things that aren't really sequential, or you can't find a natural process — that's the signal to switch notation.

Done. J03 takes the same kind of choice up a level: which model checker — TLC or Apalache — fits the spec you just wrote?

## Hints

??? hint "💡 Hint 1 — Describe the system in English first"
    Without mentioning TLA+, how would you describe the system to a colleague? Do you say "the vending machine inserts a coin, *then* picks an item, *then* dispenses" (sequential, procedural)? Or do you say "clients can put or delete any key at any time" (a set of allowed actions)? The word "then" often signals PlusCal; "any time" signals pure TLA+.

??? hint "💡 Hint 2 — Can you draw a state machine?"
    Does the system have natural states (like "awaiting-coin," "dispensing," "done") that transition in a predictable order? That's procedural — PlusCal fits. Or is it a mesh of possible transitions where you can't name a canonical "next step" (like a concurrent KV store)? That's relational — pure TLA+ is more natural.

??? hint "💡 Hint 3 — Who cares about `pc`?"
    PlusCal introduces a `pc` variable tracking which label each process is at. If the system you're modeling actually cares about control flow (`if the machine is in state "dispensing" it can't accept coins"`), that's good — `pc` is useful. If `pc` is just bookkeeping with no real meaning (`the KV store doesn't have a "phase"; any key can be written any time`), PlusCal is adding noise.
