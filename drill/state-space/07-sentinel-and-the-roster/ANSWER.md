# Answer: the sentinel and the roster

Files in `verify/`. `Roster.tla` is the system. `RosterNoAssume.tla` is
the same module with both assumptions deleted, for question 2.

Every number from `tlc -workers 1` on TLC2 Version 2026.07.31.184830.

## Question 1: the config

```
SPECIFICATION Spec
CONSTANTS
    Nurses = {ann, bo}
    Nobody = Nobody
    MaxStreak = 2
INVARIANT TypeOK
INVARIANT SomeoneAvailable
```

`Nobody = Nobody` is a model value: a bare word on the right of the
equals, no quotes, no digits. `{ann, bo}` is a set of them. `2` is a
number. The module declares all three with one line, `CONSTANTS Nurses,
Nobody, MaxStreak`, and says nothing about which is which. The config
does.

A model value is a value TLC makes up that equals itself and nothing
else. Quoted text is a string, which is also a value, and on this build
the two compare without complaint. `SentinelString.cfg` sets `Nobody =
"nobody"` against model-value nurses and exits 0 at 9 states.
`SentinelNumber.cfg` sets `Nobody = 0` and also exits 0 at 9. So the
sentinel works as any of the three. Two things tell them apart, and both
are in the rows below.

## Question 2: the assumptions

```
ASSUME Nobody \notin Nurses
ASSUME MaxStreak \in Nat /\ MaxStreak >= 1
```

TLC checks an `ASSUME` once, before the first state, and exits 10 if it's
false. Rows three and four are those two lines firing.

With both lines deleted, `CollidesNoAssume.cfg` puts `"nobody"` in the
nurse set and sets the sentinel to the same string. It exits 0 at 7
distinct states. Green. The ward now has a nurse
called nobody who can take shifts, and "unstaffed" and "nobody is on
shift" are the same state, so `SomeoneAvailable` is checking a different
ward from the one described. Exit 10 before the first state is a refusal
you read once. Exit 0 on 7 states is a verdict you believe.

The collision is only possible with strings, since two model values
with the same name are the same value and a config can't put `Nobody`
in the set without the assumption seeing it. That's the first thing
that tells a model value from a string: a string sentinel can be
spelled by accident.

## Question 3: one nurse

`One.cfg`: rc 12, 5 states, depth 5. Ann works two shifts, the ward
empties, and nobody is allowed to start. The model is right about the
ward and the requirement is false on it.

So the requirement is a claim about a ward with at least two nurses,
and the number of nurses lives in the config, not the module. The
module says `CONSTANTS Nurses` and is true of any set. A claim that
depends on the size of the model has to carry that size as part of the
claim, either as an assumption (`ASSUME Cardinality(Nurses) >= 2`) or
in prose next to the config that checks it.

## Question 4: quoted names and the sixth row

`Three.cfg` against `ThreeSym.cfg`: 13 distinct states against 5, both
rc 0. The config names the permutation set:

```
SYMMETRY Perms
```

with `Perms == Permutations(Nurses)` in the module.

`StringNursesSymmetry.cfg` spells the nurses as `{"ann", "bo"}` and
exits 255: "Symmetry function must have model values as domain and
range". That's the second thing that tells a model value from a
string. Symmetry needs values TLC can swap without changing anything
else, and a string means something. Item 02 is the longer version.

## The whole table

Every config runs against the module with the assumptions, apart from
`CollidesNoAssume.cfg`, which runs against the copy without them.

| config | rc | distinct | depth |
|---|---|---|---|
| `Two.cfg` | 0 | 9 | 5 |
| `One.cfg` | 12 | 5 | 5 |
| `SentinelInSet.cfg` | 10 | | |
| `SentinelString.cfg` | 0 | 9 | 5 |
| `SentinelNumber.cfg` | 0 | 9 | 5 |
| `SentinelStringCollides.cfg` | 10 | | |
| `CollidesNoAssume.cfg` | **0** | 7 | 5 |
| `StreakZero.cfg` | 10 | | |
| `StringNursesSymmetry.cfg` | 255 | | |
| `Three.cfg` | 0 | 13 | 5 |
| `ThreeSym.cfg` | 0 | 5 | 5 |

## Variants worth running

Set `MaxStreak = 1` with two nurses. They alternate, 5 states, still
clean. With one nurse and `MaxStreak = 1` the violation is at depth 3.

Write `Nobody = ann`. The assumption fires, exit 10. That's the
model-value version of the collision, and it's caught the same way.

## Gate rows

One thin wrapper module per run the drill gate reproduces, each with a
copy of the config it stands for. The rc is what `harness/verdict.sh`
returns.

| module | rc | stands for |
|---|---|---|
| `G07Two.tla` | rc 0 | `Two.cfg`, the answer |
| `G07One.tla` | rc 12 | `One.cfg`, the claim false on a one-nurse ward |
| `G07SentinelIn.tla` | rc 10 | `SentinelInSet.cfg`, the sentinel inside the set, refused by the assumption |
| `G07Strings.tla` | rc 255 | `StringNursesSymmetry.cfg`, symmetry over strings refused |
| `G07Collides.tla` | rc 0 | `CollidesNoAssume.cfg`, the collision with the assumptions deleted, green and wrong |

## why-not-in-prompt

The prompt says "bare name" and "quoted text", which is the model value
and string distinction in words a reader without the terms could use.
It also says which rows were refused "by something in the module", so
the reader knows the guard lives there.

What the prompt withholds: the keyword for model values (there isn't one,
which is the point), the `ASSUME` keyword, that symmetry is the thing
that refuses strings, and that a deleted assumption turns a refusal into
a green run. Question 2 asks for the deletion so the reader sees the 7.

The honest caveat: the prompt reads as a cfg-writing exercise, and it
is. The module is small and the prompt describes it closely enough that
most of the ten minutes goes on the config and the four questions. I
think that's right for this family, where the config is the surface.
