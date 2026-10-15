# Drill coverage inventory

One row per TLA+ construct the drill corpus has to reach. 105 rows, one for
each `- Construct:` entry in the twelve `exercises/ch*/CHEATSHEET.md` files.
That count is the whole population, and `drill/COLD-LIST.md` is its flat
companion for a single self-assessment pass.

## For the gate author

Rows are **tab-delimited** and carry the literal first field `ROW`, so prose
in this file can never be read as data:

    grep '^ROW' drill/INVENTORY.md | cut -f3        # family of every row
    grep '^ROW' drill/INVENTORY.md | cut -f2,6      # id and weight
    grep '^ROW' drill/INVENTORY.md | cut -f10       # the coverage verdict

Ten fields, in order:

| # | field | contents |
|---|---|---|
| 1 | marker | the literal `ROW` |
| 2 | id | `K001`-`K105`, stable, never renumbered |
| 3 | family | one of the eight authoring partitions below |
| 4 | construct | verbatim from the cheat sheet entry |
| 5 | source | `file:line` of the `- Construct:` line it came from |
| 6 | weight | `high`, `medium` or `low` |
| 7 | basis | how that weight was derived, notation below |
| 8 | items | drill item slugs, comma separated |
| 9 | reading | reading item slugs, comma separated |
| 10 | coverage | `both`, `drill-only`, `reading-only` or `neither` |

Do not reformat the rows: the delimiter is a single tab and `cut` defaults to
it. Fields 1 to 7 are hand-authored. Fields 8, 9 and 10 are **generated**, so
do not hand-edit them either:

    bash scripts/gen-coverage.sh            # rewrite them from the corpora
    bash scripts/gen-coverage.sh --check    # fail if they have drifted

`harness/test-coverage-map.sh` runs the second form, so a field 8, 9 or 10
that disagrees with what `drill/*/*/META.md` and `reading/*/*/USES.md` declare
reddens the gate.

**Field 10 is the field that is never empty, and that is the point.** An empty
cell used to be the only signal this file had for "no item reaches this
construct", which made it indistinguishable from "nobody has measured this
yet". Field 10 says `neither` in a word, so emptiness carries no claim any
more. Fields 8 and 9 are lists and a list of nothing is empty.

Field 8 keeps the contract it has always had, because it already has a reader.
`harness/drill-gate.sh:815` splits it on commas and seeds its per-construct
item count from the words it finds, and an empty cell is the only value that
reader scores as zero. The slugs are bare rather than family-qualified for the
same reason: drill-gate's union test at `drill-gate.sh:1720` matches an item
directory's basename. All 64 drill slugs are distinct, all 25 reading slugs
are distinct, and the two sets do not overlap, so a bare slug names one item.

## The eight families

Every construct lands in exactly one, and the eight are disjoint and cover all
105. Counts: `core` 16, `pluscal` 31, `temporal` 20, `functions-records` 11,
`sets` 9, `modules` 8, `state-space` 8, `sequences` 2.

- **core** - the operator language that is not about a data structure:
  definitions, logic, quantifiers, control expressions, scalar values, and the
  higher-order and recursive definition forms.
- **sets** - set values and every operator whose primary operand is a set.
- **sequences** - tuples and the Sequences module.
- **functions-records** - functions and records: literals, sets, domains,
  update and merge.
- **temporal** - anything said about a behavior rather than a state: priming,
  actions, the spec skeleton, action formulas, temporal operators, fairness.
- **modules** - the module system: import, instantiation, substitution,
  namespace access.
- **state-space** - the model-configuration surface and the declarations it
  binds: constants, assumptions, model values, symmetry, deadlock, and the
  invariant and property declaration forms.
- **pluscal** - PlusCal, **and** the raw-TLA+ idioms that exist only to encode
  PlusCal's control flow: `pc`, `ProcSet`, label-as-action, `Trans`,
  `Terminating`. Those four are pure TLA+, not PlusCal, and they are filed
  here on purpose, because one author drilling the control-flow-encoding
  muscle should own both spellings of it. This is the one family boundary
  decided by judgment rather than by the cheat sheet, so it is the one to
  argue with first.

## How the weights were derived

A weight is how often a construct should appear across the corpus. Each one
comes from a measurement, and field 7 carries the measurement.

**Rule A - spread across the twelve corpus-derived reference specs.**
`authoring/*/reference/<Name>.tla`, the twelve bare references, counted by a
presence pattern per construct. Config-only keywords are counted instead over
the thirteen `authoring/*/reference/*.cfg`. Bands: 7 or more of 12 is `high`,
2 to 6 is `medium`, 0 or 1 is `low`.

**Rule B - published practice**, from `.claude/rules/tla-practice.md` over 666
modules and 337 configs. Bands by share of the relevant population: 50% or
more is `high`, 10 to 49% is `medium`, under 10% is `low`.

**Rule C - the PlusCal family cap.** Three of the twelve references carry a
PlusCal translation (`authoring/assay-office/reference/AssayOffice.tla:4`,
`authoring/bonded-store/reference/BondedStore.tla:4`,
`authoring/laytime/reference/Laytime.tla:8`), and 59 of 666 published modules
do, which is 9% (`.claude/rules/tla-practice.md:403`). Both sources agree that
PlusCal is a minority dialect, so no construct in the `pluscal` family is
rated `high`. Inside the family a construct the three PlusCal references use
is `medium` and one they do not is `low`.

**Where Rules A and B disagree, the weight is the higher of the two**, and
field 7 records both numbers so the disagreement stays visible. The direction
is deliberate: a construct drilled more than it strictly needs costs some
authoring time, while one drilled too little is the exact failure this
inventory exists to prevent.

Field 7 notation. `A8/12` is Rule A, 8 of the 12 reference specs. `Acfg6/13`
is Rule A over the 13 reference configs. `B117@269` is Rule B, the figure 117,
at `.claude/rules/tla-practice.md:269`. `C` marks the Rule C cap. `D8omit`
marks a construct the design drawer already retired, below.

Distribution: 37 `high`, 28 `medium`, 40 `low`.

## Three findings a wave planner should read before weighting anything

