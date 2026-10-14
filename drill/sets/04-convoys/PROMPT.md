# Convoys

A haulage depot sends four trucks out to one destination. A truck leaves the
depot on its own and is then on the road.

Two groups of trucks on the road can join up and carry on as one group. A group
can never be bigger than three trucks. A group reaches the destination and
leaves the road together, whatever size it is.

Three rules the depot has to keep:

1. No truck is at the depot and on the road at once, and no truck is in two
   groups at once.
2. No group on the road has more than three trucks in it.
3. A group with no trucks in it isn't a group, so the road never holds one.

Write the specification from an empty file, with the three rules as three named
checks, and run it with four trucks and a group limit of three. A correct model
finds 150 distinct states.

Then write the joining step so that it adds the joined group and leaves the two
groups it came from where they were, run it again, and read what TLC reports.
