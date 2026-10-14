# Pancake pile

A cook has a pile of four pancakes of different sizes, 1 to 4. The only
move is to slide a spatula under one pancake and turn it and everything
above it over in one go. The pile is listed top pancake first.

| step | pile | what happened |
|---|---|---|
| 0 | 3, 1, 4, 2 | the pile was served up |
| 1 | 1, 3, 4, 2 | one flip |
| 2 | 4, 3, 1, 2 | one flip |
| 3 | 2, 1, 3, 4 | one flip |
| 4 | 1, 2, 3, 4 | one flip |

Write a module from an empty file that admits these flips, starting from
any pile. State the rule that the pancakes are always the same four, each
present once. Say how you built the flip.
