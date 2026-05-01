# A03: Apalache — Type Aliases ⭐

## Lesson: Naming a Type Once

A02 had this annotation:

```tla
\* @type: { id: Int, priority: Str };
VARIABLE currentOrder
```

That's fine for one variable. But what if FOUR variables and SIX operators all return the same record shape? You'd repeat the long type signature everywhere, and a single field rename means a sweeping edit.

Apalache lets you name a type once with a **type alias**:

```tla
\* @typeAlias: order = { id: Int, priority: Str };
```

After that line, you reference the alias with `$`:

```tla
\* @type: $order;
VARIABLE currentOrder

\* @type: Set($order);
VARIABLE allOrders
```

**Convention.** Aliases live in a single comment on a dedicated line, usually near the top of the spec inside a special module-level comment block. Snowcat 1.x recommends putting all aliases under a single `\* @typeAlias:` "header." Apalache recognizes any number of alias declarations.

**Worked example — a chess board.**

A chess engine spec uses a `square` record (file/rank coordinates) all over the place — for the king's position, the queen's position, every pawn's position, the legal moves set, and the move-history sequence. With aliases:

```tla
---- MODULE Chess ----
EXTENDS Integers

\* @typeAlias: square = { file: Int, rank: Int };
\* @typeAlias: move   = { from: $square, to: $square };
ChessTypes == TRUE

\* @type: $square;
VARIABLE king

\* @type: $square;
VARIABLE queen

\* @type: Set($square);
VARIABLE legalMoves

\* @type: Seq($move);
VARIABLE history

vars == << king, queen, legalMoves, history >>

Init ==
  /\ king       = [ file |-> 5, rank |-> 1 ]
  /\ queen      = [ file |-> 4, rank |-> 1 ]
  /\ legalMoves = {}
  /\ history    = << >>

MoveQueen ==
  \E f \in 1..8, r \in 1..8:
    LET dst == [ file |-> f, rank |-> r ] IN
    /\ queen' = dst
    /\ history' = Append(history, [ from |-> queen, to |-> dst ])
    /\ UNCHANGED << king, legalMoves >>

Next == MoveQueen

Spec == Init /\ [][Next]_vars
====
```

Notice three things:

1. **Two aliases, building on each other.** `move` uses `$square` in its definition. Aliases can reference earlier aliases.
2. **The `ChessTypes == TRUE` operator.** This is a common idiom: aliases sit inside a `\*` comment block above some operator. Apalache reads the comment regardless of what the operator does. `TRUE` is a no-op marker. (Some specs use a single-line comment block instead — both work.)
3. **`$square` in compound types.** `Set($square)`, `Seq($move)`, even nested aliases like the `move` record are all legal once `square` is declared.

**The key idea.** Aliases are pure shorthand. Apalache substitutes the body wherever `$name` appears. They don't add new types — they just save you from repeating yourself, and make field renames a single-line edit.

## Setup

A library catalog spec. The state we want to model:

- A set of all books currently on shelves.
- A sequence of recent borrowings (each borrowing has a book and a patron).
- The currently-displayed featured book.

Each book has fields `title` (string) and `pages` (integer). Each borrowing has fields `book` (a book record) and `patron` (string).

## Task

Write `Catalog.tla` using **type aliases** for `book` and `borrowing` (a borrowing's `book` field references the `book` alias).

Annotations required:
- `\* @typeAlias: book = { title: Str, pages: Int };`
- `\* @typeAlias: borrowing = { book: $book, patron: Str };`

Variables:
- `\* @type: Set($book);` `VARIABLE shelf`
- `\* @type: Seq($borrowing);` `VARIABLE recent`
- `\* @type: $book;` `VARIABLE featured`

Initial state:
- `shelf = { [title |-> "Hamlet", pages |-> 200], [title |-> "Dune", pages |-> 600] }`
- `recent = << >>`
- `featured = [ title |-> "Hamlet", pages |-> 200 ]`

Add ONE action `Borrow` that:
- Picks any book `b` from `shelf` and any patron name `p \in { "alice", "bob" }`.
- Removes `b` from `shelf`.
- Appends `[book |-> b, patron |-> p]` to `recent`.
- Leaves `featured` unchanged.

`TypeOK`:

```
TypeOK ==
  /\ shelf \subseteq { [title |-> "Hamlet", pages |-> 200], [title |-> "Dune", pages |-> 600] }
  /\ Len(recent) <= 2
  /\ featured.title \in { "Hamlet", "Dune" }
```

## Check

```bash
cd solution
tlc Catalog
```

If you have Apalache:

```bash
apalache-mc typecheck Catalog.tla
```

## Expected Result

- TLC: about 13 distinct states, no error.
- Snowcat: `Type checker [OK]`.
- Inline expansion test: replace every `$book` with the long form `{ title: Str, pages: Int }` (and every `$borrowing` with its body, including the now-inlined `book` field). The spec still type-checks identically. Aliases are pure shorthand.

## What you learned

- `\* @typeAlias: name = T;` declares an alias.
- Reference an alias with `$name` in any subsequent `@type` annotation.
- Aliases can nest: one alias can use another inside its body.
- Aliases vs annotations: `@typeAlias` declares, `@type` uses. Both are TLA+ comments invisible to TLC.

## Hints

??? hint "💡 Hint 1 — Two aliases in order"
    The lesson shows that a book has `title` and `pages`. A borrowing has a `book` (which is itself a book record) and a `patron` name. Write two `@typeAlias` declarations, and notice that the second one references the first with `$book`.

??? hint "💡 Hint 2 — The marker operator pattern"
    The lesson example uses `ChessTypes == TRUE` to "hold" the alias declarations in a comment block. This is a common pattern: aliases sit in `\*` comments just above an operator (which can be a no-op like `TRUE`). Write your two aliases above some operator to keep them organized.

??? hint "💡 Hint 3 — Reference aliases with $ in @type"
    Once you declare `\* @typeAlias: book = ...;`, use `\* @type: $book;` above the variable and `\* @type: Seq($borrowing);` for composite types. The dollar sign tells Apalache "substitute the alias body here."
