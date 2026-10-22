---- MODULE Charter ----
EXTENDS Integers
CONSTANTS Lo, Hi

\* The library guards its own parameters. This is the assumption that stops
\* guarding anything the moment somebody instantiates the module.
ASSUME Lo <= Hi

Width == Hi - Lo
========================
