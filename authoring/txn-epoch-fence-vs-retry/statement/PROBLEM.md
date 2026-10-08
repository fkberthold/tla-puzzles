# The fire office

A dockyard runs hot work. Burning, welding and riveting on ships in the basins, and any of
it can start a fire in a hull nobody is watching. So none of it happens without a permit,
and the fire office issues them.

A gang that wants to cut steel comes to the desk. The desk raises a permit and enters it in
the gang's book. The gang does the work and brings the permit back signed off. If the job
falls through it brings the permit back surrendered instead. Either way the desk enters the
close, and the entry goes on the next leaf of the book.

The office's problem is a gang that walks off the yard with a live permit in its pocket.
The book then says hot work is under way in a hull with nobody standing over it. So the
fire watch goes round, finds the work abandoned, and reports it, and the desk withdraws the
permit itself. The gang isn't there to be told. It walks away still holding a card the desk
has moved past.

Model this, and settle the eight requirements below. Each one is a claim about every run of
the office's system. Some of them are true of it. Work out which, and for each one that
isn't, produce a run that shows it.

Plan on 30 to 45 minutes if you've read the learntla core chapters. You don't need to know
anything about dockyards. Every rule the office follows is stated here.

## What you get

This statement: the rules, the interface, and the eight requirements. No model ships, and
no reference runs ship either. You write the model, and the rules above are the only oracle
you have.

## Your task

1. Model the system below, in whatever state shape you like.
2. Define `Observe` over your state, with the four fields the interface fixes.
3. Write each of the eight requirements as a formula over `Observe`, and declare it in your
   `.cfg` under the keyword the requirement names.
4. Run TLC at the checking instance.
5. Say, for each requirement, whether it holds. Keep the trace for each one that doesn't.

## The system

**The parties.** Two act, and they act independently.

- **The gang**, one. It asks for permits, does the work, and brings permits back.
- **The desk**, one. It raises permits, enters closes, and withdraws a permit the fire
  watch reports.

Nothing coordinates them. The desk's withdrawal can land between any two of the gang's
steps. There's no clock and no calendar. Nothing here happens except by a party's own act.

### Rule 1. The book and its leaves

The desk keeps one book for the gang. Its leaves are numbered 1 up to a last leaf, and
`Leaves` is how many there are, fixed before the shift starts. Every entry the desk makes
against the gang goes on a leaf, and the leaves are used in order. There's no leaf after
the last one.

At the start the gang's authority stands on leaf 1.

### Rule 2. The card

The gang carries a card. The card says which leaf the gang's authority stands on, and the
gang reads that off the card and off nothing else. At the start the card says leaf 1. Only
the desk writes it, and only while the gang is standing there. Rule 6 says when.

### Rule 3. The standing

Against the gang the desk's book shows one standing and one only.

- `"clear"`, no permit raised yet on this book
- `"open"`, a permit is raised and the work is under way
- `"completed"`, the last permit came back signed off
- `"abandoned"`, the last permit came back surrendered, or the desk withdrew it
- `"spent"`, the book is full and the desk has taken it back

At the start the standing is `"clear"`.

### Rule 4. Raising a permit

The gang asks for a permit, because it chooses to. The desk raises one while the book is
still open and no permit of the gang's stands open. That means from `"clear"`,
`"completed"` or `"abandoned"`. The standing becomes `"open"` and nothing else moves.

The desk reads the gang's card and sets it against its own book. If the card doesn't say the
leaf the desk holds, the desk refuses it as out of date and raises nothing. The desk doesn't
count the leaves the book has left.

### Rule 5. Bringing a permit back

The gang comes to the desk, presents its card, and asks either to sign off or to surrender.
The desk reads the card against its own book and does one of five things.

| the card says | the standing | the gang asks | the desk |
|---|---|---|---|
| the leaf the desk holds | `"open"` | to sign off | enters the close, and the standing becomes `"completed"` |
| the leaf the desk holds | `"open"` | to surrender | enters the close, and the standing becomes `"abandoned"` |
| the leaf the desk holds | `"clear"`, `"completed"` or `"abandoned"` | to surrender | enters a surrender all the same, and the standing becomes `"abandoned"` |
| one leaf behind the leaf the desk holds | `"abandoned"` | to surrender | reads the card as a second copy |
| anything else | | | refuses it as out of date |

