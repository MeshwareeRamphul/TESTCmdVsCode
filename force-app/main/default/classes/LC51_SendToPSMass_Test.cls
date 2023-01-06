@isTest
public class LC51_SendToPSMass_Test {

    static user testUser;
	static user vUserFunctionalAdmin;
    static User vUserPMOADV; 
    static User vUserOO;
    static Account vAccount;
    static Account vEAccount;
    static Contact vEntityContact;
    static Product__c vProduct;
    static Product__c vProduct2;
    static Product__c vProduct3;

    static Contract__c vContract;
    static Contract__c vContract2;
    static Contract__c vContract3;
    static list<Contract__c> lstContracts = new List<Contract__c>();
    static list<Contract__c> lstUpdatedContracts = new list<Contract__c>();

    static Planned_Invoicing_Line__c vInvoicingLine;
    static Planned_Invoicing_Line__c vInvoicingLine2;
    static list<Planned_Invoicing_Line__c> lstInvLines = new list<Planned_Invoicing_Line__c>();

    static String contractIds = '';

    static{

        //testUser = TestFactory.createUserLightning('UsrAdmin',TestFactory.getProfileAdminId(),true, AP_Constant.GS_ENTITY_AXA_GR_OP_HK); // SGO - 09/19 - Added company
        testUser = TestFactory.createUser('UsrFunctionalAdmin',TestFactory.getProfileIdByName(AP_Constant.functionalAdmin),true);
        testUser.PAD_BypassTrigger__c = 'AP01;AP19;AP412;AP51;AP22;';
        testUser.PAD_BypassWorkflows__c = true;
        testUser.PAD_BypassValidationRules__c = false;
        insert testUser;
        vUserFunctionalAdmin = TestFactory.createUser('UsrFunctionalAdmin',TestFactory.getProfileIdByName(AP_Constant.functionalAdmin),true);

        system.runAs(testUser){
            // Create OO user
            vUserPMOADV = AP05_TestDataFactory.createPMOADVUser();
            AP_Constant.themeLightning = true;
            System.debug('//Theme updated:' + UserInfo.getUiThemeDisplayed());
            // Create OO user
            vUserOO = AP05_TestDataFactory.createOOUser();

            // Create the legal entity (aka billing entity) account
            vAccount = AP05_TestDataFactory.createLegalEntityAccount(testUser);

            // Create the entity account
            vEAccount = AP05_TestDataFactory.createEntityAccount(testUser);

            // Create the couple Entity - Billing Entity on Parent Entity
            vAccount = AP05_TestDataFactory.linkLEgalEntityToEntity(vEAccount, vAccount);

            // Create the entity contact related to the account
            vEntityContact = AP05_TestDataFactory.createEntityContact(vAccount);
            
            //Quartile (business area)
            /*vQuartile = AP05_TestDataFactory.createBusinessArea(testUser);

            //Petal (Domain)
            vDomain = AP05_TestDataFactory.createDomain(vQuartile, testUser);

            //Offer
            vOffer = AP05_TestDataFactory.createOffer(vDomain, testUser);*/
            
            // Skip process builder "Post to Chatter product creation & update"
            AutomationSettings__c settings = new AutomationSettings__c(SetupOwnerId = testUser.Id, SkipProcessBuilder__c = true);
            insert settings;
            
            //Products ''Create more than 1 product due to AP50 trigger
            vProduct = AP05_TestDataFactory.createProduct(vUserOO);
            vProduct2 = AP05_TestDataFactory.createProduct(vUserOO, AP_Constant.PRODUCT_STATUS_IDEA, 'TestProduct2');
            vProduct3 = AP05_TestDataFactory.createProduct(vUserOO, AP_Constant.PRODUCT_STATUS_IDEA, 'TestProduct3');

            Master_WBS_Structure__c activityCode1 = AP05_TestDataFactory.createActivityCode('192039');
            activityCode1.GIE_GO_SAS__c = 'AXA Group Operations SAS';
            update activityCode1;
            //Create contracts
            for(Integer i=0; i<20; i++){
                lstContracts.add(AP05_TestDataFactory.createContract(vProduct, vAccount, testUser, vEntityContact, AP_Constant.CONTRACT_STATUS_DRAFT, false )); 
            }
            insert lstContracts;
            for(Contract__c ctr: lstContracts){
                if(contractIds !=''){
                    contractIds += ',';
                }
                contractIds += ctr.Id;
            }

            //Invoicing Line
            for (Contract__c theCon : lstContracts){
                
                lstInvLines.add(AP05_TestDataFactory.createIL(theCon, 50,'Description 1', '01', System.Today(), System.Today().addMonths(4), vEntityContact.Id));
                lstInvLines.add(AP05_TestDataFactory.createIL(theCon, 50,'Description 2', '01', System.Today().addMonths(4), System.Today().addMonths(8), vEntityContact.Id));
                

               /* vInvoicingLine2 = AP05_TestDataFactory.createPInvoicingLineAdmin(theCon, 'TestInvLine2', 'Testing error message');
                vInvoicingLine2.Master_WBS_Structure__c = theCon.Master_WBS_2__c;
                lstInvLines.add(vInvoicingLine2);*/
            }

            insert lstInvLines;
            activityCode1.Active__c = false;
            update activityCode1;
            /*Master_WBS_Structure__c activityCode2 = AP05_TestDataFactory.createActivityCode('192040');
            activityCode2.GIE_GO_SAS__c = 'GIE AXA Group Operations France';
            update activityCode2;
            lstContracts[0].Master_WBS_2__c = activityCode2.Id;
            lstContracts[0].Status__c = AP_Constant.CONTRACT_STATUS_SENT_FOR_SIGNATURE;
            update lstContracts[0];*/
        }
    }

