---- MODULE ForkInTheRoad_TTrace_1775088200 ----
EXTENDS Sequences, TLCExt, Toolbox, ForkInTheRoad, Naturals, TLC

_expression ==
    LET ForkInTheRoad_TEExpression == INSTANCE ForkInTheRoad_TEExpression
    IN ForkInTheRoad_TEExpression!expression
----

_trace ==
    LET ForkInTheRoad_TETrace == INSTANCE ForkInTheRoad_TETrace
    IN ForkInTheRoad_TETrace!trace
----

_inv ==
    ~(
        TLCGet("level") = Len(_TETrace)
        /\
        pc = ([Hiker |-> "sit"])
        /\
        location = ("summit")
        /\
        seated = (FALSE)
    )
----

_init ==
    /\ location = _TETrace[1].location
    /\ seated = _TETrace[1].seated
    /\ pc = _TETrace[1].pc
----

_next ==
    /\ \E i,j \in DOMAIN _TETrace:
        /\ \/ /\ j = i + 1
              /\ i = TLCGet("level")
        /\ location  = _TETrace[i].location
        /\ location' = _TETrace[j].location
        /\ seated  = _TETrace[i].seated
        /\ seated' = _TETrace[j].seated
        /\ pc  = _TETrace[i].pc
        /\ pc' = _TETrace[j].pc

\* Uncomment the ASSUME below to write the states of the error trace
\* to the given file in Json format. Note that you can pass any tuple
\* to `JsonSerialize`. For example, a sub-sequence of _TETrace.
    \* ASSUME
    \*     LET J == INSTANCE Json
    \*         IN J!JsonSerialize("ForkInTheRoad_TTrace_1775088200.json", _TETrace)

=============================================================================

 Note that you can extract this module `ForkInTheRoad_TEExpression`
  to a dedicated file to reuse `expression` (the module in the 
  dedicated `ForkInTheRoad_TEExpression.tla` file takes precedence 
  over the module `ForkInTheRoad_TEExpression` below).

---- MODULE ForkInTheRoad_TEExpression ----
EXTENDS Sequences, TLCExt, Toolbox, ForkInTheRoad, Naturals, TLC

expression == 
    [
        \* To hide variables of the `ForkInTheRoad` spec from the error trace,
        \* remove the variables below.  The trace will be written in the order
        \* of the fields of this record.
        location |-> location
        ,seated |-> seated
        ,pc |-> pc
        
        \* Put additional constant-, state-, and action-level expressions here:
        \* ,_stateNumber |-> _TEPosition
        \* ,_locationUnchanged |-> location = location'
        
        \* Format the `location` variable as Json value.
        \* ,_locationJson |->
        \*     LET J == INSTANCE Json
        \*     IN J!ToJson(location)
        
        \* Lastly, you may build expressions over arbitrary sets of states by
        \* leveraging the _TETrace operator.  For example, this is how to
        \* count the number of times a spec variable changed up to the current
        \* state in the trace.
        \* ,_locationModCount |->
        \*     LET F[s \in DOMAIN _TETrace] ==
        \*         IF s = 1 THEN 0
        \*         ELSE IF _TETrace[s].location # _TETrace[s-1].location
        \*             THEN 1 + F[s-1] ELSE F[s-1]
        \*     IN F[_TEPosition - 1]
    ]

=============================================================================



Parsing and semantic processing can take forever if the trace below is long.
 In this case, it is advised to uncomment the module below to deserialize the
 trace from a generated binary file.

\*
\*---- MODULE ForkInTheRoad_TETrace ----
\*EXTENDS IOUtils, ForkInTheRoad, TLC
\*
\*trace == IODeserialize("ForkInTheRoad_TTrace_1775088200.bin", TRUE)
\*
\*=============================================================================
\*

---- MODULE ForkInTheRoad_TETrace ----
EXTENDS ForkInTheRoad, TLC

trace == 
    <<
    ([pc |-> [Hiker |-> "choose"],location |-> "fork",seated |-> FALSE]),
    ([pc |-> [Hiker |-> "sit"],location |-> "summit",seated |-> FALSE])
    >>
----


=============================================================================

---- CONFIG ForkInTheRoad_TTrace_1775088200 ----

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
\* Generated on Wed Apr 01 17:03:21 PDT 2026