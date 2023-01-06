@isTest
/* AP37_UpdateContractSharingTest 
----------------------------------------------------------------------
-- - Name          : AP37_UpdateContractSharingTest 
-- - Author        : SC
-- - Description   : Test Class for AP37_UpdateContractSharing
-- Maintenance History:
--
-- Date         Name  Version  Remarks 
-- -----------  ----  -------  ---------------------------------------
-- 23-Mar-2016  DMU    1.0      Initial version                   
---------------------------------------------------------------------
**********************************************************************
*/
private class AP37_UpdateContractSharingTest {
    static Contract__c contract;
    static User testUser;
    static User updateOwner;
    static list <Contract__c> contractList;
    static list <cTin_ContractTeam__c> contratcTeamList;
    static Group testGroup ;
    static id rtConDraftId;
    static list<User> cTeamUsersLst;
    static contentversion testContentInsert;
    static contentDistribution testCD,testCD2;
    static contentversion testCV,testCV2;
    
    static {

        List<Profile> profileList = [SELECT id FROM profile where NAME like '%cTin%'];
        System.debug('##PROFILEID: ' + profileList);

        //creating user with universign
        testUser = TestFactory.createUser('TestUser' , UserInfo.getProfileId(), true);
        testUser.PAD_BypassValidationRules__c = true;
        testUser.PAD_BypassTrigger__c='AP40;ctinblockUpdate;AP44';
        testUser.cTin_LegalRepresentative__c = true;
        testUser.IsActive = true;
        testUser.cTin_UniverSign__c=true;
        insert testUser; 

        //create another user to modify owner
        System.runAs(testUser){
        LC34_AmendContract.allowClone=true;
        
        updateOwner = new User(Username = 'test@karoo1.com',
                            LastName = 'testuser',
                            LanguageLocaleKey = 'en_US',
                            FirstName = 'test',
                            Email = 'test@test.com',
                            Alias = 'test',
                            TimeZoneSidKey = 'Europe/Dublin',
                            LocaleSidKey = 'en_US',
                            EmailEncodingKey = 'UTF-8',
                            ProfileId =  profileList[0].id,
                            PAD_BypassValidationRules__c = true
                            );
        insert updateOwner;
        
        

        cTeamUsersLst=new list<User>{
                     new User(Username = 'test1@karooAP37.com',
                            LastName = 'testuser',
                            LanguageLocaleKey = 'en_US',
                            FirstName = 'test',
                            Email = 'test1@test.com',
                            Alias = 'test',
                            TimeZoneSidKey = 'Europe/Dublin',
                            LocaleSidKey = 'en_US',
                            EmailEncodingKey = 'UTF-8',
                            ProfileId =  profileList[0].id,
                            PAD_BypassValidationRules__c = true),
                     new User(Username = 'test2@karooAP37.com',
                            LastName = 'testuser',
                            LanguageLocaleKey = 'en_US',
                            FirstName = 'test',
                            Email = 'test2@test.com',
                            Alias = 'test',
                            TimeZoneSidKey = 'Europe/Dublin',
                            LocaleSidKey = 'en_US',
                            EmailEncodingKey = 'UTF-8',
                            ProfileId =  profileList[0].id,
                            PAD_BypassValidationRules__c = true)};
        insert cTeamUsersLst;
        
        testGroup = new Group();
        testGroup.Name = 'testGroup';
        testGroup.DeveloperName = 'testGroup';
         Insert testGroup;

        }


                
        system.RunAs(testUser) { 
            //creating account
            Account supplier = TestFactory.createSupplier('TestSupplier', 'Streename' , 'France');
            insert supplier;
            
             rtConDraftId=Schema.SObjectType.Contract__c.getRecordTypeInfosByName().get('Contract Draft').getRecordTypeId();

            //creating contract
            contract = TestFactory.createContract(supplier.Id, 'ContractName' , 'Draft');
            contract.recordtypeId=rtConDraftId;
            insert contract;
  
            

           

            //create contract__c list
            contractList = new list < Contract__c > {
                                            new Contract__c(Name = 'Test Contract 1', Status__c = 'In Progress', cTin_TypeofDocument__c = 'Contract', cTin_BusinessOwner__c = UserInfo.getUserId(),
                                                cTin_ShortDescription__c = 'Test Description', StartDate__c = Date.today(), EndDate__c = Date.today()-3, 
                                                cTin_Reminder__c = 'None', 
                                                cTin_FinancialEngagement__c = 'No', 
                                                cTin_SupplierAccount__c = supplier.Id, 
                                                cTin_CRClause__c = 'Standard',
                                                cTin_AntiBriberyClause__c = 'Standard', 
                                                cTin_TerminationClause__c ='Standard', 
                                                OwnerId = testUser.Id, 
                                                cTin_ProcurementInvolvementGrade__c = 'Level 1 - Challenge spend & negotiate', 
                                                cTin_FairTransparentSelectionProcess__c = 'No',
                                                cTin_MainAPCL2__c='1103-Towing', cTin_eSourcingReferenceId__c = 'WS111111111', 
                                                cTin_SourcingDecision__c = 'RFx',
                                                RecordTypeId=rtConDraftId),

                                            new Contract__c(Name = 'Test Contract 2', 
                                                Status__c = 'In Progress', 
                                                cTin_TypeofDocument__c = 'Contract', 
                                                cTin_BusinessOwner__c = UserInfo.getUserId(),
                                                cTin_ShortDescription__c = 'Test Description', 
                                                StartDate__c = Date.today(), 
                                                EndDate__c = Date.today()-3, 
                                                cTin_Reminder__c = 'None', 
                                                cTin_FinancialEngagement__c = 'No', 
                                                cTin_SupplierAccount__c = supplier.Id, 
                                                cTin_CRClause__c = 'Standard',
                                                cTin_AntiBriberyClause__c = 'Standard', 
                                                cTin_TerminationClause__c ='Standard', 
                                                OwnerId = testUser.Id, 
                                                cTin_ProcurementInvolvementGrade__c = 'Level 1 - Challenge spend & negotiate', 
                                                cTin_FairTransparentSelectionProcess__c = 'No',
                                                cTin_MainAPCL2__c='1103-Towing', cTin_eSourcingReferenceId__c = 'WS111111111', 
                                                cTin_SourcingDecision__c = 'RFx',
                                                RecordTypeId=rtConDraftId)
            };
            insert contractList;



            contratcTeamList = new list <cTin_ContractTeam__c>  {
                                                            new cTin_ContractTeam__c(cTin_Role__c = '009', cTin_Contract__c = contractList[0].Id, cTin_TeamMember__c = testUser.Id, cTin_ApprovalOrder__c = '1', cTin_ContractAccessLevel__c = 'Read'),
                                                            new cTin_ContractTeam__c(cTin_Role__c = '009', cTin_Contract__c = contractList[0].Id, cTin_TeamMember__c = cTeamUsersLst[1].Id, cTin_ApprovalOrder__c = '2', cTin_ContractAccessLevel__c = 'Edit'),
                                                            new cTin_ContractTeam__c(cTin_Role__c = '008', cTin_Contract__c = contractList[0].Id,cTin_GroupMember__c = testGroup.name,cTin_ApprovalOrder__c = 'Not in Approval Process', cTin_ContractAccessLevel__c = 'Edit'),
                                                            new cTin_ContractTeam__c(cTin_Role__c = '007', cTin_Contract__c = contractList[1].Id,cTin_GroupMember__c = testGroup.name,cTin_ApprovalOrder__c = 'Not in Approval Process',cTin_ContractAccessLevel__c = 'Edit'),
                                                            new cTin_ContractTeam__c(cTin_Role__c = '004', cTin_Contract__c = contractList[1].Id,cTin_TeamMember__c = cTeamUsersLst[1].Id,cTin_ApprovalOrder__c = '2',cTin_ContractAccessLevel__c = 'Read')


            };
            
            
            testCV = TestFactory.createContentVersion('Google.com', 'test.pdf', 'test', false);
            testCV.sign_able__c = true;
            insert testCV;
            
            testCV2 = TestFactory.createContentVersion('Google.com', 'test.pdf', 'test', false);
            testCV2.sign_able__c = true;
            insert testCV2;
            
            testCD=TestFactory.createContentDistribution(testCV.id, testCV.title, contractList[0].Id);          
            insert testCD;
            
            testCD2=TestFactory.createContentDistribution(testCV2.id, testCV.title, contractList[1].Id);          
            insert testCD2;
            
             List<ContentDocument> documents = [SELECT Id, Title, LatestPublishedVersionId,description FROM ContentDocument];

            contentDocumentLink testCDL = new contentDocumentLink(LinkedEntityId = contractList[0].Id ,ContentDocumentId=documents[0].Id,ShareType='I');
            insert testCDL;
            
            contentDocumentLink testCDL2 = new contentDocumentLink(LinkedEntityId = contractList[1].Id ,ContentDocumentId=documents[1].Id,ShareType='I');
            insert testCDL2;

            insert contratcTeamList; 


        }                           
    }
    
