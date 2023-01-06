/**
 * Created by Urvashi on 16/04/2020.
 */

@IsTest
private class DeployedComponentTriggerHandler_Test {
    @IsTest
    static void createCompnentField() {
        test.startTest();
            Support_Ticket__c SupTicket = new Support_Ticket__c();
            insert SupTicket;

            DeployedComponent__c depCom = new DeployedComponent__c();
            depCom.case__c = SupTicket.Id;
            depCom.ComponentType__c = 'CustomField';
            depCom.IsNewField__c = true;
            depCom.ComponentDevelopperName__c = 'testField__c';

            insert depCom;

            List<DeployedComponent__c> lstDepComCreated = [
                    SELECT ComponentType__c, NeedManualDeploiement__c, ExecuteManualTask__c
                    FROM DeployedComponent__c
                    WHERE ComponentType__c IN ('Translation', 'Field Level Security')
            ];
            system.assertEquals(2, lstDepComCreated.size());
        test.stopTest();
    }
}