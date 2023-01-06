/**
 * <b>Classe VFC18_ContractNew_Test</b>: unit test class for VFC18_ContractNew/VFP18_ContractNew
 * @author Eric Wartelle
 * @version 1.0
 */
@isTest
private class VFC18_ContractNew_Test {
    //Data initialisation
    @testSetup    
    public static void createTestsDatas() {
        //Create datas for the tests methods
        
        // Create PMO User
        User vUserPMO = AP05_TestDataFactory.createPMOUser();

        

    }        
        
    //Test Method
    @isTest 
    Public static void  newContractTest() {
        User vUserPMO = [SELECT Id FROM User WHERE  username=:AP05_TestDataFactory.USER_PMO_USERNAME];
        System.runAs(vUserPMO) {
            Test.startTest();                         

            VFC18_ContractNew controller = new VFC18_ContractNew(null);   
            
            controller.newContract();


            Test.stopTest();        
        }
    }

    @isTest 
    Public static void  newContractInTest() {

        id localAdminProfileId=[select id,name from profile where name =:'cTin - Local Admin'].id;

        User testUser = TestFactory.createUser('UsrAdmin',localAdminProfileId,true);
        testUser.cTin_LegalRepresentative__c = true;
        testUser.PAD_BypassTrigger__c = 'AP412;';
        testuser.PAD_BypassValidationRules__c=true;
        testUser.IsActive = true;
        testUser.cTin_UniverSign__c = true;
        insert testUser;

        System.runAs(testUser) {
            Test.startTest();                         
              
            
            VFC18_ContractNew controller = new VFC18_ContractNew(null);   
            
            controller.newContract();


            Test.stopTest();        
        }
    }
}