    @IsTest
    public static void testSendUnauthorised(){
        System.runAs(vUserPMOADV) {
            test.StartTest();
                Map<String, Object> result = LC51_SendToPSMass.checkStatus('');
                System.assertEquals(System.Label.LC05_HaveNoSufficientRights, result.get('error'));
            test.StopTest();
        }
    }

	@isTest
    public static void testSendNoContract(){
        system.runAs(vUserFunctionalAdmin){
            Test.startTest();
                Map<String, Object> result = LC51_SendToPSMass.checkStatus('');
                System.assertEquals(System.Label.LC51_SelectAtLeastONe, result.get('error'));
            Test.stopTest();
        }
    }

	@isTest
    public static void testSendContractStatusDraft(){
        system.runAs(vUserFunctionalAdmin){
            Test.startTest();
                Map<String, Object> result = LC51_SendToPSMass.checkStatus(contractIds);
                System.assertEquals(System.Label.LC51_SelectRightListView, result.get('error'));
            Test.stopTest();
        }
    }

	@isTest
    public static void testSendContractMorethan20(){
        system.runAs(vUserFunctionalAdmin){
            Test.startTest();
                vContract = AP05_TestDataFactory.createContractAdmin('Test 356 v21', vProduct, vAccount, vUserOO, vEntityContact);
                vContract.Global_Amount__c = 100;
                insert vContract;
                lstContracts.add(vContract);

                contractIds = '';
                for(Contract__c ctr: lstContracts){
                    if(contractIds !=''){
                        contractIds += ',';
                    }
                    contractIds += ctr.Id;
                }
                Map<String, Object> result = LC51_SendToPSMass.checkStatus(contractIds);
                System.assertEquals(System.Label.LC51_ValidateSelection, result.get('error'));
            Test.stopTest();
        }
    }
    

	@isTest
    public static void testContractIsSending(){
        system.runAs(vUserFunctionalAdmin){
            Test.startTest();
                lstContracts[0].Status__c = AP_Constant.CONTRACT_STATUS_SENT_FOR_SIGNATURE;
                lstContracts[0].Tech_isSendingToPS__c = true;
                lstContracts[0].Tech_TriggerFilter__c = true;
                update lstContracts[0];
                contractIds = lstContracts[0].Id;
                Map<String, Object> result = LC51_SendToPSMass.checkStatus(contractIds);
                System.assertEquals(System.Label.LC51_ContractIsSending, result.get('error'));
            Test.stopTest();
        }
    }
    

	@isTest
    public static void testNoILToSend(){
        system.runAs(vUserFunctionalAdmin){
            Test.startTest();
                lstContracts[0].Status__c = AP_Constant.CONTRACT_STATUS_SENT_FOR_SIGNATURE;
                update lstContracts[0];
                contractIds = lstContracts[0].Id;
                lstInvLines = [SELECT Id FROM Planned_Invoicing_Line__c WHERE Contract2__c = :contractIds];
                delete lstInvLines;
                Map<String, Object> result = LC51_SendToPSMass.checkStatus(contractIds);
                System.assertEquals(System.Label.LC51_SelectRightListView, result.get('error'));
            Test.stopTest();
        }
    }
    

