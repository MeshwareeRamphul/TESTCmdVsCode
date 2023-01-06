@isTest
private class AP46_RecalculateCTOrder_TEST{

/* 
--------------------------------------------------------------------------------------
-- - Name          : AP46_RecalculateCTOrder_TEST
-- - Author        : Spoon
-- - Description   : Test class for AP46_RecalculateCTOrder
--
-- Maintenance History: 
--
-- Date         Name  Version  Remarks 
-- -----------  ----  -------  -------------------------------------------------------
-- 13-APR-2020  MRA 1.0     UAT Ticket : SP-00190
*************************************************************************************/

    static List<Contract__c> lstContract =  new List<Contract__c>();
    static List<cTin_ContractTeam__c> lstContractTeam;
    static List<User> lstUser = new list<User>();
    static ContentVersion testCV = new ContentVersion();
    static ContentDistribution testCD = new ContentDistribution();

    static {
        for(integer i=1;i<=11;i++){
            lstUser.add(TestFactory.createUser('Testuser'+ i , UserInfo.getProfileId(), true));           
        }
        
        insert lstUser;

        lstUser[0].PAD_BypassTrigger__c = 'AP40';
        update lstUser;

        System.runAs(lstUser[0]){

            Account supplier = TestFactory.createSupplier('TestSupplier' , 'BillingCity', 'France');
            insert supplier;

            lstContract.add(TestFactory.createContract(supplier.Id, 'TestContract', 'Draft'));
            lstContract.add(TestFactory.createContract(supplier.Id, 'TestContract2', 'Draft'));
            insert lstContract;
            
            testCV = TestFactory.createContentVersion('Google.com', 'test.pdf', 'test', false);
           // testCV.sign_able__c = true;
            insert testCV;
            
            testCD=TestFactory.createContentDistribution(testCV.id, testCV.title, lstContract[1].Id);          
            insert testCD;

            List<ContentDocument> documents = [SELECT Id, Title, LatestPublishedVersionId,description FROM ContentDocument];

            contentDocumentLink testCDL = new contentDocumentLink(LinkedEntityId = lstContract[0].Id ,ContentDocumentId=documents[0].Id,ShareType='I');
            insert testCDL;
            
            AP44_BlockNewContractTeam.bypassSpecial=true;
            
            lstContractTeam = new List<cTin_ContractTeam__c>{
                new cTin_ContractTeam__c(cTin_Role__c = 'Buyer/Sourcing Expert', cTin_Contract__c = lstContract[0].Id, cTin_TeamMember__c = lstUser[0].Id,cTin_ApprovalOrder__c = '1', cTin_ContractAccessLevel__c = 'Read'),
                new cTin_ContractTeam__c(cTin_Role__c = 'Buyer/Sourcing Expert', cTin_Contract__c = lstContract[0].Id, cTin_TeamMember__c = lstUser[1].Id,cTin_ApprovalOrder__c = '2', cTin_ContractAccessLevel__c = 'Read'),
                new cTin_ContractTeam__c(cTin_Role__c = 'Buyer/Sourcing Expert', cTin_Contract__c = lstContract[0].Id, cTin_TeamMember__c = lstUser[2].Id,cTin_ApprovalOrder__c = '3', cTin_ContractAccessLevel__c = 'Read'),
                new cTin_ContractTeam__c(cTin_Role__c = 'Buyer/Sourcing Expert', cTin_Contract__c = lstContract[0].Id, cTin_TeamMember__c = lstUser[3].Id,cTin_ApprovalOrder__c = '4', cTin_ContractAccessLevel__c = 'Read'),
                new cTin_ContractTeam__c(cTin_Role__c = 'Buyer/Sourcing Expert', cTin_Contract__c = lstContract[0].Id, cTin_TeamMember__c = lstUser[4].Id,cTin_ApprovalOrder__c = '5', cTin_ContractAccessLevel__c = 'Read'),
                new cTin_ContractTeam__c(cTin_Role__c = 'Buyer/Sourcing Expert', cTin_Contract__c = lstContract[0].Id, cTin_TeamMember__c = lstUser[5].Id,cTin_ApprovalOrder__c = '6', cTin_ContractAccessLevel__c = 'Read'),
                new cTin_ContractTeam__c(cTin_Role__c = 'Buyer/Sourcing Expert', cTin_Contract__c = lstContract[0].Id, cTin_TeamMember__c = lstUser[6].Id,cTin_ApprovalOrder__c = '7', cTin_ContractAccessLevel__c = 'Read'),
                new cTin_ContractTeam__c(cTin_Role__c = 'Buyer/Sourcing Expert', cTin_Contract__c = lstContract[0].Id, cTin_TeamMember__c = lstUser[7].Id,cTin_ApprovalOrder__c = '8', cTin_ContractAccessLevel__c = 'Read'),
                new cTin_ContractTeam__c(cTin_Role__c = 'Buyer/Sourcing Expert', cTin_Contract__c = lstContract[0].Id, cTin_TeamMember__c = lstUser[8].Id,cTin_ApprovalOrder__c = '9', cTin_ContractAccessLevel__c = 'Read'),
                new cTin_ContractTeam__c(cTin_Role__c = 'Buyer/Sourcing Expert', cTin_Contract__c = lstContract[0].Id, cTin_TeamMember__c = lstUser[9].Id,cTin_ApprovalOrder__c = 'Not in Approval Process', cTin_ContractAccessLevel__c = 'Read')
            };
            insert lstContractTeam;

        }

    }
    
