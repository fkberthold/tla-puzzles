---- MODULE Ex5Sensor ----
EXTENDS Integers, TLC

\* Untranslated. Run `pcal Ex5Sensor.tla` before you run TLC.

(*--algorithm sensor
  variables
    temp \in 0..30,
    mode = "idle";

begin
  Sense:
    if temp > 40 then
      Trip:
        mode := "alarm";
    elsif temp > 20 then
      mode := "cool";
    else
      mode := "hold";
    end if;
  Settle:
    skip;
end algorithm; *)
====
