---- MODULE ParcelDesk ----
\* Exercise 1 reference, learntla core ch.6 "Structured Data".
\*
\* A parcel is a struct. `ParcelType` is the set of all well formed parcels,
\* and it is the whole type invariant. `KeysAreFixed` is the second half of the
\* lesson: a struct's key set is part of its value, so a misspelled key makes a
\* different struct rather than a struct with a bad field.
EXTENDS Integers

CONSTANT Depots
ASSUME Depots # {}

MaxKilos == 4

ParcelType == [kilos: 1..MaxKilos, depot: Depots, express: BOOLEAN]

(*--algorithm parceldesk {
variables
  parcel \in ParcelType;

define {
  TypeOK == parcel \in ParcelType

  KeysAreFixed == DOMAIN parcel = {"kilos", "depot", "express"}
}

{
  Weigh:
    if (parcel.kilos < MaxKilos) {
      parcel.kilos := parcel.kilos + 1;
    };
  Upgrade:
    parcel := [kilos |-> parcel.kilos, depot |-> parcel.depot, express |-> TRUE];
}
}
*)
\* BEGIN TRANSLATION (chksum(pcal) = "a8d2638e" /\ chksum(tla) = "e1db9a53")
VARIABLES pc, parcel

(* define statement *)
TypeOK == parcel \in ParcelType

KeysAreFixed == DOMAIN parcel = {"kilos", "depot", "express"}


vars == << pc, parcel >>

Init == (* Global variables *)
        /\ parcel \in ParcelType
        /\ pc = "Weigh"

Weigh == /\ pc = "Weigh"
         /\ IF parcel.kilos < MaxKilos
               THEN /\ parcel' = [parcel EXCEPT !.kilos = parcel.kilos + 1]
               ELSE /\ TRUE
                    /\ UNCHANGED parcel
         /\ pc' = "Upgrade"

Upgrade == /\ pc = "Upgrade"
           /\ parcel' = [kilos |-> parcel.kilos, depot |-> parcel.depot, express |-> TRUE]
           /\ pc' = "Done"

(* Allow infinite stuttering to prevent deadlock on termination. *)
Terminating == pc = "Done" /\ UNCHANGED vars

Next == Weigh \/ Upgrade
           \/ Terminating

Spec == Init /\ [][Next]_vars

Termination == <>(pc = "Done")

\* END TRANSLATION 
====