    @isTest static void testUpdateOwner() {
        system.runas(testUser) {  
         Test.startTest();   
            LC34_AmendContract.allowClone=true;
            list <cTin_ContractTeam__c> ctList = [SELECT id, cTin_Contract__c, cTin_GroupMember__c, cTin_TeamMember__c, 
                                                  cTin_ContractAccessLevel__c 
                                                  from cTin_ContractTeam__c 
                                                  WHERE cTin_Contract__c IN: contractList];  

           ///id grpId=[select id from group where name='cTin_ABE_Genex'].id;

            Contract__Share conshare=new Contract__Share(ParentId = contractList[0].id, 
                                                         UserOrGroupId = testGroup.id, 
                                                         AccessLevel = 'Read');
            insert conshare;

            set<id> contractIds=new set<id>();
            contractIds.add( contractList[0].id);
            contractIds.add( contractList[1].id);

            contractList[0].ownerId = updateOwner.Id;
            contractList[1].ownerId = updateOwner.Id;

            //generate contract form to cater for error 'invalid parent Id' when generating contract form share - deploying to Prod
            list <cTin_ContractForm__c> cf=new list <cTin_ContractForm__c>{
                                            new cTin_ContractForm__c(cTin_Contract__c=contractList[0].id),
                                            new cTin_ContractForm__c(cTin_Contract__c=contractList[1].id)};
            insert cf;                               

                     
            update contractList;
            Test.stopTest();
            //list <Contract__c> clist = [SELECT id,name FROM Contract__c WHERE id =: contractList /*order by name asc*/];
            //system.debug('###clist: '+ clist);
           // list <Contract__Share> cs = [SELECT id, ParentId, Parent.Name, AccessLevel FROM Contract__Share WHERE ParentId IN: contractList /*order by parent.name asc*/];
            //system.debug('###cs: '+ cs);
            //system.assertNOTEquals(cs.size(), null); 

            //AP37_UpdateContractSharing.updateParentcontract(contractIds,updateOwner.id,testUser.id);
           
        }
    }
}