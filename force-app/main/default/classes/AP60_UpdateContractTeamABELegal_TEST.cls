@isTest
private class AP60_UpdateContractTeamABELegal_TEST {

/* 
--------------------------------------------------------------------------------------
-- - Name          : AP60_UpdateContractTeamABELegal_TEST
-- - Author        : Spoon
-- - Description   : Test class for AP60_UpdateContractTeamABELegal
--
-- Maintenance History: 
--
-- Date         Name  Version  Remarks 
-- -----------  ----  -------  -------------------------------------------------------
-- 09-JUN-2021  MRA    1.0    Initial version
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
            lstUser[0].PAD_BypassTrigger__c = 'AP40;AP46;AP37;';
            lstUser[0].Bypass_FieldFilter__c=true;
            lstUser[0].cTin_Entity__c='430 - AXA Belgium Corporate Legal';
            lstUser[0].cTin_EntityLocalCode__c='ABCL';

            lstUser[1].Bypass_FieldFilter__c=true;
            lstUser[1].PAD_BypassValidationRules__c = true;
            lstUser[1].Bypass_FieldFilter__c=true;
            lstUser[1].PAD_BypassTrigger__c = 'AP40;AP46;AP37;';
            lstUser[1].cTin_Entity__c='600 - AXA XL';
            lstUser[1].cTin_EntityLocalCode__c='AXL';
            
            lstUser[1].Bypass_FieldFilter__c=true;
            lstUser[1].PAD_BypassValidationRules__c = true;
            lstUser[1].PAD_BypassTrigger__c = 'AP40;AP46;AP37;';
            lstUser[1].cTin_Entity__c=' 1320 - AXA Switzerland';
            lstUser[1].cTin_EntityLocalCode__c='ACH';
            update lstUser;
    
            System.runAs(lstUser[0]){
    
                Account supplier = TestFactory.createSupplier('TestSupplier' , 'BillingCity', 'France');
                insert supplier;
    
                lstContract.add(TestFactory.createContract(supplier.Id, 'TestContract', 'Draft'));
                lstContract.add(TestFactory.createContract(supplier.Id, 'TestContract2', 'Draft'));
                
                
               // testCV = TestFactory.createContentVersion('Google.com', 'test.pdf', 'test', false);
               // testCV.sign_able__c = true;
               // insert testCV;
                
               // testCD=TestFactory.createContentDistribution(testCV.id, testCV.title, lstContract[1].Id);          
               // insert testCD;
    
              //  List<ContentDocument> documents = [SELECT Id, Title, LatestPublishedVersionId,description FROM ContentDocument];
    
              //  contentDocumentLink testCDL = new contentDocumentLink(LinkedEntityId = lstContract[0].Id ,ContentDocumentId=documents[0].Id,ShareType='I');
              //  insert testCDL;
                
                AP44_BlockNewContractTeam.bypassSpecial=true;
                
                /*lstContractTeam = new List<cTin_ContractTeam__c>{
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
                insert lstContractTeam;*/
    
            }
    
        }
        
        @isTest
        static void createCtrABCLTest(){
              system.runAs(lstUser[0]){               
               test.startTest();
                    insert lstContract;
               test.stopTest();
             }
             
             list<cTin_ContractTeam__c> lstAssert=[select id,cTin_TeamMember__c 
             from cTin_ContractTeam__c
             WHERE cTin_contract__c IN: lstContract 
             AND cTin_role__c = :'016'];
            // system.assertEquals(lstAssert.size(), 1);
            
             system.runAs(lstUser[0]){ 
                AP44_BlockNewContractTeam.bypassSpecial=true;
                lstContract[0].ownerId=lstUser[1].Id;
                update lstContract[0];
             }

             system.runAs(lstUser[0]){ 
            // AP44_BlockNewContractTeam.bypassSpecial=true;
             //lstContract[0].ownerId=lstUser[0].Id;
             //update  lstContract[0];
             }
        }

        @isTest
        static void UpdateOwnerABCLTest(){
              system.runAs(lstUser[1]){               
               test.startTest();
                    insert lstContract;
              
             
           /* list<cTin_ContractTeam__c> lstAssert=[select id,cTin_TeamMember__c 
             from cTin_ContractTeam__c
             WHERE cTin_contract__c IN: lstContract 
             AND cTin_role__c = :'007'];
             system.assertEquals(lstAssert.size(), 0);*/
            
             system.runAs(lstUser[1]){ 
                AP44_BlockNewContractTeam.bypassSpecial=true;
                lstContract[0].ownerId=lstUser[0].Id;
                update lstContract[0];
             }
                   test.stopTest();
             }

             system.runAs(lstUser[0]){ 
            // AP44_BlockNewContractTeam.bypassSpecial=true;
             //lstContract[0].ownerId=lstUser[0].Id;
             //update  lstContract[0];
             }

        }
    
    @isTest
        static void UpdateOwnerACHTest(){
              system.runAs(lstUser[1]){               
               test.startTest();
                    insert lstContract;
              
             
           /* list<cTin_ContractTeam__c> lstAssert=[select id,cTin_TeamMember__c 
             from cTin_ContractTeam__c
             WHERE cTin_contract__c IN: lstContract 
             AND cTin_role__c = :'007'];
             system.assertEquals(lstAssert.size(), 0);*/
            
             system.runAs(lstUser[1]){ 
                AP44_BlockNewContractTeam.bypassSpecial=true;
                lstContract[0].ownerId=lstUser[2].Id;
                update lstContract[0];
             }
                   test.stopTest();
             }

             system.runAs(lstUser[0]){ 
            // AP44_BlockNewContractTeam.bypassSpecial=true;
             //lstContract[0].ownerId=lstUser[0].Id;
             //update  lstContract[0];
             }

        }

       
}