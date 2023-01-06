@isTest
private class AP42_AddSignatoryToTeam_TEST
{
    static User use;
    static User relatedUser;
    static Contract__c testContract;
    static Account supplier;
    static Contact axaRep;
    static eSignature__c testEsignature;
    static eSignatory__c testEsignatory;
    static{

        use = TestFactory.createUser('UsrAdmin',TestFactory.getProfileAdminId(),true);
        insert use; 

        System.runAs(use){
            relatedUser = new User( Username = 'test1@test11.test1', 
                                    LastName = 'test', 
                                    Email ='test@test1.test', 
                                    Alias = 'test', 
                                    ProfileId = UserInfo.getProfileId(),
                                    TimeZoneSidKey = 'Europe/London', 
                                    LocaleSidKey = 'en_US', 
                                    EmailEncodingKey = 'UTF-8', 
                                    LanguageLocaleKey = 'en_US', 
                                    cTin_EntityLocalCode__c='CORE', 
                                    PAD_BypassValidationRules__c = true, 
                                    isActive = true, 
                                    cTin_LegalRepresentative__c = true );
            insert relatedUser;

            supplier = TestFactory.createSupplier('TestSupplier' , 'BillingCity', 'France');
            insert supplier;

            testContract = TestFactory.createContract(supplier.Id, 'TestContract', 'Draft');
            testContract.RecordTypeId = Schema.SObjectType.Contract__c.getRecordTypeInfosByName().get('Contract Draft').getRecordTypeId();
            //contract.cTin_RelatedUser__c = relatedUser.id;
            insert testContract;


            axaRep = TestFactory.createContact(supplier,'TestContactFn','TestContactLn');
            axaRep.cTin_RelatedUser__c = relatedUser.id;
            axaRep.RecordTypeId  = TestFactory.MapRecordType('Contact').get('cTin_AXA');

            insert axaRep;

            testEsignature = TestFactory.createEsignature(testContract , 'Testname', 'In Signature');
            testEsignature.RecordTypeId = Schema.SObjectType.eSignature__c.getRecordTypeInfosByName().get('cTin_Draft').getRecordTypeId();
            insert testEsignature;

            testEsignatory= TestFactory.createEsignatory(testContract, testEsignature, 'TestName' ,axaRep.id , 'Ready');
            
        }

        
    }
    @isTest
    static void TestAddSignatoryToTeam()
    {
        System.runAs(use){
            Test.startTest();
            testEsignatory.cTin_Role__c = 'AXA Representative';
            testEsignatory.MobileTxt__c= '+6758465876';
                insert testEsignatory;
            Test.stopTest();
        }
    }
}