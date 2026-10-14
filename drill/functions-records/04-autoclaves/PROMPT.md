# The autoclaves

A lab has three autoclaves. Each has a door, open or shut, and a pressure
gauge reading 0, 1 or 2. Heating raises the pressure by one and venting
lowers it by one. The door can only be opened at pressure 0, and only a
shut autoclave can be heated. The lab's compressor can hold pressure in at
most two autoclaves at once, so a third is never heated while two are
above zero.

Two rules the safety officer checks: a door is never open while that
autoclave's pressure is above 0, and no more than two autoclaves are above
0 at any moment.

All three start open at pressure 0.

Write the specification and both rules from an empty file. Check it with
deadlock checking on. A correct model finds 56 distinct states and reports
no error.

Then say, in one sentence each, what the step that raises one autoclave's
pressure has to say about that autoclave's door, and what it has to say
about the other two autoclaves.
