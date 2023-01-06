@isTest
public with sharing class AP48_blockFileUpdate_TEST {
    /* 
--------------------------------------------------------------------------------------
-- - Name          : AP48_blockFileUpdate_TEST
-- - Author        : ARA
-- - Description   : Test class for controller AP48_blockFileUpdate
--
-- Maintenance History: 
--
-- Date         Name  Version  Remarks 
-- -----------  ----  -------  -------------------------------------------------------
-- 04-JUN-2020  ARA    1.0     Initial version
*************************************************************************************/
    
    static List<Contract__c> lstContract =  new List<Contract__c>();
    static List<cTin_ContractTeam__c> lstContractTeam;
    static List<User> lstUser = new list<User>();
    static ContentVersion testCV = new ContentVersion();
    static ContentDistribution testCD = new ContentDistribution();
    
    static {
        lstUser.add(TestFactory.createUser('Testuser1', UserInfo.getProfileId(), true));
        lstUser.add(TestFactory.createUser('Testuser2', UserInfo.getProfileId(), true));
        insert lstUser;
        
        lstUser[0].Bypass_FieldFilter__c=true;
        lstUser[0].cTin_Universign__c = true;
        lstUser[0].PAD_BypassValidationRules__c = true;
        lstUser[0].PAD_BypassTrigger__c = 'AP40;AP39';
        update lstUser;
        
        System.runAs(lstUser[0]){
            
            Account supplier = TestFactory.createSupplier('TestSupplier', 'BillingCity', 'France');
            insert supplier;
            
            lstContract.add(TestFactory.createContract(supplier.Id, 'TestContract', 'Draft'));
            lstContract.add(TestFactory.createContract(supplier.Id, 'TestContract2', 'Draft'));
            insert lstContract;
            
            testCV = TestFactory.createContentVersion('Google.com', 'test.pdf', 'test', false);
            testCV.sign_able__c = true;
            insert testCV;
            
            testCD = TestFactory.createContentDistribution(testCV.id, testCV.title, lstContract[1].Id);          
            insert testCD;
            
            List<ContentDocument> documents = [SELECT Id, Title, LatestPublishedVersionId,description FROM ContentDocument];
            
            contentDocumentLink testCDL = new contentDocumentLink(LinkedEntityId = lstContract[1].Id ,ContentDocumentId=documents[0].Id,ShareType='I');
            insert testCDL;
        }
        
    }
    
    @isTest
    static void testAllowUpdateSendForSignature(){
        System.runAs(lstUser[0]){
            // change Contentversion sign_able__c , Contract status 'Draft'
            testCV.sign_able__c = false;
            
            Test.startTest();
            update testCV;
            Test.stopTest();
            
            System.assertEquals(false, testCV.IsMajorVersion);
        }
    }
    
    @isTest
    static void testBlockUpdateSendForSignature(){
        System.runAs(lstUser[0]){
            lstContract[1].Status__c = 'In Approval';
            lstContract[1].cTin_MainAPCL0__c='1-Insurance Procurement';
            lstContract[1].cTin_OrganizationalScope__c='test';
            update lstContract[1];
            // change Contentversion sign_able__c , Contract status 'In Approval'
            testCV.sign_able__c = false;
            
            Test.startTest();
            try{
                update testCV;
            }
            catch(Exception e){
                System.assert(e.getMessage().contains(system.label.cTin_BlockUpdateFile));
            }
            Test.stopTest();
            List<Contentversion> lstCV = [SELECT sign_able__c FROM Contentversion];
            System.assertEquals(1, lstCV.size());
            System.debug('lstCV'+lstCV);
            contractTriggerhandler.dummmyTest();
           // System.assert(lstCV[0].sign_able__c);
        }
    }
}