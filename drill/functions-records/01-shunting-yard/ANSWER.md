# The shunting yard: answer

## The answer

```tla
---- MODULE ShuntYard ----
EXTENDS Naturals
CONSTANTS Wagons, Tracks

VARIABLE pos
vars == <<pos>>

TypeOK == pos \in [Wagons -> Tracks]

NoShare == \A w1, w2 \in Wagons : w1 /= w2 => pos[w1] /= pos[w2]

Init == /\ pos \in [Wagons -> Tracks]
        /\ NoShare

Shunt(w, t) == /\ \A v \in Wagons : pos[v] /= t
               /\ pos' = [pos EXCEPT ![w] = t]

Next == \E w \in Wagons, t \in Tracks : Shunt(w, t)

Spec == Init /\ [][Next]_vars
====
```

```
SPECIFICATION Spec
INVARIANTS TypeOK NoShare
CHECK_DEADLOCK TRUE
CONSTANTS
  Wagons = {a, b, c}
  Tracks = {t1, t2, t3, t4}
```

One variable, one function, wagon to track. The two lines the prompt asks
for are the `TypeOK` line and the `Init` line, and both of them name the
same set.

24 is a hand count. Three named wagons onto four tracks with no sharing is
4 times 3 times 2. Every shunt moves one wagon onto the one free track, so
a state has 3 successors and all of them are already in the 24. TLC
generated 96 and found 24, which is the 24 plus 72 successors that were all
repeats.

## Two spellings, and only one of them belongs here

`[Wagons -> Tracks]` is a set. At this model size it holds 64 functions,
and `pos \in` it is what lets the day open anywhere the rule allows.

`[w \in Wagons |-> Tracks]` is one function. Its value at every wagon is
the whole set of four tracks, which is not a track.

The two differ by an arrow and a bar, and the reader who reaches for the
wrong one is not making a typo. Both read in English as "wagon to track".
The set is the one you want in both lines of this item, and the literal is
the thing the item exists to rule out.

What makes it worth measuring is that three of the four wrong spellings
never produce a verdict at all. They stop TLC rather than violating
anything, so the reader gets rc 75 and a message about enumerability or
fingerprinting instead of a named invariant and a trace.

## The four swaps

The prompt's closing question is what the checker does when the `Init` line
and the `TypeOK` line swap shapes. There are four wrong cells, and they do
four different things.

| line changed | what it becomes | result |
|---|---|---|
| `Init` takes `=` and the set | `pos` is a set of 64 functions | rc 75, TLC cannot fingerprint |
| `Init` takes `=` and the literal | `pos` is one function onto sets | rc 12, `TypeOK` red on the first state |
| `Init` takes `\in` and the literal | the right side of `\in` is a function | rc 75, not enumerable, 0 states |
| `TypeOK` takes `\in` and the literal | asks whether a function is in a function | rc 75, 1 state |

The second row is the only readable one. A function literal onto sets is a
legal TLA+ value, so `TypeOK` gets evaluated, comes out false, and TLC
prints the offending state. Everywhere else the mistake takes the checker
somewhere it cannot answer the question.

Worth noting what the first row does **not** do. `pos = [Wagons -> Tracks]`
makes the variable a set, and the plain reading is that `TypeOK` is then
false, since a set of functions is not one of the functions. TLC does not
say that. It stops at `Attempted to check if ... which is not a TLC
function value, is in the set of functions`, then `TLC was unable to
fingerprint`, and exits 75. The stack trace points at the `TypeOK` line and
at the `Init` line above it. The comment in that module says the invariant
is false on the first state, and I think that reading is wrong in a way
worth keeping an eye on: TLC refused the question rather than answering it.

## The fifth neighbor

`ShuntYardNoGuard` is a separate mistake and the only one in this item that
has nothing to do with the two spellings. Both lines are right. The shunter
checks that the wagon is not already on the target track and forgets to
check that nothing else is:

