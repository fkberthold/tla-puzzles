# META

- **shape**: two missing temporal properties in a given machine, checked against one correct machine and two broken ones
- **TLA+ in the prompt**: the whole machine, minus the two claim bodies
- **time**: 15 to 25 minutes
- **verify**: `bash completion/verify-item.sh completion/temporal/01-roster`
- **reading sibling**: `reading/temporal/01-handover`, varied

## What changed from the reading sibling, and why the page is a hint

Handover tracks whether anybody wants the baton in a `BOOLEAN` called `want`,
and its `Grant` moves the baton to any other site. Here `want` becomes
`asked`, a set of names, `Grant` can only hand the baton to a site that is in
it, and the fairness conjunct moves from one `Grant` action onto the subaction
`Grant(s)`. That one change to the state is what makes a new fact statable:
the baton goes to the site that asked, and not merely to somebody while
somebody was asking.

The page is a hint rather than a key because of the same change. Handover
publishes `MovesOnlyWhenAsked == [][holder' # holder => want]_vars`, and the
nearest port of it is `[][holder' # holder => asked # {}]_vars`. That port
passes `Askew`, where the reference answer fails it, so it scores 0, 13, 0
and the grader rejects it. The learner gets the box-action shape off the page
and still has to work out whose name has to be on the list. `Served == want
~> ~want` hands over `~>` for claim 1 the same way, and the quantifier and
the target state are still theirs to write.

## Constructs

One per bullet, named as `drill/INVENTORY.md` field 4 writes them. These are
what the two claim bodies and their accepted variants use.

- `~> (leads-to)`
- `[P]_x (box action formula)`
- `' (prime, next-state value)`
- `Implication`
- `\A (universal quantifier, "forall")`
- `[] (always)`
- `<> (eventually)`
- `vars (the all-variables tuple)`

## Roles

| id | construct | role |
|---|---|---|
| K070 | `~> (leads-to)` | claim 1, absent from the shown code |
| K080 | `[P]_x (box action formula)` | claim 2, and shown in `Spec` |
| K079 | `' (prime, next-state value)` | claim 2, and shown in every action |
| K009 | `Implication` | claim 2, absent from the shown code |
| K037 | `\A (universal quantifier, "forall")` | claim 1, and shown in the fairness conjunct |
| K063 | `[] (always)` | variant of claim 1, and shown in `Spec` |
| K067 | `<> (eventually)` | variant of claim 1, absent from the shown code |
| K082 | `vars (the all-variables tuple)` | claim 2's subscript, given in `Claims.tla` |

## Where the no-telegraph rule does not reach, and what carries the hole instead

Three of claim 2's four constructs are in the shown code, and they cannot be
taken out of it. `Spec == Init /\ [][Next]_vars /\ ...` is the spec skeleton,
so `[]`, `[P]_x` and `vars` are all on the page before the learner writes a
character, and the actions are full of primes. A temporal item cannot hide
any of that, which is the same finding the reference recorded about K013 and
`\subseteq`, arriving from a different direction. There the shown operator was
avoidable and got replaced. Here it is structural.

What is not shown is the implication, and I think that is where the hole
actually lives. Claim 2's content is the relation between `holder'` and
`asked`, and no shown line relates those two at all. Claim 1 is cleaner:
`~>` appears nowhere the learner can see.

So a gate checking this rule per INVENTORY row will flag claim 2 on three
rows. One of them, K009, is a real absence. The other two are the price of
the family.

telegraph-waiver: [] -- Spec is Init /\ [][Next]_vars and every one of the 27
machines in the corpus carries that skeleton, so the box cannot be hidden by
any item; what this hole withholds is the implication.

telegraph-waiver: ]_ -- the same skeleton and the same count: the box-action
subscript is on the page before the learner writes a character.
