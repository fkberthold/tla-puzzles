# Authoring evidence: chapter 3 exercise set

Bead `tla-jb7f.15`. Written while the set was built, not after.

## Toolchain

- `tlc` reports `TLC2 Version 2026.07.31.184830 (rev: 30cc360)`, the pinned
  build the pre-flight battery asks for.
- `pcal` is `/home/frank/bin/pcal`, a wrapper on `pcal.trans` in the same
  `tla2tools.jar`. It reports `pcal.trans Version 1.12 of 01 July 2024`.
- Every reference is committed with its translation in place, so a reader can
  run the whole set without translating anything first. The three starters are
  the exception, and Ex2's is the exception to that.

Two `pcal` habits worth knowing before you drive it:

- It rewrites the `.cfg` next to the module unless you pass `-nocfg`. Every
  translation in this set used `-nocfg`.
- It leaves a `.old` backup beside anything it rewrites. Those are deleted
  here rather than committed.

## Stated outcomes

One confirmation sweep over the committed tree, after the last edit. A scratch
driver ran `harness/verdict.sh -c <dir>/<name>.cfg <dir>/<name>.tla` for each
row:

```
== references ==
references Ex1Dispenser       OK               rc=0
references Ex1DispenserFail   ASSERT_VIOLATION rc=14
references Ex2Fresh           OK               rc=0
references Ex2Stale           ASSERT_VIOLATION rc=14
references Ex3Retry           OK               rc=0
references Ex3RetryFail       CONFIG_ERROR     rc=151
references Ex4Tanks           OK               rc=0
references Ex4TanksSplit      ASSERT_VIOLATION rc=14
references Ex5DeadLabel       OK               rc=0
references Ex5LiveLabel       ASSERT_VIOLATION rc=14

== starters, as delivered ==
starters   Ex2Stale           ASSERT_VIOLATION rc=14
starters   Ex4Tanks           CONFIG_ERROR     rc=151
starters   Ex5Sensor          CONFIG_ERROR     rc=151
```

The two starters that ship untranslated read `CONFIG_ERROR` until the learner
runs `pcal`. Measured after translating a scratch copy of each:

```
Ex4Tanks     after pcal (rc=0)   ASSERT_VIOLATION rc=14
Ex5Sensor    after pcal (rc=0)   OK               rc=0
```

Ex4's skeleton is red on arrival because a `skip` moves no water. Ex5's is
green on arrival, which is the whole point of that exercise.

Ex3's fail run has a translator half as well as a TLC half:

```
$ pcal -nocfg Ex3RetryFail.tla
Unrecoverable error:
 -- Missing label at the following location:
     line 27, column 7.
pcal rc=255
```

Line 27 is the assignment sitting after the `goto`. `pcal` refuses, writes no
translation, and TLC then has no `Spec` for the `.cfg` to name. That is the
`CONFIG_ERROR` row above, and it matches `harness/verdict.sh`'s own note that
151 is the semantic half of config failure rather than a syntax failure.

Nothing measured here contradicted the §5.1 exit-code table or the verdict
table in `harness/verdict.sh`.

77 `harness/verdict.sh` invocations in total across the build: 18 while the
references and starters were taking shape, 46 across two mutant passes, and 13
in the final sweep above.

## Mutant pass

22 mutants, 3 to 5 per pass reference, one edit each, all driven through
`pcal` and then `harness/verdict.sh`. Every mutant must flip the reference's
`OK` to a failing verdict.

