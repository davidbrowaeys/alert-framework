/**
* @author David Browaeys
* @date 12/12/2018
* @group Alert
* @description A test class created for BooleanEvaluate class
*/
@isTest
public class BooleanEvaluate_Test {
    @isTest static void test_Boolean_Evaluate_Expression() {
        List<Boolean> values = new List<Boolean>{true, true, false};
		Test.startTest();
        BooleanEvaluate boolEval = new BooleanEvaluate('1 AND ( 2 OR 3 )', values);
        boolEval.evaluate();
        system.assertEquals(true, boolEval.finalResult);
        Test.stopTest();
    }
}