# Reading expansion plan

Written 2026-10-15 for epic `tla-fwkz.2`, as the design a wave of implementers
builds from. Frank's ask was that one reader see the whole set before anyone
writes a module, so that no two models read as the same model with the names
changed. This is that reader's plan. It writes no `.tla` files.

The short version. The reading corpus already reaches 100 of the 105 inventory
rows, the drill corpus declares 79, and only two rows are reached by neither
(`skip` and `goto`). Coverage doesn't justify a wave. Frank has read one model
and 25 sit unread, which is four sittings at his own six per sitting, so
volume doesn't either. What's left is depth, meaning rows the corpus meets
without any model being about them, and the supply of insights the 25 don't
carry. I found eight models worth writing now, four worth holding until Frank
has reacted, and three I'd not write. The plain answer the coordinator asked
for: 25 is close to enough, and after these eight the tokens belong in the
drill audit and in waiting.

## Part 1, the coverage measurement

Three measurements. Reading coverage from the `.tla` and `.cfg` text, drill
coverage from the 64 `META.md` files through the drill gate's own reader, and
a hand pass over all 25 modules for the rows no regex can see. The script was
`.plan-scratch/scan.sh` in the worktree, run under `bash`, deleted before
commit.

The sibling's gated map landed on `main` while I was writing, and its four
numbers (both 76, reading-only 24, drill-only 3, neither 2) match what follows
row for row. Two independent routes to one answer is the point of the
redundancy, so I'm leaving my route in.

### Reading, from the module text

100 of 105 rows appear in at least one reading module. The five that don't:

| row | construct | why |
|---|---|---|
| K026 | `skip` | never written, line bound (epic notes) |
| K028 | `goto` | never written, and D8 retired it as anti-idiomatic |
| K043 | symmetry set | forbidden by the epic |
| K091 | `Trans` helper | never written |
| K101 | `LOCAL INSTANCE` | needs a third module, one `.tla` per item |

The text scan and the `USES.md` claims agree row for row, which I read as
evidence the declarations are honest after the 01-euclid fix in `652915a`.
The brief said `USES.md` carries no construct list. It does, in both sections,
and the epic's NOTES already counted them at 100. I measured from text anyway
because the brief asked for an independent route, and the two routes agree.

Three regex results had to be thrown out by reading the matched lines, and I
name them because any gated map will hit the same three.

- `[]` matched `Chameleons.tla:23`, which is CASE's arm separator.
- `<>` matched `Brackets.tla:18`, which is the empty sequence `<<>>`.
- `[][` matched every `Spec` line, so action properties were hand counted at 10.

### Drill, from the 64 `META.md` files

79 of 105 rows are declared by at least one drill item, using the gate's reader
(`harness/drill-gate.sh:1177`, any heading containing "construct", bullets only,
backticks stripped). All 64 files carry such a heading, and no declared name
fails to match a row.

The 26 undeclared rows are 25 PlusCal-family rows plus K068 `<>[]`. The
2026-10-12 read/write split keeps PlusCal out of the blank-page channel, so 25
of the 26 are unreachable by design. The six PlusCal-family rows that are
declared (K036 `pc`, K054 `pc[...]`, K089 `ProcSet`, K090 label-as-action,
K091 `Trans`, K092 `Terminating`) come from the `control-state` family, which
hand-rolls program counters in raw TLA+
(`drill/control-state/01-slip-on-the-spike/META.md`).

### Reached by neither

Two rows: K026 `skip` and K028 `goto`.

### Met against taught, which is the measurement that matters now

The sibling's closing finding is right. A reading item declares everything a
reader meets (29 bullets a file against 11 for a drill item), so a row marked
`both` can be a row no model is about. I went back through the 25 `USES.md`
files and asked, for each row, whether the "What the properties rest on"
section edits or names it. That's the construct the model is about. Everything
else is met.

Twelve base rows are met in every module and can't be about anything (operator
definition, equality, integers, booleans, bullets, prime, box action,
`VARIABLE`, `vars`, the skeleton, action, nondeterministic action). They're
left out. Of the other 93, these are the rows no landed model is about, with
the weight the inventory gives them:

| row | weight | met in | about in | can a model be about it |
|---|---|---|---|---|
| K004 | high | 23 | 0 | no, nothing to work out |
| K006 | high | 11 | 0 | no, nothing to work out |
| K039 | high | 19 | 1, thinly (`02-gears`) | no beyond the ASSUME models |
| K042 | high | 10 | 0 | maybe, see Ids below |
| K050 | high | 12 | 0 | maybe, see Rota below |
| K063 | high | 4 | 0 | yes, see Latch below |
| K021 | medium | 3 | 0 | no, nothing to work out |
| K029 | low | 2 | 0 | no |

So of 93 rows, 8 are met and never taught, 5 of them `high`, and I think three
of those five have a model in them. The other 85 are about in at least one
model, by the probe test. That's a much narrower depth gap than the "wide net"
caveat suggests, and it's the measurement I'd rest the ruling on.

The thin rows are the other half. `High` or `medium` rows that are about in
one model only, where a second model would be the first repetition:

