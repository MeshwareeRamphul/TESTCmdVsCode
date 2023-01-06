@isTest
private class AP33_GrantVisibilityContract_Test {
/* 
--------------------------------------------------------------------------------------
-- - Name          : AP03_GrantVisibilityContract
-- - Author        : Spoon Consulting 
-- - Description   : Grant visibility to Parent Contract
--
-- Maintenance History: 
--
-- Date         Name  Version  Remarks 
-- -----------  ----  -------  -------------------------------------------------------
-- 24-DEC-2015  NJA    1.0     Initial version
*************************************************************************************/
    static User use; 
    static User currentUser;
    static Account supplier; 
    static cTin_Entity__c entity;
    static list<Contract__c> contracts; 
    static Group testGroup ;
    static list<cTin_ContractTeam__c> contractTeams;
    static Map<String,ID> MapContactRT = new Map<String,ID>(); 
    static Map<String,ID> MapAccRT = new Map<String,ID>(); 
    static Account AxaAcc;
    static Contact AxaREP;
    static Contact AxaSUP;

    static{
        use = TestFactory.createUser('TestUser' , UserInfo.getProfileId(), true);
        insert use;

        System.runAs(use){

            currentUser =[Select id,Name, cTin_EntityLocalCode__c,Email from User where id =: UserInfo.getUserId()] ;

            MapAccRT = TestFactory.MapRecordType('Account');

            MapContactRT = TestFactory.MapRecordType('Contact');
            
            AxaAcc = TestFactory.createSupplier('Test Supplier', 'Florange', 'France');
            AxaAcc.RecordTypeId = MapAccRT.get('cTin_AXA') ;
            insert AxaAcc;

            AxaREP= TestFactory.createContact(AxaAcc, 'TestFname' , 'TestlName');
            AxaREP.RecordTypeID = MapContactRT.get('cTin_AXA');
            AxaREP.cTin_RelatedUser__c = use.Id;
            AxaREP.cTin_LegalRepresentative__c = true;
            AxaREP.MobilePhone = '+212667849903';
            AxaREP.cTin_Active__c = true;
            insert AxaREP;

            supplier = TestFactory.createSupplier('Test Supplier', 'Florange', 'France');
            insert supplier; 

            AxaSUP = TestFactory.createContact(supplier, 'TestFname 1', 'TestLname 1');
            AxaSUP.RecordTypeID = MapContactRT.get('cTin_Supplier');
            AxaSUP.cTin_RelatedUser__c = use.Id;
            AxaSUP.cTin_LegalRepresentative__c = true;
            AxaSUP.MobilePhone = '+2126655565645';
            AxaSUP.cTin_Active__c = true;
            AxaSUP.email ='elhaddad.amine@gmail.com' ; 
            AxaSUP.FirstName='Amine' ; 
            AxaSUP.LastName = 'ElHaddad' ; 
            insert AxaSUP;

            entity = TestFactory.createEntity();
            insert entity;

            contracts = new list<Contract__c>{ 
                new Contract__c(Name = 'Test Contract__c', 
                    Status__c = 'In Signature', 
                    cTin_TypeofDocument__c = 'Contract', 
                    cTin_BusinessOwner__c = UserInfo.getUserId(),  
                    cTin_ShortDescription__c = 'Test Description', 
                    StartDate__c = Date.today(), 
                    EndDate__c = Date.today(), 
                    cTin_Reminder__c = 'None',
                    cTin_FinancialEngagement__c = 'No', 
                    cTin_SupplierAccount__c = supplier.id, 
                    cTin_CRClause__c = 'Standard',
                    cTin_AntiBriberyClause__c = 'Standard', 
                    cTin_TerminationClause__c ='Standard', 
                    OwnerId = UserInfo.getUserId(), 
                    cTin_ProcurementInvolvementGrade__c = 'Level 1 - Challenge spend & negotiate', 
                    cTin_FairTransparentSelectionProcess__c = 'No',
                    cTin_MainAPCL2__c='1103-Towing',
                    cTin_eSourcingReferenceId__c = 'WS111111111', 
                    cTin_AXAMainLegalSignatoryEntity__c= entity.Id, 
                    cTin_SupplierSignatoryRepresentative__c = AxaSUP.Id,
                    cTin_AXASignatoryRepresentative__c = AxaREP.Id,
                    recordtypeId=Schema.SObjectType.Contract__c.getRecordTypeInfosByName().get('Contract In Progress').getRecordTypeId())
            };
            insert contracts;

            ContractTriggerHandler.hasExecutedafterUpdateHandler = false;

            testGroup = new Group(Name = 'testGroup',
                                DeveloperName = 'ABC');
            Insert testGroup;
            
            contractTeams = new list<cTin_ContractTeam__c>{
                TestFactory.createContractTeamGroupMember(system.label.cTin_role_legal_rep, contracts[0].Id, 'testGroup', '1', 'Read'),
                new cTin_ContractTeam__c(cTin_Role__c = system.label.cTin_role_business_owner, cTin_Contract__c = contracts[0].Id, cTin_GroupMember__c = 'testGroup', cTin_ContractAccessLevel__c = 'Read')
            };
        }
 
    }   
    static  testMethod void test_insert_team_member() {
        System.runAs(use){
            Contract__c c;
            c = new Contract__c(Name = 'Test Contract__c', 
                                Status__c = 'In Signature', 
                                cTin_TypeofDocument__c = 'Contract', 
                                cTin_BusinessOwner__c = UserInfo.getUserId(),
                                cTin_ParentContract__c = contracts[0].Id, 
                                cTin_ShortDescription__c = 'Test Description', 
                                StartDate__c = Date.today(), 
                                EndDate__c = Date.today(), 
                                cTin_Reminder__c = 'None', 
                                cTin_FinancialEngagement__c = 'No', 
                                cTin_SupplierAccount__c = supplier.id, 
                                cTin_CRClause__c = 'Standard',
                                cTin_AntiBriberyClause__c = 'Standard', 
                                cTin_TerminationClause__c ='Standard', 
                                OwnerId = UserInfo.getUserId(), 
                                cTin_ProcurementInvolvementGrade__c = 'Level 1 - Challenge spend & negotiate', 
                                cTin_FairTransparentSelectionProcess__c = 'No',
                                cTin_MainAPCL2__c='1103-Towing', 
                                cTin_eSourcingReferenceId__c = 'WS111111111', 
                                cTin_AXAMainLegalSignatoryEntity__c= entity.Id, 
                                cTin_SourcingDomain__c = 'Market Data',
                                recordtypeId=Schema.SObjectType.Contract__c.getRecordTypeInfosByName().get('Contract In Progress').getRecordTypeId());
 
            insert c; 

            ContractTriggerHandler.hasExecutedafterUpdateHandler = false; 
  
        
            cTin_ContractTeam__c ct = new cTin_ContractTeam__c();
            ct.cTin_Contract__c = c.Id;
            ct.cTin_Role__c = system.label.cTin_role_legal_rep;
            ct.cTin_TeamMember__c = use.Id;
            ct.cTin_ContractAccessLevel__c = 'Read';

            test.startTest();
                insert ct;
            test.stopTest();

            //select legal rep
            list<cTin_ContractTeam__c> conParent = [Select cTin_Role__c, cTin_TeamMember__c, cTin_GroupMember__c 
                                                      From cTin_ContractTeam__c 
                                                     Where cTin_Contract__c = :contracts[0].Id 
                                                       And cTin_Role__c = :system.label.cTin_role_legal_rep];

            list<cTin_ContractTeam__c> conChild = [Select cTin_Role__c, cTin_TeamMember__c, cTin_GroupMember__c 
                                                     from cTin_ContractTeam__c 
                                                    where cTin_Contract__c = :c.Id];

            system.debug('## conChild: '+conChild);
            system.debug('## conParent: '+conParent);
            
            system.assertEquals(ct.cTin_TeamMember__c, conParent[0].cTin_TeamMember__c);
        }
    }

    
    static testMethod void test_insert_group_member() {
        System.runAs(use){

            //Contract__c c = new Contract__c(Name = 'Test Contract__c', Status__c = 'In Progress', cTin_TypeofDocument__c = 'Contract', 
            //                                        cTin_BusinessOwner__c = UserInfo.getUserId(),
            //                                        cTin_ParentContract__c = contracts[1].Id, 
            //                                        cTin_ShortDescription__c = 'Test Description', StartDate__c = Date.today(), 
            //                                        EndDate__c = Date.today(), 
            //                                        cTin_Reminder__c = 'None', cTin_FinancialEngagement__c = 'No', 
            //                                        cTin_SupplierAccount__c = supplier.id, 
            //                                        cTin_CRClause__c = 'Standard',
            //                                        cTin_AntiBriberyClause__c = 'Standard', cTin_TerminationClause__c ='Standard', 
            //                                        OwnerId = UserInfo.getUserId(), 
            //                                        cTin_ProcurementInvolvementGrade__c = 'Level 1 - Challenge spend & negotiate', 
            //                                        cTin_FairTransparentSelectionProcess__c = 'No',
            //                                        cTin_MainAPCL2__c='1103-Towing', cTin_eSourcingReferenceId__c = 'WS111111111', 
            //                                        cTin_AXAMainLegalSignatoryEntity__c= entity.Id);
            //insert c;   

            //ContractTriggerHandler.hasExecutedafterUpdateHandler = false; 
            
            Contract__c c;
            c = new Contract__c(Name = 'Test Contract__c', 
                                Status__c = 'In Signature', 
                                cTin_TypeofDocument__c = 'Contract', 
                                cTin_BusinessOwner__c = UserInfo.getUserId(),
                                cTin_ParentContract__c = contracts[0].Id, 
                                cTin_ShortDescription__c = 'Test Description', 
                                StartDate__c = Date.today(), 
                                EndDate__c = Date.today(), 
                                cTin_Reminder__c = 'None', 
                                cTin_FinancialEngagement__c = 'No', 
                                cTin_SupplierAccount__c = supplier.id, 
                                cTin_CRClause__c = 'Standard',
                                cTin_AntiBriberyClause__c = 'Standard', 
                                cTin_TerminationClause__c ='Standard', 
                                OwnerId = UserInfo.getUserId(), 
                                cTin_ProcurementInvolvementGrade__c = 'Level 1 - Challenge spend & negotiate', 
                                cTin_FairTransparentSelectionProcess__c = 'No',
                                cTin_MainAPCL2__c='1103-Towing', 
                                cTin_eSourcingReferenceId__c = 'WS111111111', 
                                cTin_AXAMainLegalSignatoryEntity__c= entity.Id, 
                                cTin_SourcingDomain__c = 'Market Data',
                                recordtypeId=Schema.SObjectType.Contract__c.getRecordTypeInfosByName().get('Contract In Progress').getRecordTypeId());
 
            insert c; 

            ContractTriggerHandler.hasExecutedafterUpdateHandler = false; 

            contractTeams[1].cTin_Contract__c = c.Id;
            test.startTest();
                insert contractTeams[1];
            test.stopTest();
            
           // ContractTriggerHandler.dummy_Test();

            //list<cTin_ContractTeam__c> conParent = [Select cTin_Role__c, cTin_TeamMember__c, cTin_GroupMember__c 
            //                                          From cTin_ContractTeam__c 
            //                                         Where cTin_Contract__c = :c.Id 
            //                                           And cTin_Role__c = '016'];

            //system.assertEquals(contractTeams[0].cTin_GroupMember__c, conParent[0].cTin_GroupMember__c);
        }
    }
    
