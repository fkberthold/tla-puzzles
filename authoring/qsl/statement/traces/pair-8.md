# Pair 8

The first run stays inside the rules. The second breaks at least one rule.

## Allowed

```
State 1
  filed:    o1 {} | o2 {} | o3 {}
  credited: o1 {} | o2 {} | o3 {}

State 2
  filed:    o1 {o2 on b1} | o2 {} | o3 {}
  credited: o1 {} | o2 {} | o3 {}

State 3
  filed:    o1 {o2 on b1} | o2 {o1 on b1} | o3 {}
  credited: o1 {} | o2 {} | o3 {}

State 4
  filed:    o1 {o2 on b1} | o2 {o1 on b1} | o3 {}
  credited: o1 {o2 on b1} | o2 {o1 on b1} | o3 {}

State 5
  filed:    o1 {o2 on b1} | o2 {o1 on b1} | o3 {o1 on b2}
  credited: o1 {o2 on b1} | o2 {o1 on b1} | o3 {}
```

## Forbidden

```
State 1
  filed:    o1 {} | o2 {} | o3 {}
  credited: o1 {} | o2 {} | o3 {}

State 2
  filed:    o1 {o2 on b1} | o2 {} | o3 {}
  credited: o1 {} | o2 {} | o3 {}

State 3
  filed:    o1 {o2 on b1} | o2 {o1 on b1} | o3 {}
  credited: o1 {} | o2 {} | o3 {}

State 4
  filed:    o1 {o2 on b1} | o2 {o1 on b1} | o3 {}
  credited: o1 {o2 on b1} | o2 {o1 on b1} | o3 {}

State 5
  filed:    o1 {o2 on b1} | o2 {o1 on b1} | o3 {}
  credited: o1 {} | o2 {} | o3 {}
```
