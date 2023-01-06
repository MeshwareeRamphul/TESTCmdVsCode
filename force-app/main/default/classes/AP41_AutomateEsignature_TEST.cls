@isTest
private class AP41_AutomateEsignature_TEST {
/* 
--------------------------------------------------------------------------------------
-- - Name          : AP41_AutomateEsignature_TEST
-- - Author        : Spoon Consulting 
-- - Description   : Test class for AP41_AutomateEsignature
--
-- Maintenance History: 
--
-- Date         Name  Version  Remarks 
-- -----------  ----  -------  -------------------------------------------------------
-- 06-NOV-2017  HVA/MRA   1.0     Initial version
-- 11-MAR-2020  SGO       1.1     Implement sign able
*************************************************************************************/

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
            List<cTin_ContractForm__c> lstContractForm =[SELECT cTin_Contract__c,
                                                                cTin_FinalApprovalStatus__c
                                                           FROM cTin_ContractForm__c
                                                          WHERE cTin_Contract__c = :contract.id];

            lstContractForm[0].cTin_FinalApprovalStatus__c = system.label.cTin_ApprovedStatus;

            string errorMsg = '';
            testUser.cTin_UniverSign__c = false;
            update testUser;

            Test.startTest();      
                try{
                    update lstContractForm;
                }
                catch(Exception e){
                    errorMsg = e.getMessage();
                }
            Test.stopTest();

            system.assert(true, errorMsg.contains(system.label.SameContactEmail));
            system.assert(true, errorMsg.contains(system.label.ErrorMessageNoActiveMail));
            system.assert(true, errorMsg.contains(system.label.ErrorMessageEsignNoDocs));
            system.assert(true, errorMsg.contains(system.label.MessageBlockCreation2));
        }
    }

    //test scenario: final document url != public URL of content distribution
    static testmethod void automateEsignCorrectStatusTest(){
        system.runAs(testUser){
         
            List<cTin_ContractForm__c> lstContractForm =[SELECT cTin_Contract__c,
                                                                cTin_FinalApprovalStatus__c
                                                           FROM cTin_ContractForm__c
                                                          WHERE cTin_Contract__c = :contract.id];

            lstContractForm[0].cTin_FinalApprovalStatus__c = system.label.cTin_ApprovedStatus;

            string errorMsg = '';

            ContentVersion testContent = [SELECT ContentDocumentId
                                            FROM ContentVersion
                                           WHERE Id = :testContentInsert.Id];    

            ContentWorkspaceDoc newWorkspaceDoc = new ContentWorkspaceDoc(ContentDocumentId = testContent.ContentDocumentId); 

            try{
                insert newWorkspaceDoc;
            }
            catch(Exception e){
                System.debug('Error ==> ' + e.getMessage());
            }
                    
            update testContentInsert;

            Test.startTest();      
                try{
                    update lstContractForm;
                }
                catch(Exception e){
                    errorMsg = e.getMessage();
                }
            Test.stopTest();
    
        }
    } 

    //supplier representative=null , axa representative = null
    static testmethod void automateEsignNoRepTest(){

        system.runAs(testUser){
          Test.startTest(); 
            List<cTin_ContractForm__c> lstContractForm =[SELECT cTin_Contract__c,
                                                                cTin_FinalApprovalStatus__c
                                                           FROM cTin_ContractForm__c
                                                          WHERE cTin_Contract__c = :contract.id];

            lstContractForm[0].cTin_FinalApprovalStatus__c = system.label.cTin_ApprovedStatus;

            string errorMsg = '';

            ContentVersion testContent = [SELECT ContentDocumentId
                                            FROM ContentVersion
                                           WHERE Id = :testContentInsert.Id];    

            ContentWorkspaceDoc newWorkspaceDoc = new ContentWorkspaceDoc(ContentDocumentId = testContent.ContentDocumentId); 

            try{
                insert newWorkspaceDoc;
            }
            catch(Exception e){
                System.debug('Error ==> ' + e.getMessage());
            }

            contract.cTin_SupplierSignatoryRepresentative__c = lstContacts[0].Id;
            contract.cTin_AXASignatoryRepresentative__c = lstContacts[1].Id;
            update contract;

                
                try{
                    update lstContractForm;
                }
                catch(Exception e){
                    errorMsg = e.getMessage();
                }
            Test.stopTest();
        }
    }

    /*test scenario : contract.status!= in signature*/
    static testmethod void automateEsignErrStatusTest(){
    
        system.runAs(testUser){
         
            List<cTin_ContractForm__c> lstContractForm =[SELECT cTin_Contract__c,
                                                                cTin_FinalApprovalStatus__c
                                                           FROM cTin_ContractForm__c
                                                          WHERE cTin_Contract__c = :contract.id];

            lstContractForm[0].cTin_FinalApprovalStatus__c = system.label.cTin_ApprovedStatus;

            string errorMsg = '';
            
            contract.status__c = 'In Progess';
            contract.LinkToDocument__c= '';
            update contract;

            Test.startTest();      
            try{
                update lstContractForm;
            }
            catch(Exception e){
                errorMsg = e.getMessage();
            }
            Test.stopTest();

            system.assert(true, errorMsg.contains(system.label.MessageBlockCreation));
         
        }
    }

    static testmethod void automateEsignExistsTest(){

        system.runAs(testUser){
            ContentVersion content=TestFactory.createContentVersion('contractEFG', 'contract.pdf', 'Content',false);
            insert content;

            ContentDistribution cd=TestFactory.createContentDistribution(content.id, content.title, contract.Id);          
            insert cd;

            ContentDistribution cdistr = [Select id,PreferencesNotifyOnVisit, DistributionPublicUrl, contentDocumentID, ContentVersionId 
                                             from ContentDistribution 
                                             where id=: cd.Id ];  
            contract.LinkToDocument__c= cdistr.DistributionPublicUrl;
            //contract.status__c='In Approval';
            //update contract;
            
           
            
            List<cTin_ContractForm__c> lstContractForm =[SELECT cTin_Contract__c,
                                                          cTin_FinalApprovalStatus__c
                                                           FROM cTin_ContractForm__c
                                                          WHERE cTin_Contract__c = :contract.id];

            lstContractForm[0].cTin_FinalApprovalStatus__c = system.label.cTin_ApprovedStatus;

            string errorMsg = '';
          
            Test.startTest();      
            try{
                update lstContractForm;
            }
            catch(Exception e){
                errorMsg = e.getMessage();
            }
            Test.stopTest();

            system.assert(true, errorMsg.contains(system.label.MessageBlockCreation));
             
            
        }
    }
    
     static testmethod void blockUpdtInApprovalTest(){
        string errMsg='';
        system.runAs(testUser){
            
           
            test.startTest();
            try{
                contract.status__c='In Approval';
                update contract;
            }
            catch(Exception e){
                errMsg=e.getMessage();
            }   
            test.stopTest();
        }   
            
       // system.assert(true, errMsg.contains(system.label.cTin_ErrorMessageInApprovalStatus));
             
            
        
    }
}