| row | weight | about in | construct |
|---|---|---|---|
| K041 | high | `02-tickets` | model value |
| K044 | high | `02-shelves` | struct literal |
| K045 | medium | `02-shelves` | struct set |
| K072 | medium | `03-cups` | higher-order operator parameter |
| K088 | medium | `03-overlay` | `@` inside EXCEPT |
| K020 | medium | `01-clockface` | CHOOSE |
| K018 | low | `01-clockface` | set map |
| K011 | low, and the inventory doubts it | `01-brackets` | sequence operators |

### Discrepancies against the brief

- `~/tla-practice/drill/PROGRESS.tsv` doesn't exist. `drill/drill.sh:52` says an
  absent file means nothing done yet, `LAST-SERVED` reads
  `control-state/01-slip-on-the-spike`, and `~/Study/tla-drills/01-slip-on-the-spike/`
  holds `pickers.tla`, `pickers_collision.tla`, a `.cfg` and two TLC trace files.
  So one drill was worked, with two models, and nothing was marked. The
  conclusion stands. The file it cites doesn't.
- The fluency exploration drawer's F29 says 25 of 64 drill items declare
  constructs (`drawer_tla_puzzles_decisions_391c4fb41f7034a4fafcc7c3`). It
  counted `K`-ids. Under the gate's reader all 64 declare.
- On the drill side the hole isn't uniform at the weighted level. Six `high`
  rows have five or fewer drill items: K004 5, K044 4, K064 3, K078 4, K095 3,
  K098 2. Four of the six are temporal. With no drill marked it changes nothing
  today.

### A hazard for every agent scanning this repo from the Bash tool

In this tool's shell `grep` is a shell function that execs the `claude` binary as
`ugrep` (`type grep` in the snapshot). It returned 0 for
`(^|[^A-Za-z_])CASE([^A-Za-z_]|$)` on `Chameleons.tla`, where GNU grep 3.12
(`command grep`, `/run/current-system/sw/bin/grep`) returns 1. The same shape
matched `ENABLED` and `RECURSIVE` under both, so the miss is pattern specific
and I don't know its rule. Scripts run under `#!/usr/bin/env bash` get GNU grep,
so the gates aren't affected. Any scan typed into the Bash tool is. I suspect
this is behind some of the five plausible wrong answers central saw. The
workaround is `command grep`, or a script.

## Part 2, the model specs

Fifteen candidates in three tiers. Eight to write now, four to hold until
Frank has read some of what's landed, three I'd not write and list so nobody
re-derives them. For each: where it sits, the system, the constructs it
happens to expose (named as `drill/INVENTORY.md` field 4 writes them), the
insight, the obligation shape, what the property rests on with the rc I
expect, and why the search is complete. Every rc here is a prediction. The
implementer measures it, and a measurement that disagrees is a finding about
this plan.

All of them record rc 0. I thought about letting one carry a deliberately
false property at rc 13, which `tla-practice.md` §7 attests once in 666
modules (`EWD687a`), and decided against it. The landed bar,
`temporal/01-handover`, delivers its insight through the probe table, and
that's the channel the corpus already has. Where a model's best moment is a
property that fails, it goes in the first probe row.

### Tier 1, write now

#### 1. `state-space/04-key`, "Key"

**System**: a storeroom with one key on a hook. Taking the key lets you in, and
hanging it back up is the only way out. The obvious rule is that at most one
person is inside.

**Constructs**: `Invariant`, `Init / Next / Spec` (a second specification,
`ISpec`), `set of model values`, `Cardinality`, `Set relational and algebraic
operators`, `Booleans and logical operators` (`<=>`), `\E`.

**Insight**: TLC checks reachable states, and a property that's true of every
reachable state can still fail the test of being inductive. The cfg points at
`ISpec == TypeOK /\ Inv /\ [][Next]_vars`, whose initial states are every state
satisfying the invariant. The one-conjunct `MutEx` fails there, from the state
"someone inside and the key on the hook", which the real `Init` never reaches.
The two-conjunct `Inv == MutEx /\ (hook <=> inside = {})` passes. So the weaker
statement is the one that breaks, and the reader has to work out why a cfg
would ever start from the invariant instead of from `Init`.

This is the only model in the set whose insight lives in the `SPECIFICATION`
line. Published practice names the variant `ISpec` (`tla-practice.md` §3).

**Obligation**: invariant, under `SPECIFICATION ISpec`.

**Rests on**: the `hook <=> inside = {}` conjunct. With `INVARIANT MutEx` alone
under `ISpec`, rc 12 from an unreachable initial state. With `INVARIANT MutEx`
under `Spec`, rc 0. With the conjunct dropped from `Inv`, rc 12.

**State space**: `hook \in BOOLEAN`, `inside \subseteq Staff`, three staff. Under
`ISpec`, four initial states and the same four reachable. Complete because the
initial predicate is enumerable and closed.

#### 2. `temporal/05-break`, "Break"

**System**: two players who each start and stop playing on their own. A
conductor can call a break, and once called, nobody starts again until both
have stopped.

