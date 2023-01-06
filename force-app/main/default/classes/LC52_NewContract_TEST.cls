@isTest
public class LC52_NewContract_TEST {
    static Map<String, RecordType> mapRT;
    static User vUserPMO;
    
    static{
        // Create PMO User
        vUserPMO = AP05_TestDataFactory.createPMOUser();
        mapRT = AP_Constant.getRecordTypes('Contract__c');
    }
        
    //Test Method
    @isTest 
    public static void  newLightContractTest(){
        System.runAs(vUserPMO) {
            Test.startTest();
            LC52_NewContract.getRecordType(mapRT.get(AP_Constant.RT_LIGHTCONTRACT).Id);
            Test.stopTest();        
        }
    }
        
    //Test Method
    @isTest 
    public static void  newContractEditTest(){
        System.runAs(vUserPMO) {
            Test.startTest();
            LC52_NewContract.getRecordType(mapRT.get(AP_Constant.RT_CONTRACT_EDIT_LIGHTNING).Id);
            Test.stopTest();        
        }
    }
        
    //Test Method
    @isTest 
    public static void  newAmendmentEditTest(){
        System.runAs(vUserPMO) {
            Test.startTest();
            LC52_NewContract.getRecordType(mapRT.get(AP_Constant.RT_AMENDMENT_EDIT_LIGHTNING).Id);
            Test.stopTest();        
        }
    }

    @isTest
    Public static void  newContractInTest(){

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
            LC52_NewContract.getRecordType(mapRT.get(AP_Constant.RT_CONTRACT_EDIT_LIGHTNING).Id);
            Test.stopTest();        
        }
    }

    @isTest
    Public static void  newContractFunctionalAdminTest(){

        id functionalAdmin=[select id,name from profile where name =:AP_Constant.functionalAdmin].id;

        User testUser = TestFactory.createUser('UsrAdmin',functionalAdmin,true);
        testUser.cTin_LegalRepresentative__c = true;
        testUser.PAD_BypassTrigger__c = 'AP412;';
        testuser.PAD_BypassValidationRules__c=true;
        testUser.IsActive = true;
        testUser.cTin_UniverSign__c = false;
        insert testUser;

        System.runAs(testUser) {
            Test.startTest();
            LC52_NewContract.getRecordType(mapRT.get(AP_Constant.RT_LIGHTCONTRACT).Id);
            Test.stopTest();        
        }
    }        
        
    //Test Method
    @isTest 
    public static void  newContractRTnullTest() {
        System.runAs(vUserPMO) {
            Test.startTest();
            LC52_NewContract.getRecordType(null);
            Test.stopTest();        
        }
    }
}