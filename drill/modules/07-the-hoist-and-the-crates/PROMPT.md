# The hoist and the crates

Eight minutes of thinking. Every run is under a second.

## The system

A goods hoist with a weight limit. Crates wait on the floor. A crate
boards if it's not already aboard and the load with it would still be
within the limit. A crate leaves whenever. The load is the total weight
of what's aboard. Crates are told apart by their weight, so no two weigh
the same, and that's a modelling choice you should state.

The total has to be computed from a set, inside the spec, with no
library beyond the arithmetic one. Keep the summing definition local to
the place that uses it, with its helper next to it, so the module's top
level has only the hoist in it.

The requirement: the load never exceeds the limit.

## What happened

| model | verdict | distinct states |
|---|---|---|
| crates of 40, 70 and 90, limit 150 | clean | 6 |
| crates of 40, 50 and 60, limit 150 | clean | 8 |
| the same sum, one line short | refused: the sum's own name was unknown inside its body | |
| the boarding rule without the weight check | violation | 7 |

## The questions

1. Write it. Row three is one line short. What is the line, and what is
   it for?
2. The second row kills a shortcut. Which one?
3. There's a way to write the sum with no declaration at all. What is
   it, and what does it cost?

Write it, reproduce the 6, then take that line off.
