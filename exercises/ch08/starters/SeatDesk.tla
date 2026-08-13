---- MODULE SeatDesk ----
\* Exercise 1 starter. Three holes, marked TODO.
\*
\* The file does not parse until all three are filled. That is on purpose. Fill
\* them, run `pcal` on this file, then run the model.
\*
\* A ticket desk holds `Capacity` seats. Each agent in `Agents` tries to sell
\* one seat. An agent looks first, and sells only if it saw a seat free.
EXTENDS Integers

Agents == {"ann", "bo"}
Capacity == 1

(*--algorithm seatdesk {
  variables seats = Capacity, sold = 0;

  define {
    \* TODO 1. The desk never oversells. Say it about `seats` alone.
    NeverOversold == TODO_1

    \* TODO 2. No seat is invented and none goes missing. One equation
    \* relating `seats`, `sold` and `Capacity`.
    BooksBalance == TODO_2
  }

  process (agent \in Agents)
    variables sawFree = FALSE;
  {
    Look:
      \* TODO 3. Three statements, all inside this one label.
      \* First record in `sawFree` whether any seat is free. Then, if it is,
      \* take one off `seats` and add one to `sold`.
      TODO_3;
  }
}
*)
====
