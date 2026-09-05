# An executor's notice to creditors

System description for the reference-solution author (V2-PLAN §9.4). It fixes the
system and leaves the representation open (§3.2). It is not the learner-facing
statement, and nothing in it is worded for a learner.

Sections 1 to 4 are the hand-off: paste them into the §9.4 brief as the
`<system description>`. Sections 5 and 6 are pipeline notes for central. Keep
them out of the author's brief and out of anything downstream of it.

Grid cell: task shape A, in a situation of a closing window before an
irreversible payout.

## 1. The system

Someone has died. The person who winds up their affairs is the **executor**. She
gathers what the dead person owned, pays what the dead person owed, and hands the
rest to the people named in the will. Those people are the **beneficiaries**, and
they're outside this system. The problem the executor has is that she can't know
who's owed money. A debt she's never heard of is still a debt, and if she pays
the beneficiaries first she can end up paying it out of her own pocket.

Her answer is a public notice. She advertises that she's winding up the estate
and invites anyone owed money to come forward. She closes the notice when she
chooses. After that, a creditor who never came forward has lost his claim
against her, though not his money: he can go after the beneficiaries instead.
The debt doesn't vanish. It moves. Nothing below needs any law that isn't
stated here.

**The parties.** Two kinds act, and they act independently.

- The **executor**, one. She closes the notice, decides claims, pays them, and
  distributes the residue. Nobody else does any of those.
- The **creditors**, a fixed finite set named by `Creditors`. Each is owed money
  by the estate. A creditor can lodge a claim, or come forward out of time, and
  that's the whole of what he can do.

Nothing coordinates them. Any creditor's step can land between any two of the
executor's. There's no clock and no calendar. Nothing in this system happens
except by a party's own act.

### Rule 1. Creditors and claims

`Creditors` is fixed and named up front. Each creditor is owed something, and the
system never asks how much. A claim is one creditor's assertion that the estate
owes him. He makes it once or not at all. There's no second claim, no amendment,
and no withdrawal. At any moment a creditor stands in one place and one only:
nothing lodged, lodged and undecided, admitted, admitted and paid, rejected, or
out of time. Every creditor starts with nothing lodged.

### Rule 2. The notice

The executor advertises one notice. It stands open from the start. She closes it
when she chooses, and closing it is her act alone. Nothing else closes it, no
period runs out, and it never reopens.

### Rule 3. Lodging

While the notice stands open, a creditor who has lodged nothing can lodge a
claim. He lodges because he chooses to. No claim arrives on its own, and the
executor can't lodge one on his behalf. A lodged claim sits with her until she
decides it.

### Rule 4. Out of time

Once the notice is closed, a creditor who never lodged can still come forward. He
comes forward against the beneficiaries and not against the executor, so his
coming forward is never a claim she has to answer. He's out of time, and out of
time is where he stays. Whether the beneficiaries pay him is their business and
this system doesn't watch it.

### Rule 5. Admitting and rejecting

The executor can admit a lodged claim or reject it. She can do either while the
notice is open or after she's closed it. She takes one claim at a time, in
whatever order she likes. A decision is final. She never rejects what she
admitted and never admits what she rejected.

### Rule 6. Paying

The executor pays a claim she has admitted. Payment is its own act and it comes
after the admission, never in the same motion. She never pays a claim she
rejected, a claim still undecided, a claim nobody lodged, or a creditor who's out
of time. What's paid stays paid.

### Rule 7. Distributing the residue

The executor hands what's left to the beneficiaries. She can do that only when
the notice is closed and every claim lodged with her is either rejected or paid.
Distributing happens once. There's no partial distribution, no interim payment,
and no way to call it back. At the start the residue is still in her hands and
nothing has been distributed.

### Rule 8. After the distribution

Once the residue has gone, the executor is finished. Every claim she holds is
settled and the notice is shut against new ones, so there's nothing left for her
to do. A creditor who never lodged can still come forward out of time, and now
the beneficiaries are the ones holding the money.

### Rule 9. What must happen, and what needn't

The estate has to be wound up. The executor may take her time over any single
step, but she can't sit on the whole business forever, and the residue reaches
the beneficiaries in the end. That's the one thing in this system that must
happen. A creditor owes nobody anything. He need never lodge and need never come
forward, and nothing here obliges him either way.

## 2. What must be true

A correct model satisfies all of these. They're stated in English here, over the
observables of section 3. The author renders them as properties of their model.

1. **She distributes only when she's clear.** Whenever the estate has been
   distributed, the notice is closed and every claim lodged with the executor is
   either rejected or paid.
2. **A claim starts with the creditor, inside the window the notice sets.** At a
   step where a creditor moves off nothing lodged, he moves to lodged if the
   notice was open before that step, or to out of time if the notice was closed
   before it. He moves nowhere else.
