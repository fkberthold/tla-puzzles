# TLA+ Practice Puzzles

Progressive exercises for learning TLA+ and PlusCal by doing — modeled on the [99 Prolog Problems](https://www.ic.unicamp.br/~meidanis/courses/mc336/2009s2/prolog/problemas/).

## What This Is

A set of small, self-contained puzzles. Each one teaches ONE new concept. Each one can be solved in 15-30 minutes. Each solution has been written, translated by `pcal`, and verified by TLC.

## Difficulty

- ⭐ = ~15 minutes
- ⭐⭐ = ~30 minutes
- ⭐⭐⭐ = ~60 minutes

## Tier 1: PlusCal Basics

| # | Title | Concept | Difficulty |
|---|-------|---------|------------|
| T01 | [The Light Switch](puzzles/T01-the-light-switch/) | First spec: variables, process, loop, invariant | ⭐ |
| T02 | [The Guessing Game](puzzles/T02-the-guessing-game/) | `with` — nondeterministic value selection | ⭐ |
| T03 | [The Fork in the Road](puzzles/T03-the-fork-in-the-road/) | `either/or` — nondeterministic control flow | ⭐ |
| T04 | [The Broken Door](puzzles/T04-the-broken-door/) | Multiple labels — atomicity and race conditions | ⭐⭐ |
| T05 | [The Toll Booth](puzzles/T05-the-toll-booth/) | `assert` — runtime checks inside the algorithm | ⭐ |
| T06 | [The Scoreboard](puzzles/T06-the-scoreboard/) | `define` block — operators as reusable vocabulary | ⭐ |
| T07 | [The Off-By-One](puzzles/T07-the-off-by-one/) | Deliberate bug — TLC as debugger | ⭐⭐ |
| T08 | [The Ticket Machine](puzzles/T08-the-ticket-machine/) | Capstone — combining all Tier 1 skills | ⭐⭐ |

## How to Use

1. Read the puzzle README
2. Write your PlusCal spec
3. Translate: `pcal YourSpec.tla`
4. Check: `tlc YourSpec.tla`
5. Compare with the solution in `solution/`

## Requirements

- [TLA+ tools](https://lamport.azurewebsites.net/tla/tools.html) (`pcal` and `tlc` on your PATH)

## Quality Gate

Every puzzle passes [six checks](QUALITY_GATE.md) before inclusion.
