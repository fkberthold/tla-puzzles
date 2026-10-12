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
    grep '^ROW' drill/INVENTORY.md | cut -f8        # coverage, empty today

Eight fields, in order:

| # | field | contents |
|---|---|---|
| 1 | marker | the literal `ROW` |
| 2 | id | `K001`-`K105`, stable, never renumbered |
| 3 | family | one of the eight authoring partitions below |
| 4 | construct | verbatim from the cheat sheet entry |
| 5 | source | `file:line` of the `- Construct:` line it came from |
| 6 | weight | `high`, `medium` or `low` |
| 7 | basis | how that weight was derived, notation below |
| 8 | items | comma-separated drill item ids. **Empty on every row today.** |

Field 8 is the only field a coverage gate writes. A row whose field 8 is empty
is an uncovered construct. Do not reformat the rows: the delimiter is a single
tab and `cut` defaults to it.

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
here is field 8: a row with an empty field 8 is an uncovered construct, which
is the same invariant in a form a shell script can check.

## The rows

ROW	K001	core	Operator definition	exercises/ch02/CHEATSHEET.md:11	high	A12/12	
ROW	K002	core	IF-THEN-ELSE	exercises/ch02/CHEATSHEET.md:15	high	A8/12	
ROW	K003	core	Equality and inequality	exercises/ch02/CHEATSHEET.md:19	high	A12/12	
ROW	K004	modules	EXTENDS (module import)	exercises/ch02/CHEATSHEET.md:23	high	A8/12	
ROW	K005	core	Integers	exercises/ch02/CHEATSHEET.md:27	high	A8/12	
ROW	K006	core	Strings	exercises/ch02/CHEATSHEET.md:31	high	A8/12	
ROW	K007	core	Booleans and logical operators	exercises/ch02/CHEATSHEET.md:35	high	A12/12	
ROW	K008	core	Bullet-point boolean notation	exercises/ch02/CHEATSHEET.md:39	high	A12/12	
ROW	K009	core	Implication	exercises/ch02/CHEATSHEET.md:43	high	A11/12	
ROW	K010	sequences	Sequences	exercises/ch02/CHEATSHEET.md:47	high	A11/12;B375@253	
ROW	K011	sequences	Sequence module operators	exercises/ch02/CHEATSHEET.md:51	low	A0/12	
ROW	K012	sets	Sets	exercises/ch02/CHEATSHEET.md:55	high	A12/12	
ROW	K013	sets	Set relational and algebraic operators	exercises/ch02/CHEATSHEET.md:59	high	A12/12	
ROW	K014	sets	Cardinality	exercises/ch02/CHEATSHEET.md:63	medium	A3/12	
ROW	K015	sets	BOOLEAN and integer interval as sets	exercises/ch02/CHEATSHEET.md:67	high	A9/12	
ROW	K016	sets	Cartesian product	exercises/ch02/CHEATSHEET.md:71	low	A1/12	
ROW	K017	sets	SUBSET (powerset)	exercises/ch02/CHEATSHEET.md:75	medium	A4/12	
ROW	K018	sets	Set map	exercises/ch02/CHEATSHEET.md:79	low	A1/12	
ROW	K019	sets	Set filter	exercises/ch02/CHEATSHEET.md:83	medium	A3/12	
ROW	K020	sets	CHOOSE	exercises/ch02/CHEATSHEET.md:87	medium	A4/12	
ROW	K021	core	LET-IN	exercises/ch02/CHEATSHEET.md:91	medium	A4/12	
ROW	K022	pluscal	--algorithm block	exercises/ch03/CHEATSHEET.md:11	medium	A3/12;C	
ROW	K023	pluscal	:= assignment	exercises/ch03/CHEATSHEET.md:15	medium	A3/12;C	
ROW	K024	pluscal	label	exercises/ch03/CHEATSHEET.md:19	medium	A3/12;C	
ROW	K025	pluscal	|| simultaneous assignment	exercises/ch03/CHEATSHEET.md:23	low	A0/12;C	
ROW	K026	pluscal	skip	exercises/ch03/CHEATSHEET.md:27	low	A0/12;C	
ROW	K027	pluscal	assert	exercises/ch03/CHEATSHEET.md:31	low	A0/12;C	
ROW	K028	pluscal	goto	exercises/ch03/CHEATSHEET.md:35	low	A0/12;C;D8omit	
ROW	K029	pluscal	PlusCal if	exercises/ch03/CHEATSHEET.md:39	low	A0/12;C	
ROW	K030	pluscal	macro	exercises/ch03/CHEATSHEET.md:43	low	A0/12;C	
ROW	K031	pluscal	with	exercises/ch03/CHEATSHEET.md:47	medium	A2/12;C	
ROW	K032	pluscal	while	exercises/ch03/CHEATSHEET.md:51	medium	A3/12;C	
ROW	K033	pluscal	\in on a variable declaration	exercises/ch03/CHEATSHEET.md:55	low	A0/12;C	
ROW	K034	state-space	Invariant (as a TLA+ operator, checked at every state)	exercises/ch04/CHEATSHEET.md:11	high	A11/12;B117@269	
ROW	K035	pluscal	define block (PlusCal)	exercises/ch04/CHEATSHEET.md:15	medium	A3/12;C	
ROW	K036	pluscal	pc (PlusCal's label-tracking variable)	exercises/ch04/CHEATSHEET.md:20	medium	A0/12;B49of59@419	
ROW	K037	core	\A (universal quantifier, "forall")	exercises/ch04/CHEATSHEET.md:24	high	A11/12	
ROW	K038	core	\E (existential quantifier, "exists")	exercises/ch04/CHEATSHEET.md:28	high	A11/12	
ROW	K039	state-space	CONSTANT	exercises/ch05/CHEATSHEET.md:11	high	A12/12	
ROW	K040	state-space	ASSUME	exercises/ch05/CHEATSHEET.md:15	high	A8/12	
ROW	K041	state-space	model value	exercises/ch05/CHEATSHEET.md:19	high	Acfg13/13	
ROW	K042	state-space	set of model values	exercises/ch05/CHEATSHEET.md:25	high	Acfg8/13	
ROW	K043	state-space	symmetry set	exercises/ch05/CHEATSHEET.md:31	medium	Acfg0/13;B49of337@398	
ROW	K044	functions-records	struct literal	exercises/ch06/CHEATSHEET.md:11	high	A12/12;B176@357	
ROW	K045	functions-records	struct set	exercises/ch06/CHEATSHEET.md:15	medium	A2/12	
ROW	K046	functions-records	DOMAIN	exercises/ch06/CHEATSHEET.md:19	medium	A3/12	
ROW	K047	functions-records	function literal	exercises/ch06/CHEATSHEET.md:23	high	A11/12	
ROW	K048	functions-records	:> (singleton function)	exercises/ch06/CHEATSHEET.md:27	low	A0/12	
ROW	K049	functions-records	@@ (function merge)	exercises/ch06/CHEATSHEET.md:31	low	A0/12	
ROW	K050	functions-records	function set	exercises/ch06/CHEATSHEET.md:35	high	A12/12	
ROW	K051	pluscal	nondeterministic with	exercises/ch07/CHEATSHEET.md:11	medium	A2/12;C	
ROW	K052	pluscal	either-or	exercises/ch07/CHEATSHEET.md:15	medium	A3/12;C	
ROW	K053	pluscal	process (single)	exercises/ch08/CHEATSHEET.md:11	low	A1/12;C	
ROW	K054	pluscal	pc[...] (multi-process pc)	exercises/ch08/CHEATSHEET.md:15	low	A0/12;C	
ROW	K055	pluscal	process-local variable	exercises/ch08/CHEATSHEET.md:19	low	A0/12;C	
ROW	K056	pluscal	process set	exercises/ch08/CHEATSHEET.md:23	low	A1/12;C	
ROW	K057	pluscal	self	exercises/ch08/CHEATSHEET.md:27	low	A1/12;C	
ROW	K058	pluscal	await	exercises/ch08/CHEATSHEET.md:31	medium	A3/12;C	
ROW	K059	state-space	deadlock (checking)	exercises/ch08/CHEATSHEET.md:35	medium	Acfg6/13;B82of337@399	
ROW	K060	pluscal	procedure	exercises/ch08/CHEATSHEET.md:39	low	A0/12;C	
ROW	K061	pluscal	call	exercises/ch08/CHEATSHEET.md:43	low	A0/12;C	
ROW	K062	pluscal	return	exercises/ch08/CHEATSHEET.md:47	low	A0/12;C	
ROW	K063	temporal	[] (always)	exercises/ch09/CHEATSHEET.md:11	high	A12/12	
ROW	K064	state-space	PROPERTY (TLC model config: register a temporal property)	exercises/ch09/CHEATSHEET.md:15	high	Acfg13/13;B117of337@115	
ROW	K065	pluscal	fair process (weak fairness)	exercises/ch09/CHEATSHEET.md:19	low	A0/12;B5of59@425	
ROW	K066	pluscal	fair+ (strong fairness)	exercises/ch09/CHEATSHEET.md:23	low	A0/12;B5of59@425	
ROW	K067	temporal	<> (eventually)	exercises/ch09/CHEATSHEET.md:27	medium	A2/12	
ROW	K068	temporal	<>[] (eventually always)	exercises/ch09/CHEATSHEET.md:31	low	A0/12	
ROW	K069	temporal	[]<> (always eventually)	exercises/ch09/CHEATSHEET.md:35	low	A0/12	
ROW	K070	temporal	~> (leads-to)	exercises/ch09/CHEATSHEET.md:39	medium	A6/12	
ROW	K071	core	RECURSIVE	exercises/ch10/CHEATSHEET.md:11	low	A1/12	
ROW	K072	core	Higher-order operator parameter	exercises/ch10/CHEATSHEET.md:15	medium	A2/12	
ROW	K073	core	LAMBDA	exercises/ch10/CHEATSHEET.md:19	low	A0/12	
ROW	K074	core	Custom binary operator	exercises/ch10/CHEATSHEET.md:23	low	A0/12	
ROW	K075	functions-records	Bracket function definition	exercises/ch10/CHEATSHEET.md:27	low	A0/12	
ROW	K076	functions-records	Recursive function definition	exercises/ch10/CHEATSHEET.md:31	low	A0/12	
ROW	K077	core	CASE	exercises/ch10/CHEATSHEET.md:35	low	A0/12	
ROW	K078	temporal	action property	exercises/ch11/CHEATSHEET.md:11	high	A12/12	
ROW	K079	temporal	' (prime, next-state value)	exercises/ch11/CHEATSHEET.md:15	high	A12/12	
ROW	K080	temporal	[P]_x (box action formula)	exercises/ch11/CHEATSHEET.md:19	high	A12/12;B1182@169	
ROW	K081	temporal	VARIABLE / VARIABLES	exercises/ch12/CHEATSHEET.md:11	high	A12/12	
ROW	K082	temporal	vars (the all-variables tuple)	exercises/ch12/CHEATSHEET.md:15	high	A11/12;B906of1182@169	
ROW	K083	temporal	Init / Next / Spec (the pure-TLA+ spec skeleton)	exercises/ch12/CHEATSHEET.md:19	high	A12/12;B178of253@259	
ROW	K084	temporal	action (formal definition)	exercises/ch12/CHEATSHEET.md:23	high	A12/12	
ROW	K085	temporal	UNCHANGED	exercises/ch12/CHEATSHEET.md:27	high	A10/12	
ROW	K086	temporal	nondeterministic action (\E form and disjunction form)	exercises/ch12/CHEATSHEET.md:31	high	A12/12;B105of238@279	
ROW	K087	functions-records	EXCEPT	exercises/ch12/CHEATSHEET.md:35	high	A11/12	
ROW	K088	functions-records	@ (the original value, inside EXCEPT)	exercises/ch12/CHEATSHEET.md:39	medium	A4/12	
ROW	K089	pluscal	ProcSet	exercises/ch12/CHEATSHEET.md:43	low	A1/12;C	
ROW	K090	pluscal	label-as-action encoding	exercises/ch12/CHEATSHEET.md:47	medium	A3/12;C	
ROW	K091	pluscal	Trans helper action for pc transitions	exercises/ch12/CHEATSHEET.md:51	low	A0/12;C	
ROW	K092	pluscal	Terminating	exercises/ch12/CHEATSHEET.md:55	low	A0/12;B41of666@422	
ROW	K093	temporal	ENABLED	exercises/ch12/CHEATSHEET.md:59	low	A0/12	
ROW	K094	temporal	<<A>>_v (angle action formula)	exercises/ch12/CHEATSHEET.md:63	low	A0/12	
ROW	K095	temporal	WF_v(A) (weak fairness)	exercises/ch12/CHEATSHEET.md:67	high	A8/12	
ROW	K096	temporal	SF_v(A) (strong fairness)	exercises/ch12/CHEATSHEET.md:71	low	A0/12	
ROW	K097	temporal	fairness conjunct on Spec	exercises/ch12/CHEATSHEET.md:75	medium	A5/12;B83of337@455	
ROW	K098	temporal	fairness on a subaction	exercises/ch12/CHEATSHEET.md:79	high	A7/12	
ROW	K099	modules	LOCAL (definition modifier)	exercises/ch13/CHEATSHEET.md:11	low	A0/12	
ROW	K100	modules	INSTANCE	exercises/ch13/CHEATSHEET.md:15	medium	A0/12;B190of666@368	
ROW	K101	modules	LOCAL INSTANCE	exercises/ch13/CHEATSHEET.md:19	low	A0/12	
ROW	K102	modules	named instance	exercises/ch13/CHEATSHEET.md:23	medium	A0/12;B@377	
ROW	K103	modules	! (namespace lookup)	exercises/ch13/CHEATSHEET.md:27	medium	A0/12;B@377	
ROW	K104	modules	INSTANCE ... WITH (<- constant substitution)	exercises/ch13/CHEATSHEET.md:31	low	A1/12;B43of666@368	
ROW	K105	modules	partial parameterization	exercises/ch13/CHEATSHEET.md:35	low	A0/12	