**Constructs**: `~> (leads-to)`, `WF_v(A) (weak fairness)`,
`fairness on a subaction`, `action property`, `\A`, `\E`, `set of model values`,
`UNCHANGED`, `function literal`, `EXCEPT`.

**Insight**: fairness is a promise about actions, and no fairness assumption can
make two independent processes coincide. `asked ~> AllIdle` holds because
`Start(p)` carries a `~asked` guard, and it's the guard doing the work. Drop the
guard and the property fails even with `SF_vars` on all four actions, because
every action still fires infinitely often while "both idle" is never visited.
The reader's question is "why is there a guard here instead of fairness", and
the answer is that there's nothing fairness could promise.

**Obligation**: temporal `~>`, plus
`[][asked => \A p : playing'[p] => playing[p]]_vars`.

**Rests on**: the `~asked` guard on `Start`. Removed, rc 13 with `WF` and still
rc 13 with `SF` on every action. `WF_vars(Stop(p))` removed, rc 13.

**State space**: `playing \in [Player -> BOOLEAN]` and `asked \in BOOLEAN`, 8
states at two players, with a `Resume` step clearing `asked` once both are idle
so the behavior cycles. Complete because every variable is a boolean.

#### 3. `modules/04-cycle`, "Cycle"

**System**: a washer that runs fill, wash, spin, round and round. The abstract
submodule says only that the phase advances and keeps advancing. The concrete
module adds a countdown timer per phase.

**Constructs**: `INSTANCE`, `named instance`, `! (namespace lookup)`, `WF_v(A)`
in a submodule, `CASE`, `fairness on a subaction`, `PROPERTY`.

**Insight**: refining a spec that carries fairness is a liveness obligation, not
only a safety one. `Tick` maps to abstract stuttering, as `Refresh` does in
`modules/01-bitcounter`, but here the abstract `WF_ph(RNext)` forbids stuttering
forever, so the concrete `WF_vars(Tick)` is load-bearing. Drop it and TLC
reports a violation of the submodule's fairness, which is a formula the outer
module never wrote.

**Obligation**: refinement, `Refines == Abs!RSpec`.

**Rests on**: `WF_vars(Tick)` and `WF_vars(Advance)` both. Either dropped,
rc 13 naming the submodule's temporal formula. `Advance` skipping a phase,
rc 13 on the submodule's box action.

**State space**: three phases times a timer in `0..Dwell`, 9 states at `Dwell = 2`.
Complete because both variables are bounded.

#### 4. `sets/03-gossip`, "Gossip"

**System**: four phones on a ring of possible links. Links come up and go down.
A rumor starts at one phone and crosses a link that's up. The invariant says
nobody has heard it who couldn't have.

**Constructs**: `RECURSIVE`, `LET-IN`, `Set map`, `Set filter`, `SUBSET`,
`Cardinality`, `Set relational and algebraic operators`, `\E`, `\A`,
`action property`.

**Insight**: a closure invariant has to be computed over the history, not over
the current graph. `Reach` is a recursive fixpoint (`next = S` stops it) over
`ever`, the set of links that have ever been up. Computed over `link` instead,
the invariant fails on the trace where the rumor crosses a link and the link
then goes down. The reader works out why the spec carries `ever` at all, which
is the history-variable lesson in its smallest form.

**Obligation**: invariant `heard \subseteq Reach({Src})`, invariant `Src \in heard`,
action property `[][heard \subseteq heard']_vars`.

**Rests on**: `Reach` reading `ever`. Over `link`, rc 12. `Tell` guarded by
`ever` instead of `link`, rc 12 in the other direction.

**State space**: `Edge` is the four ring links, `link \subseteq ever \subseteq Edge`
gives 81 pairs, `heard` is one of at most 8 subsets, under 700 states. Complete
because all three variables are subsets of fixed finite sets.

#### 5. `functions-records/04-ledger`, "Ledger"

**System**: a tally of hits per key kept two ways at once. A total function with
a zero for every key, and a sparse map that only has keys it has seen. A key can
be forgotten.

**Constructs**: `:> (singleton function)`, `@@ (function merge)`, `DOMAIN`,
`EXCEPT`, `@`, `function literal`, `function set`, `Set filter`, `IF-THEN-ELSE`.

**Insight**: a function has no delete. Adding a key to the sparse map is
`sparse @@ (k :> 1)`, and bumping one is `EXCEPT ![k] = @ + 1`, but taking a
key out is a rebuild, `[j \in DOMAIN sparse \ {k} |-> sparse[j]]`. The two
invariants, that the maps agree and that the sparse domain is the set of
non-zero keys, both hold, and the reader works out why `Forget` is the only
action that can't be written with `EXCEPT`.

**Obligation**: two invariants.

