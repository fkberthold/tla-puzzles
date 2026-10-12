# Answer: the view that hides the bug

Files in `verify/`. `RetryHistory.tla` is client A. `RetryAudit.tla` is
client B, with a `Strict` constant for the fix.

Every number from `tlc -workers 1` on TLC2 Version 2026.07.31.184830.

## Question 1: which clean is wrong

A's. The bug is still in and the run says clean after 3 states.

The instruction is `VIEW`. The module defines a tuple of the variables
TLC should fingerprint, and the config names it:

```
StatusOnly == <<status>>
```

```
VIEW StatusOnly
```

TLC fingerprints a state by the view instead of by the whole state. Two
states with the same view are the same state to it, and it expands the
first one it meets and drops the rest as already seen.

On A, every "failed" state has the same view. The first one TLC meets
has one error in the log. The one with two errors looks identical, so
it's never expanded. The one with four errors, where the bug lives at
depth 8, is never generated at all. Three states, depth 2, clean.

On B, the view is `<<status, tries>>`. The counter is still in the
fingerprint, the log isn't. The next-state relation reads the counter
and never the log, so two states that differ only in the log have the
same successors up to the log. Dropping one loses nothing TLC would have
done with it.

| run | rc | distinct | depth | wall |
|---|---|---|---|---|
| A, no view | 12 | 12 | 8 | 0.3 s |
| A, view | **0** | 3 | 2 | 0.3 s |
| B buggy, no view | 12 | 45 | 8 | 0.3 s |
| B buggy, view | 12 | 12 | 8 | 0.3 s |
| B fixed, no view | 124 | 2,628,536 at 30 s | | 30.1 s |
| B fixed, view | 0 | 10 | 7 | 0.3 s |

B's bug is found with the view at the same depth, which is the check
that the view lost nothing there.

## Question 2: what the view changes

It changes which states TLC considers already seen. That's all. It
doesn't change the next-state relation, it doesn't change which
invariants run, and it doesn't state anything. TLC still generates every
successor of every state it expands and still checks each one.

So the failure mode is omission, not false positives. A view can't make
TLC report a violation that isn't there, because every state it checks
is a real reachable state. It can make TLC never reach one. Lamport says
so at *Specifying Systems* p. 244: with a non-default view "TLC may stop
before it has found all reachable states", and it "may incorrectly check
the ImpliedTemporal property". Both runs above are the first half of
that sentence.

## Question 3: the condition

A variable can be left out of the view when nothing TLC evaluates reads
it: not the next-state relation, not any invariant, not any property.

You can check that by reading the module. In `RetryAudit.tla`, `log`
appears on the left of a prime in `Succeed` and `Fail`, in `UNCHANGED`
elsewhere, and nowhere else. In `RetryHistory.tla`, `Errs` reads it and
`Retry`, `GiveUp` and `WithinBudget` all read `Errs`.

The corpus agrees with the condition. All 15 resolvable `VIEW` targets
in 666 published modules are tuples of variables, and the usual shape is
the full state minus a bookkeeping variable
(`.claude/rules/tla-practice.md`, section 5). None is a record and none
projects a variable that the relation reads.

## Question 4: the other knob

`CONSTRAINT LogShort` with `LogShort == Len(log) <= 6` on B fixed: rc 0,
262 distinct states, depth 15. That finishes, and it checks a system
where jobs can be resubmitted about three times. The view checks the
unbounded one in 10 states. When the hidden variable meets the condition
in question 3, I'd take the view every time, because it doesn't change
the system and the constraint does.

## Variants worth running

Put `log` back in B's view. The fixed run goes infinite again, which is
the check that the log alone was the blow-up.

Give A a view of `<<status, Errs>>`. That's a derived value, not a
variable, and it's the one thing the relation reads. I'd expect it to
find the bug, and I haven't run it, so that's a guess.

## Gate rows

One thin wrapper module per run the drill gate reproduces, each with a
copy of the config it stands for. The rc is what `harness/verdict.sh`
returns.

| module | rc | stands for |
|---|---|---|
| `G03HistoryBug.tla` | rc 12 | `History.cfg`, client A, the bug at depth 8 |
| `G03HistoryHidden.tla` | rc 0 | `HistoryView.cfg`, client A with the log hidden, the false clean |
| `G03AuditBug.tla` | rc 12 | `AuditBuggy.cfg`, client B, the same bug |
| `G03AuditHidden.tla` | rc 0 | `AuditFixedView.cfg`, client B fixed with the log hidden, 10 states |

## why-not-in-prompt

The prompt says "there's a way to say that to TLC", which tells the
reader a mechanism exists without naming it. The counts do the rest: 3
states at depth 2 for a bug at depth 8 is the whole argument, and a
reader who sees it will work out that something stopped early.

What the prompt withholds: the keyword, that the view changes
fingerprinting and nothing else, that it can only omit and never invent,
and the one-sentence condition. Question 3 asks for the condition, so the
reader knows one exists.

The honest caveat: the prompt says B's log is "never read" and A's is
counted. That's the condition stated in prose, before the reader has
derived it. I left it in because the two clients have to differ in
that one way for the item to work, and a prompt that hid the
difference would be hiding the system rather than the answer.

