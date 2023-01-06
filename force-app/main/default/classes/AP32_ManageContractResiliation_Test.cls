@IsTest
private class AP32_ManageContractResiliation_Test {
    /*
    --------------------------------------------------------------------------------------
    -- - Name          : AP32_ManageContractResiliation
    -- - Author        : Spoon Consulting
    -- - Description   : Test class for AP32_ManageContractResiliation
    --
    -- Maintenance History:
    --
    -- Date         Name  Version  Remarks
    -- -----------  ----  -------  -------------------------------------------------------
    -- 29-APR-2020  USA    1.0     Initial version [SP-00221]
    -- 06-JUL-2020  ARA    1.0     add canlelCtrSentSigWithTransaction method
    --------------------------------------------------------------------------------------*/
    static User vUserPM;
    static Account accLE;
    static Account vEntity1;
    static User adminUser;
    static Contract__c ctrOpCo;
    static Contact vEntityContact;
    static List<Planned_Invoicing_Line__c> lstILs = new List<Planned_Invoicing_Line__c>();
    static List<eSignature__c> lstSignatures = new List<eSignature__c>();
    static List<eSignatory__c> lstSignatories = new List<eSignatory__c>();

    static{
        adminUser = new User();
        adminUser.Alias = 'admin';
        adminUser.FirstName = 'adminUser';
        adminUser.LastName = 'adminUser';
        adminUser.Username = AP05_TestDataFactory.getUniqueUserName();
        adminUser.Email = 'userAdmin@User.com';
        adminUser.EmailEncodingKey = 'ISO-8859-1';
        adminUser.TimeZoneSidKey = 'Europe/Paris';
        adminUser.LanguageLocaleKey = 'en_US';
        adminUser.LocaleSidKey = 'fr_FR_EURO';
        adminUser.ProfileId = AP_Constant.getProfileIdAdmin();
        adminUser.PAD_BypassTrigger__c = 'AP412;';
        insert adminUser;

        System.runAs(adminUser) {

            // Create OO user
            User vUserOO = AP05_TestDataFactory.createOOUser();

            // Create PM user
            vUserPM = AP05_TestDataFactory.createPMUser(true);

            //Product
            Product__c vProduct = AP05_TestDataFactory.createProduct(vUserOO);

            // Create the customer (aka entity) account
            accLE = AP05_TestDataFactory.createLegalEntityAccount(vUserPM, 'ACC_AP32');

            vEntityContact = AP05_TestDataFactory.createEntityContact(accLE);

            // Create the entity account
            vEntity1 = AP05_TestDataFactory.createEntityAccount(vUserPM, 'testEntity');

            vEntityContact = new Contact();
            vEntityContact.AccountId = accLE.Id;
            vEntityContact.LastName = 'Lname_ap32';
            vEntityContact.Title = 'testing';
            vEntityContact.Email = 'ap32@gmail.com';
            vEntityContact.MobilePhone = '+331234567890';
            vEntityContact.AXA_GO_Signatory__c = true;
            vEntityContact.Active__c = true;
            vEntityContact.RecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get(AP_Constant.RT_ENTITY_CONTACT).getRecordTypeId(); // TODO add method with developer name
            insert vEntityContact;
        }
    }

    @IsTest
    static void resilateCtrDraftError() {
        String strErrMsg = '';
        test.startTest();
            System.runAs(adminUser) {
                ctrOpCo = AP05_TestDataFactory.createContractLEX(AP_Constant.RT_CONTRACT_EDIT_LIGHTNING_LABEL, accLE, adminUser, vEntityContact, AP_Constant.CONTRACT_STATUS_DRAFT, false);
                insert ctrOpCo;

                try {
                    ctrOpCo.status__c = 'Resiliated';
                    update ctrOpCo;
                } catch (exception e) {
                    strErrMsg = e.getMessage();
                }
                system.assert(strErrMsg.contains('The fields Decision Maker and Reason are mandatory to update the Status to Cancelled or Resiliated'));
            }
        test.stopTest();
    }

