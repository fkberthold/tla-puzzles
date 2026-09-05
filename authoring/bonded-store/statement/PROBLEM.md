# The bonded store

Some goods carry a tax called duty. Spirits, tobacco and fuel are the usual
ones. A bonded store is a place the revenue authority has approved, where
such goods can sit with the duty not yet paid. That suspension is what
"under bond" means. You have the model of one store, finished and working.
What it doesn't have is properties. Nothing in it says what must be true.
Your job is to say it, in TLA+, and check it.

You don't need to know any customs law. Every rule the store follows is
stated below.

## What you get

- `BondedStore.tla`: the model. The constant, the algorithm, the
  translation, and `Observe`.
- `traces/`: pairs of runs. In each pair, one run follows the rules and one
  breaks them.

## Your task

Write three properties over `Observe`, in `BondedStore.tla`, and a `.cfg`
that declares them. The requirements below name all three. Each one tells
you the TLC keyword to declare it under, what kind of formula it is, and
what to subscript it over where that applies. The formula itself is yours.

1. Read the module. Work out how it carries the nouns the rules use.
2. Write each requirement as a formula over `Observe`.
3. Declare each one under the keyword its requirement names.
4. Run TLC. The model must satisfy all three.
5. Hold your three against the traces. Every forbidden run must break at
   least one. Every allowed run must break none.

## The system

**The parties.** One. The **keeper** runs the store, and every step in this
system is his. Nothing else acts. There's no clock, no calendar, and no
event that happens on its own.

### Rule 1: lots

Goods move as lots. The set of lots is fixed and finite, named up front. A
lot is whole. It's never split, never merged with another, and never
renamed. At any moment exactly one of these is true of a lot. It hasn't
been entered yet, or it's in the store under bond, or it's been released
for home consumption, or it's been moved on under bond. Every lot starts
not yet entered.

### Rule 2: entry

The keeper enters a lot into the store. Entry applies to a lot not yet
entered, and to no other. Goods don't arrive on their own, and no lot
enters unless the keeper enters it. On entry the lot is under bond and the
duty on it is unpaid.

### Rule 3: release for home consumption

The keeper can release a lot that's in the store. Release is the duty
point. The duty on that lot is paid in the same motion, and the lot leaves
the store. There's no way to pay the duty on a lot and keep it in the
store, and no way to release a lot without paying.

### Rule 4: movement under bond

The keeper can move a lot that's in the store on to another approved store.
The lot leaves and the duty stays unpaid, because the bond carries on at
the receiving store. The receiving store is outside this system. Nothing
about it is modeled, nobody there acts, and a lot moved on is simply gone.

### Rule 5: two ways out, and no way back

Release and movement under bond are the only ways a lot leaves the store.
There's no loss, no breakage, no write-off, and no way to take a lot back
off the store's account. Once a lot is out it stays out. It never returns
to the store, and its duty never changes again. Duty once paid stays paid.

### Rule 6: nothing has to happen

The keeper acts when he chooses and never on a deadline. He can leave a lot
outside forever, and he can leave a lot in the store forever. Nothing in
this system must eventually happen.

## The interface

`BondedStore.tla` defines `Observe`, and `Observe` is the store's whole
public face:

- **place**: for each lot, which of rule 1's four holds of it right now.
- **dutyPaid**: for each lot, whether the duty on it has been paid.

The module has its own name for each of the four. Read it to find out what
it calls them, and which field carries which of the rules' nouns.

State every property over `Observe`. Grading reads `Observe` and nothing
else.

## The requirements

Three of them. Each one says which keyword to declare it under and what
kind of formula it is. Write the formula yourself.

### Requirement 1: duty is paid exactly on release

A lot's duty is paid exactly when that lot has been released for home
consumption. A lot not yet entered, a lot in the store, and a lot moved on
under bond all have their duty unpaid.

This is a claim about a single state, so write it as a state predicate.
Declare it under `INVARIANT`.

### Requirement 2: the way in, and the two ways out

Two arms, and one property carries both.

- When a lot that hasn't been entered yet moves, it moves into the store
  under bond.
- When a lot in the store moves, it moves to released for home
  consumption, or to moved on under bond.

Both arms compare a lot at two consecutive moments, so this is an action
property. Write it in the form `[][A]_Observe` and declare it under
`PROPERTY`.

Subscript it over the whole of `Observe`, never over one of its fields. A
step rule watched over a single field is satisfied for free by any step
that changes only the other field. TLC won't warn you. The property just
stops seeing the steps it was written about.

### Requirement 3: out stays out

Once a lot is out of the store, released or moved on, where it stands never
changes again and its duty never changes again.

This compares two consecutive moments too, so it's an action property.
Write it in the form `[][A]_Observe` and declare it under `PROPERTY`. The
same warning about the subscript applies.

Nothing here needs "eventually". None of the three is a liveness property,
and `Spec` carries no fairness conjunct for you to add.

## The traces

Five pairs under `traces/` witness the requirements. Each state shows the
two `Observe` fields. Four notes:

- A forbidden run can break more than one requirement. If your set rejects
  it for any requirement it breaks, your set is right about that run.
- Requirement 1 reads in two directions, so it gets two pairs. One
  forbidden run breaks each direction.
- Requirement 2 has two arms, so it gets two pairs. One forbidden run
  breaks each arm.
- The allowed runs are behaviors of `BondedStore.tla`. The forbidden runs
  are not. They exist to pin down what your properties must reject.

## Checking

Use the instance the traces use:

```
Lots = {l1, l2, l3}
```

Your `.cfg` declares `SPECIFICATION Spec`, the constant, and your three
properties under the keywords the requirements name.

Turn deadlock checking off. Put `CHECK_DEADLOCK FALSE` in your `.cfg`, or
pass TLC the `-deadlock` flag, which despite its name turns the check off.
When every lot has left the store, no action is enabled and the run stops.
That's the story ending, not a fault.

Whatever properties you declare, the run should find 64 distinct states. A
different count means the system half of the module changed, and that half
isn't yours to change.
