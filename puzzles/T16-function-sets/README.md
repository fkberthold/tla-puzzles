# T16: Function Sets — `[S -> T]` ⭐

## Lesson: The Set of All Functions from S to T

You've built individual functions with `[x \in S |-> e]`. T16 introduces a different `[ ... ]` form — one that names a SET of functions:

```
[S -> T]    \* the set of all functions f such that DOMAIN f = S, and \A x \in S : f[x] \in T
```

Read it as: "every function from `S` to `T`."

```
[{1, 2} -> {"a", "b"}]
\* contains 4 functions:
\*   [x \in {1,2} |-> "a"]
\*   [x \in {1,2} |-> "b"]
\*   [x \in {1,2} |-> IF x = 1 THEN "a" ELSE "b"]
\*   [x \in {1,2} |-> IF x = 1 THEN "b" ELSE "a"]
```

**The size:** `[S -> T]` has `|T|^|S|` elements. With `|S| = 2` and `|T| = 2`, that's 4 (above). With `|S| = 3` and `|T| = 5`, that's 125.

**Where you reach for it:**

- `TypeOK` for a function variable: `inventory \in [Items -> 0..10]` says "inventory is a function whose domain is `Items` and whose values are bounded integers."
- `\E f \in [S -> T] : ...` says "there exists some function from `S` to `T` such that ..." Useful for nondeterministically picking a whole assignment at once.

Two warnings:

1. **The arrow is `->`, not `|->`.** `|->` builds a SINGLE function (binding `x` to a value); `->` builds a SET of functions.
2. **`[S -> T]` is finite only when `S` and `T` are finite.** TLC needs both finite to enumerate.

**Worked example — a workshop seat assignment.**

A small workshop has 2 students and 3 chairs. Each student is assigned to a chair (multiple students CAN share a chair in this casual seating). The room is initially "empty" (a placeholder). The instructor nondeterministically picks a complete seating assignment, drawn from the SET of all functions from students to chairs.

```
(*--algorithm Workshop {
  variables seating = [s \in {"alice", "bob"} |-> 1];

  define {
    Students == {"alice", "bob"}
    Chairs == 1..3
    AllSeatings == [Students -> Chairs]   \* 3^2 = 9 possible assignments

    TypeOK == seating \in AllSeatings
  }

  fair process (instructor = "Inst") {
    assign:
      with (s \in AllSeatings) {           \* nondeterministically pick ANY function from Students to Chairs
        seating := s;
      };
  }
}*)
```

Sample invariants:

- `TypeOK == seating \in AllSeatings` — passes for every reachable state
- `BothInChair1 == seating["alice"] = 1 /\ seating["bob"] = 1` — TLC violates this; many seatings don't have both in chair 1

The `with (s \in AllSeatings)` clause uses the function-set as a finite source for nondeterministic choice. TLC enumerates all 9 functions, and you get one branch per assignment.

That's the punchline: `[S -> T]` is a normal SET, usable anywhere a set is — in `\in`, in `\E`, in `with`. It just happens to contain functions.

## Setup

A small parking garage assigns 3 cars (`"X"`, `"Y"`, `"Z"`) to 2 parking spots (`1`, `2`). Multiple cars can share a spot (the garage is permissive). The garage operator picks an assignment for the day from the set of all possible assignments.

You'll model this with a function variable `parked` whose type is "function from cars to spots." Use `[Cars -> Spots]` in TypeOK and as the source set in a `with`.

## Task

Write a PlusCal spec with:

- A variable `parked` initialized to `[c \in {"X", "Y", "Z"} |-> 1]` (everyone starts in spot 1)
- A variable `assigned` starting at `FALSE`

In the `define` block:

- `Cars == {"X", "Y", "Z"}`
- `Spots == 1..2`
- `AllAssignments == [Cars -> Spots]`
- `TypeOK == parked \in AllAssignments /\ assigned \in BOOLEAN`
- `EveryoneInSpot1 == \A c \in Cars : parked[c] = 1` — true sometimes, false sometimes

A single fair process runs one label:

1. **assign**: use `with (a \in AllAssignments) { parked := a; }`. Set `assigned := TRUE`.

## Check

1. **TypeOK** — every reachable `parked` is a function in `[Cars -> Spots]`. There are `2^3 = 8` such functions.
2. **NotAlwaysSpot1**: `~EveryoneInSpot1` — this SHOULD be violated. The TLC trace will pick the assignment that puts everyone in spot 1, leaving the invariant true at the end... wait, this invariant is "NOT everyone in spot 1." Reread: invariants must hold in EVERY state. The initial state has everyone in spot 1, so `EveryoneInSpot1` is true initially, so `~EveryoneInSpot1` is FALSE initially. TLC violates `NotAlwaysSpot1` at the initial state (with a 1-state trace).

## Expected Result

- TLC should report `No error has been found` (for TypeOK).
- NotAlwaysSpot1 is violated by the initial state — a 1-state trace.
- The canonical solution finds **9 distinct states**: the initial state plus 8 post-`assign` states (one per function in `AllAssignments`). The `assigned` flag ensures post-assign states are distinguishable from the initial. Your label choices may affect the exact state count, but the violation and invariant behavior remain the same.

**Bonus.** Add `OneCarInTwo == \E c \in Cars : parked[c] = 2`. Will it always hold? In which reachable state does it FAIL? (Hint: same answer as the violation above.)

## Hints

??? hint "💡 Hint 1 — [S -> T] is a SET of functions"
    `[Cars -> Spots]` names the SET of all functions from cars to spots. With 3 cars and 2 spots, there are 2^3 = 8 such functions. You use this set in `with (a \in AllAssignments) { parked := a; }` — the `with` picks one function nondeterministically, and TLC branches on each choice.

??? hint "💡 Hint 2 — Arrow vs. bar-arrow"
    `[S -> T]` (arrow) is a SET of functions. `[x \in S |-> e]` (bar-arrow) is ONE function. They're complementary: the first describes a type; the second constructs a value. Use `[Cars -> Spots]` in TypeOK and in the `with` clause.

??? hint "💡 Hint 3 — One label that branches 8 ways"
    The `assign` label uses `with (a \in AllAssignments) { parked := a; }`. This picks one of the 8 functions, setting `parked` to it. TLC creates a branch for each of the 8 possibilities. The initial state (everyone in spot 1) is one of those 8, so you might pick it again (hence `assigned` flag distinguishes the initial state from later ones).
