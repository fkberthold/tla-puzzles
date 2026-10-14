# Port rules: answer

## The answer

```tla
---- MODULE PortsAnswer ----
EXTENDS Naturals, FiniteSets

CONSTANTS Lo, Hi, Mgmt, MaxRules

Allowed == Lo..Hi
Typed == (Lo - 1)..(Hi + 1)

VARIABLES rules, maint

vars == <<rules, maint>>

Covered(r) == r[1]..r[2]

Open == UNION {Covered(r) : r \in rules}

TypeOK ==
  /\ rules \subseteq Typed \X Typed
  /\ maint \in BOOLEAN

Init == rules = {} /\ maint = FALSE

Add ==
  /\ ~maint
  /\ Cardinality(rules) < MaxRules
  /\ \E a, b \in Typed :
       /\ a <= b
       /\ a..b \subseteq Allowed
       /\ Mgmt \notin a..b
       /\ rules' = rules \cup {<<a, b>>}
  /\ UNCHANGED maint

Remove ==
  /\ \E r \in rules : rules' = rules \ {r}
  /\ UNCHANGED maint

Toggle == maint' = ~maint /\ UNCHANGED rules

Next == Add \/ Remove \/ Toggle

Spec == Init /\ [][Next]_vars

ManagementClosed == Mgmt \notin Open

WithinAllowed == Open \subseteq Allowed
====
```

```
SPECIFICATION Spec
CONSTANTS
  Lo = 1
  Hi = 8
  Mgmt = 5
  MaxRules = 2
INVARIANTS
  TypeOK
  ManagementClosed
  WithinAllowed
```

A rule is a pair of ports and its reach is the interval between them. The
open ports are every interval flattened into one set, and that line is the
item: a map builds the set of intervals, and the big union flattens it.
Without the flattening `Open` is a set of sets and neither rule can be
asked of it, which TLC says out loud, measured below. The switch is a
Boolean, and `BOOLEAN` is the set it's drawn from in `TypeOK`.

## Measured

Every run from `bash drill/sets/verify-item.sh drill/sets/06-port-rules`
on TLC2 Version 2026.07.31.184830, `-workers 1`. Each module has a config
of its own name. The rc is what `harness/verdict.sh` returned.

| module | rc | distinct | what it is |
|---|---|---|---|
| `PortsAnswer` | rc 0 | 274 | the answer |
| `PortsNoBand` | rc 12 | 2 | `Add` without the band check. Rule 2 names it |
| `PortsNoMgmtGuard` | rc 12 | 12 | `Add` without the management check. Rule 1 names it |
| `PortsFlat` | rc 75 | 3 | `Open` unflattened, both rules in the config |
| `PortsFlatMgmt` | rc 75 | 3 | `Open` unflattened on the broken model, rule 1 only |

The 274 is 137 arrangements of rules, twice over for the switch. There
are 16 ranges that avoid port 5 and stay inside 1 to 8, so the list holds
nothing, one of 16, or one of 120 pairs of them.

## The unflattened set

I expected `PortsFlatMgmt` to run clean. `Mgmt \notin Open` with `Open` a
set of intervals asks whether 5 is one of the intervals, and it isn't, so
I read it as a rule that could never fire. TLC doesn't evaluate it that
way. It compares 5 against an interval, refuses to compare an integer with
a set, and stops at rc 75 on the first state that holds a rule. So the
missing flattening is loud on this build, in both configs, and it's loud
for a reason the reader has to go and read in the log. I'd still call it
the trap, since a reader who skips the log sees a crash and not a reason.

## Elimination table

| wrong neighbour | what kills it | rc |
|---|---|---|
| band check dropped from `Add` | rule 2, a rule reaching port 0 or 9 | 12 |
| management check dropped from `Add` | rule 1, a rule spanning port 5 | 12 |
| `Open` as the set of intervals | TLC refuses to compare a port with an interval | 75 |
| `maint` checked in `Remove` as well | passes, fewer states, and the prompt says removal is allowed |
| `Cardinality(rules) <= MaxRules` as the guard | passes with three rules in the list, and `TypeOK` doesn't see it |

The last row is the one I'd flag in review. The prompt bounds the list at
two and nothing in the three named checks says so, so a guard that's off
by one passes clean. A fourth name, `rules` has at most two members, is
the fix, and I left it out of the answer so the reader can decide whether
"never holds more than two" is a requirement or a description.

## Variants

- `maint \in {TRUE, FALSE}` in `TypeOK`
- a predicate `IsOpen(p) == \E r \in rules : p \in Covered(r)` and no `Open` set at all
- rule 2 as `\A p \in Open : p \in Allowed`
- the typed range as a constant, with the pairs enumerated in the config

The predicate variant avoids the flattening entirely, since it never
builds the set. Rule 2 then reads `\A p \in Typed : IsOpen(p) => p \in
Allowed`. I'd accept it, and I'd point out that it quantifies over the
typed range to say what the set form says of itself.

## Why not in prompt

"A port is open when any rule covers it" is the flattening in prose, and
the reader has to find the operator that turns a set of intervals into a
set of ports. The prompt withholds the word "union" so neither spelling
can be read off the page. The interval is withheld the same way: "the
lowest and highest port" has to become the two-dot range.

The honest caveat: the item's trap is a loud crash rather than a quiet
pass, measured above, so a reader who leaves out the flattening gets told
within one state. What the item drills is retrieval, not diagnosis, and I
think that's fine for this family. The quieter risk is the one in the
elimination table, a list bound that no named check covers, and the
prompt's count is the only thing that catches it.
