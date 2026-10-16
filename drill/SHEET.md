# Construct sheet

The 12 cheat sheets at `exercises/ch*/CHEATSHEET.md` carry the syntax shape
of every construct this curriculum introduces. A study session has no reason
to open 12 files, so this is all of them, flat, one entry per construct.

105 entries, sorted by the `K` id, so this file, `drill/INVENTORY.md` and
`drill/COLD-LIST.md` all read in the same order. The id is the join. Find a
construct here, then read its coverage in the inventory.

Flat rather than per-family on purpose. A per-family sheet names the answer
shape for the family you are working. It gets read cold once, and after that
it is the answer key. This form selects nothing, so it leaks nothing, and I
think it is the only form that puts the ch03 PlusCal assignment beside the
ch12 `VARIABLE` declaration, with their chapters visible.

GENERATED. Do not hand-edit. The next run drops your change.

    bash scripts/gen-sheet.sh            # rewrite it from the cheat sheets
    bash scripts/gen-sheet.sh --check    # fail if it has drifted

`harness/test-sheet.sh` runs the second form.

- K001  ch02  Operator definition
  `Name(a, b) == expr` (or `Name == expr` with no arguments)

- K002  ch02  IF-THEN-ELSE
  `IF cond THEN a ELSE b`

- K003  ch02  Equality and inequality
  `a = b`, `a # b`

- K004  ch02  EXTENDS (module import)
  `EXTENDS Integers, Sequences`

- K005  ch02  Integers
  `123`, `-4`, needs `EXTENDS Integers` for arithmetic

- K006  ch02  Strings
  `"double quoted text"`

- K007  ch02  Booleans and logical operators
  `TRUE`, `FALSE`, `/\` (and), `\/` (or), `~` (not)

- K008  ch02  Bullet-point boolean notation
  stacked `/\` / `\/` lines, indentation is meaningful

- K009  ch02  Implication
  `A => B`

- K010  ch02  Sequences
  `<<a, b, c>>`, indexed with `seq[n]`, 1-indexed

- K011  ch02  Sequence module operators
  `Append(S, x)`, `Head(S)`, `Tail(S)`, `Len(S)`, `SubSeq(S, i, j)`, `S \o T`, needs `EXTENDS Sequences`

- K012  ch02  Sets
  `{1, 2, 3}`, unordered and unique

- K013  ch02  Set relational and algebraic operators
  `x \in set`, `x \notin set`, `s1 \subseteq s2`, `s1 \union s2`, `s1 \intersect s2`, `s1 \ s2`

- K014  ch02  Cardinality
  `Cardinality(set)`, needs `EXTENDS FiniteSets`

- K015  ch02  BOOLEAN and integer interval as sets
  `BOOLEAN`, `a..b`

- K016  ch02  Cartesian product
  `S \X T`

- K017  ch02  SUBSET (powerset)
  `SUBSET S`

- K018  ch02  Set map
  `{expr: x \in S}`

- K019  ch02  Set filter
  `{x \in S: P(x)}`

- K020  ch02  CHOOSE
  `CHOOSE x \in S: P(x)`

- K021  ch02  LET-IN
  `LET x == expr IN body`, can define several suboperators at once

- K022  ch03  --algorithm block
  `(* --algorithm Name variables x = 0; begin Label: x := 1; end algorithm; *)`

- K023  ch03  := assignment
  `x := expr` updates a variable. `x = expr` only compares or binds, never updates.

- K024  ch03  label
  `Name: statement;` marks one atomic step in time

- K025  ch03  || simultaneous assignment
  `seq[1] := a || seq[2] := b;` updates two parts of one variable in one label

- K026  ch03  skip
  `skip;` does nothing

- K027  ch03  assert
  `assert expr;` fails the model check right away if `expr` is false, needs `EXTENDS TLC`

- K028  ch03  goto
  `goto L;` jumps to label `L`. A new label must follow the `goto`.

- K029  ch03  PlusCal if
  `if Expr then ... elsif Expr2 then ... else ... end if;`

- K030  ch03  macro
  `macro name(arg) begin ... end macro;` a textual rewrite rule, no labels inside

- K031  ch03  with
  `with x = expr do ... end with;` a temporary binding, no labels inside

- K032  ch03  while
  `while Expr do ... end while;` the only loop form. Must follow a label.

- K033  ch03  \in on a variable declaration
  `variables x \in SomeSet;` runs the model once for every element of `SomeSet`

- K034  ch04  Invariant (as a TLA+ operator, checked at every state)
  `TypeInvariant == /\ var \in Set`

- K035  ch04  define block (PlusCal)
  `define { ... }`  (c-syntax, as used in every starter here; `define ... end define;` is the p-syntax spelling learntla shows)

- K036  ch04  pc (PlusCal's label-tracking variable)
  `pc = "LabelName"`

- K037  ch04  \A (universal quantifier, "forall")
  `\A x \in S: P(x)`

- K038  ch04  \E (existential quantifier, "exists")
  `\E x \in S: P(x)`

- K039  ch05  CONSTANT
  `CONSTANT S` or `CONSTANT S, Length`

- K040  ch05  ASSUME
  `ASSUME S # {}`

