---- MODULE LightSwitch_TTrace_1775086647 ----
EXTENDS LightSwitch, Sequences, TLCExt, Toolbox, Naturals, TLC

_expression ==
    LET LightSwitch_TEExpression == INSTANCE LightSwitch_TEExpression
    IN LightSwitch_TEExpression!expression
----

_trace ==
    LET LightSwitch_TETrace == INSTANCE LightSwitch_TETrace
    IN LightSwitch_TETrace!trace
----

_inv ==
    ~(
        TLCGet("level") = Len(_TETrace)
        /\
        pc = ([Person |-> "toggle"])
        /\
        light = ("on")
        /\
        count = (1)
    )
----

_init ==
    /\ light = _TETrace[1].light
    /\ pc = _TETrace[1].pc
    /\ count = _TETrace[1].count
----

_next ==
    /\ \E i,j \in DOMAIN _TETrace:
        /\ \/ /\ j = i + 1
              /\ i = TLCGet("level")
        /\ light  = _TETrace[i].light
        /\ light' = _TETrace[j].light
        /\ pc  = _TETrace[i].pc
        /\ pc' = _TETrace[j].pc
        /\ count  = _TETrace[i].count
        /\ count' = _TETrace[j].count

\* Uncomment the ASSUME below to write the states of the error trace
\* to the given file in Json format. Note that you can pass any tuple
\* to `JsonSerialize`. For example, a sub-sequence of _TETrace.
    \* ASSUME
    \*     LET J == INSTANCE Json
    \*         IN J!JsonSerialize("LightSwitch_TTrace_1775086647.json", _TETrace)

=============================================================================

 Note that you can extract this module `LightSwitch_TEExpression`
  to a dedicated file to reuse `expression` (the module in the 
  dedicated `LightSwitch_TEExpression.tla` file takes precedence 
  over the module `LightSwitch_TEExpression` below).

---- MODULE LightSwitch_TEExpression ----
EXTENDS LightSwitch, Sequences, TLCExt, Toolbox, Naturals, TLC

expression == 
    [
        \* To hide variables of the `LightSwitch` spec from the error trace,
        \* remove the variables below.  The trace will be written in the order
        \* of the fields of this record.
        light |-> light
        ,pc |-> pc
        ,count |-> count
        
        \* Put additional constant-, state-, and action-level expressions here:
        \* ,_stateNumber |-> _TEPosition
        \* ,_lightUnchanged |-> light = light'
        
        \* Format the `light` variable as Json value.
        \* ,_lightJson |->
        \*     LET J == INSTANCE Json
        \*     IN J!ToJson(light)
        
        \* Lastly, you may build expressions over arbitrary sets of states by
        \* leveraging the _TETrace operator.  For example, this is how to
        \* count the number of times a spec variable changed up to the current
        \* state in the trace.
        \* ,_lightModCount |->
        \*     LET F[s \in DOMAIN _TETrace] ==
        \*         IF s = 1 THEN 0
        \*         ELSE IF _TETrace[s].light # _TETrace[s-1].light
        \*             THEN 1 + F[s-1] ELSE F[s-1]
        \*     IN F[_TEPosition - 1]
    ]

=============================================================================



Parsing and semantic processing can take forever if the trace below is long.
 In this case, it is advised to uncomment the module below to deserialize the
 trace from a generated binary file.

\*
\*---- MODULE LightSwitch_TETrace ----
\*EXTENDS LightSwitch, IOUtils, TLC
\*
\*trace == IODeserialize("LightSwitch_TTrace_1775086647.bin", TRUE)
\*
\*=============================================================================
\*

---- MODULE LightSwitch_TETrace ----
EXTENDS LightSwitch, TLC

trace == 
    <<
    ([pc |-> [Person |-> "toggle"],light |-> "off",count |-> 0]),
    ([pc |-> [Person |-> "toggle"],light |-> "on",count |-> 1])
    >>
----


=============================================================================

---- CONFIG LightSwitch_TTrace_1775086647 ----

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
\* Generated on Wed Apr 01 16:37:28 PDT 2026