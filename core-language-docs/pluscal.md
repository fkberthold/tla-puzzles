# PlusCal

PlusCal is an algorithm language that lives inside a TLA+ comment and compiles
to TLA+ in the same file. You write labeled statements with assignment, loops,
branches and processes. A translator turns them into `Init`, `Next` and one
action per label, and writes that TLA+ underneath your comment.

What pays for it is control flow. A sequence of steps, a loop, and a few
processes taking turns is tedious as a transition relation and plain as
statements. Lamport's stated reason for the language is that its structures
describe control state more naturally than an explicit `pc` variable does.

What it costs is a second artifact. The translation is what TLC checks and what
a counterexample names, so you end up reading both. Two things are
inexpressible in PlusCal besides, and the last section of this page names them.

Every module on this page is a real file under
`core-language-docs/snippets/`, and `run-all.sh` beside them checks each one
against the exit code and the state count quoted here. Measured on TLC
2026.07.31.184830 and `pcal.trans` 1.12 of 01 July 2024, on 2026-10-22.

## The constructs

| Construct | Shape | What it means | In published specs |
|---|---|---|---|
| algorithm block | `(*--algorithm Name { variables x = 0; { L: x := 1; } }*)` | the whole algorithm, inside a TLA+ comment, with the translation beneath it | 59 of 666 modules carry a translation |
| `:=` assignment | `x := expr;` | updates a variable. `x = expr` compares or binds and never updates | not counted |
| label | `L: statement;` | names one step. Everything up to the next label happens at once | not counted |
| `\|\|` simultaneous assignment | `seq[1] := a \|\| seq[2] := b;` | two updates to one variable in one step | not counted |
| `skip` | `skip;` | does nothing. Translates to a bare `TRUE` conjunct | not counted |
| `assert` | `assert expr;` | stops the run where `expr` is false. Needs `EXTENDS TLC` | not counted |
| `goto` | `goto L;` | jumps to label `L`. A label has to follow the jump | not counted |
| PlusCal `if` | `if (e) { ... } else { ... };` | branches on `e`, with `else if` for more arms | not counted |
| `macro` | `macro Name(a) { ... }` | a rewrite expanded at the call site. No label inside it | not counted |
| `with` | `with (x = expr) { ... };` | binds `x` for that block only. No label inside it | not counted |
| `while` | `while (e) { ... }` | the only loop form. The statement before it has to carry a label | not counted |
| `\in` on a variable declaration | `variables x \in S;` | one initial state per member of `S` | not counted |
| `define` block | `define { Op == ... }` | raw TLA+ definitions, copied into the translation untouched | not counted |
| `pc` | `pc = "L"`, or `pc[self] = "L"` | the label whose action is enabled next | in the `vars` tuple of 49 of 59 translated modules |
| nondeterministic `with` | `with (x \in S) { ... };` | any member of `S`. Translates to `\E x \in S` | not counted |
| `either-or` | `either { ... } or { ... };` | any one branch. Translates to `\/` | not counted |
| `process` (single) | `process (name = val) { L: ... }` | one process at a fixed identity | not counted |
| `pc[...]` | `pc[self]`, `pc["port"]` | with more than one process, `pc` is a function from identity to label | not counted |
| process-local variable | `process (p \in S) variables i = 0; { ... }` | per-process state, unreachable from outside the process | not counted |
| process set | `process (p \in S) { ... }` | one process per member of `S`, all running the same body | not counted |
| `self` | `queue := Append(queue, self);` | the running process's own identity | not counted |
| `await` | `await e;` | holds the label until `e` is true. Translates to a guard conjunct | not counted |
| `procedure` | `procedure Name(a) variables v = 0; { L1: ...; return; }` | a labeled body with its own arguments and locals | not counted |
| `call` | `call Name(v);` | enters the procedure. A `goto`, a label or a `return` has to follow | not counted |
| `return` | `return;` | hands control back to the caller | not counted |
| `fair process` | `fair process (p = v) { ... }` | weak fairness on that process's actions | not counted |
| `fair+` | `fair+ process (p = v) { ... }`, or `L:+` for one label | strong fairness, on the process or on the one action | not counted |
| `ProcSet` | `ProcSet == (Threads)` | the set of process identities, generated, and the domain of `pc` | not counted |
| label-as-action encoding | `L(self) == /\ pc[self] = "L" /\ ... /\ pc' = [pc EXCEPT ![self] = "M"]` | guard on the current label, then advance it. One action per label | not counted |
| `Trans` | `Trans(p, from, to) == /\ pc[p] = from /\ pc' = [pc EXCEPT ![p] = to]` | the `pc` half of a label action, factored out of every action | not counted |
| `Terminating` | `Terminating == (\A p \in ProcSet: pc[p] = "Done") /\ UNCHANGED vars` | endless stuttering once every process is past its last label | not counted |

