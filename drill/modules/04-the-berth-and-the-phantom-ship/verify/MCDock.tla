------------------------------ MODULE MCDock ------------------------------
\* The model wrapper. Everything TLC-specific lives here, so the dock
\* module itself never has to import TLC.
EXTENDS Dock, TLC

Perms == Permutations(Ships)

=============================================================================
