@isTest
public class LegalInformationHandler_TEST {
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
            insert lstContractTeam;
        }
    }


    @isTest
    static void insertLegalInformationTest(){
        System.runAs(lstUser[0]){
            Test.startTest();
            Legal_Information__c legalInfo = new Legal_Information__c(Contract__c = lstContract[0].Id, Based_on_Axa_template_YES_NO__c = 'Yes', Comments_on_documents__c = 'Test', contractual_requirements__c = 'Test');
            insert legalInfo;
            Test.stopTest();
        }
    }
    
    //Test new Legal InformationTest => user not in contract team
    @isTest
    static void newLIUserNotInCT(){
        List<Profile> profileList = [SELECT id FROM profile where NAME like '%sys%' limit 1];
        profileList.add([select id,name from profile where name='cTin - Contract Buyer']);
        
        List<User> lstUsr = new List<User>(); 
        lstUsr.add(TestFactory.createUser('Testing', profileList[0].Id, true));
        lstUsr.add(TestFactory.createUsercTin('TestuserNewLI' , profileList[1].Id, true));
        insert lstUsr;
        
        account acct;
        System.runAs(lstUsr[0]){
            acct = TestFactory.createSupplier('Test Supplier', 'Florange', 'France');
            insert acct;
        }
        
        List<RecordType> lstRecordTypes = [SELECT Id,developerName,Name,sObjectType FROM RecordType WHERE sObjectType = 'Contract__c' AND DeveloperName LIKE 'cTin_%'];
        
        List<Contract__c> lstContracts = new List<Contract__c>{
            TestFactory.createcTinContracts('Test Contract1', acct.Id, lstRecordTypes[0].id),
            TestFactory.createcTinContracts('Test Contract2', acct.Id, lstRecordTypes[0].id)
        };
         
        System.runAs(lstUsr[0]){
            lstContracts[0].EndDate__c=system.today()+39;
            lstContracts[1].EndDate__c=system.today()+39;
            lstContracts[0].cTin_Reminder__c='N/A';
            lstContracts[1].cTin_Reminder__c='N/A';
            insert lstContracts;
        }
                
        System.runAs(lstUsr[1]){
            Legal_Information__c legalInfo = new Legal_Information__c(Contract__c = lstContracts[0].Id, Based_on_Axa_template_YES_NO__c = 'Yes', Comments_on_documents__c = 'Test', contractual_requirements__c = 'Test');
            Test.startTest();
            Database.SaveResult result = Database.insert(legalInfo, false);
            Test.stopTest();
            System.assertEquals('You do not have the permission to create a legal information.',result.getErrors()[0].getMessage());
        }
    }
    
    //Test new Legal InformationTest => user in contract team (team member and group member)
    @isTest
    static void newLIUserInTM(){
        List<Profile> profileList = [SELECT id FROM profile where NAME like '%sys%' limit 1];
        profileList.add([select id,name from profile where name='cTin - Contract Buyer']);
        
        List<User> lstUsr = new List<User>{ 
            TestFactory.createUser('Testing', profileList[0].Id, true),
            TestFactory.createUsercTin('TestuserNewLI' , profileList[1].Id, true),
            TestFactory.createUsercTin('TestuserNewLI2' , profileList[1].Id, true)
        };
        insert lstUsr;
        
        account acct;
        System.runAs(lstUsr[0]){
            acct = TestFactory.createSupplier('Test Supplier', 'Florange', 'France');
            insert acct;
        }
        
        List<RecordType> lstRecordTypes = [SELECT Id,developerName,Name,sObjectType FROM RecordType WHERE sObjectType = 'Contract__c' AND DeveloperName LIKE 'cTin_%'];
        
        List<Contract__c> lstContracts = new List<Contract__c>{
            TestFactory.createcTinContracts('Test Contract1', acct.Id, lstRecordTypes[0].id),
            TestFactory.createcTinContracts('Test Contract2', acct.Id, lstRecordTypes[0].id)
        };
              
        Group Grp = [select id,name from group where name='AIM audit' limit 1];
        system.debug('Grp '+Grp);
        //GroupMember GrpMember = [select id from groupmember where group.id=:Grp.id limit 1];
        
        insert new GroupMember(groupid=Grp.id,userorgroupid=lstUsr[2].id);
         
        System.runAs(lstUsr[0]){
            lstContracts[0].EndDate__c=system.today()+39;
            lstContracts[1].EndDate__c=system.today()+39;
             lstContracts[0].cTin_Reminder__c='N/A';
            lstContracts[1].cTin_Reminder__c='N/A';
            insert lstContracts;
            List<cTin_ContractTeam__c> lstCtrTeam = new List<cTin_ContractTeam__c>{
                new cTin_ContractTeam__c(cTin_TeamMember__c=lstUsr[1].id,cTin_Role__c='004',cTin_Contract__c=lstContracts[0].id,Legal_Access_Level__c='Edit' ),
                new cTin_ContractTeam__c(cTin_GroupMember__c='AIM audit',cTin_Role__c='004',cTin_Contract__c=lstContracts[1].id,Legal_Access_Level__c='Edit' )
            };
            insert lstCtrTeam;
        }
                
        System.runAs(lstUsr[1]){
            List<Legal_Information__c> lstLegalInfo = new List<Legal_Information__c>{
                new Legal_Information__c(Contract__c = lstContracts[0].Id, Based_on_Axa_template_YES_NO__c = 'Yes', Comments_on_documents__c = 'Test', contractual_requirements__c = 'Test'),
                new Legal_Information__c(Contract__c = lstContracts[0].Id, Based_on_Axa_template_YES_NO__c = 'Yes', Comments_on_documents__c = 'Test', contractual_requirements__c = 'Test'),
                new Legal_Information__c(Contract__c = lstContracts[1].Id, Based_on_Axa_template_YES_NO__c = 'Yes', Comments_on_documents__c = 'Test', contractual_requirements__c = 'Test')
            };
            Test.startTest();
            Database.SaveResult[] result = Database.insert(lstLegalInfo, false);
            Test.stopTest();
        }
    }
}