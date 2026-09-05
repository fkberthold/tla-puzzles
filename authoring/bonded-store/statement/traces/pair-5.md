# Pair 5

The first run stays inside the rules. The second breaks at least one rule.

## Allowed

```
State 1
  place:    l1 not entered | l2 not entered | l3 not entered
  dutyPaid: l1 unpaid | l2 unpaid | l3 unpaid

State 2
  place:    l1 in store | l2 not entered | l3 not entered
  dutyPaid: l1 unpaid | l2 unpaid | l3 unpaid

State 3
  place:    l1 moved on | l2 not entered | l3 not entered
  dutyPaid: l1 unpaid | l2 unpaid | l3 unpaid
```

## Forbidden

```
State 1
  place:    l1 not entered | l2 not entered | l3 not entered
  dutyPaid: l1 unpaid | l2 unpaid | l3 unpaid

State 2
  place:    l1 in store | l2 not entered | l3 not entered
  dutyPaid: l1 unpaid | l2 unpaid | l3 unpaid

State 3
  place:    l1 moved on | l2 not entered | l3 not entered
  dutyPaid: l1 paid | l2 unpaid | l3 unpaid
```
