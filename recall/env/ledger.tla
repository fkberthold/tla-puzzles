\* ledger -- a tiny accounting domain. It exists so the same construct can be
\* asked over a second surface: a rep answered twice over one domain is a
\* sentence recalled, and the point of the rung is the fact.
\*
\* This is a FRAGMENT, not a module. No header, no EXTENDS, no trailing ====.
\*
\* Balance leaves bo at zero so a rep about an empty account is true and a
\* rep about every account being in credit is false. Entries repeats 5 so a
\* rep about listing amounts once each has something to collapse.
Accounts == {"ann", "bo"}
Kinds == {"deposit", "withdraw"}
Amounts == 1..4
Balance == [ann |-> 3, bo |-> 0]
Entries == <<2, 5, 1, 5>>
