# Museum exhibit loans with conservation limits: system description

This is the input to the reference-solution author (V2-PLAN.md §9.4). It fixes the
system and leaves the representation open (§3.2). It is not the learner statement.
The statement author works from the frozen spec later, not from this file.

Grid cell: task shape A, in a situation of time, accrual, and custody.

## 1. The system

A museum (the **lender**) owns a small collection. Other institutions (**borrowers**)
put on exhibitions and ask to show pieces from it. A registrar at the lender answers.
Light damages an object while it hangs, the damage never heals, and the lender's
conservation policy caps it and forces rest between showings.

**The parties.** Three kinds of party act, and they act independently.

- The lender's **registrar**, the only party that moves objects or answers requests.
- A fixed, finite set of **borrowers**, named by `Borrowers`.
- A fixed, finite set of **objects**, named by `Objects`. Objects don't act, but every
  rule below is about them.

Nothing coordinates the parties. Any party's next step can land between any two steps
of another party.

### Rule 1. The calendar

The lender publishes a loan calendar of `Horizon` numbered seasons. Seasons follow one
another in order. No party's action drives a season forward, and no season waits for
anyone. Everything in this system happens inside the published calendar.

### Rule 2. Custody

At any moment each object has one holder, and only one: the lender, or one borrower.
Every object starts with the lender. A loan is the only thing that moves custody out,
a return is the only thing that moves it back, and title never moves. A borrower can
hold several objects at once, each under its own loan.

### Rule 3. Display, and how the policy counts it

An object is **on display** when it hangs in the lender's own gallery, or for the
whole of any time it is away on loan, whatever the borrower does with it. The policy
counts in whole seasons: if an object is on display during any part of a season, that
season counts as one season of display for that object.

Both roundings are deliberate. The policy book charges the worst case instead of
tracking install weeks and dark storage at the borrower's end. Real lenders meter
light more finely than this. This system doesn't, and says so.

### Rule 4. The light budget

Each object has a lifetime budget of `Budget` seasons of display. A season of display
spends one season of the budget, and nothing ever refunds it. The lender never lets an
object be on display in more seasons than its budget holds. An object whose budget is
spent never hangs again, and, since time away counts as display, never leaves again
either.

### Rule 5. Rest

When an object comes off display, rest starts. Before the object is on display again,
at least `Rest` whole calendar seasons must pass with it off display throughout. Rest
belongs to the object, not the venue. Coming off the lender's own wall and going
straight out on loan breaks it just as two back-to-back loans would. An object that
has never been displayed owes no rest.

### Rule 6. Requests

A borrower with no request outstanding can ask for one object, for a stated whole
number of consecutive seasons, from one up to `MaxTerm`. Each borrower has at most one
request outstanding at a time, and a request sits until the registrar answers it. The
registrar can decline any request at any time. A decline frees the borrower to ask
again, for the same object or another.

### Rule 7. Granting

The registrar can grant an outstanding request only when all of these hold at that
moment:

- the object is with the lender, off display
- its rest is done, or it has never been displayed
- its remaining budget covers the full term asked
- the term fits inside what is left of the calendar

The budget check charges the whole asked span at the moment of decision. An early
return spends less, but it never earns the decision back.

A grant takes effect at once. Custody passes to the borrower, the loan's span runs
from the current season through the asked number of seasons, and the request is
answered. Policy permitting a loan never compels one. The registrar can sit on a
grantable request for as long as it likes, or decline it.

### Rule 8. The loan runs, and ends

For the whole time away, the object counts as on display. The borrower can send it
back in any season of the span, and it must be back with the lender by the end of the
span's last season. Borrowers honor the span. Late return doesn't happen in this
system. A return puts the object in the lender's store, off display, and its rest
starts. Handover is immediate: no courier, no crate, no transit.

### Rule 9. The home wall

The lender shows its own collection too, under the same policy. The registrar can hang
an object that is with the lender, off display, rested (or never displayed), and with
budget left for the season it would hang into. The registrar can take it down at any
time, and take-down starts rest. There's no span and no agreement at home. What forces
a home take-down is the budget: the object must come down before it would be on
display in a season the budget can't cover.

### Rule 10. The calendar closes

By the end of the last season, every object is back with the lender and off display.
After the last season ends, nothing further happens. No requests, no answers, no
hangings, no loans. The story this system tells is the published calendar, and it ends
with the collection home and dark.

## 2. What must be true

A correct model satisfies all of these. They're stated in English here, over the
observables of section 3, and central renders them later.

