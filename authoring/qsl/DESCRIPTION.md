# A contact-confirmation bureau

System description for the reference-solution author (V2-PLAN §9.4). It fixes the
system and leaves the representation open (§3.2). It is not the learner-facing
statement, and nothing in it is worded for a learner.

Sections 1 to 4 are the hand-off: paste them into the §9.4 brief as the
`<system description>`. Sections 5 and 6 are pipeline notes for central. Keep them
out of the author's brief and out of anything downstream of it.

Grid cell: task shape B, in a situation of independent records and one shared
registry.

## 1. The system

Amateur radio operators make two-way contacts over the air. By the hobby's custom
a contact counts between two stations only when both ends confirm it, and the
confirming is done through a bureau. Each operator keeps a station log at home
and mails claims in when they feel like it. The bureau keeps a file of claims per
operator and a register of credits, and it issues a credit when the two sides'
claims corroborate. Nothing below depends on knowing radio. Everything the model
needs is stated here.

**The parties.**

- The **operators**, a fixed, finite set. Each logs at home, out of sight, and
  mails claims to the bureau whenever they choose.
- The **bureau**, keeper of the files and the register. It works one envelope or
  one credit at a time.

Nothing coordinates the operators. One operator's envelope can land between any
two of another's, and the bureau's own steps interleave with the mail however
they fall. The operators owe nothing to anyone, ever. The bureau is the one
party with an obligation (Rule 5).

### Rule 1. Claims

