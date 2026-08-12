# Coverage audit: learntla core ch.4

Audited against the six major themes and five constructs in
`exercises/ch04/CHEATSHEET.md`. This is an audit written after the set, not
the thing the set was built from.

## Major themes

| # | Theme (abbreviated) | Exercises | Status |
|---|---|---|---|
| 1 | Checked on every reachable state, not "the spec ran" | 1, 3, 4 | covered |
| 2 | Type invariants pin shape with `\in` and `\subseteq` | 1 | partial |
| 3 | Error trace, one state per row, `pc` on each, changes in red | 1, 2 | partial |
| 4 | `pc` and `=>` restrict a check to one point | 2 | covered |
| 5 | `\A` and `\E` are vacuous on the empty set | 3, 4 | covered |
| 6 | `=>` in a quantifier, and the `\E` trap | 4 | covered |

Theme 1 is the spine of the set rather than one exercise's lesson. Exercise 1
carries it hardest, because its `TRUE` stub passes both the good spec and the
broken one. A learner who stops at the pass run learns nothing, and the set
says so out loud.

Theme 5 shows up twice on purpose, from opposite sides. Exercise 3 fails an
`\E` on an empty set. Exercise 4 has an `\E` on an empty set hold at the
initial state and then fail one row later. I think seeing both is what makes
the rule stick, rather than seeing it named once.

## Two partials, and why

**Theme 2, `\subseteq`**: no exercise asks for it. Exercise 1's type
invariant is two uses of `\in` on integer counts. The only set-valued
variable in the set is `pending` in exercise 3, and pinning its shape there
would sit next to the vacuity drill and compete with it for the learner's
attention. So `\subseteq` is named on the cheat sheet and not drilled here.
A later revision could add `pending \subseteq Jobs` to `DrainQueue.tla` as a
given, which is where I'd put it.

**Theme 3, "changed values in red"**: not reproducible. Red is a Toolbox
rendering. TLC's command-line trace prints every variable on every row with
no color at all, so the part of the theme a learner can practice here is
reading the rows and finding `pc`. Exercises 1 and 2 both ask for that.
Exercise 2 asks for `pc` by name. The color is a property of one front end,
not of the trace.

## Constructs

| Construct | Exercises |
|---|---|
| `Invariant` as a TLA+ operator | 1, 2, 3, 4 |
| `define` block | 1, 2, 3, 4 |
| `pc` | 2 |
| `\A` | 2, 3, 4 |
| `\E` | 2, 3, 4 |

## Scope check

Every construct used comes from chapters 2, 3, and 4. Checked against the
ch02, ch03, and ch04 cheat sheets.

From ch.2: operator definitions, `EXTENDS Integers` and `EXTENDS Sequences`,
integers, booleans, `/\`, `~`, `=>`, sequences and `seq[i]` and `Len` and
`Append`, sets and `\in` and `\`, `\union`, the `a..b` interval.

From ch.3: the `--algorithm` block, `:=`, labels, `while`, PlusCal `if`,
`with`, and the translation step.

From ch.4: the `define` block, `pc`, `\A`, `\E`, and invariants themselves.

Nothing from ch.5 or later. No `CONSTANT`, so every parameter is a plain
operator (`Capacity`, `Input`, `Jobs`, `Steps`). No structures and no
function literals, which are ch.6.
