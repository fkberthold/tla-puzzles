# ANSWER: completion/temporal/01-roster

## The two claims

```tla
Answered == \A s \in Site : (s \in asked) ~> (holder = s)

OnRequest == [][holder' # holder => holder' \in asked]_vars
```

## Why claim 1 holds on the real roster

Once `s` is in `asked`, nothing takes it out except `Grant(s)`, and `Grant(t)`
for another site removes `t` only. So `Grant(s)` stays enabled from the
moment `s` asks until it fires. `Ask(s)` needs `s # holder`, so a site in
`asked` is never the current holder, which makes every `Grant(s)` step a real
step rather than a stuttering one. `WF_vars(Grant(s))` then has to fire it,
and firing it sets `holder = s`.

The last part is the bit worth holding onto. Weak fairness says nothing about
an action that changes nothing, so the argument needs `s # holder` as much as
it needs the fairness conjunct.

## Why claim 2 holds on the real roster

`Grant(s)` is the only action that writes `holder`, and its guard is
`s \in asked`. `Ask` leaves `holder` alone.

## Accepted variants

For claim 1, `\A s \in Site : []((s \in asked) => <>(holder = s))` is the
same statement, since that is what `~>` abbreviates.

For claim 2, the subscript may be spelled out as
`[][holder' # holder => holder' \in asked]_<<holder, asked>>`, which is what
`vars` is. `[][holder' \in asked \/ holder' = holder]_vars` is the same
formula with the implication rewritten as a disjunction.

What does not count is a claim over the state alone. `holder \notin asked` is
true of the real roster and true of both broken ones, so it scores 0, 13, 0.

## What each machine measures

`Site = {s1, s2, s3}` throughout. Taken from each machine's `.cfg`.

| machine | reference answer | both `TRUE` | claim 1 only | claim 2 only | unfilled |
|---|---|---|---|---|---|
| `Roster` | 0, 12 distinct | 0 | 0 | 0 | 150 |
| `Stall` | 13 | 0 | 13 | 0 | 150 |
| `Askew` | 13 | 0 | 0 | 13 | 150 |

Five distinct signatures, so the three codes separate every half-right answer
from the full one.

`Stall` is the machine that makes claim 1 necessary. It is the real roster
with the fairness conjunct taken off `Spec`, so claim 2 still holds on it and
only claim 1 can fire.

`Askew` is the machine that makes claim 2 necessary, and it is the more
interesting of the two. It keeps `asked` and checks only that the list is not
empty before handing the baton on, so the baton lands on sites that never
asked. Claim 1 survives that: while `s` is in `asked` the list is not empty,
so `Hand(s)` is continuously enabled and weak fairness fires it. I measured
that rather than reasoning my way to it, because the argument is thin enough
that I would not want to bet on it.

`Askew` needs three sites to fail. With `Site = {s1, s2}` the only hand-over
that goes to a site not on the list is one that leaves `holder` where it was,
and claim 2 says nothing about those. Measured: `Askew` under
`CONSTANT Site = {s1, s2}` and a relaxed `Cardinality(Site) > 1` returns 0.
That is why the ASSUME in `Claims.tla` reads `> 2`.

## Where the module comes from

`reading/temporal/01-handover` is the sibling, and `Askew` is very nearly its
machine. Handover's `Grant` moves the baton to any other site when `want` is
set, which is exactly what `Askew` does once `want` becomes a set of names.
So the broken machine here is the one the reading page teaches, and what
breaks it is that a flag cannot say who asked.

That matters for the second claim. Handover publishes
`MovesOnlyWhenAsked == [][holder' # holder => want]_vars`, and the nearest
port of it is `[][holder' # holder => asked # {}]_vars`. Measured, that port
returns 0, 13, 0: it passes `Askew`, where the reference answer returns 13.
So the page gives the shape of claim 2 and gets the content wrong, which is
what we wanted out of varying the module rather than reusing it.
