# Core Language

Eight pages, one per authoring family. Each one says what its family is for,
what using it costs you, and where its quiet failures are.

This section is the language itself. The standard library gets its own section
beside this one, Standard Modules, and the exercises and chapters that teach
this material sit outside the reference.

## Finding a construct

Go straight to the family page when you know which family a construct belongs
to. The table below is for when you don't.

The search box takes a construct name directly, and I'd reach for that first.
Searching `EXCEPT` lands on functions and records, which is faster than
placing it by hand. The table is the fallback when the name you remember isn't
the name TLA+ uses.

Every page opens with its family's full construct table, so landing on the
wrong page costs one look rather than a hunt.

## The eight families

| Page | What it covers |
|---|---|
| [Core operators](core.md) | Definitions, logic, quantifiers, and the control expressions a definition body is built from |
| [Functions and records](functions-records.md) | Functions, records, their sets and domains, and changing one field without rewriting the rest |
| [Sets](sets.md) | Set values, the operators that combine two sets, and the four ways to build a set out of something else |
| [Sequences](sequences.md) | Ordered finite lists, the standard `Sequences` operators, and the state space they cost |
| [Actions and temporal properties](temporal.md) | Priming, actions, the spec skeleton, the temporal operators, and fairness |
| [The model configuration](state-space.md) | The `.cfg` file, what each keyword does to the run, and which two of them state a property |
| [Modules](modules.md) | Pulling one module into another, naming an import, and substituting its parameters |
| [PlusCal](pluscal.md) | The algorithm language, its translation, and the control-flow encoding that translation emits |

The order is roughly the order you meet them. The operator language first,
then the data, then behavior, then the run, and last the two a spec can go a
long way without.

A construct sits on one page and no other. The eight tables carry 120 rows
between them and no name appears twice, counted on 2026-10-22.

## Why the pages are shaped this way

A family page is not a syntax list. The construct table at the top is the
short answer, and most of each page is the sections under it, one per trap,
each stating its claim in the heading and then showing the module and the real
TLC output behind it.

That split is deliberate. Syntax you can get from a cheat sheet, and this
project ships twelve of those. What a cheat sheet can't give you is the
formula that parses, runs clean, and asserts nothing, which is most of what
costs time once the syntax is in hand.

## The modules are real files

Every TLA+ block on these pages comes out of a module under
`core-language-docs/snippets/`. `run-all.sh` beside them re-runs each one and
checks it against the exit code and the distinct-state count the page quotes,
so a page can't drift away from the code that ran.

```bash
git clone https://github.com/fkberthold/tla-puzzles
cd tla-puzzles
core-language-docs/snippets/run-all.sh
```

The state count matters as much as the exit code. Two of the findings on the
modules page are state counts where both runs exit 0, so a check on the exit
code alone would stay green while the page went wrong.
