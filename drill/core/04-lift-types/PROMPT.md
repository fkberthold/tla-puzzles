# Lift

A lift serves a building with floors below ground as well as above. The
building has basements, a ground floor and floors up. The lift has a door, and
at any moment it's either moving or standing.

One run, one row per step:

| step | floor | door | moving |
|---|---|---|---|
| start | 0 | open | no |
| door closes | 0 | shut | no |
| starts | 0 | shut | yes |
| moves | -1 | shut | yes |
| moves | -2 | shut | yes |
| stops | -2 | shut | no |
| door opens | -2 | open | no |

The rules. The door opens only while standing. The lift starts only with the
door shut. It moves one floor at a time, within the building, and only while
moving. It can stop whenever it's moving. The door can close whenever it's open.

Write the specification from an empty file. Say what every variable can be.
State the safety rule: the door is shut whenever the lift is moving.

Check it with 2 basements and 3 floors up. A correct model finds 18 distinct
states.