```tla
Shunt(w, t) == /\ pos[w] /= t
               /\ pos' = [pos EXCEPT ![w] = t]
```

24 initial states, then `NoShare` goes red on the first move, with a
two-state trace and `Shunt(b,t1)` named in it. rc 12. This is the loud one,
and it's in the item as the contrast: a logic error in the rule reads
straight off the output, and a wrong spelling of the type does not.

## Acceptable variants

- `NoShare` written as `\A w1, w2 \in Wagons : pos[w1] = pos[w2] => w1 = w2`. Same thing.
- `Shunt` guarded with `pos[w] /= t` as well as the free-track check. Implied, and harmless.
- `Init` with `NoShare` spelled out instead of reused. Costs a line, same 24.
- `Tracks` as `1..4` with `EXTENDS Naturals` doing real work. Not measured, and I'd expect the same 24.

The last one changes nothing about the lesson. Model values are here so the
trace reads as track names rather than as arithmetic the item never uses.

## Elimination table

| neighbor answer | what kills it |
|---|---|
| `=` where the set belongs | an evaluation failure, not a violated invariant |
| the literal in either line | enumerability or a function applied as a set |
| no free-track check in the shunter | `NoShare` red on the first move, with a trace |
| `Init` without `NoShare` | the day could open with two wagons sharing. Not measured |
| `[][Next]_pos` instead of `_vars` | passes here, since `pos` is the whole state. Not measured |

The fourth row is the one I'd expect a reader to get right by accident. The
prompt states the rule twice, once as the yard's rule and once as a thing
the opening has to respect, so the conjunct in `Init` is hard to miss.

## Why not in prompt

The prompt holds the whole subject back. It says what the yard is, what the
variable has to carry, where the day can start and what the rule is, all in
English, and it never writes a bracket. A reader who already knows that
TLA+ has two bracket forms will pick the right one without reading this
file, and that reader is not who the item is for.

The 24 is in the prompt on purpose. It's the foreclosing row. Three of the
five wrong neighbors exit 75 and announce themselves, so for those the
count is redundant, but the readable one exits 12 on the first state and a
reader could take that for a bad choice of model size. The count says the
model size is not the problem.

The closing prediction is the part I'd watch in practice. Asking for it
without a run is asking the reader to hold both bracket forms in their head
at once and say what each does in each line, and my hunch is that most
readers will get the readable 12 and miss that the other three stop the
checker instead.

## Measured runs

TLC2 Version 2026.07.31.184830, one config per module, `-d` passed on all
six because every config in this item carries `CHECK_DEADLOCK TRUE`.
Measured 2026-10-14 through `harness/verdict.sh`.

| module | config | rc | distinct states | TLC says |
|---|---|---|---|---|
| `ShuntYard.tla` | `ShuntYard.cfg` | rc 0 | 24 | no error has been found |
| `ShuntYardSetInit.tla` | `ShuntYardSetInit.cfg` | rc 75 | 1 | `TLC was unable to fingerprint.` |
| `ShuntYardLiteralEq.tla` | `ShuntYardLiteralEq.cfg` | rc 12 | none reported | `Invariant TypeOK is violated by the initial state` |
| `ShuntYardLiteralInit.tla` | `ShuntYardLiteralInit.cfg` | rc 75 | 0 | `the right side of \IN is not enumerable` |
| `ShuntYardLiteralType.tla` | `ShuntYardLiteralType.cfg` | rc 75 | 1 | `Attempted to check if the value ... is an element of the function` |
| `ShuntYardNoGuard.tla` | `ShuntYardNoGuard.cfg` | rc 12 | 25 | `Invariant NoShare is violated.` |

The reference generated 96 states to find its 24. `ShuntYardNoGuard`
generated 25 and stopped, with 23 still on the queue, which is what a
first-move violation looks like out of a 24-state opening.

The third row reports no count because TLC never finished computing initial
states. It printed the violation and the counterexample and left.
