# Cheat sheet: learntla core ch.12

## Header

- Chapter number: `12`
- Chapter title: `TLA+`
- learntla-v2 clone SHA: `09840bfc2ee9a88cdbedb672be77a6c73942fe16`

## Constructs introduced

- Construct: `VARIABLE` / `VARIABLES`
  Syntax shape: `VARIABLE hr` or `VARIABLES counter, pc`, declared at module level the same way `CONSTANTS` are
  Section anchor: `tla § Learning from PlusCal`

- Construct: `vars` (the all-variables tuple)
  Syntax shape: `vars == << hr >>`, one operator naming every variable, used as the subscript in `[][Next]_vars`
  Section anchor: `tla § Learning from PlusCal`

- Construct: `Init` / `Next` / `Spec` (the pure-TLA+ spec skeleton)
  Syntax shape: `Init == /\ hr = 1`, `Next == hr' = hr + 1`, `Spec == Init /\ [][Next]_vars`. `Spec` is what you register as the temporal property to run.
  Section anchor: `tla § Learning from PlusCal`

- Construct: `action` (formal definition)
  Syntax shape: any boolean operator containing a primed variable, like `Next == hr' = hr + 1`. It is true for a pair `<<hr, hr'>>` exactly when it describes that step.
  Section anchor: `tla § Learning from PlusCal`

- Construct: `UNCHANGED`
  Syntax shape: `UNCHANGED x` means `x' = x`. `UNCHANGED <<x, y, z>>` means none of the three change.
  Section anchor: `tla#UNCHANGED`

- Construct: nondeterministic action (`\E` form and disjunction form)
  Syntax shape: `\E x \in 1..2: hr' = hr + x`, or equivalently `\/ hr' = hr + 1 \/ hr' = hr + 2`. An action is nondeterministic when more than one next state satisfies it.
  Section anchor: `tla § with`

- Construct: `EXCEPT`
  Syntax shape: `s' = [s EXCEPT ![1] = FALSE]`. `!` is the selector, `[1]` the element. Multiple keys in one statement: `[s EXCEPT ![1] = FALSE, ![2] = 17]`. Nested lookups: `[s EXCEPT ![1].x = ~@]`.
  Section anchor: `tla § EXCEPT`

- Construct: `@` (the original value, inside `EXCEPT`)
  Syntax shape: `counter' = [counter EXCEPT ![c] = @ + 1]`. Also usable in PlusCal function assignments, `counter[i] := @ + 1;`.
  Section anchor: `tla § EXCEPT`

- Construct: `ProcSet`
  Syntax shape: `ProcSet == (Threads)`, the set of all process identities, used as the domain of `pc` and as the range of the `\A` in `Terminating`
  Section anchor: `tla § Modeling Concurrency`

- Construct: label-as-action encoding
  Syntax shape: `IncCounter(self) == /\ pc[self] = "IncCounter" /\ ... /\ pc' = [pc EXCEPT ![self] = "Done"]`. A `pc` guard enables the action, a `pc'` update advances it. Each label corresponds to exactly one action and vice versa.
  Section anchor: `tla § Modeling Concurrency`

- Construct: `Trans` helper action for `pc` transitions
  Syntax shape: `Trans(state, from, to) == /\ pc[state] = from /\ pc' = [pc EXCEPT ![state] = to]`, then `IncCounter(self) == /\ Trans(self, "IncCounter", "Done") /\ counter' = counter + 1`
  Section anchor: `tla#trans`

- Construct: `Terminating`
  Syntax shape: `Terminating == /\ \A self \in ProcSet: pc[self] = "Done" /\ UNCHANGED vars`, disjoined into `Next` to allow infinite stuttering once every process is done
  Section anchor: `tla § Modeling Concurrency`

- Construct: `ENABLED`
  Syntax shape: `ENABLED A` is true when `A` can be true this step, that is, when it can describe the next step
  Section anchor: `tla § Fairness in TLA+`

- Construct: `<<A>>_v` (angle action formula)
  Syntax shape: `<<A>>_v` is `A` is true *and* `v` changes. The mirror of `[A]_v`, which is `A` is true *or* `v` does not change.
  Section anchor: `tla § Fairness in TLA+`

- Construct: `WF_v(A)` (weak fairness)
  Syntax shape: `WF_v(A) == <>[](ENABLED <<A>>_v) => []<><<A>>_v`. If `A` is eventually always able to happen in a way that changes `v`, it eventually does.
  Section anchor: `tla § Fairness in TLA+`

- Construct: `SF_v(A)` (strong fairness)
  Syntax shape: `SF_v(A) == []<>(ENABLED <<A>>_v) => []<><<A>>_v`. If `A` is always eventually able to happen in a way that changes `v`, it eventually does.
  Section anchor: `tla § Fairness in TLA+`

- Construct: fairness conjunct on `Spec`
  Syntax shape: `Spec == /\ Init /\ [][Next]_vars /\ \A self \in Threads : SF_vars(thread(self))`, or a named `Fairness == /\ SF_status(Succeed) /\ WF_status(Retry)` conjoined as `Spec == Init /\ [][Next]_status /\ Fairness`
  Section anchor: `tla § Fairness in TLA+`

- Construct: fairness on a subaction
  Syntax shape: name the branch first, `Succeed == Trans("start", "done")`, then mark just that branch, `SF_status(Succeed)`. Reaches inside a label instead of covering all of it.
  Section anchor: `tla#fairness_status_example`

## Major themes

