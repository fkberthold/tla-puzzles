# Completion items

9 items across 8 families. Each one gives you a working machine with its
properties taken out, and three runs that grade what you put back.

## How to work one

```bash
cd completion/<family>/<NN>-<slug>
```

1. Read `PROMPT.md`. It states each missing claim in English.
2. Open `work/Claims.tla`. It is the only file you edit.
3. Replace each `FILL_IN_CLAIM_n` marker with a formula.
4. Run the grader.

```bash
bash ~/repos/tla-puzzles/completion/verify-item.sh .
```

Ten to twenty-five minutes an item, by the estimate in each one's `META.md`.

## Why there are three machines

One of them is the real machine and your claims have to hold on it. The other
two are broken, and your claims have to catch them.

That second half is the point. `TRUE` holds on the real machine, so a claim
that passes it has proved nothing. The two broken machines are what tell a real
claim from an empty one, and each is built so exactly one of your claims can
fire on it.

So three exit codes say which claim is weak, not just that one is.

| what you get | what it means |
|---|---|
| 0, then two non-zero | both claims hold and both bite |
| 0, 0, 0 | neither claim says anything |
| 0, non-zero, 0 | the first claim is good, the second is too weak |
| 0, 0, non-zero | the second claim is good, the first is too weak |

Each item's `PROMPT.md` carries its own table with the real codes in it, since a
safety claim answers 12 and a liveness claim answers 13.

Exit code 150 means nothing parsed. The grader says whether a marker is still
in place or whether what you wrote is not a formula, and on the second it
prints the parser's own sentence.

## What's missing, on purpose

- `ANSWER.md`, the reference claims, why each holds, and the variants that count
- `META.md`, the constructs each hole needs, and the reading model the item varies

Both are at `~/repos/tla-puzzles/completion/<family>/<item>/`.

## These are variations, not copies

Eight of the 9 items vary a module from the reading corpus rather than reuse
one. Same vocabulary, same kind of machine, a different fact to state. So the
published reading page at <https://fkberthold.github.io/tla-puzzles/reading/>
is worth opening when you are stuck, and it will not hand you the answer.

`sets/01-clockface` is the exception and it is deliberate. It reuses its
reading model whole, so its answer is published, and it is the item that
teaches you what the three codes mean.
