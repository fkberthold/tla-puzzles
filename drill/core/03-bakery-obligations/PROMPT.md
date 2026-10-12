# Bakery

A bakery has one oven, one tray, one shelf and one till.

The oven is cold or hot. It can be lit when cold. It can be doused when hot,
but only with the tray empty.

The tray is empty, baking or done. A batch can be loaded only when the oven is
hot and the tray is empty. A loaded batch bakes until it's done. A done batch is
unloaded onto the shelf, but only if the shelf has room for the whole batch, and
the tray is empty again.

The shelf holds loaves, up to its capacity.

A loaf sells for a fixed price. One loaf leaves the shelf, the day's count goes
up by one, and the price goes into the till. The bakery sells a fixed number of
loaves a day. When that many have sold, the till is banked: it goes to zero, and
so does the day's count.

The owner has three worries:

1. Nothing is ever in a cold oven.
2. The shelf never holds more than its capacity.
3. The till holds exactly the price of every loaf sold today.

Write the specification from an empty file, with whatever TLC needs to check all
three worries, and the model configuration that runs them. Say what every
variable can be. Check it with a batch of 2, a shelf of 3, a price of 5 and a
day of 4 loaves. A correct model finds 40 distinct states.

Then break it. Take out the check that the oven is hot before loading, run it
again, and read what TLC reports. The answer says what it should report.