Two of the thirty-one rows carry a figure, so twenty-nine read "not counted".
Both figures come from a survey of 666 modules and 337 configuration files
drawn from 16 public repositories, read on 2026-09-05. That survey measured
how published specs use TLA+, and 59 of its 666 modules carry a PlusCal
translation, so there was little PlusCal in it to count. "Not counted" means
the survey has no number for the construct. It does not mean the construct is
rare. Every other count on this page is one I measured on this build.

**Weights**: no construct in this family is rated high-frequency in this
project's drill inventory, and that is a measurement rather than an oversight.
The 31 constructs here are weighted 20 low and 11 medium, with no high. The
weight came from two sources that agreed. 3 of this project's 12 reference
specs carry a translation, and 59 of the survey's 666 modules do.

That is a fact about how often PlusCal shows up and not an argument against
the language. Every source in the survey's reading that gives a reason for the
split gives a **domain** reason rather than an expertise one. The TLA+ Toolbox
paper calls PlusCal "especially well suited to express sequential and
shared-memory multithreaded algorithms", and the published corpus is mostly
consensus protocols. learntla's own position is that "plenty of people never
learn pure TLA+ and get along fine with just PlusCal". This project treats
PlusCal as something to read rather than something to produce. That's a
decision about one reader's practice and says nothing about the language.

**Dialect**: the shapes above are c-syntax, with braces. Frank settled that on
2026-08-12 for readability, and every module authored here uses it. learntla
teaches p-syntax, so the chapter cheat sheets carry forms like
`with x = expr do ... end with;` where the table carries
`with (x = expr) { ... };`. The two dialects translate to the same TLA+. Where
a cheat sheet and this page disagree on punctuation, that is why.

## `pc` enters the state only when control has somewhere else to be

The translation adds a variable your algorithm never mentions. `pc` holds the
label whose action runs next, and once it exists every state carries it, every
action guards on it and `vars` covers it.

It is not unconditional, and the condition is the interesting part. `Trestle`
is one label wrapped in a loop that never ends:

```tla
---- MODULE Trestle ----
EXTENDS Integers

(*--algorithm trestle {
  variables span = 0;
  {
    Lay:
      while (TRUE) {
        span := (span + 1) % 3;
      }
  }
}*)
```

Here is the whole translation, markers and all, and `pc` is absent from it:

```tla
\* BEGIN TRANSLATION (chksum(pcal) = "6ad25dfc" /\ chksum(tla) = "784bba6a")
VARIABLE span

vars == << span >>

Init == (* Global variables *)
        /\ span = 0

Next == span' = (span + 1) % 3

Spec == Init /\ [][Next]_vars

\* END TRANSLATION
```

The two marker comments are the translator's, and the last section of this
page is about the checksums in the first one. Later quotes on this page leave
the markers off and show the body.

Add one label inside the loop and the shape changes. `TrestleTwo` is the same
algorithm with a `Rest: skip;` after the assignment:

```tla
VARIABLES pc, span

vars == << pc, span >>

Init == (* Global variables *)
        /\ span = 0
        /\ pc = "Lay"

Lay == /\ pc = "Lay"
       /\ span' = (span + 1) % 3
       /\ pc' = "Rest"

Rest == /\ pc = "Rest"
        /\ TRUE
        /\ pc' = "Lay"
        /\ span' = span

Next == Lay \/ Rest
```

