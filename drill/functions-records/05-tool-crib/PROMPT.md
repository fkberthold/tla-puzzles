# The tool crib

A workshop's tool crib holds four tools: a saw, a drill, a plane and a
rasp. Two workers borrow from it. A worker signs a tool out and later
returns it. The crib's rule: a worker holds at most two tools at a time.

At any moment the crib can say, for every tool, whether it is on the shelf
and if not, who has it. Nothing else is recorded.

| what has happened | possible? |
|---|---|
| all four tools are out, two with each worker | yes |
| the saw was returned by one worker and signed out again by the other | yes |
| one worker has the drill and the other has the drill | no |
| a worker holds the plane while the other three tools are on the shelf | yes |

Write the specification and the rule from an empty file. Check it with
deadlock checking on. A correct model finds 63 distinct states and reports
no error.

Then say what the set of tools that are out looks like in your model.
