# Building permit review

## What you're given

Two files, `PermitReview.tla` and `PermitReview.cfg`. Someone at the city wrote them to
pin down the review process described below.

The spec parses, it runs, and TLC reports no error against the checks its own `.cfg`
declares. So running it won't hand you anything. The gap between what the process
requires and what the spec says is the whole exercise.

## Your task

Read the description of the system. Then work out what the specification fails to say
about it.

You're not writing a spec. You're reading one against the process it claims to capture.

## The system

A city reviews building permit applications. One application is in front of it.

**The parties.** Three kinds of party act, and they act independently.

- The **applicant**, who submitted the application.
- A fixed, finite set of **review departments**, named by `Departments`.
- The **city**, the only party that can issue a permit.

Nothing orders the departments and nothing coordinates them. Any party's next step can
land between any two steps of another party.

### Rule 1. An application is open until it reaches an outcome

An application starts open. It stops being open when the city issues the permit, or when
the applicant withdraws it. Those are the only two outcomes, and an application reaches
at most one of them.

### Rule 2. A department records a position, and can change it

While the application is open, a department can record an approval, or record that it
wants changes. A department that already recorded one can record the other instead, as
often as it likes. A position is a current opinion, not a promise. A department that has
recorded nothing holds neither.

### Rule 3. The city issues, and only under unanimity

Issuing the permit is an act of the city. The city can issue only while the application
is open, and only when every department is holding an approval at that moment.

### Rule 4. Issuing is a step of its own

Unanimity lets the city issue. It doesn't make the city issue.

So the process has states where every department has approved and the permit hasn't
issued. The city can sit in one of those states for as long as it likes, and the rest of
the world keeps moving while it sits there. A department can drop its approval and ask
for changes instead. The applicant can amend, or withdraw. Approval doesn't latch, and
reaching unanimity once doesn't hold the application at unanimity.

### Rule 5. An amendment resets the review

While the application is open, the applicant can amend it. An amendment produces a new
version of the application. Every position recorded against the old version is thrown
away, so right after an amendment no department holds an approval. Each department has to
review the new version from scratch.

The applicant can amend at most a fixed number of times. Past that bound, amending isn't
available. The bound is part of the process the city runs. It isn't a device for keeping
the model finite.

### Rule 6. The applicant can withdraw

While the application is open, the applicant can withdraw it.

### Rule 7. An outcome is the end

Once the permit is issued, or the application withdrawn, nothing else happens. No
department records or changes a position. The applicant neither amends nor withdraws. The
city doesn't issue. Every action above is available only while the application is open.

## The vocabulary your answers are written in

The spec defines an observation operator. It's already there, and you don't change it.

```tla
Observe == [ issued     |-> ...,
             withdrawn  |-> ...,
             approvedBy |-> ... ]
```

- **issued**: TRUE when the city has issued the permit.
- **withdrawn**: TRUE when the applicant has withdrawn the application.
- **approvedBy**: the set of departments holding an approval of the current version.

Write your answers over `Observe` and over `Departments`. Don't reach for the spec's own
variables. The point of the operator is that it survives a change of representation, and
an answer that reads the variables underneath doesn't.

Write conjuncts that hold for any `Departments` and any amendment bound. The three
departments in the config are one instance, not the specification.

## What to hand in

For each thing the spec fails to say, one TLA+ conjunct over `Observe` that states the
missing requirement.

Don't hand in a trace. TLC builds the counterexample out of your conjunct, which is the
point of writing one.

**Notes.** Put anything else you noticed at the end, under a `Notes` heading. Notes don't
score. Write them anyway.

## How each conjunct is checked

Two runs, and your conjunct has to survive both.

1. **Against the spec you were given.** TLC has to find a behavior that violates it. That
   counterexample is the evidence the requirement really is missing.
2. **Against a correct spec of the same process.** It has to hold.

A conjunct that fails both runs isn't an answer, and neither is one that holds in both.
`~Observe.issued` is the cheap way to get run 1, and it dies on run 2, because a correct
spec issues permits. Run 2 is what separates a missing requirement from a true sentence
about the process.

## Time

20 to 40 minutes, if you've read the learntla.com core material.
