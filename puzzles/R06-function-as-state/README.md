# R06: Review — Function-as-State ⭐

## Lesson: Per-Process State via Functions

You learned functions in Tier 2 (T12–T15) and process sets with `self` in Tier 1 (T04). This review combines them: when you have a SET of processes, the natural way to give each one its own private state is a FUNCTION whose domain is the process set.

```
state = [p \in ProcSet |-> initialValue]
```

Each process reads its own slot with `state[self]` (function application — T13) and updates it with `state' = [state EXCEPT ![self] = newValue]`, which in PlusCal is written `state[self] := newValue` (T14, T15).

No new syntax. The novelty is that the FUNCTION INDEX is the SAME process running the action.

**Worked example — voting booths.**

A polling station has booths, one per voter. Each voter walks to their booth and casts a vote (`"yes"`, `"no"`, or `"abstain"`). The ballot for voter `v` lives in `ballot[v]`. Domain: `Voters`. Codomain: `{"unmarked", "yes", "no", "abstain"}`.

```
(*--algorithm Polling {
  variables ballot = [v \in {"V1", "V2", "V3"} |-> "unmarked"];

  define {
    Cast == {v \in {"V1", "V2", "V3"} : ballot[v] /= "unmarked"}
  }

  fair process (voter \in {"V1", "V2", "V3"}) {
    vote:
      with (choice \in {"yes", "no", "abstain"}) {
        ballot[self] := choice;
      };
  }
}*)
```

Two things to notice:

- `ballot = [v \in {"V1", "V2", "V3"} |-> "unmarked"]` — the function constructor (T12) builds a function with one slot per voter, each starting `"unmarked"`.
- `ballot[self] := choice` — inside a process, `self` is this process's identity (T04), so `ballot[self]` reads/writes ONLY this voter's slot. PlusCal translates this to `ballot' = [ballot EXCEPT ![self] = choice]` — the EXCEPT update from T14.

After translation, an invariant like `\A v \in {"V1","V2","V3"} : ballot[v] \in {"unmarked","yes","no","abstain"}` checks every voter's ballot.

The pattern in one sentence: **one function, one slot per process, each process reads/writes only `f[self]`.**

## Setup

A gym has lockers, one per member. Each member walks up to their locker, opens it (`"open"`), uses it, and closes it (`"closed"`). The lockers start `"closed"`.

We want to verify that no member's locker ever ends up in some bogus state, and that every member's locker is `"closed"` when the spec terminates.

## Task

Write a PlusCal spec with:

- A constant set `Members = {"Anna", "Ben", "Cleo"}` (just write it in-line — no CONSTANT yet).
- A function variable `locker = [m \in Members |-> "closed"]`.
- A process set indexed by `Members` that for each member:
  1. **open**: `locker[self] := "open"`
  2. **use**: `skip` (just an atomic step where the locker is in use)
  3. **close**: `locker[self] := "closed"`

## Check

1. **TypeOK**: `\A m \in Members : locker[m] \in {"open", "closed"}`
2. **AllClosedAtEnd**: A property — eventually every locker is `"closed"` again.
   - In PlusCal, after every process reaches `"Done"`, all lockers should read `"closed"`.
   - Express it as: `<>[](\A m \in Members : locker[m] = "closed")` (eventually-always — covered loosely; you can also use a Termination-style check).
   - Simpler: just an invariant that says `pc[m] = "Done" => locker[m] = "closed"` for every member.

Use the simpler invariant form for this puzzle:

```
DoneImpliesClosed == \A m \in Members : pc[m] = "Done" => locker[m] = "closed"
```

## Expected Result

- TLC explores all interleavings of three members opening, using, and closing their lockers.
- Both `TypeOK` and `DoneImpliesClosed` should PASS.
- State count: roughly 64 distinct states (each of 3 members can be at one of 4 pc values independently — 4^3 = 64, minus a few unreachable).

## Hint

Inside the process, `self` is the member's name. `locker[self] := "open"` is the EXCEPT update. To assert across all members in an invariant, use `\A m \in Members : ...`.
