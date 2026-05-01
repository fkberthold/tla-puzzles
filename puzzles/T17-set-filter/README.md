# T17: Set Comprehension — Filter ⭐

## Lesson: Selecting a Subset by Predicate

So far you've built sets by listing them: `{1, 2, 3}` or `0..3` or `{"a", "b"}`. T17 introduces SET COMPREHENSION — building a new set from an existing one.

The FILTER form keeps the elements of a source set that satisfy a predicate:

```
{x \in S : P(x)}
```

Read aloud: "the set of `x` in `S` such that `P(x)`." The colon means "where" or "such that."

```
{n \in 1..10 : n > 5}                    \* {6, 7, 8, 9, 10}
{n \in 0..20 : n % 2 = 0}                \* {0, 2, 4, ..., 20} — the evens
{s \in {"yes", "no", "maybe"} : Len(s) = 3}   \* {"yes"}
```

The shape is always `{ binding : predicate }`. The binding `x \in S` introduces the variable; `P(x)` is the boolean test that decides which elements survive.

You'll use this constantly in invariants:

- "every account in the active set has a positive balance"
- "the set of orders pending is the set of orders not yet shipped"
- "the count of busy workers is the cardinality of `{w \in Workers : status[w] = "busy"}`"

**Worked example — a guest list filtered by RSVP.**

A wedding has 4 invited guests. The host tracks each guest's RSVP status. The kitchen needs the set of guests who've actually said yes — to set the table.

```
(*--algorithm Wedding {
  variables
    rsvp = [g \in {"alice", "bob", "carol", "dave"} |-> "pending"],
    confirmed = {};

  define {
    Guests == DOMAIN rsvp
    Yeses == {g \in Guests : rsvp[g] = "yes"}    \* filter: just the confirmed
  }

  fair process (host = "Host") {
    collect:
      \* Each guest answers nondeterministically.
      with (a \in [Guests -> {"yes", "no"}]) {
        rsvp := a;
      };
    settable:
      confirmed := Yeses;     \* read the filtered set into a variable
  }
}*)
```

Sample invariants:

- `TypeOK == \A g \in Guests : rsvp[g] \in {"pending", "yes", "no"} /\ confirmed \subseteq Guests`
- `ConfirmedAreYes == \A g \in confirmed : rsvp[g] = "yes"` — by construction; passes
- `NoMaybes == \A g \in confirmed : rsvp[g] /= "maybe"` — passes; only "yes" makes the cut

The filter `{g \in Guests : rsvp[g] = "yes"}` runs over EVERY guest, applies the predicate, and gathers those that pass. There's no order, no iteration — just a set defined by membership.

(In T18 you'll meet the second comprehension form — the MAP, where the expression before the colon transforms each element. Today is filter only: the binding variable appears verbatim in the result.)

## Setup

A small library tracks a function `loaned` from book ID to borrower name (or `"none"` if not loaned). The librarian wants to know:

- the set of book IDs currently out on loan,
- the set of book IDs still available.

You'll define both as filters over the function's domain.

## Task

Write a PlusCal spec with:

- A variable `loaned` initialized so book 1 is on loan to "alice", and books 2, 3, 4 are not loaned:
  ```
  loaned = [b \in 1..4 |->
              IF b = 1 THEN "alice" ELSE "none"]
  ```
- A variable `outOnLoan` starting at `{}`
- A variable `available` starting at `{}`
- A variable `phase` starting at `0`

A single fair process runs three labels:

1. **scanLoaned**: set `outOnLoan := {b \in 1..4 : loaned[b] /= "none"}`. Increment `phase`.
2. **scanAvailable**: set `available := {b \in 1..4 : loaned[b] = "none"}`. Increment `phase`.
3. **finish**: increment `phase`.

In the `define` block:

- `Books == DOMAIN loaned`
- `TypeOK == Books = 1..4 /\ outOnLoan \subseteq Books /\ available \subseteq Books /\ phase \in 0..3`
- `Disjoint == outOnLoan \intersect available = {}`  \* a loaned book isn't available
- `EndsCorrect == phase = 3 => (outOnLoan = {1} /\ available = {2, 3, 4})`

(`\intersect` is set intersection. You haven't been asked to USE intersection in earlier puzzles, but the operator name is suggestive. If TLC complains, replace with `\cap` — it's the same operator with a shorter name.)

## Check

1. **TypeOK** — see above.
2. **Disjoint** — once both filters have run, the two sets share no element.
3. **EndsCorrect** — after both scans, the loan set is `{1}` and the available set is `{2, 3, 4}`.

## Expected Result

- TLC should report `No error has been found`.
- All three invariants pass.
- The canonical solution reports **4 distinct states** (one per `phase` value). Your deterministic spec will produce a similar count.

**Bonus.** Replace `loaned[b] /= "none"` with `loaned[b] \in {"alice", "bob"}` — this filter "by membership in a set" is a common shape. Predict whether the result is the same (only alice has a loan), then run TLC and confirm.

## Hints

??? hint "💡 Hint 1 — Filter syntax: binding before colon"
    The filter `{x \in S : P(x)}` puts the BINDING (`x \in S`) BEFORE the colon, and the PREDICATE (`P(x)`) AFTER. Read it as "the set of x in S WHERE P(x) holds." You iterate through the domain `loaned` (which is 1..4), and keep only the books where the predicate matches.

??? hint "💡 Hint 2 — Two filters: out on loan and available"
    One filter keeps books where `loaned[b] /= "none"` (on loan). The other keeps books where `loaned[b] = "none"` (available). These are COMPLEMENTARY — every book is in exactly one. Together, `outOnLoan \cup available = {1, 2, 3, 4}`.

??? hint "💡 Hint 3 — The invariant Disjoint is automatic"
    Because you defined `outOnLoan` and `available` as complementary filters (one checks `= "none"`, the other checks `\= "none"`), they are guaranteed to be disjoint. The invariant `Disjoint` checking `outOnLoan \intersect available = {}` will always pass — it's a logical consequence of your definitions.
