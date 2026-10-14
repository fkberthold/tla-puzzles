# Two chutes, one gate

Ten minutes of thinking. Every run is under a second.

## The system

A sorting line. Parcels are told apart by weight, one to four. A chute
takes a parcel it hasn't taken before, if the parcel satisfies the
chute's rule, and keeps a record of what it has taken. That's the whole
chute, and the rule is the chute's parameter: not a set of allowed
weights, a test the chute applies to a parcel. The chute module is
written once and doesn't know any rule.

Two chutes on the line. The light chute takes parcels of weight at most
two. The paired chute takes even weights. Each step is one chute taking
one parcel. The two rules are written in the line, in place, where the
chutes are set up. Neither rule gets a definition of its own, though
it's allowed to, and that's a variant worth writing.

The requirement: a chute never holds a parcel its rule rejects. State it
twice. Once through each chute's own view of itself, and once from the
line, naming the variables directly.

## What happened

| model | verdict | distinct states |
|---|---|---|
| the line, parcels one to four | clean | 16 |
| each rule written as a plain true-or-false expression instead of a test | refused: something of arity 1 was expected | |
| each rule wired to the other chute's record | the line's own statement failed, the chutes' did not | 2 |

## The questions

1. Write the chute, the line, and the config. What kind of thing is the
   chute's rule parameter, and how is that declared?
2. Row two. What's the difference between a true-or-false expression
   about a parcel and a test you can apply to one, and what's the
   shortest way to write the second in place?
3. Row three. Why is each chute satisfied with itself when the wiring is
   crossed?
4. Why 16?

Write it, reproduce the 16, then write the rule as an expression and
read the refusal.