    /*
    static  testMethod void test_update_parent() {
        System.runAs(use){
            contracts[1].cTin_ParentContract__c = contracts[0].Id;
            test.startTest();
                update contracts[1];
            test.stopTest();
        }
    }

    static  testMethod void test_update_GroupMember() {
        System.runAs(use){
            contractTeams[0].cTin_Contract__c = contracts[1].Id;
            contractTeams[0].cTin_Role__c = system.label.cTin_role_business_owner;
            //contractTeams[0].cTin_Contract__c = contracts[1].Id;
            contractTeams[0].cTin_GroupMember__c = 'AIM IT Procurement';
            contractTeams[0].cTin_ApprovalOrder__c='Not in Approval Process';
            update contractTeams[0];

            Contract__c c = new Contract__c(Name = 'Test Contract__c', Status__c = 'Draft', cTin_TypeofDocument__c = 'Contract', 
                                                    cTin_BusinessOwner__c = UserInfo.getUserId(),
                                                    cTin_ParentContract__c = contracts[1].Id, 
                                                    cTin_ShortDescription__c = 'Test Description', StartDate__c = Date.today(), 
                                                    EndDate__c = Date.today(), 
                                                    cTin_Reminder__c = 'None', cTin_FinancialEngagement__c = 'No', 
                                                    cTin_SupplierAccount__c = supplier.id, 
                                                    cTin_CRClause__c = 'Standard',
                                                    cTin_AntiBriberyClause__c = 'Standard', cTin_TerminationClause__c ='Standard', 
                                                    OwnerId = UserInfo.getUserId(), 
                                                    cTin_ProcurementInvolvementGrade__c = 'Level 1 - Challenge spend & negotiate', 
                                                    cTin_FairTransparentSelectionProcess__c = 'No',
                                                    cTin_MainAPCL2__c='1103-Towing', cTin_eSourcingReferenceId__c = 'WS111111111', 
                                                    cTin_AXAMainLegalSignatoryEntity__c= entity.Id,
                                                    recordTypeId=Schema.SObjectType.Contract__c.getRecordTypeInfosByName().get('Contract Draft').getRecordTypeId() );
            insert c; 

            ContractTriggerHandler.hasExecutedafterUpdateHandler = false; 

            c.cTin_ParentContract__c=contracts[1].id;


            test.startTest();
                //AP33_GrantVisibilityContract.executeTest=true;
                update c;
            test.stopTest();
        }
    }
    
    static  testMethod void test_existing_contractTeam() {
        System.runAs(use){

            contractTeams[0].cTin_Contract__c = contracts[1].Id;
            update contractTeams[0];

            Contract__c c = new Contract__c(Name = 'Test Contract__c', Status__c = 'In Progress', cTin_TypeofDocument__c = 'Contract', 
                                                    cTin_BusinessOwner__c = UserInfo.getUserId(),
                                                    cTin_ParentContract__c = contracts[1].Id, 
                                                    cTin_ShortDescription__c = 'Test Description', StartDate__c = Date.today(), 
                                                    EndDate__c = Date.today(), 
                                                    cTin_Reminder__c = 'None', cTin_FinancialEngagement__c = 'No', 
                                                    cTin_SupplierAccount__c = supplier.id, 
                                                    cTin_CRClause__c = 'Standard',
                                                    cTin_AntiBriberyClause__c = 'Standard', cTin_TerminationClause__c ='Standard', 
                                                    OwnerId = UserInfo.getUserId(), 
                                                    cTin_ProcurementInvolvementGrade__c = 'Level 1 - Challenge spend & negotiate', 
                                                    cTin_FairTransparentSelectionProcess__c = 'No',
                                                    cTin_MainAPCL2__c='1103-Towing', cTin_eSourcingReferenceId__c = 'WS111111111', 
                                                    cTin_AXAMainLegalSignatoryEntity__c= entity.Id);
            insert c; 

            ContractTriggerHandler.hasExecutedafterUpdateHandler = false;

            cTin_ContractTeam__c ct = new cTin_ContractTeam__c();
            ct = contractTeams[0].clone();
            ct.cTin_Contract__c = c.Id;

            test.startTest();
                insert ct;
            test.stopTest();
        }
    }*/
}