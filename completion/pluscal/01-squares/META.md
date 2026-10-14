# META

- **shape**: two missing invariants in a given PlusCal machine, checked against one correct machine and two broken ones
- **TLA+ in the prompt**: the whole machine, algorithm and committed translation, minus the two claim bodies
- **time**: 10 to 20 minutes
- **verify**: `bash completion/verify-item.sh completion/pluscal/01-squares`
- **reading sibling**: `reading/pluscal/01-euclid`, varied rather than reused

## The structure, and why it is not the reference's

The reference item has each machine `EXTENDS Claims`, with `Claims.tla` declaring
the variables. A PlusCal machine looks like it cannot do that, because `pcal`
writes a `VARIABLES` line into the module it translates and those are the same
names `Claims.tla` declares. Both ways were measured on TLC 2026.07.31.184830,
and the first result was not what I expected.

`EXTENDS Claims` with the duplicate declaration **runs**. SANY reports four
warnings rather than an error, "Multiple declarations or definitions for symbol
pc", and both occurrences resolve to the declaration in `Claims`. The run is
correct: 66 distinct states, and the coverage report shows the claim evaluated at
all 66 of them. So the collision the brief predicted is not a collision on this
build.

This item instantiates anyway, and that is the one change from the reference.
`Claims.tla` declares the four names, each machine ends with `C == INSTANCE
Claims` and no `WITH` clause, and implicit binding ties each parameter to the
machine's own variable of the same spelling. Zero warnings, and the same 66
states.

I went with the instance for two reasons. A learner running `tlc` by hand would
otherwise get four warnings naming the file they just edited, which reads as
their own mistake. And which declaration SANY resolves a duplicate to is not
something I would want a correctness gate resting on. If a later SANY resolved to
the local declaration while `Claims` kept its own, the claims would be checked
over unconstrained variables, and the failure direction there is a false pass.

`completion/verify-item.sh` drives this unchanged, and needs no edit. It reads
`EXPECT`, runs `harness/verdict.sh` once per stem, and has no opinion about how a
machine reaches its claims. `scripts/deliver-completion.sh` needs no edit either,
since everything new sits under `work/`.

The cost is four lines per machine: the instance, plus one alias per claim name,
because a `.cfg` names an unqualified operator.

## What changed from the reading sibling, and why the page is a hint

`01-euclid` is the nearest model. One process, one label, a `while` loop driving a
pair of numbers to an answer, an invariant the body preserves, and a terminal
claim about the answer. This item keeps that skeleton and changes three things.

The input arrives as `\in` on a variable declaration rather than as two
`CONSTANTS`, so one run covers 16 inputs instead of one pair. The loop grows
rather than reduces, and its invariant is an arithmetic identity the reader has to
pull out of `s := s + 2 * r + 3`, where euclid hands `Divisors` and `Common` over
as named operators. And the fairness comes from `--fair algorithm`, where
euclid's comes from `pcal`'s `-termination` flag, which is the thing euclid's page
spends a paragraph on.

`Preserved` and `Greatest` give a reader nothing here. Neither mentions anything
like a square, and `Divisors` has no counterpart.

What the page does hand over is the `(pc = "Done") => ...` shape for a terminal
claim. That is not worth hiding, and I do not think it can be hidden: `pcal`
writes `Terminating == pc = "Done" /\ UNCHANGED vars` into every translation that
can finish.

telegraph-waiver: pc -- pcal writes Terminating == pc = "Done" into every
translation that can finish, so claim 2's guard is in all three machines by
construction and only its body is withheld. So claim 2's guard sits in the shown code of all three machines by
construction, and the item's substance is the body rather than the shape. That is
a standing limit on the no-telegraph rule for this whole family, not a defect in
this item.

## Constructs

One per bullet, named as `drill/INVENTORY.md` field 4 writes them.

- `--algorithm block`
- `label`
- `while`
- `:= assignment`
- `\in on a variable declaration`
- `pc (PlusCal's label-tracking variable)`
- `Terminating`
- `label-as-action encoding`
- `Implication`
- `Equality and inequality`

## Roles

| id | construct | role |
|---|---|---|
| K022 | `--algorithm block` | shown, all three machines |
| K024 | `label` | shown, the one label `grow` |
| K032 | `while` | shown, and `Over` differs only in its guard |
| K023 | `:= assignment` | shown, and `Stall` differs only by dropping one |
| K033 | `\in on a variable declaration` | shown, `n \in 0..15` |
| K036 | `pc` | claim 2's guard, and shown in the translation |
| K092 | `Terminating` | shown, and why that guard cannot be hidden |
| K090 | `label-as-action encoding` | shown |
| K009 | `Implication` | claim 2, absent from the shown code |
| K003 | `Equality and inequality` | both claims, and shown throughout |

`INSTANCE`, a named instance and `!` are all in the shown code too, in the four
glue lines at the bottom of each machine. They are apparatus rather than subject,
so they are not claimed above. `completion/modules/01-tiles` is where they are
the subject.

## Notes for whoever writes item 02 in this family

Every machine's committed translation round-trips. Re-running
`pcal -lineWidth 60 -nocfg` over each of the three leaves the file byte-identical,
which is the only reason the hand-written glue below `END TRANSLATION` is safe to
keep there.

Delete the `.old` files before you call the item done. `pcal` writes a
`<Module>.old` backup beside each module it rewrites, and
`scripts/deliver-completion.sh` delivers everything under `work/` recursively,
including a file added tomorrow. So a translation run inside `work/` leaves three
backups that the next delivery hands to the learner. The `--check` run is what
caught it here, which is a good reason to run `--check` on a pluscal item rather
than trusting the file list you think you wrote.

`--fair algorithm` is what puts `WF_vars(Next)` on `Spec`, and no `-termination`
flag is passed. `01-euclid` gets the same conjunct the other way round, from the
flag with no keyword, and its page has the three-way measurement.

A terminal claim is the natural second hole for a terminating algorithm, and the
`pc = "Done"` leak above comes with it. If that leak ever needs closing, guarding
on the loop's own exit test works instead: `(s > n) => (r * r <= n)` was measured
and scores the reference signature.
