@isTest
private without sharing class AP65_NotifExpiredEsig_TEST{
    /* 
--------------------------------------------------------------------------------------
-- - Name          : AP65_NotifExpiredEsig_TEST
-- - Author        : Spoon Consulting 
-- - Description   : Test class for AP65_NotifExpiredEsig
--
-- Maintenance History: 
--
-- Date         Name  Version  Remarks 
-- -----------  ----  -------  -------------------------------------------------------
-- 18-OCT-2021  MRA    1.0     Initial version
************************************************************************************
*/
  static User testUser;
    static List<Account> lstSuppliers;
    static List<Contact> lstContacts;
    static Contract__c contract;
    static ContentVersion testContentInsert;
    static Map<string,Id> mapAcctRecordTypes;
    static Map<string,Id> mapContactRecordTypes;
    static Map<string,Id> mapEsignatoryRecordTypes;
    static ESignature__c eSignature;
    static List<eSignatory__c> lstEsignatories;
    
    static{
        
        List<RecordType> lstRecordTypes = [SELECT Id,
                                                  developerName,
                                                  Name,
                                                  sObjectType
                                             FROM RecordType
                                            WHERE sObjectType = 'Contract__c'
                                              AND DeveloperName LIKE 'cTin_%'];

        //creating user with universign
        testUser = TestFactory.createUser('TestUniversign', UserInfo.getProfileId(), true);
        testUser.cTin_LegalRepresentative__c = true;
        testUser.PAD_BypassTrigger__c = 'AP412;AP36';
        testUser.IsActive = true;
        testUser.cTin_UniverSign__c = true;
        testUser.Bypass_FieldFilter__c=true;
        testUser.PAD_BypassValidationRules__c = true;
        testUser.cTin_EntityLocalCode__c = 'ACH';
        insert testUser;
        
        system.runAs(testUser){

            //record types
            mapAcctRecordTypes = TestFactory.MapRecordType('Account');
            mapContactRecordTypes = TestFactory.MapRecordType('Contact');
            mapEsignatoryRecordTypes = TestFactory.MapRecordType('eSignatory__c');

            //creating accounts
            lstSuppliers = new List<Account>{TestFactory.createSupplier('Test Supplier1', 'Florange', 'France'),
                                             TestFactory.createSupplier('Test Supplier2', 'Florange', 'France'),
                                             TestFactory.createSupplier('Test Supplier3', 'Florange', 'France')};
            lstSuppliers[1].RecordTypeId = mapAcctRecordTypes.get('cTin_Supplier');
            lstSuppliers[2].RecordTypeId = mapAcctRecordTypes.get('cTin_AXA');
            insert lstSuppliers;

            //creating contacts
            lstContacts = new List<Contact>{TestFactory.createContact(lstSuppliers[1],'James','Brown'),
                                            TestFactory.createContact(lstSuppliers[2],'Kim','Brown')};

            lstContacts[0].RecordTypeId = mapContactRecordTypes.get('cTin_Supplier');
            lstContacts[0].cTin_RelatedUser__c = testUser.Id;
            lstContacts[0].cTin_LegalRepresentative__c = true;
            lstContacts[0].MobilePhone = '+2126655565645';
            lstContacts[0].cTin_Active__c = true;
            lstContacts[0].email ='james.brown@gmail.com'; 

            lstContacts[1].RecordTypeId = mapContactRecordTypes.get('cTin_AXA');
            lstContacts[1].cTin_RelatedUser__c = testUser.Id;
            lstContacts[1].cTin_LegalRepresentative__c = true;
            lstContacts[1].MobilePhone = '+212667849903';
            lstContacts[1].email ='kim.brown@gmail.com'; 
            lstContacts[1].cTin_Active__c = true;

            insert lstContacts;
          
            //creating contract
            contract = TestFactory.createcTinContracts('Test Contract1', lstSuppliers[0].Id, lstRecordTypes[0].id);
            contract.cTin_Reminder__c='N/A';
            contract.cTin_SendMonthlyReminder__c =false;
            contract.cTin_MonthlyReminderDate__c =system.today();
            insert contract;   
            contract.cTin_eSignature_automate__c=true;
            contract.LinkToDocument__c='https://wwww.google.com';
            update contract;

            //create content version
            testContentInsert = TestFactory.createContentVersion('Google.com', 'test.pdf', 'test', false);
            testContentInsert.sign_able__c = true;
            insert testContentInsert;

            //create esignature
            eSignature = TestFactory.createEsignature(contract, 'Test Esignature', AP_Constant.eSignatureCreatedStatus);
            insert eSignature;

            //creating esignatory  
            lstEsignatories = new List<eSignatory__c>{TestFactory.createEsignatory(contract, eSignature, 'James', lstContacts[1].id, AP_Constant.esignatoryStatusNotStarted),
                                                      TestFactory.createEsignatory(contract, eSignature, 'James', lstContacts[0].id, AP_Constant.esignatoryStatusNotStarted)};

            lstEsignatories[0].RecordTypeId = mapEsignatoryRecordTypes.get('cTin_AXA_Representative');
            lstEsignatories[0].EmailTxt__c = lstContacts[1].Email;
            lstEsignatories[0].Status__c = 'Ready';
            lstEsignatories[0].Contact__c = lstContacts[1].Id;
            lstEsignatories[0].cTin_Role__c = 'AXA Representative';
            lstEsignatories[0].MobileTxt__c = lstContacts[1].Phone;
            lstEsignatories[0].Order__c = 2;
            //lstEsignatories[0].cTin_SupplierAccount__c = lstSuppliers[2].Id; 
            lstEsignatories[0].signURL__c = 'https://sign.test.universign.eu/en/signature/?id=a85da5d0-be9d-31e4-aa39-848a9596e374';

            lstEsignatories[1].RecordTypeId = mapEsignatoryRecordTypes.get('cTin_Supplier_Representative');
            lstEsignatories[1].EmailTxt__c = lstContacts[0].Email;
            lstEsignatories[1].MobileTxt__c = lstContacts[0].Phone;
            lstEsignatories[1].Status__c = 'Ready';
            lstEsignatories[1].cTin_Role__c = 'Supplier Representative';
            lstEsignatories[1].Order__c = 1;
            lstEsignatories[1].signURL__c = 'https://sign.test.universign.eu/en/signature/?id=a85da5d0-be9d-31e4-aa39-848a9596e374';
            lstEsignatories[1].Contact__c = lstContacts[0].Id;
            //lstEsignatories[1].cTin_SupplierAccount__c = lstSuppliers[1].Id;

            insert lstEsignatories;
   
        }
    }

    /*test scenario : contract.status!= in signature*/
    static testmethod void automateEsignErrUserAndDocTest(){
        system.runAs(testUser){
           list<esignature__c> esignlst=[select id from esignature__c where id =:esignature.id];
           
           esignlst[0].status__c='Expired';
           set<id> setCtinExpiredEsign=new set<id>();
           setCtinExpiredEsign.add(esignlst[0].id);
           
            Test.startTest();      
                try{
                    update esignature;
                     AP65_NotifExpiredEsig.notifyCtrOwners(setCtinExpiredEsign);
                }
                catch(Exception e){
                   // errorMsg = e.getMessage();
                }
            Test.stopTest();

            
        }
    }
}