# T19: `\subseteq` and `SUBSET` ⭐

## Lesson: Subset Test vs. Power Set

Two operators that look similar but do very different things.

**`A \subseteq B`** is a BOOLEAN test: "is every element of `A` also in `B`?"

```
{1, 2} \subseteq {1, 2, 3}        \* TRUE
{1, 4} \subseteq {1, 2, 3}        \* FALSE
{} \subseteq AnySet               \* TRUE — the empty set is a subset of every set
S \subseteq S                     \* TRUE — every set is its own subset
```

**`SUBSET S`** is a SET-VALUED operator returning the POWER SET of `S` — the set of all subsets:

```
SUBSET {1, 2}                     \* {{}, {1}, {2}, {1,2}}
SUBSET {a, b, c}                  \* the 8 subsets of {a, b, c}
```

The size: `|SUBSET S| = 2^|S|`. With `|S| = 4`, that's 16. With `|S| = 10`, that's 1024. **`SUBSET` blows up fast.** Use it only on small sets, or with care in TypeOK.

The two operators are related:

```
A \subseteq B  <=>  A \in SUBSET B
```

That is: "A is a subset of B" is equivalent to "A is a member of the power set of B."

You'll use `\subseteq` constantly — for typing variables that hold sets:

```
TypeOK == registered \subseteq Users        \* "registered is a subset of all users"
```

You'll use `SUBSET` rarely — for nondeterministically picking ANY subset:

```
with (s \in SUBSET Users) {                  \* pick ANY group of users (could be empty, could be everyone)
  selected := s;
}
```

**Worked example — a tournament committee.**

A small tournament has 4 players. The committee — a subset of the players — has authority over rules. The director picks a committee nondeterministically (anything from no players to all of them).

```
(*--algorithm Tournament {
  variables players = {"p1", "p2", "p3", "p4"}, committee = {};

  define {
    AllCommittees == SUBSET players      \* 2^4 = 16 possible committees
    TypeOK == committee \subseteq players  \* committee is always some subset
  }

  fair process (director = "Dir") {
    pick:
      with (c \in AllCommittees) {
        committee := c;
      };
  }
}*)
```

Sample invariants:

- `TypeOK == committee \subseteq players` — passes always
- `Nonempty == committee /= {}` — TLC will violate this; one of the 16 subsets is `{}`
- `LessThanAll == committee /= players` — TLC will violate this too; another subset is the whole set

Two patterns to keep separate:

- **Sized invariant:** "committee has at most 2 members" → `Cardinality(committee) <= 2` (you'll meet `Cardinality` in T20)
- **Subset invariant:** "committee is some subset of players" → `committee \subseteq players` — guaranteed by construction

## Setup

A school's chess club has a roster of 4 students: `{"a", "b", "c", "d"}`. The coach picks a TEAM — any subset of the roster — to send to a meet. After picking, the coach also picks a CAPTAIN, who must be a member of the team.

You'll use `SUBSET` to pick the team, and `\subseteq` plus `\in` for the typing.

## Task

Write a PlusCal spec with:

- A variable `roster` initialized to `{"a", "b", "c", "d"}`
- A variable `team` initialized to `{}`
- A variable `captain` initialized to `"none"`
- A variable `phase` starting at `0`

A single fair process runs two labels:

1. **pickTeam**: use `with (t \in SUBSET roster)` to choose any subset; assign it to `team`. Increment `phase`.
2. **pickCaptain**: use `with (c \in team \cup {"none"})` to choose either a team member OR the placeholder `"none"` (handles the empty-team case). Assign to `captain`. Increment `phase`.

In the `define` block:

- `Roster == roster`  \* alias
- `TypeOK == team \subseteq roster /\ captain \in roster \cup {"none"} /\ phase \in 0..2`
- `CaptainConsistent == phase = 2 => (captain = "none" \/ captain \in team)`

## Check

1. **TypeOK** — see above. The team is always a subset of the roster; the captain is a roster member or `"none"`.
2. **CaptainConsistent** — once both choices are made, the captain is either the placeholder or a team member. Never a non-team-member.

## Expected Result

- TLC reports a substantial state count (2^4 = 16 possible teams; for each team, |team|+1 possible captains).
- Both invariants pass.
- Notice the difference: `SUBSET roster` ENUMERATES all 16 subsets and feeds them into `with`; `team \subseteq roster` is a one-line BOOLEAN test in the invariant. Same noun ("subset") but different operator.

**Bonus.** Replace `with (t \in SUBSET roster)` with `with (t \in {{}, roster})` — only two choices: empty team or whole roster. Predict the new state count, run TLC, and confirm. Then revert.

## Hints

??? hint "💡 Hint 1 — Subset test vs. power set"
    `\subseteq` is a BOOLEAN operator — `team \subseteq roster` is TRUE or FALSE. `SUBSET` is a function that RETURNS A SET — `SUBSET roster` is the power set (all 16 subsets of the 4-element roster). Use `\subseteq` in invariants; use `SUBSET` in `with` to branch on choices.

??? hint "💡 Hint 2 — Power set blows up fast"
    `|SUBSET S| = 2^|S|`. With 4 roster members, `SUBSET roster` has 16 subsets. Each subset branches the `with`, creating 16 paths. Then for each team, `with (c \in team \cup {"none"})` creates |team|+1 branches (to pick captain). Total state count is roughly 1 initial + 16 teams * (1-5 captain choices) = 100+.

??? hint "💡 Hint 3 — Handle the empty team case"
    When the team is empty, there's no one to pick as captain. The expression `team \cup {"none"}` adds the placeholder `"none"` so you can always pick. The invariant `CaptainConsistent` uses `captain \in roster \cup {"none"}` to allow the placeholder, and checks that the captain is either "none" or actually on the team.
