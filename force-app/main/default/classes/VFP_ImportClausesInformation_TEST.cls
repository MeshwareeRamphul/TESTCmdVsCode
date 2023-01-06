@isTest
public class VFP_ImportClausesInformation_TEST {

    static List<Contract__c> lstContract =  new List<Contract__c>();
    static List<cTin_ContractTeam__c> lstContractTeam;
    static List<User> lstUser = new list<User>();
    static ContentVersion testCV = new ContentVersion();
    static ContentDistribution testCD = new ContentDistribution();

    static {
        for(integer i=0;i<3;i++){
            lstUser.add(TestFactory.createUsercTin('Testuser'+ i , UserInfo.getProfileId(), true));          
        }
        insert lstUser;

        lstUser[0].PAD_BypassTrigger__c = 'AP40;AP25';
        lstUser[0].PAD_BypassValidationRules__c =true;
        lstUser[0].PAD_BypassWorkflows__c=true;
        lstUser[0].cTin_Universign__c = true;
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
            
            lstContractTeam = new List<cTin_ContractTeam__c>{
                new cTin_ContractTeam__c(cTin_Role__c = '003', cTin_Contract__c = lstContract[0].Id, cTin_TeamMember__c = lstUser[0].Id,cTin_ApprovalOrder__c = '1', cTin_ContractAccessLevel__c = 'Read', Legal_Access_Level__c ='Read'),
                new cTin_ContractTeam__c(cTin_Role__c = '003', cTin_Contract__c = lstContract[0].Id, cTin_TeamMember__c = lstUser[1].Id,cTin_ApprovalOrder__c = '2', cTin_ContractAccessLevel__c = 'Read', Legal_Access_Level__c ='Read'),
                new cTin_ContractTeam__c(cTin_Role__c = '003', cTin_Contract__c = lstContract[0].Id, cTin_TeamMember__c = lstUser[2].Id,cTin_ApprovalOrder__c = 'Not in Approval Process', cTin_ContractAccessLevel__c = 'Read', Legal_Access_Level__c ='Read')
            };
                
            Legal_Information__c legalInfo = new Legal_Information__c(Contract__c = lstContract[1].Id, Based_on_Axa_template_YES_NO__c = 'Yes', Comments_on_documents__c = 'Test', contractual_requirements__c = 'Test',Imported__c = true);
            insert legalInfo;
        }
    }
        
    @isTest
    static void importClauses_OK() {
        System.runAs(lstUser[0]){
            Test.startTest();

            insert lstContractTeam;
            Legal_Information__c legalInfo = new Legal_Information__c(Contract__c = lstContract[0].Id, Based_on_Axa_template_YES_NO__c = 'Yes', Comments_on_documents__c = 'Test', contractual_requirements__c = 'Test');
            insert legalInfo;
            lstContract[1].cTin_ParentContract__c = lstContract[0].Id;
            update lstContract[1];
            
            ApexPages.StandardController sc = new ApexPages.standardController(lstContract[1]);
            VFP_ImportClausesInformation vController = new VFP_ImportClausesInformation(sc);
            vController.recordId = lstContract[1].Id;
            vController.importClauses();
			System.assertEquals(vController.callfunc, '<script> showToast("'+Label.Success_LegalClausesImported+'","Success"); </script>');

            Test.stopTest();
        }
    }
        
    @isTest
    static void importClauses_NoParentContract() {
        System.runAs(lstUser[0]){
            Test.startTest();
            
            ApexPages.StandardController sc = new ApexPages.standardController(lstContract[1]);
            VFP_ImportClausesInformation vController = new VFP_ImportClausesInformation(sc);
            vController.recordId = lstContract[1].Id;
            vController.importClauses();
			System.assertEquals(vController.callfunc, '<script> showToast("'+Label.Error_NoParentContract+'","Error"); </script>');

            Test.stopTest();
        }
    }
        
    @isTest
    static void importClauses_noLegalClause() {
        System.runAs(lstUser[0]){
            Test.startTest();
            
            lstContract[1].cTin_ParentContract__c = lstContract[0].Id;
            update lstContract[1];
            
            ApexPages.StandardController sc = new ApexPages.standardController(lstContract[1]);
            VFP_ImportClausesInformation vController = new VFP_ImportClausesInformation(sc);
            vController.recordId = lstContract[1].Id;
            vController.importClauses();
			System.assertEquals(vController.callfunc, '<script> showToast("'+Label.Error_NoLegalClauseAvailable+'","Error"); </script>');

            Test.stopTest();
        }
    }
        
    @isTest
    static void importClauses_otherError() {
        System.runAs(lstUser[0]){
            Test.startTest();
            
            ApexPages.StandardController sc = new ApexPages.standardController(lstContract[1]);
            VFP_ImportClausesInformation vController = new VFP_ImportClausesInformation(sc);
            vController.recordId = null;
            vController.importClauses();
			System.assertEquals(vController.callfunc, '<script> showToast("'+Label.Error_ErrorDuringProcess+'","Error"); </script>');
            
            Test.stopTest();
        }
    }
}