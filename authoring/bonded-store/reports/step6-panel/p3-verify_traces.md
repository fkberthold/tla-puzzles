# Trace Verification

## Pair 1: Duty paid iff released (direction 1)
Allowed: notEntered -> inStore -> released (duty paid)
Forbidden: notEntered -> inStore -> released (duty NOT paid)

Forbidden trace violates: **DutyPaidIffReleased**
- Final state: place[l1]="released", dutyPaid[l1]=FALSE
- Property requires: dutyPaid[l] <=> place[l]="released"
- This is FALSE <=> TRUE, which is FALSE

Allowed trace passes all properties ✓

## Pair 2: Way in is through inStore
Allowed: notEntered -> inStore
Forbidden: notEntered -> released (skips inStore)

Forbidden trace violates: **TheWayInAndTwoWaysOut**
- Transition from "notEntered" to "released" not allowed
- A2 requires: place="notEntered" implies place'="inStore" (only valid transition)
- This transition fails A2

Allowed trace passes all properties ✓

## Pair 3: Out stays out (no return)
Allowed: notEntered -> inStore -> movedOn
Forbidden: notEntered -> inStore -> notEntered (returns)

Forbidden trace violates: **TheWayInAndTwoWaysOut**
- Transition from "inStore" to "notEntered" not allowed
- A2 requires: place="inStore" implies place' ∈ {"released","movedOn"}
- This transition fails A2

Allowed trace passes all properties ✓

## Pair 4: Out stays out (place immutable after released)
Allowed: notEntered -> inStore -> released -> (l2 enters)
Forbidden: released -> movedOn

Forbidden trace violates: **OutStaysOut**
- State 3-4: place[l1]="released", place'[l1]="movedOn", dutyPaid'[l1]=TRUE
- A3 requires: when place ∈ {"released","movedOn"}, place' = place and dutyPaid' = dutyPaid
- This transition fails A3

Allowed trace passes all properties ✓

## Pair 5: Out stays out (duty immutable after movedOn)
Allowed: notEntered -> inStore -> movedOn
Forbidden: movedOn with duty paid

Forbidden trace violates: **OutStaysOut**
- State 3-4: place[l1]="movedOn", place'[l1]="movedOn", dutyPaid[l1]=FALSE, dutyPaid'[l1]=TRUE
- A3 requires: when place="movedOn", dutyPaid' = dutyPaid
- This transition fails A3

Allowed trace passes all properties ✓

## Summary
All 5 forbidden traces are correctly rejected by at least one property.
All 5 allowed traces pass all properties.