`span` takes three values in both, so the state space tells you what `pc`
cost. `Trestle` reads:

```
4 states generated, 3 distinct states found, 0 states left on queue.
```

and `TrestleTwo` reads:

```
7 states generated, 6 distinct states found, 0 states left on queue.
```

Three against six, and both runs exit 0. There is no error channel for this.

My read of the rule is that `pc` appears when control has more than one place
to be, and that "Done" counts as a place. A loop that never ends has one
label and one place, so the translator drops the variable. An algorithm that
can finish has at least two, so it keeps it. `Flume` is the check on that: one
label, no loop, and it gets `pc` with the values `"Pour"` and `"Done"`. I have
not read the translator's source, so treat the rule as a description of four
measured translations rather than as the implementation.

Two consequences follow from `pc` being in the state.

A partial subscript now has to decide about it. `[][A]_v` is sound when `v`
covers every variable `A` mentions, and every label action mentions `pc`. The
survey found `pc` in the `vars` tuple of 49 of the 59 translated modules it
read, so the usual answer is to cover it and move on.

And termination becomes something you can say. `<>(pc = "Done")` is a
property, where in a raw spec with no control variable there is nothing to
write it over. The survey found 29 of its 59 translated modules defining
`Termination` against 41 in the whole corpus. So 71% of the corpus's
termination properties sit in the 9% of modules that are PlusCal.

## A label is where a step ends, so moving one rewrites the algorithm

A label is not a comment and it is not a name for a line. It's the boundary of
one atomic step, which means it's the only place another process gets to move
and the only place TLC records a state.

`Bellows` has two hands, each reading a shared counter and then writing it
back one higher. The read and the write are two macro calls in one label:

```tla
(*--algorithm bellows {
  variables chamber = 0;

  define {
    BothDone == \A h \in Hands : pc[h] = "Done"
    NoLoss == BothDone => chamber = Cardinality(Hands)
  }

  macro Lift(seen) {
    seen := chamber;
  }

  macro Press(seen) {
    chamber := seen + 1;
  }

  process (hand \in Hands)
  variables seen = 0;
  {
    Stroke:
      Lift(seen);
      Press(seen);
  }
}*)
```

`BellowsSplit` is the same file with a second label between the two calls.
Nothing else differs. Put the two translated actions side by side and the whole
change is one apostrophe:

```tla
Stroke(self) == /\ pc[self] = "Stroke"
                /\ seen' = [seen EXCEPT ![self] = chamber]
                /\ chamber' = seen'[self] + 1
                /\ pc' = [pc EXCEPT ![self] = "Done"]
```

```tla
Stroke(self) == /\ pc[self] = "Stroke"
                /\ seen' = [seen EXCEPT ![self] = chamber]
                /\ pc' = [pc EXCEPT ![self] = "Push"]
                /\ UNCHANGED chamber

Push(self) == /\ pc[self] = "Push"
              /\ chamber' = seen[self] + 1
              /\ pc' = [pc EXCEPT ![self] = "Done"]
              /\ seen' = seen
```

In one label the write reads `seen'`, the value the read just assigned. Split
across two, it reads `seen`. Inside a label the translator threads the primed
value through, which is what makes a sequence of statements act as one step.
Across a label it cannot, because the other hand may have moved in between.

The invariant says no count gets lost. `Bellows` exits 0 over 5 distinct
states. `BellowsSplit` exits 12:

```
Error: Invariant NoLoss is violated.
Error: The behavior up to this point is:
State 1: <Initial predicate>
/\ seen = <<0, 0>>
/\ pc = <<"Stroke", "Stroke">>
/\ chamber = 0

State 2: <Stroke(1) line 49, col 17 to line 52, col 36 of module BellowsSplit>
/\ seen = <<0, 0>>
/\ pc = <<"Push", "Stroke">>
/\ chamber = 0

State 3: <Stroke(2) line 49, col 17 to line 52, col 36 of module BellowsSplit>
/\ seen = <<0, 0>>
/\ pc = <<"Push", "Push">>
/\ chamber = 0

State 4: <Push(1) line 54, col 15 to line 57, col 29 of module BellowsSplit>
/\ seen = <<0, 0>>
/\ pc = <<"Done", "Push">>
/\ chamber = 1

State 5: <Push(2) line 54, col 15 to line 57, col 29 of module BellowsSplit>
/\ seen = <<0, 0>>
/\ pc = <<"Done", "Done">>
/\ chamber = 1
```

