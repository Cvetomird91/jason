/**
 * Test manager provides general test configurations and facilities
 */

tests_performed(0).
tests_failed(0).
tests_passed(0).

/**
 * Configurations
 */
auto_create_fail_plan.  // create a -!test fail plan for each desire starting with "test"
shutdown_hook.          // enable to shutdown after finishing tests

/**
 * Startup operations
 */
!set_controller.          // starts test controller operations
!create_test_agents.      // create agents by .asl files in test/agt/

/**
 * execute plans that contains "test" in the label
 */
@execute_plans[atomic]
+!execute_test_plans:
    .relevant_plans({+!_},_,LL)
    <-
    !create_default_fail_plan;

    for (.member(P,LL)) {
        if (.substring("test",P,0)) {
            /**
             * Execute the @test plan
             */
            !!execute_test_plan(P);
        }
    }
.

/**
 * Add a default -!P fail plan to generate
 * assert failure for others non expected
 * errors
 */
@create_default_fail_plan[atomic]
+!create_default_fail_plan:
    auto_create_fail_plan
    <-
    .add_plan({
        -!P <-
            !force_failure("Failure captured by default fail plan -!P.");
    }, self, end);
.
+!create_default_fail_plan. // Do not create plans if it is disabled

@execute_plan[atomic]
+!execute_test_plan(P) :
    true
    <-
    .current_intention(I);
    I = intention(Id,IStack);
    .log(info,"TESTING ",Id," (main plan: ",P,")");
    !P;
.

/**
 * setup of the controller, including hook for shutdown
 */
 @set_controller[atomic]
+!set_controller :
    .my_name(test_manager)
    <-
    .log(info,"\n\n");
    .log(info,"Starting Jason unit tests...\n\n");

    .at("now +2 s", {+!shutdown_after_tests});
.
+!set_controller. // avoid plan not found for asl that includes controller

/**
 * enable to shutdown after finishing tests
 */
 @shutdown_after_fail[atomic]
 +!shutdown_after_tests :
     shutdown_hook &
     failed &
     tests_performed(N) &
     tests_failed(F) &
     tests_passed(P)
     <-
     .log(severe,"\n\n");
     .log(severe,"#",N," plans executed, #",P," passed and #",F," FAILED.");
     .log(severe,"End of Jason unit tests: FAILED!\n\n");
     .exit_error;
 .
@shutdown_after_success[atomic]
+!shutdown_after_tests :
    shutdown_hook &
    not intention(_) &
    tests_performed(N) &
    tests_failed(F) &
    tests_passed(P)
    <-
    .log(info,"\n\n");
    .log(info,"#",N," plans executed, #",P," PASSED and #",F," failed.");
    .log(info,"End of Jason unit tests: PASSED\n\n");
    .stopMAS;
.
+!shutdown_after_tests. // If auto shutdown is disabled

/**
 * create agents by files present in folder test/agt/
 */
@create_agents[atomic]
+!create_test_agents :
    .my_name(test_manager)
    <-
    .list_files("./src/test/jason/inc",".*.asl",IGNORE);
    .list_files("./src/test/jason/",".*.asl",FILES);
    for (.member(M,FILES)) {
      if (not .nth(N,IGNORE,M)) {
        for (.substring("/",M,R)) {
          -+lastSlash(R);
        }
        ?lastSlash(R0);
        .length(M,L);
        .substring(M,AGENT,R0+1,L-4);
        .log(fine,"LAUNCHING: ",AGENT," (",M,")");
        .create_agent(AGENT,M);
      }
    }
.
+!create_test_agents. // avoid plan not found for asl that includes controller

/**
 * Statistics for tests (passed/failed)
 */
@count_tests_passed[atomic]
+!count_tests(passed) :
    tests_performed(N) &
    tests_passed(P)
    <-
    -+tests_performed(N+1);
    -+tests_passed(P+1);
.
@count_tests_failed[atomic]
+!count_tests(failed) :
    tests_performed(N) &
    tests_failed(F)
    <-
    +failed;
    -+tests_performed(N+1);
    -+tests_failed(F+1);
.