A claim is one operator's assertion of a two-way contact. It names the
counterpart station and the band the contact was on. The set of bands is fixed.
A claim never names its own submitter as counterpart, and the desk refuses one
that tries (you can't work yourself). Real logs carry dates, times, modes, and
signal reports. This register doesn't (simplification): the one question it
answers is worked-or-not, per counterpart, per band.

### Rule 2. The files

The bureau keeps a file per operator holding every claim that operator has sent
in. An envelope can carry any number of claims and lands as one step: all of its
claims enter that operator's file together. Files only grow. Nothing is
withdrawn, corrected, or expunged. A claim already on file, sent in again,
changes nothing: the file records that the claim stands, not how often it
arrived.

The station log at home is out of the bureau's sight. The bureau learns only
what's mailed in. An operator can log for years and mail nothing, mail a claim
for a contact that never happened, or botch the counterpart's callsign. The
bureau can't tell, and this system never asks it to.

### Rule 3. Corroboration

Two claims corroborate when each names the other on the same band: A's file
holds a claim naming B on band b, and B's file holds one naming A on band b.
Corroborated-on-b is then a fact about the pair, and it's definable from the
files alone.

### Rule 4. Credit

The bureau may credit a corroborated fact that it hasn't credited yet. A credit
is one step and one fact, and it lands on both sides at once: A gains credit for
B on b, and B gains credit for A on b, in the same motion. Credit, once given,
is never revoked. A one-sided claim just sits on file, harmless, until its
counterpart arrives or forever.

### Rule 5. The bureau keeps up

The bureau works at its own pace and in any order it likes. What it may not do
is sit on confirmable work forever: a fact that is corroborated on file and not
yet credited is eventually credited. That's the bureau's charter, and it is the
one thing in this system that must happen.

## 2. What must be true

A correct model satisfies all of the following, stated in English over the
observables of section 3 and the two constant sets. They must hold for any
operator set and any band set. The instance in section 4 is one instance, not
the specification.

1. **The opening.** Every file is empty, and nobody holds credit for anything.
2. **Files only grow.** A claim on file stays on file.
3. **Files are well formed.** Every claim on an operator's file names a
   different operator and a band from the band set.
4. **One envelope at a time.** A step that changes any file changes exactly one
   operator's file, and changes no credit.
5. **Credit is corroborated.** Whenever an operator holds credit for a
   counterpart on a band, both matching claims are on file.
6. **Credit is mutual.** A holds credit for B on b exactly when B holds credit
   for A on b.
7. **Credit comes whole, one fact at a time.** A step that changes credit adds
   credit for exactly one fact, on both sides in that same step, and changes no
   file.
8. **Credit is permanent.** Credit held is never lost.
9. **The bureau keeps up.** A fact corroborated on file and uncredited is
   eventually credited.

Items 3, 5, and 6 are invariants. Items 2, 4, 7, and 8 constrain steps, so
they'll land as action properties. Item 9 is the one liveness obligation in this
description. Item 1 is a condition on the opening state.

One interaction is worth naming for the record. Item 5 does the work of a
moment-of-credit rule only because 2 and 8 hold: with files that never shrink
and credit that never lapses, credit-was-sound-when-given and
credit-is-sound-now coincide. A model is free to make either one the thing it
maintains. The properties don't care, and that is on purpose.

## 3. The observation operator

The model names an operator, `Observe`, with two fields. They are the bureau's
whole public face: the files and the register. Each field is given here as a
named fact, not as syntax. The author renders them over whatever state they
chose.

- **filed**: for each operator, the set of claims on their file, each claim a
  counterpart station and a band.
- **credited**: for each operator, the set of counterpart-and-band facts they
  hold credit for.

Why each field is there:

**filed** is the paper trail. Corroboration (Rule 3) is definable from it alone,
properties 2, 3, and 4 are about it, and 5 and 9 read it. Without it, a credit
has no visible cause at the interface.

**credited** is the register the bureau exists to produce. Properties 5 through
8 are about it, and 9 reads it. A model that stores per-operator credit lists
and one that stores one set of pair-facts both produce this field.

Event signatures: an envelope shows as one operator's filed growing while every
credit holds still (properties 2 and 4). A credit shows as two mirror entries
appearing together while every file holds still (properties 6 and 7). No other
observable event exists, so no two events share a signature.

The sufficiency walk, rule by rule. The test in each row is which property
constrains the rule, never which field mentions it. A rule no property
constrains is ungraded, whatever the fields show.

| Rule | Constrained by |
|---|---|
| 1 claims | 3 |
| 2 the files | 2 and 4, with 1 pinning the empty start. The duplicates-collapse clause rides `filed`'s set shape, not a property, the way custody's one-outstanding rule rides `pending`'s type |
| 3 corroboration | none directly, and that's right: it's a definition, not a behavior. The behavior it feeds is constrained at 5 and 9 |
| 4 credit | 5, 6, 7, and 8 |
| 5 the bureau keeps up | 9 |

Three honest notes on what the interface does not show.

First, hands at the bureau. Who mailed an envelope is visible (it's whose file
grew). Which clerk matched a fact isn't, and no property depends on it.

Second, the station logs. There is no field for them. A model that carries
private logs and one that skips straight to the mail produce the same
observations: under `Observe`, private logging is stutter.

Third, truth. No field and no property says whether a claim describes a contact
that happened. The register never knows, so the model never says.

## 4. Bounds

**Operators and bands** are the domain's own sets, the way custody's two parents
are. The config picks one instance. The rules hold for any.

Suggested instance: 3 operators, 2 bands. Three operators is the least where
credit-is-mutual (property 6) bites across distinct pairs, and where one pair's
mail can interleave with a third party's. Two bands is the least that makes the
band half of a claim do any work.

The arithmetic at the instance. Each operator has 4 possible claims, so each
file is one of 16 sets and the three files give 4,096 combinations. There are 6
facts, each credited or not, bounded by corroboration, so the naive product is
under 262,144 and the reachable count sits well below it. TLC should exhaust
this in well under a minute with liveness on (property 9 carries the one
eventually). That's an estimate. Nobody has run it.

## 5. Open forks

These are modeling choices the description leaves open on purpose. An edit that
closes one is a regression, not a tightening.

- **The station logs**: modeled as private state feeding the mail, or skipped
  entirely. Invisible either way (section 3's second note).
- **The register**: per-operator credit sets maintained, or one set of
  pair-facts each operator's view derives from.
- **Corroboration**: computed at the crediting step, or a matchable-list the
  model keeps as claims land.
- **The envelope**: how a batch of claims is represented in the action. The
  rules fix that a batch lands as one step, not how the model carries it.
- **The bureau**: a process, or bare actions.

Two-step crediting is not on the list. Property 6 is an invariant, and crediting
one side before the other leaves a between-state where mutuality fails. Rule 4
already says both sides move in one motion, so that choice was never open.

One pipeline note. This domain seats the wave's shape-B cell: the learner-facing
artifact hands over a spec and asks for the properties, so the reference will
ship with one satisfying and one violating trace per property downstream (§3.9).
Nothing in sections 1 to 4 depends on that. The description fixes the system the
same way for any task shape.

## 6. Ambiguities I resolved, and the other way each could go

The pilot's author settled six of these silently and each one surfaced
downstream as a risk. These are mine, with the road not taken.

1. **No retraction.** Files only grow. The alternative is an audit that expunges
   bad claims. Shrinking files cost property 2, and with it the coincidence
   noted at the end of section 2: credit-was-sound and credit-is-sound come
   apart, and 5 stops being the simple invariant it is here. Bureaus keep
   everything, so I kept it.
2. **Duplicates collapse.** A file records that a claim stands. The alternative
   counts repeat contacts, which needs times to tell them apart, and this
   register answers worked-or-not. Counts buy nothing here.
3. **A fact is pair plus band, once.** The alternative gives each contact a
   serial. Same cost as 2, same verdict.
4. **Self-claims are refused at the desk.** The alternative accepts them as
   inert junk. Inert entries grade nothing, and the refusal is what makes
   property 3 a clean invariant.
5. **One fact per credit step.** The alternative sweeps everything matchable in
   one step. The sweep collapses signatures (one step crediting five facts, and
   no way to tell the bureau's motions apart) and asks no new modeling question.
   A note for the variant pass: Rule 4's credited-once guard is observationally
   vacuous. A re-credit of an already-credited fact changes nothing at the
   interface, so a model that permits the attempt produces the same `Observe`
   traces as one that refuses it. That variant is uncatchable, with the cause
   named here in advance, custody's self-acceptance situation exactly.
6. **The bureau must keep up.** The alternative is a lazy bureau. Then nothing
   in the system ever must happen, every property is safety, and a one-sided
   claim "waiting" means nothing when credit can also wait forever. I gave the
   bureau its charter. It's the only liveness here, so the author should expect
   exactly one fairness decision.
7. **Envelopes carry many claims.** The alternative is one claim per step. Log
   sheets are batches, and one-at-a-time is a constraint the rules don't make. A
   model that imposes it is modeling a different mailroom.
8. **Bands only, no modes.** The alternative is a band-and-mode matrix, which
   multiplies the claim space for no new question. Same reasoning as museum's
   one sensitivity class.
9. **Membership is fixed.** Nobody joins or leaves mid-story. Files of departed
   members are a records-retention question, not a modeling one.
10. **No awards.** Real bureaus feed award programs (so many confirmed
    counterparts earns a certificate). An award is a derived counter on top of
    the register, and none of the bureau's own discipline changes with it, so it
    stays out.