- K041  ch05  model value
  `CONSTANT Unclaimed = Unclaimed` in the `.cfg`. A bare word on the right of the `=`, no quotes and no digits, is a model value.

- K042  ch05  set of model values
  `CONSTANT Runners = {r1, r2, r3}` in the `.cfg`. Bare words again, one per element.

- K043  ch05  symmetry set
  `Perms == Permutations(Runners)` in the module, then `SYMMETRY Perms` in the `.cfg`. The module names the permutation set and the `.cfg` points at it.

- K044  ch06  struct literal
  `struct == [a |-> 1, b |-> 2]`, read with `struct["a"]` or `struct.a`

- K045  ch06  struct set
  `Type == [acct: Accounts, amnt: 1..10, type: {"deposit", "withdraw"}]`

- K046  ch06  DOMAIN
  `DOMAIN f` is the set of keys, indices, or inputs of `f`

- K047  ch06  function literal
  `F == [x \in S |-> expr]`, called with `F[x]`

- K048  ch06  :> (singleton function)
  `a :> b` is the one element function `[x \in {a} |-> b]`, needs `EXTENDS TLC`

- K049  ch06  @@ (function merge)
  `f @@ g` merges `f` and `g`, keeping `f`'s value on a shared key, needs `EXTENDS TLC`

- K050  ch06  function set
  `[S -> T]` is the set of all functions from `S` to `T`

- K051  ch07  nondeterministic with
  `with x \in set do ... end with;` tries every value in `set`

- K052  ch07  either-or
  `either branch1 or branch2 or branch3 end either;` picks one branch

- K053  ch08  process (single)
  `process writer = 1 begin AddToQueue: queue := Append(queue, 1); end process;`

- K054  ch08  pc[...] (multi-process pc)
  `pc[0]`, `pc` becomes a function from process values to labels once a spec has more than one process

- K055  ch08  process-local variable
  `process writer = 1 variables i = 0; begin ... end process;`, invisible outside the process and in `define` blocks

- K056  ch08  process set
  `process writer \in Writers begin ... end process;`, one process per element of `Writers`

- K057  ch08  self
  `queue := Append(queue, self);`, the current process's own value inside a process set

- K058  ch08  await
  `await queue = <<>>;`, blocks the label until the expression is true

- K059  ch08  deadlock (checking)
  no PlusCal keyword, TLC reports "deadlock" when no process has an enabled next action. Turned off from the model configuration, not from spec text

- K060  ch08  procedure
  `procedure Name(arg1, ...) variables var1 = ... begin Label1: ... Label2: ... return; end procedure;`

- K061  ch08  call
  `call Name(val1, ...);`, must be followed by a `goto`, a label, or another `return`

- K062  ch08  return
  `return;` ends the procedure and hands control back to the caller. TLC errors if a procedure ends without reaching one

- K063  ch09  [] (always)
  `[]P` is true when `P` holds in every state of the behavior

- K064  ch09  PROPERTY (TLC model config: register a temporal property)
  add `PROPERTY Safety` to the model, alongside but distinct from `INVARIANT`

- K065  ch09  fair process (weak fairness)
  `fair process Name = ... begin ... end process;`

- K066  ch09  fair+ (strong fairness)
  `fair+ process Name ...`, or mark one action strongly fair with `Label:+`

- K067  ch09  <> (eventually)
  `<>P` is true when `P` holds in at least one state of the behavior

- K068  ch09  <>[] (eventually always)
  `<>[]P` means `P` becomes true and then stays true for the rest of the behavior

- K069  ch09  []<> (always eventually)
  `[]<>P` means `P` becomes true infinitely often, though it can go false again in between

- K070  ch09  ~> (leads-to)
  `P ~> Q` means whenever `P` is true, `Q` becomes true now or in a later state

- K071  ch10  RECURSIVE
  `RECURSIVE Op(_)` before `Op(x) == ...`, lets `Op` reference itself

- K072  ch10  Higher-order operator parameter
  `Name(Op(_), arg) == ... Op(x) ...`, takes another operator as an argument

- K073  ch10  LAMBDA
  `LAMBDA x: expr`, builds an anonymous operator inline

- K074  ch10  Custom binary operator
  `a ++ b == expr`, defines a new infix operator from TLA+'s fixed symbol set

- K075  ch10  Bracket function definition
  `Name[x \in S] == expr`, sugar for `Name == [x \in S |-> expr]`

- K076  ch10  Recursive function definition
  `Name[x \in S] == expr` where `expr` calls `Name` again, no `RECURSIVE` keyword needed

- K077  ch10  CASE
  `CASE cond1 -> val1 [] cond2 -> val2 [] OTHER -> valN`

- K078  ch11  action property
  `Name == [][action]_vars`, checked with `PROPERTY Name` in the model, never `INVARIANT`

- K079  ch11  ' (prime, next-state value)
  `x'` is the value of `x` at the end of the current step, the start of the next step

- K080  ch11  [P]_x (box action formula)
  `[P]_x` is shorthand for `P \/ UNCHANGED x`

