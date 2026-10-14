# Answer: two tanks, one hose

Files in `verify/`. `HeaderTank.tla` is the shared tank. `TankPair.tla`
is the pair. `TankPairAnon.tla` and `TankPairAnonInit.tla` are the two
anonymous-copy neighbours, and `TankPairNoVar.tla` is the one that
substitutes the capacity and forgets the level.

Every number from `harness/verdict.sh` on TLC2 Version
2026.07.31.184830.

## Question 1: the tank, the pair, the config

```
---- MODULE HeaderTank ----
EXTENDS Naturals

CONSTANT Cap

VARIABLE level

Init == level = 0

Fill == level < Cap /\ level' = level + 1

Drain == level > 0 /\ level' = 0

Next == Fill \/ Drain

Spec == Init /\ [][Next]_level

WithinCap == level <= Cap
====
```

```
---- MODULE TankPair ----
EXTENDS Naturals

CONSTANTS CapA, CapB

VARIABLES a, b

A == INSTANCE HeaderTank WITH Cap <- CapA, level <- a
B == INSTANCE HeaderTank WITH Cap <- CapB, level <- b

Init == A!Init /\ B!Init

Next ==
    \/ A!Next /\ UNCHANGED b
    \/ B!Next /\ UNCHANGED a

Spec == Init /\ [][Next]_<<a, b>>

WithinCap == A!WithinCap /\ B!WithinCap
====
```

`Pair.cfg` sets `CapA = 2`, `CapB = 3` and names `WithinCap`.

Each copy carries a name, and each substitution clause accounts for both
of the symbols the tank declares. The capacity is a constant and the
level is a variable, and the same arrow does both. Nothing marks one as
different from the other.

The names are what keeps the copies apart. `A!Init` and `B!Init` are two
formulas over two variables, both built from the one `Init` the tank
defines, and neither of them is called `Init`.

One hose is the `UNCHANGED` on the idle tank. `A!Next` constrains `a` and
says nothing about `b`, so a step has to pin the other tank or TLC is
left with a variable it cannot value.

## Question 2: the names that arrived twice

A copy with no name puts every definition of the tank straight into the
pair. Two of them put `Init`, `Fill`, `Drain`, `Next`, `Spec` and
`WithinCap` in twice, and SANY warns six times, once per name:

```
line 11, col 1 to line 11, col 48 of module TankPairAnon

Multiple declarations or definitions for symbol Init.
This duplicates the one at line 10, col 1 to line 10, col 48 of module TankPairAnon.
```

Both line numbers are the two instance lines. The message names the
collision and leaves you to work out which definition survived.

Row four adds a seventh, and that one is an error rather than a warning,
because the pair writes a `Spec` of its own:

```
Semantic errors:

*** Errors: 1

line 13, col 1 to line 13, col 33 of module TankPairAnon

Operator Spec already defined or declared.
```

That's the whole difference between rows four and five. A duplicate
between two copies is a warning. A duplicate between a copy and the
module's own definition is an error, and nothing runs.

Naming each copy fixes it because `A!Init` is not `Init`. Nothing lands
at the pair's top level, so the pair is free to define `Init`, `Next`,
`Spec` and `WithinCap` itself.

Row five got as far as a state because it defines nothing of its own, so
no name collides at error level. SANY reports six warnings and prints no
errors block, so TLC runs.

What it runs is the first of each pair of duplicate definitions, which
for `Init` is the first copy's, constraining `a` and saying nothing about
`b`:

```
Error: current state is not a legal state
While working on the initial state:
/\ a = 0
/\ b = null
```

I'm reading the surviving definition off that state rather than off any
documentation, so take "the first one wins" as what these two runs show.
`null` is TLC's report of a variable the initial predicate never
constrained. It isn't a value the spec can produce.

## Question 3: the level that was never substituted

The tank declares one constant and one variable, and a copy has to
account for both. A symbol the instantiating module declares under the
same name passes through on its own. The pair declares `a` and `b`
rather than `level`, so `level` has nowhere to go:

```
*** Errors: 2

line 10, col 1 to line 10, col 41 of module TankPairNoVar

Substitution missing for symbol level declared at line 6, col 10 to line 6, col 14 of module HeaderTank
and instantiated in module TankPairNoVar.
```

