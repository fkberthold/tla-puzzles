# Pair 4: turning adds one

The first run is one the floor can produce. Your model must allow it. The
second is one the floor can't produce. Your properties must rule it out.

## Allowed

```
State 1
  stage:        p1 on the floor | p2 on the floor | p3 on the floor
  modification: p1 0 | p2 0 | p3 0

State 2
  stage:        p1 on the floor | p2 on the floor | p3 on the floor
  modification: p1 1 | p2 0 | p3 0

State 3
  stage:        p1 on the floor | p2 on the floor | p3 on the floor
  modification: p1 2 | p2 0 | p3 0
```

## Forbidden

```
State 1
  stage:        p1 on the floor | p2 on the floor | p3 on the floor
  modification: p1 0 | p2 0 | p3 0

State 2
  stage:        p1 on the floor | p2 on the floor | p3 on the floor
  modification: p1 2 | p2 0 | p3 0
```
