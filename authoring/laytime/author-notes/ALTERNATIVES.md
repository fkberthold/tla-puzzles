# Alternatives considered (laytime reference)

Author-only note per V2-PLAN §9.4, written after the reference went green. It
records the state representations I weighed and why the shipped one won.

## What shipped

Four variables: `noticeTendered`, `laytimeLeft`, `demurrage` and `finished`.
`Observe` renders as the identity over them, field for field. The state is the
interface, and there's nothing sitting behind it.

## A variable for the mode

The strongest rival, and the one I spent longest on. Carry a fifth variable
holding "laytime" or "demurrage", flip it when the allowance empties, and let
each logging step read the mode instead of testing the counter.

I rejected it on two counts. The mode is `laytimeLeft = 0` and nothing else, so
the variable is a cache of a test that costs nothing to run. A cache can go
stale, and a model that lets this one go stale takes a step no property here can
see, because the mode isn't an `Observe` field. The second count is the rung.
The reference's variables are the `Observe` fields and no others, and a fifth
variable would move the problem up a level on representation before its turn.

I think the mode is also the whole question the problem asks. The learner either
sees the latch already sitting in the counter, or invents state for it. Writing
the variable into the reference answers that on the reference's own page.

## A log of periods

Hold a sequence of logged periods, each one tagged working or excepted, and
derive both counters from it. This is closer to what a laytime statement really
is. The statement is a document, and the document is the log.

Rejected because the counters are what the statement records and the log is only
how they got there. The four fields carry every fact a property here reads. So
the sequence buys history that nothing looks at, and it grows the state space by
the order of the periods rather than by what they cost. `Observe` would also
turn into a derived view over the log instead of a plain record over state.

## One counter, running negative

Keep a single integer starting at `Allowance` and let it run down past zero. The
allowance left is the positive part, and the demurrage accrued is whatever sits
below zero. One variable, and Rule 7's no-split clause holds by construction.

That last part is why I dropped it. Both `Observe` fields become projections of
one number, so "the two never move in the same step" can't fail inside the
model. Must-be-true 2's third clause stops being a claim about anything. My
mutant probe on the working-period step leans on that clause. A representation
where an obligation can't break is a representation that hides it.

## Several labels, and `pc`

The shipped PlusCal is one label inside a `while (TRUE)`, which is what keeps the
translator from emitting `pc`. The natural alternative is a label per step, or a
process body that tenders, then loops, then closes.

Rejected for the same reason as the mode variable. `pc` is a variable, it isn't
an `Observe` field, and the rung says the reference carries no others. The single
label costs nothing here, because every step is one atomic write to the
statement and there's no partial state to name.

## The excepted period that moves nothing

While the allowance stands, an excepted period changes no field. Under `Observe`
that's a stutter, and dropping the branch would lose no behavior.

I kept it. It's Rule 5, and the reference should say what the agent can do rather
than only what the statement records. The description already says this half of
Rule 8 is graded by nothing, so the branch is there for the reader and not for
the checker. The cost is a few self-loop edges, and they land in TLC's generated
count rather than its distinct one.

## The cap as a guard, not a constraint

Rule 9 stops the agent logging once the demurrage claim reaches `Limit`. I put
that in the guard on both logging steps. The alternative is a `CONSTRAINT` line
in the cfg, which cuts the search at the same place and leaves the model itself
unbounded.

I went with the guard because the cap is a term of the charter. A constraint says
the checker stopped looking, and a guard says the agent stopped writing. Only one
of those is true here.