    @IsTest
    static void resilateCtrSentSig() {
        String strErrMsg = '';
        test.startTest();
        System.runAs(adminUser) {
            ctrOpCo = AP05_TestDataFactory.createContractLEX(AP_Constant.RT_CONTRACT_EDIT_LIGHTNING_LABEL, accLE, adminUser, vEntityContact, AP_Constant.CONTRACT_STATUS_DRAFT, false);
            insert ctrOpCo;

            Planned_Invoicing_Line__c vInvoicingLine1 = AP05_TestDataFactory.createIL(ctrOpCo, 100,'IL0', AP_Constant.INVLINE_STATUS_DRAFT, System.Today(), System.Today().addMonths(4), vEntityContact.Id);
            Planned_Invoicing_Line__c vInvoicingLine2 = AP05_TestDataFactory.createIL(ctrOpCo, 100,'IL1', AP_Constant.INVLINE_STATUS_INVOICED, System.Today(), System.Today().addMonths(4), vEntityContact.Id);
            lstILs.add(vInvoicingLine1);
            lstILs.add(vInvoicingLine2);
            insert lstILs;

            ctrOpCo.PDFStatus_lgt__c = 'Updated';
            ctrOpCo.TacitRenewal__c = 'No';
            update ctrOpCo;
            ctrOpCo.Status__c = AP_Constant.CONTRACT_STATUS_READY_FOR_SIGNATURE;
            update ctrOpCo;

            eSignature__c esignature=TestFactory.createEsignature(ctrOpCo,'esign1', AP_Constant.eSignatureCreatedStatus);
            insert esignature;
            Esignatory__c esignatory = TestFactory.createEsignatory(ctrOpCo, esignature,'Jane',vEntityContact.Id,AP_Constant.esignatoryStatusNotStarted);
            esignatory.Order__c=3;
            esignatory.OrderCachet__c=3;
            esignatory.MobileTxt__c='45648464';
            insert esignatory;

            ctrOpCo.status__c = 'Sent for Signature';
            update ctrOpCo;

            ContractTriggerHandler.hasExecutedafterUpdateHandler = false;
            ctrOpCo.status__c = System.Label.ContractStatus_Resiliated;
            ctrOpCo.Decision_maker__c = 'AXA GS';
            ctrOpCo.Cancelled_reason__c = 'Price';
            update ctrOpCo;

            List<Planned_Invoicing_Line__c> lstUpdatedIl = [SELECT id, status__c from Planned_Invoicing_Line__c WHERE Contract2__c = :ctrOpCo.Id AND status__c = '99'];
            //System.assertEquals(1, lstUpdatedIl.size());

        }
        test.stopTest();
    }
    
    @IsTest
    static void resilateCtrSentSigWithTransaction() {
        String strErrMsg = '';
        test.startTest();
        System.runAs(adminUser) {
            ctrOpCo = AP05_TestDataFactory.createContractLEX(AP_Constant.RT_CONTRACT_EDIT_LIGHTNING_LABEL, accLE, adminUser, vEntityContact, AP_Constant.CONTRACT_STATUS_DRAFT, false);
            insert ctrOpCo;

            Planned_Invoicing_Line__c vInvoicingLine1 = AP05_TestDataFactory.createIL(ctrOpCo, 100,'IL0', AP_Constant.INVLINE_STATUS_DRAFT, System.Today(), System.Today().addMonths(4), vEntityContact.Id);
            Planned_Invoicing_Line__c vInvoicingLine2 = AP05_TestDataFactory.createIL(ctrOpCo, 100,'IL1', AP_Constant.INVLINE_STATUS_INVOICED, System.Today(), System.Today().addMonths(4), vEntityContact.Id);
            lstILs.add(vInvoicingLine1);
            lstILs.add(vInvoicingLine2);
            insert lstILs;
            
            ctrOpCo.PDFStatus_lgt__c = 'Updated';
            ctrOpCo.TacitRenewal__c = 'No';
            update ctrOpCo;
            ctrOpCo.Status__c = AP_Constant.CONTRACT_STATUS_READY_FOR_SIGNATURE;
            update ctrOpCo;

            eSignature__c esignature=TestFactory.createEsignature(ctrOpCo,'esign1', AP_Constant.eSignatureCreatedStatus);
            esignature.transactionId__c = 'e401d29a-6ec3-4433-9ecc-b51e40ab78c9';
            insert esignature;
            Esignatory__c esignatory = TestFactory.createEsignatory(ctrOpCo, esignature,'Jane',vEntityContact.Id,AP_Constant.esignatoryStatusNotStarted);
            esignatory.Order__c=3;
            esignatory.OrderCachet__c=3;
            esignatory.MobileTxt__c='45648464';
            insert esignatory;

            ctrOpCo.status__c = 'Sent for Signature';
            update ctrOpCo;

            ContractTriggerHandler.hasExecutedafterUpdateHandler = false;
            ctrOpCo.status__c = System.Label.ContractStatus_Resiliated;
            ctrOpCo.Decision_maker__c = 'AXA GS';
            ctrOpCo.Cancelled_reason__c = 'Price';
            update ctrOpCo;

            List<Planned_Invoicing_Line__c> lstUpdatedIl = [SELECT id, status__c from Planned_Invoicing_Line__c WHERE Contract2__c = :ctrOpCo.Id AND status__c = '99'];
            //System.assertEquals(1, lstUpdatedIl.size());

        }
        test.stopTest();
    }
    
