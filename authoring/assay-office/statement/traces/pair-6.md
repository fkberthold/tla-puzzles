# Pair 6

The first run stays inside the rules. The second breaks at least one rule.

## Allowed

```
State 1
  finding: w1 not tested | w2 not tested | w3 not tested
  marked:  w1 unmarked | w2 unmarked | w3 unmarked
  defaced: w1 whole | w2 whole | w3 whole

State 2
  finding: w1 not tested | w2 substandard | w3 not tested
  marked:  w1 unmarked | w2 unmarked | w3 unmarked
  defaced: w1 whole | w2 whole | w3 whole

State 3
  finding: w1 not tested | w2 substandard | w3 not tested
  marked:  w1 unmarked | w2 unmarked | w3 unmarked
  defaced: w1 whole | w2 defaced | w3 whole

State 4
  finding: w1 at standard | w2 substandard | w3 not tested
  marked:  w1 unmarked | w2 unmarked | w3 unmarked
  defaced: w1 whole | w2 defaced | w3 whole
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
  finding: w1 substandard | w2 not tested | w3 not tested
  marked:  w1 unmarked | w2 unmarked | w3 unmarked
  defaced: w1 defaced | w2 whole | w3 whole

State 4
  finding: w1 substandard | w2 not tested | w3 not tested
  marked:  w1 unmarked | w2 unmarked | w3 unmarked
  defaced: w1 whole | w2 whole | w3 whole
```
