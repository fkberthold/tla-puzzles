# T57: Refinement — Stuttering Steps ⭐⭐⭐

## Lesson: Why `[Next]_vars` (Not `Next`) — Stutter is Refinement's Lifeblood

You've been writing `Spec == Init /\ [][Next]_vars` mechanically since Tier 3. The `[Next]_vars` notation is shorthand for `Next \/ UNCHANGED vars` — "either Next happens, or the variables don't change." That second disjunct is called STUTTERING.

Stutter steps don't matter much for a single spec. But they're the WHOLE POINT of refinement.

**Why stuttering must be allowed:**

The concrete spec usually has MORE actions than the abstract. Abstract says `Sell`. Concrete says `OpenDrawer`, `ScanItem`, `RingTotal`, `Sell`, `CloseDrawer`. From the abstract's projected viewpoint, four out of five concrete steps DON'T CHANGE the abstract variables — they're invisible. They are stutters relative to the abstract.

If the abstract spec said `Init /\ [] Next` (no brackets, no `_vars`), then EVERY concrete step would have to match a real abstract step. That's impossibly strict — `OpenDrawer` doesn't correspond to any abstract action.

`[Next]_vars` says "every step is either a real Next-step or a stutter." So `OpenDrawer` (which leaves `stock` unchanged) is allowed — it's a stutter. The abstract observer sees no change. The concrete observer sees a drawer open. Both observers' specs are satisfied.

**The square-bracket notation:**

`[A]_v` is read "the action A or stuttering on v." Formally: `A \/ (v' = v)`. When `v` is a tuple of variables, `v' = v` means each variable equals its primed self. So `[Next]_vars` = `Next \/ UNCHANGED vars`.

`<<A>>_v` is the dual: A AND a real change to v. We won't need it here.

**Worked example — file system meta and content.**

Abstract `FileSystemA` tracks file CONTENT — when content changes, that's a real abstract step. Metadata (filename, timestamp) is invisible to the abstract.

```
---- MODULE FileSystemA ----
VARIABLE content
Init == content = ""
Write(c) == content' \in STRING /\ content' /= content
Next == \E c \in {"hello", "world", "TLA+"} : content' = c /\ content /= c
Spec == Init /\ [][Next]_<<content>>
====
```

Concrete `FileSystemC` adds `mtime` (modification time). `Touch` updates mtime without changing content — invisible to the abstract:

```
---- MODULE FileSystemC ----
EXTENDS Integers
VARIABLES content, mtime
vars == << content, mtime >>
Init == content = "" /\ mtime = 0
Write ==
  /\ \E c \in {"hello", "world", "TLA+"} : content /= c /\ content' = c
  /\ mtime' = mtime + 1
Touch ==
  /\ mtime' = mtime + 1
  /\ UNCHANGED content
Next == Write \/ Touch
Spec == Init /\ [][Next]_vars

L0 == INSTANCE FileSystemA WITH content <- content
Refines == L0!Spec
====
```

`Touch` leaves `content` unchanged but increments `mtime`. From the abstract's projection (just `content`), `Touch` is `content' = content` — a stutter. Allowed by `[Next]_<<content>>`.

**The wrong way:**

If the abstract had been written `Spec == Init /\ [] Next` (no brackets), the concrete `Touch` step would have had to satisfy `\E c \in {...} : content /= c /\ content' = c`. But during `Touch`, `content' = content`, so `content /= c` and `content' = c` together force `c /= c` — false. The refinement check would fail on every Touch.

The `_vars` is not boilerplate. It's the formal admission that "the implementation may take steps the abstract doesn't see."

## Setup

You'll write a concrete spec with explicit "noise" steps that are pure stutter relative to the abstract.

The abstract `Counter`: a counter that increments by 1, with no other actions.

The concrete `LoggedCounter`: same counter, plus a `lastLog` string that records "no-op" or "incremented" each step. There is also a `Log` action that updates `lastLog` to "no-op" without changing the counter — pure stutter from the abstract's view.

## Task

Three files in `solution/`:

### `solution/Counter.tla`

```
---- MODULE Counter ----
EXTENDS Integers
CONSTANT Max
ASSUME Max \in Nat /\ Max >= 1

VARIABLE n
Init == n = 0
Inc == n < Max /\ n' = n + 1
Next == Inc
Spec == Init /\ [][Next]_<<n>>

TypeOK == n \in 0..Max
====
```

### `solution/LoggedCounter.tla`

- `EXTENDS Integers`
- `CONSTANT Max`, `ASSUME Max \in Nat /\ Max >= 1`
- `VARIABLES n, lastLog`
- `vars == << n, lastLog >>`
- `Init == n = 0 /\ lastLog = "init"`
- `Inc == n < Max /\ n' = n + 1 /\ lastLog' = "incremented"`
- `Log == lastLog' = "no-op" /\ UNCHANGED n`
- `Next == Inc \/ Log`
- `Spec == Init /\ [][Next]_vars`
- `TypeOK == n \in 0..Max /\ lastLog \in {"init", "incremented", "no-op"}`
- `L0 == INSTANCE Counter WITH n <- n`
- `Refines == L0!Spec`

### `solution/LoggedCounter.cfg`

```
SPECIFICATION Spec
CONSTANT Max = 3
INVARIANT TypeOK
PROPERTY Refines
```

## Check

```bash
cd solution
tlc LoggedCounter
```

## Expected Result

- TLC explores about **9 distinct states** (4 values of `n` × up to 3 lastLog values, minus unreachable combos).
- `TypeOK` passes.
- `Refines` PASSES — `Inc` matches the abstract `Inc`; `Log` is a pure stutter on `n`.

## Strip Test

To FEEL why the brackets matter, edit `Counter.tla` and change:

```
Spec == Init /\ [][Next]_<<n>>
```

to

```
Spec == Init /\ [][Next]_<<n, lastLog>>
```

Wait — `lastLog` isn't even declared in `Counter`. So you can't just append it. Instead, edit `LoggedCounter.tla` and try: change the INSTANCE substitution to provide a different mapping. Or, more directly: in `Counter.tla` change `[Next]_<<n>>` to plain `Next` (no brackets, no `_<<n>>`). Re-run TLC on `LoggedCounter`. You should see TLC report a refinement violation: a `Log` step that doesn't satisfy the un-bracketed abstract `Next` (which would require `n' = n + 1`).

This is what the brackets buy you. They are the formal hook on which refinement hangs.

## Hints

??? hint "💡 Hint 1 — [Next]_vars allows stuttering; plain Next does not"
    [Next]_vars = Next \/ UNCHANGED vars. The concrete Log action doesn't change `n`, so it's a stutter on `n`. Without the brackets, Log would have to match an abstract step, which it doesn't — refinement breaks.

??? hint "💡 Hint 2 — Stuttering is not a hack; it's the refinement glue"
    The concrete has internal events (Log) that the abstract doesn't see. From the abstract's projection (just `n`), those events disappear. That's what stuttering formalizes — invisible implementation details.

??? hint "💡 Hint 3 — Check the square brackets in the abstract"
    Your abstract MUST say Spec == Init /\ [][Next]_vars (with brackets and _vars). If it said just Next (no brackets), refinement would require every concrete step to match a real abstract step — impossible if the concrete has internal-only actions.

