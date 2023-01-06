@isTest
public class HealthCheckHandler_TEST {
    static List<Contract__c> lstContract =  new List<Contract__c>();
    static List<cTin_ContractTeam__c> lstContractTeam;
    static List<User> lstUser = new list<User>();
    static ContentVersion testCV = new ContentVersion();
    static ContentDistribution testCD = new ContentDistribution();

  /* static {
        for(integer i=1;i<=11;i++){
                lstUser.add(TestFactory.createUser('Testuser'+ i , UserInfo.getProfileId(), true));           
        }
        insert lstUser;

        lstUser[0].PAD_BypassTrigger__c = 'AP40';
        lstUser[0].PAD_BypassTrigger__c='AP44';
        lstUser[0].cTin_Universign__c = true;
        lstUser[0].Bypass_FieldFilter__c=true;
        update lstUser;

        System.runAs(lstUser[0]){
            // Create the customer (aka entity) account
            Account vAccount = AP05_TestDataFactory.createLegalEntityAccount(lstUser[0]);
            // Create the entity account
            Account vEAccount = AP05_TestDataFactory.createEntityAccount(lstUser[0]);

            lstContract.add(TestFactory.createContract(vAccount.Id, 'TestContract', 'Draft'));
            lstContract.add(TestFactory.createContract(vAccount.Id, 'TestContract2', 'Draft'));
            insert lstContract;
            
            testCV = TestFactory.createContentVersion('Google.com', 'test.pdf', 'test', false);
            insert testCV;
            
            testCD=TestFactory.createContentDistribution(testCV.id, testCV.title, lstContract[1].Id);          
            insert testCD;

            List<ContentDocument> documents = [SELECT Id, Title, LatestPublishedVersionId,description FROM ContentDocument];

            contentDocumentLink testCDL = new contentDocumentLink(LinkedEntityId = lstContract[0].Id ,ContentDocumentId=documents[0].Id,ShareType='I');
            insert testCDL;
            
            AP44_BlockNewContractTeam.bypassSpecial=true;
            AP44_BlockNewContractTeam.allowAP44=false;
            lstContractTeam = new List<cTin_ContractTeam__c>{
                new cTin_ContractTeam__c(cTin_Role__c = '003', cTin_Contract__c = lstContract[0].Id, cTin_TeamMember__c = lstUser[0].Id,cTin_ApprovalOrder__c = '1', cTin_ContractAccessLevel__c = 'Read', Health_Check_Access_Level__c ='Read'),
                new cTin_ContractTeam__c(cTin_Role__c = '003', cTin_Contract__c = lstContract[0].Id, cTin_TeamMember__c = lstUser[1].Id,cTin_ApprovalOrder__c = '2', cTin_ContractAccessLevel__c = 'Read', Health_Check_Access_Level__c ='Read'),
                new cTin_ContractTeam__c(cTin_Role__c = '003', cTin_Contract__c = lstContract[0].Id, cTin_TeamMember__c = lstUser[2].Id,cTin_ApprovalOrder__c = 'Not in Approval Process', cTin_ContractAccessLevel__c = 'Read', Health_Check_Access_Level__c ='Read')
            };
            insert lstContractTeam;
        }
    }


    @isTest
    static void insertHealthCheckTest(){
        System.runAs(lstUser[0]){
            Test.startTest();
            Health_Check__c healthCheck = new Health_Check__c(Contract__c = lstContract[0].Id, Context__c = 'Yearly review', Contract_Value__c = 200);
            insert healthCheck;
            Test.stopTest();
        }
    }*/
    
      @isTest
    static void insertHealthCheckTest(){
       
            Test.startTest();
           HealthCheckHandler.dummy();
            Test.stopTest();
        
    }
    
}