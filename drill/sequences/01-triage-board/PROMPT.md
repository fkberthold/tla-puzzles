# Triage board

A walk-in clinic has one doctor and a waiting board with room for three
names. Each patient who arrives is written at the bottom of the board with
a severity from 1 to 4, where 1 is the most urgent. The doctor takes one
patient at a time, and the severity of each patient she takes is added to
the end of the day's treated list.

The table shows one morning. Each row is the board and the treated list
after one step, oldest entry on the left.

| step | board | treated | what happened |
|---|---|---|---|
| 0 | empty | empty | the clinic opened |
| 1 | 3 | empty | a patient arrived |
| 2 | 3, 1 | empty | a patient arrived |
| 3 | 3, 1, 4 | empty | a patient arrived |
| 4 | 3, 4 | 1 | the doctor took a patient |
| 5 | 3, 4, 2 | 1 | a patient arrived |
| 6 | 3, 4 | 1, 2 | the doctor took a patient |
| 7 | 4 | 1, 2, 3 | the doctor took a patient |
| 8 | 4, 4 | 1, 2, 3 | a patient arrived |
| 9 | 4 | 1, 2, 3, 4 | the doctor took a patient |

Write a module from an empty file that admits this morning. Then state,
as something TLC can check, the rule the table shows the doctor keeping
when she picks a patient. Say how you stopped the treated list growing
without bound.
