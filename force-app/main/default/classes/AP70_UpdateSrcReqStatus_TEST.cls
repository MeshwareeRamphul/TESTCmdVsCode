@isTest
public class AP70_UpdateSrcReqStatus_TEST {

    @testSetup static void setup() {
        
    }

    @isTest static void updateTest() {
        Sourcing_Request__c srcReq = new Sourcing_Request__c(Risk_assessment_requirements__c='Applicable',CRAQ_number__c='');
        Sourcing_Request__c srcReq2 = new Sourcing_Request__c();
        insert new List<Sourcing_Request__c>{srcReq,srcReq2};

        Sourcing_Request__c srcReq3 = [select id,name from Sourcing_Request__c where id=:srcReq.id];
        system.debug('srcReq3 '+srcReq3);
        Sourcing_Event__c srcEvt = new Sourcing_Event__c(Name='srcEvt',Sourcing_Request__c=srcReq3.id);  
        
        contract__c contract = new contract__c(name='contract',cTin_SignatureDate__c=date.newInstance(2022, 05, 05),Global_Amount__c=25.2,Sourcing_Request__c=srcReq2.id);
        insert contract; 
        
        Test.startTest();
            insert srcEvt;
            system.debug('srcReq3 '+srcReq);
        Test.stopTest();  
    }
}