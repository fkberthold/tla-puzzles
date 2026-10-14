# Any healthy upstream

A load balancer sits in front of three upstream servers. When it starts it
reads the health list once. Any of the three may be on it, at least one is,
and the list doesn't change while the balancer runs.

Requests arrive one at a time, each carrying an id from a pool of three. A
request that has arrived waits in the balancer. The balancer forwards a
waiting request to any upstream on the health list. Which one is not
specified. A forwarded request is in flight on that upstream until it
completes, and its id then goes back to the pool and can arrive again.

Two rules the balancer must keep:

1. A request is never in flight on an upstream that isn't on the health list.
2. No id is in two places at once: waiting and in flight, or in flight twice.

Someone on the team has read this description and says: "With the balancer
as described, every request in flight at any moment is on the same upstream."

Write the specification from an empty file, with the two rules and the claim
as three named checks, and run it with three upstreams and a pool of three
ids. The answer says what TLC should report for the claim. A correct model
finds 398 distinct states.
