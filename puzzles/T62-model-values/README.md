# T62: Model Values vs Concrete Values ⭐⭐

## Lesson: When Identity Matters and When It Doesn't

T60 introduced **model values** — opaque tokens declared in the cfg, equal only to themselves. T62 is about WHEN to use them and WHY the alternative (concrete values like strings or integers) is the wrong tool.

**The rule:**

- A **concrete value** like `"alice"`, `42`, or `<<1, 2>>` has a known type and rich equality semantics. `"alice" = "alice"` is TRUE; `"alice" < "bob"` is meaningful (lexicographic); `42 + 1 = 43`.
- A **model value** like `alice` (no quotes) is opaque. `alice = alice` is TRUE, `alice = bob` is FALSE — that's the entire equality theory. You can't add it, compare it ordinally, or do anything other than test equality.

**Worked example — patient identifiers vs. patient names.**

A clinic spec models patients waiting to be seen. The spec NEVER inspects a patient's name — it just tracks who's in the queue and who's been seen. Two ways to model patients:

```
\* Approach A — concrete strings
CONSTANT Patients = {"alice", "bob", "carol"}

\* Approach B — model values
CONSTANT Patients = {p1, p2, p3}
```

Both work for safety. The spec says `\E p \in Patients \ seen : ...` and never branches on `p = "alice"` specifically. So far, no difference.

NOW try to add `SYMMETRY Permutations(Patients)`. With approach A (strings), TLC throws a runtime error:

```
Symmetry function must have model values as domain and range.
```

TLC won't permute concrete values — they have an identity beyond equality (the string ordering, the bytes, etc.) and TLC doesn't trust that the permutation is sound. With approach B (model values), TLC accepts the symmetry and reduces the state space dramatically.

**The judgment:**

- Use **model values** when (a) the spec only cares about identity (equality) of the value, AND (b) you want to apply SYMMETRY for state-space reduction.
- Use **concrete values** when (a) the spec compares the value with `<`, `>`, arithmetic, or string operations, OR (b) the value's "shape" matters (a record, a sequence).

A common mistake is picking strings for human readability of the trace and being unable to apply SYMMETRY later. The fix: switch to model values; the trace will print `alice` either way.

**Equality semantics — what model values can and can't do.**

Inside the spec, you can:

- Compare with `=` and `#`: `worker = manager` is well-defined.
- Use them as set elements: `Workers = {alice, bob}` is a set with two elements.
- Use them as record-field tags: `[role |-> alice]` is a valid record.

You CANNOT:

- Order them: `alice < bob` is undefined.
- Do arithmetic: `alice + 1` errors out.
- Convert them: there's no string form, no integer form.

If your spec needs any of those, model values are the wrong choice.

**A subtle case — distinguished members.**

A spec may have a SET of model values that are interchangeable (`Workers`) and ONE value within that set that is distinguished (`Boss`, who supervises). The right thing is:

- `CONSTANT Workers = {w1, w2, w3, boss}` — model values
- `CONSTANT Boss = boss` — a specific one of them
- `SYMMETRY Permutations(Workers \ {Boss})` — permute only the interchangeable ones

This is a new pattern, not covered in T60 — `Permutations` can take any set, including a subset formed by set-difference (`\`).

This is how you keep symmetry usable when one process is special.

## Setup

A pre-written spec lives in `solution/Tasks.tla`: a set of workers complete tasks, one at a time. One worker (the Boss) supervises and never finishes a task. The cfg uses **model values** for workers and applies SYMMETRY only to the non-Boss workers.

## Task

Run TLC as-is:

```bash
cd solution
tlc Tasks
```

Note: 4 distinct states (one per cardinality of `done`).

Now edit `solution/Tasks.cfg` and replace the model values with strings:

```
CONSTANT Workers = {"alice", "bob", "carol", "boss"}
CONSTANT Boss = "boss"
```

Re-run. TLC errors out with:

```
Symmetry function must have model values as domain and range.
```

Restore the model values.

Now try a third experiment: keep model values, but add a comparison operator the spec doesn't support. Inside `solution/Tasks.tla`, change `Finish` to:

```
Finish == \E w \in Workers \ done : w # Boss /\ w > Boss /\ done' = done \cup {w}
```

Save the file and re-run TLC. TLC errors at evaluation: `>` is not defined for model values.

Restore the original `Finish`.

## Check

- With model values + correct spec: 4 distinct states, "No error has been found."
- With strings + SYMMETRY: TLC throws "Symmetry function must have model values as domain and range."
- With model values + ordinal comparison: TLC errors at runtime when it tries to evaluate `w > Boss`.

## Expected Result

- Model values + symmetry → fast and correct.
- Strings + symmetry → TLC refuses to run.
- Model values + arithmetic/order → TLC errors at runtime.

The two failures map to the two halves of the rule: model values give you symmetry but cost you ordinal/arithmetic operations; concrete values give you operations but cost you symmetry.

## What to take away

- **Use model values** when the spec only needs equality and you want SYMMETRY.
- **Use concrete values** when the spec needs arithmetic, ordering, string operations, or shape inspection.
- Set up your specs with model values from the start whenever symmetry is plausible — switching later is mechanical but tedious.
- One model value in a set CAN be distinguished (Boss) — symmetry then permutes only the interchangeable ones via `Permutations(Workers \ {Boss})`.

## Hints

??? hint "💡 Hint 1 — Equality vs. Ordering"
    The lesson stated the rule: use model values when the spec ONLY cares about equality (e.g., `worker = manager` or `w \in done`). Use concrete values when the spec needs comparison (`<`, `>`, `<=`), arithmetic, or string operations. In Tasks, do any of the spec's guards or actions compare workers with `<` or `+`? Or do they only test equality? The answer decides whether model values or strings are appropriate.

??? hint "💡 Hint 2 — Permutations Require Model Values"
    When you try `SYMMETRY Permutations(Workers)` with concrete values like strings, TLC throws "Symmetry function must have model values as domain and range." Why? Because strings have a built-in total order (lexicographic), and TLC can't permute something with an intrinsic identity. Permutations only work on opaque tokens (model values) that have NO semantics beyond equality. The error is TLC protecting you: if it allowed string permutation, it would be unsound.

??? hint "💡 Hint 3 — Boss As a Distinguished Value"
    The Boss is special — they never finish a task. This asymmetry means you can't apply `Permutations(Workers)` to the full set; Boss would be treated like any other worker, and the reduction would be unsound. The fix: `Permutations(Workers \ {Boss})` permutes only the interchangeable workers, leaving Boss fixed. This is the right pattern when a spec has one privileged process among a symmetric set.
