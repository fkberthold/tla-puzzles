# T60: SYMMETRY for State-Space Reduction ⭐⭐

## Lesson: Two New Things at Once — Model Values & SYMMETRY

A **model value** is a name from the cfg that is equal only to itself. `s1`, `s2`, `s3` declared in `CONSTANT Students = {s1, s2, s3}` are not strings, not integers — they're opaque tokens. TLC knows `s1 # s2`, but it doesn't know which is "first" or whether `s1` looks like anything else. Two model values are interchangeable up to equality.

When the spec uses model values uniformly — e.g., it never branches on `s = s1` specifically — then ANY permutation of the model-value set produces an equivalent behavior. **SYMMETRY** is the cfg directive that tells TLC about this. Once given, TLC visits only one representative per orbit. The state space shrinks dramatically.

**Worked example — committee voting (NOT a locker).**

```
---- MODULE Vote ----
EXTENDS FiniteSets, TLC

CONSTANT Members
VARIABLE voted

Init == voted = {}
Cast == \E m \in Members \ voted : voted' = voted \cup {m}
        /\ voted # Members
Next == Cast
vars == << voted >>
Spec == Init /\ [][Next]_vars

TypeOK == voted \subseteq Members

\* Symmetry set: every permutation of Members is a symmetry of this spec.
MemberSym == Permutations(Members)
=====
```

`Vote.cfg`:

```
SPECIFICATION Spec
CONSTANT Members = {alice, bob, carol, dave}
SYMMETRY MemberSym
CHECK_DEADLOCK FALSE
INVARIANT TypeOK
```

Without `SYMMETRY MemberSym`, TLC explores every subset of `Members` — 2^4 = **16 distinct states** for 4 members.

With `SYMMETRY MemberSym`, TLC notices that `{alice}`, `{bob}`, `{carol}`, `{dave}` are all in the same orbit (same cardinality, indistinguishable shape) and visits only one. Same for the 2-element subsets, the 3-element subsets, and the 4-element subset. Result: **5 distinct states** (one per cardinality 0..4). Same coverage, much less work.

**Three load-bearing things in this example:**

1. **Model values** — `alice`, `bob`, `carol`, `dave` are declared in `CONSTANT` and never appear in the spec body. Their identity doesn't matter — only equality.
2. **`Permutations(...)`** — `Permutations(S)` is in the `TLC` module. It returns the set of all bijections on `S`, expressed as functions. TLC reads this and applies orbit reduction.
3. **`SYMMETRY` directive** — written exactly once in the cfg. Names an operator that returns a permutation set.

**Three caveats:**

- Symmetry is **safety-only**. If you ask TLC to check liveness (`PROPERTY Termination`, `<>X`, etc.), TLC will refuse to use symmetry — liveness counterexamples can hide in the orbits TLC skips.
- The spec must be ACTUALLY symmetric in the model-value set. If your spec has `if (m = alice) ...`, then `alice` is privileged and you can't apply `Permutations(Members)`.
- Bigger gains for bigger sets. With `n` model values, the savings are typically `~n!`. For `n = 6`, that's a 720× speedup. For `n = 8`, 40,320×.

## Setup

A pre-written abstract spec lives in `solution/Lockers.tla`: students from a set are assigned lockers one at a time. The spec is symmetric — no specific student is privileged. The cfg uses model values for students and a `SYMMETRY` directive.

## Task

Open `solution/Lockers.tla` (or click the 🔒 spoiler below). Note:

- `CONSTANT Students` declares the model-value set.
- `StudentSym == Permutations(Students)` builds the symmetry set, using `Permutations` from the `TLC` module.

Open `solution/Lockers.cfg` (or click the ⚙️ spoiler below). Note:

- `CONSTANT Students = {s1, s2, s3, s4}` — `s1..s4` are model values.
- `SYMMETRY StudentSym` — tells TLC to apply orbit reduction.

Run TLC:

```bash
cd solution
tlc Lockers
```

Note the **distinct states found**.

Now comment out the SYMMETRY line:

```
\* SYMMETRY StudentSym
```

Re-run. Count again. Restore the line.

## Check

- WITH `SYMMETRY StudentSym`: TLC reports **5 distinct states** (cardinalities 0, 1, 2, 3, 4 — one representative each).
- WITHOUT `SYMMETRY StudentSym`: TLC reports **16 distinct states** (2^4 subsets, one per subset).

Both runs check `TypeOK` successfully. The reduction does not lose any safety information.

## Expected Result

- 5 distinct states with symmetry, 16 without.
- Identical "No error has been found." outcome — the symmetry reduction is sound for safety.
- For larger `Students` sets, the savings explode. With 6 students: 7 states with symmetry vs. 64 without.

## What to take away

- **Model values** — opaque tokens declared in the cfg, equal only to themselves.
- **`Permutations(S)`** — the permutation set, from the `TLC` module.
- **`SYMMETRY name`** — cfg directive, names an operator that returns the permutation set.
- Symmetry is safety-only. If you turn on liveness, TLC will reject the symmetry directive.
- Use this on every spec where you have indistinguishable processes, clients, requests, lockers, jobs. The speedup is the difference between a spec that checks in 1 second and one that runs all night.

## Hints

??? hint "💡 Hint 1 — Why Model Values Matter"
    The lesson says "model values are opaque tokens, equal only to themselves." In Lockers, the model values `s1, s2, s3, s4` are interchangeable — the spec never branches on `assigned = {s1}` specifically. Because they're interchangeable, any permutation (renaming s1→s2, s2→s3, etc.) produces an equivalent behavior. That's where Permutations comes in. If you had written `CONSTANT Students = {"alice", "bob", "carol", "dave"}` (strings), TLC would reject the Permutations because strings have a built-in ordering — they're NOT interchangeable in TLC's eyes.

??? hint "💡 Hint 2 — Orbits and Representatives"
    Without SYMMETRY, TLC visits all 2^4 = 16 subsets of Students: {}, {s1}, {s2}, {s3}, {s4}, {s1,s2}, ... With SYMMETRY, TLC groups states into orbits (equivalence classes under permutation). All 1-element subsets {s1}, {s2}, {s3}, {s4} are in the same orbit; TLC visits only ONE representative. Same for all 2-element, 3-element, and 4-element subsets. Result: 5 distinct views instead of 16. The coverage is identical because every cardinality class has the same structure.

??? hint "💡 Hint 3 — SYMMETRY Rejects Liveness"
    If you try to add a PROPERTY like Termination (a liveness property with <>) to Lockers, TLC will refuse to use SYMMETRY. Why? Because liveness counterexamples are lasso traces (a prefix followed by a loop). Symmetry reduction can hide a liveness bug in a skipped orbit. TLC plays it safe: SYMMETRY is safety-only. For this puzzle, stick with TypeOK.