Three of those rows want a word of explanation.

The third row is a gang that can't tell whether its last permit ever reached the desk. It
surrenders again rather than leave a live permit behind it, and the desk takes that at face
value and enters it.

The fourth row is a second copy. The desk has a surrender already entered against this
gang, and the leaf on the card is the leaf its own entry was written against. So it reads
the card as a duplicate of work it has done. It enters nothing. It writes the leaf it now
holds onto the card, so the card and the book agree again.

The fifth row changes nothing anywhere. The desk enters nothing and writes nothing, and the
gang keeps the card it came in with.

### Rule 6. What an entry does, and what the card gets

Every entry the desk makes moves the gang's authority on by one leaf, and the entry goes
there. That holds for a close the gang brought and for a withdrawal alike.

The card gets written only while the gang is at the desk. That means on a close the desk
entered for it, and on a second copy the desk recognised. The desk writes the leaf it holds
after the entry, so the card and the book agree.

The gang doesn't always wait for it. It can turn away before the card is handed back, and
then nothing is written on the card although the desk has entered the close. Afterwards the
gang has no way of telling whether that close reached the desk.

### Rule 7. Filling the book

A close the gang brought, entered on the last leaf, fills the book. The desk takes the book
back and the standing becomes `"spent"`. The gang's permits for this shift are done, and
`"spent"` is where the standing stays.

That is the only way a book is taken back. The gang's next book comes with its next shift,
and the next shift is outside this system.

### Rule 8. Withdrawing a permit

From the book alone the desk can't tell a gang at work from a gang long gone. So the fire
watch goes round the basins. When it reports a permit, the desk withdraws it: the desk
enters the withdrawal and the standing becomes `"abandoned"`.

The desk withdraws at a moment of its own choosing, and the gang gets no say in it. The
gang isn't at the desk when it happens, nothing is written on its card, and nothing tells
it afterwards.

### Rule 9. The fire watch's log

The fire watch keeps a log of its own, beside the desk's book. It notes that a permit of
this gang's has been withdrawn, and once noted the note stays. Nothing the office does
turns on that log, and the desk never reads it. It's there so the yard can be audited, and
it's the fourth of the facts the interface reports.

### Rule 10. What must happen, and what needn't

An open permit doesn't stay open forever. The fire watch may take its time over any one
round, but it can't walk past an open permit for good. A permit the gang doesn't bring back
is withdrawn in the end. That's the one thing in this system that must happen.

The gang owes nobody anything. It need never ask for a permit, and a permit it holds may
sit open as long as it likes. Nothing here obliges it either way.

## The interface

The checker never looks at your state. It evaluates one operator, `Observe`, which your
module defines over whatever state you chose. Each field is a fact about the shift right
now, the kind you could read off the desk's book, the gang's card, or the watch's log.

```tla
Observe == [standing |-> ..., leaf |-> ..., card |-> ..., withdrawn |-> ...]
```

- **standing**: where the desk's book shows the gang now.
- **leaf**: the leaf the gang's authority stands on, as the desk holds it.
- **card**: the leaf the gang's card says it stands on.
- **withdrawn**: whether a permit of this gang's has ever been withdrawn by the desk.

The shapes are load-bearing, because the checker compares values. A renamed field, a fifth
field, or a different spelling doesn't fail a check. It keeps the check from ever running.

- `Observe.standing` is one of the five standings, spelled exactly like this:

```
"clear"   "open"   "completed"   "abandoned"   "spent"
```

- `Observe.leaf` is an integer in `1 .. Leaves`.
- `Observe.card` is an integer in `1 .. Leaves`.
- `Observe.withdrawn` is a boolean.

Behind the operator the state is your own. Keep whatever you like, and let `Observe` render
it as the four facts above.

## The requirements

Eight requirements. Each one names the TLC keyword it goes under and what kind of formula
it is. None of them names a subscript.

Where a requirement constrains steps, the subscript is yours to choose. A step rule is only
tested at steps that change what its subscript watches. Watch one field, and every step
that changes only the other fields satisfies the rule for free. TLC won't warn you. Work
out what each rule has to watch.

