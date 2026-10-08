# The posted plate

A land office keeps a register of plots. Before it enters a plot, it wants to
know the man applying really holds the ground he says he holds. Asking him
proves nothing, and a deed can be forged. So the office does something cheaper.
It issues him a numbered plate and tells him to nail it to his plot's gate,
where anyone can read it from the road. Then the office goes out and looks.

Looking is the part that gives trouble. The plate is up but the gate has swung
back against the wall. A hay wagon stands in front of it. The man nailed it on
yesterday and the office rode past the day before. None of that means the plate
isn't there, so the office goes back. It keeps a defect list against each
applicant, and each fruitless visit puts a line on it. When the office has had
enough it gives up, and giving up is what turns a man down.

Model this, and establish the nine requirements below. The rules fix what
happens. How you model it is up to you: your state, your steps, TLA+ or
PlusCal. The one fixed point is the interface, a single operator the checker
reads.

Plan on 25 to 45 minutes if you've read the learntla core chapters. You don't
need to know anything about land registration. Every rule the office follows is
stated here.

## What you get

This statement: the rules, the office's own diagram, the interface, and the
nine requirements. No model ships, and no reference runs ship either. You write
the model, and you write one check of your own besides the nine. The last
section says which.

## Your task

1. Model the system below, in whatever state shape you like.
2. Define `Observe` over your state, with the three fields the interface fixes.
3. Write each of the nine requirements as a formula over `Observe`, and declare
   it in your `.cfg` under the keyword the requirement names.
4. Run TLC at the checking instance.
5. Write a tenth formula, the one the last section asks for, and run it by
   itself.

A model can be wrong in two directions, and only one of them turns a check red.
Allow a step the rules forbid, and a requirement breaks with a trace to show
for it. Forbid a step the rules allow, and every check stays green over a
system that no longer exists. The whole business of going back and looking
again is a loop, and a model that never turns the loop will pass a great many
things. The office going back a second time is a claim that some run reaches a
state. None of the nine is a claim of that kind, so the tenth formula is the
only thing here that can go looking for it.

## The system

**The parties.** Two kinds act, and they act independently.

- **The office**, one. It visits a plot, writes defect entries, gives up,
  allows and refuses. Nobody else does any of those.
- **The applicants**, a fixed finite set named by the constant `Applicants`.
  Each has one plot, one numbered plate, and one page in the register. An
  applicant can send word that his plate is up, and that's the whole of what
  he can do.

Nothing coordinates them. Any applicant's step can land between any two of the
office's. There's no clock and no calendar here. The office's riding schedule
is its own business, and nothing in this system measures how long it waits
between visits or how fast it answers a letter. Nothing happens except by a
party's own act.

### Rule 1. The applicants and the plates

`Applicants` is fixed and named up front. The office has already issued each
man his plate before the story opens, so no step here issues one. The plate
nailed to the gate is the whole of the proof, and the office never asks who
nailed it up.

At any moment an applicant stands in one place on the register and one only:
his plate issued and no word back, under inspection, allowed, or refused. Every
applicant starts with his plate issued and no word back.

### Rule 2. Word that the plate is up

An applicant sends word to the office that his plate is up. He sends it when he
chooses. The first word he sends moves him from plate-issued to under
inspection, and the office starts going out to look.

He can send the same word again, as often as he likes. Later word changes
nothing about where he stands, what's on his defect list, or whether the office
has given up on him. Later word is how he asks the office to come back, which
is the thing to do once he's shifted the hay wagon.

He ought to hold off sending word until he believes the office's visit will
find the plate. Nothing here holds him to that.

### Rule 3. Visits

The office visits an applicant who stands under inspection and whom it hasn't
given up on. A visit either finds the plate or doesn't. A visit that finds it
moves the applicant to allowed.

Within one inspection the office can visit more than once. How often it goes
back is its own business, and nothing here fixes a number of visits it has to
make.

The office's standing orders allow it `Patience` fruitless visits to any one
applicant, and it makes no more than that. Reaching the number settles nothing
by itself.

### Rule 4. The defect list

The office adds an entry to the applicant's defect list after each failed
visit. An entry says what went wrong, so the man can tell what to fix. The list
only grows, and nothing takes an entry off it.

When the office turns a man down it ordinarily writes an entry saying why.

### Rule 5. Giving up

The office gives up on an applicant when it chooses. Nothing forces it and no
period runs out. Once it has given up it makes no further visit to that man,
and it never takes a give-up back.

While the office is still going back, the applicant stands under inspection.
He's marked refused only once the office has given up on him.

### Rule 6. What an entry on the list means

An applicant with any entry on his defect list stands refused.

### Rule 7. Settled is settled

An applicant who stands allowed or refused stays there. The office doesn't
reopen him, later word from him moves nothing, and no further visit changes
him.

### Rule 8. The opening

Every applicant stands with his plate issued and no word back. No defect list
carries an entry. The office has given up on nobody.

### Rule 9. Nothing has to happen

An applicant need never send word. The office need never visit, need never give
up, and need never allow or refuse anybody. It can leave a man under inspection
forever. Nothing in this system must eventually happen. So none of the nine
requirements says "eventually", and a fairness conjunct that drives the office
along is modeling a different office.

### The handbook's diagram

The office's handbook prints the same machine as a drawing, on the page facing
the rules.

```
             issued
                |
                | Word
                | received
                V
            inspecting <-+
                |   |    | Office revisit or
                |   |    | applicant revisit request
                |   +----+
                |
                |
    Successful  |   Failed
         visit  |   visit
      +---------+---------+
      |                   |
      V                   V
    allowed            refused

              Standings on the register
```