    @IsTest
    static void canlelCtrSentSigWithTransaction() {
        String strErrMsg = '';
        test.startTest();
        System.runAs(adminUser) {

            ctrOpCo = AP05_TestDataFactory.createContractLEX(AP_Constant.RT_CONTRACT_EDIT_LIGHTNING_LABEL, accLE, adminUser, vEntityContact, AP_Constant.CONTRACT_STATUS_DRAFT, false);
            ctrOpCo.PDFStatus_lgt__c = 'Updated';
            insert ctrOpCo;
            Planned_Invoicing_Line__c vInvoicingLine1 = AP05_TestDataFactory.createIL(ctrOpCo, 100,'IL0', AP_Constant.INVLINE_STATUS_DRAFT, System.Today(), System.Today().addMonths(4), vEntityContact.Id);
            Planned_Invoicing_Line__c vInvoicingLine2 = AP05_TestDataFactory.createIL(ctrOpCo, 100,'IL1', AP_Constant.INVLINE_STATUS_INVOICED, System.Today(), System.Today().addMonths(4), vEntityContact.Id);
            lstILs.add(vInvoicingLine1);
            lstILs.add(vInvoicingLine2);
            insert lstILs;

            ctrOpCo.PDFStatus_lgt__c = 'Updated';
            ctrOpCo.TacitRenewal__c = 'No';
            update ctrOpCo;
            ctrOpCo.Status__c = AP_Constant.CONTRACT_STATUS_READY_FOR_SIGNATURE;
            update ctrOpCo;

            eSignature__c esignature=TestFactory.createEsignature(ctrOpCo,'esign1', AP_Constant.eSignatureCreatedStatus);
            esignature.transactionId__c = 'e401d29a-6ec3-4433-9ecc-b51e40ab78c9';
            insert esignature;
            Esignatory__c esignatory = TestFactory.createEsignatory(ctrOpCo, esignature,'Jane',vEntityContact.Id,AP_Constant.esignatoryStatusNotStarted);
            esignatory.Order__c=3;
            esignatory.OrderCachet__c=3;
            esignatory.MobileTxt__c='45648464';
            insert esignatory;

            ctrOpCo.status__c = 'Sent for Signature';
            ctrOpCo.Decision_maker__c = 'AXA GS';
            ctrOpCo.Cancelled_reason__c = 'Price';
            update ctrOpCo;

            ContractTriggerHandler.hasExecutedafterUpdateHandler = false;
            ctrOpCo.status__c = System.Label.ContractStatus_Cancelled;
            update ctrOpCo;

            List<Planned_Invoicing_Line__c> lstUpdatedIl = [SELECT id, status__c from Planned_Invoicing_Line__c WHERE Contract2__c = :ctrOpCo.Id AND status__c = '99'];
            //System.assertEquals(1, lstUpdatedIl.size());

        }
        test.stopTest();
    }
}