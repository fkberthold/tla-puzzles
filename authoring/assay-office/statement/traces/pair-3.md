# Pair 3

The first run stays inside the rules. The second breaks at least one rule.

## Allowed

```
State 1
  finding: w1 not tested | w2 not tested | w3 not tested
  marked:  w1 unmarked | w2 unmarked | w3 unmarked
  defaced: w1 whole | w2 whole | w3 whole

State 2
  finding: w1 substandard | w2 not tested | w3 not tested
  marked:  w1 unmarked | w2 unmarked | w3 unmarked
  defaced: w1 whole | w2 whole | w3 whole

State 3
  finding: w1 substandard | w2 at standard | w3 not tested
  marked:  w1 unmarked | w2 unmarked | w3 unmarked
  defaced: w1 whole | w2 whole | w3 whole

State 4
  finding: w1 substandard | w2 at standard | w3 not tested
  marked:  w1 unmarked | w2 unmarked | w3 unmarked
  defaced: w1 defaced | w2 whole | w3 whole
```

## Forbidden

```
State 1
  finding: w1 not tested | w2 not tested | w3 not tested
  marked:  w1 unmarked | w2 unmarked | w3 unmarked
  defaced: w1 whole | w2 whole | w3 whole

State 2
  finding: w1 substandard | w2 not tested | w3 not tested
  marked:  w1 unmarked | w2 unmarked | w3 unmarked
  defaced: w1 whole | w2 whole | w3 whole

State 3
  finding: w1 substandard | w2 at standard | w3 not tested
  marked:  w1 unmarked | w2 unmarked | w3 unmarked
  defaced: w1 whole | w2 whole | w3 whole

State 4
  finding: w1 substandard | w2 at standard | w3 at standard
  marked:  w1 unmarked | w2 unmarked | w3 unmarked
  defaced: w1 whole | w2 whole | w3 whole

State 5
  finding: w1 substandard | w2 at standard | w3 at standard
  marked:  w1 unmarked | w2 struck | w3 unmarked
  defaced: w1 whole | w2 whole | w3 whole

State 6
  finding: w1 substandard | w2 at standard | w3 at standard
  marked:  w1 unmarked | w2 struck | w3 struck
  defaced: w1 whole | w2 whole | w3 whole
```

After state 6 nothing more happens, ever. The office stays as state 6 shows
it, for the whole rest of the run. That last clause is the whole fault. The
six states above it are an ordinary run of the office.
