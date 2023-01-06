@isTest
private class AP12_Contract_Test {

    static PDFContractAttached__c pdfContractAttached;
    static User vUserPM1,vUserPM;
    static Product__c vProduct1;
    static ProductItem__c vPItem1;
    static ProductItem__c vPItem2;
    static ProductItem__c vPItem3;
    static ProductItem__c vPItem4;
    static Account vLegalEntity1;
    static Contact vEntityContact1;
    static Contact vEntityContact2;
    static Contact vEntityContact3;
    static Contact vEntityContact4;
    static Contact vEntityContact5;
    static Account vLEntity1;
    static Account vEntity1;
    static Account vMEntity1;
    static Account vEAccount;
    static Product__c vProduct;
    static List<Opportunity> lstOpp;
    static List<Contract__c> lstContract;
    static List<ProductItem__c> lstPItems;
    static Planned_Invoicing_Line__c vPlannedInvLine;
    static Planned_Invoicing_Line__c vPInvLine0;
    static Planned_Invoicing_Line__c vPInvLine1;
    static Planned_Invoicing_Line__c vPInvLine2;
    static Planned_Invoicing_Line__c vPInvLine3;
    static Planned_Invoicing_Line__c vPInvLine4;
    static List<Planned_Invoicing_Line__c> lstPIL = new List<Planned_Invoicing_Line__c>();
    static Map<Id, String> mapOppStatus;
    static Map<Id, Contract__c> mapContracts;
    static list<Contact> contactLst = new list<Contact>();
    static Planned_Invoicing_Line__c pInvLine;
    static Opportunity vOpp1;
    static Opportunity vOpp2;
    static Opportunity vOpp3;
    static Contract__c contract;
    static Contract__c vContract;
    static Contract__c vContract1;
    static Contract__c vContract2;
    static Contract__c vContract3;
    static Contract__c vContract4;
    static Contract__c vContract5;
    static Contract__c vContract6;
    static Master_WBS_Structure__c vMasterWBS_2;
    static User adminUser;