**The Sequences module is used nowhere in the authoring tree.** Not in the 12
bare references, not in the commented variants, not in the `MC` wrappers: a
recursive search of `authoring/*/reference/*.tla` for `Append`, `Head`, `Tail`,
`Len`, `SubSeq` or `Seq` returns nothing, and no reference `EXTENDS Sequences`.
So K011 is measured `low` honestly, and it is the **weight most likely to be
wrong in this file**. The 12 references happen to contain no queue, buffer or
log spec, which is the one shape that needs the module. A planner who thinks
`Sequence module operators` deserves `high` is probably right and should
overrule K011 against a wider sample rather than against this one.

**`pc` is absent from all twelve references, and that is real rather than a
measurement artifact.** All three PlusCal references are single-label
uniprocess algorithms, so the translator elides `pc` entirely; the only `pc`
substring in any of them is inside a `chksum(pcal)` comment. Published
practice disagrees sharply, with `pc` in the `vars` tuple of 49 of the 59
translated modules (`.claude/rules/tla-practice.md:419`), which is why K036
carries `medium` rather than `low`.

**Nine of the twelve packages stop at chapter 12.** The `uses constructs from:`
line in each `authoring/*/VECTOR.md` puts nine packages at chapter 12 and three
at chapter 13, and only one of those three reaches `INSTANCE`
(`authoring/consign/VECTOR.md:18`); the other two reach chapter 13 through a
user-module `EXTENDS` only (`authoring/custody/VECTOR.md:18`,
`authoring/seedlib/VECTOR.md:18`). `authoring/qsl/VECTOR.md:18` states the
negative case outright. So the whole `modules` family measures 0 or 1 of 12
under Rule A, and every weight in it above `low` comes from Rule B.

## Reconciling with the prior design

`drawer_tla_puzzles_decisions_8af15aed4e3d4a625f8d5ec5` decision D8 estimated
115 to 125 tokens from a different source, `SCAFFOLDING_MAP.md` plus
`module-docs/` plus TLA+/PlusCal core, and was never built. This file is built
from the cheat sheets instead, which are curated, carry a section anchor per
entry, and exist.

The two counts are close, and the gap is accounted for rather than mysterious.
D8's inventory included items the cheat sheets do not carry as entries: the
`TLC` module operators `Print` and `Assert`, and a rare-operator tail it
allocated to a third specimen, namely `^`, `\cdot`, `SortSeq`, `ToString` and
`Permutations`. It also counted `\AA` and `\EE`, which it then retired. So
D8's figure is a superset of this one at roughly the size the difference
predicts, and the 105 here is not a shortfall against it.

Two D8 omissions are worth carrying forward as weights rather than as absences,
because a drill corpus can afford to touch what a typical specimen cannot:
`goto` is K028, rated `low`, which D8 retired as anti-idiomatic, and `\AA` and
`\EE` have no cheat-sheet entry and so no row at all.

D8's coverage invariant was that every token appears in at least one specimen
or on the operator card with a documented rationale. The shape that replaces it
here is field 10: a row reading `neither` is an uncovered construct, which is
the same invariant in a form a shell script can check.

## What the two channels reach

Generated with the rows, so these counts cannot go stale separately. Measured
2026-10-15 over 64 drill items and 25 reading items.

| verdict | rows |
|---|---|
| `both` | 76 |
| `reading-only` | 24 |
| `drill-only` | 3 |
| `neither` | 2 |

So the drill corpus reaches 79 of the 105 and the reading corpus reaches 100.

**The 24 reading-only rows are 23 PlusCal rows plus K068.** `drill/` has no
`pluscal` family directory at all. Its eight directories are `control-state`,
`core`, `functions-records`, `modules`, `sequences`, `sets`, `state-space` and
`temporal`, and `control-state` holds the four raw-TLA+ control-flow-encoding
rows rather than PlusCal itself. The reading corpus has six `pluscal` items.
So this is a corpus boundary rather than a gap in anybody's authoring, and a
wave planner should read it that way.

**The 2 rows neither channel reaches are K026 `skip` and K028 `goto`**, both
`pluscal` and both weighted `low`. K028 is the row the design drawer retired
as anti-idiomatic and this file carried forward as a weight (see above), so
leaving it unreached is a defensible outcome rather than an oversight.

Field 8 and field 9 are not symmetric in what a count over them means. A drill
item declares the constructs it drills plus the ones it leans on, and a reading
item declares everything a reader meets in the module text. So a reading item
names 29 constructs on average against 11 for a drill item, and the reading
channel's 100 is a wider net rather than a deeper one. Do not read `both` as
two items of equal weight behind a row.

## The rows

