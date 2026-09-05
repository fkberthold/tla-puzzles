# Pair 6

These two runs are about requirement 6. The first stays inside the rules. The
second breaks at least one of them.

## Allowed

```
State 1
  standing:    c1 none | c2 none
  notice:      open
  distributed: FALSE

State 2
  standing:    c1 none | c2 none
  notice:      closed
  distributed: FALSE

State 3
  standing:    c1 none | c2 none
  notice:      closed
  distributed: TRUE

State 4
  standing:    c1 outOfTime | c2 none
  notice:      closed
  distributed: TRUE
```

## Forbidden

```
State 1
  standing:    c1 none | c2 none
  notice:      open
  distributed: FALSE

State 2
  standing:    c1 none | c2 none
  notice:      closed
  distributed: FALSE

State 3
  standing:    c1 none | c2 none
  notice:      closed
  distributed: TRUE

State 4
  standing:    c1 none | c2 none
  notice:      closed
  distributed: FALSE
```
