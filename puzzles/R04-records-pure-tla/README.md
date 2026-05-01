# R04: Review — Records via TLA+ EXCEPT ⭐

## Lesson: Records, but in Pure TLA+

You learned records (`[field |-> value]`, `r.field`, `[r EXCEPT !.field = ...]`) inside PlusCal back in T09. Tier 3 drops PlusCal entirely. This puzzle is a bridge: **same record operators, but written directly in TLA+** instead of being translated by pcal.

The shift is small but real:

- No `(*--algorithm ... *)` block. You write `Init`, `Next`, `Spec` by hand.
- No `:=`. State changes use **primed variables**: `x' = expr` means "in the next state, `x` has value `expr`."
- No labels, no `pc`. A step is just an action formula on `vars` and `vars'`.

The records themselves are unchanged. `[r EXCEPT !.field = newval]` still means "the same record but with `field` replaced." Read T09 if any of that feels rusty.

**Worked example — a vending machine record.**

A vending machine tracks a record `state` with two fields: `inventory` (number of cans) and `coins` (cents in the till). One action sells a can: `inventory` drops by 1, `coins` rises by 75. Here is the full pure-TLA+ spec:

```
---- MODULE Vending ----
EXTENDS Integers

VARIABLE state

TypeOK == state \in [inventory: 0..10, coins: 0..1000]

Init == state = [inventory |-> 10, coins |-> 0]

Sell ==
  /\ state.inventory > 0
  /\ state' = [state EXCEPT !.inventory = @ - 1, !.coins = @ + 75]

Next == Sell

Spec == Init /\ [][Next]_state
====
```

Walk through it:

- `VARIABLE state` declares the single variable. (Plural form `VARIABLES` works too; both are accepted.)
- `Init` is a **predicate on the unprimed state** — "what's true initially." For a single variable, `state = [...]` is the whole story.
- `Sell` is a **predicate on the unprimed AND primed state** — "what relates one step to the next." The first conjunct is a guard (`state.inventory > 0`); the second describes the new value of `state`.
- The `EXCEPT` form `[state EXCEPT !.inventory = @ - 1, !.coins = @ + 75]` updates two fields at once. The `@` is sugar for "the old value of the field being updated" — without it you'd write `state.inventory - 1`, which works but is verbose when the field name is long.
- `Next == Sell` because there is only one action. (T31 generalizes to multiple actions joined by `\/`.)
- `Spec == Init /\ [][Next]_state` is the standard shape: "starts in `Init`, every step is either a `Next` step or stutters on `state`." T32 unpacks `[Next]_v`.

You'd run this with `tlc Vending` (no `-pcal` — the file is already pure TLA+). TLC explores 11 distinct states (`inventory` from 10 down to 0).

## Setup

A music app tracks a `song` record with three fields:

- `title` (a string, fixed at `"Etude"`)
- `plays` (number of times played, starts at 0)
- `liked` (boolean, starts FALSE)

Two things can happen: the user **plays** the song (increments `plays`), or the user **toggles** the like button (flips `liked`).

The app caps `plays` at 5 and then stops — no more plays once the cap is hit. Toggling like is always allowed.

## Task

Author `solution/MusicApp.tla` as **pure TLA+** (no PlusCal, no `(*--algorithm ...*)` block). It must contain:

- `EXTENDS Integers`
- `VARIABLE song`
- `TypeOK == song \in [title: {"Etude"}, plays: 0..5, liked: BOOLEAN]`
- `Init` that sets `song = [title |-> "Etude", plays |-> 0, liked |-> FALSE]`
- A `Play` action: enabled when `song.plays < 5`; sets `song' = [song EXCEPT !.plays = @ + 1]`
- A `ToggleLike` action: always enabled; sets `song' = [song EXCEPT !.liked = ~@]`
- `Next == Play \/ ToggleLike`
- `Spec == Init /\ [][Next]_song`

Author `solution/MusicApp.cfg` with `SPECIFICATION Spec` and `INVARIANT TypeOK`.

## Check

Run from `solution/`:

```bash
tlc MusicApp
```

(No `-pcal` — there is no PlusCal block to translate.)

## Expected Result

- TLC reports **12 distinct states**: 6 values of `plays` (0..5) × 2 values of `liked` (TRUE/FALSE).
- `TypeOK` should pass.
- No deadlock — `ToggleLike` is always enabled, so the system never gets stuck.

If you forget the guard `song.plays < 5` on `Play`, TLC will report a `TypeOK` violation when `plays` becomes 6. If you write `state'` instead of `song'`, you'll get a parse or unknown-symbol error — variable names must match.

## Hints

??? hint "💡 Hint 1 — Where does the syntax change?"
    You learned records in T09 using PlusCal. This puzzle writes the same records without PlusCal. The lesson explains the shift: instead of `:=` and labels, you use **primed variables** (`x'`) to describe the next state. Read the "Worked example" section — it shows `state'` (not `:=`). Does your spec follow that pattern?

??? hint "💡 Hint 2 — What's the structure of an action?"
    An action is a conjunction of a guard and an assignment. Your `Play` action should have the form: `/\ song.plays < 5 /\ song' = [song EXCEPT ...]`. The first line is the guard; the second updates the variable. For `ToggleLike`, there's no guard — it's always enabled.

??? hint "💡 Hint 3 — The @ symbol and EXCEPT"
    Inside `[song EXCEPT !.plays = @ + 1]`, the `@` means "the old value of the field being updated." For `ToggleLike`, you want to flip `liked`, so use `@ + 1` for plays but `~@` (logical NOT) for the boolean field.
