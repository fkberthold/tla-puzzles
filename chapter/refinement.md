# Refinement

You know how to write a spec, and you know how to pull one module into
another. This chapter is about the thing those two facts add up to: writing
*two* specs of the same system, one small enough to understand and one close
enough to the real thing to be useful, and then getting TLC to check that
they agree.

That's refinement. The reason to care about it is not that it's elegant. It's
that past a certain size you cannot write one spec that is both honest about
the system and small enough to reason about, and refinement is how you stop
having to choose.

Everything in here is checkable, and I've checked all of it. Every TLA+ block
below comes out of a module in [`snippets/`](snippets/), and
`snippets/run-all.sh` runs 26 module/config pairs, asserts the exit code each
one produces, and then reconciles every block on this page against the module
it was taken from — so the page cannot drift away from the code that ran
without something going red. Three blocks are exceptions and I flag each one
where it appears: two are algebraic expansions of a formula rather than
something you would write, and one is a line quoted from a published paper that
does not parse — which is the reason I'm being fussy about this in the first
place.

## Why you'd bother

Here's the pitch. You have a system with fifteen moving parts. You write one
spec containing all fifteen, and now the invariant you care about is buried
under a page and a half of `EXCEPT`s. Nobody can review it. You can't tell
whether a failed check means the system is wrong or your model of it is.

So instead you write the two-line version — what the thing is *for* — and
prove your fifteen-part version implements it. Now:

- The small spec is where you state and check the properties you actually
  care about. It's short enough that a reviewer can agree it says the right
  thing, which is the only guarantee anyone ever gets that a spec is correct.
- Anything you prove of the small spec is automatically true of the big one.
  Not "true by a similar argument." True, for free, the moment the refinement
  check passes.
- You can chain it. Three specs, two refinement checks, and the properties of
  the top one hold of the bottom one. `EWD998ChanID.tla` in the TLA+ examples
  repo does exactly this — its `EWD998Live` is defined as
  `EWD998Chan!EWD998!TD!Live`, three instance hops deep, and the `.cfg` just
  lists `EWD998Live` under `PROPERTIES`.

Lamport and Merz have a nice line about why the small spec is worth writing
even when it costs you a second module. Working on a snapshot algorithm, they
found that the natural refinement was painful, so they invented an
intermediate specification to split it in two:

> The advantage of introducing Spec_NL is that the specification of what an
> algorithm is supposed to do is generally much simpler than the algorithm.

That's from *Auxiliary Variables in TLA+* §6.4, and the same move is in
*Prophecy Made Simple* §5: rather than fight the hard case, verify that your
algorithm implements a *new* specification, and separately that the new
specification implements the original one. Two easy links instead of one
impossible one.

Now the honest part, because I don't want to oversell this. Lamport, in
*Specifying Systems* §10.9:

> If you are writing a specification from scratch, it's probably better to
> write a monolithic specification. It is usually easier to understand.

He's talking about composition rather than refinement, but the point carries.
If you can hold the whole system in one spec, do that. Refinement is what you
reach for when you can't — when the spec has outgrown your head, or when the
abstract version already exists and you want to check something against it.
It's a tool for managing size, and if you don't have a size problem you don't
need it.

## Implementation is implication

The entire idea, in one line, from Lamport's *Hiding, Refinement, and
Auxiliary Variables* §5:

> Reduced to a slogan, this means: implementation is implication.

A spec is a formula. A behavior either satisfies it or doesn't. If every
behavior satisfying `Concrete!Spec` also satisfies `Abstract!Spec`, then
`Concrete!Spec => Abstract!Spec` is valid, and that *is* what "the concrete
one implements the abstract one" means. There's no separate definition.

That works because of something worth pinning down before we go any further,
since it's the mental model that makes the rest of the chapter make sense.
Lamport and Merz, *Prophecy Made Simple* §4.3:

> A reader who finds this hard to understand is making the mistake of
> thinking of a specification like (17) as a rule for generating behaviors.
> It's not. It's a predicate on behaviors — a formula that is either
> satisfied or not satisfied by a behavior.

If you read `Spec` as a program that emits states, refinement looks like it
should be about simulation, and half of what follows will feel arbitrary.
Read it as a predicate and it's just implication.