	@isTest
    public static void testNoNewInformationToSend(){
        system.runAs(vUserFunctionalAdmin){
            
            /*contractIds = lstContracts[0].Id;
            lstInvLines = [SELECT Id, Status__c, Contract2__r.Name, Master_WBS_Structure__r.GIE_GO_SAS__c FROM Planned_Invoicing_Line__c WHERE Contract2__c = :lstContracts[0].Id];
            String manageSyncIL = '';
            for(Planned_Invoicing_Line__c pil : lstInvLines){
                pil.Status__c = System.label.InvLineStatusCancelled;
                if(manageSyncIL == ''){
                    manageSyncIL += pil.Id;
                }else{
                    manageSyncIL += ','+ pil.Id;
                }
            }
            lstContracts[0].Manage_Sync_ILs__c = manageSyncIL;
            lstContracts[0].Status__c = AP_Constant.CONTRACT_STATUS_SENT_FOR_SIGNATURE;
            update lstContracts;*/


            lstContracts[0].Status__c = AP_Constant.CONTRACT_STATUS_SENT_FOR_SIGNATURE;
            update lstContracts[0];

            lstInvLines = [SELECT Id, Status__c, Contract2__r.Name, Master_WBS_Structure__r.GIE_GO_SAS__c FROM Planned_Invoicing_Line__c WHERE Contract2__c = :lstContracts[0].Id];
            for(Planned_Invoicing_Line__c pil : lstInvLines){
                pil.Status__c = System.label.InvLineStatusCancelled;
            }

            contractIds = lstContracts[0].Id;
            update lstInvLines;
            system.debug('****status '+lstInvLines[0].Status__c);
            Test.startTest();
                Map<String, Object> result = LC51_SendToPSMass.checkStatus(contractIds);
                System.assertEquals(System.Label.LC51_NoNewInformationToSend, result.get('error'));
            Test.stopTest();
        }
    }
    

	@isTest
    public static void testNoNewInfoToSendContract(){
        system.runAs(vUserFunctionalAdmin){
            Test.startTest();
                lstContracts[0].Status__c = AP_Constant.CONTRACT_STATUS_SENT_FOR_SIGNATURE;
                lstContracts[1].Status__c = AP_Constant.CONTRACT_STATUS_SENT_FOR_SIGNATURE;
                lstContracts[2].Status__c = AP_Constant.CONTRACT_STATUS_SENT_FOR_SIGNATURE;
                update lstContracts;

                contractIds = lstContracts[0].Id+','+lstContracts[1].Id+','+lstContracts[2].Id;
                lstInvLines = [SELECT Id FROM Planned_Invoicing_Line__c WHERE Contract2__c = :lstContracts[2].Id];
                for(Planned_Invoicing_Line__c pil : lstInvLines){
                    pil.Status__c = System.label.InvLineStatusCancelled;
                }
                update lstInvLines;
                Map<String, Object> result = LC51_SendToPSMass.checkStatus(contractIds);
                System.assertEquals(System.Label.LC51_SelectRightListView, result.get('error'));
            Test.stopTest();
        }
    }
    

	@isTest
    public static void testChooseActivityCodeContract(){
                
        // vUserFunctionalAdmin.PAD_BypassValidationRules__c = false;
        // update vUserFunctionalAdmin;
        system.runAs(vUserFunctionalAdmin){
            
            Test.startTest();
                contractIds = lstContracts[0].Id;
                lstInvLines = [SELECT Id, Contract2__r.Name, Master_WBS_Structure__r.GIE_GO_SAS__c FROM Planned_Invoicing_Line__c WHERE Contract2__c = :contractIds];
                Map<String, Object> result = LC51_SendToPSMass.sendToPS(contractIds);
                //System.assertEquals(System.Label.LC51_ChooseActivityCodeContract+' "'+lstInvLines[0].Contract2__r.Name+'".', result.get('error'));
            Test.stopTest();
            System.debug('*** '+lstContracts[0].Master_WBS_2__r.GIE_GO_SAS__c+' *** '+lstInvLines[0].Master_WBS_Structure__r.GIE_GO_SAS__c);
        }
    }
    

	@isTest
    public static void testSendToPS(){
                
        system.runAs(vUserFunctionalAdmin){
            
            Test.startTest();
                for(Contract__c ctr : lstContracts){
                    ctr.Status__c = AP_Constant.CONTRACT_STATUS_SENT_FOR_SIGNATURE;
                }
                update lstContracts;
                Map<String, Object> result = LC51_SendToPSMass.sendToPS(contractIds);
                System.assertEquals(null, result.get('error'));
                Contract__c cont = [Select id,PeopleSoftConnectionMessage__c  from Contract__c where Id = :lstContracts[0].Id];
                
                test.StopTest();
            //System.assertEquals('Connection to PeopleSoft OK', cont.PeopleSoftConnectionMessage__c);
        }
    }
}