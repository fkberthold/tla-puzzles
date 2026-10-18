# tla-practice

Where Frank works problems. **The references and commentary are not here, and that is the point.**

## Why this is a separate directory

V2-PLAN.md §6b.1 says instruction isolation is not isolation: telling someone not to look at the
answers does not work, and the fix has to be structural. §2.4 says the practice/answers split "is a
leak defense, not a preference", and must not be simplified back into two directories of one repo.

The v2 pilot broke this rule and it was caught by an adversarial pass, not by the people who built
it: the answer key sat in the directory a blind critic reads, carrying the line "Never show this to
a critic". The v1 post-mortem records the same shape one layer down, in puzzles that printed the
answer in the next paragraph.

So: problems live here. References, commentary and answer keys live in the repo under
`pilot/` and, later, in a separate answers location. **Nothing releases a reference until an attempt
is recorded.**

## How to work a problem

1. `problems/<NN_name>/` holds everything you get: `PROBLEM.md`, an `ATTEMPT-LOG.md`,
   and for some task shapes a spec or traces to read. Treat the directory as read-only
   except the log. The two-digit prefix is the problem's position on the ramp and it
   comes from `problems/ORDER`.
2. Work it. Write your spec wherever you like, then copy your files into
   `attempts/<batch>/<NN_name>/`, keeping the problem's own directory name. The live
   batch is `attempts/2026-10-02-fresh-start/`.
3. Fill in the problem's `ATTEMPT-LOG.md` and copy it into that same directory with
   your spec. It is short and it is the only telemetry this project has.
4. Then ask for the reference. The commented reference and the author's alternatives
   note get copied into `released/<NN_name>/`, and your attempt gets graded through the
   harness.

The number is part of the name in all three trees, so `problems/`, `attempts/` and
`released/` line up directory for directory. Frank settled that on 2026-10-18, over the
alternative of naming an attempt for the bare problem name, because a matching name is
easier to track than a positional one you have to resolve first.

Each attempt batch keeps its own copy of `ORDER`, and that copy is what the batch's
numbers answer to. A later reorder of the ramp renumbers `problems/` and leaves the
batch alone, because a batch records what you worked and in what order, and renaming it
would falsify that record. `scripts/number-problems.sh --check <root>` in the repo
validates any tree against the `ORDER` sitting beside it.

## The problems

Seven, `01_bonded-store` through `07_estate-notice`, in the order `problems/ORDER`
gives.

The six batch-1 problems were withdrawn on 2026-09-04, because they were built for the
top of a ramp that didn't exist yet. They're in `attempts/withdrawn-2026-09-04/`, and
four of them (02 to 05) are a reserve set, unread and untuned. Don't open those four.
The design is bead `tla-h2cg`.

This section read "`problems/` stays empty until the ramp's first rungs land" until
2026-10-18, by which point seven problems had landed in it. Nothing in the repo sources
or checks this file, which is bead `tla-bxcd`.

Practical notes, learned the hard way so you don't have to:

- Every statement names its observation interface and the exact answer shapes. Grading
  runs through that operator and nothing else, so a mismatched field shape means your
  check never ran, not that it failed.
- `tlc -deadlock <Module>` turns deadlock checking OFF, despite the name. The statements
  say when to use it. A system that legitimately comes to rest is not an error.
- You do not need PlusCal. Raw TLA+ or PlusCal both work; the statements fix the system
  and leave the representation entirely to you.
- After each attempt we talk: your log drives revision of the problems you have not
  reached yet. That loop is the standing agreement, and the log's stuck question is
  what it runs on.

Step 3 is not bookkeeping. §7.0's whole reason for working in batches is that your telemetry shapes
the ~48 problems after this one. Without the log, batch 2 is authored on anecdote, and §7.1 cites
Kornell and Bjork: 78% of participants preferred the format that taught them worst, so your
impressions alone are a reliable signal about ambiguity and an unreliable one about difficulty.

## The one question that matters most

When you get stuck, §6b.4 wants this distinguished and says it is load-bearing:

> Is it the RULES OF THE SYSTEM that are unclear, or is it HOW TO MODEL them?

The first is a bug in the problem and gets fixed. The second is the problem working as intended and
gets left alone. Nobody can infer which from the outside, and guessing wrong means rewriting a
statement that was fine.
