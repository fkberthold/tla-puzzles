---- MODULE PipelineRefused ----
\* A neighbor the tools refuse outright, kept apart from Pipeline so the
\* rejection cannot fail the runs over there.
EXTENDS Pipeline

N3 == [](~Halted => Next)
====
