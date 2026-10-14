# Answer: the bank that vouched

Files in `verify/`. `LockerBank.tla` is the library. `PostOffice.tla` is
the client as described. `PostOfficeGuarded.tla` adds the one line from
question 4. `PostOfficePass.tla` is row five, with the size passed
through by name instead of computed.

Every number from `harness/verdict.sh` on TLC2 Version
2026.07.31.184830.

## Question 1: the bank and the office

```
---- MODULE LockerBank ----
EXTENDS Naturals
CONSTANT N

ASSUME N >= 1

VARIABLE used

Init == used = 0
Deposit == used < N /\ used' = used + 1
Collect == used > 0 /\ used' = used - 1
Next == Deposit \/ Collect
Spec == Init /\ [][Next]_used

NeverOver == used <= N
====
```

```
---- MODULE PostOffice ----
EXTENDS Naturals
CONSTANTS Lockers, Reserved
VARIABLES occupied, open

B == INSTANCE LockerBank WITH N <- Lockers - Reserved, used <- occupied

Init == B!Init /\ open = FALSE
Shutter == open' = ~open /\ UNCHANGED occupied
Next ==
    \/ B!Next /\ UNCHANGED open
    \/ Shutter
Spec == Init /\ [][Next]_<<occupied, open>>

NeverOver == B!NeverOver
====
```

`Office.cfg` sets `Lockers = 4`, `Reserved = 1` and names `NeverOver`.
That's 4 counts times 2 shutter positions, 8 states.

## Question 2: where the refusal went

The bank's refusal is `ASSUME N >= 1`. TLC checks an assumption once,
before the first state, and exits 10 when it's false. Row two is that
line firing, and the message names it:

```
Error: Assumption line 7, col 8 to line 7, col 13 of module LockerBank is false.
```

Row four hands the bank `N <- 2 - 2`, and nothing fires. On this build
TLC does not check the assumptions of a module that was brought in by
instantiation. It checks those of the root module and of modules the
root extends. So the office took the guard away by writing `INSTANCE`
where `EXTENDS` would have carried it, and the run is clean at 2 states:
one count, two shutter positions, no deposit ever enabled.

That's the thing to remember. A guard you wrote in a library protects
every spec that extends the library and no spec that instantiates it. I
haven't found this written down in the TLC documentation, so treat the
general rule as my reading of these runs rather than as doctrine, and
treat the runs as fact.

`EXTENDS` would have kept it, with the cost that the office's own
constants would then have to be the bank's. For a library with one user
that's often the right call. For one with two, it isn't.

## Question 3: row five rules out the arithmetic

`PostOfficePass.tla` declares its own `N`, lets it pass through the
instance by name, and takes `N = 0` from the config. Still clean, still 2
states. So the subtraction in row four isn't what lost the guard. The
instance is.

## Question 4: the line

```
ASSUME Lockers - Reserved >= 1
```

In the office, about the value the office passes. With it, row four is
refused:

```
Error: Assumption line 7, col 8 to line 7, col 30 of module PostOfficeGuarded is false.
```

It has to be about the office's own constants, since those are what the
config sets. Restating the bank's guard in the bank's terms isn't
possible from the office, because `N` isn't a name the office has.

## Variants worth running

Set `Reserved` larger than `Lockers`. The difference goes negative, the
bank's `Deposit` is never enabled, and the office is still clean. The
guard in question 4 catches that too.

Give the bank a second constant with its own assumption and watch the
same thing happen to it. One line per guard, each one restated by each
client, is the price of a library with assumptions.

## The whole table

| config | module run | rc | distinct | depth |
|---|---|---|---|---|
| `Bank.cfg` | the bank alone, 3 lockers | 0 | 4 | 4 |
| `BankZero.cfg` | the bank alone, 0 lockers | 10 | | |
| `Office.cfg` | the office, 4 with 1 kept back | 0 | 8 | 5 |
| `OfficeZero.cfg` | the office, 2 with 2 kept back | **0** | 2 | 2 |
| `Pass.cfg` | the size passed through by name, 0 | **0** | 2 | 2 |
| `OfficeZero.cfg` | the office with the guard restated | 10 | | |

The two bold zeros are the item. Same library, same value, same guard,
and the guard is silent.

## Gate rows

One thin wrapper module per run the drill gate reproduces, each with a
copy of the config it stands for. The rc is what `harness/verdict.sh`
returns.

| module | rc | stands for |
|---|---|---|
| `G03Bank.tla` | rc 0 | `Bank.cfg`, the library alone with 3 lockers |
| `G03BankZero.tla` | rc 10 | `BankZero.cfg`, the library alone refusing 0 |
| `G03Office.tla` | rc 0 | `Office.cfg`, the answer, 8 states |
| `G03OfficeZero.tla` | rc 0 | `OfficeZero.cfg`, the guard silent through the instance |
| `G03Pass.tla` | rc 0 | `Pass.cfg`, the guard silent with the constant passed through |
| `G03Guarded.tla` | rc 10 | `OfficeZero.cfg` against the office with its own guard |

## why-not-in-prompt

The prompt says "the one way a module can refuse a value before the
first state" and gives exit 10 in the table, so the reader knows a guard
exists and knows the mechanism in words. It says "which of the two ways
of bringing a module in", so the reader knows there are two.

What the prompt withholds: the keyword for the guard, that instantiation
drops it and extension keeps it, which keyword is which, and that the
fix is the same keyword again in the client about the client's own
numbers.

The honest caveat: question 2 all but says one keyword keeps the guard
and the other loses it, so the retrieval is which is which rather than
whether. The bank and the office themselves are ordinary spec writing
and will take most of the ten minutes. The lesson is a single measured
fact about TLC, and a reader who has it already will finish early.