    @isTest
    static void resetOrderTest(){
          system.runAs(lstUser[0]){
           lstContractTeam[0].cTin_ApprovalOrder__c='2';
           test.startTest();
              update lstContractTeam;
           test.stopTest();
         }
         
         list<cTin_ContractTeam__c> lstAssert=[select id,cTin_TeamMember__c from cTin_ContractTeam__c
         where cTin_ApprovalOrder__c='2' and id IN:lstContractTeam];
         system.assertEquals(lstUser[0].Id, lstAssert[0].cTin_TeamMember__c );
         
         
         
    }
   /* 
    @isTest
    static void resetOrderNotInProcessTest(){
          system.runAs(lstUser[0]){
           lstContractTeam[0].cTin_ApprovalOrder__c='Not in Approval Process';
           test.startTest();
              update lstContractTeam[0];
           test.stopTest();
           
           list<cTin_ContractTeam__c> lstAssert=[select id, cTin_ApprovalOrder__c from cTin_ContractTeam__c where cTin_ApprovalOrder__c!='Not in Approval Process'
                                                   and id IN :lstContractTeam
                                                   order by cTin_ApprovalOrder__c desc limit 1];
           system.assertEquals( lstAssert[0].cTin_ApprovalOrder__c, '8');
           
          
         }
    }*/
    
    @isTest
    static void resetOrderInProcessTest(){
          system.runAs(lstUser[0]){
           lstContractTeam[9].cTin_ApprovalOrder__c='10';
           test.startTest();
              update lstContractTeam[9];
           test.stopTest();
           
           list<cTin_ContractTeam__c> lstAssert=[select id from cTin_ContractTeam__c 
           where cTin_ApprovalOrder__c='Not in Approval Process' and id IN:lstContractTeam
           ];
           
           AP46_RecalculateCTOrder.blockDeletion(lstContractTeam);
           
           //system.assertEquals(lstAssert.size(),0);
          // lstContractTeam[0].cTin_ApprovalOrder__c='Not in Approval Process';
           //  update lstContractTeam[0];
         }
    }
    
    @isTest
    static void resetOrderOnDelTest(){
    
         system.runAs(lstUser[0]){
           
           test.startTest();
              AP46_RecalculateCTOrder.resetOrderOnDel(lstContractTeam[0].id,lstContract[0].id, '1');
           test.stopTest();
           
         }
   
    }
    
    /*@isTest
    static void resetOrderOnDelsTest(){
          system.runAs(lstUser[0]){
            List<ContentDocument> documents = [SELECT Id, Title, LatestPublishedVersionId,description FROM ContentDocument];

            contentDocumentLink testCDL = new contentDocumentLink(LinkedEntityId = lstContract[1].Id ,ContentDocumentId=documents[0].Id,ShareType='I');
            insert testCDL;
 
           cTin_ContractTeam__c ct=new cTin_ContractTeam__c(cTin_Role__c = 'Buyer/Sourcing Expert', cTin_Contract__c = lstContract[1].Id, cTin_TeamMember__c = lstUser[0].Id,cTin_ApprovalOrder__c = '1', cTin_ContractAccessLevel__c = 'Read');
           insert ct;
           
           test.startTest();
              delete ct;
           
          // list<cTin_ContractTeam__c> lstAssert=[select id from cTin_ContractTeam__c 
          //where cTin_Contract__c=:lstContract[1].id
          // ];
           
          test.stopTest();
            
           //system.assertEquals(lstAssert.size(),0);
         }
    }*/

}