    static{
        /*adminUser = new User();
        adminUser.Alias = 'admin';
        adminUser.FirstName = 'adminUser';
        adminUser.LastName = 'adminUser';
        adminUser.Username = AP05_TestDataFactory.getUniqueUserName(); //'userAdmin@User.com';
        adminUser.Email = 'userAdmin@User.com';
        adminUser.EmailEncodingKey = 'ISO-8859-1';
        adminUser.TimeZoneSidKey = 'Europe/Paris';
        adminUser.LanguageLocaleKey = 'en_US';
        adminUser.LocaleSidKey = 'fr_FR_EURO';
        adminUser.ProfileId = AP_Constant.getProfileIdAdmin();
        insert adminUser;*/
        
        adminUser = TestFactory.createUser('UsrAdmin',TestFactory.getProfileAdminId(),true);
        adminUser.cTin_Universign__c = true;
        adminUser.Bypass_FieldFilter__c = true;
        adminUser.PAD_BypassWorkflows__c = true;
        insert adminUser;
        
        vUserPM = AP05_TestDataFactory.createPMUser(true);
        update vUserPM;
        

        System.runAs(adminUser) {

            // Create OO user
            User vUserOO = AP05_TestDataFactory.createOOUser();
            
            // Create the entity account
            vEAccount = AP05_TestDataFactory.createEntityAccount(vUserPM);
            
            //Quartile (business area)
            /*vQuartile = AP05_TestDataFactory.createBusinessArea(vUserPM);

            //Petal (Domain)
            vDomain = AP05_TestDataFactory.createDomain(vQuartile, vUserPM);

            // Offer
            vOffer = AP05_TestDataFactory.createOffer(vDomain, vUserPM);*/

            // Skip process builder "Post to Chatter product creation & update"
            AutomationSettings__c settings = new AutomationSettings__c(SetupOwnerId = adminUser.Id, SkipProcessBuilder__c = true);
            insert settings;

            //Product
            vProduct = AP05_TestDataFactory.createProduct(/*vOffer,*/ vUserOO);

            AccountModification_Flag__c accModifFlag = new AccountModification_Flag__c(SetupOwnerId=vUserPM.Id, Flag__c=true, Show_In_POS_Flag__c =false);
            insert accModifFlag;

            vUserPM1 = [SELECT Id FROM USER WHERE UserName = :AP05_TestDataFactory.USER_PM_USERNAME LIMIT 1];

            // Get the offer
            vProduct1 = [SELECT Id, OwnerId FROM Product__c WHERE Name = :AP05_TestDataFactory.PRODUCT_NAME];

            // Create the customer (aka entity) account
            vLEntity1 = AP05_TestDataFactory.createLegalEntityAccount(vUserPM1, AP05_TestDataFactory.ACCOUNT_NAME);

            // Create the entity account
            vEntity1 = AP05_TestDataFactory.createEntityAccount(vUserPM1, 'testEntity');

            // Create the master entity account
            vMEntity1 = AP05_TestDataFactory.createMasterEntityAccount(vUserPM1, 'Master Entity');

            // Get the legal entity
            vLegalEntity1 = [SELECT Id, OwnerID FROM Account WHERE Name = :AP05_TestDataFactory.ACCOUNT_NAME];

            // Create the entity contact related to the account
            vEntityContact1 = AP05_TestDataFactory.createEntityContact(vLegalEntity1);
            vEntityContact2 = AP05_TestDataFactory.createEntityContact(vLegalEntity1, 'entitycontact@test2.com', 'name2');
            vEntityContact3 = AP05_TestDataFactory.createEntityContact(vLegalEntity1, 'entitycontact@test3.com', 'name3');
            vEntityContact4 = AP05_TestDataFactory.createEntityContact(vLegalEntity1, 'entitycontact@test4.com', 'name4');
            vEntityContact5 = AP05_TestDataFactory.createEntityContact(vLegalEntity1, 'entitycontact@test5.com', 'name5');

            //Master WBS
            //createActivityCode
            vMasterWBS_2 = AP05_TestDataFactory.createActivityCode('L22FS_FM_000025', AP05_TestDataFactory.CONTRACT_LEGAL_ENTITY);
            
            //Create an attached file
            pdfContractAttached = new PDFContractAttached__c();
            pdfContractAttached.PDFStatus__c = 'Updated';
            insert pdfContractAttached;
            
            // Create contracts
            lstContract = new List<Contract__c>();
            vContract1 = AP05_TestDataFactory.createContract(vProduct1, vLegalEntity1, vUserPM, vEntityContact1, AP_Constant.CONTRACT_STATUS_DRAFT, false);
            vContract1.RecordTypeId = ContractTriggerHandler.idRecOpCoSingleEdit;
            vContract1.Global_Amount__c = 500;
            vContract1.PDFContrAtt__c = pdfContractAttached.id;
            lstContract.add(vContract1);
            
            vContract2 = AP05_TestDataFactory.createContract(vProduct1, vLegalEntity1, vUserPM, vEntityContact1, AP_Constant.CONTRACT_STATUS_DRAFT, false);
            vContract2.RecordTypeId = ContractTriggerHandler.idRecOpCoSingleEdit;
            vContract2.Global_Amount__c = 500;
            vContract2.PDFContrAtt__c = pdfContractAttached.id;
            lstContract.add(vContract2);
            
            vContract3 = AP05_TestDataFactory.createContract(vProduct1, vLegalEntity1, vUserPM, vEntityContact1, AP_Constant.CONTRACT_STATUS_DRAFT, false);
            vContract3.RecordTypeId = ContractTriggerHandler.idRecOpCoAmendEdit;
            vContract3.Global_Amount__c = 500;
            vContract3.PDFContrAtt__c = pdfContractAttached.id;
            lstContract.add(vContract3);
            
            vContract4 = AP05_TestDataFactory.createContract(vProduct1, vLegalEntity1, vUserPM, vEntityContact1, AP_Constant.CONTRACT_STATUS_DRAFT, false);
            vContract4.RecordTypeId = ContractTriggerHandler.idRecOpCoAmendEdit;
            vContract4.Global_Amount__c = 500;
            vContract4.PDFContrAtt__c = pdfContractAttached.id;
            lstContract.add(vContract4);

            vContract5 = AP05_TestDataFactory.createContract(vProduct1, vLegalEntity1, vUserPM, vEntityContact1, AP_Constant.CONTRACT_STATUS_DRAFT, false);
            vContract5.RecordTypeId = ContractTriggerHandler.idRecOpCoAmendEdit;
            vContract5.Global_Amount__c = 500;
            vContract5.PDFContrAtt__c = pdfContractAttached.id;
            vContract5.Customer_Operational_Contact__c = vEntityContact1.Id;
            vContract5.CustomerSignedBy__c = vEntityContact2.Id;
            vContract5.CustomerSignedBy2__c = vEntityContact3.Id;
            vContract5.AXA_GS_Signed_By__c = vEntityContact4.Id;
            vContract5.AXA_GO_Signed_By_2__c = vEntityContact5.Id;
            lstContract.add(vContract5);

            insert lstContract;

            vContract6 = AP05_TestDataFactory.createContract(vProduct1, vLegalEntity1, vUserPM, vEntityContact1, AP_Constant.CONTRACT_STATUS_DRAFT, false);
            vContract6.RecordTypeId = ContractTriggerHandler.idRecOpCoAmendEdit;
            vContract6.Global_Amount__c = 500;
            vContract6.PDFContrAtt__c = pdfContractAttached.id;
            vContract6.Customer_Operational_Contact__c = vEntityContact1.Id;
            vContract6.CustomerSignedBy__c = vEntityContact2.Id;
            vContract6.CustomerSignedBy2__c = vEntityContact3.Id;
            vContract6.AXA_GS_Signed_By__c = vEntityContact4.Id;
            vContract6.AXA_GO_Signed_By_2__c = vEntityContact5.Id;          
            
            vPInvLine0 = AP05_TestDataFactory.createIL(lstContract[0], 250,'Description 2', '01', System.Today(), System.Today().addMonths(4), vEntityContact1.Id);
            vPInvLine1 = AP05_TestDataFactory.createIL(lstContract[0], 250,'Description 2', '01', System.Today(), System.Today().addMonths(4), vEntityContact1.Id);
            vPInvLine2 = AP05_TestDataFactory.createIL(lstContract[1], 500,'Description 2', '01', System.Today(), System.Today().addMonths(4), vEntityContact1.Id);
            vPInvLine3 = AP05_TestDataFactory.createIL(lstContract[2], 500,'Description 2', '01', System.Today(), System.Today().addMonths(4), vEntityContact1.Id);
            vPInvLine4 = AP05_TestDataFactory.createIL(lstContract[3], 500,'Description 2', '01', System.Today(), System.Today().addMonths(4), vEntityContact1.Id);

            lstPIL.add(vPInvLine0);
            lstPIL.add(vPInvLine1);
            lstPIL.add(vPInvLine2);
            lstPIL.add(vPInvLine3);
            lstPIL.add(vPInvLine4);
            insert lstPIL;
            
            
			//Create Product Item
			lstPItems = new List<ProductItem__c>();
            vPItem1 = AP05_TestDataFactory.createCtrProdItems(lstContract[0], vProduct1, 'Product Item desc');
            lstPItems.add(vPItem1);
            vPItem2 = AP05_TestDataFactory.createCtrProdItems(lstContract[1], vProduct1, 'Product Item desc');
            lstPItems.add(vPItem2);
            vPItem3 = AP05_TestDataFactory.createCtrProdItems(lstContract[2], vProduct1, 'Product Item desc');
            lstPItems.add(vPItem3);
            vPItem4 = AP05_TestDataFactory.createCtrProdItems(lstContract[3], vProduct1, 'Product Item desc');
            lstPItems.add(vPItem4);
            insert lstPItems;

            
            
            Account supplier = TestFactory.createSupplier('AXA GROUP SOLUTIONS','Paris','France');    
            insert supplier;
            
            Contact con1=TestFactory.createContact(supplier,'James','Brown');
            Contact con2=TestFactory.createContact(supplier,'Jim','Brown'); 
            Contact con3=TestFactory.createContact(supplier,'James','Brown'); 
            con3.Email = 'JamesBrown@gmail.com';
            
            contactLst.add(con1);
            contactLst.add(con2); 
            contactLst.add(con3); 
            insert contactLst;
            
            contract  = TestFactory.createContract(supplier.Id,'Contract1',AP_Constant.CONTRACT_STATUS_DRAFT);
            contract.CustomerSignedBy__c=contactLst[0].id;
            contract.AXA_GS_Signed_By__c=contactLst[1].id;
            contract.OpCo_Send_Automatic_PO_Reminder__c = true;
            contract.Signature_Type__c = AP_Constant.SIGNATURE_MANUAL;
            contract.Customer_Operational_Contact__c = contactLst[2].id;
            insert contract;
            pInvLine = AP05_TestDataFactory.createIL(contract, 100,'Description 2', '01', System.Today(), System.Today().addMonths(4), supplier.Id);
            insert pInvLine;
        }
    }
    