Both hands read 0 and both wrote 1. With the invariant taken off, the state
space goes from 5 to 13, so the count moves too.

The same trap arrives from a second direction, and that one has no violation
in it at all. `Flume` assigns `x` then `y` in one label. `FlumeTwo` splits
them. Under `INVARIANT Level`, where `Level == x = y`, `Flume` exits 0 and
`FlumeTwo` exits 12 on the state between the assignments. Take the invariant
off and the two exit 0 at 2 and 3 distinct states.

So a label is an interleaving point you are choosing. If you are modeling a
read-modify-write and want the race, the label goes in the middle. If you want
the operation atomic, it does not. Nothing in the syntax says which you meant.

## A missing label is a refusal in one place and a silent edit in the other

Where the translator requires a label it refuses outright, with a line and a
column. `JigRaw` puts a `while` loop after an assignment in the same block:

```tla
(*--algorithm jigraw {
  variables bore = 0;
  {
    Start:
      bore := 1;
      while (bore < 3) {
        bore := bore + 1;
      }
  }
}*)
```

`pcal JigRaw.tla` prints this and writes nothing:

```
pcal.trans Version 1.12 of 01 July 2024

Unrecoverable error:
 -- Missing label at the following location:
     line 21, column 7.
```

`Jig.tla` is the same source with a `Ream:` label on the loop, and it
translates. The file with no label stays untranslated on purpose, so running
TLC against it exits 151:

```
Error: The name Spec specified in the configuration file
is not defined in the specification.
```

Two more positions refuse, with different messages. Hand `pcal` a
`macro Bump() { Inner: n := n + 1; }` and it reads "A label may not appear in
a macro." Put the same label inside a `with` block and it reads "Label in
`with' statement". I read both as the same rule. A macro and a `with` expand
into the step around them, so neither can hold a step boundary of its own.

Everywhere else a label is optional, and the previous section is what happens
when you add or drop one. So "missing label" is two unrelated failures wearing
one name. One of them stops the translator. The other one ships.

## `await` translates to a guard, and a stuck spec is TLC's report rather than PlusCal's

`await e;` holds a label until `e` is true. It compiles to `e` as a conjunct of
the action, next to the `pc` guard, and nothing marks it as the author's
blocking intent.

`Capstan` has two crews taking two pawls in opposite order:

```tla
(*--algorithm capstan {
  variables pawlFore = TRUE, pawlAft = TRUE;

  process (port = "port") {
    PortFore:
      await pawlFore;
      pawlFore := FALSE;
    PortAft:
      await pawlAft;
      pawlAft := FALSE;
  }

  process (stbd = "stbd") {
    StbdAft:
      await pawlAft;
      pawlAft := FALSE;
    StbdFore:
      await pawlFore;
      pawlFore := FALSE;
  }
}*)
```

The translated action puts the `await` and the `pc` guard on adjacent lines:

```tla
PortFore == /\ pc["port"] = "PortFore"
            /\ pawlFore
            /\ pawlFore' = FALSE
            /\ pc' = [pc EXCEPT !["port"] = "PortAft"]
            /\ UNCHANGED pawlAft
```

Take one pawl each and neither crew can take the second. TLC exits 11:

```
Error: Deadlock reached.
Error: The behavior up to this point is:
State 1: <Initial predicate>
/\ pawlFore = TRUE
/\ pawlAft = TRUE
/\ pc = [port |-> "PortFore", stbd |-> "StbdAft"]

State 2: <PortFore line 37, col 13 to line 41, col 32 of module Capstan>
/\ pawlFore = FALSE
/\ pawlAft = TRUE
/\ pc = [port |-> "PortAft", stbd |-> "StbdAft"]

