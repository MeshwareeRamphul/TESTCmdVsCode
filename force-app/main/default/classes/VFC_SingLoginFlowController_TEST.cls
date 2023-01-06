@isTest
public with sharing class VFC_SingLoginFlowController_TEST {
/*----------------------------------------------------------------------
-- - Name          : VFC_SingLoginFlowController_TEST
-- - Author        : Spoon
-- - Description   : Test Class for VFC_SingLoginFlowController
-- - History:

-- Date         Name  Version  Remarks
-- -----------  ----  -------  ---------------------------------------
-- 04-JAN-2022  MBE   1.0      Initial version 
-------------------------------------------------------------------------*/
    static User testUser;
    static User testUser2;
    
    static{
        testUser = TestFactory.createUser('UsrAdmin',TestFactory.getProfileAdminId(),true);
        insert testUser;
        
        testUser2 = TestFactory.createUser('UsrAdmin',TestFactory.getProfileAdminId(),true);
        testUser2.TermsOfService__c = true;
        testUser2.AgreedToPolicy__c = true;
        insert testUser2;
    }
    
    static testmethod void finishLoginFlowStartUrl_Test(){
        system.runAs(testUser){
            test.startTest();
            	VFC_SingLoginFlowController controller = new VFC_SingLoginFlowController();
            	System.assertNotEquals(null, controller.FinishLoginFlowStartUrl());     
            test.stopTest();             
        }
    }
    
    static testmethod void finishLoginFlowStartUrl_Test2(){
        system.runAs(testUser2){
            test.startTest();
            	VFC_SingLoginFlowController controller = new VFC_SingLoginFlowController();
            	System.assertNotEquals(null, controller.FinishLoginFlowStartUrl());                    
            test.stopTest();             
        }
    }
    
    static testmethod void FinishLoginFlowHome_Test(){
        system.runAs(testUser){
            test.startTest();
            	VFC_SingLoginFlowController controller = new VFC_SingLoginFlowController();            
            	System.assertNotEquals(null, controller.FinishLoginFlowHome());       
            test.stopTest();             
        }
    }
}