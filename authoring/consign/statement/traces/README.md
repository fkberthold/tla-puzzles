# Reading these traces

One pair per obligation: a trace that satisfies it, and one that violates
it. The pairs use a small instance of the round:

- **Ann** consigns the **lamp** and the **clock**
- **Ben** consigns the **radio** and the **vase**
- the floor holds two items (`Floor = 2`)

Each row of a table is one state of the book, exactly what
`Observe.standing` shows, nothing more. The satisfying traces come from a
correct model, and each is a real run TLC found. The violating traces come
from models broken in one deliberate way, and each is the counterexample TLC
printed. Read a pair to check your reading of an obligation before you
formalize it.

| Obligation | Pair |
|---|---|
| 1, the opening | `opening.md` |
| 2, one standing each | `standings.md` |
| 3, the cap | `cap.md` |
| 4, one way only | `path.md` |
| 5, single steps, whole payouts | `till.md` |