| Reference | Mutant | The one edit | Verdict | rc |
|---|---|---|---|---|
| Ex1Dispenser | Ex1M1 | `owed >= 5` to `owed > 5` | `ASSERT_VIOLATION` | 14 |
| Ex1Dispenser | Ex1M2 | `while owed > 0` to `while owed > 1` | `ASSERT_VIOLATION` | 14 |
| Ex1Dispenser | Ex1M3 | macro pays `owed - 1` instead of `owed - value` | `ASSERT_VIOLATION` | 14 |
| Ex1Dispenser | Ex1M4 | `Give(pennies, 1)` to `Give(pennies, 2)` | `ASSERT_VIOLATION` | 14 |
| Ex1Dispenser | Ex1M5 | macro counts `+ 2` instead of `+ 1` | `ASSERT_VIOLATION` | 14 |
| Ex2Fresh | Ex2M1 | `setpoint + 2` to `setpoint + 3` | `ASSERT_VIOLATION` | 14 |
| Ex2Fresh | Ex2M2 | `setpoint - 1` to `setpoint - 2` | `ASSERT_VIOLATION` | 14 |
| Ex2Fresh | Ex2M3 | initial `setpoint = 68` to `70` | `ASSERT_VIOLATION` | 14 |
| Ex2Fresh | Ex2M4 | delete the `Cooler:` label | `CONFIG_ERROR` | 151 |
| Ex3Retry | Ex3M1 | `attempts < 3` to `attempts < 2` | `ASSERT_VIOLATION` | 14 |
| Ex3Retry | Ex3M2 | `attempts + 1` to `attempts + 2` | `ASSERT_VIOLATION` | 14 |
| Ex3Retry | Ex3M3 | `goto Dial` to `goto Report` | `ASSERT_VIOLATION` | 14 |
| Ex3Retry | Ex3M4 | `linked := TRUE` to `linked := FALSE` | `ASSERT_VIOLATION` | 14 |
| Ex3Retry | Ex3M5 | a statement after the `goto` | `CONFIG_ERROR` | 151 |
| Ex4Tanks | Ex4M1 | `\|\|` to `;` | `CONFIG_ERROR` | 151 |
| Ex4Tanks | Ex4M2 | tank 2 gains `2` instead of `amount` | `ASSERT_VIOLATION` | 14 |
| Ex4Tanks | Ex4M3 | `with amount = 3` to `with amount = 4` | `ASSERT_VIOLATION` | 14 |
| Ex4Tanks | Ex4M4 | `tanks = <<7, 0>>` to `<<7, 1>>` | `ASSERT_VIOLATION` | 14 |
| Ex5DeadLabel | Ex5M1 | `temp \in 0..30` to `0..50` | `ASSERT_VIOLATION` | 14 |
| Ex5DeadLabel | Ex5M2 | `temp > 40` to `temp > 20` | `ASSERT_VIOLATION` | 14 |
| Ex5DeadLabel | Ex5M3 | `temp > 40` to `temp > -1` | `ASSERT_VIOLATION` | 14 |
| Ex5DeadLabel | Ex5M4 | `skip` in `Settle` to `assert FALSE` | `ASSERT_VIOLATION` | 14 |

22 caught, 0 inert, 0 skipped. 19 rows land on `ASSERT_VIOLATION` rc 14 and 3
on `CONFIG_ERROR` rc 151. The three `CONFIG_ERROR` rows are mutants that break
a labeling rule, so `pcal` exits 255 and refuses to translate. Those flip the
outcome as surely as the assertion failures do.

Correction, 2026-08-11, central, after the cold-solve review: the prose above
originally said 23. The table has always held 22 measured rows, and the
authoring agent was gone before the discrepancy surfaced, so whether a row was
lost or the count was inflated is not recoverable. The table is the evidence
and the claim now matches it. The 46-run figure in the invocation tally is
left as recorded, since it cannot be decomposed after the fact.

### One mutant escaped on the first pass, and Ex1 changed because of it

The first pass ran the same 23 mutants against an earlier `Ex1Dispenser` and
came back 22 caught, 1 inert:

```
Ex1M3                  pcal=0    OK               rc=0
```

Ex1M3 makes the macro subtract 1 from `owed` whatever coin it hands over, so
the dispenser counts a nickel for every penny it pays out. The earlier assert
set was `owed = 0` and `pennies < 5`. Both still hold under the mutant, since
the guard keeps the penny count low and the loop still drains `owed` to
exactly zero. Nothing in the spec ever looked at `nickels`.

I checked the mutant file before believing the result, because an inert
mutant and a `sed` that never matched look identical from the outside. The
edit was there.

So Ex1 grew a `target` variable, a `Record` label that saves the original
amount, and a third assert:

```
assert nickels * 5 + pennies = target;
```

The second pass caught Ex1M3 at `ASSERT_VIOLATION` rc 14. That change is the
whole reason Ex1 has three asserts rather than two, and the comment at the
top of `references/Ex1Dispenser.tla` points back here.

## A `pcal` trap found while writing Ex3

`references/Ex3RetryFail.tla` first carried a header comment explaining that
the module has no translation block. Writing that explanation used the two
marker words `pcal` scans for, and the run died:

```
Unrecoverable error:
 -- No line containing `END TRANSLATION.