    @isTest
    public static void deactivateCustomerOperationalContact_Test(){
        // Link the legal entity to the master entity
        System.runAs(adminUser) {
            // Deactivate contact
            vEntityContact1.Active__c = false;
            update vEntityContact1;
            Test.startTest();
                try{
                    insert vContract6;
                }catch(Exception e){
                    System.assert(e.getMessage().contains(label.Contract_Operational_Contact));
                }

                try{
                    update lstContract;
                }catch(Exception e){
                    System.assert(e.getMessage().contains(label.Contract_Operational_Contact));
                }
            Test.stopTest();
        }
    }
    
    @isTest
    public static void deactivateCustomerSignedBy01_Test(){
        // Link the legal entity to the master entity
        System.runAs(adminUser) {
            // Deactivate contact
            vEntityContact2.Active__c = false;
            update vEntityContact2;
            Test.startTest();
                try{
                    insert vContract6;
                }catch(Exception e){
                    System.assert(e.getMessage().contains(label.Customer_Signed_By_Error));
                }
                
                try{
                    update lstContract;
                }catch(Exception e){
                    System.assert(e.getMessage().contains(label.Customer_Signed_By_Error));
                }
            Test.stopTest();
        }
    }
    
    @isTest
    public static void deactivateCustomerSignedBy02_Test(){
        // Link the legal entity to the master entity
        System.runAs(adminUser) {
            // Deactivate contact
            vEntityContact3.Active__c = false;
            update vEntityContact3;
            Test.startTest();
                try{
                    insert vContract6;
                }catch(Exception e){
                    System.assert(e.getMessage().contains(label.Customer_Signed_By_2_Error));
                }

                try{
                    update lstContract;
                }catch(Exception e){
                    System.assert(e.getMessage().contains(label.Customer_Signed_By_2_Error));
                }
            Test.stopTest();
        }
    }
    
