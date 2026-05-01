# R03: Process Set with `self` ⭐

## Lesson: Recap — Multi-Process Race Through Two Labels

You met process sets in T04 (Alice and Bob racing through a door) and the multi-label race that exposed the TOCTOU bug. This is a recap drill in a fresh domain — two processes, two labels, same shape, different story.

The pieces:

- `process (worker \in {"P1", "P2"})` — declares a SET of processes, all running the same code.
- `self` — inside a process body, evaluates to the identity of the running process (`"P1"` or `"P2"`).
- Multiple labels — splitting work into separate atomic steps creates an INTERLEAVING POINT where another process can sneak between your steps.

The classic shape: process A checks shared state in label 1, process B reads the SAME state in label 1 before A writes it back in label 2, both think they have exclusive access, both act.

**Recap example — concert tickets, last seat.**

A box office has ONE seat left. Two buyers — `"B1"` and `"B2"` — try to buy. Each buyer first reads the seat count, then if there's a seat, claims it. Because read and claim are separate labels, both buyers can read "1 seat remaining" before either claims, then BOTH decrement, leaving the count at -1.

```
(*--algorithm BoxOffice {
  variables seats = 1, buyers = {};

  fair process (buyer \in {"B1", "B2"}) {
    check:
      if (seats > 0) {
        goto buy;
      } else {
        goto leave;
      };
    buy:
      seats := seats - 1;
      buyers := buyers \cup {self};
      goto leave;
    leave:
      skip;
  }
}*)
```

Sample invariants:

- `TypeOK == seats \in -1..1 /\ buyers \subseteq {"B1", "B2"}`
- `Oversold == seats >= 0` — TLC violates this!

Trace:

1. B1 at `check`: sees seats = 1, jumps to `buy`.
2. B2 at `check`, **before B1 buys**: sees seats = 1 too, jumps to `buy`.
3. B1 at `buy`: seats = 0, buyers = {"B1"}.
4. B2 at `buy`: seats = -1, buyers = {"B1", "B2"}.

Two buyers, ONE seat, BOTH claim it — `seats < 0` is the smoking gun. The fix is to collapse `check` and `buy` into one label so the read-and-decrement is atomic.

Notice `buyers \cup {self}` — `self` is the running buyer's name, added to the set so we can audit who got what. Same pattern T04 used for the `through` set, just a different theme.

## Setup

A library has `1` available copy of a popular book. Two patrons — `"Pat1"` and `"Pat2"` — each try to check it out. Each patron:

1. **inspect**: looks at the available count. If positive, decides to take it; otherwise gives up.
2. **borrow**: decrements the available count and adds themselves to the `holders` set.

The bug: between Pat1 inspecting and Pat1 borrowing, Pat2 might inspect too — and both think a copy is available.

## Task

Write a PlusCal spec with:

- A variable `available` starting at `1`
- A variable `holders` starting at `{}` (set of names)
- A process set over `{"Pat1", "Pat2"}` running in two labels:
  1. **inspect**: if `available > 0`, `goto borrow`; else `goto done`.
  2. **borrow**: `available := available - 1`; `holders := holders \cup {self}`; `goto done`.
  3. **done**: `skip`.

Use `self` inside the `borrow` label to record which patron took a copy.

## Check

1. **TypeOK**: `available \in -1..1 /\ holders \subseteq {"Pat1", "Pat2"}`
2. **NoOverborrow**: `available >= 0` — at most one patron should be able to borrow

## Expected Result

- **NoOverborrow WILL BE VIOLATED.** TLC finds a trace where both patrons borrow, leaving `available = -1`.
- The trace shows the interleaving: Pat1 inspects (sees 1), Pat2 inspects (still 1 — Pat1 hasn't borrowed yet!), Pat1 borrows, Pat2 borrows.
- This is the same TOCTOU race as T04's door, in a fresh domain. Different setting; same shape; same `self`-keyed audit set.
