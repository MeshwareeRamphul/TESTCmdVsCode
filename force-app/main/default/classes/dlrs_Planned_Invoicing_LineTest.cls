/**
 * Auto Generated and Deployed by the Declarative Lookup Rollup Summaries Tool package (dlrs)
 **/
@IsTest
private class dlrs_Planned_Invoicing_LineTest
{
    @IsTest
    private static void testTrigger()
    {
        // Force the dlrs_Planned_Invoicing_LineTrigger to be invoked, fails the test if org config or other Apex code prevents this.
        dlrs.RollupService.testHandler(new Planned_Invoicing_Line__c());
    }
}