3. **A lodged claim ends only in her decision.** At a step where a lodged claim
   changes, it becomes admitted or rejected.
4. **A decision stands.** At a step, an admitted claim stays admitted or becomes
   paid. A rejected claim, a paid claim, and a creditor out of time never change
   again.
5. **The notice never reopens.** At a step, a closed notice stays closed.
6. **The distribution is never undone.** At a step, a distributed estate stays
   distributed.
7. **The estate is eventually distributed.**

Item 1 is a claim about a single state, so it's an invariant. Items 2 through 6
each compare the record at two consecutive moments, so they constrain steps and
land as action properties. Item 7 is the one liveness obligation here, and it's
the only item needing "eventually". Its fairness sits on the executor's steps and
on none of the creditors', which is Rule 9 stated as a fairness decision. Four of
her steps carry a conjunct each: closing the notice, deciding a named creditor's
lodged claim, paying a named creditor's admitted claim, and distributing. Naming
them one at a time matters, because fairness written over a disjunction of her
actions obliges none of them in particular. Item 7 is false if any one of the
four is dropped.

Blanket fairness on the whole next-state relation would make item 7 true without
naming any of the four. Every action here permanently disables itself and
`Creditors` is finite, so the transition graph is a finite DAG. No terminal state
holds the residue, since if nothing else is enabled then distributing is. The
reference ships the four named conjuncts rather than the blanket form, which
would carry a lesson this system can't defend.

Every step rule is checked over the whole of `Observe`, never over one field.
Items 2 through 6 each name one field or two, and the subscript is still the
whole record.

The type invariant is the reference author's, declared in the cfg. It isn't one
of the seven above and it's never a learner requirement.

Each item breaks on a short finite trace, which is what §3.9 needs downstream.
Item 1 falls in a single state, the estate distributed with a claim still lodged
and undecided. Item 2 falls on one step, a creditor going from nothing lodged to
lodged while the notice is already closed. Item 3 falls on one step, a lodged
claim going back to nothing lodged. Item 4 falls on one step, an admitted claim
turning rejected. Items 5 and 6 each fall on one step, a closed notice reopening
and a distributed estate coming undone. Item 7 is liveness, so its violating
trace is a finite prefix and then nothing more: the notice open, no claim lodged,
and the executor never closing, with the behavior stuttering there forever. Each
of the seven is satisfied by an ordinary run of the system.

Seven items plus the type invariant is eight cfg lines, and that's the whole of
what this system asks for. A ninth would be redundant against these seven rather
than new, so the author should hold the count where it is.

## 3. The observation operator

The operator is named `Observe`. Each field is a fact about the winding-up right
now, the kind the executor could read off her own file. The fields are given here
as named facts, not as syntax. The author renders them over whatever state they
chose, one field per line.

**standing**: for each creditor, where he stands with the executor now. Nothing
lodged, lodged and undecided, admitted, admitted and paid, rejected, or out of
time. Items 1 through 4 all read it, and without it none of them can be stated.

**notice**: whether the notice still stands open, or is closed. Needed for the
window in item 2, for the one-way door in item 5, and for the guard in item 1.

**distributed**: whether the residue has gone to the beneficiaries. Needed for
items 1, 6 and 7, and item 7 is stated over this field alone.

**Why the standings are one field and not several.** A creditor stands in one
place at a time, and this field is what makes that unrepresentable rather than
merely forbidden. A model that carried lodged, admitted, rejected and paid as
four sets could show a creditor in two of them at once, and then the one-place
rule needs a property of its own. I closed that here, at the cost of one degree
of the author's freedom. My read is that it's worth it, because the property it
would have bought grades the bookkeeping instead of the system. None of that bans
set-shaped state. A partition of `Creditors` into named sets is disjoint by
definition and computes `standing` fine. What's ruled out is four independent
sets that can overlap.

**Sufficiency walk.** The test in each row is which property constrains the rule,
never which field mentions it. A rule a field names and no property constrains is
loose. First, what each must-be-true reads:

| Must-be-true | Reads |
|---|---|
| 1 She distributes only when she's clear | standing, notice, distributed |
| 2 A claim starts with the creditor | standing, notice |
| 3 A lodged claim ends in her decision | standing |
| 4 A decision stands | standing |
| 5 The notice never reopens | notice |
| 6 The distribution is never undone | distributed |
| 7 The estate is eventually distributed | distributed |

Then each rule, against the properties that constrain it:

