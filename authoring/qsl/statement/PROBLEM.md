# The confirmation bureau

Amateur radio operators make two-way contacts over the air. By the hobby's
custom a contact counts between two stations only when both ends confirm it,
and the confirming runs through a bureau. You have the bureau's model,
finished and working. What it doesn't have is properties. Nothing in it says
what must be true. Your job is to say it, in TLA+, and check it.

You don't need to know radio. Every rule the bureau follows is stated below.

## What you get

- `Bureau.tla`: the model. Constants, state, `Init`, the actions, `Spec`.
- `traces/`: pairs of runs. In each pair, one run follows the rules and one
  breaks them.

## Your task

Work out what must be true of this bureau, and write it down:

1. State each property as a TLA+ formula over `Observe`, in `Bureau.tla`.
2. Decide what kind of claim each property makes, and declare it under the
   matching keyword in your `.cfg`. A property declared under the wrong
   kind can pass without checking what you meant it to check.
3. Run TLC. The model must satisfy every property you wrote.
4. Hold your set against the traces. Every forbidden run must break at
   least one of your properties. Every allowed run must break none.

Not everything the rules say can be written over the interface. Part of the
work is deciding which rules your properties can carry.

## The system

**The parties:**

- **operators**: a fixed, finite set of stations. Each logs contacts at
  home, out of the bureau's sight, and mails claims in when they choose.
- **the bureau**: keeper of a claim file per operator and a register of
  credits. It handles one envelope or one credit at a time.

Nothing coordinates the operators. One operator's envelope can land between
any two of another's, and the bureau's own steps interleave with the mail
however they fall. No operator ever owes anyone a mailing. The bureau is
the one party with an obligation (rule 5).

### Rule 1: claims

A claim is one operator's assertion of a two-way contact. It names the
counterpart station and the band the contact was on. Each operator is one
station, and the two words mean the same thing here. The set of bands is
fixed. A claim never names its own sender as counterpart, and the desk
refuses one that tries: you can't work yourself. Real logs carry dates,
times, and signal reports. This register doesn't. The one question it
answers is worked-or-not, per counterpart, per band.

### Rule 2: the files

The bureau keeps a file per operator holding every claim that operator has
sent in. An envelope can carry any number of claims, and it lands as one
step: all of its claims enter that one operator's file together. Files only
grow. Nothing is withdrawn, corrected, or expunged. A claim already on
file, sent in again, changes nothing. The file records that a claim stands,
not how often it arrived.

The station log at home is out of the bureau's sight. The bureau learns
only what's mailed in. An operator can log for years and mail nothing, mail
a claim for a contact that never happened, or botch the counterpart's
callsign. The bureau can't tell, and this system never asks it to.

### Rule 3: corroboration

Two claims corroborate when each names the other on the same band: A's file
holds a claim naming B on band b, and B's file holds one naming A on band
b. Corroborated-on-b is then a fact about the pair, and it's definable from
the files alone.

### Rule 4: credit

The bureau may credit a corroborated fact that it hasn't credited yet. A
credit is one step and one fact, and it lands on both sides at once: A
gains credit for B on b, and B gains credit for A on b, in the same motion.
Credit, once given, is never revoked. A one-sided claim just sits on file,
harmless, until its counterpart arrives or forever.

### Rule 5: the bureau keeps up

The bureau works at its own pace and in any order it likes. What it may not
do is sit on confirmable work forever: a fact that is corroborated on file
and not yet credited must eventually be credited. That's the bureau's
charter.

## The interface

`Bureau.tla` defines `Observe`, and `Observe` is the bureau's whole public
face:

- **filed**: for each operator, the set of claims on their file.
- **credited**: for each operator, the set of counterpart-and-band facts
  they hold credit for.

State every property over `Observe`. Grading reads `Observe` and nothing
else.

One warning about steps. A rule that constrains a step must watch the whole
interface. Subscript a step rule over `Observe` itself, never over one of
its fields. A step rule watched over a single field is satisfied for free
by any step that changes only the other field. TLC won't warn you. The
property just stops seeing the steps it was written about.

## The traces

The runs under `traces/` witness the rules. Each state shows the two
`Observe` fields. A claim or a credit is written `o2 on b1`: station `o2`,
band `b1`.

Three notes:

- A forbidden run can break more than one rule. If your set rejects it for
  any rule it breaks, your set is right about that run.
- Every run shown is finite. Where a forbidden run's fault is that nothing
  more ever happens, the trace says so under its last state.
- The allowed runs are behaviors of `Bureau.tla`. The forbidden runs are
  not. They exist to pin down what your properties must reject.

## Checking

Use the instance the traces use:

```
Operators = {o1, o2, o3}
Bands = {b1, b2}
```

Your `.cfg` declares `SPECIFICATION Spec`, the two constants, and your
properties under the kinds you chose.

Run TLC with deadlock checking off. The flag is `-deadlock`, and despite
its name it turns the check off. The bureau never has to act, so a model
of it should not treat quiet moments as errors, whether or not your
rendering happens to have a step available in every state.

Whatever properties you declare, the run should find 15,625 distinct
states. A different count means the system half of the module changed, and
that half isn't yours to change.
