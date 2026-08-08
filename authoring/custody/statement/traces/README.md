# Traces for P1

Every property in `../PROBLEM.md` ships with two behaviors: one that satisfies
it and one that violates it. The satisfying side of all ten is a single
behavior, `full-window.md`, a window that goes right from opening to day 14.
It comes from a correct model. Each violating trace comes from a real broken
model, one per file, and each file says where its behavior breaks the
property.

Read them before you model. If TLC later hands you a counterexample shaped
like one of these, you are standing in that trap.

## How to read the tables

Every row is one state of the observation, nothing else. The columns are the
three `Observe` fields plus a narration of the step that led in.

- **today**: the latest day to have begun. "none yet" is the 0 marker.
- **custody, days 1-14**: `custodian` as fourteen letters, day 1 on the left,
  with a space after day 7. Position d is who has day d right now.
- **A proposes / B proposes**: `pending` per parent. "none" is the 0 marker.

The scheduled parents for the arrangement are:

```
AAABAAA BBBABBB     (days 1-14: base pattern, with day 4 to B, day 11 to A)
```

Custody starts there, and an agreed swap shows as one letter differing from
this string. The narration column speaks the parents' language. It is not a
fourth field, and your model does not have to name any of it.

## The files

| File | Property |
|---|---|
| `full-window.md` | satisfies all ten |
| `property-01.md` | total custody |
| `property-02.md` | the opening baseline |
| `property-03.md` | at most one flip |
| `property-04.md` | flips come from acceptance |
| `property-05.md` | the past is fixed |
| `property-06.md` | proposals point forward |
| `property-07.md` | the cap |
| `property-08.md` | quiet at the end |
| `property-09.md` | the window runs |
| `property-10.md` | a proposal holds its day |