- K081  ch12  VARIABLE / VARIABLES
  `VARIABLE hr` or `VARIABLES counter, pc`, declared at module level the same way `CONSTANTS` are

- K082  ch12  vars (the all-variables tuple)
  `vars == << hr >>`, one operator naming every variable, used as the subscript in `[][Next]_vars`

- K083  ch12  Init / Next / Spec (the pure-TLA+ spec skeleton)
  `Init == /\ hr = 1`, `Next == IF hr = 12 THEN /\ hr' = 1 ELSE /\ hr' = hr + 1`, `Spec == Init /\ [][Next]_vars`. `Spec` is what you register as the temporal property to run.

- K084  ch12  action (formal definition)
  any boolean operator containing a primed variable, like `Next == IF hr = 12 THEN /\ hr' = 1 ELSE /\ hr' = hr + 1`. It is true for a pair `<<hr, hr'>>` exactly when it describes that step.

- K085  ch12  UNCHANGED
  `UNCHANGED x` means `x' = x`. `UNCHANGED <<x, y, z>>` means none of the three change.

- K086  ch12  nondeterministic action (\E form and disjunction form)
  `\E x \in 1..2: hr' = hr + x`, or equivalently `\/ hr' = hr + 1 \/ hr' = hr + 2`. An action is nondeterministic when more than one next state satisfies it.

- K087  ch12  EXCEPT
  `s' = [s EXCEPT ![1] = FALSE]`. `!` is the selector, `[1]` the element. Multiple keys in one statement: `[s EXCEPT ![1] = FALSE, ![2] = 17]`. Nested lookups: `[s EXCEPT ![1].x = ~@]`.

- K088  ch12  @ (the original value, inside EXCEPT)
  `counter' = [counter EXCEPT ![c] = @ + 1]`. Also usable in PlusCal function assignments, `counter[i] := @ + 1;`.

- K089  ch12  ProcSet
  `ProcSet == (Threads)`, the set of all process identities, used as the domain of `pc` and as the range of the `\A` in `Terminating`

- K090  ch12  label-as-action encoding
  `IncCounter(self) == /\ pc[self] = "IncCounter" /\ ... /\ pc' = [pc EXCEPT ![self] = "Done"]`. A `pc` guard enables the action, a `pc'` update advances it. Each label corresponds to exactly one action and vice versa.

- K091  ch12  Trans helper action for pc transitions
  `Trans(state, from, to) == /\ pc[state] = from /\ pc' = [pc EXCEPT ![state] = to]`, then `IncCounter(self) == /\ Trans(self, "IncCounter", "Done") /\ counter' = counter + 1`

- K092  ch12  Terminating
  `Terminating == /\ (\A self \in ProcSet: pc[self] = "Done") /\ UNCHANGED vars`, disjoined into `Next` to allow infinite stuttering once every process is done

- K093  ch12  ENABLED
  `ENABLED A` is true when `A` can be true this step, that is, when it can describe the next step

- K094  ch12  <<A>>_v (angle action formula)
  `<<A>>_v` is `A` is true *and* `v` changes. The mirror of `[A]_v`, which is `A` is true *or* `v` does not change.

- K095  ch12  WF_v(A) (weak fairness)
  `WF_v(A) == <>[](ENABLED <<A>>_v) => []<><<A>>_v`. If `A` is eventually always able to happen in a way that changes `v`, it eventually does.

- K096  ch12  SF_v(A) (strong fairness)
  `SF_v(A) == []<>(ENABLED <<A>>_v) => []<><<A>>_v`. If `A` is always eventually able to happen in a way that changes `v`, it eventually does.

- K097  ch12  fairness conjunct on Spec
  `Spec == /\ Init /\ [][Next]_vars /\ \A self \in Threads : SF_vars(thread(self))`, or a named `Fairness == /\ SF_status(Succeed) /\ WF_status(Retry)` conjoined as `Spec == Init /\ [][Next]_status /\ Fairness`

- K098  ch12  fairness on a subaction
  name the branch first, `Succeed == Trans("start", "done")`, then mark just that branch, `SF_status(Succeed)`. Reaches inside a label instead of covering all of it.

- K099  ch13  LOCAL (definition modifier)
  `LOCAL Op == "definition"`, keeps `Op` out of any spec that extends this module

- K100  ch13  INSTANCE
  `INSTANCE Sequences` on a line of its own, drops the module into the file namespace

- K101  ch13  LOCAL INSTANCE
  `LOCAL INSTANCE Integers`, the module is available here but its operators are not passed on to a spec that imports this one

- K102  ch13  named instance
  `Foo == INSTANCE Sequences`, binds the module to a name instead of the file namespace

- K103  ch13  ! (namespace lookup)
  `Foo!Append(seq, 1)` in place of `Append(seq, 1)`

- K104  ch13  INSTANCE ... WITH (<- constant substitution)
  `Origin == INSTANCE Point WITH X <- 0, Y <- 0`, supplies the imported module's constants

- K105  ch13  partial parameterization
  `XAxis(X) == INSTANCE Point WITH Y <- 0`, then called as `XAxis(2)!Add(x, y)`