Here's the smallest example I could make. The abstract shop has one number,
which goes up by one on every sale:

```tla
------------------------------ MODULE Till ------------------------------
EXTENDS Naturals

CONSTANT Max

VARIABLE takings
vars == << takings >>

Init == takings = 0

Ring ==
  /\ takings < Max
  /\ takings' = takings + 1

Next == Ring

Spec == Init /\ [][Next]_vars

MonotonicTakings == [][takings' >= takings]_vars
=========================================================================
```

And the real shop has two tills, plus a member of staff who moves cash
between them:

```tla
---------------------------- MODULE TwoTills ----------------------------
EXTENDS Naturals

CONSTANT Max

VARIABLES a, b
cvars == << a, b >>

Init == a = 0 /\ b = 0

RingA == /\ a + b < Max
         /\ a' = a + 1
         /\ UNCHANGED b

RingB == /\ a + b < Max
         /\ b' = b + 1
         /\ UNCHANGED a

Sweep == /\ a > 0
         /\ a' = a - 1
         /\ b' = b + 1

Next == RingA \/ RingB \/ Sweep

Spec == Init /\ [][Next]_cvars

T == INSTANCE Till WITH takings <- a + b

Refines == T!Spec
=========================================================================
```

Two things to notice. `T` is an ordinary `INSTANCE`, the same one you already
know — the only new part is what's on the right of the arrow. And `Refines`
is just a name for `T!Spec`, so the config can say:

```
SPECIFICATION Spec
PROPERTY Refines
```

That `Refines == Abstract!Spec` plus `PROPERTY Refines` shape is the house
style. I counted: in `tlaplus/Examples`, 20 modules define an operator of the
form `Name == Instance!Spec`, and 17 of them have a config that names that
operator under `PROPERTY` or `PROPERTIES`. (One more, `btree`, has the line
present but commented out. The other two are `byzpaxos` proof modules whose
configs check invariants only.)

There's a reason it's always a named operator, and it will cost you an hour
if you don't know it: **the `.cfg` grammar takes bare identifiers only.** You
cannot write `PROPERTY T!Spec`. And the error doesn't tell you that:

```
Error: The property A specified in the configuration file
is not defined in the specification.
```

`A` *is* defined. It's the instance. TLC parsed up to the `!`, treated the
rest as noise, and told you about a symbol that isn't the problem. Define an
operator and name the operator.

## A refinement is a claim about three things

Before you run anything, get this straight, because it's the difference
between refinement being a check and refinement being a ritual.

"`TwoTills` refines `Till`" is not a fact about `TwoTills` and `Till`. It's a
fact about `TwoTills`, `Till`, **and `takings <- a + b`**. Change the mapping
and it becomes a different claim, and the pair of specs has nothing to say
about whether the new claim is interesting.

This isn't a stylistic warning. It's a theorem, and it's about as bad as it
sounds. *Hiding, Refinement, and Auxiliary Variables* §5:

> In the general case, it's meaningless to say that a spec Spec 2 implements
> a spec Spec 1 without saying what expressions are substituted for the
> observable variables of Spec 1 . For any two specs Spec 1 and Spec 2 , by
> adding suitable auxiliary variables to Spec 2 , it's possible to define a
> refinement mapping under which Spec 2 implements Spec 1 .

*Any* two specs. Your cache refines your leftpad, given a sufficiently
creative mapping. So "does it refine?" is never the whole question. The
question is always "does it refine *under a mapping that means something*,"
and no tool answers that part. Lamport finishes the paragraph by telling you
to go and look:

> To decide if implementing Spec 1 under a refinement mapping is an
> interesting property of Spec 2 , you have to examine carefully the
> expressions the refinement mapping substitutes for the variables of Spec 1
> — especially its observable variables.

Keep that in your pocket. The rest of the chapter is mostly about specific
ways a mapping can fail to mean anything while TLC reports success.

## Substituting for variables

One gap to close first. The modules chapter taught `INSTANCE ... WITH` for
constants, which is the common case. The refinement case substitutes for
**variables**, and the rule is the same one with a wider target: every
variable of the instantiated module gets replaced by an expression over the
instantiating module's state.

```tla
T == INSTANCE Till WITH takings <- a + b
```