Two errors, one per instance line. The parser catches this one, so it
never reaches a state.

## Question 4: the 12 and the 9 from the 3

One tank of capacity 2 holds 0, 1 or 2. Three states, and depth 3 is the
two fills from empty plus the initial state.

The pair is the full cross product, because one tank moves while the
other holds still. Capacities 2 and 3 give 3 levels times 4 levels, which
is 12. The deepest state is both tanks full, five fills from empty, so
depth 6. Capacities 2 and 2 give 3 times 3, which is 9, and four fills,
so depth 5.

Every combination is reachable. `Drain` goes to empty from any level and
`Fill` adds one, so each tank's level walks its own range whatever the
other is doing.

## Variants worth running

Drop the `UNCHANGED` and change nothing else. I measured this in a
scratch tree rather than adding it to the item: rc 75, and the message
names both the action and the variable it was left holding.

```
Error: Successor state is not completely specified by action A!Next of the
next-state relation. The following variable is not defined: b.
```

State the requirement from the pair instead, as `a <= CapA /\ b <= CapB`.
Same 12 states, and it reads fine. It also restates the tank's rule in
the pair, which is the one thing the prompt asked you not to do, and
nothing in the run says so. I think that's the quiet failure of this
item, and it's the only one. All three of the wrong neighbours the prompt
asks for are loud.

Name one copy and leave the other anonymous. The named one is reachable
behind its prefix and the anonymous one lands at the top level, so the
pair may then define nothing the tank defines. I haven't run it.

## The whole table

The three clean rows have a bare config in `verify/`. The three refusals
are reached through the wrapper's copy of the config, since they were
never worth a second file.

| config | model | rc | distinct | depth |
|---|---|---|---|---|
| `Alone.cfg` | one tank alone, capacity 2 | 0 | 3 | 3 |
| `Pair.cfg` | the pair, capacities 2 and 3 | 0 | 12 | 6 |
| `Equal.cfg` | the pair, capacities 2 and 2 | 0 | 9 | 5 |
| `G01Anon.cfg` | both copies unnamed, the pair writing its own behaviour formula | 150 | | |
| `G01AnonInit.cfg` | both copies unnamed, the pair writing nothing of its own | 255 | | |
| `G01NoVar.cfg` | both copies named, the capacity substituted and the level not | 150 | | |

## Gate rows

One thin wrapper module per run the drill gate reproduces, each with a
copy of the config it stands for. The rc is what `harness/verdict.sh`
returns.

| module | rc | distinct | stands for |
|---|---|---|---|
| `G01Alone.tla` | rc 0 | 3 | `Alone.cfg`, one tank alone, 3 states |
| `G01Pair.tla` | rc 0 | 12 | `Pair.cfg`, the answer, 12 states |
| `G01Equal.tla` | rc 0 | 9 | `Equal.cfg`, equal capacities, 9 states |
| `G01Anon.tla` | rc 150 | - | the pair's own behaviour formula already defined |
| `G01AnonInit.tla` | rc 255 | - | one level never constrained, reported as null |
| `G01NoVar.tla` | rc 150 | - | the level never substituted |

## why-not-in-prompt

The prompt says the tank module is shared and that nothing in it may know
about any particular pair. That's the reason each copy has to be told its
capacity and its variable. It says "nothing about a tank is written
twice". The table gives three verdicts in English: a definition already
there, a level reported as null, and something declared but never
substituted.

What the prompt withholds: the keyword that brings a module in, that a
copy can be given a name, the arrow that substitutes a symbol, that a
variable takes the same arrow as a constant, and the prefix that reaches
a named copy's definitions.

The honest caveat, in two parts. The table's fourth row says "a
definition the pair wrote was already there", which is most of the
diagnosis, and a reader who has met unnamed copies before will go
straight to naming them. And the `UNCHANGED` is scenery here rather than
the subject. It's load-bearing for the 12, so a reader who leaves it out
gets a refusal that has nothing to do with the item. I'd expect that on
the first run and I wouldn't read it as the drill failing.