1. **Budget.** At every moment, the count of seasons in which an object has been on
   display is at most `Budget`.
2. **Retirement holds.** Once an object is off display with its budget fully spent, it
   never appears on display again.
3. **Rest.** Whenever an object that has been displayed before begins display in some
   season, at least `Rest` whole seasons lie strictly between that season and the last
   season it was displayed in.
4. **Custody.** Every object has one holder at a time, and an object away from the
   lender counts as on display for as long as it's away.
5. **Terms.** An object with a borrower is never in a season past the last season of
   its agreed span. No span is longer than `MaxTerm`, and none runs past the calendar.
6. **Consent.** Custody passes to a borrower only in answer to that borrower's own
   outstanding request, for that object, for the term the request named.
7. **Closure.** Once the calendar has closed, every object is with the lender, nothing
   is on display, and nothing observable ever changes again.

Items 1, 4, 5, and the first two clauses of 7 are invariants. Items 2, 3, 6, and the
tail of 7 constrain steps, so they'll land as action properties. The learner path
covers action properties before this cell (V2-PLAN.md §3b, learntla ch.11).

## 3. The observation operator

The operator is named `Observe`. Each field below is a fact about the system at the
current moment, the kind a conservator could read out of the object's file. Do not
render these as TLA+ here. Central renders the operator, one field per line, each
field an expression over the state.

**season**: the calendar season now in progress, or a closed marker once the last
season has ended. Needed because every duration rule counts in seasons, and closure
(must-be-true 7) needs the calendar's stage.

**custodian**: for each object, who holds it now, the lender or one borrower. Needed
for custody, consent, and closure (4, 6, 7).

**onDisplay**: the set of objects on display right now, at home or away. Needed for
budget, rest, retirement, and the away-counts-as-display coupling (1 through 4).

**spent**: for each object, in how many calendar seasons it has been on display so
far, any part of a season counting. Needed for the budget cap and retirement (1, 2).

**lastLit**: for each object, the latest season in which it was on display, or a
none marker if it never has been. Needed because the rest rule is a gap between this
and the next display (3).

**dueBack**: for each object away, the last season of its agreed span, and a none
marker at home. Needed for terms, `MaxTerm`, and calendar fit (5, 6). Without it,
Rules 7 and 8 would be invisible at the graded interface, which is the pilot's
under-exposure failure repeated.

**asking**: for each borrower, its outstanding request (which object, how many
seasons), or a none marker. Needed for consent and the request-shape rules (6).
Without it, Rule 6 would be invisible.

**What the fields do and don't constrain.** A field says what must be reportable from
the state, not what the state is. A model that keeps its books another way must still
be able to answer each question from its own state, and that's the whole demand. Don't
read `spent` and `lastLit` as two counters the model must store, and don't read the
absence of an episode-history field as a ban on storing one. I left a per-episode
history field out on purpose: exposing one would force the history representation and
close a fork.

**The mid-episode subtlety.** `spent` is a fact about the past. The moment an object
hangs in season s, season s counts, and every model must report it as counted from
that state on. When a model writes its own internal ledger is its own affair, but the
reported fact can't lag. This is what keeps grading neutral between the two accrual
mechanisms in section 5.

**Sufficiency walk.** I walked all ten rules and all seven must-be-trues against the
fields.

| Must-be-true | Reads |
|---|---|
| 1 Budget | spent |
| 2 Retirement | spent, onDisplay |
| 3 Rest | season, lastLit, onDisplay |
| 4 Custody | custodian, onDisplay |
| 5 Terms | season, custodian, dueBack |
| 6 Consent | season, custodian, dueBack, asking |
| 7 Closure | season, custodian, onDisplay, and the record as a whole |

Every rule lands on at least one field: Rule 1 on `season`, Rule 2 on `custodian`,
Rule 3 on `onDisplay` and `spent`, Rule 4 on `spent`, Rule 5 on `lastLit` and
`season`, Rule 6 on `asking`, Rule 7 on `asking`, `custodian`, and `dueBack`, Rule 8
on `custodian`, `dueBack`, and `onDisplay`, Rule 9 on `onDisplay`, `spent`, and
`lastLit`, Rule 10 on `season`, `custodian`, and `onDisplay`. Every field earns its
place through at least one must-be-true, so nothing here is decoration.

## 4. Bounds

TLC must check the suggested instance exhaustively in well under 60 seconds. Every
bound below is a fact of the system first and a finiteness device second, and each one
already appears inside a rule the model must enforce as behavior. That's the pilot's
amendment-bound lesson applied up front: no bound hides in an action for the statement
to discover later.