| Rule | Constrained by |
|---|---|
| 1 Creditors and claims | The six standings are the type invariant, which is a real cfg line and not a shape argument. One place at a time rides `standing`'s shape, since a creditor has one standing and nowhere to record a second. One claim each and no withdrawal are 3 and 4 together |
| 2 The notice | 5 for the one-way door, and 1 ties the close to the distribution. Who closes it is invisible at this interface, and the paragraph below says why |
| 3 Lodging | 2, both halves. The open window is 2's first clause, and 2's last clause is what stops a creditor appearing as lodged, admitted, rejected or paid without lodging first |
| 4 Out of time | 2 for the way in, which is closed-notice-only, and 4 for the finality. The debt moving to the beneficiaries has no observable at all, which is the point of putting them outside |
| 5 Admitting and rejecting | 3 for the only two outcomes, 4 for the finality. One claim at a time is ungraded, and the paragraph below says why |
| 6 Paying | 4, which makes admitted the only standing that turns into paid, with 2 and 3 shutting the other routes in |
| 7 Distributing | 1 for the guard, 6 for the one-way door |
| 8 After the distribution | 1 and 2 together, and it's a consequence rather than a line of its own. At the distribution no claim is lodged, and 2 keeps the closed notice against a new one, so nothing she can do is enabled |
| 9 What must happen | 7, and the absence of any other liveness property is what says the rest is hers to time. The creditors' freedom is the absence of fairness on their steps |

Two things are ungraded above, and I'd rather name them than let a reader find
them. The first is who acts. `Observe` shows the file, not the hand that wrote in
it. Who took a step is invisible at this interface, so "the executor closes the
notice" can't be a property of any model, whatever fields you add. What the
interface does carry is that the close happened and that nothing lodged after it,
which is items 5 and 2.

The second is one claim at a time in Rule 5. Nothing above stops a step deciding
two creditors together, since items 2, 3 and 4 hold for both of them. An action
property saying at most one creditor's standing changes at a step would catch a
batch model. It fits inside the band as a ninth line. I'd leave it for the
variant pass to ask for.

Everything else is constrained. Every field earns its place through at least one
must-be-true, so nothing in the operator is decoration.

## 4. Bounds

TLC must check the suggested instance exhaustively in well under a second. Every
bound is a fact of the system first and a finiteness device second.

- **`Creditors`**: the people the estate owes. The config picks one instance and
  the rules hold for any.
- **The six standings** (Rule 1): fixed by the rules, not by the config.
- **The notice as open or closed** (Rule 2): the system asks whether it stands,
  never how long it stood.
- **The residue as gone or not** (Rule 7): no amounts anywhere.

**Suggested instance**: 2 creditors. Two is the least that shows a paid creditor
and an out-of-time creditor in the same observation, which is the state the whole
notice exists to produce. It's also the least that shows one claim holding up the
distribution while another is already settled.

The arithmetic. With the notice open the estate can't have been distributed, and
no creditor can be out of time, so each of the two stands in one of five places
and that's 25 states. With the notice closed and the residue not yet gone, each
stands in any of six, so 36. With the residue gone, item 1 leaves each creditor
nothing lodged, rejected or paid at that moment, and out of time is reachable
after, so four places each and 16. That's about 77 reachable, well under 1,000 and
sub-second. It's an estimate. Nobody has run it. The same sum at three creditors
is about 405, which still fits, and at four it's about 2,177, which doesn't.

**Quiescence.** The end of the story is the residue gone, every lodged claim
settled, and every other creditor out of time. Nothing is enabled there and the
system stops. A checker reporting deadlock in that state is reporting the design
working, and the reference author should handle it in the config rather than by
inventing a stuttering action this system doesn't have.

## 5. Open forks

The learner writes the state here, so the forks are the problem rather than a
footnote to it. Each line below is a choice the rules don't make.

- **Standing**: one value per creditor, a partition of `Creditors` into named
  sets, or a set of claim records that carries the late creditor as a record too.
- **Payment**: a standing a claim reaches, or a separate ledger of who's been
  paid.
- **The notice**: a yes-or-no flag, a two-value stage, or the set of creditors
  still in time.
- **The residue**: a flag, or a stage the whole winding-up is in.
- **Out of time**: a standing the creditor reaches, or a separate came-forward
  marker read against a closed notice.
- **Creditor names**: model values, or numbers.

One narrowing for the reference author, and it's the rung rather than my choice.
The reference's variables are exactly the three `Observe` fields and it carries no
fourth. That rules out a PlusCal translation with processes or labels, because
the generated `pc` is a fourth variable and pushes the reference up a level on
representation. The reading gate is ch11, so the reference ships as plain TLA+
actions written inside the ch11 vocabulary. `authoring/buyclub/reference/BuyClub.tla:11`
is the shape, three variables and nothing else.

**The dropped candidate.** The screen report offered eight rules
(`authoring/estate-notice/reports/step0-screens.md:215-227`). Its rule 7, that
every claim lodged before the close is eventually paid or rejected, is implied by
my item 7 under the safety rules. Distributing needs every lodged claim rejected
or paid, and nothing can be lodged after the close, so an estate that eventually
distributes has settled every claim that ever existed. A redundant cfg line
teaches nothing, so it went. That leaves one liveness item, which is what property
kind 3 asks for. Its rules 2 and 3 merged into my item 1, since both are claims
about the same moment.

