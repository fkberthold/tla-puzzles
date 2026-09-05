# Pair 2

These two runs are about requirement 2. The first stays inside the rules. The
second breaks at least one of them.

## Allowed

```
State 1
  standing:    c1 none | c2 none
  notice:      open
  distributed: FALSE

State 2
  standing:    c1 lodged | c2 none
  notice:      open
  distributed: FALSE

State 3
  standing:    c1 lodged | c2 none
  notice:      closed
  distributed: FALSE

State 4
  standing:    c1 lodged | c2 outOfTime
  notice:      closed
  distributed: FALSE
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
  standing:    c1 lodged | c2 none
  notice:      closed
  distributed: FALSE
```
