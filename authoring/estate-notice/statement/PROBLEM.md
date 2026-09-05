# The executor's notice

Someone has died, and one person has to wind up their affairs. She's the
executor. She gathers what the dead person owned, pays what they owed, and
hands the rest to the people named in the will. Those people are the
beneficiaries, and they stay outside this system.

Her problem is that she can't know who's owed money. A debt she's never heard
of is still a debt, and if she hands the estate to the beneficiaries first she
can end up paying it herself. So she advertises. She puts out a public notice
that she's winding up the estate, and invites anyone owed money to come
forward. She closes the notice when she chooses. After that, a creditor who
never came forward has lost his claim against her, though not his money. He can
go after the beneficiaries instead. The debt doesn't vanish. It moves.

Model this, and establish the eight requirements below. The rules fix what
happens. How you model it is up to you: your state, your steps, TLA+ or
PlusCal. The one fixed point is the interface, a single operator the checker
reads.

Plan on 20 to 40 minutes if you've read the learntla core chapters. You don't
need to know any probate law. Every rule the system follows is stated here.

## What you get

- This statement: the rules, the interface, and the eight requirements.
- `traces/`: one pair of runs per requirement. In each pair, one run follows
  the rules and one breaks them.

No model ships. You write it.

## Your task

1. Model the system below, in whatever state shape you like.
2. Define `Observe` over your state, with the three fields the interface fixes.
3. Write each of the eight requirements as a formula over `Observe`, and
   declare it in your `.cfg` under the keyword the requirement names.
4. Run TLC at the checking instance. All eight must hold.
5. Hold your model against the traces. Every allowed run must be a run your
   model can produce. Every forbidden run must break at least one requirement.

A model can be wrong in two directions, and only one of them turns a check red.
Allow a step the rules forbid, and a requirement breaks with a trace to show for
it. Forbid a step the rules allow, and every check stays green over a system
that no longer exists. The allowed runs are your oracle for the second
direction.

## The system

**The parties.** Two kinds act, and they act independently.

- **The executor**, one. She closes the notice, decides claims, pays them, and
  distributes the residue. Nobody else does any of those.
- **The creditors**, a fixed finite set named by the constant `Creditors`. Each
  is owed money by the estate. A creditor can lodge a claim, or come forward
  out of time, and that's the whole of what he can do.

Nothing coordinates them. Any creditor's step can land between any two of the
executor's. There's no clock and no calendar. Nothing here happens except by a
party's own act.

### Rule 1. Creditors and claims

`Creditors` is fixed and named up front. Each creditor is owed something, and
the system never asks how much. A claim is one creditor's assertion that the
estate owes him. He makes it once or not at all. There's no second claim, no
amendment, and no withdrawal.

At any moment a creditor stands in one place and one only: nothing lodged,
lodged and undecided, admitted, admitted and paid, rejected, or out of time.
Every creditor starts with nothing lodged.

### Rule 2. The notice

The executor advertises one notice. It stands open from the start. She closes
it when she chooses, and closing it is her act alone. Nothing else closes it,
no period runs out, and it never reopens.

### Rule 3. Lodging

While the notice stands open, a creditor who has lodged nothing can lodge a
claim. He lodges because he chooses to. No claim arrives on its own, and the
executor can't lodge one on his behalf. A lodged claim sits with her until she
decides it.

### Rule 4. Out of time

Once the notice is closed, a creditor who never lodged can still come forward.
He comes forward against the beneficiaries and not against the executor, so his
coming forward is never a claim she has to answer. He's out of time, and out of
time is where he stays. Whether the beneficiaries pay him is their business,
and this system doesn't watch it.

### Rule 5. Admitting and rejecting

The executor can admit a lodged claim or reject it. She can do either while the
notice is open or after she's closed it. She takes one claim at a time, in
whatever order she likes. A decision is final. She never rejects what she
admitted and never admits what she rejected.

### Rule 6. Paying

The executor pays a claim she has admitted. Payment is its own act and it comes
after the admission, never in the same motion. She never pays a claim she
rejected, a claim still undecided, a claim nobody lodged, or a creditor who's
out of time. What's paid stays paid.

### Rule 7. Distributing the residue

The executor hands what's left to the beneficiaries. She can do that only when
the notice is closed and every claim lodged with her is either rejected or
paid. It happens once. There's no partial distribution, no interim payment, and
no way to call it back. At the start the residue is still in her hands and
nothing has been distributed.

### Rule 8. After the distribution

Once the residue has gone, the executor is finished. Every claim she holds is
settled and the notice is shut against new ones, so there's nothing left for
her to do. A creditor who never lodged can still come forward out of time.

### Rule 9. What must happen, and what needn't

The estate has to be wound up. The executor may take her time over any single
step, but she can't sit on the whole business forever, and the residue reaches
the beneficiaries in the end. That's the one thing in this system that must
happen. A creditor owes nobody anything. He need never lodge and need never
come forward, and nothing here obliges him either way.

## The interface

The checker never looks at your state. It evaluates one operator, `Observe`,
which your module defines over whatever state you chose. Each field is a fact
about the winding-up right now, the kind the executor could read off her own
file.

