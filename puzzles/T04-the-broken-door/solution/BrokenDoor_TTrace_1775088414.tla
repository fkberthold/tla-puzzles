---- MODULE BrokenDoor_TTrace_1775088414 ----
EXTENDS Sequences, TLCExt, Toolbox, Naturals, TLC, BrokenDoor

_expression ==
    LET BrokenDoor_TEExpression == INSTANCE BrokenDoor_TEExpression
    IN BrokenDoor_TEExpression!expression
----

_trace ==
    LET BrokenDoor_TETrace == INSTANCE BrokenDoor_TETrace
    IN BrokenDoor_TETrace!trace
----

_inv ==
    ~(
        TLCGet("level") = Len(_TETrace)
        /\
        through = ({"Alice"})
        /\
        door = ("locked")
        /\
        pc = ([Alice |-> "Done", Bob |-> "check"])
    )
----

_init ==
    /\ through = _TETrace[1].through
    /\ door = _TETrace[1].door
    /\ pc = _TETrace[1].pc
----

_next ==
    /\ \E i,j \in DOMAIN _TETrace:
        /\ \/ /\ j = i + 1
              /\ i = TLCGet("level")
        /\ through  = _TETrace[i].through
        /\ through' = _TETrace[j].through
        /\ door  = _TETrace[i].door
        /\ door' = _TETrace[j].door
        /\ pc  = _TETrace[i].pc
        /\ pc' = _TETrace[j].pc

\* Uncomment the ASSUME below to write the states of the error trace
\* to the given file in Json format. Note that you can pass any tuple
\* to `JsonSerialize`. For example, a sub-sequence of _TETrace.
    \* ASSUME
    \*     LET J == INSTANCE Json
    \*         IN J!JsonSerialize("BrokenDoor_TTrace_1775088414.json", _TETrace)

=============================================================================

 Note that you can extract this module `BrokenDoor_TEExpression`
  to a dedicated file to reuse `expression` (the module in the 
  dedicated `BrokenDoor_TEExpression.tla` file takes precedence 
  over the module `BrokenDoor_TEExpression` below).

---- MODULE BrokenDoor_TEExpression ----
EXTENDS Sequences, TLCExt, Toolbox, Naturals, TLC, BrokenDoor

expression == 
    [
        \* To hide variables of the `BrokenDoor` spec from the error trace,
        \* remove the variables below.  The trace will be written in the order
        \* of the fields of this record.
        through |-> through
        ,door |-> door
        ,pc |-> pc
        
        \* Put additional constant-, state-, and action-level expressions here:
        \* ,_stateNumber |-> _TEPosition
        \* ,_throughUnchanged |-> through = through'
        
        \* Format the `through` variable as Json value.
        \* ,_throughJson |->
        \*     LET J == INSTANCE Json
        \*     IN J!ToJson(through)
        
        \* Lastly, you may build expressions over arbitrary sets of states by
        \* leveraging the _TETrace operator.  For example, this is how to
        \* count the number of times a spec variable changed up to the current
        \* state in the trace.
        \* ,_throughModCount |->
        \*     LET F[s \in DOMAIN _TETrace] ==
        \*         IF s = 1 THEN 0
        \*         ELSE IF _TETrace[s].through # _TETrace[s-1].through
        \*             THEN 1 + F[s-1] ELSE F[s-1]
        \*     IN F[_TEPosition - 1]
    ]

=============================================================================



Parsing and semantic processing can take forever if the trace below is long.
 In this case, it is advised to uncomment the module below to deserialize the
 trace from a generated binary file.

\*
\*---- MODULE BrokenDoor_TETrace ----
\*EXTENDS IOUtils, TLC, BrokenDoor
\*
\*trace == IODeserialize("BrokenDoor_TTrace_1775088414.bin", TRUE)
\*
\*=============================================================================
\*

---- MODULE BrokenDoor_TETrace ----
EXTENDS TLC, BrokenDoor

trace == 
    <<
    ([through |-> {},door |-> "unlocked",pc |-> [Alice |-> "check", Bob |-> "check"]]),
    ([through |-> {},door |-> "unlocked",pc |-> [Alice |-> "walk", Bob |-> "check"]]),
    ([through |-> {"Alice"},door |-> "locked",pc |-> [Alice |-> "Done", Bob |-> "check"]])
    >>
----


=============================================================================

---- CONFIG BrokenDoor_TTrace_1775088414 ----

INVARIANT
    _inv

CHECK_DEADLOCK
    \* CHECK_DEADLOCK off because of PROPERTY or INVARIANT above.
    FALSE

INIT
    _init

NEXT
    _next

CONSTANT
    _TETrace <- _trace

ALIAS
    _expression
=============================================================================
\* Generated on Wed Apr 01 17:06:55 PDT 2026