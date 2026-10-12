---- MODULE TurnstileRefused ----
\* A neighbour the tools refuse outright, kept apart from Turnstile so the
\* rejection cannot fail the runs over there.
EXTENDS Turnstile

N5 == [](count' = count + 1)
====
