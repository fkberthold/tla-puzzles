---- MODULE Gears ----
EXTENDS Naturals

---- MODULE Wheel ----
CONSTANT K
VARIABLE n
WType == n \in 0..(K - 1)
WInit == n = 0
WNext == n' = (n + 1) % K
WSpec == WInit /\ [][WNext]_n
====

CONSTANT Teeth
ASSUME Teeth \in 1..12 /\ 12 % Teeth = 0

VARIABLE n
vars == <<n>>

Big   == INSTANCE Wheel WITH K <- 12
Small == INSTANCE Wheel WITH K <- Teeth, n <- n % Teeth

TypeOK == Big!WType

Init == Big!WInit

Click == Big!WNext

Spin == n' = (n + Teeth) % 12

Next == Click \/ Spin

Spec == Init /\ [][Next]_vars

SmallTurns == Small!WSpec

SpinInvisible == [][Spin => UNCHANGED (n % Teeth)]_vars
====
