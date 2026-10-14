# Answer: the signal and the ticker

Files in `verify/`. `Signal.tla` is the coarse machine. `Ticker.tla` is
the fine one with the reading and the refinement. `TickerNoAmber.tla`
drops amber from the reading, `TickerNoWith.tla` drops the reading
altogether, and `TickerTheorem.tla` states the claim as a theorem.

Every number from `harness/verdict.sh` on TLC2 Version
2026.07.31.184830.

## Questions 1 and 2: the two modules and the tie

The signal:

```
---- MODULE Signal ----
VARIABLE colour

Init == colour = "red"

Next ==
    \/ colour = "red"   /\ colour' = "green"
    \/ colour = "green" /\ colour' = "amber"
    \/ colour = "amber" /\ colour' = "red"

Spec == Init /\ [][Next]_colour
====
```

The ticker, with the tie at the bottom:

```
---- MODULE Ticker ----
EXTENDS Naturals
VARIABLE tick

Init == tick = 0
Next == tick' = (tick + 1) % 6
Spec == Init /\ [][Next]_tick

Shown ==
    IF tick < 3 THEN "red"
    ELSE IF tick < 5 THEN "green"
    ELSE "amber"

S == INSTANCE Signal WITH colour <- Shown

Refinement == S!Spec
====
```

And the config, `Refines.cfg`:

```
SPECIFICATION Spec
PROPERTY Refinement
```

Three things are doing the work. `S == INSTANCE Signal WITH colour <-
Shown` is the refinement mapping: every operator of `Signal` is now
available as `S!Op` with `Shown` written wherever `Signal` wrote
`colour`. So `S!Spec` is the signal's behaviour formula over the
ticker's state. `Refinement == S!Spec` gives that formula a plain name,
because a config can only name a definition of the root module.
`PROPERTY Refinement` asks TLC to check that every behaviour of the
ticker satisfies it.

The substituted thing here is a variable, not a constant. That's the
usual shape for a refinement: the abstract state is a function of the
concrete state, and the mapping is where you write the function.

## Question 3: five as green

With `Shown == IF tick < 3 THEN "red" ELSE "green"`, the wrap from five
to zero reads as green to red. The signal has no such step. TLC's
message, from `G02NoAmber.tla`'s run:

```
Error: Action property line 12, col 17 to line 12, col 31 of module Signal is violated.
```

Line 12 of `Signal` is `Spec`, and columns 17 to 31 are `[][Next]_colour`.
So the blame lands on the abstract module's own action formula, not on
anything in the ticker. The trace is seven states long: ticks zero
through five, then zero. The violation is on the last step.

A refinement failure is a liveness-class exit, 13, even though this one
is caught on a finite prefix. verdict.sh's table says why: an action
property is checked as a temporal formula.

## Question 4: the theorem

`THEOREM Spec => S!Spec` with the same wrong reading is clean at 6
states. TLC doesn't check theorems. On this build it doesn't warn about
them either. A theorem is a proof obligation, for TLAPS or for a reader,
and the only way to make TLC look at the claim is a `PROPERTY` line
naming a definition. I think this is the trap worth remembering: a
module can carry a true-looking theorem and a config that never asks.

## Question 5: what a config can name

`PROPERTY S!Spec` in the config is refused:

```
Error: The property S specified in the configuration file
is not defined in the specification.
```

TLC reads the name up to the `!` and looks for an operator called `S`.
The config names definitions of the root module and nothing else, which
is why `Refinement == S!Spec` exists at all. The same holds for
`INVARIANT` and `SPECIFICATION`.

## Row three: no reading

`S == INSTANCE Signal` with no `WITH`, in a module that declares no
`colour`:

```
line 14, col 1 to line 14, col 20 of module TickerNoWith
Substitution missing for symbol colour declared at line 3, col 10 to line 3, col 15 of module Signal
and instantiated in module TickerNoWith.
```

An instance has to account for every constant and variable the
instantiated module declares. A name the instantiating module also
declares passes through on its own. Everything else needs a `<-`.

## Variants worth running

Name the two halves separately: `Refinement == S!Init /\ [][S!Next]_Shown`
is the same formula written out, and the subscript is the derived
expression. That's the one place a derived state function appears as a
subscript in published specs, through a mapping like this one.

Make the signal richer. Add a fourth colour, or make amber go back to
green, and the correct reading fails. The item's signal is as small as it
can be while still having a step a wrong reading can break.

## The whole table

| config | module run | rc | distinct | depth |
|---|---|---|---|---|
| `Refines.cfg` | the ticker, correct reading | 0 | 6 | 6 |
| `Refines.cfg` | five read as green | 13 | 6 | 6 |
| `Refines.cfg` | no reading | 150 | | |
| spec only | the theorem, five read as green | 0 | 6 | 6 |
| property named with a `!` | the ticker, correct reading | 151 | | |

## Gate rows

One thin wrapper module per run the drill gate reproduces, each with a
copy of the config it stands for. The rc is what `harness/verdict.sh`
returns.

| module | rc | distinct | stands for |
|---|---|---|---|
| `G02Ticker.tla` | rc 0 | 6 | the answer, 6 states |
| `G02NoAmber.tla` | rc 13 | 6 | five read as green, the signal's action formula violated |
| `G02NoWith.tla` | rc 150 | - | no reading, substitution missing for colour |
| `G02Theorem.tla` | rc 0 | 6 | the theorem alone, wrong reading, unchecked |
| `G02BangCfg.tla` | rc 151 | - | the config naming the instance formula directly |

## why-not-in-prompt

The prompt describes both machines in words and says the reading is
"how to read the count as a colour". It says a keyword in the config
asks for the check, and that row three is about a symbol "never
substituted". Those are the mechanism in English.

What the prompt withholds: the four tokens of the tie, that the reading
is written as a substitution for the signal's variable, that a derived
expression goes where a variable's name would, that the instance needs a
name so its formula can be reached, and the keyword that registers the
check.

The honest caveat, in two parts. First, the prompt leans on the reader
knowing what "implements" means for behaviours, and a reader who has met
refinement before will recall the shape from the smell of the domain
rather than retrieve it. Second, time. Two modules, the mapping line, a
named definition and a two-line config is more typing than the other
items in this family. I'd put it at 10 to 12 minutes for someone who has
the syntax, and past 15 for someone reconstructing it. The earlier
version of this item showed both modules and asked for the mapping line
alone. This one asks for everything, and I think the retrieval is worth
the extra minutes, but it's the item in the family most likely to run
long.
