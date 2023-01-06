@isTest
public class AP40_SharingContractTeam_TEST {

    /* 
      --------------------------------------------------------------------------------------
      -- - Name          : AP40_SharingContractTeam_TEST
      -- - Author        : Zohar Sinay
      -- - Description   : This test class tests Trigger ContractTeam_AfterInsert_BeforeDelete and Helper class Helper_ContractTeam_InsertDelete
      --
      -- Maintenance History: 
      --
      -- Date         Name  Version  Remarks 
      -- -----------  ----  -------  -------------------------------------------------------
      -- 25-OCT-2014  ZOS    1.0     Initial version 
      -- 16-MAR-2021  ARA    1.1     SP-01222 - Correction of bug (Sharing not generated on ContractForm for BO)
      *************************************************************************************/

      /*static testMethod void test_method_zero(){
        User user00 = TestFactory.createUser('Testuser', UserInfo.getProfileId(), true);
        insert user00;
        System.runAs(user00){

            List<Contract__c> lstContract =  new List<Contract__c>();
            List<cTin_ContractTeam__c> lstContractTeam = new List<cTin_ContractTeam__c>();
            
            Account supplier = TestFactory.createSupplier('TestSupplier' , 'BillingCity', 'France');
            insert supplier;

            Contract__c contract = TestFactory.createContract(supplier.Id, 'TestContract', 'Draft');
            Contract__c contract2 = TestFactory.createContract(supplier.Id, 'TestContract2', 'Draft');
            lstContract.add(contract);
            lstContract.add(contract2);
            insert lstContract;

            contract.OwnerId = UserInfo.getUserId();
            update contract;
            
            Group testGroup = new Group();
            testGroup.Name = 'testGroup';
            testGroup.DeveloperName = 'ABC';
            Insert testGroup;
            
            test.startTest();
                cTin_ContractTeam__c ContractTeam = new cTin_ContractTeam__c(cTin_Role__c = 'Buyer/Sourcing Expert', cTin_Contract__c = lstContract[0].Id, cTin_TeamMember__c = user00.Id,
                                                                    cTin_ApprovalOrder__c = '1', cTin_ContractAccessLevel__c = 'Read');
                cTin_ContractTeam__c ContractTeam2 = new cTin_ContractTeam__c(cTin_Role__c = 'Buyer/Sourcing Expert', cTin_Contract__c = lstContract[1].Id, cTin_TeamMember__c = user00.Id,
                                                                    cTin_ApprovalOrder__c = 'Not in approval process', cTin_ContractAccessLevel__c = 'Read');

                lstContractTeam.add(ContractTeam);
                lstContractTeam.add(ContractTeam2);
                insert lstContractTeam;
               
                list<cTin_ContractTeam__c >cteam=[select id from cTin_ContractTeam__c  where id =: ContractTeam.id];
                try{delete cteam;}
                catch(Exception e){}
            test.stopTest();
        }
    }*/
    
    static Account acc;
    static Contact con;