**Rests on**: the rebuild in `Forget`. Written as `[sparse EXCEPT ![k] = 0]`, the
domain invariant fails, rc 12. `@@` operands swapped in `Hit`, rc 0 (the key is
new, so the operands don't overlap), worth recording as the probe that comes
back green.

**State space**: `Key` three model values, counts capped by a guard at `Max = 3`,
so `tally` ranges over 64 functions and `sparse` is determined by `tally`.
Complete because the cap is a guard rather than a constraint.

The epic's note that functions-records is "done at three items" is a
line-budget statement about the landed three. Ledger is about 42 lines.

#### 6. `sequences/02-josephus`, "Josephus"

**System**: people in a circle, numbered. Every second person leaves, counting
round from the last one who left, until one is left.

**Constructs**: `Sequences`, `Sequence module operators` (`Head`, `Tail`,
`Append`, `Len`), `RECURSIVE`, `IF-THEN-ELSE`, `function literal`, `\E`,
`Implication`, `Integers` (`%`, `\div`), `action property`.

**Insight**: a simulation and a closed form, checked against each other. The
ring step is `Append(Tail(Tail(ring)), Head(ring))`, and the invariant says
that when one person is left it's `J(n)`, where `J` is the recurrence
`((J(n - 1) + 1) % n) + 1`. A second invariant checks the binary closed form
`2 * (n - Pow2Below(n)) + 1`. The reader works out why the recurrence's `+ 1`
is where it is, which is an off-by-one the probe confirms.

**Obligation**: two invariants, plus `[][Len(ring') = Len(ring) - 1]_vars`.

**Rests on**: the `+ 1` inside the modulus. Written as `J(n - 1) % n + 1`,
rc 12 at `n = 3`. The closed form's `Pow2Below` wrong by one, rc 12 at `n = 4`.

**State space**: `Init` picks every `n \in 1..7`, so the run is seven
trajectories of `n` states each, 28 in all. Complete because each trajectory
is a chain, and `CHECK_DEADLOCK FALSE` since a one-person ring is the end.

#### 7. `pluscal/07-peterson`, "Peterson"

**System**: two processes sharing one critical section, each with a flag and a
shared turn, written in raw TLA+ with a hand-rolled program counter.

**Constructs**: `Trans helper action for pc transitions`, `pc`, `pc[...]`,
`label-as-action encoding`, `EXCEPT`, `CHOOSE`, `\A`, `\E`, `WF_v(A)`,
`fairness on a subaction`, `[]<>`, `set of model values`.

**Insight**: the tie-break. Both processes write `turn`, and the one who wrote
it last is the one who waits. That's why a process can enter while the other is
idle (which `temporal/03-alternation` can't do) and why neither starves (which
`pluscal/03-contend` needs `fair+` for). The reader works out from `Enter`'s
guard, `~flag[other] \/ turn = p`, which disjunct is doing the work in which
state.

`Trans` is here because it's how a two-process pc is hand-coded within the line
bound, and the inventory files it under `pluscal` on purpose
(`drill/INVENTORY.md`, "The eight families"). This is the raw-TLA+ side of the
label-as-action encoding, which every other pluscal item shows only as pcal
output.

**Obligation**: invariant `MutEx`, temporal `\A p : []<>(pc[p] = "cs")`.

**Rests on**: writing `flag` before `turn`. Order swapped, rc 12. The `turn = p`
disjunct dropped, rc 13 (both wait forever, with `CHECK_DEADLOCK FALSE`). The
`~flag[other]` disjunct dropped, rc 13 on starvation.

**State space**: `flag \in [Proc -> BOOLEAN]`, `turn \in Proc`, `pc` over five
labels per process, 200 combinations and under 100 reachable. Complete because
every domain is finite.

My line estimate is 55. If `Trans` doesn't pay for itself, drop it and inline
the two conjuncts, and say so, since the row then stays reading-unreached.

#### 8. `core/04-stamps`, "Stamps"

**System**: a postage machine that only has 3 and 5 cent stamps. Every step
adds one stamp to what's been paid.

**Constructs**: `\E`, `\A`, `Set relational and algebraic operators` (`\notin`,
`\cup`), `Sets`, `BOOLEAN and integer interval as sets`, `ASSUME`, `CONSTANT`,
`Integers`, `nondeterministic action`. Also `CONSTRAINT`, which has no row.

**Insight**: "the reachable amounts are exactly `{0, 3, 5, 6}` and everything from
8" is two claims, and they need two mechanisms. The invariant
`paid \notin {1, 2, 4, 7}` is the subset direction, checked at every state. The
superset direction can't be an invariant, since no state can say "every amount
from 8 is reached". It goes in an `ASSUME` quantified over `8..Max`, which TLC
checks before generating a state. The reader works out why 7 is the last gap,
and then why half the theorem lives in an `ASSUME`.

**Obligation**: invariant, plus a constant-level `ASSUME`.

**Rests on**: the stamp values. Change 3 to 4 and the `ASSUME` fails at 11,
rc 10, before the run starts. Drop the `ASSUME` and make the same change, rc 12
against the invariant at a different gap set.

**State space**: `paid \in 0..Max` under `CONSTRAINT paid <= Max`, 21 states at
`Max = 20`. Complete under the bound, and `state-space/02-tickets` already
explains what that means.

### Tier 2, hold until Frank has reacted

#### 9. `temporal/06-latch`, "Latch"

The one depth candidate I'd rank above the rest of this tier, because K063
`[]` is `high`, met in four models and about in none.

**System**: a fuse that can be blown by a surge and never resets. A reset button
exists and does nothing to a blown fuse.

**Constructs**: `[] (always)`, `action property`, `PROPERTY`, `Implication`,
`Invariant`.

**Insight**: a temporal operator doesn't make a property a liveness property.
`[](blown => []blown)` is safety, TLC refutes it with a finite prefix, and it
exits 12 like an invariant. The same claim written as `[][blown => blown']_vars`
goes through the implied-action channel and exits 13. `harness/verdict.sh`
measured both shapes on a two-state spec, and no landed model carries either.
The reader works out why three spellings of "once blown, stays blown" are one
claim, and why TLC reports two of them differently.

**Obligation**: two `PROPERTY` lines stating the same thing, plus `TypeOK`.

**Rests on**: `Reset` leaving `blown` alone. Let it clear the fuse and the
box-implication form gives rc 12, the action form rc 13, same trace.

**State space**: `blown \in BOOLEAN` and a surge counter capped at 3, 8 states.
Complete because both are bounded.

The moment here is about TLC's channels more than about the system, which is
why it's tier 2. Frank reads verdict codes in every `USES.md`, so I think it
lands, and I'd want his reaction to the first eight before betting on it.

#### 10. `temporal/07-preempt`, "Preempt"

**System**: three tasks and one processor. A task wakes and becomes ready, the
processor can switch to any ready task at any time, and a running task can
finish and go back to sleep.

**Constructs**: `WF_v(A)`, `fairness on a subaction`, `fairness conjunct on Spec`,
`~>`, `model value` (`Nil`), `set of model values`, `function set`, `EXCEPT`.

**Insight**: `WF_vars(Next)` and `\A t : WF_vars(Run(t))` aren't the same promise,
and it takes three tasks to tell them apart. Under fairness on the disjunction
alone, `t1, t2, t1, t2, ...` is a fair behavior in which `t3` is ready forever
and never runs.

**Obligation**: temporal, `\A t \in Task : ready[t] ~> running = t`.

**Rests on**: the quantifier being outside the `WF`. As `WF_vars(Next)`, rc 13 at
three tasks and rc 0 at two. As `WF_vars(\E t : Run(t))`, rc 13.

**State space**: about 20 reachable of 32. Complete because every domain is
finite.

Held because its "needs three" is a shape `pluscal/02-interleave` already has,
and because `05-break` is the stronger of the two fairness-limit models.

#### 11. `temporal/08-settle`, "Settle"

**System**: a source value and a cached copy. Writes change the source and come
out of a budget. A sync step copies the source into the cache.

**Constructs**: `<>[]`, `[]<>`, `WF_v(A)`, `CONSTANT`, `set of model values`,
`action property`.

**Insight**: `[]<>Consistent` and `<>[]Consistent` rest on different things.
Recurrence needs only a fair `Sync`. Stabilization needs the writes to stop,
and the budget is what stops them.

**Obligation**: `Recovers == []<>(copy = source)`, `Settles == <>[](copy = source)`,
`[][left' <= left]_vars`.

**Rests on**: the `left > 0` guard on `Write`. Removed, rc 13 on `Settles` and
rc 0 on `Recovers`. `WF_vars(Sync)` removed, rc 13 on both.

**State space**: 12. Complete because the budget is bounded by its own guard.

Held because `02-converge` already carries `<>[]`, and the contrast is the only
new thing here.

#### 12. `pluscal/08-retry`, "Retry"

**System**: a sender that tries to deliver a message. Each try either succeeds
or does nothing, and it tries again until it succeeds or runs out of tries.

**Constructs**: `skip`, `either-or`, `while`, `--algorithm block`,
`:= assignment`, `label`, `assert`, `pc`, `Terminating`, `label-as-action
encoding`, `<>`, `WF_v(A)`, `fairness conjunct on Spec`.

**Insight**: `either` is a choice that fairness never resolves. The run
terminates, and the reader's question is why, when the failing branch can be
taken every time. The answer is the `tries < Max` in the `while` guard, not the
`fair` on the algorithm. `skip` earns its place as the honest spelling of "the
attempt did nothing".

**Obligation**: `Termination`, the invariant
`pc = "Done" => (sent \/ tries = Max)`, and `[][sent => sent']_vars`.

**Rests on**: the cap. `<>sent` added as a property, rc 13. The cap removed,
rc 13 on `Termination` and the state count grows with `Max`. `assert`
tightened to `sent`, rc 14.

**State space**: about 32 at `Max = 3`. Complete because `tries` is capped by
the loop guard.

An earlier draft used `goto` for the loop, which would have closed one of the
two unreached rows. I took it out. D8 retired `goto` as anti-idiomatic, the epic
says a model that violates published practice teaches the wrong thing, and
`03-contend` already paid seven lines to avoid it. So `goto` stays unreached on
purpose, and `skip` is the only coverage this model buys. It's here for the
`either` insight, not the row.

### Tier 3, not recommended

**Rota** (K050 depth): a roster where the invariant is
`\E f \in [Pending -> Worker] : ...`, so a function set is a search space
rather than a type. The mechanism is real and no model has it. The moment
isn't, because the guard on `Accept` runs the same search and the reader sees
the invariant restate the guard. I'd only write it if K050 depth matters more
than the moment, and I don't think it does.

**Ids** (K042 depth): the same protocol with `Proc` as model values and as
`1..3`, where a `<` makes the first fail to evaluate. It teaches that a model
value is an atom with no order. I couldn't make the system interesting at 10
minutes, and the hazard shape (rc 75) is one `02-shelves` already carries.

**Lossy**: a numbered-message wire with middle drops, with order preserved
stated over sequence numbers. Exposes `SubSeq`, `\o` and records, and K011 is a
thin row. It's the weakest "wait, why" of everything I drafted, so the thin
row can wait for a better system.

## Part 3, the differentiation argument

### The axes

The brief names five, and I used all of them: the construct exposed, the
obligation shape, what the property rests on, the channel that reports its
removal, and what makes the state count complete. I found two more that
separated pairs the five didn't.

**Where the insight lives.** In a guard, in an operator's argument order, in a
fairness conjunct, in the cfg, in a theorem about constants, or in a choice of
representation. Two models with the same obligation shape and the same rc feel
different when one's answer is in a guard and the other's is in the cfg.

**The direction of the surprise.** Holds and looks like it shouldn't
(`01-handover`, `01-nim`, `03-chips`). Fails and looks like it should hold
(`02-interleave`, `05-break` in its probe). Passes for the wrong reason
(`01-quorums`'s `Settled`, `01-clockface`'s `CHOOSE`). Dies instead of failing
(`02-shelves` at 75, `03-fences` at 150). A set that leans on one direction
reads as one model, however the fictions vary.

### All 37, one row each

The 25 landed plus the twelve in tiers 1 and 2. The insight column is the one
the brief says I'll be judged on. Landed rows are taken from each item's
`USES.md`.

| item | exposes | shape | rests on | breaks as | complete because | insight |
|---|---|---|---|---|---|---|
| core/01-nim | custom infix op, RECURSIVE | I + A | a move touches one heap | 13, 12 | three heaps in `0..7` | a zero nim-sum can't survive a move, and a nonzero one reaches zero in one |
| core/02-chameleons | CASE in a rebuilt function | I | the third color gains two | 12 | 9 reachable, `-d` clean | the pairwise differences mod 3 are conserved |
| core/03-cups | higher-order op, LAMBDA | I | the gap of two | 12 | 8 of 32 positions | odd and even places never mix, one law named twice |
| core/04-stamps (T1) | ASSUME as theorem, CONSTRAINT | I + ASSUME | the stamp values | 10, 12 | bounded by CONSTRAINT | one direction of "reachable = X" is an invariant, the other is an ASSUME |
| fr/01-matching | multi-key EXCEPT | I | both ends in one EXCEPT | 12, and 0 on the spare guard | all 10 involutions | a guard the invariant already implies |
| fr/02-shelves | two record shapes, DOMAIN | I | shape test first | 12, 75 | finite titles | the slot is only permuted, and a missing field kills the run |
| fr/03-overlay | `@@`, `:>`, recursive function | I + A | left operand wins | 12, 13 | layers × partials | fold order decides who wins, and Pop must blank |
| fr/04-ledger (T1) | `:>`, `@@`, DOMAIN rebuild, `@` | I | the rebuild in Forget | 12, and 0 on swapped `@@` | capped counts | a function has no delete |
| seq/01-brackets | Seq ops, SelectSeq LAMBDA | I | open moves with the char | 12 on TypeOK first | 43 sound prefixes | two invariants on one guard, the cheaper reports first |
| seq/02-josephus (T1) | Head, Tail, Append, RECURSIVE | I + A | the `+ 1` in the modulus | 12 | 28 chain states | a simulation and a closed form check each other |
| sets/01-clockface | set map, CHOOSE | I | the step picked once | 12, 0 without minimality | 141, Tick always on | orbit size divides the face, and CHOOSE's witness isn't a guarantee |
| sets/02-antichain | SUBSET, `\X`, filter | I + A | both arms of Nests | 12, 13, 10 | all 168 antichains | the Sperner bound is tight, and Narrowing has a direction |
| sets/03-gossip (T1) | RECURSIVE closure, map, filter | I + A | Reach over `ever` | 12 either way | subsets of a fixed edge set | a closure invariant is over the history |
| ss/01-quorums | SUBSET as quorum | I + A | strict majority | 12, 0 on destructive update | 99 | a strict majority can't be mustered twice |
| ss/02-tickets | CONSTRAINT, model value | I + A | the CONSTRAINT | 124, 12, 13 | 79 under the bound | termination bought, coverage charged |
| ss/03-chips | ASSUME, deadlock on | I + 11 | `Stake % N # 0` | 10, 12, 11 | all 120 splits | one ASSUME does two jobs, the invariant reports before deadlock |
| ss/04-key (T1) | ISpec, SPECIFICATION | I under ISpec | the `<=>` conjunct | 12 from an unreachable init | enumerable Inv | the weaker invariant fails the inductiveness test |
| mod/01-bitcounter | INSTANCE WITH variable | R | Value counts in order | 13 | 16 | Refresh maps to stuttering, TLC names the submodule |
| mod/02-gears | two instances, partial param | R + A | tooth counts divide | 10, 13 | 12 | the `_n` subscript after substitution admits Spin |
| mod/03-fences | LOCAL, state-expression WITH | I | the clamp | 12, 150, 0 | 28 | an ASSUME doesn't cross an INSTANCE |
| mod/04-cycle (T1) | WF inside a submodule | R | concrete WF on Tick | 13 naming the submodule's WF | 9 | refinement carries the abstract fairness as an obligation |
| temporal/01-handover | WF on one subaction, `~>` | T + A | WF(Grant) alone | 13 twice, different messages | 6 | Request's own guard disables it |
| temporal/02-converge | `<>[]` | T + A | WF on every Learn | 13, 11 | bounded functions | monotone copying plus WF settles the ring |
| temporal/03-alternation | `[]<>` | T + I | WF on Ask too | 13, 12 | 2 × 3 × 2 | no starvation needs the asking to be fair |
| temporal/04-contention | SF, ENABLED, `<<A>>_v` | T | SF on TaskTake | 13 | 6 | the window keeps closing |
| temporal/05-break (T1) | `~>` with a guard | T + A | the `~asked` guard | 13 under WF and under SF | 8 booleans | no fairness makes two processes coincide |
| temporal/06-latch (T2) | `[]` over a state predicate | T, safety | Reset leaves blown alone | 12 and 13, same trace | 8 | a temporal operator doesn't make a property liveness |
| temporal/07-preempt (T2) | WF quantified per task | T | the quantifier outside WF | 13 at three, 0 at two | finite | fairness on a disjunction isn't fairness on each disjunct |
| temporal/08-settle (T2) | `<>[]` against `[]<>` | T + A | the write budget | 13 on Settles only | 12 | stabilization needs the disturbance to end |
| pluscal/01-euclid | while, if, pc, `-termination` | I + T | subtraction keeps divisors | measured three ways | `M, N <= 12` | the WF comes from the flag, not the keyword |
| pluscal/02-interleave | process set, self, fair | I + T | three workers | 12, 13, 13 at 3 and 0 at 2 | 3 × pc × seen | the counter can fall |
| pluscal/03-contend | fair against fair+ | I + T | fair+ on keen | 13 | 2 × lock | the syntax for asking, one word |
| pluscal/04-ring | either, macro, no pc | I + A | count carried at all | 12 | Cap² × count | head = tail means empty or full |
| pluscal/05-collatz | procedure, call, assert | I + T | the call site is a loop | 12, 14 | one trajectory | one frame, return address as data, assert is 14 |
| pluscal/06-bubble | with, `\|\|`, define | I + A + T | all-pairs inversions | 13 at 4, 0 at 3 | 256 arrays | one swap removes exactly one inversion |
| pluscal/07-peterson (T1) | Trans, hand-rolled pc | I + T | flag before turn | 12, 13, 13 | finite | the last to write turn waits |
| pluscal/08-retry (T2) | skip, either, while | I + A + T | the tries cap | 13 on `<>sent`, 14 | capped tries | either is a choice fairness never resolves |

### The pairs that are closest, and why they're two models

Six fairness models (`03-alternation`, `04-contention`, `03-contend`, `05-break`,
`07-preempt`, `01-handover`), which is where a reader is most likely to feel
repetition. They separate on what fairness can't do.

- `01-handover`: a weaker fairness than expected is enough, because of a guard.
- `04-contention` and `03-contend`: WF isn't enough, because the guard flickers.
- `03-alternation`: fairness on the wrong action isn't enough.
- `07-preempt`: fairness on the disjunction isn't fairness on each disjunct.
- `05-break`: no fairness reaches a state that needs two processes to coincide.

Each is a different thing fairness fails to promise, and the probes fail through
different edits (a conjunct dropped, a keyword changed, a quantifier moved, a
guard removed). Holding `07-preempt` in tier 2 is the hedge: if Frank reads
`05-break` and finds the fairness lesson done, `07-preempt` never gets written.

`02-converge` and `08-settle` both state `<>[]`. Converge's settles because the
process is monotone and terminates. Settle's settles because the disturber runs
out, and the same predicate under `[]<>` doesn't need that. The contrast is the
only new thing, which is why Settle is tier 2.

`01-bitcounter`, `02-gears` and `04-cycle` are all refinement. Bitcounter is
safety-only stuttering. Gears is the subscript after substitution. Cycle is the
liveness half, where the abstract fairness becomes a concrete obligation, and
its failure names a formula the outer module never wrote. Three different
things a refinement check can report.

Four mutex fictions (`03-alternation`, `03-contend`, `07-peterson`, `04-key`).
The brief says to differentiate on mechanism, and these do. Alternation is a
turn without flags. Contend is a lock with two fairness strengths. Peterson is
the tie-break between flags. Key has no fairness, no liveness and no tie-break,
and its whole content is the `SPECIFICATION` line. The fiction repeats because
a token-guarded resource is the smallest system with a natural invariant that
isn't inductive, and I couldn't find a smaller one that didn't look contrived.
If a reader objects to the fourth mutex, Key's mechanism survives a change of
story and the others don't.

`06-latch` against the monotone action properties (`01-quorums`'s `Settled`,
`02-antichain`'s `Narrowing`, `03-overlay`'s `PushChangesNothing`). Those are
all `[][...]_vars` and all exit 13. Latch's point is the other spelling, the
one that exits 12, and no landed model has it.

Six drafts were dropped for overlap, and I list them so nobody re-derives them:
a lights-out parity puzzle (Cups' property under a different toggle), quantifier
order on keys and locks (no "wait, why"), CHOOSE inside an action (Clockface's
lesson moved), a narrow fairness subscript
(`drill/control-state/04-night-patrol` drills it), composition by conjunction of
instance specs (Gears' subscript lesson with a different spelling), and a
vacuous `~>` (a property that holds for no reason teaches the wrong shape).

One cross-channel overlap worth naming: an operator-valued module parameter
(`CONSTANT Keep(_)` substituted with a named operator or a `LAMBDA`) is the
cleanest modules insight I didn't propose, because
`drill/modules/06-two-chutes-one-gate` is that exact lesson. If central would
rather have it than Cycle, it fits in 45 lines and lifts K072, which is a thin
row.

## Part 4, what justifies a wave, and how big

### The four options, ruled on

**More models for volume.** No. Frank has read one (`bd show tla-fwkz.2`,
"I looked over the first 'read'"). 25 are unread, which is four sittings at six
a sitting. Volume is not short, and I can't measure from here whether the
insight column lands in 10 minutes, which is the thing a third wave would need
to know.

**Depth on rows the corpus meets without teaching.** Partly. The met-against-
taught pass in Part 1 finds 8 such rows out of 93, five of them `high`. Three
of the five have nothing to work out (`EXTENDS`, `Strings`, `CONSTANT`), and
forcing a model onto them is the v1 failure the epic names. One has a real
model (K063, `06-latch`). Two have a mechanism without a moment (K050, K042),
and I've put them in tier 3. So depth justifies one model, maybe two, not a
wave.

**The PlusCal boundary.** No. Two rows are unreached, `goto` is retired as
anti-idiomatic, and `skip` is one keyword. `08-retry` carries `skip` as a side
effect of an `either` insight, and that's the right way round.

**Materially fewer than assumed.** Yes. Eight now, against the twelve I'd
drafted and the "dozens" the channel was framed around. The eight are the
models whose insight no landed model carries, under the seven axes in Part 3,
and each also lifts at least one thin row from the table in Part 1 (`model
value` to 2, `struct set` stays at 1 since Lossy was cut, `:>` and `@@` and `@`
to 2, `CHOOSE` to 2, `RECURSIVE` from about-in-1 to about-in-3, sequence
operators to 2). After eight, the next candidates are the ones I rated medium,
and I'd rather Frank read the eight than I guess which medium ones land.

So the plain answer: 25 is close to enough. Eight more is the case for depth
and differentiation, and after that the reading channel should wait for
reactions while the tokens go to the drill audit.

### The drill channel

The measured gap doesn't justify new drill items, and I'd rule no new items
this cycle.

The non-PlusCal gap is one row, K068 `<>[]`. No drill answer is `<>[]`-shaped,
though `drill/temporal/01-print-job/ANSWER.md:42` lists it as a rejected
variant. Closing it is one item, or one accepted-variant row in an existing
temporal item, and either can wait.

The throughput side is the real constraint. 64 items at ten minutes each is
about eleven hours of drilling, and one has been attempted. The run on
2026-10-14 produced two modules and two traces for `control-state/01` and no
mark, so the loop works and supply isn't what's short.

What's worth doing instead, in order:

1. `tla-3hwj`, the telegraph audit over the 40 never-ranked prompts.
2. The K068 variant row, if a temporal author is in that tree anyway.
3. `tla-hp23`, which is Frank's call and shouldn't be made for him.

The audit is the better value because it touches items Frank will meet, and
the three ranked families found the shape in about half their items
(`bd show tla-3hwj`). On `tla-hp23`, my read is that asking the learner to
check the table doesn't give the trap away, since he still has to find which
row his rule misfires on. That's a judgment about his learning, and the bead
is right to leave it with him.

## Findings for central

- `PROGRESS.tsv` doesn't exist. One attempt, zero marks, from `LAST-SERVED` and the study tree.
- The tool-shell `grep` is `ugrep` and disagrees with GNU grep on at least one pattern. Gates unaffected. Scans typed into the Bash tool are.
- The drill side declares 79 rows under the gate's reader, not the 45 floor drawer F29 reports.
- Reached by neither channel: K026 `skip`, K028 `goto`. Nothing else.
- Met but never taught, by the probe test: 8 rows, 5 of them `high`, listed in Part 1.
- Three regex rows produced plausible wrong counts (`[]`, `<>`, `[][`) and any gated map should hand check those three.
- No change proposed to `harness/Gate.tla` or `harness/verdict.sh`.
- No change proposed to any file the five running workers own.