ROW	K001	core	Operator definition	exercises/ch02/CHEATSHEET.md:11	high	A12/12	07-donor-session,01-box-office,02-vending-unchanged,03-bakery-obligations,04-lift-types,05-pelican-case,06-can-pyramid,07-prime-capacity,08-altimeter-approx,07-the-hoist-and-the-crates,02-two-pools,04-convoys,05-leases,07-which-pub	01-nim,02-chameleons,03-cups,01-matching,02-shelves,03-overlay,01-bitcounter,02-gears,03-fences,01-euclid,02-interleave,03-contend,04-ring,05-collatz,06-bubble,01-brackets,01-clockface,02-antichain,01-quorums,02-tickets,03-chips,01-handover,02-converge,03-alternation,04-contention	both
ROW	K002	core	IF-THEN-ELSE	exercises/ch02/CHEATSHEET.md:15	high	A8/12	03-two-tools,05-crane-and-riggers,06-three-reds,05-pelican-case,06-can-pyramid,08-troughs,05-undo-history,08-pancake-pile,02-two-pools	01-nim,02-shelves,03-overlay,01-bitcounter,03-fences,01-euclid,05-collatz,06-bubble,03-chips	both
ROW	K003	core	Equality and inequality	exercises/ch02/CHEATSHEET.md:19	high	A12/12	01-box-office,02-vending-unchanged,03-bakery-obligations,04-lift-types,05-pelican-case,06-can-pyramid,07-prime-capacity,08-altimeter-approx,02-floor-robot,07-pneumatic-tube	01-nim,02-chameleons,03-cups,01-matching,02-shelves,03-overlay,01-bitcounter,02-gears,03-fences,01-euclid,02-interleave,03-contend,04-ring,05-collatz,06-bubble,01-brackets,01-clockface,02-antichain,01-quorums,02-tickets,03-chips,01-handover,02-converge,03-alternation,04-contention	both
ROW	K004	modules	EXTENDS (module import)	exercises/ch02/CHEATSHEET.md:23	high	A8/12	05-tool-crib,06-depot-cover,03-the-bank-that-vouched,04-the-berth-and-the-phantom-ship,05-the-helper-that-leaked	01-nim,02-chameleons,03-cups,01-matching,02-shelves,03-overlay,01-bitcounter,02-gears,03-fences,01-euclid,02-interleave,04-ring,05-collatz,06-bubble,01-brackets,01-clockface,02-antichain,01-quorums,02-tickets,03-chips,01-handover,02-converge,03-alternation	both
ROW	K005	core	Integers	exercises/ch02/CHEATSHEET.md:27	high	A8/12	01-box-office,02-vending-unchanged,03-bakery-obligations,04-lift-types,05-pelican-case,06-can-pyramid,07-prime-capacity,08-altimeter-approx,04-deck-log,02-two-pools,04-convoys,06-port-rules,07-which-pub	01-nim,02-chameleons,03-cups,01-matching,02-shelves,03-overlay,01-bitcounter,02-gears,03-fences,01-euclid,02-interleave,04-ring,05-collatz,06-bubble,01-brackets,01-clockface,02-antichain,01-quorums,02-tickets,03-chips,02-converge,03-alternation	both
ROW	K006	core	Strings	exercises/ch02/CHEATSHEET.md:31	high	A8/12	03-bakery-obligations,04-lift-types,05-pelican-case,06-can-pyramid,03-returns-desk,05-undo-history,06-dispatch-board,07-pneumatic-tube,02-two-pools	02-shelves,02-interleave,03-contend,05-collatz,06-bubble,01-brackets,01-quorums,03-alternation,04-contention	both
ROW	K007	core	Booleans and logical operators	exercises/ch02/CHEATSHEET.md:35	high	A12/12	06-three-reds,01-box-office,02-vending-unchanged,03-bakery-obligations,04-lift-types,05-pelican-case,06-can-pyramid,07-prime-capacity,08-altimeter-approx,02-floor-robot,06-port-rules	01-nim,02-chameleons,03-cups,02-shelves,01-bitcounter,03-contend,04-ring,02-antichain,01-handover,04-contention	both
ROW	K008	core	Bullet-point boolean notation	exercises/ch02/CHEATSHEET.md:39	high	A12/12	01-box-office,02-vending-unchanged,03-bakery-obligations,04-lift-types,05-pelican-case,06-can-pyramid,07-prime-capacity,08-altimeter-approx,02-floor-robot	01-nim,02-chameleons,01-matching,02-shelves,03-overlay,01-bitcounter,03-fences,01-euclid,02-interleave,03-contend,04-ring,05-collatz,06-bubble,01-brackets,01-clockface,02-antichain,01-quorums,02-tickets,03-chips,01-handover,02-converge,03-alternation,04-contention	both
ROW	K009	core	Implication	exercises/ch02/CHEATSHEET.md:43	high	A11/12	05-crane-and-riggers,03-bakery-obligations,04-lift-types,05-pelican-case,01-triage-board,02-floor-robot,03-returns-desk,02-two-pools,04-convoys,07-which-pub,08-the-dive	01-nim,02-chameleons,03-cups,02-shelves,03-overlay,02-gears,03-fences,01-euclid,02-interleave,04-ring,06-bubble,01-clockface,02-tickets	both
ROW	K010	sequences	Sequences	exercises/ch02/CHEATSHEET.md:47	high	A11/12;B375@253	01-triage-board,02-floor-robot,03-returns-desk,04-deck-log,05-undo-history,06-dispatch-board,07-pneumatic-tube,08-pancake-pile,01-any-healthy-upstream,02-two-pools,04-convoys,05-leases,06-port-rules,07-which-pub	05-collatz,01-brackets	both
ROW	K011	sequences	Sequence module operators	exercises/ch02/CHEATSHEET.md:51	low	A0/12	01-triage-board,02-floor-robot,03-returns-desk,04-deck-log,05-undo-history,06-dispatch-board,07-pneumatic-tube,08-pancake-pile	05-collatz,01-brackets	both
ROW	K012	sets	Sets	exercises/ch02/CHEATSHEET.md:55	high	A12/12	03-bakery-obligations,04-lift-types,05-pelican-case,06-can-pyramid,08-altimeter-approx,03-returns-desk,06-dispatch-board,01-any-healthy-upstream,02-two-pools,03-ballast,04-convoys,05-leases,06-port-rules,07-which-pub,08-the-dive	03-cups,03-overlay,02-interleave,03-contend,04-ring,06-bubble,01-clockface,02-antichain,02-tickets,03-chips	both
ROW	K013	sets	Set relational and algebraic operators	exercises/ch02/CHEATSHEET.md:59	high	A12/12	04-night-patrol,03-returns-desk,06-dispatch-board,01-any-healthy-upstream,02-two-pools,03-ballast,04-convoys,05-leases,06-port-rules,07-which-pub,08-the-dive	03-cups,02-shelves,03-overlay,03-fences,01-euclid,03-contend,01-clockface,02-antichain,01-quorums,02-tickets,03-chips,01-handover	both
ROW	K014	sets	Cardinality	exercises/ch02/CHEATSHEET.md:63	medium	A3/12	02-pumps,07-donor-session,08-wrong-label,04-autoclaves,05-tool-crib,02-two-pools,03-ballast,04-convoys,05-leases,06-port-rules,07-which-pub	03-cups,01-matching,02-shelves,03-fences,02-interleave,06-bubble,01-clockface,02-antichain,01-quorums,02-tickets,03-chips,01-handover,03-alternation	both
ROW	K015	sets	BOOLEAN and integer interval as sets	exercises/ch02/CHEATSHEET.md:67	high	A9/12	04-night-patrol,01-box-office,02-vending-unchanged,03-bakery-obligations,04-lift-types,05-pelican-case,06-can-pyramid,07-prime-capacity,08-altimeter-approx,03-ballast-tanks,04-autoclaves,06-depot-cover,07-stock-board,08-troughs,02-floor-robot,04-deck-log,08-pancake-pile,06-port-rules	01-nim,02-chameleons,03-cups,02-shelves,03-overlay,01-bitcounter,02-gears,03-fences,01-euclid,02-interleave,03-contend,04-ring,06-bubble,01-brackets,01-clockface,03-chips,02-converge,04-contention	both
ROW	K016	sets	Cartesian product	exercises/ch02/CHEATSHEET.md:71	low	A1/12	02-floor-robot,01-any-healthy-upstream,02-two-pools,05-leases,06-port-rules,07-which-pub	06-bubble,02-antichain	both
ROW	K017	sets	SUBSET (powerset)	exercises/ch02/CHEATSHEET.md:75	medium	A4/12	05-tool-crib,01-any-healthy-upstream,02-two-pools,03-ballast,04-convoys	03-overlay,02-antichain,01-quorums	both
ROW	K018	sets	Set map	exercises/ch02/CHEATSHEET.md:79	low	A1/12	01-any-healthy-upstream,02-two-pools,05-leases,06-port-rules,07-which-pub	03-overlay,01-clockface	both
ROW	K019	sets	Set filter	exercises/ch02/CHEATSHEET.md:83	medium	A3/12	02-pumps,07-donor-session,08-wrong-label,04-autoclaves,05-tool-crib,06-depot-cover,02-two-pools,05-leases,07-which-pub	03-cups,01-matching,02-shelves,01-euclid,06-bubble,02-antichain,01-quorums,02-tickets,03-alternation	both
ROW	K020	sets	CHOOSE	exercises/ch02/CHEATSHEET.md:87	medium	A4/12	07-the-hoist-and-the-crates,01-triage-board,01-any-healthy-upstream	01-clockface,03-chips,03-alternation	both
ROW	K021	core	LET-IN	exercises/ch02/CHEATSHEET.md:91	medium	A4/12	05-pelican-case,07-the-hoist-and-the-crates,01-triage-board	01-nim,03-cups,03-chips	both
ROW	K022	pluscal	--algorithm block	exercises/ch03/CHEATSHEET.md:11	medium	A3/12;C		01-euclid,02-interleave,03-contend,04-ring,05-collatz,06-bubble	reading-only
ROW	K023	pluscal	:= assignment	exercises/ch03/CHEATSHEET.md:15	medium	A3/12;C		01-euclid,02-interleave,03-contend,04-ring,05-collatz,06-bubble	reading-only
ROW	K024	pluscal	label	exercises/ch03/CHEATSHEET.md:19	medium	A3/12;C		01-euclid,02-interleave,03-contend,04-ring,05-collatz,06-bubble	reading-only
ROW	K025	pluscal	|| simultaneous assignment	exercises/ch03/CHEATSHEET.md:23	low	A0/12;C		06-bubble	reading-only
ROW	K026	pluscal	skip	exercises/ch03/CHEATSHEET.md:27	low	A0/12;C			neither
ROW	K027	pluscal	assert	exercises/ch03/CHEATSHEET.md:31	low	A0/12;C		05-collatz	reading-only
ROW	K028	pluscal	goto	exercises/ch03/CHEATSHEET.md:35	low	A0/12;C;D8omit			neither
ROW	K029	pluscal	PlusCal if	exercises/ch03/CHEATSHEET.md:39	low	A0/12;C		01-euclid,05-collatz	reading-only
ROW	K030	pluscal	macro	exercises/ch03/CHEATSHEET.md:43	low	A0/12;C		04-ring	reading-only
ROW	K031	pluscal	with	exercises/ch03/CHEATSHEET.md:47	medium	A2/12;C		06-bubble	reading-only
ROW	K032	pluscal	while	exercises/ch03/CHEATSHEET.md:51	medium	A3/12;C		01-euclid,03-contend,04-ring,05-collatz,06-bubble	reading-only
ROW	K033	pluscal	\in on a variable declaration	exercises/ch03/CHEATSHEET.md:55	low	A0/12;C		06-bubble	reading-only
ROW	K034	state-space	Invariant (as a TLA+ operator, checked at every state)	exercises/ch04/CHEATSHEET.md:11	high	A11/12;B117@269	01-box-office,02-vending-unchanged,03-bakery-obligations,04-lift-types,05-pelican-case,06-can-pyramid,07-prime-capacity,08-altimeter-approx,01-shunting-yard,02-charging-bays,03-ballast-tanks,04-autoclaves,05-tool-crib,06-depot-cover,07-stock-board,08-troughs,01-two-tanks-one-hose,04-the-berth-and-the-phantom-ship,06-two-chutes-one-gate,07-the-hoist-and-the-crates,08-doors-of-the-hall,01-triage-board,02-floor-robot,03-returns-desk,04-deck-log,05-undo-history,06-dispatch-board,07-pneumatic-tube,08-pancake-pile,01-any-healthy-upstream,02-two-pools,03-ballast,04-convoys,05-leases,06-port-rules,07-which-pub,08-the-dive,01-clock-never-stops,02-four-identical-workers,03-view-hides-the-bug,04-clean-run-colleague-deadlock,05-summary-record,07-sentinel-and-the-roster,08-the-database-you-did-not-need	01-nim,02-chameleons,03-cups,01-matching,02-shelves,03-overlay,01-bitcounter,02-gears,03-fences,01-euclid,02-interleave,03-contend,04-ring,05-collatz,06-bubble,01-brackets,01-clockface,02-antichain,01-quorums,02-tickets,03-chips,01-handover,02-converge,03-alternation,04-contention	both
ROW	K035	pluscal	define block (PlusCal)	exercises/ch04/CHEATSHEET.md:15	medium	A3/12;C		06-bubble	reading-only
ROW	K036	pluscal	pc (PlusCal's label-tracking variable)	exercises/ch04/CHEATSHEET.md:20	medium	A0/12;B49of59@419	01-slip-on-the-spike,02-pumps,03-two-tools,04-night-patrol,05-crane-and-riggers,06-three-reds,07-donor-session,08-wrong-label	01-euclid,02-interleave,03-contend,05-collatz,06-bubble	both
ROW	K037	core	\A (universal quantifier, "forall")	exercises/ch04/CHEATSHEET.md:24	high	A11/12	01-slip-on-the-spike,02-pumps,05-crane-and-riggers,07-prime-capacity,01-shunting-yard,02-charging-bays,04-autoclaves,05-tool-crib,06-depot-cover,07-stock-board,01-triage-board,02-floor-robot,03-returns-desk,04-deck-log,06-dispatch-board,08-pancake-pile,01-any-healthy-upstream,02-two-pools,04-convoys,05-leases,07-which-pub	02-chameleons,03-cups,01-matching,02-shelves,03-overlay,01-euclid,02-interleave,01-brackets,01-clockface,02-antichain,01-quorums,02-tickets,02-converge,03-alternation	both
ROW	K038	core	\E (existential quantifier, "exists")	exercises/ch04/CHEATSHEET.md:28	high	A11/12	05-crane-and-riggers,07-donor-session,07-prime-capacity,08-altimeter-approx,01-shunting-yard,02-charging-bays,03-ballast-tanks,04-autoclaves,05-tool-crib,06-depot-cover,07-stock-board,08-troughs,01-triage-board,02-floor-robot,03-returns-desk,04-deck-log,05-undo-history,06-dispatch-board,07-pneumatic-tube,08-pancake-pile,01-any-healthy-upstream,02-two-pools,03-ballast,04-convoys,05-leases,06-port-rules,07-which-pub,08-the-dive	01-nim,02-chameleons,03-cups,01-matching,02-shelves,03-overlay,02-interleave,02-antichain,01-quorums,02-tickets,03-chips,01-handover,02-converge,03-alternation	both
ROW	K039	state-space	CONSTANT	exercises/ch05/CHEATSHEET.md:11	high	A12/12	02-pumps,01-box-office,02-vending-unchanged,03-bakery-obligations,04-lift-types,06-can-pyramid,07-prime-capacity,08-altimeter-approx,01-shunting-yard,02-charging-bays,03-ballast-tanks,04-autoclaves,05-tool-crib,07-stock-board,08-troughs,01-two-tanks-one-hose,03-the-bank-that-vouched,04-the-berth-and-the-phantom-ship,06-two-chutes-one-gate,07-the-hoist-and-the-crates,08-doors-of-the-hall,01-triage-board,03-returns-desk,04-deck-log,05-undo-history,06-dispatch-board,07-pneumatic-tube,08-pancake-pile,01-any-healthy-upstream,02-two-pools,03-ballast,04-convoys,05-leases,06-port-rules,07-which-pub,08-the-dive,01-clock-never-stops,02-four-identical-workers,03-view-hides-the-bug,04-clean-run-colleague-deadlock,05-summary-record,07-sentinel-and-the-roster,08-the-database-you-did-not-need	01-nim,01-matching,02-shelves,03-overlay,02-gears,03-fences,01-euclid,02-interleave,04-ring,05-collatz,01-brackets,01-clockface,02-antichain,01-quorums,02-tickets,03-chips,01-handover,02-converge,03-alternation	both
ROW	K040	state-space	ASSUME	exercises/ch05/CHEATSHEET.md:15	high	A8/12	03-two-tools,05-crane-and-riggers,03-the-bank-that-vouched,04-the-berth-and-the-phantom-ship,02-two-pools,03-ballast,01-clock-never-stops,03-view-hides-the-bug,04-clean-run-colleague-deadlock,05-summary-record,07-sentinel-and-the-roster,08-the-database-you-did-not-need	01-nim,02-shelves,03-overlay,02-gears,03-fences,01-euclid,04-ring,01-brackets,01-clockface,02-antichain,03-chips,01-handover,02-converge,03-alternation	both
ROW	K041	state-space	model value	exercises/ch05/CHEATSHEET.md:19	high	Acfg13/13	01-slip-on-the-spike,03-two-tools,05-crane-and-riggers,06-three-reds,07-donor-session,02-charging-bays,03-ballast-tanks,04-the-berth-and-the-phantom-ship,03-returns-desk,02-four-identical-workers,04-clean-run-colleague-deadlock,05-summary-record,07-sentinel-and-the-roster	02-tickets	both
ROW	K042	state-space	set of model values	exercises/ch05/CHEATSHEET.md:25	high	Acfg8/13	01-slip-on-the-spike,02-pumps,05-crane-and-riggers,07-donor-session,01-shunting-yard,02-charging-bays,04-autoclaves,05-tool-crib,07-stock-board,04-the-berth-and-the-phantom-ship,03-returns-desk,01-any-healthy-upstream,02-two-pools,03-ballast,04-convoys,05-leases,07-which-pub,08-the-dive,02-four-identical-workers,04-clean-run-colleague-deadlock,07-sentinel-and-the-roster,08-the-database-you-did-not-need	01-matching,02-shelves,03-overlay,02-interleave,02-antichain,01-quorums,02-tickets,03-chips,01-handover,03-alternation	both
ROW	K043	state-space	symmetry set	exercises/ch05/CHEATSHEET.md:31	medium	Acfg0/13;B49of337@398	04-the-berth-and-the-phantom-ship,02-four-identical-workers,05-summary-record,07-sentinel-and-the-roster		drill-only
ROW	K044	functions-records	struct literal	exercises/ch06/CHEATSHEET.md:11	high	A12/12;B176@357	02-charging-bays,04-autoclaves,07-stock-board,02-floor-robot	02-shelves,05-collatz	both
ROW	K045	functions-records	struct set	exercises/ch06/CHEATSHEET.md:15	medium	A2/12	02-charging-bays,04-autoclaves,07-stock-board,02-floor-robot	02-shelves	both
ROW	K046	functions-records	DOMAIN	exercises/ch06/CHEATSHEET.md:19	medium	A3/12	05-tool-crib,06-depot-cover,01-triage-board,02-floor-robot,03-returns-desk,04-deck-log,06-dispatch-board,08-pancake-pile	02-shelves,03-overlay	both
ROW	K047	functions-records	function literal	exercises/ch06/CHEATSHEET.md:23	high	A11/12	02-pumps,01-shunting-yard,02-charging-bays,03-ballast-tanks,04-autoclaves,05-tool-crib,06-depot-cover,07-stock-board,08-troughs,03-returns-desk,08-pancake-pile,02-two-pools	02-chameleons,01-matching,02-shelves,03-overlay,02-interleave,03-contend,01-quorums,02-tickets,03-chips,02-converge,03-alternation	both
ROW	K048	functions-records	:> (singleton function)	exercises/ch06/CHEATSHEET.md:27	low	A0/12	05-tool-crib	03-overlay	both
ROW	K049	functions-records	@@ (function merge)	exercises/ch06/CHEATSHEET.md:31	low	A0/12	05-tool-crib,06-depot-cover	03-overlay	both
ROW	K050	functions-records	function set	exercises/ch06/CHEATSHEET.md:35	high	A12/12	02-pumps,01-shunting-yard,02-charging-bays,03-ballast-tanks,04-autoclaves,05-tool-crib,07-stock-board,08-troughs,03-returns-desk,08-pancake-pile,02-two-pools	02-chameleons,01-matching,02-shelves,03-overlay,02-interleave,03-contend,06-bubble,01-quorums,02-tickets,03-chips,02-converge,03-alternation	both
ROW	K051	pluscal	nondeterministic with	exercises/ch07/CHEATSHEET.md:11	medium	A2/12;C		06-bubble	reading-only
ROW	K052	pluscal	either-or	exercises/ch07/CHEATSHEET.md:15	medium	A3/12;C		04-ring	reading-only
ROW	K053	pluscal	process (single)	exercises/ch08/CHEATSHEET.md:11	low	A1/12;C		03-contend	reading-only
ROW	K054	pluscal	pc[...] (multi-process pc)	exercises/ch08/CHEATSHEET.md:15	low	A0/12;C	01-slip-on-the-spike,03-two-tools,05-crane-and-riggers,07-donor-session,08-wrong-label	02-interleave,03-contend	both
ROW	K055	pluscal	process-local variable	exercises/ch08/CHEATSHEET.md:19	low	A0/12;C		02-interleave	reading-only
ROW	K056	pluscal	process set	exercises/ch08/CHEATSHEET.md:23	low	A1/12;C		02-interleave	reading-only
ROW	K057	pluscal	self	exercises/ch08/CHEATSHEET.md:27	low	A1/12;C		02-interleave	reading-only
ROW	K058	pluscal	await	exercises/ch08/CHEATSHEET.md:31	medium	A3/12;C		03-contend,04-ring	reading-only
ROW	K059	state-space	deadlock (checking)	exercises/ch08/CHEATSHEET.md:35	medium	Acfg6/13;B82of337@399	01-slip-on-the-spike,03-two-tools,06-three-reds,03-bakery-obligations,04-deck-log,01-any-healthy-upstream,04-convoys,07-which-pub,08-the-dive,01-clock-never-stops,04-clean-run-colleague-deadlock,06-liveness-at-the-fence,08-the-database-you-did-not-need	01-nim,03-contend,01-brackets,02-antichain,01-quorums,02-tickets,03-chips,02-converge	both
ROW	K060	pluscal	procedure	exercises/ch08/CHEATSHEET.md:39	low	A0/12;C		05-collatz	reading-only
ROW	K061	pluscal	call	exercises/ch08/CHEATSHEET.md:43	low	A0/12;C		05-collatz	reading-only
ROW	K062	pluscal	return	exercises/ch08/CHEATSHEET.md:47	low	A0/12;C		05-collatz	reading-only
ROW	K063	temporal	[] (always)	exercises/ch09/CHEATSHEET.md:11	high	A12/12	01-triage-board,01-print-job,03-commit-sticks,06-help-desk,07-pipeline-halt,08-turnstile-clock	03-contend,04-ring,06-bubble	both
ROW	K064	state-space	PROPERTY (TLC model config: register a temporal property)	exercises/ch09/CHEATSHEET.md:15	high	Acfg13/13;B117of337@115	06-three-reds,02-four-identical-workers,06-liveness-at-the-fence	01-nim,03-overlay,01-bitcounter,02-gears,01-euclid,02-interleave,03-contend,04-ring,05-collatz,06-bubble,02-antichain,01-quorums,02-tickets,01-handover,02-converge,03-alternation,04-contention	both
ROW	K065	pluscal	fair process (weak fairness)	exercises/ch09/CHEATSHEET.md:19	low	A0/12;B5of59@425		02-interleave,03-contend	reading-only
ROW	K066	pluscal	fair+ (strong fairness)	exercises/ch09/CHEATSHEET.md:23	low	A0/12;B5of59@425		03-contend	reading-only
ROW	K067	temporal	<> (eventually)	exercises/ch09/CHEATSHEET.md:27	medium	A2/12	03-two-tools,04-night-patrol,01-print-job,05-flaky-link	01-euclid,02-interleave,05-collatz,06-bubble,04-contention	both
ROW	K068	temporal	<>[] (eventually always)	exercises/ch09/CHEATSHEET.md:31	low	A0/12		02-converge	reading-only
ROW	K069	temporal	[]<> (always eventually)	exercises/ch09/CHEATSHEET.md:35	low	A0/12	02-heartbeat,05-flaky-link	03-contend,03-alternation,04-contention	both
ROW	K070	temporal	~> (leads-to)	exercises/ch09/CHEATSHEET.md:39	medium	A6/12	01-print-job,06-help-desk	01-handover,04-contention	both
ROW	K071	core	RECURSIVE	exercises/ch10/CHEATSHEET.md:11	low	A1/12	06-can-pyramid,08-troughs,07-the-hoist-and-the-crates,06-dispatch-board,08-pancake-pile	01-nim,03-chips	both
ROW	K072	core	Higher-order operator parameter	exercises/ch10/CHEATSHEET.md:15	medium	A2/12	06-can-pyramid,06-two-chutes-one-gate	03-cups	both
ROW	K073	core	LAMBDA	exercises/ch10/CHEATSHEET.md:19	low	A0/12	06-can-pyramid,06-two-chutes-one-gate,06-dispatch-board	03-cups,01-brackets	both
ROW	K074	core	Custom binary operator	exercises/ch10/CHEATSHEET.md:23	low	A0/12	08-altimeter-approx	01-nim	both
ROW	K075	functions-records	Bracket function definition	exercises/ch10/CHEATSHEET.md:27	low	A0/12	08-troughs	03-overlay	both
ROW	K076	functions-records	Recursive function definition	exercises/ch10/CHEATSHEET.md:31	low	A0/12	08-troughs	03-overlay	both
ROW	K077	core	CASE	exercises/ch10/CHEATSHEET.md:35	low	A0/12	05-pelican-case	02-chameleons,03-contend	both
ROW	K078	temporal	action property	exercises/ch11/CHEATSHEET.md:11	high	A12/12	06-three-reds,01-triage-board,03-commit-sticks,08-turnstile-clock	01-nim,03-overlay,02-gears,04-ring,06-bubble,02-antichain,01-quorums,02-tickets,01-handover,02-converge	both
ROW	K079	temporal	' (prime, next-state value)	exercises/ch11/CHEATSHEET.md:15	high	A12/12	06-three-reds,08-wrong-label,01-box-office,02-vending-unchanged,03-bakery-obligations,04-lift-types,05-pelican-case,06-can-pyramid,07-prime-capacity,08-altimeter-approx,01-triage-board,02-two-pools,03-ballast,04-convoys,07-which-pub,02-heartbeat,03-commit-sticks,04-revision-freeze,08-turnstile-clock	01-nim,02-chameleons,03-cups,01-matching,02-shelves,03-overlay,01-bitcounter,02-gears,03-fences,01-euclid,02-interleave,03-contend,04-ring,05-collatz,06-bubble,01-brackets,01-clockface,02-antichain,01-quorums,02-tickets,03-chips,01-handover,02-converge,03-alternation,04-contention	both
ROW	K080	temporal	[P]_x (box action formula)	exercises/ch11/CHEATSHEET.md:19	high	A12/12;B1182@169	01-slip-on-the-spike,04-night-patrol,06-three-reds,01-box-office,02-vending-unchanged,03-bakery-obligations,04-lift-types,05-pelican-case,06-can-pyramid,07-prime-capacity,08-altimeter-approx,01-triage-board,03-commit-sticks,04-revision-freeze,08-turnstile-clock	01-nim,02-chameleons,03-cups,01-matching,02-shelves,03-overlay,01-bitcounter,02-gears,03-fences,01-euclid,02-interleave,03-contend,04-ring,05-collatz,06-bubble,01-brackets,01-clockface,02-antichain,01-quorums,02-tickets,03-chips,01-handover,02-converge,03-alternation,04-contention	both
ROW	K081	temporal	VARIABLE / VARIABLES	exercises/ch12/CHEATSHEET.md:11	high	A12/12	01-box-office,02-vending-unchanged,03-bakery-obligations,04-lift-types,05-pelican-case,06-can-pyramid,07-prime-capacity,08-altimeter-approx,01-shunting-yard,01-two-tanks-one-hose,02-signal-and-the-ticker,04-revision-freeze	01-nim,02-chameleons,03-cups,01-matching,02-shelves,03-overlay,01-bitcounter,02-gears,03-fences,01-euclid,02-interleave,03-contend,04-ring,05-collatz,06-bubble,01-brackets,01-clockface,02-antichain,01-quorums,02-tickets,03-chips,01-handover,02-converge,03-alternation,04-contention	both
ROW	K082	temporal	vars (the all-variables tuple)	exercises/ch12/CHEATSHEET.md:15	high	A11/12;B906of1182@169	01-slip-on-the-spike,04-night-patrol,01-box-office,02-vending-unchanged,03-bakery-obligations,04-lift-types,05-pelican-case,06-can-pyramid,07-prime-capacity,08-altimeter-approx,04-revision-freeze	01-nim,02-chameleons,03-cups,01-matching,02-shelves,03-overlay,01-bitcounter,02-gears,03-fences,01-euclid,02-interleave,03-contend,04-ring,05-collatz,06-bubble,01-brackets,01-clockface,02-antichain,01-quorums,02-tickets,03-chips,01-handover,02-converge,03-alternation,04-contention	both
ROW	K083	temporal	Init / Next / Spec (the pure-TLA+ spec skeleton)	exercises/ch12/CHEATSHEET.md:19	high	A12/12;B178of253@259	01-box-office,02-vending-unchanged,03-bakery-obligations,04-lift-types,05-pelican-case,06-can-pyramid,07-prime-capacity,08-altimeter-approx,01-shunting-yard,02-signal-and-the-ticker,01-triage-board,02-floor-robot,03-returns-desk,04-deck-log,05-undo-history,06-dispatch-board,07-pneumatic-tube,08-pancake-pile,04-revision-freeze,07-pipeline-halt	01-nim,02-chameleons,03-cups,01-matching,02-shelves,03-overlay,01-bitcounter,02-gears,03-fences,01-euclid,02-interleave,03-contend,04-ring,05-collatz,06-bubble,01-brackets,01-clockface,02-antichain,01-quorums,02-tickets,03-chips,01-handover,02-converge,03-alternation,04-contention	both
ROW	K084	temporal	action (formal definition)	exercises/ch12/CHEATSHEET.md:23	high	A12/12	02-pumps,01-box-office,02-vending-unchanged,03-bakery-obligations,04-lift-types,05-pelican-case,06-can-pyramid,07-prime-capacity,08-altimeter-approx,01-shunting-yard,02-heartbeat,04-revision-freeze	01-nim,02-chameleons,03-cups,01-matching,02-shelves,03-overlay,01-bitcounter,02-gears,03-fences,02-interleave,03-contend,04-ring,05-collatz,06-bubble,01-brackets,01-clockface,02-antichain,01-quorums,02-tickets,03-chips,01-handover,02-converge,03-alternation,04-contention	both
ROW	K085	temporal	UNCHANGED	exercises/ch12/CHEATSHEET.md:27	high	A10/12	02-pumps,04-night-patrol,08-wrong-label,01-box-office,02-vending-unchanged,03-bakery-obligations,04-lift-types,05-pelican-case,06-can-pyramid,07-prime-capacity,08-altimeter-approx,02-charging-bays,04-autoclaves,06-depot-cover,07-stock-board,08-troughs,01-triage-board,03-returns-desk,04-deck-log,06-dispatch-board,07-pneumatic-tube,02-two-pools,04-convoys,08-the-dive,03-commit-sticks,04-revision-freeze	01-nim,03-overlay,01-bitcounter,02-gears,03-fences,01-euclid,02-interleave,05-collatz,06-bubble,01-clockface,01-quorums,02-tickets,01-handover,03-alternation,04-contention	both
ROW	K086	temporal	nondeterministic action (\E form and disjunction form)	exercises/ch12/CHEATSHEET.md:31	high	A12/12;B105of238@279	02-pumps,01-box-office,02-vending-unchanged,03-bakery-obligations,04-lift-types,05-pelican-case,06-can-pyramid,07-prime-capacity,08-altimeter-approx,01-shunting-yard,02-charging-bays,03-ballast-tanks,01-any-healthy-upstream,04-revision-freeze	01-nim,02-chameleons,03-cups,01-matching,02-shelves,03-overlay,01-bitcounter,02-gears,03-fences,02-interleave,03-contend,04-ring,05-collatz,06-bubble,01-brackets,02-antichain,01-quorums,02-tickets,03-chips,01-handover,02-converge,03-alternation,04-contention	both
ROW	K087	functions-records	EXCEPT	exercises/ch12/CHEATSHEET.md:35	high	A11/12	01-slip-on-the-spike,02-pumps,08-wrong-label,01-shunting-yard,02-charging-bays,03-ballast-tanks,04-autoclaves,05-tool-crib,07-stock-board,08-troughs,03-returns-desk,02-two-pools	01-matching,02-shelves,03-overlay,02-interleave,03-contend,06-bubble,01-quorums,02-tickets,03-chips,02-converge,03-alternation	both
ROW	K088	functions-records	@ (the original value, inside EXCEPT)	exercises/ch12/CHEATSHEET.md:39	medium	A4/12	03-ballast-tanks,04-autoclaves,07-stock-board,08-troughs	03-overlay	both
ROW	K089	pluscal	ProcSet	exercises/ch12/CHEATSHEET.md:43	low	A1/12;C	03-two-tools,05-crane-and-riggers,07-donor-session	02-interleave,03-contend	both
ROW	K090	pluscal	label-as-action encoding	exercises/ch12/CHEATSHEET.md:47	medium	A3/12;C	01-slip-on-the-spike,03-two-tools,04-night-patrol,05-crane-and-riggers,06-three-reds,07-donor-session,08-wrong-label	01-euclid,02-interleave,03-contend,05-collatz,06-bubble	both
ROW	K091	pluscal	Trans helper action for pc transitions	exercises/ch12/CHEATSHEET.md:51	low	A0/12;C	07-donor-session		drill-only
ROW	K092	pluscal	Terminating	exercises/ch12/CHEATSHEET.md:55	low	A0/12;B41of666@422	03-two-tools,06-three-reds,07-donor-session,08-wrong-label	01-euclid,02-interleave,05-collatz,06-bubble	both
ROW	K093	temporal	ENABLED	exercises/ch12/CHEATSHEET.md:59	low	A0/12	07-pipeline-halt	04-contention	both
ROW	K094	temporal	<<A>>_v (angle action formula)	exercises/ch12/CHEATSHEET.md:63	low	A0/12	04-night-patrol,02-heartbeat	04-contention	both
ROW	K095	temporal	WF_v(A) (weak fairness)	exercises/ch12/CHEATSHEET.md:67	high	A8/12	03-two-tools,04-night-patrol,06-help-desk	01-euclid,02-interleave,03-contend,05-collatz,06-bubble,01-handover,02-converge,03-alternation,04-contention	both
ROW	K096	temporal	SF_v(A) (strong fairness)	exercises/ch12/CHEATSHEET.md:71	low	A0/12	05-flaky-link	03-contend,04-contention	both
ROW	K097	temporal	fairness conjunct on Spec	exercises/ch12/CHEATSHEET.md:75	medium	A5/12;B83of337@455	05-flaky-link,06-help-desk	01-euclid,02-interleave,03-contend,05-collatz,06-bubble,01-handover,02-converge,03-alternation,04-contention	both
ROW	K098	temporal	fairness on a subaction	exercises/ch12/CHEATSHEET.md:79	high	A7/12	05-flaky-link,06-help-desk	02-interleave,03-contend,01-handover,02-converge,03-alternation,04-contention	both
ROW	K099	modules	LOCAL (definition modifier)	exercises/ch13/CHEATSHEET.md:11	low	A0/12	05-the-helper-that-leaked	03-fences	both
ROW	K100	modules	INSTANCE	exercises/ch13/CHEATSHEET.md:15	medium	A0/12;B190of666@368	01-two-tanks-one-hose,02-signal-and-the-ticker,03-the-bank-that-vouched,05-the-helper-that-leaked,06-two-chutes-one-gate	01-bitcounter,02-gears,03-fences	both
ROW	K101	modules	LOCAL INSTANCE	exercises/ch13/CHEATSHEET.md:19	low	A0/12	05-the-helper-that-leaked		drill-only
ROW	K102	modules	named instance	exercises/ch13/CHEATSHEET.md:23	medium	A0/12;B@377	01-two-tanks-one-hose,02-signal-and-the-ticker,03-the-bank-that-vouched,05-the-helper-that-leaked,06-two-chutes-one-gate	01-bitcounter,02-gears,03-fences	both
ROW	K103	modules	! (namespace lookup)	exercises/ch13/CHEATSHEET.md:27	medium	A0/12;B@377	01-two-tanks-one-hose,02-signal-and-the-ticker,03-the-bank-that-vouched,05-the-helper-that-leaked,06-two-chutes-one-gate,08-doors-of-the-hall	01-bitcounter,02-gears,03-fences	both
ROW	K104	modules	INSTANCE ... WITH (<- constant substitution)	exercises/ch13/CHEATSHEET.md:31	low	A1/12;B43of666@368	01-two-tanks-one-hose,02-signal-and-the-ticker,03-the-bank-that-vouched,06-two-chutes-one-gate,08-doors-of-the-hall	02-gears,03-fences	both
ROW	K105	modules	partial parameterization	exercises/ch13/CHEATSHEET.md:35	low	A0/12	08-doors-of-the-hall	02-gears	both
