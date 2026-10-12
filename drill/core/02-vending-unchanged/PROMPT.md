# Vending machine

A vending machine sells one kind of can at a fixed price. It holds a small
stock and counts the cans sold since it was last filled. Nobody refills it.

Coins go in one or more at a time. A customer can insert any number of coins in
one go, as long as the credit stays within the machine's limit. A can is vended
when the credit covers the price and a can is in stock: the credit drops by the
price, the stock drops by one, and the sold count goes up by one. Pressing
refund returns all the credit.

Write the specification from an empty file. Say what every variable can be.
State the rule the operator cares about: every can is either still in the
machine or has been sold.

Check it with a price of 2, a credit limit of 3 and a stock of 2. A correct
model finds 12 distinct states and reports no error.