## The interface

The checker never looks at your state. It evaluates one operator, `Observe`,
which your module defines over whatever state you chose. Each field is a fact
about the inspection right now, the kind the office could read off its own
page.

```tla
Observe == [standing |-> ..., defects |-> ..., givenUp |-> ...]
```

- **standing**: for each applicant, where he stands on the register now.
- **defects**: for each applicant, how many entries stand on his defect list.
- **givenUp**: for each applicant, whether the office has given up on him.

The shapes are load-bearing, because the checker compares values. A renamed
field, a fourth field, or a different spelling doesn't fail a check. It keeps
the check from ever running.

- `Observe.standing` is a function from `Applicants` to the four standings,
  spelled exactly like this:

```
"issued"   "inspecting"   "allowed"   "refused"
```

- `Observe.defects` is a function from `Applicants` to a natural number.
- `Observe.givenUp` is a function from `Applicants` to a boolean.

`"issued"` is where a man stands when his plate is up and no word has reached
the office. It's a standing like the other three, not a missing value, so every
applicant carries one of the four at every moment.

The defect list reaches `Observe` as a count and not as the entries themselves.
What an entry says never gets into the register's reading, so no requirement
below can see it. Model the entries if you like. The count is what's watched.

`Observe.givenUp` is the office's note to itself. The man outside never sees
it, and it sits on the register's page because the office reads its own file.

Behind the operator the state is your own. Keep whatever you like, and let
`Observe` render it as the three facts above.

## The requirements

Nine requirements. Each is a claim about every run of this system, and a
correct model satisfies all nine. Each one names the TLC keyword it goes under
and what kind of formula it is. None names a subscript.

1. **An entry on the list means refused.** Whenever an applicant has one or
   more entries on his defect list, he stands at `"refused"`.

   `INVARIANT`. A claim about a single state.

2. **Refusal waits for the give-up.** Whenever an applicant stands at
   `"refused"`, the office has given up on him.

   `INVARIANT`. A claim about a single state.

3. **A failed visit leaves him under inspection.** At a step where an
   applicant's defect count rises, and the office hasn't given up on him after
   that step, he stands at `"inspecting"` before the step and at `"inspecting"`
   after it.

   `PROPERTY`. An action property.

4. **One visit, one entry.** At a step, an applicant's defect count either
   stays where it is or rises by one. It never rises by more, and it never
   falls.

   `PROPERTY`. An action property.

5. **Word comes first.** At a step where an applicant moves off `"issued"`, he
   moves to `"inspecting"` and nowhere else.

   `PROPERTY`. An action property.

6. **A visit is what settles him.** At a step where an applicant moves off
   `"inspecting"`, he becomes `"allowed"` or `"refused"`.

   `PROPERTY`. An action property.

7. **Settled is settled.** At a step, an applicant standing at `"allowed"` or
   `"refused"` stays where he is.

   `PROPERTY`. An action property.

8. **A give-up stands.** At a step, an applicant the office has given up on is
   still given up on after it.

   `PROPERTY`. An action property.

9. **The office takes one applicant at a time.** At a step where one
   applicant's standing changes, every other applicant's standing stays where
   it was.

   `PROPERTY`. An action property.

A type invariant of your own is fine, and it isn't one of the nine. Rule 3
bounds the defect count at `Patience`, and that bound is yours to state if you
want it.

### Where a step rule is watching

Where a requirement constrains steps, the subscript is yours to choose. A step
rule is only tested at steps that change what its subscript watches. Watch one
field, and every step that changes only the other fields satisfies the rule for
free. TLC won't warn you. The property just stops seeing the steps it was
written about and goes on reporting green.

So each rule has to watch a field that every step breaking it would move. Take
requirement 7. A step that moves a settled man breaks it, and such a step
moves his standing, so a subscript watching only the defect count never sees
it. Work the same question for each of the seven step rules.

## Checking

Check at two applicants and a patience of two:

```
Applicants = {a1, a2}
Patience   = 2
```

Two applicants is the least that shows one man allowed and another refused in
the same reading. It's also the least that gives requirement 9 anything to be
wrong about, because the per-man rules all need a second man to leave alone.

A `Patience` of 2 is the least that lets a second fruitless visit happen. At a
patience of one the office is out of orders the moment it has looked once. The
loop never turns twice, and the thing the whole inspection is built around
never shows up in a run.

Run TLC with deadlock checking off. The flag is `-deadlock`, and despite its
name it turns the check off. The end of the story is every man allowed or
refused, and the office can also come to rest with a man under inspection and
its patience spent. Nothing is enabled at either, and the system stops. That
stall is the design working, not an error.

No distinct-state count is quoted here, and none of the nine says how far your
model reaches. The tenth formula is where that gets checked.

## What to deliver

- Your module and the `.cfg` you checked it with.
- A tenth formula, with the run you made of it and the result.
- A line or two on what that result says about your model.

Every one of the nine is an upper bound, and a system where nothing happens
satisfies every upper bound there is. So none of them asks whether your office
ever goes back, and none of them can answer it either. The tenth formula is the
one that asks.

Write a formula that's false the moment the office goes back to a man it has
already put an entry against. Working out what that looks like on the register
is part of the job, and `Observe` has three fields to say it with. Declare it as
an `INVARIANT` and run it on its own, not beside the nine.

Then say which way TLC called it. Either answer is a fact about your model, and
the line or two is where you say which fact you got.
