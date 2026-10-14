# USES: temporal/04-contention

Subject: A background poller that takes and releases a lock over and
over, and a one-shot task that needs the same lock once.

rc: 0

## What the properties rest on

`SF_vars(TaskTake)` is the whole point. Swapping it for
`WF_vars(TaskTake)` gives rc 13, and `WindowCloses` says why: the
window the task needs never stays open, so weak fairness has no
hypothesis to fire on.

## Constructs

- <> (eventually)
- []<> (always eventually)
- ~> (leads-to)
- ' (prime, next-state value)
- [P]_x (box action formula)
- <<A>>_v (angle action formula)
- VARIABLE / VARIABLES
- vars (the all-variables tuple)
- Init / Next / Spec (the pure-TLA+ spec skeleton)
- action (formal definition)
- UNCHANGED
- nondeterministic action (\E form and disjunction form)
- ENABLED
- WF_v(A) (weak fairness)
- SF_v(A) (strong fairness)
- fairness conjunct on Spec
- fairness on a subaction

## Constructs from other families, also exercised

- Operator definition
- Strings
- Equality and inequality
- Booleans and logical operators
- Bullet-point boolean notation
- BOOLEAN and integer interval as sets
- Invariant (as a TLA+ operator, checked at every state)
- PROPERTY (TLC model config: register a temporal property)