State 3: <PortAft line 43, col 12 to line 47, col 32 of module Capstan>
/\ pawlFore = FALSE
/\ pawlAft = FALSE
/\ pc = [port |-> "Done", stbd |-> "StbdAft"]
```

Note what that trace found. The port crew took both pawls and finished, so the
starboard crew is stuck at its first label with nothing left to take. The
opposite-order grab is not the only way in.

That report comes from the model configuration and not from the algorithm.
`CHECK_DEADLOCK FALSE` turns it off, and the same module over the same 6
distinct states then exits 0 with "No error has been found".

The spec has not changed. What changed is which channel notices. Add
`PROPERTY Termination` to the run with the check still off and it exits 13:

```
Error: Temporal property Termination was violated.

Error: The following behavior constitutes a counter-example:

State 1: <Initial predicate>
/\ pawlFore = TRUE
/\ pawlAft = TRUE
/\ pc = [port |-> "PortFore", stbd |-> "StbdAft"]

State 2: <PortFore line 37, col 13 to line 41, col 32 of module Capstan>
/\ pawlFore = FALSE
/\ pawlAft = TRUE
/\ pc = [port |-> "PortAft", stbd |-> "StbdAft"]

State 3: <StbdAft line 51, col 12 to line 55, col 32 of module Capstan>
/\ pawlFore = FALSE
/\ pawlAft = FALSE
/\ pc = [port |-> "PortAft", stbd |-> "StbdFore"]

State 4: Stuttering
```

Three codes over one module: 11 from the deadlock check, 0 from turning it
off, 13 from asking about termination instead. The deadlock trace above picks
a different interleaving than this one, since the safety pass and the temporal
pass each report the first behavior they find. Note what the generated
`Terminating` disjunct does and does not cover. It allows stuttering once
**every** process is past its last label, so it rescues a clean finish and
does nothing for a crew stuck halfway.

## `fair algorithm` is one line of the translation, and nothing else is

A plain algorithm declaration gives you a safety spec. `Init /\ [][Next]_vars`
admits a behavior that takes one step and then stutters forever, so any
liveness property over it fails.

`Pawl` counts to three in a loop and declares nothing about fairness. Under
`PROPERTY Termination` it exits 13:

```
Error: Temporal property Termination was violated.

Error: The following behavior constitutes a counter-example:

State 1: <Initial predicate>
/\ notch = 0
/\ pc = "Climb"

State 2: <Climb line 22, col 10 to line 27, col 37 of module Pawl>
/\ notch = 1
/\ pc = "Climb"

State 3: <Climb line 22, col 10 to line 27, col 37 of module Pawl>
/\ notch = 2
/\ pc = "Climb"

State 4: <Climb line 22, col 10 to line 27, col 37 of module Pawl>
/\ notch = 3
/\ pc = "Climb"

State 5: Stuttering
```

`PawlFair` is the same algorithm declared as a fair one. Diff the two
translations and the whole difference is a conjunct:

```tla
Spec == Init /\ [][Next]_vars
```

```tla
Spec == /\ Init /\ [][Next]_vars
        /\ WF_vars(Next)
```

That run exits 0 over the same 5 distinct states. One line, and a liveness
property that could not hold now holds.

The survey found 5 of its 59 translated modules using the algorithm-level fair
declaration. I'd read that as liveness being checked rarely rather than
fairness being hard. 196 of the survey's 337 configurations declare no fairness
anywhere, and 220 declare no property at all. Pure safety is the majority case
in published work.

Three forms are available and they are not interchangeable. `fair algorithm`
puts weak fairness on the whole thing. `fair process` puts it on one process's
actions. `fair+` and the `L:+` label suffix ask for strong fairness, which is
the one to reach for when an action can be disabled and re-enabled repeatedly.

## The translation is committed, so what gets checked is not what you read

All 59 translated modules in the survey carry the translated TLA+ in the file
rather than generating it at check time. That is the normal practice and it has
a consequence the Toolbox paper names directly: the algorithm and its
translation "pose the risk that they get out of sync unnoticed".

`Treadle.tla` is that risk made into a file. Its source says the second label
puts `stroke` back to 0. One line of its generated block was changed by hand
afterwards, so the block says 2. The invariant is `stroke \in {0, 1}`, and TLC
exits 12:

```
Error: Invariant Stroke is violated.
Error: The behavior up to this point is:
State 1: <Initial predicate>
/\ stroke = 0
/\ pc = "Press"

