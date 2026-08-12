---- MODULE DomainProbe ----
\* Exercise 2 starter. Read it, predict the verdict, then run it.
\*
\* This is a scratch file. It has no variables and no behavior spec, the same
\* setup chapter 1 uses for trying an expression out. TLC checks every ASSUME
\* in the module before it looks for anything to run, so these six lines are
\* the whole model.
\*
\* Write your prediction for each claim into LOG.md BEFORE you run TLC.
EXTENDS Integers, Sequences, FiniteSets, TLC

Claim1 == DOMAIN <<"red", "green", "blue">> = {1, 2, 3}

Claim2 == DOMAIN [hue |-> 3, sat |-> 7] = {"hue", "sat"}

Claim3 == [i \in 1..3 |-> i * i] = <<1, 4, 9>>

Claim4 == Len([i \in 1..3 |-> i * i]) = 3

Claim5 == ("hue" :> 3 @@ "hue" :> 9)["hue"] = 3

Claim6 == Cardinality(DOMAIN [i \in 1..3, j \in 1..2 |-> i]) = 6

ASSUME Claim1
ASSUME Claim2
ASSUME Claim3
ASSUME Claim4
ASSUME Claim5
ASSUME Claim6
====