- **`Objects`, `Borrowers`**: the collection and the peer institutions. The config
  picks one instance. The rules hold for any.
- **`Horizon`** (Rule 1): the published calendar. In this world nothing is agreed
  beyond what the lender has published, so the bound is the calendar itself.
- **`Budget`** (Rule 4): the policy's lifetime display budget. Real practice budgets
  cumulative exposure over an object's life, in lux-hours as far as I know. This
  system simplifies the unit to whole seasons, and Rule 3 says so.
- **`Rest`** (Rule 5): the policy's mandated rest between showings.
- **`MaxTerm`** (Rule 6): the lender's cap on a single loan term.
- **One request per borrower** (Rule 6): how these borrowers work here. Surfaced as
  resolved ambiguity 7 below.

**Suggested instance**: 2 objects, 2 borrowers, `Horizon` 6, `Budget` 3, `Rest` 1,
`MaxTerm` 2. Each bound bites at these values. Two max-term loans spend 4 seasons
against a budget of 3, so the budget refuses something. Rest 1 blocks the
back-to-back showing that would otherwise fit. MaxTerm 2 under Budget 3 lets an
object go out more than once. Horizon 6 holds loan, rest, loan (2+1+2 seasons) with
one to spare for interleaving.

I expect the reachable count between 10^4 and 10^6 states, which TLC clears in well
under a minute. INFERRED. The verifier's step 6 counts settle it. If it runs long,
shrink `Horizon` first, then `Objects`.

**Quiescence.** The closed calendar is the intended end of every behavior. A checker
reporting deadlock in that state is reporting the design working. The reference
author should handle that in the config, not by inventing a stuttering action the
system doesn't have.

## 5. Open forks

The probe found more than one sensible model here, and this description is written to
keep it that way. Each line below is a choice the rules don't make.

- **Exposure**: a running total per object, or a history of display episodes. The
  rules need a total and a latest season, and both carry them.
- **Time**: a marching season counter, span records with endpoint seasons, or an
  ordered run of season events. The rules count in calendar seasons and never name a
  clock.
- **Rest**: a deadline (the first season the object may hang again) or an explicit
  resting state. The rule is a gap, not a mechanism.
- **Accrual**: charge the ledger season by season while the object hangs, or in one
  move when the episode closes. The observables are facts about the past, and both
  mechanisms can report them.

One more, beyond the probe's list: **retirement** as a stored status or as a fact
derived from a spent budget. The rules state the fact and never the flag.

## 6. Ambiguities resolved, and how they could have gone

The pilot's author settled six of these silently and every one turned into downstream
risk. These are mine, in the open.

1. **Transit.** Handover is immediate. A transit phase (away, off display, uncharged)
   would deepen the custody story and grow the state. I cut it, and Rule 3's
   worst-case counting stands in for it.
2. **What the borrower does with the object.** All time away counts as display. The
   other choice lets the borrower control display inside the loan window, with dark
   weeks uncharged. I folded that into the policy's worst-case accounting instead.
3. **The grain of time.** Whole seasons, rounded against the object. The other choice
   is weeks or lux-hours, which is closer to real practice and much bigger as a state
   space.
4. **Whose rest.** Rest belongs to the object across venues. The alternative scopes
   rest to loans only, so home display and loans keep separate books.
5. **One sensitivity class.** The same `Budget` and `Rest` for every object. Real
   collections class objects by sensitivity (works on paper against bronze). Per-class
   constants would multiply the config for no new modeling question.
6. **No renewals.** A loan never extends. A second showing needs a new request, and
   the rest rule forces a gap between them anyway.
7. **Request discipline.** One outstanding ask per borrower, no withdrawal by the
   borrower, decline only by the registrar. Queues, withdrawal, and priority were all
   available. I kept them out to keep this system away from allocator dress, which is
   where the probe's neighbor domains (library holds, standby lists) already sit
   (V2-PLAN.md §2.2 pre-screen table).
8. **Worst-case commitment.** The registrar charges the whole asked span at grant.
   The optimistic alternative grants tighter and recalls on overrun, and recall is a
   whole protocol this cell doesn't need.
9. **Initial state.** All objects start home, dark, unexposed, owing no rest. Objects
   arriving with prior histories would push `Budget` and last-displayed facts into
   the config as per-object inputs.
10. **Late return.** Doesn't exist. Borrowers honor the span. Breach and recovery
    would add fallibility and agency, worth revisiting if this domain ever fills a
    column-D or column-F cell, but not needed for shape A.