Two items are mine rather than the screener's, and both close holes. Item 2 is
the way in. Without it a creditor can appear as lodged after the close, or as
admitted without ever having lodged, and neither shows up in the screener's list.
Item 6 is the other one-way door. The screener graded the notice against reopening
and left the distribution ungraded, so an estate could be un-distributed and
nothing would catch it.

**A finding against the screener's route.** The report says blanket fairness is
the shortcut and that it makes the liveness property true without the learner
asking which party's stalling matters
(`authoring/estate-notice/reports/step0-screens.md:194-198`). I think it's worse
than that. Every action here permanently disables itself, and `Creditors` is
finite, so the transition graph has no cycle. A terminal state with the residue
still in hand doesn't exist, because if nothing else is enabled then distributing
is. So `WF_vars(Next)` alone makes item 7 true, and a learner who writes it hands
in a passing spec. The fairness question is real, and the statement is where it
has to be made to bite. Under form left open 1 the subscript is withheld, which
helps. The property it's withheld on is item 7, so the learner has to decide for
himself what its fairness sits on. My read is that the variant pass is where this
actually gets caught.

**A correction to the screener's reasoning, same page.** It says fairness on the
close is needed because creditors can keep lodging while the notice is open
(`authoring/estate-notice/reports/step0-screens.md:230-234`). Under Rule 1 each
creditor lodges once, so the lodging stops after two steps and can't hold the
close open. The conclusion survives, and the reason is simpler: the executor can
just never close, and distributing needs a closed notice. I've written Rule 9 to
carry that and left the creditors unobliged.

**The state estimate.** The screener gave 144 as a type-space count
(`authoring/estate-notice/reports/step0-screens.md:236-241`). Section 4's 77 is a
reachable estimate over the same instance, and neither has been measured.

## 6. Ambiguities resolved, and how they could have gone

1. **No money.** A claim is owed or it isn't. Real probate turns on whether the
   estate covers the debts, and an insolvent estate pays creditors in a statutory
   order. That's arithmetic and a priority rule, and priority is allocation, which
   this project's own screen treats as burned ground.
2. **No period.** The notice closes by her act. Real notices run a statutory
   period, and a period is a step this description would assign to no party. That
   takes step sources to the top level and breaks the rung outright.
3. **A fixed set of creditors.** Everyone is named up front and starts with
   nothing lodged. The alternative creates creditors as they appear, which needs
   an unbounded set and a different kind of bound in section 4.
4. **One claim per creditor.** No second claim, no amendment, no withdrawal. The
   alternative lets a rejected creditor lodge again with better evidence, which is
   real practice and which kills item 4.
5. **Coming forward late is the creditor's own act.** The alternative sweeps every
   creditor who hasn't lodged into out of time at the moment she closes. That's
   one step of hers changing several creditors at once, and it makes the late
   appearance her doing rather than his. It also removes the state this domain is
   for, a closed notice with a creditor still able to surface.
6. **The beneficiaries are outside the system.** Rule 4 says the debt moves to
   them and stops there. The alternative models them and what they hold, which is
   a second set of parties and a recovery protocol.
7. **Payment is its own act.** The alternative pays in the same motion as
   admitting. Then admitted and paid collapse, and Rule 6 becomes true by
   construction rather than something a step can get wrong.
8. **She can decide while the notice is still open.** The alternative makes her
   wait for the close. Waiting is tidier and it removes most of the interleaving
   between her steps and the creditors', which is the half of the rung that's new.
9. **Capacity.** She holds any number of claims at once and there's no cap. She
   takes one step at a time and decides one claim at a time, so no step ever
   settles two creditors together. The alternative is a batch decision, which
   collapses signatures and asks no new modeling question.
10. **Distribution is one act and it's total.** No partial distribution and no
    interim payment to a beneficiary. Interim distributions are real and they'd
    turn a flag into a running position.
11. **No appeal.** A rejected creditor has no route back. Real practice lets him
    sue, and a second forum is a whole other system.
12. **No obligation on the creditors.** Rule 9 says so in as many words, and it's
    a fairness decision rather than a safety one. Fairness on a creditor's lodging
    would oblige a party the domain says owes nothing.
13. **No opening item in section 2.** Every creditor starts with nothing lodged,
    the notice starts open, and nothing is distributed. The shipped spec's `Init`
    fixes all three. I considered an eighth item pinning it and left it out,
    because the count band has one line spare and I'd rather the reference author
    hold it than spend it here.
14. **The word "probate".** Real practice calls this a section 27 notice, after
    the statute. This file says notice to creditors, because the statute number
    means nothing without the statute and the phrase carries its own meaning.