    @isTest
    public static void deactivateAXAGoSignedBy01_Test(){
        // Link the legal entity to the master entity
        System.runAs(adminUser) {
            // Deactivate contact
            vEntityContact4.Active__c = false;
            update vEntityContact4;
            Test.startTest();  
                try{
                    update lstContract;
                }catch(Exception e){
                    system.debug('******e.getMessage() '+e.getMessage());
                    System.assert(e.getMessage().contains('AXA_GS_Signed_By__c') || e.getMessage().contains(label.Contract_AXA_Go_Signed_By_Error));
                }
            Test.stopTest();
        }
    }
    
    @isTest
    public static void deactivateAXAGoSignedBy02_Test(){
        // Link the legal entity to the master entity
        System.runAs(adminUser) {
            // Deactivate contact
            vEntityContact5.Active__c = false;
            update vEntityContact5;
            Test.startTest();
                try{
                    insert vContract6;
                }catch(Exception e){
                    System.assert(e.getMessage().contains(label.Contract_AXA_Go_Signed_By_2_Error));
                }

                try{
                    update lstContract;
                }catch(Exception e){
                    System.assert(e.getMessage().contains(label.Contract_AXA_Go_Signed_By_2_Error));
                }
            Test.stopTest();
        }
    }
    
    @isTest
    public static void updateWBS_Test(){
        // Link the legal entity to the master entity
        System.runAs(adminUser) {
            // Update wbs on contract
            Test.startTest();
            lstContract[0].Master_WBS_2__c = vMasterWBS_2.Id;
            lstContract[2].Master_WBS_2__c = vMasterWBS_2.Id;
            ContractTriggerHandler.hasExecutedafterUpdateHandler = false;
            update lstContract;
            
            //vPlannedInvLine = [SELECT Id, WBS__c FROM Planned_Invoicing_Line__c WHERE ID = :vPlannedInvLine.Id];
            Test.stopTest();
        }
    }
    
