---------------------------- MODULE GearingLocal ----------------------------
\* The helper with its private parts marked private. Only Turn travels.
EXTENDS Naturals

LOCAL INSTANCE Clockface

LOCAL Teeth == 4

Turn(n) == Wrap(n + Teeth)

=============================================================================
