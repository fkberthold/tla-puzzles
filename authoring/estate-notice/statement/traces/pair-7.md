# Pair 7

These two runs are about requirement 7. The first stays inside the rules. The
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
  standing:    c1 admitted | c2 none
  notice:      closed
  distributed: FALSE

State 5
  standing:    c1 paid | c2 none
  notice:      closed
  distributed: FALSE

State 6
  standing:    c1 paid | c2 none
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
  standing:    c1 lodged | c2 none
  notice:      open
  distributed: FALSE

State 3
  standing:    c1 lodged | c2 lodged
  notice:      open
  distributed: FALSE

State 4
  standing:    c1 rejected | c2 lodged
  notice:      open
  distributed: FALSE

State 5
  standing:    c1 rejected | c2 admitted
  notice:      open
  distributed: FALSE

State 6
  standing:    c1 rejected | c2 paid
  notice:      open
  distributed: FALSE
```

The forbidden run doesn't end. From state 6 onward nothing more ever happens.
Both creditors are settled, and the notice stays open forever.