	@isTest
    public static void updateRecordType_Test(){
        System.runAs(adminUser) {
            
            test.startTest();
            
            ContractTriggerHandler.hasExecutedafterUpdateHandler = false;
            lstContract[0].RecordTypeId = ContractTriggerHandler.idRecOpCoSingleReadOnly;
            lstContract[0].PDFStatus_lgt__c = 'Updated';
            lstContract[0].Status__c = 'Internal Validation';
            
            lstContract[1].RecordTypeId = ContractTriggerHandler.idRecOpCoSingleReadOnly;
            lstContract[1].PDFStatus_lgt__c ='Updated';
            lstContract[1].Status__c = 'Ready for Signature';
            lstContract[1].TacitRenewal__c = 'Yes';
            
            lstContract[2].RecordTypeId = ContractTriggerHandler.idRecOpCoAmendReadOnly;
            lstContract[2].Master_WBS_2__c = vMasterWBS_2.Id;
            lstContract[2].PDFStatus_lgt__c ='Updated';
            lstContract[2].Status__c = 'Internal Validation';
            
            lstContract[3].RecordTypeId = ContractTriggerHandler.idRecOpCoAmendReadOnly;
            lstContract[3].PDFStatus_lgt__c ='Updated';
            lstContract[3].Status__c = 'Ready for Signature';
            lstContract[3].TacitRenewal__c = 'Yes';
            
            update lstContract;
            test.stopTest();
        }
    }
    
	@isTest
    public static void pushStatusToOpportunityTest(){
        System.runAs(vUserPM) {
            //Opportunity
			lstOpp = new List<Opportunity>();
            vOpp1 		= new Opportunity(	OwnerId                         = vUserPM.Id,
											Name 							= 'Test Opp',
											AccountId 						= vEAccount.Id,
											StageName 						= AP_Constant.STAGE_LEADS_GATHERING,
											CloseDate						= System.Today().addMonths(-5),
											AXA_GO_Entity__c = 'AXA Group Operations Hong Kong Limited',
											RecordTYpeId                     = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Full Opportunity Contract process OpCo360').getRecordTypeId()
			);
            lstOpp.add(vOpp1);
            vOpp2  		= new Opportunity(	OwnerId                         = vUserPM.Id,
                                            Name 							= 'Test Opp2',
                                            AccountId 						= vEAccount.Id,
                                            StageName 						= AP_Constant.STAGE_LEADS_GATHERING,
                                            CloseDate						= System.Today().addMonths(-5),
                                            AXA_GO_Entity__c = 'AXA Group Operations Hong Kong Limited',
                                            RecordTYpeId                     = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Full Opportunity Contract process OpCo360').getRecordTypeId()
);
            lstOpp.add(vOpp2);
            vOpp3 		= new Opportunity(	OwnerId                         = vUserPM.Id,
											Name 							= 'Test Opp3',
											AccountId 						= vEAccount.Id,
											StageName 						= AP_Constant.STAGE_LEADS_GATHERING,
											CloseDate						= System.Today().addMonths(-5),
											AXA_GO_Entity__c = 'AXA Group Operations Hong Kong Limited',
											RecordTYpeId                     = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Full Opportunity Contract process OpCo360').getRecordTypeId()
			);
            lstOpp.add(vOpp3);
            insert lstOpp;
            
            for(integer i=0; i<3; i++){
                lstContract[i].Opportunity__c = lstOpp[i].Id;
            }
            ContractTriggerHandler.hasExecutedafterUpdateHandler = false;
            update lstContract;
            
            ContractTriggerHandler.hasExecutedafterUpdateHandler = false;
            test.startTest();
                lstContract[0].Status__c = AP_Constant.CONTRACT_STATUS_INTERNAL_VALIDATION;
            	update lstContract;
            test.stopTest();

            //System.assertEquals(2, [SELECT count() FROM Opportunity WHERE TECH_ContractStatus__c =: AP_Constant.CONTRACT_STATUS_DRAFT]);
        }
    }