State 2: <Press line 31, col 10 to line 33, col 24 of module Treadle>
/\ stroke = 1
/\ pc = "Lift"

State 3: <Lift line 35, col 9 to line 37, col 23 of module Treadle>
/\ stroke = 2
/\ pc = "Done"
```

Read the algorithm and that trace is impossible. Read the translation and it's
the only thing that can happen. TLC never looked at the comment.

The marker line the translator writes carries two checksums, one over the
algorithm and one over the TLA+ it produced. That is the artifact that could
catch this, and nothing in the command-line toolchain reads it. The Toolbox
reads it and warns. A plain `tlc` run says nothing at all, and neither does
this project's own gate.

So two habits are worth having. Re-translate before you check, and read the
counterexample against the translated action it names rather than against the
statement you think it came from. The trace above points at `Lift` on line 35,
which is in the generated block, not at the `Lift:` label in the source.

## A `with` over an empty set is a dead action, not an error

`with (x \in S)` compiles to `\E x \in S`, and an existential over the empty
set is FALSE. The action is then never enabled, which is not an error in any
channel.

`Reamer` fits a bit drawn from a constant set:

```tla
(*--algorithm reamer {
  variables fitted = "none";
  {
    Fit:
      with (b \in Bits) {
        fitted := b;
      };
  }
}*)
```

The translation makes the quantifier visible:

```tla
Fit == /\ pc = "Fit"
       /\ \E b \in Bits:
            fitted' = b
       /\ pc' = "Done"
```

With `Bits = {"brace", "spur"}` the action opens a branch per member and the
invariant `fitted = "none"` is violated at depth 2, exit 12. With `Bits = {}`
nothing is enabled and `pc` never leaves `"Fit"`, so the deadlock check reports
it at the initial state and TLC exits 11:

```
Error: Deadlock reached.
Error: The behavior up to this point is:
State 1: <Initial predicate>
/\ fitted = "none"
/\ pc = "Fit"

1 states generated, 1 distinct states found, 0 states left on queue.
```

The dangerous run is the third one. Turn the deadlock check off and the same
empty set gives these two lines, with the fingerprint estimate between them:

```
Model checking completed. No error has been found.
1 states generated, 1 distinct states found, 0 states left on queue.
```

Exit 0, over one state, with an invariant that was checked and held. A spec
whose only action can never fire reads as a clean pass. The signal is the state
count, which is why the manifest beside these modules records it. Any time a
`with` or a process set draws from a configured constant, a model that sets
that constant empty checks nothing and says so in no words.

## Five of these are pure TLA+, and this curriculum needs you to write them

Five rows in the table above are not PlusCal syntax at all. `pc`, `ProcSet`,
the label-as-action encoding, `Trans` and `Terminating` are ordinary TLA+. The
first two are variables and operators the translator generates, and the last
three are idioms for hand-writing what it generates.

They are filed here on purpose rather than by mistake. Their subject is
PlusCal's control flow, and one reader learning to recognize that flow should
meet both spellings of it together. Looking for them under the temporal family
or the modules family will not find them, so this is where they live.

There's a live reason to care. This project treats PlusCal as something to
read and raw TLA+ as what you write. That makes hand-rolling an explicit `pc`
a required skill rather than an alternative to one. Lamport's stated reason
for inventing PlusCal is that its structures describe control state more
naturally than an explicit `pc` does. So these five are the thing he built the
language to spare you.

`Gantry.tla` is `BellowsSplit` with no translator anywhere near it:

```tla
VARIABLES pc, chamber, seen
vars == << pc, chamber, seen >>

ProcSet == Hands