```

`pcal` scans the whole file for the opening marker, including comments, and
then demands the closing one. A mention in prose reads as a real translation
block. The comment was reworded, and it now says so in the file, since the
next person to write a module about translation will hit the same thing.

## The chapter's worked examples, and how this set stays off them

Read from `docs/core/pluscal.rst` at clone SHA
`09840bfc2ee9a88cdbedb672be77a6c73942fe16`, along with the spec files it
includes. None of the following is reused here, in surface or in shape:

- `docs/specs/pluscal.tla`: the warm-up with `x = 2`, `y = TRUE` and labels
  `A` and `B`.
- `docs/specs/duplicates/1/`, `/2/`, `/3/`: the duplication checker over
  `seq`, `index`, `seen` and `is_unique`, in all three variants. This is the
  chapter's running example and the one thing an exercise set for chapter 3
  is most likely to walk into.
- `Label1: x := Sum(seq)` and the `SendRequest:` / `GetResponse:` pair, the
  atomicity illustrations.
- The `Sum:` while loop that adds up a sequence, in both its forms. No
  exercise here loops over a sequence at all.
- `seq[1] := seq[1] + 1 || seq[2] := seq[2] - 1`, the `||` snippet. Ex4 uses
  the same operator, which is unavoidable, on two named tanks with an audit
  step that makes the atomicity observable. The chapter's snippet has no
  model and no outcome.
- `A: if bool then B: skip else skip end if; x := 1;`, the missing-label
  illustration. Ex3 drills the `goto` rule instead, which the chapter states
  in one line and never shows.
- `macro inc(var) begin if var < 10 then var := var + 1; end if; end macro;`.
  Ex1's macro takes two arguments and updates two variables.
- `with tmp_x = x, tmp_y = y do ... end with;`, the swap. Ex4 uses `with` to
  name a constant instead.
- `variables x \in 1..1000; A: x := 0; B: x := x+1;`, the state-space
  collapse illustration.

The chapter also spends a section on reading TLC's run statistics. That is a
theme rather than an example, and `COVERAGE.md` records what this set does
with it and what it leaves alone.

## Conversion to c-syntax, 2026-08-12

Converted to c-syntax 2026-08-12 (bead `tla-s7hw`), on Frank's ruling that all
exercise PlusCal use braces, not `begin`/`end`. Every starter and reference
under `exercises/ch03/` was rewritten by hand from p-syntax to c-syntax and
retranslated with `pcal`. Variable names, labels, guards, and asserts stayed
the same. Only the algorithm's surface syntax changed.

Two checks carried the proof.

First, `pcal` reports the same `chksum(pcal)` value before and after
conversion, for every reference that ships a translation. That checksum is
computed from the parsed algorithm, not the source text, so an unchanged
value means `pcal` sees the exact same algorithm under the new syntax. Every
converted reference matched: `Ex1Dispenser` (`d1e8c926`), `Ex1DispenserFail`
(`6d3c1264`), `Ex2Fresh`/`Ex2Stale` (`e05ac07d`), `Ex3Retry` (`7ca0a0f8`),
`Ex4Tanks` (`f4426267`), `Ex4TanksSplit` (`29ba82c4`), `Ex5DeadLabel`
(`46f245ce`), `Ex5LiveLabel` (`1946d781`).

Second, the full 13-row stated-outcome sweep and the 22-mutant pass both
ran again against the converted tree, through `harness/verdict.sh`. All 13
outcomes matched the table above exactly, token and rc. All 22 mutants
matched the mutant table exactly, token and rc. No adaptation changed a
verdict.

`elsif` does not exist in c-syntax. Every p-syntax `elsif` in this set
(`Ex5DeadLabel`, `Ex5LiveLabel`, the `Ex5Sensor` starter) became a nested
`if`/`else`, which is the only c-syntax form for a three-way branch. `pcal`
confirmed this is the same translation p-syntax `elsif` already produced:
the nested-if source and the old `elsif` source hit the same `chksum(pcal)`.

`Ex2Stale` needed one extra step beyond a plain retranslation, because its
whole point is a translation that no longer matches its own source. A fresh
`pcal` run on the converted source gives the correct, matching translation
(`setpoint' = setpoint + 2`), which is what `Ex2Fresh` now carries. `Ex2Stale`
instead keeps the same one-line divergence it always had: the `Warmer`
action reads `setpoint' = setpoint + 3` by hand, with the `chksum(tla)`
comment left at the value the fresh, pre-edit translation actually had. That
is what "stale" means: a checksum on record that no longer matches the code
below it. The starter copy carries the same translation block as the
reference, unchanged, matching how the original p-syntax pair related to
each other.

`Ex3RetryFail` stays broken the same way. The statement after the `goto`
with no label between them is still a labeling-rule violation under
c-syntax, and `pcal` still refuses it: `Unrecoverable error: -- Missing
label`, rc 255. The header comment warning about `pcal`'s own translation-
marker scan needed no change. It never named the p-syntax `begin`/`end`
forms.

The 22 mutants from the table above needed no adapted edits. Every edit
carried over as a direct syntactic transliteration: `while owed > 0` became
`while (owed > 0)`, `if attempts < 3 then` became `if (attempts < 3) {`, and
so on. The two structural mutants that break translation on purpose,
`Ex2M4` (delete a label, forcing a double assignment into one step) and
`Ex4M1` (`||` to `;`, same double-assignment trap), still land on
`CONFIG_ERROR` under c-syntax through the same labeling-rule failure `pcal`
already used to catch them under p-syntax. `exercises/ch03/reports/
mutant-sweep.sh` is the runner that reproduces this pass: for each mutant it
takes the committed reference, strips its translation, applies the one
documented edit, retranslates, and checks the verdict. Run it with `bash
exercises/ch03/reports/mutant-sweep.sh`.