    @isTest
    static void prefillEntitiesTest() {

        System.runAs(adminUser) {
            Test.startTest();

            // Case 1 : Legal Entity linked to Entity
            Contract__c vContract = AP05_TestDataFactory.createContract(vProduct1, vLegalEntity1, vUserPM1, vEntityContact1, AP_Constant.CONTRACT_STATUS_DRAFT, false);
            insert vContract;
            vContract = [SELECT Id, C_Account__c FROM Contract__c WHERE Id = :vContract.Id][0];
            //System.assert(vContract.C_Account__c != null, 'Entity is null');

            Test.stopTest();
        }
    }


    @isTest
    static void prefillEntitiesFromMasterTest() {

        System.runAs(adminUser) {
            Test.startTest();

            // Case 2 : Legal Entity linked to Master entity with entity not linked
            // Create the couple Entity - Billing Entity on Parent Entity
            vLEntity1 = AP05_TestDataFactory.linkLEgalEntityToEntity(vEntity1, vLEntity1);
            // Create contract
            Contract__c vContract = AP05_TestDataFactory.createContract(vProduct1, vLEntity1, vUserPM1, vEntityContact1, 'Draft', false);
            vContract.C_Account__c = vEntity1.Id;
            vContract.Account__c = null;
            insert vContract;
            vContract = [SELECT Id, Account__c FROM Contract__c WHERE Id = :vContract.Id][0];

            //System.assert(vContract.Account__c != null, 'Legal Entity is null');
            Test.stopTest();
        }
    }


    @isTest
    static void prefillEntitiesWithMasterTest() {

        System.runAs(adminUser) {
            AccountModification_Flag__c accM = new AccountModification_Flag__c();
            accM.Flag__c = true;
            insert accM;
            
            Test.startTest();
            // Link the legal entity to the master entity
            system.debug('******.Active__c : '+vMEntity1.Active__c +'***'+ vLEntity1.Active__c);
            vLEntity1 = AP05_TestDataFactory.linkLEgalEntityToEntity(vMEntity1, vLEntity1);
            // Link the entity to the master entity
            AP05_TestDataFactory.linkLEgalEntityToEntity(vMEntity1, vEntity1);
            // Create contract
            Contract__c vContract = AP05_TestDataFactory.createContract(vProduct1, vLEntity1, vUserPM1, vEntityContact1, 'Draft', false);
            vContract.RecordTypeId = ContractTriggerHandler.idRecOpCoSingleEdit;
            vContract.C_Account__c = vEntity1.Id;
            vContract.Account__c = null;

            insert vContract;
            vContract = [SELECT Id, Account__c FROM Contract__c WHERE Id = :vContract.Id][0];

            //System.assert(vContract.Account__c != null, 'Legal Entity is null');
            Test.stopTest();
        }
    }

    @isTest
    public static void fillInSignatureTypeTest_Insert_SIGNATURE_MANUAL() {
        System.runAs(adminUser) {
            vLEntity1.Signature_Type__c = AP_Constant.SIGNATURE_MANUAL;
            update vLEntity1;
            // Link the legal entity to the master entity
            vLEntity1 = AP05_TestDataFactory.linkLEgalEntityToEntity(vMEntity1, vLEntity1);
            // Create contract
            Contract__c vContract = AP05_TestDataFactory.createContract(vProduct1, vLEntity1, vUserPM1, vEntityContact1, 'Draft', false);
			vContract.RecordTypeId = ContractTriggerHandler.idRecOpCoSingleEdit;
            // test Manual insert
            Test.startTest();
                insert vContract;
            Test.stopTest();
            vContract = [SELECT Id, Signature_Type__c FROM Contract__c WHERE Id = :vContract.Id][0];
            //System.assertEquals(AP_Constant.SIGNATURE_MANUAL, vContract.Signature_Type__c, 'Signature type should be Manual');
        }
    }
    
