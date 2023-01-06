@istest
private class AP36_UpdateParentContractTest {
/*
// AP04_UpdateParentContractTest
----------------------------------------------------------------------
-- - Name          : AP04_UpdateParentContractTest
-- - Author        : Spoon Consulting 
-- - Description   : Test class AP04_UpdateParentContract
                                         
--                                       
-- Maintenance History:
--
-- Date         Name  Version  Remarks
-- -----------  ----  -------  ---------------------------------------
-- 21-JAN-2016  RLA    1.0      Intitial version
-- 10-DEC-2021  MBE    1.1      Reworked for Coverage Error
----------------------------------------------------------------------
**********************************************************************
*/

static User use, use1;
	static Account supplier;
	static cTin_Entity__c entity;
	static string role_legal_rep;
	static string role_business_owner;
	static set <id> contractIds =  new Set<id>();
	static Contract__c contract1;
	static Contract__c contract;
	static ContentVersion testCV = new ContentVersion();
    static ContentDistribution testCD = new ContentDistribution();
	static {
		role_legal_rep = '009';
		role_business_owner = '016';
		use = TestFactory.createUser('u1', UserInfo.getProfileId(), true);
		use.Bypass_FieldFilter__c = true;
		use.PAD_BypassTrigger__c = 'AP22';
		insert use;
		System.runAs(use){
	
			use1 = TestFactory.createUser('u2' , UserInfo.getProfileId(), true);
            use1.PAD_BypassTrigger__c = 'AP22';
			insert use1;

			supplier = TestFactory.createSupplier('TestSupplier' , 'City', 'France');
			insert supplier;

			entity = TestFactory.createEntity();
			insert entity;

			//creating contract1
			contract = TestFactory.createContract(supplier.Id, 'testContract', 'Draft');
			insert contract;

			testCV = TestFactory.createContentVersion('Google.com', 'test.pdf', 'test', false);
            testCV.sign_able__c = true;
            insert testCV;
            
            testCD=TestFactory.createContentDistribution(testCV.id, testCV.title, contract.Id);          
            insert testCD;

			List<ContentDocument> documents = [SELECT Id, Title, LatestPublishedVersionId,description FROM ContentDocument];

            contentDocumentLink testCDL = new contentDocumentLink(LinkedEntityId = contract.Id ,ContentDocumentId=documents[0].Id,ShareType='I');
            insert testCDL;
			
			ContractTriggerHandler.hasExecutedafterUpdateHandler = false;

			Group testGroup = new Group(Name = 'testGroup', 
										DeveloperName = 'ABC');
			Insert testGroup;

			cTin_ContractTeam__c ContractTeam = TestFactory.createContractTeamMember(role_legal_rep, contract.Id, use.Id,'1', 'Read');
			insert ContractTeam;

			cTin_LegalEntity__c legalEntity = TestFactory.createLegalEntity(contract.id, entity.id);
			insert legalEntity;

			cTin_Location__c Location = TestFactory.createLocation(contract.id);
			insert Location;
		}
	}

	static testmethod void testingTrigger(){

		System.runAs(use1){

			contract1 = new Contract__c(Name = 'Test Contract1', 
										Status__c = 'In Approval', 
										cTin_TypeofDocument__c = 'Agreement', 
										cTin_BusinessOwner__c = UserInfo.getUserId(),
										cTin_ShortDescription__c = 'Test Description', 
										StartDate__c = Date.today(), 
										EndDate__c = Date.today(),										
										cTin_FinancialEngagement__c = 'No',
										cTin_SupplierAccount__c = supplier.id, 
										cTin_CRClause__c = 'Standard',
										cTin_AntiBriberyClause__c = 'Standard', 
										cTin_TerminationClause__c ='Standard', 
										OwnerId = UserInfo.getUserId(),
										cTin_ProcurementInvolvementGrade__c = 'Level 1 - Challenge spend & negotiate', 
										cTin_FairTransparentSelectionProcess__c = 'No',
										cTin_eSourcingReferenceId__c = 'WS111111111', 
										cTin_AXAMainLegalSignatoryEntity__c= entity.Id,
										cTin_ParentContract__c=contract.id,
										cTin_ContractSegment__c = 'Strategic',
										cTin_MainAPCL0__c = '1-Insurance Procurement',
										cTin_MainAPCL1__c = '11-Motor',
										cTin_MainAPCL2__c = '1102-Motor engineering',
										cTin_MainAPCL3__c = '120301-Drugs - generic products',
										cTin_OrganizationalScope__c = '	001 - AXA All Entities',
                                        cTin_Reminder__c= 'N/A',
										recordtypeId=Schema.SObjectType.Contract__c.getRecordTypeInfosByName().get('Contract Draft').getRecordTypeId());
			insert contract1;

			ContractTriggerHandler.hasExecutedafterUpdateHandler = false;

			contract1.OwnerId = UserInfo.getUserId();
			contract1.Status__c = label.cTin_triggerStatus;
			contract1.cTin_TypeOfDocument__c = label.cTin_AmendTypeOfDoc;
			
			test.startTest();				
				update contract1;
			Test.stopTest();

			System.debug('>### contract : ' + contract);
			System.debug('>### contract1 : ' + contract1); 

			List<Contract__c> conList = [SELECT Id, status__c, EndDate__c
											FROM Contract__c
											WHERE id = :contract.id];
			System.debug('##contract List:'+conList);
		}
	}

 }