# Coverage audit: chapter 5 exercise set

Audited against the theme list in `exercises/ch05/CHEATSHEET.md`. This file is
an audit of the set that already exists. It was not used to generate it.

## Major themes

| Cheat sheet theme | Exercise | Status |
| --- | --- | --- |
| Constants defer concrete values to the model run, keeping the spec free of hardcoded settings. | 1 | covered |
| `ASSUME` documents and enforces valid constant values before a run starts. | 2, and again in 5 | covered |
| Model values give an opaque, self-only-equal type for sentinels and placeholders. | 3 | covered |
| Symmetry sets collapse states that only differ by relabeling model values. | 4 | covered in part, see below |
| Constants can also steer a spec's behavior, not just supply data, like a `DEBUG` flag. | 5 | covered |

## Constructs introduced

| Cheat sheet construct | Exercise |
| --- | --- |
| `CONSTANT` | 1, 2, 3, 4, 5 |
| `ASSUME` | 2, 5 |
| model value | 3 |
| set of model values | 4 |
| symmetry set | 4 |

## The one partial, and why

**Theme 4, the state collapse itself, is not exercised.** Exercise 4 covers the
precondition and the failure mode. It does not ask a learner to observe the
smaller state space, which is what the chapter actually shows.

The reason is a house rule. Every stated outcome in this set is a TLC verdict,
never a state count. A count is a fact about how TLC represented the run, and it
moves with worker settings, with fingerprint choices, and with TLC releases. An
exercise that asserted "you will see 715 states" would be asserting something
this project has decided not to depend on.

So exercise 4 keeps the half of the theme that has a verdict. It asks what
happens when a symmetry set is declared over values that are not model values,
and TLC's refusal is the answer. That teaches the condition symmetry rests on,
which is the part a learner gets wrong in practice. The speedup is the reward
for getting the condition right, and the chapter already shows it.

The payoff of symmetry sets for concurrent systems is chapter 8's material, per
this chapter's own boundary notes, and is out of scope here either way.

## One construct used that is not on the cheat sheet

`Permutations`, from the `TLC` standard module, appears in
`references/ex4-relay/Relay.tla`.

The cheat sheet lists a symmetry set as something you mark in the toolbox
constant assignment dialog. There is no dialog here. Outside the toolbox the
same thing is expressed by defining `Perms == Permutations(Runners)` in the
module and naming it with a `SYMMETRY` line in the `.cfg`. learntla says so
itself, in `docs/topics/optimization.rst` at the pinned SHA.

So this is the same chapter 5 construct wearing its command line clothes, not a
later chapter's construct borrowed early. Exercise 4 says as much in its own
text so a learner is not left wondering where `Permutations` came from.

## Scope check

Every other construct in the set comes from chapters 2 to 5, checked against the
`ch02` through `ch05` cheat sheets:

- chapter 2: operator definition, `IF-THEN-ELSE`, `EXTENDS`, integers, booleans,
  `BOOLEAN`, `a..b`, sets, `\in`, `\notin`, `#`, `>=`, `<=`
- chapter 3: `--algorithm`, `:=`, labels, `while`, `with`, variable declarations
- chapter 4: `define` block, invariants
- chapter 5: `CONSTANT`, `ASSUME`, model values, sets of model values, symmetry

No records, no function literals, no function sets. Those are chapter 6, and the
cheat sheet's boundary notes put them there.
