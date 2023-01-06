@isTest
private class AP62_SendReminderToBOLegals_TEST{

/* 
--------------------------------------------------------------------------------------
-- - Name          : AP62_SendReminderToBOLegals_TEST
-- - Author        : Spoon
-- - Description   : Test class for AP62_SendReminderToBOLegals
--
-- Maintenance History: 
--
-- Date         Name  Version  Remarks 
-- -----------  ----  -------  -------------------------------------------------------
-- 10-SEP-2021  MRA    1.0    Initial version
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

            lstUser[0].Bypass_FieldFilter__c=true;
            lstUser[0].PAD_BypassValidationRules__c = true;
            lstUser[0].PAD_BypassTrigger__c = 'AP40';
            lstUser[0].cTin_Entity__c='430 - AXA Belgium Corporate Legal';
            lstUser[0].cTin_EntityLocalCode__c='ABCL';

            lstUser[1].Bypass_FieldFilter__c=true;
            lstUser[1].PAD_BypassValidationRules__c = true;
            lstUser[1].PAD_BypassTrigger__c = 'AP40';
            lstUser[1].cTin_Entity__c='600 - AXA XL';
            lstUser[1].cTin_EntityLocalCode__c='AXL';
            update lstUser;
    
            System.runAs(lstUser[0]){
    
                Account supplier = TestFactory.createSupplier('TestSupplier' , 'BillingCity', 'France');
                insert supplier;
    
                lstContract.add(TestFactory.createContract(supplier.Id, 'TestContract', 'Draft'));
                 lstContract[0].StartDate__c=date.today();
                lstContract[0].EndDate__c=date.today()+30;
               //lstContract.add(TestFactory.createContract(supplier.Id, 'TestContract2', 'Draft'));
                insert lstcontract;
                
               // testCV = TestFactory.createContentVersion('Google.com', 'test.pdf', 'test', false);
               // testCV.sign_able__c = true;
               // insert testCV;
                
               // testCD=TestFactory.createContentDistribution(testCV.id, testCV.title, lstContract[1].Id);          
               // insert testCD;
    
              //  List<ContentDocument> documents = [SELECT Id, Title, LatestPublishedVersionId,description FROM ContentDocument];
    
              //  contentDocumentLink testCDL = new contentDocumentLink(LinkedEntityId = lstContract[0].Id ,ContentDocumentId=documents[0].Id,ShareType='I');
              //  insert testCDL;
                
                AP44_BlockNewContractTeam.bypassSpecial=true;
                
                lstContractTeam = new List<cTin_ContractTeam__c>{
                    new cTin_ContractTeam__c(cTin_Role__c = '004', cTin_Contract__c = lstContract[0].Id, cTin_TeamMember__c = lstUser[9].Id,cTin_ApprovalOrder__c = 'Not in Approval Process', cTin_ContractAccessLevel__c = 'Read')
                   // new cTin_ContractTeam__c(cTin_Role__c = '016', cTin_Contract__c = lstContract[0].Id, cTin_TeamMember__c = lstUser[9].Id,cTin_ApprovalOrder__c = 'Not in Approval Process', cTin_ContractAccessLevel__c = 'Read')
                };
                insert lstContractTeam;
    
            }
    
        }
        
        @isTest
        static void notifyBoLegalsTest(){
              system.runAs(lstUser[0]){   
              
              lstContract[0].TECH_NotifyBOLegals__c=true;            
               test.startTest();
                    update lstContract;
               test.stopTest();
             }
             
             
        }

      

}