- The chapter bootstraps pure TLA+ out of PlusCal, by reading the translator's output. The translated TLA+ is known-valid, and it must do the same thing the PlusCal did, so it can be used as the answer key for what each PlusCal construct means.
- In TLA+ it is all comparison, never assignment. `x = 5` is true when `x` is 5 in this state, `x' = 5` is true when `x` is 5 in the next state. That is why PlusCal needs both `=` and `:=` and TLA+ needs only `=`.
- A spec is `Init /\ [][Next]_vars`, which expands to `Init /\ [](Next \/ UNCHANGED vars)`. By convention anything outside a temporal operator is tested in the initial state, so this reads as `Init` holds at the start and `Next` accurately describes every step. That is the next-state relationship, and it is the blueprint every spec follows.
- The next action must fully describe every variable. Leave one out and TLC reports "Successor state is not completely specified by the next-state action". The translator emits `x' = x` for an unused variable; by hand you write `UNCHANGED x`.
- The same completeness rule bites harder on functions. `s[1]' = FALSE` says nothing about `s[2]'`, so TLC rejects it with the unhelpful "the identifier s is either undefined or not an operator". `EXCEPT` is the fix, and the chapter admits the syntax is awkward.
- The PlusCal-to-TLA+ translation is mechanical and readable. Deterministic `with` becomes `LET`, which is why a `with` cannot contain labels. Nondeterministic `with` becomes `\E` and `either` becomes `\/`, and in both cases the primed variable is set inside the quantifier or the branch.
- Concurrency is just `\E self \in Threads: thread(self)`. Sequentiality within a process is emulated by guarding each action on `pc[self]` and updating `pc'` to the next label. There is no other machinery.
- `await` needs no translation machinery either. `await lock = NULL` becomes the plain conjunct `/\ lock = NULL`, which simply fails to enable the action when it is false.
- TLA+ can describe any set of behaviors, including ones TLC cannot enumerate. `Next == x' >= x` is a valid spec whose behaviors include `1 -> 9 -> 17 -> 17.1 -> 84`. Valid spec and checkable spec are two different things.
- Fairness is a constraint appended to `Spec`, not a property checked against it. `Spec` defines what counts as a valid trace, and the fairness conjuncts rule out traces that stutter forever instead of taking an available step.
- Whether you write `\A self \in Threads : SF_vars(thread(self))` or `\E` decides whether every thread is fair or only one of them is. The chapter offers this as its own comprehension test: if both readings are syntactically intuitive, you understand pure TLA+.
- Pure TLA+ earns its steeper learning curve on a short list of things PlusCal cannot reach: helper actions, fairness on subactions rather than whole labels, verifying a refactored spec behaves the same, interruptible algorithms (a `\/ pc' = "Start"` disjunct instead of a duplicated `either` in every label), several sequential tasks per worker, and refinement. Sticking with PlusCal is fine, as long as you know where its limits are.

## Boundary notes

- `'` (prime, the next-state value) is covered in chapter `11` instead. This chapter reuses it and adds the formal name for a boolean operator containing one, an action.
- `[P]_x` (the box action formula, `P \/ UNCHANGED x`) is covered in chapter `11` instead. This chapter supplies the `UNCHANGED` half of the expansion and adds the mirror form `<<A>>_v`.
- Helper actions inside an *action property* are covered in chapter `11` instead (`action-properties.rst:141`). The `trans` entry here is the spec-side use, factoring `pc` transitions out of the actions themselves.
- `[]`, `<>`, `<>[]`, and `[]<>`, which the `WF_v` and `SF_v` definitions are written in, are covered in chapter `09` instead.
- PlusCal fairness, `fair process` and `fair+` and the `Label:+` action form, is covered in chapter `09` instead. This chapter gives the pure-TLA+ operators those modifiers translate into, and the subaction reach PlusCal does not have.
- `process`, process sets, `self`, and `await` are covered in chapter `08` instead. This chapter shows only what each becomes after translation.
- Deadlock, and the fact that the translator inserts `Terminating` to avoid one on completion, is covered in chapter `08` instead (`concurrency.rst:219`). That chapter names `Terminating` in prose without showing it; this chapter gives its body.
- The PlusCal `label` (`Name: statement;`) is covered in chapter `03` instead. The label-as-action entry here is what one becomes after translation, a `pc` guard plus a `pc'` update.
- `pc` is covered in chapter `04` instead, and its multi-process function form in chapter `08`. This chapter only shows the TLA+ side, its `ProcSet` initialization and its `EXCEPT` update.
- `\A` and `\E` are covered in chapter `04` instead. This chapter puts them to two new uses, a primed variable assigned inside `\E`, and process interleaving expressed as `\E self \in ProcSet`.
- Nondeterministic `with x \in set` and `either-or`, the PlusCal forms of this chapter's `\E` and `\/` actions, are covered in chapter `07` instead.
- Deterministic `with` is covered in chapter `03` instead, and the `LET` it translates into in chapter `02`.
- Function literals (`[x \in S |-> expr]`), used here to initialize `pc`, are covered in chapter `06` instead. `EXCEPT` is the update counterpart this chapter adds.
- `IF-THEN-ELSE`, `LET-IN`, and the boolean operators `/\`, `\/`, `~` are covered in chapter `02` instead.
- `CONSTANT` declarations, which `VARIABLE` is introduced by analogy to, are covered in chapter `05` instead.
- Verifying that a refactored spec has the same behavior is covered in `topics/tips.rst` instead, outside `core` (target `action_refactoring` at `tips.rst:279`). Refinement properties, the last item on the chapter's why-TLA+ list, are covered in `topics/refinement.rst`, also outside `core`.
- Multi-module specs and `INSTANCE`, the other place `VARIABLE` declarations appear, are covered in chapter `13` instead.