`Till` has one variable, so the mapping has one line. Every occurrence of
`takings` inside `Till` — in `Init`, in `Ring`, in `vars` — becomes `a + b`.
Occurrences of `takings'` become `(a + b)'`, which is `a' + b'`.

If you don't name every variable, SANY tells you exactly which one, which is
a pleasant change from most of the error messages in this chapter:

```
Substitution missing for symbol takings declared at line 9, col 10 to
line 9, col 16 of module Till and instantiated in module MissingSub.
```

If the instantiating module happens to have a variable of the same name, you
can leave it out and it's substituted for itself, which is why the identity
refinement `R == INSTANCE Running` in `RunningH.tla` needs no `WITH` at all.

That last one is worth knowing about. `INSTANCE Foo` with no `WITH`, where
your module has a superset of `Foo`'s variables, gives you "my spec with the
extra variables ignored" — which is exactly the check you want when you've
bolted something onto a spec and want to know you didn't change it.

## Stuttering, which is the whole trick

You already know `[Next]_vars` means `Next \/ UNCHANGED vars`, and you
probably learned it as a technical requirement — something you write because
otherwise the spec forbids other parts of the system from doing anything.

That framing undersells it. Stuttering isn't a concession the logic makes to
practicality. It's constitutive: a spec describes *part* of a world, and a
formula about part of a world has to be indifferent to steps that change only
the rest of it. `[Next]_vars` is what "this formula is about `vars` and
nothing else" looks like when you write it down.

Which means refinement gets its central mechanism for free. Look at `Sweep`
in `TwoTills`: it changes both `a` and `b`, and leaves `a + b` alone. Under
the mapping, `Sweep` is a step in which `takings` doesn't move. That's a
stuttering step of `Till`. Nothing in `Till` had to anticipate the existence
of tills, or of staff, or of sweeping; the `[...]_vars` it already had covers
it.

Now here is the part almost nobody says out loud. **The subscript is
substituted too.** `Till!Spec` is

```tla
Init /\ [][Next]_vars
```

and `vars` is `<< takings >>`. Under `takings <- a + b`, the whole formula
becomes this — an expansion, not something you'd type:

```
(a + b = 0) /\ [][ Ring-with-takings-replaced ]_<< a + b >>
```

So the mapping doesn't just decide what the abstract variables *are*. It
decides **which concrete steps are invisible** — a concrete step is invisible
exactly when it leaves the mapped expressions unchanged. Choosing the mapping
and choosing the stuttering are the same act. If you find yourself wanting to
say "and this concrete action shouldn't count," you're not adding a rule,
you're constraining the mapping.

### The hole

Read that substituted formula again, and expand the box (again, an expansion,
not a snippet):

```
[][ ANext ]_<< a + b >>   ==   [] ( ANext \/ UNCHANGED << a + b >> )
```

It's a disjunction. If `a + b` never changes, the right side is true at every
step, the disjunction is satisfied at every step, and `ANext` **is never
evaluated at all**.

So take the two-till shop and map `takings` to a constant:

```tla
TFrozen == INSTANCE Till WITH takings <- 0

RefinesFrozen == TFrozen!Spec
```

Run it:

```
$ ./run.sh TwoTills.tla TwoTillsFrozen.cfg
Model checking completed. No error has been found.
19 states generated, 10 distinct states found, 0 states left on queue.
=== TwoTills.tla (TwoTillsFrozen.cfg) rc=0
```

Ten states explored, zero errors, exit code 0, and the check proved nothing
whatsoever. `Ring` was never once evaluated. TLC is not broken and is not
being unhelpful — you asked whether every step satisfies
`Ring \/ UNCHANGED <<0>>`, and every step does, because the right disjunct is
`TRUE`.

**Stuttering is both the load-bearing beam and the trapdoor.** It's the same
disjunction doing both jobs, and there is no version of TLA+ refinement where
you get one without the other.

`takings <- 0` is obvious. The trap is that frozen mappings do not have to
look frozen — a one-character typo will do it, and the worked example is
built around exactly that. It is also not a theoretical worry: `TLAiBench`,
the TLA+ Foundation's benchmark for grading machine-written specs, checks
refinement in two stages, and a fully frozen mapping passes both of them at
exit code 0 — indistinguishably from a correct one.

### The probe

The fix is cheap and you should wire it in permanently. Ask TLC, separately,
whether the mapped abstract state ever moves:

```tla
Frozen == Archived = {}   \* the mapped expression, at its initial value
```

Run that as an `INVARIANT`. **A violation is the pass.** If TLC reports
`Invariant Frozen is violated`, the mapped state left its starting value at
least once, so the refinement check above it had something to chew on. If TLC
reports no error, your mapping never moved.

```
probe on a live mapping     ->  rc=12   good
probe on a frozen mapping   ->  rc=0    the refinement check was empty
```

It is the one check in your suite whose good outcome is a failure, so label
it loudly.

And now the caveat, because a probe that you trust too much is worse than no
probe. The probe rules out the *degenerate* mapping. It does not rule out a
mapping that moves for reasons of its own. `RunningH.tla` in the snippets has
one: a mapping that produces a sequence of `num` ones, which grows on every
step (so the probe is satisfied, rc=12) and passes the refinement check
(rc=0) — because appending a `1` is a legal step of the abstract spec no
matter what the implementation actually did. Two green checks, and the
mapping tracks nothing.

The probe is a floor. The thing above it is still you, reading the mapping.

## Reading a failure

When a refinement does fail, the message points into the *abstract* module,
which is exactly where you aren't looking:

```
Error: Action property line 21, col 17 to line 21, col 29 of module Almanac
is violated.
```

Three tools, in increasing order of how much you should reach for them.

**`ALIAS`.** The trace shows concrete state, and what you need to see is
mapped state. Define a record with both, and name it in the config:

```tla
Alias ==
  [ status |-> status,
    onsky  |-> onsky,
    acc    |-> acc,
    logged |-> ArchivedEager ]
```

```
State 2: <Slew(d1,p1) ...>
/\ status = (p1 :> "observing" @@ p2 :> "queued")
/\ logged = {p1}

State 3: <Cloud(d1) ...>
/\ status = (p1 :> "queued" @@ p2 :> "queued")
/\ logged = {}
```

There it is, in one glance: the abstract archive went from `{p1}` to `{}`,
and archives don't shrink. The mapping was counting a proposal as archived
while it was still being observed.

**The rung below.** Full refinement bundles the initial predicate, the
next-state relation, and any liveness into one formula, and TLC tells you the
bundle failed. Check the middle one alone:

```tla
IProp == [][A!Next]_<< Archived >>
```

That's the shape `MCPaxos.tla` uses in the examples repo
(`MCIProp == [][V!Next]_<<votes, maxBal>>`, line 72). If `IProp` passes and
`Refines` fails, your problem is `Init` or your liveness, not your actions.

**`Inv!n`.** When the failing thing is a fat conjunction, TLC names the
conjunction:

```
Error: Invariant Inv is violated.
```

`Inv!n` selects the nth conjunct positionally. Define one operator per
conjunct — you have to, since the config takes bare identifiers — and TLC
names the conjunct instead:

```tla
Inv == /\ x <= 4
       /\ y <= 3
       /\ y = 2 * x

Inv1 == Inv!1
Inv2 == Inv!2
Inv3 == Inv!3
```

```
Error: Invariant Inv2 is violated.
```

Same run, same trace, and now you know which line to read.

## When there is no mapping

Sometimes the concrete spec really does implement the abstract one and there
is still no mapping. This is not a failure of imagination; it's a property of
the pair.

The clean case is that the abstract spec talks about something the concrete
state doesn't contain. Here's the abstract spec, which keeps every value it
was handed:

```tla
Init == log = << >>
Record(v) == /\ Len(log) < MaxInputs
             /\ log' = Append(log, v)
```

and the implementation, which keeps a count and a total:

```tla
Init == num = 0 /\ sum = 0
Take(v) == /\ num < MaxInputs
           /\ num' = num + 1
           /\ sum' = sum + v
```

Every visible behavior of the implementation is a legal behavior of the spec.
But a refinement mapping has to be an *expression over the concrete
variables*, and there is no expression over `num` and `sum` that equals the
sequence of values. The information isn't there. These two are cut down from
Lamport and Merz's specifications A and B (*Prophecy Made Simple* §3.1 and
§3.2 — their `A` keeps the count and total, their `B` keeps `seq`), and they
say it in one line about that pair, in the opening paragraph of §4:

> IA does not implement IB under any refinement mapping because there is no
> way to define seq in terms of the variables of A.

The other direction is the same problem in the future tense, and you can
watch it fail. `Oracle` decides at time zero:

```tla
Init == pick \in Vals /\ done = FALSE
```

`Late` decides at the last moment:

```tla
Init == out = Nothing /\ done = FALSE
Reveal == /\ ~done
          /\ \E v \in Vals : out' = v
          /\ done' = TRUE
```

Try the obvious mapping, `pick <- out`:

```
Error: Property line 11, col 6 to line 11, col 18 of module Oracle is
violated by the initial state:
/\ out = Nothing
/\ done = FALSE
/\ pick = Nothing
```

Line 11 of `Oracle` is `pick \in Vals`. In `Late`'s initial state the value
hasn't been chosen, and nothing in the state says which one it will be.
There's no cleverer expression, either: whatever you write is a function of
the current state, and the current state doesn't know.

This has been mapped out properly. Abadi and Lamport's 1988 report *The
Existence of Refinement Mappings* proves that if `S1` implements `S2` then
auxiliary variables are always enough to make a mapping exist — under three
hypotheses, each of which they show is needed by producing a specification
that breaks it. Their words, with `S1` the implementation and `S2` the spec:

> **S1 is machine closed.** Machine closure means that the supplementary
> property (the one normally used to specify liveness requirements) does not
> specify any safety property not already specified by the state machine. In
> other words, the state machine does as much of the specifying as possible.
>
> **S2 has finite invisible nondeterminism.** This denotes that, given any
> finite number of steps of an externally visible behavior allowed by S2,
> there are only a finite number of possible choices for its internal state
> component.
>
> **S2 is internally continuous.** A specification is internally continuous
> if, for any complete behavior that is not allowed, we can determine that it
> is not allowed by examining only its externally visible part (which may be
> infinite) and some finite portion of the complete behavior.

