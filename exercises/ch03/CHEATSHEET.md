# Cheat sheet: chapter 3

## Header

- Chapter number: `03`
- Chapter title: `Writing Specifications`
- learntla-v2 clone SHA: `09840bfc2ee9a88cdbedb672be77a6c73942fe16`

## Constructs introduced

- Construct: `--algorithm` block
  Syntax shape: `(* --algorithm Name variables x = 0; begin Label: x := 1; end algorithm; *)`
  Section anchor: `pluscal § PlusCal`

- Construct: `:=` assignment
  Syntax shape: `x := expr` updates a variable. `x = expr` only compares or binds, never updates.
  Section anchor: `pluscal § PlusCal`

- Construct: label
  Syntax shape: `Name: statement;` marks one atomic step in time
  Section anchor: `pluscal#labels`

- Construct: `||` simultaneous assignment
  Syntax shape: `seq[1] := a || seq[2] := b;` updates two parts of one variable in one label
  Section anchor: `pluscal#||`

- Construct: `skip`
  Syntax shape: `skip;` does nothing
  Section anchor: `pluscal § PlusCal expressions`

- Construct: `assert`
  Syntax shape: `assert expr;` fails the model check right away if `expr` is false
  Section anchor: `pluscal#assert`

- Construct: `goto`
  Syntax shape: `goto L;` jumps to label `L`. A new label must follow the `goto`.
  Section anchor: `pluscal#goto`

- Construct: PlusCal `if`
  Syntax shape: `if Expr then ... elsif Expr2 then ... else ... end if;`
  Section anchor: `pluscal#if_pluscal`

- Construct: `macro`
  Syntax shape: `macro name(arg) begin ... end macro;` a textual rewrite rule, no labels inside
  Section anchor: `pluscal#macro`

- Construct: `with`
  Syntax shape: `with x = expr do ... end with;` a temporary binding, no labels inside
  Section anchor: `pluscal#with`

- Construct: `while`
  Syntax shape: `while Expr do ... end while;` the only loop form. Must follow a label.
  Section anchor: `pluscal#while`

- Construct: `\in` on a variable declaration
  Syntax shape: `variables x \in SomeSet;` runs the model once for every element of `SomeSet`
  Section anchor: `pluscal#multiple_starting_states`

## Major themes

- PlusCal compiles to TLA+ through a translation step in a comment block. TLC runs the translated output, not the PlusCal you typed.
- A label marks one atomic step. Where you place labels decides how much concurrency the spec allows.
- Every statement must belong to a label, and a variable can update only once per label. `||` is the escape hatch for a double update.
- PlusCal's statement and block constructs (`skip`, `assert`, `goto`, `if`, `macro`, `with`, `while`) each carry their own labeling rule.
- Declaring a variable with `\in` runs the model over every element of a set instead of one fixed value, growing state-space coverage.
- TLC's run stats (diameter, states found, distinct states, per-label counts) show whether the model check explored what you expected.

## Boundary notes

- Checking that the duplication checker actually finds duplicates (writing `IsUnique` and matching the algorithm against it) is covered in chapter `04` instead. (`pluscal.rst:266`)
- How to translate and run a model in the TLC toolbox is covered in chapter `01` instead. (`pluscal.rst:275`, target `running_models` defined at `setup.rst:54`)
- Building the sets fed into `\in` (set-builder syntax like `{x*x: x \in 1..4}`) is covered in chapter `02` instead. (`pluscal.rst:355`, target `sets_of_values` defined at `operators.rst:286`)
- Variable-length sequences, the gap left by testing only one fixed sequence length, are covered in chapter `06` instead. (`pluscal.rst:364`)
- Writing a spec in pure TLA+ with no PlusCal at all is covered in chapter `12` instead. (`pluscal.rst:19`)
