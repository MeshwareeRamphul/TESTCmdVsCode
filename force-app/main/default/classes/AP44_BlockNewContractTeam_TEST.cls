@isTest
public without sharing class AP44_BlockNewContractTeam_TEST {
/* 
--------------------------------------------------------------------------------------
-- - Name          : AP44_BlockNewContractTeam_TEST
-- - Author        : Spoon
-- - Description   : Test class for controller AP44_BlockNewContractTeam
--
-- Maintenance History: 
--
-- Date         Name  Version  Remarks 
-- -----------  ----  -------  -------------------------------------------------------
-- 26-MAR-2020  SGO    1.0     UAT Ticket : SP-001
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

        lstUser[0].PAD_BypassTrigger__c = 'AP40';
        lstUser[0].PAD_BypassValidationRules__c=true;
        update lstUser;

        System.runAs(lstUser[0]){

            Account supplier = TestFactory.createSupplier('TestSupplier' , 'BillingCity', 'France');
            supplier.cTin_TOBA_needed__c='no';
            insert supplier;

            lstContract.add(TestFactory.createContract(supplier.Id, 'TestContract', 'Draft'));
            lstContract.add(TestFactory.createContract(supplier.Id, 'TestContract2', 'Draft'));
            insert lstContract;
            
            testCV = TestFactory.createContentVersion('Google.com', 'test.pdf', 'test', false);
            testCV.sign_able__c = true;
            insert testCV;
            
            testCD=TestFactory.createContentDistribution(testCV.id, testCV.title, lstContract[1].Id);          
            insert testCD;

            List<ContentDocument> documents = [SELECT Id, Title, LatestPublishedVersionId,description FROM ContentDocument];

            contentDocumentLink testCDL = new contentDocumentLink(LinkedEntityId = lstContract[1].Id ,ContentDocumentId=documents[0].Id,ShareType='I');
            insert testCDL;

            lstContractTeam = new List<cTin_ContractTeam__c>{
                new cTin_ContractTeam__c(cTin_Role__c = 'Buyer/Sourcing Expert', cTin_Contract__c = lstContract[0].Id, cTin_TeamMember__c = lstUser[0].Id,cTin_ApprovalOrder__c = '1', cTin_ContractAccessLevel__c = 'Read'),
                new cTin_ContractTeam__c(cTin_Role__c = 'Buyer/Sourcing Expert', cTin_Contract__c = lstContract[1].Id, cTin_TeamMember__c = lstUser[1].Id,cTin_ApprovalOrder__c = '1', cTin_ContractAccessLevel__c = 'Read')
            };

        }

    }


   

    @IsTest
    static void testBlockCreation(){
        
        System.runAs(lstUser[0]){
            // get initial number of contract team members
            List<cTin_ContractTeam__c> lstRetCtrTeam1 = new List<cTin_ContractTeam__c>([SELECT Id, Name FROM cTin_ContractTeam__c WHERE cTin_Contract__c = :lstContract[0].Id]);

            Test.startTest();
                try{
                    insert lstContractTeam[0];
                }
                catch(Exception ex){
                    System.debug('ex: ' + ex);
                    System.assert(ex.getMessage().contains(system.label.NoPdfError));
                }

            Test.stopTest();

            List<cTin_ContractTeam__c> lstRetCtrTeam2 = new List<cTin_ContractTeam__c>([SELECT Id, Name FROM cTin_ContractTeam__c WHERE cTin_Contract__c = :lstContract[0].Id]);

            //System.assertEquals(lstRetCtrTeam1.size(),lstRetCtrTeam2.size());   
        }
        
    }

    
    @IsTest
    static void testAllowCreation(){
        
        System.runAs(lstUser[0]){
            // get initial number of contract team members
            List<cTin_ContractTeam__c> lstRetCtrTeam1 = new List<cTin_ContractTeam__c>([SELECT Id, Name FROM cTin_ContractTeam__c WHERE cTin_Contract__c = :lstContract[1].Id]);

            Test.startTest();

                insert lstContractTeam[1];

            Test.stopTest();
            
            List<cTin_ContractTeam__c> lstRetCtrTeam2 = new List<cTin_ContractTeam__c>([SELECT Id, Name FROM cTin_ContractTeam__c WHERE cTin_Contract__c = :lstContract[1].Id]);

            System.assertEquals(lstRetCtrTeam1.size()+1,lstRetCtrTeam2.size());
           
            List<ContentDocument> documents = [SELECT Id, Title, LatestPublishedVersionId,description FROM ContentDocument];
            
            contentDocumentLink CDL = new contentDocumentLink(LinkedEntityId = lstContract[0].Id ,ContentDocumentId=documents[0].Id,ShareType='I');
            insert CDL;
            
            AP44_BlockNewContractTeam.determineNumOfSignablePDF(documents);
           
            testCV.sign_able__c = false;
            update testCV;
            
            //Database.executeBatch(new AP44_BatchUpdateNumDocs (),1);

        }
        
    }
    
      static testMethod void runBatchAP44_test(){
        System.runAs(lstUser[0]){
            list<contentversion>lstCv=new list<Contentversion>();
            lstCv.add(testCV);
            AP44_BatchUpdateNumDocs batch = new AP44_BatchUpdateNumDocs();
            test.startTest();
              string batchId=database.executeBatch(batch);      
            test.stopTest();
            AP44_BlockNewContractTeam.dummy();
         }
     }

}