You will not use those definitions directly. What's worth carrying is the
shape of them: each says the abstract spec's hidden state is pinned down by
something finite and visible, and each failure mode is a way for it not to
be. (*Prophecy Made Simple* refers to the second as "finite internal
non-determinism," if you meet it under that name.)

The fix for all of them is the same. If the concrete spec doesn't carry the
information the mapping needs, add it.

## Auxiliary variables

An auxiliary variable is one you add to the concrete spec *purely* to make a
mapping expressible. It records or predicts; nothing in the system reads it. learntla's
[auxiliary variables](https://learntla.com/topics/aux-vars/) topic covers the
working patterns; what refinement adds is the obligation that comes with
them.

### History variables

A history variable remembers. Add `h` to the implementation:

```tla
Init == num = 0 /\ sum = 0 /\ h = << >>

Take(v) ==
  /\ num < MaxInputs
  /\ num' = num + 1
  /\ sum' = sum + v
  /\ h'   = Append(h, v)
```

and now `log <- h` is an expression over the concrete state, and the
refinement passes.

### The obligation, which is an equivalence

Here's the part that's easy to skip. Adding a variable is only legitimate if
the augmented spec has **the same behaviors** as the original, once you hide
the new variable. Not "implies." Same. Two directions:

1. The augmented spec allows nothing the original didn't.
2. The augmented spec forbids nothing the original allowed.

Lamport and Merz call these AV1 and AV2 (*Prophecy Made Simple* §4). If you
only check (1) you can "prove" anything: a spec whose `Init` is `FALSE`
allows nothing new and refines everything in the universe.

Direction (1) is a refinement check, so TLC can do it. Point the augmented
spec at the original and let the shared variables map to themselves:

```tla
R == INSTANCE Running

NoNewBehavior == R!Spec
```

Direction (2) is not a refinement check — it's an existence claim over hidden
values — and TLC cannot do it. You get it by argument.

For a **history variable** the argument is syntactic and you get it for free:
`h` is only ever conjoined onto an action that already existed, its new value
is uniquely determined by the state and the step, and it's never mentioned in
any guard. Nothing was pruned, because nothing consults `h`.

For a **prophecy variable** you have to earn it, and that's the real
difference between the two.

### Prophecy variables

A prophecy variable predicts. There is a three-line recipe, and I'd rather
give it to you verbatim than paraphrase it. *Prophecy Made Simple* §4.2,
where `Next` is a disjunction of elementary actions including a set `A_i` for
`i` in some set `P`:

> A simple prophecy variable p that predicts for which i the next A_i step
> occurs is obtained by:
>
> 1. Conjoining p ∈ P to the initial predicate Init.
> 2. Replacing each A_i by (p = i) ∧ (p′ ∈ P) ∧ A_i.
> 3. Replacing each other elementary action B by (p′ = p) ∧ B.

`Late`'s `Reveal` is `\E v \in Vals : out' = v`, which is a disjunction of
one action per value, so `P` is `Vals`. And since there's only ever one
prediction to make, step 2's `p' \in P` specializes to holding `p` fixed:

```tla
Init ==
  /\ out = Nothing
  /\ done = FALSE
  /\ p \in Vals              \* 1. predict

Reveal ==
  /\ ~done
  /\ out' = p                \* 2. keep the promise
  /\ done' = TRUE
  /\ UNCHANGED p             \*    and p' \in P, specialized
```

Now `pick <- p` works, and both halves check out: `Refines` passes and
`NoNewBehavior` passes.

Look at line 2 though. It **constrains an existing action** — `Reveal` used
to be free to produce any value in `Vals`, and now it must produce `p`. That
is exactly what a history variable never does, and it's why the AV2 argument
has to be made rather than assumed: you have to say why `p` ranges over
precisely the outcomes `Reveal` could have produced. Here that's obvious,
because `p \in Vals` and `Reveal` chose from `Vals`. It is not always
obvious, and getting it wrong means you proved your implementation correct by
quietly deleting the behaviors where it isn't.

This is also, if you squint, the same trick as learntla's `aux_proph_digits`
— hoist a nondeterministic choice to the front of the behavior. The
refinement setting just makes the obligation explicit.

### Machine closure

One more thing about prophecy, because it produces a genuinely strange
artifact and you should recognize it rather than think you broke something.

A spec of the form `Init /\ [][Next]_vars /\ Liveness` is **machine closed**
when, in *Specifying Systems*' words, "the conjunct Liveness constrains
neither the initial state nor what steps may occur." Normally that's what you
want: the state machine says what can happen, and the liveness conjunct only
says what must eventually happen.

Add a prophecy variable to a spec that has liveness and you can lose it. Let
`p` range over `Vals` plus one outcome that `Reveal` can never produce, and
conjoin weak fairness on the *original* action over the *original* variables
— which is what a liveness property of the implementation looks like:

```tla
Init == out = Nothing /\ done = FALSE /\ p \in Vals \cup {Never}

Reveal == /\ ~done /\ p \in Vals /\ out' = p /\ done' = TRUE /\ UNCHANGED p

RevealAny == /\ ~done /\ \E v \in Vals : out' = v /\ done' = TRUE

SpecWF == Init /\ [][Next]_vars /\ WF_ovars(RevealAny)
```

A behavior that predicted `Never` can never take a `Reveal` step, so it
halts. But `RevealAny` stays enabled forever in a halted behavior, so weak
fairness rules that behavior out. **The liveness conjunct has forbidden an
initial state.** Lamport and Merz, *Auxiliary Variables in TLA+* §4.6:

> The technical term for this weirdness is that the formula SpecP is not
> machine closed [2], which means that its liveness property affects safety
> as well as liveness.

You can watch both halves:

```
./run.sh LateProphMC.tla                       -> rc=0   <>done holds under SpecWF
./run.sh LateProphMC.tla LateProphMCReach.cfg  -> rc=12  p = Never is reachable from Init/Next
```

Note *why* it takes two runs. TLC builds its state graph from `Init` and
`Next` and ignores the fairness conjunct while doing so, so it cannot show
you a machine-closure failure in a single run. That's also the practical
advice: don't ship a non-machine-closed spec as a description of a system —
the same source says "Non-machine closed specs should never be used to
describe how a system works," and the reason is that the next-state action no
longer tells you what the system can do. It's fine here, because `SpecP`
isn't a description of anything. It exists to check `Spec`, and then you
throw it away.

## Liveness, and why ENABLED ruins it

Everything above is safety. Liveness refinement is harder, and there's one
specific reason.

Substitution distributes over almost everything. `(A /\ B)` with a
substitution is the substituted `A` and the substituted `B`; same for `[]`,
for priming, for arithmetic. It does **not** distribute over `ENABLED` — and
therefore not over `WF` or `SF`, which are defined in terms of it.

Lamport's example, from *Specifying Systems* §17.8. A module with two
variables and one claim:

```tla
VARIABLES x, y

F == ENABLED (x' = 0 /\ y' = 1)
```

`F` is `TRUE`. Whatever state you're in, there's a next state with `x = 0`
and `y = 1`. Now instantiate it with both variables mapped to the same one:

```tla
I == INSTANCE EnabledInner WITH x <- z, y <- z
```

Push the substitution through by hand and you get `ENABLED (z' = 0 /\ z' = 1)`,
which is `FALSE`. A theorem stopped being a theorem, which isn't allowed. So
TLA+ doesn't push it through: the primed variables under `ENABLED` are bound
identifiers, and substitution doesn't reach bound identifiers. `I!F` is still
`TRUE`. You can check that the two really are different formulas:

```tla
StillTrue == I!F
ByHand    == ENABLED (z' = 0 /\ z' = 1)

Different == StillTrue /\ ~ByHand
```

`Different` holds in every state, at rc=0. TLC will tell you to your face
that substituting into `ENABLED` is not the same as substituting into the
action underneath it.

The consequence for you: `ENABLED` of the abstract action *under the mapping*
is a different thing from `ENABLED` of the corresponding concrete action, and
no amount of symbol-pushing relates them. So a fairness condition on the
concrete spec does not automatically give you the abstract spec's fairness
condition. You have to argue it, usually by showing that whenever the
abstract action is enabled under the mapping, some concrete action that
implements it is enabled too. *Specifying Systems* §17.8 states the rule
directly:

> Our rules for instantiating in an enabled expression imply that
> instantiation does not distribute over enabled. It also does not
> distribute over any operator defined in terms of enabled — in particular,
> the built-in operators WF and SF.

Practical advice: get safety refinement passing first, on its own, and only
then add the liveness conjuncts. If you add them together you won't know
which half is failing.

## What I left out

**`\EE`.** There is a temporal existential quantifier, written `\EE x : F`,
which means "there's some sequence of values for `x` that makes `F` true."
It's the honest way to write "these variables are internal," and it makes the
definition of refinement clean: `Concrete` implements `Abstract` when they
have the same *observable* behaviors, hiding the rest. I'm telling you it
exists so that "internal variable" has a meaning, and then telling you never
to write it. Lamport, in *Hiding, Refinement, and Auxiliary Variables* §5
(the ∃ here is the temporal one, `\EE`):
"neither the TLC model checker nor the TLAPS prover can handle the ∃
operator. TLC is unlikely ever to handle it, since checking if a behavior
satisfies such a formula is inherently difficult." Instead you say `Spec` is
the spec and note in a comment which variables are internal, which is what
every module in this chapter does. (He also calls it the stone in the TLA+
soup, which is the best description of a piece of notation I have read.)

**Proof.** Everything here is model checking, on finite models. Refinement
also has a proof theory, and TLAPS can discharge these obligations for
unbounded models. That's a different chapter.

## One last thing about running the code

I said at the top that every snippet here is executed. Here's why I bothered.

*Hiding, Refinement, and Auxiliary Variables* is a careful note by a careful
author, and its title page records two rounds of corrections after the first
posting. Figure 8 contains this line — transcribed from the paper, and the
one block in this chapter that will not parse:

```
qPbar == IF s = 0 THEN <<>> ELSE End(seq)
```

There is no `seq` in scope. `seq` is the formal parameter of the `End` and
`Front` operators defined at the top of the same module; the variables in
scope are `op` and `queue`, inherited from module `FIFO`, plus `s`. The line
immediately below reads `qGbar == IF s = 0 THEN queue ELSE Front(queue)`. It
should be `End(queue)`.

It's a typo, it's obvious once you see it, and it survived two rounds of
corrections because nobody ran it. If a spec in a paper hasn't been through a
parser, treat it as pseudocode. That includes this chapter, which is why
`run-all.sh` exists.

## Next

The [worked example](worked-example.md) builds one abstract/concrete pair end
to end, and walks through the frozen-mapping trap with a mapping that looks
completely reasonable.
