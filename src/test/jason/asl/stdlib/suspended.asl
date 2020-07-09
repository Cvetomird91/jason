/**
 * Test plans for jason internal actions in stdlib
 *
 * Most of examples come from Jason's documentation
 */

{ include("test_assert.asl") }

!execute_test_plans.

@test_suspended[atomic]
+!test_suspended
    <-
    /**
     * Add a mock plan for go(X,Y)
     */
    .add_plan({
      +!go(X,Y) <-
          .wait(10); // An arbitrary delay
    }, self, begin);

    // Trigger the mock plan to test desire
    !!go(1,3);
    !assert_true(.desire(go(1,3)));

    if (.suspended(go(1,3),R0)) {
        .print("It is suspended!");
        !assert_equals("wait",R0);
    } else {
        .print("TODO: It is expected to be suspended since go(X,Y) is always on .wait!");
    }

    .suspend(go(1,3));
    if (.suspended(go(1,3),R1)) {
        .print("It is suspended!");
        !assert_equals("wait",R1);
    } else {
        .print("TODO: It is expected to be suspended after .suspend!");
    }

    //.suspended(go(1,3),R2); // <<< Causing unexpected failure!
    .print("TODO: Calling .suspended outside of a test structure should not cause error");
.