    @isTest
    public static void fillInSignatureTypeTest_Insert_SIGNATURE_CONTRACTIN() {
        System.runAs(adminUser) {
            vLEntity1.Signature_Type__c = AP_Constant.SIGNATURE_CONTRACTIN;
            update vLEntity1;
            // Link the legal entity to the master entity
            vLEntity1 = AP05_TestDataFactory.linkLEgalEntityToEntity(vMEntity1, vLEntity1);
            // Create contract
            Contract__c vContract = AP05_TestDataFactory.createContract(vProduct1, vLEntity1, vUserPM1, vEntityContact1, 'Draft', false);
			vContract.RecordTypeId = ContractTriggerHandler.idRecOpCoSingleEdit;
            // test Manual insert
            Test.startTest();
                insert vContract;
            Test.stopTest();

            vContract = [SELECT Id, Signature_Type__c FROM Contract__c WHERE Id = :vContract.Id][0];
            //System.assertEquals(AP_Constant.SIGNATURE_CONTRACTIN, vContract.Signature_Type__c, 'Signature type should be Contract In');
        }
    }
    
    @isTest
    public static void fillInSignatureTypeTest_Insert_SIGNATURE_SPECIFIC() {
        System.runAs(adminUser) {
            vLEntity1.Signature_Type__c = Label.Contract_Signature_Type_Specific;
            update vLEntity1;
            // Link the legal entity to the master entity
            vLEntity1 = AP05_TestDataFactory.linkLEgalEntityToEntity(vMEntity1, vLEntity1);
            // Create contract
            Contract__c vContract = AP05_TestDataFactory.createContract(vProduct1, vLEntity1, vUserPM1, vEntityContact1, 'Draft', false);
			vContract.RecordTypeId = ContractTriggerHandler.idRecOpCoSingleEdit;
            // test Manual insert
            Test.startTest();
                insert vContract;
            Test.stopTest();

            vContract = [SELECT Id, Signature_Type__c FROM Contract__c WHERE Id = :vContract.Id][0];
            //System.assertEquals(Label.Contract_Signature_Type_Specific, vContract.Signature_Type__c, 'Signature type should be Specific');
        }
    }
    
    @isTest
    public static void fillInSignatureTypeTest_Insert_SIGNATURE_ELECTRONIC() {
        System.runAs(adminUser) {
            vLEntity1.Signature_Type__c = AP_Constant.SIGNATURE_ELECTRONIC;
            update vLEntity1;
            // Link the legal entity to the master entity
            vLEntity1 = AP05_TestDataFactory.linkLEgalEntityToEntity(vMEntity1, vLEntity1);
            // Create contract
            Contract__c vContract = AP05_TestDataFactory.createContract(vProduct1, vLEntity1, vUserPM1, vEntityContact1, 'Draft', false);
			vContract.RecordTypeId = ContractTriggerHandler.idRecOpCoSingleEdit;
            // test Manual insert
            Test.startTest();
                insert vContract;
            Test.stopTest();

            vContract = [SELECT Id, Signature_Type__c FROM Contract__c WHERE Id = :vContract.Id][0];
            //System.assertEquals(AP_Constant.SIGNATURE_ELECTRONIC, vContract.Signature_Type__c, 'Signature type should be Electronic');
        }
    }

    @isTest
    public static void sendPOReminder(){
        System.runAs(adminUser) {
            Test.startTest();
            contract.OpCo_Send_Automatic_PO_Reminder__c = true;
            contract.Status__c = AP_Constant.CONTRACT_STATUS_SIGNED;
            contract.Contract_Signed_Date__c = System.today();
            contract.RecordTypeId = Schema.SObjectType.Contract__c.getRecordTypeInfosByName().get(AP_Constant.RT_CONTRACT_READONLY_LIGHTNING_LABEL).getRecordTypeId();
            update contract;
            AP12_Contract.sendPOReminder(new Set<Id>{contract.Id});
            Test.stopTest();
        }
    }

    @isTest
    public static void getRecTypes(){
        System.runAs(adminUser) {
            Test.startTest();
                AP12_contract ap12_Ctr = new AP12_contract();
            Test.stopTest();
        }
    }
}