```tla
Observe == [standing |-> ..., notice |-> ..., distributed |-> ...]
```

- **standing**: for each creditor, where he stands with her now.
- **notice**: whether the notice still stands open.
- **distributed**: whether the residue has gone to the beneficiaries.

The shapes are load-bearing, because the checker compares values. A renamed
field, a fourth field, or a different spelling doesn't fail a check. It keeps
the check from ever running.

- `Observe.standing` is a function from `Creditors` to the six standings,
  spelled exactly like this:

```
"none"   "lodged"   "admitted"   "paid"   "rejected"   "outOfTime"
```

- `Observe.notice` is either `"open"` or `"closed"`.
- `Observe.distributed` is a boolean.

`"none"` is where a creditor stands when he has lodged nothing. It's a standing
like the other five, not a missing value, so every creditor carries one of the
six at every moment.

Behind the operator the state is your own. Keep whatever you like, and let
`Observe` render it as the three facts above.

## The requirements

Eight requirements. Each is a claim about every run of this system, and a
correct model satisfies all eight. Each one names the TLC keyword it goes
under and what kind of formula it is. None names a subscript.

Where a requirement constrains steps, the subscript is yours to choose. A step
rule is only tested at steps that change what its subscript watches. Watch one
field, and every step that changes only the other fields satisfies the rule for
free. TLC won't warn you. Work out what each rule has to watch.

1. **She distributes only when she's clear.** Whenever the residue has been
   distributed, the notice is closed and every claim lodged with her is either
   rejected or paid.

   `INVARIANT`. A claim about a single state.

2. **A claim starts with the creditor, inside the window the notice sets.** At a
   step where a creditor moves off `"none"`, he moves to `"lodged"` if the
   notice was open before that step. He moves to `"outOfTime"` if the notice
   was closed before it. He moves nowhere else.

   `PROPERTY`. An action property.

3. **A lodged claim ends only in her decision.** At a step where a creditor's
   standing moves off `"lodged"`, it becomes `"admitted"` or `"rejected"`.

   `PROPERTY`. An action property.

4. **A decision stands.** At a step, a creditor standing at `"admitted"` stays
   admitted or becomes `"paid"`. A creditor standing at `"rejected"`, `"paid"`
   or `"outOfTime"` never changes again.

   `PROPERTY`. An action property.

5. **The notice never reopens.** At a step, a closed notice stays closed.

   `PROPERTY`. An action property.

6. **The distribution is never undone.** At a step, a residue that has gone
   stays gone.

   `PROPERTY`. An action property.

7. **The estate is eventually distributed.**

   `PROPERTY`. A claim that something eventually happens.

8. **She takes one claim at a time.** At a step where one creditor's standing
   changes, every other creditor's standing stays where it was.

   `PROPERTY`. An action property.

### Requirement 7 needs fairness, and fairness needs a target

A formula saying the residue eventually goes is false over a system that lets
the executor stall forever. It should be false there. Rule 9 says she can't
stall, so your `Spec` has to say it too, with fairness.

The fairness goes on her steps and on none of the creditors'. Rule 9 leaves
them free, and fairness on a creditor's lodging would oblige a party the rules
say owes nothing. What she owes is the winding up itself. She has to close the
notice, decide each claim lodged with her, pay each claim she admits, and hand
over the residue. Your `Spec` has to say so, over those steps and no others.

Weak fairness on your whole next-state relation is not what Rule 9 means. It
also won't fail here, which is worse. Every act in this system disables itself
for good, and `Creditors` is finite. So no run goes on forever, and no run can
stop with the residue still in her hands. Blanket fairness makes requirement 7
come out true without your ever deciding whose stalling the rule is about.
Make that call, and write the fairness over her steps.

## The traces

`traces/` holds one file per requirement, eight in all. Each file carries two
runs, rendered over the three `Observe` fields at the checking instance, with
creditors `c1` and `c2`.

- **A run the rules allow.** Your model must be able to produce it.
- **A run the rules forbid.** Your model must rule it out, and your requirement
  set must break on it.

Each row of a trace is one moment, the value of `Observe`. Consecutive rows are
one step apart.

Two notes on reading them. A forbidden run can break more than one requirement,
and if your set rejects it for any requirement it breaks, your set is right
about that run. And where a forbidden run's fault is that nothing more ever
happens, the trace says so under its last state.

## Checking

Check at two creditors:

```
Creditors = {c1, c2}
```

Two is the least that shows a paid creditor and an out-of-time creditor in the
same observation. That's the state the whole notice exists to produce. It's also
the least that shows one claim holding up the distribution while another is
already settled.

Run TLC with deadlock checking off. The flag is `-deadlock`, and despite its
name it turns the check off. The end of the story is the residue gone, every
lodged claim settled, and every other creditor out of time. Nothing is enabled
there and the system stops. That stall is the design working, not an error.

A model whose state is exactly the three facts `Observe` reports finds 77
distinct states here. It runs in well under a second. Keep state beyond those
three facts and your count comes out larger, which isn't wrong by itself. If
your state is just the three facts and your count isn't 77, your rules differ
from the rules above. That difference is worth finding before you go on.

## What to deliver

Your module and the `.cfg` you checked it with.
