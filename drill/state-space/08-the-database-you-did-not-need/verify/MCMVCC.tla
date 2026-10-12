------------------------------ MODULE MCMVCC ------------------------------
EXTENDS MVCC

CONSTANT MaxTs

ASSUME MaxTs \in Nat

\* The knob a stalled run reaches for. Named in a .cfg as CONSTRAINT TsBound.
\* Every commit and every begin moves ts, so the anomaly with N doctors sits
\* at ts = 2N. A bound below 2N - 1 never generates it.
TsBound == ts <= MaxTs

===========================================================================
