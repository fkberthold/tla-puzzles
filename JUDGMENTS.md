# Judgment Decision Tree

A consolidated reference for the seven design choices the curriculum's J-puzzles teach. Each decision is a *judgment*, not a rule — the right answer depends on what you're modeling and what question you want answered.

For depth, work the corresponding J-puzzle. This page is a refresher card you can keep open while specifying.

---

## J01 · Records vs. separate variables

**Question:** Several pieces of state belong to one logical thing (an order, an account, a request). Should they be separate top-level variables or one variable holding a record?

```
Will you ever need to atomically update >1 of these fields together?
├── No                              → separate variables (simpler labels, terser EXCEPT)
└── Yes
    ├── Often passed/returned as a unit?  → record
    ├── Likely to grow new fields?        → record (one EXCEPT, not many)
    └── Otherwise                          → separate variables; revisit if it bloats
```

**Smell:** if you find yourself writing `[X EXCEPT !.a = …, !.b = …, !.c = …]` more than three lines down, you have a record. If you're writing `a' = …, b' = …, c' = …` and the fields are independent, you have separate variables.

---

## J02 · PlusCal vs. pure TLA+

**Question:** Algorithmic notation (PlusCal) or relational (pure TLA+)?

```
Is the system naturally a sequence of steps a process executes?
│   (loops, conditionals, procedure calls, "first do X, then Y")
├── Yes  → PlusCal
└── No   → pure TLA+
        Most refinement, most multi-action protocols, most level-3 reasoning lives here.
```

**Smell:** if your action description is "*on event X, atomically do A; on event Y, atomically do B*", that's pure TLA+. If your description is "*a worker picks a task, then locks, then processes, then releases*", that's PlusCal.

A real spec rarely mixes the two in one module. Pick per module.

---

## J03 · TLC vs. Apalache

**Question:** Which model checker fits this verification?

```
Does the spec need liveness checking (<>, [], ~>, []<>, <>[])?
├── Yes  → TLC. Apalache currently doesn't handle most liveness.
└── No   → safety only
    ├── Is the state space huge or unbounded in a CONSTANT?  → Apalache (--cinit)
    │     "MaxN = 1_000_000" is a problem for TLC, fine for Apalache.
    ├── Do you want a concrete trace as a debugging artifact? → TLC (great traces)
    ├── Already heavily annotated with @type comments?        → Apalache (snowcat first)
    └── Neither / unsure                                       → TLC for development,
                                                                 Apalache for the final pass
```

A common industrial pattern: develop and debug with TLC at small bounds, then run Apalache at larger or symbolic bounds for the final story. They are complementary, not competitive.

---

## J04 · When to use refinement

**Question:** Single-level spec, or abstract + concrete + refinement mapping?

```
Will several different implementations need to be checked against the same contract?
├── Yes                    → refinement (write the contract once, refine multiple times)
└── No
    Does the concrete spec have at least 2x as much detail as the natural specification?
    │   (buffers, retries, internal channels, scheduler bookkeeping)
    ├── Yes                → refinement (abstract contract is the actual claim;
    │                          concrete spec proves the implementation respects it)
    └── No                 → single-level. Don't write a redundant abstract layer.
```

**Smell:** if the abstract spec ends up being almost the same shape as the concrete spec, refinement is overhead. The win comes from the abstract spec being *much smaller* than the concrete one.

---

## J05 · Choosing fairness type

**Question:** None, weak fairness, or strong fairness on each action?

```
For each action A whose firing your liveness property depends on:

Is A continuously enabled once enabled (until it fires)?
├── Yes  → WF_vars(A)   (or `fair process`)
│   Examples: a process that loops on its own; an action with no shared dependency.
│
└── No, A's enablement flickers (others disable it intermittently)
    ├── A still fires "infinitely often when enabled"?  → SF_vars(A)  (or `fair+ process`)
    │   Examples: server-handles-request when clients pause/resume traffic;
    │             aggregator with a heartbeat gate.
    └── A is meant to be optional / racing                → no fairness; liveness shouldn't depend on A
```

**Default:** start with `WF_vars(A)` for every action your liveness needs. Upgrade to `SF` only after TLC's lasso shows A starved by intermittent disable. Don't sprinkle SF prophylactically — it costs verifier time and can mask real bugs.

---

## J06 · Safety vs. liveness

**Question:** Express this property as an INVARIANT or as a temporal PROPERTY?

```
Does the property say something is true in EVERY reachable state?
│   ("nothing bad happens", "the invariant holds at all times")
├── Yes  → INVARIANT (state predicate)
│   Cheap to check. Counterexample is a single trace ending at the violating state.
│
└── No, the property talks about EVENTUAL or RECURRING behavior
    │   ("something good eventually happens", "always eventually responds")
    ↓
    PROPERTY (temporal formula)
    Requires fairness assumptions. Counterexample is a lasso (stem + cycle).
    More expensive to check.
```

**Smell:** if your "property" doesn't contain `<>`, `[]`, `~>`, or `[]<>`, it's almost certainly an invariant. If it does, it's almost certainly a temporal property.

A safety-only check is dramatically cheaper. Don't reach for liveness until you actually need to claim "eventually."

---

## J07 · Label split vs. combine

**Question:** Should two PlusCal statements be in one label (atomic) or two labels (interleaved)?

```
Are these two operations atomic in the real system?
│   (CPU instruction, transaction, held lock, single message)
├── Yes  → one label
│   Other processes cannot interleave between them.
│   Simulates: hardware atomic, locked critical section, single-message handler.
│
└── No, the operations happen at different times in reality
    └── two labels
        State between is visible to other processes.
        TLC will find any race that two-label visibility permits.
        Simulates: independent reads/writes, separate network messages,
                   re-evaluation after a yield.
```

**Smell:** the classic lost-update bug — `read; write` in two labels — is exactly what TLC catches when you split. If your "atomic" claim is wrong, the boundaries you draw with labels surface the race.

**Default:** match the granularity of the *real system*. PlusCal's labels are how you draw atomicity boundaries; nothing else does it for you.

---

## Cross-judgment shorthand

| If you find yourself… | Probably want… |
|---|---|
| Writing `f' = [f EXCEPT !.a=…, !.b=…]` constantly | A record, not separate variables (J01) |
| Translating an algorithm step-by-step from a paper | PlusCal (J02) |
| Stuck because TLC won't terminate at MaxN ≥ 100 | Apalache with `--cinit` (J03) |
| Maintaining two specs that look 90% identical | Drop refinement; you don't need it (J04) |
| Writing `<>` and seeing infinite stuttering counterexamples | Add fairness — start with WF (J05) |
| Reaching for `~>` when an INVARIANT would do | Safety, not liveness (J06) |
| Writing two PlusCal statements that "should" be atomic | One label (J07) |

---

For the original puzzles, see `puzzles/J01-records-vs-variables/`, `puzzles/J02-pluscal-vs-tla/`, etc.
