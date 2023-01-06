@isTest
public with sharing class AP72_ManageCTeamListView_TEST {
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
        lstUser[0].PAD_BypassValidationRules__c =true;
        lstUser[0].Bypass_FieldFilter__c = true;
        update lstUser;

        System.runAs(lstUser[0]){

            Account supplier = TestFactory.createSupplier('TestSupplier' , 'BillingCity', 'France');
            insert supplier;
            
            lstContract.add(TestFactory.createContract(supplier.Id, 'TestContract', 'Draft'));
            lstContract.add(TestFactory.createContract(supplier.Id, 'TestContract2', 'Draft'));
            insert lstContract;
            
            cTin_ContractTeam__c ct = new cTin_ContractTeam__c();
            ct.cTin_Contract__c = lstContract[0].Id;
            ct.cTin_Role__c = system.label.cTin_role_legal_rep;
            ct.cTin_TeamMember__c = lstUser[0].Id;
            ct.cTin_ContractAccessLevel__c = 'Read';
            insert ct;
            
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

    @isTest static void setEventContractTeamMemberTest() {
       System.runAs(lstUser[0]){
        Test.startTest();
        Set<ID> setIds = new Set<ID>{lstContract[0].id};
            AP72_ManageCTeamListView.setEventContractTeamMember(setIds/*,lstCtr[1].id,lstCtr[2].id,lstCtr[3].id*/);
        Test.stopTest();  
         }
    }
}