# USES: sets/03-gossip

Subject: Four phones on a ring of links that come up and go down. A rumor
crosses a link while that link is up, and a second variable keeps every link
that was ever up.

rc: 0

## What the properties rest on

rc 0 over 345 distinct states, 2063 generated, depth 12, under a second, with
deadlock checking on. `link \subseteq ever \subseteq Edge` admits 81 pairs at
four links, and `heard` takes at most 7 of its 16 possible values, since every
`Tell` attaches a phone to one that has already heard. `heard = {1, 3}` is the
set that shape rules out, and an added invariant refusing it runs rc 0. So 567
bounds the space and 345 is what is reachable. Under `-coverage 1` no action
is dead and the three of them partition the count exactly: `Up` 119, `Down`
176, `Tell` 49, `Init` 1. The rumor is a seventh of the space and the link
churn is the rest.

`Reach` reads `ever` and not `link`, and that one word is the whole item.
Point it at `link` instead and the run gives rc 12 with `Sound` named. The
counterexample raises a link, tells across it, and drops the link, after which
the current graph cannot explain a phone that has already heard. The closure
has to be taken over the links there have ever been, which is a history
variable doing the only job a history variable does.

Then the probe the plan got wrong, and it is the better half of the lesson.

Guard `Tell` by `e \in ever` rather than `e \in link`, so a rumor can cross a
link that is down and was once up. `PLAN-reading-expansion.md:285` predicts
rc 12. The measured run gives **rc 13** with the action property
`AcrossALink` named, and with `AcrossALink` commented out of the .cfg the same
module gives **rc 0 over the same 345 distinct states**. So `Sound` cannot
tell the live guard from the historical one, and it never could: `Sound` is a
claim about the accumulated set, `ever` only grows, and a rumor crossing a
dead link stays inside the closure it names. The step is what distinguishes
them, so the claim has to be made at the step. That is what `AcrossALink` is
for, and it is why a closure invariant is not enough on its own.

`Sound` and `Tightest` bracket the recursion from opposite sides, and either
alone is loose. Return `S \cup out` instead of recursing, so `Reach` goes one
hop, and `Tightest` still holds while `Sound` gives rc 12. Return `Phone` at
the fixpoint instead of `S`, so `Reach` overshoots, and `Sound` still holds
while `Tightest` gives rc 12 against the initial state. One invariant says the
answer is big enough and the other says it is the smallest one that is.

The stopping test does not fail loudly. Written `out = {}` rather than
`out \subseteq S`, the recursion never stops, because after the first round
`out` holds the neighbors of the phones already in `S`. TLC returns rc 255,
`TLC_EXCEPTION`, on a Java StackOverflowError. The verdict table at
`harness/verdict.sh:67` glosses 255 as an unparseable .cfg, so a runaway
evaluation arrives through the same door. A wrong fixpoint test buys no
counterexample at all.

Two smaller ones. The `Cardinality(Edge) = N` assumption is what refuses a
two-phone ring, where both links are the same unordered pair: point the .cfg
at `N = 2` and the run gives rc 10. And `Spreading` earns its own line, since
`heard' = e` in place of `heard' = heard \cup e` gives rc 13 with `Spreading`
named while `Sound`, `Tightest` and `AcrossALink` all still hold.

## Constructs

- Sets
- Set relational and algebraic operators
- Cardinality
- BOOLEAN and integer interval as sets
- SUBSET (powerset)
- Set map
- Set filter

## Constructs from other families, also exercised

- Operator definition
- IF-THEN-ELSE
- Equality and inequality
- EXTENDS (module import)
- Integers
- Booleans and logical operators
- Bullet-point boolean notation
- Implication
- LET-IN
- Invariant (as a TLA+ operator, checked at every state)
- \A (universal quantifier, "forall")
- \E (existential quantifier, "exists")
- CONSTANT
- ASSUME
- deadlock (checking)
- PROPERTY (TLC model config: register a temporal property)
- RECURSIVE
- action property
- ' (prime, next-state value)
- [P]_x (box action formula)
- VARIABLE / VARIABLES
- vars (the all-variables tuple)
- Init / Next / Spec (the pure-TLA+ spec skeleton)
- action (formal definition)
- nondeterministic action (\E form and disjunction form)
- UNCHANGED

`Reach` takes a set and not an operator, so this item does not claim
`Higher-order operator parameter`. `Src` is an ordinary definition rather than
a declared constant, so it does not claim `model value` either.