BothDone == \A h \in Hands : pc[h] = "Done"
NoLoss == BothDone => chamber = Cardinality(Hands)

Init ==
  /\ chamber = 0
  /\ seen = [h \in Hands |-> 0]
  /\ pc = [h \in ProcSet |-> "Stroke"]

Trans(h, from, to) ==
  /\ pc[h] = from
  /\ pc' = [pc EXCEPT ![h] = to]

Stroke(h) ==
  /\ Trans(h, "Stroke", "Push")
  /\ seen' = [seen EXCEPT ![h] = chamber]
  /\ UNCHANGED chamber

Push(h) ==
  /\ Trans(h, "Push", "Done")
  /\ chamber' = seen[h] + 1
  /\ UNCHANGED seen

Terminating == BothDone /\ UNCHANGED vars

Next == (\E h \in Hands : Stroke(h) \/ Push(h)) \/ Terminating
```

It exits 12 on the same lost update at the same depth, and with the invariant
off it reads 13 distinct states, the same as the translated version. The
encoding is not an approximation of what the translator does. It is what the
translator does.

`Trans` is the one piece the translator does not write. It factors the `pc`
guard and the `pc` update out of every action, which is worth doing by hand
and is noise to generate. Compare `Stroke` above against the generated action
in the label section and the saving is two lines per label.

## What PlusCal cannot say

Two limits are worth knowing before you reach for the language, and both come
from the TLA+ Toolbox paper: "Neither the TLA+ concept of refinement nor
fine-grained fairness constraints can be expressed in PlusCal."

Refinement is the bigger of the two for this project, since it's a whole
chapter here. A refinement mapping is built with `INSTANCE ... WITH` and
checked as a property, and there is no PlusCal statement for either. See
[Modules](modules.md) for the mechanism and
[Refinement](../../chapter/refinement.md) for the chapter.

Fine-grained fairness means anything past the three forms the language offers.
`fair algorithm`, `fair process` and `fair+` cover weak and strong fairness at
the algorithm and process level. Fairness on one action, or on an action per
member of a set, is a `WF_` or `SF_` conjunct you write yourself.

The practical answer to both is a `define` block and a hand-written tail. The
block holds raw TLA+ the translator copies out untouched, and anything below
the translated region is yours. Every obligation a configuration names in this
project's three PlusCal reference specs is defined inside a `define` block.
`authoring/assay-office/reference/AssayOffice.tla:124` is the tail half of the
same pattern:

```tla
FairSpec ==
    /\ Spec
    /\ \A o \in Officers, w \in Wares : WF_vars(Deface(o, w))
```

That asks for weak fairness on one action per officer and ware. `fair process`
would have given fairness to the process body as a whole, which is a weaker
and different claim.

Lamport adds a third limit, which is scale: PlusCal "would not work well for
algorithms of more than one or two thousand lines." I have not seen that
boundary tested and would treat it as the author's estimate rather than a
measured ceiling.

## Where this is taught

The family spans six chapters, which is more than any other family in this
reference. learntla's PlusCal chapter supplies the statement language and this
project's chapter 3 exercise set follows it. Chapter 4 adds the `define` block
and the first look at `pc`. Chapter 7 covers the two nondeterministic forms.
Chapter 8 is concurrency, which is where `process`, `self`, `await`,
procedures and `pc` as a function arrive together. Chapter 9 adds the fairness
declarations alongside the temporal operators they serve. Chapter 12 is the
raw-TLA+ chapter, and the five pure constructs on this page are taught there.

So the five live at the far end of the curriculum from the syntax they encode,
and I think that ordering is right. The encoding only reads as an encoding
once you know what it's encoding.

One thing is not taught anywhere in the set, and that's the translator itself.
Nothing in the exercises covers running `pcal`, reading its refusals, or the
checksum in the marker line. The sections above on the missing label and on the
committed translation are that gap, filled from measurement rather than from a
chapter.

Lamport's own teaching advice is that students need to "know enough TLA+ to
understand the TLA+ translation of their PlusCal algorithms". That's close to
what this page assumes about its reader.
