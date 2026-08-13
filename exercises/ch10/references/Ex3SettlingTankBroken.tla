---------------------------- MODULE Ex3SettlingTankBroken ----------------------------
\* Seeded-wrong copy of the exercise 3 reference, "The settling tank".
\*
\* THE SEEDED ERROR: `\ominus` is plain subtraction, with the floor at zero
\* dropped. Nothing else differs. The tank now drains past empty and reports
\* a negative level in the last hour, which is the case the floor was there
\* to catch.

EXTENDS Integers

\* ---------------- answer block, this is what you write ----------------

\* A binary operator. TLA+ will not let you invent a name for one, so this
\* borrows `\ominus` from the fixed set of symbols the language reserves for
\* the purpose. It earns its place here because `Level` below reads as the
\* physical thing it models once the floor is hidden inside the symbol.

x \ominus y == x - y

\* A recursive function, written with the bracket form. No RECURSIVE
\* declaration appears anywhere in this module. The bracket form carries its
\* own recursion, which is the one place TLA+ lets you skip the declaration.

Level[n \in 0..6] ==
    IF n = 0
    THEN 480
    ELSE (Level[n - 1] - Level[n - 1] \div 5) \ominus 40

\* A plain bracket function, no recursion. This is sugar for
\* `Drop == [n \in 1..6 |-> Level[n - 1] \ominus Level[n]]`.

Drop[n \in 1..6] == Level[n - 1] \ominus Level[n]

\* ---------------- scaffolding below this line ----------------

\* The spec needs one variable so TLC has a state to check the invariant in.
\* It never changes.
VARIABLE probe

Init == probe = 0
Next == UNCHANGED probe

\* The `probe = 0` line is load bearing. Without it every conjunct is a
\* constant, TLC folds the whole invariant away before the run starts, and a
\* wrong answer comes back as a config error instead of a violation.
TankIsRight ==
    /\ probe = 0
    /\ (7 \ominus 3) = 4
    /\ (3 \ominus 7) = 0
    /\ (5 \ominus 5) = 0
    /\ Level[0] = 480
    /\ Level[1] = 344
    /\ Level[2] = 236
    /\ Level[3] = 149
    /\ Level[4] = 80
    /\ Level[5] = 24
    /\ Level[6] = 0
    /\ Drop[1] = 136
    /\ Drop[6] = 24
    /\ DOMAIN Drop = 1..6

===========================================================================
