# Two tanks, one hose

Ten minutes of thinking. Every run is under a second.

## The system

A plant has header tanks. A tank holds some number of units, up to its
own capacity. It starts empty. One unit goes in per pour, and a tank can
be drained to empty at any moment. That's the whole tank, and the plant
already has a module for it, used by two other specs. You'll have to
write that module too, but it's shared, so nothing in it may know about
any particular pair.

Now the pair. Two tanks with different capacities fed by one hose. Each
step is one pour into one tank or one drain of one tank, and the other
tank holds still. Nothing about a tank is written twice.

The requirement: neither tank ever holds more than its capacity.

## What happened

| model | verdict | distinct states | depth |
|---|---|---|---|
| one tank alone, capacity 2 | clean | 3 | 3 |
| the pair, capacities 2 and 3 | clean | 12 | 6 |
| the pair, capacities 2 and 2 | clean | 9 | 5 |
| the pair, both copies of the tank brought in without a name, the pair writing its own behaviour formula | refused: a definition the pair wrote was already there | | |
| the pair, both copies brought in without a name, the pair writing nothing of its own | stopped on the first state, with one tank's level reported as null | | |
| the pair, capacities given but levels not | refused: something the tank declares was never substituted | | |

## The questions

1. Write the tank module, the pair module, and the config for row two.
   Each copy of the tank has to be told which capacity it has and which
   variable of the pair it lives in.
2. Rows four and five. Which names arrived twice, and why does naming
   each copy fix it? Why did row five get as far as a state at all?
3. Row six. The tank module declares one thing that isn't a constant.
   What happens to it when the pair doesn't say where it goes?
4. Explain the 12 and the 9 from the 3.

Write it, reproduce the 12, then break it all three ways.
