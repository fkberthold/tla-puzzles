# Traces for the branch transfer

Every requirement in `../PROBLEM.md` ships with a run that breaks it, one per
file. The allowed side is `allowed.md`, which holds two behaviours the standing
orders permit. Each violating run comes from a model that got one thing wrong,
and each file says where its behaviour breaks the requirement.

Read them before you model. If TLC later hands you a counterexample shaped like
one of these, you're standing in that trap.

## How to read the tables

Every row is one state of the observation, nothing else. The columns are the
three `Observe` fields plus a narration of the step that led in.

- **sending**: `Observe.sending`, both members, m1 first.
- **receiving**: `Observe.receiving`, the same two.
- **answer**: `Observe.answer`. Every run starts at waiting.

The instance is two members, m1 and m2. The narration column speaks the
society's language. It isn't a fourth field, and your model doesn't have to
name any of it.

## The files

| File | Requirement |
|---|---|
| `allowed.md` | satisfies all three |
| `requirement-01.md` | nothing stands half-made |
| `requirement-02.md` | nobody is off both rolls |
| `requirement-03.md` | nobody is on both rolls |

Each violating run breaks the requirement it's named for and holds the other
two. So a formula of yours that goes red on another requirement's run is asking
for more than its own requirement does.

All three break at the second state. A counterexample of your own that runs
twenty states deep is telling you about something else.
