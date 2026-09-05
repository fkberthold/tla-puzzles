---------------------------- MODULE P06 ----------------------------
EXTENDS AssayOffice

MarksOneSided ==
    \A w \in Wares :
        Observe.marked[w] => Observe.finding[w] = "atStandard"

=============================================================================
