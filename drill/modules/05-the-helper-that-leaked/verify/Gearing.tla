------------------------------ MODULE Gearing ------------------------------
\* The helper as first written. Both its import and its scratch constant
\* travel on to anything that extends it.
EXTENDS Naturals

INSTANCE Clockface

Teeth == 4

Turn(n) == Wrap(n + Teeth)

=============================================================================
