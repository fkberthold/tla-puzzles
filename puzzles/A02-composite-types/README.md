# A02: Apalache — Composite Types ⭐

## Lesson: Apalache Type Constructors

A01 covered `Int`, `Bool`, `Str`. Real specs need composite types. Apalache has five constructors that compose them:

| TLA+ value           | Apalache type           |
|----------------------|-------------------------|
| `{1, 2, 3}`          | `Set(Int)`              |
| `<<1, 2, 3>>`        | `Seq(Int)`              |
| `<<1, "ok">>`        | `<<Int, Str>>`          |
| `[a \|-> 1, b \|-> "ok"]` | `{ a: Int, b: Str }` |
| `[k \in S \|-> ... ]` (a function)  | `Int -> Str` (or whatever the domain/codomain types are) |

A few things to watch:

- Sets and sequences are **homogeneous** in Apalache: every element must have the same type. `Set(Int)` cannot mix integers and strings. (TLC tolerates heterogeneity at runtime; Apalache rejects it before model checking starts.)
- A **tuple** type `<<Int, Str>>` is fixed-length and can mix types per position. It is *not* the same as a `Seq` — sequences are variable-length and homogeneous.
- A **record** type uses curly braces: `{ a: Int, b: Str }`. Field order doesn't matter.
- A **function** type uses an arrow: `Int -> Str` means the domain is integers and the codomain is strings. (For functions with finite explicit domains like `[k \in {1,2,3} \|-> ... ]`, you write the domain element type, not the literal set.)

**Worked example — a music library.**

A library tracks: a set of artists (strings), a playlist (sequence of song IDs), a top-track tuple of `<<song_id, play_count>>`, a record describing the current track, and a function from artist name to album count.

```tla
---- MODULE MusicLibrary ----
EXTENDS Integers, Sequences

\* @type: Set(Str);
VARIABLE artists

\* @type: Seq(Int);
VARIABLE playlist

\* @type: <<Int, Int>>;
VARIABLE topTrack

\* @type: { id: Int, title: Str };
VARIABLE current

\* @type: Str -> Int;
VARIABLE albumCount

vars == << artists, playlist, topTrack, current, albumCount >>

Init ==
  /\ artists    = { "Bjork", "Aphex" }
  /\ playlist   = << 101, 102 >>
  /\ topTrack   = << 101, 5 >>
  /\ current    = [ id |-> 101, title |-> "Hyperballad" ]
  /\ albumCount = [ a \in {"Bjork", "Aphex"} |-> 4 ]

Play ==
  /\ topTrack' = << topTrack[1], topTrack[2] + 1 >>
  /\ UNCHANGED << artists, playlist, current, albumCount >>

Next == Play

Spec == Init /\ [][Next]_vars
====
```

Each variable's type is one line, sitting in a `\*` comment. The five constructors above cover the entire spec. `apalache-mc typecheck MusicLibrary.tla` accepts it.

**The key idea.** Once you know the five constructors, you can annotate any non-recursive TLA+ data shape. Reach for these whenever a variable is anything more than a primitive.

## Setup

A package tracker for an online store. The state we want to model:

- A set of pending order IDs (integers).
- A queue of orders being processed in FIFO (sequence of integers).
- A 2-tuple `<<warehouse_id, picker_id>>` (both integers) for the current shift.
- A record `currentOrder` with fields `id` (integer) and `priority` (string).
- A function from order ID (integer) to status string ("pending", "processing", "shipped").

## Task

Write `Tracker.tla` with five variables, each `\* @type:`-annotated using the right constructor:

| variable        | meaning                          | type                  |
|-----------------|----------------------------------|-----------------------|
| `pending`       | set of order IDs                 | `Set(Int)`            |
| `queue`         | queue of order IDs               | `Seq(Int)`            |
| `shift`         | warehouse-picker pair            | `<<Int, Int>>`        |
| `currentOrder`  | record                           | `{ id: Int, priority: Str }` |
| `status`        | order ID → status string         | `Int -> Str`          |

Initial state:
- `pending = { 1, 2, 3 }`
- `queue = << >>`
- `shift = << 10, 20 >>`
- `currentOrder = [ id |-> 0, priority |-> "none" ]`
- `status = [ i \in { 1, 2, 3 } |-> "pending" ]`

Add ONE action `Promote` that picks any `i \in pending`, removes it from `pending`, appends it to `queue`, sets `currentOrder` to `[id |-> i, priority |-> "high"]`, updates `status[i]` to `"processing"`, and leaves `shift` unchanged. (Use `\E i \in pending: ...` for nondeterminism.)

Add a `TypeOK` invariant:

```
TypeOK ==
  /\ pending \subseteq { 1, 2, 3 }
  /\ Len(queue) <= 3
  /\ shift = << 10, 20 >>
  /\ currentOrder.id \in 0..3
  /\ currentOrder.priority \in { "none", "high" }
```

## Check

```bash
cd solution
tlc Tracker
```

If you have Apalache:

```bash
apalache-mc typecheck Tracker.tla
```

## Expected Result

- TLC: a small, finite state space (about 16 distinct states), no error.
- Snowcat: `Type checker [OK]`.
- Try mistyping one annotation: change `\* @type: Set(Int);` over `pending` to `\* @type: Set(Str);` and rerun `apalache-mc typecheck`. Snowcat will report a type mismatch at the line where `pending` is initialized to `{ 1, 2, 3 }`. Restore the annotation when you've seen the error.

## What you learned

- Five Apalache type constructors: `Set(T)`, `Seq(T)`, `<<T1, T2>>`, `{ field: T, ... }`, `T -> U`.
- Sets and sequences are homogeneous; tuples and records can mix per slot.
- Snowcat catches type mismatches before model checking begins, with line-precise errors.
