# Pair 7: the floor gets cleared

The first run is one the floor can produce. Your model must allow it. The
second is one the floor can't produce. Your properties must rule it out.

## Allowed

```
State 1
  stage:        p1 on the floor | p2 on the floor | p3 on the floor
  modification: p1 0 | p2 0 | p3 0

State 2
  stage:        p1 on the floor | p2 a loss | p3 on the floor
  modification: p1 0 | p2 no count | p3 0

State 3
  stage:        p1 on the floor | p2 a loss | p3 on the floor
  modification: p1 1 | p2 no count | p3 0

State 4
  stage:        p1 on the floor | p2 a loss | p3 on the floor
  modification: p1 2 | p2 no count | p3 0

State 5
  stage:        p1 on the floor | p2 a loss | p3 on the floor
  modification: p1 3 | p2 no count | p3 0

State 6
  stage:        p1 on the floor | p2 a loss | p3 a loss
  modification: p1 3 | p2 no count | p3 no count

State 7
  stage:        p1 a loss | p2 a loss | p3 a loss
  modification: p1 no count | p2 no count | p3 no count
```

## Forbidden

```
State 1
  stage:        p1 on the floor | p2 on the floor | p3 on the floor
  modification: p1 0 | p2 0 | p3 0

State 2
  stage:        p1 on the floor | p2 a loss | p3 on the floor
  modification: p1 0 | p2 no count | p3 0

State 3
  stage:        p1 on the floor | p2 a loss | p3 on the floor
  modification: p1 1 | p2 no count | p3 0

State 4
  stage:        p1 on the floor | p2 a loss | p3 on the floor
  modification: p1 2 | p2 no count | p3 0

State 5
  stage:        p1 on the floor | p2 a loss | p3 on the floor
  modification: p1 3 | p2 no count | p3 0

State 6
  stage:        p1 on the floor | p2 a loss | p3 a loss
  modification: p1 3 | p2 no count | p3 no count

(from the last state on, nothing ever changes)
```