    static testMethod void test_method_one(){
        User user00 = TestFactory.createUser('Testuser', UserInfo.getProfileId(), true);
        insert user00;
        user00.Bypass_FieldFilter__c=true;
        update user00;
        System.runAs(user00){

            List<Contract__c> lstContract =  new List<Contract__c>();
            List<cTin_ContractTeam__c> lstContractTeam = new List<cTin_ContractTeam__c>();
            
            acc = AP05_TestDataFactory.createLegalEntityAccount(user00);
            con = AP05_TestDataFactory.createEntityContact(acc);

            Contract__c contract = TestFactory.createContract(acc.Id, 'TestContract', 'Draft');
            Contract__c contract2 = TestFactory.createContract(acc.Id, 'TestContract2', 'Draft');
            lstContract.add(contract);
            lstContract.add(contract2);
            insert lstContract;

            contract.OwnerId = UserInfo.getUserId();
            update contract;
            
            Group testGroup = new Group();
            testGroup.Name = 'testGroup';
            testGroup.DeveloperName = 'ABC';
            Insert testGroup;
            
            test.startTest();
                cTin_ContractTeam__c ContractTeam = new cTin_ContractTeam__c(cTin_Role__c = 'Buyer/Sourcing Expert', cTin_Contract__c = lstContract[0].Id, cTin_TeamMember__c = user00.Id,
                                                                    cTin_ApprovalOrder__c = 'Not in approval process', cTin_ContractAccessLevel__c = 'Read');
                cTin_ContractTeam__c ContractTeam2 = new cTin_ContractTeam__c(cTin_Role__c = 'Buyer/Sourcing Expert', cTin_Contract__c = lstContract[1].Id, cTin_TeamMember__c = user00.Id,
                                                                    cTin_ApprovalOrder__c = 'Not in approval process', cTin_ContractAccessLevel__c = 'Read');

                lstContractTeam.add(ContractTeam);
                lstContractTeam.add(ContractTeam2);

                insert lstContractTeam;
               
               list<cTin_ContractTeam__c >cteam=[select id from cTin_ContractTeam__c  where id =: ContractTeam.id];
               try{delete cteam;}
               catch(Exception e){}
           
            
               AP40_SharingContractTeam.dummy();
            test.stopTest();
        }
    }

    static testMethod void test_method_two(){
        User user00 = TestFactory.createUser('Testuser2', UserInfo.getProfileId(), true);
        insert user00;
         user00.Bypass_FieldFilter__c=true;
        update user00;
        System.runAs(user00){
            
            acc = AP05_TestDataFactory.createLegalEntityAccount(user00);
            con = AP05_TestDataFactory.createEntityContact(acc);
            Contract__c contract = TestFactory.createContract(acc.Id,'TestContract2', 'Draft');
            insert contract;
            contract.OwnerId = UserInfo.getUserId();
            update contract;
            Group testGroup = new Group();
            testGroup.Name = 'testGroup';
            testGroup.DeveloperName = 'ABC';
            Insert testGroup;
            test.startTest();
            cTin_ContractTeam__c ContractTeam = new cTin_ContractTeam__c(cTin_Role__c = 'Buyer/Sourcing Expert', cTin_Contract__c = contract.Id, cTin_GroupMember__c = 'testGroup',
                                                cTin_ContractAccessLevel__c = 'Read');
            insert ContractTeam;
            
            list<cTin_ContractTeam__c >cteam=[select id from cTin_ContractTeam__c  where id =: ContractTeam.id];
            
            try{delete cteam;}
            catch(Exception e){}
            test.stopTest();

        }
    }   
    
   /* static testMethod void test_method_three(){
        User user00 = TestFactory.createUser('Testuser2', UserInfo.getProfileId(), true);
        insert user00;
         user00.Bypass_FieldFilter__c=true;
        update user00;
        
        User newusr = TestFactory.createUser('Testuser3', UserInfo.getProfileId(), true);
        insert newusr;
        
        System.runAs(user00){
            
            acc = AP05_TestDataFactory.createLegalEntityAccount(user00);
            con = AP05_TestDataFactory.createEntityContact(acc);
            
            Contract__c contract = TestFactory.createContract(acc.Id,'TestContract2', 'Draft');
            insert contract;

            cTin_ContractTeam__c ContractTeam = new cTin_ContractTeam__c(cTin_Role__c = 'Buyer/Sourcing Expert',
                                                                         cTin_Contract__c = contract.Id, cTin_TeamMember__c = user00.Id,
                                                cTin_ContractAccessLevel__c = 'Read');
            insert ContractTeam;
            
           // Map<Id, Contract__c> mapofContracts=new map<id,Contract__c>();
           // mapofContracts.put(contract.id,contract);
           // test.startTest();
           //     AP40_GenerateContractShare.generateContractShare(mapofContracts);
           //  test.stopTest();
           
            set<Id> setCtrId=new set<id>();
            setCtrId.add(contract.id);
            test.startTest();
               AP40_GenerateContractShare.generateContractShare(setCtrId);
            test.stopTest();

        }
    }   */
}