1. **A card on the last leaf means a book taken back.** At every moment, if the leaf on the
   gang's card is the last leaf, the standing is `"spent"`. The desk has taken the book back.

   `INVARIANT`. A claim about a single state.

2. **Every permit is closed in the end.** A permit that's raised is closed sooner or later,
   signed off or surrendered or withdrawn.

   `PROPERTY`. A claim that something eventually happens.

3. **The book never goes back.** At a step, the leaf the gang's authority stands on never
   moves to an earlier leaf.

   `PROPERTY`. An action property.

4. **An entry is one leaf.** At a step where the gang's authority moves, it moves on by
   exactly one leaf.

   `PROPERTY`. An action property.

5. **The card never runs ahead.** At every moment the leaf on the card is the leaf the desk
   holds, or an earlier one.

   `INVARIANT`. A claim about a single state.

6. **The card says what the desk holds.** At a step where the leaf on the card moves, it
   becomes the leaf the desk holds after that step.

   `PROPERTY`. An action property.

7. **An open permit closes.** At a step where the standing moves off `"open"`, it becomes
   `"completed"`, `"abandoned"` or `"spent"`.

   `PROPERTY`. An action property.

8. **A book taken back stays taken back.** At a step, a standing of `"spent"` stays
   `"spent"`.

   `PROPERTY`. An action property.

### Requirement 2 needs fairness, and fairness needs a target

A formula saying every permit closes is false over a system that lets an open permit sit
unwithdrawn forever. It should be false there. Rule 10 says the office can't let that
happen, so your `Spec` has to say so too, with fairness.

The fairness goes on the withdrawal and on nothing else. Rule 10 leaves the gang free, and
fairness on the gang's own steps would oblige a party the rules say owes nothing. What the
office owes is that no permit sits open and unattended for good. Write the fairness over
the desk's withdrawal, over no other step.

Weak fairness on your whole next-state relation is not what Rule 10 means. It obliges the
gang to ask for permits and to bring them back, and nothing in the rules does. Decide whose
stalling Rule 10 is about, and write the fairness over that party's step.

## What the rules leave to you

The rules above fix what the office does. They don't fix your model.

**The step granularity is yours.** Whether a close the gang brings is one step or two, and
whether a withdrawal is one step or two, the rules don't say. Pick, and say which you
picked.

**The subscripts are yours**, as the note above the requirements says.

**Where the rules name no case, your model names one.** The rules say what the desk does in
every case they reach. Where they reach none, your model still has to do something, even if
that something is nothing at all. Write down which cases those were and what you decided.
A different decision there is a different system, and it can change which of the eight
hold.

## Checking

Check at three leaves:

```
Leaves = 3
```

Three is the least that lets a close land with the book still open. At two leaves the
gang's first close fills the book, so the shift is over in two steps. At three, a close can
land on leaf 2 and the book stays open.

Run TLC with deadlock checking off. The flag is `-deadlock`, and despite its name it turns
the check off. This system can stop. Once the book has been taken back nothing is enabled,
and that stall is the design working rather than an error.

The four fields take 5, 3, 3 and 2 values. So a model whose state is exactly the four facts
`Observe` reports can't reach more than 90 distinct states here. Keep state beyond those
four facts and your count comes out larger, which isn't wrong by itself. A count over 90
from a model that holds nothing else means you're carrying state you didn't mean to.

## Two ways to be wrong, and only one turns a check red

A model can be wrong in two directions. Allow a step the rules forbid, and a requirement
breaks and hands you a trace. Forbid a step the rules allow, and every check stays green
over a system that no longer exists. The second is the dangerous one, and nothing shipped
with this problem will catch it for you.

So before you believe a green check, break something on purpose. Let the desk's leaf slip
back a leaf somewhere, and watch requirement 3 go red. Drop a rule and watch something
else go. A requirement you can't make fail isn't being checked.

And when a check goes red by itself, it means one of two things. Either the office doesn't
have that property, or your model isn't the office. Telling those two apart is most of the
work here. The trace is the evidence either way, so read it before you decide which one
you're looking at.

## What to deliver

- Your module and the `.cfg` you checked it with.
- For each of the eight, the verdict: it holds, or it doesn't.
- For each one that doesn't, the shortest run you found that breaks it, written over the
  four fields of `Observe`.
- The cases the rules left open, and what you decided for each.
