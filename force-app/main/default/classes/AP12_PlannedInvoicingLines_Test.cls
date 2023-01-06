@isTest
private class AP12_PlannedInvoicingLines_Test {

    static user testUser;
    static ContentWorkspace workspace;
    static User vUserPM;
    static User vUserOO;
    static Account vAccount;
    static  Account vEAccount;
    static Contact vEntityContact;
    static Product__c vProduct;
    static Contract__c vContract;
    static Planned_Invoicing_Line__c vPInvLine1;
    static Planned_Invoicing_Line__c vPInvLine2;
    static Id InvDateRecordTypeId;
    static Id InvLinRecordTypeId;
    static Id InvCondRecordTypeId;
    static Invoicing_Parameter__c a1ParmInvLin,a1ParmInvCond,a2ParmInvCond,a2ParmInvLin,a3ParmInvCond,a3ParmInvLin,a4ParmInvLin,aParmInvDate,a5ParmInvLin;  
    static List <Invoicing_Parameter__c> ParmLineList;  
    static id recordTypeAGSSpainEditId;
    static opportunity vOpp;
    static Master_WBS_Structure__c vMasterWBS_2; 

    static List<Planned_Invoicing_Line__c> lstPIL = new List<Planned_Invoicing_Line__c>(); 
    static invoicing_parameter__c invParam;
    static List<Planned_Invoicing_Line__c> lstPILs;
    static PDFContractAttached__c pdfContractAttached;


    static{
       
    // Create PM user
    vUserPM = new User();
    vUserPM.Alias = 'Admin';
    vUserPM.FirstName = 'userAdmin';
    vUserPM.LastName = 'userAdmin';
    vUserPM.Username = 'userADMIN01@test.com';
    vUserPM.Email = 'userAdmin@Account.com';
    vUserPM.EmailEncodingKey = 'ISO-8859-1';
    vUserPM.TimeZoneSidKey = 'Europe/Paris';
    vUserPM.LanguageLocaleKey = 'en_US';
    vUserPM.LocaleSidKey = 'fr_FR_EURO';
    vUserPM.ProfileId = AP_Constant.getProfileIdAdmin();
    vUserPM.PAD_BypassValidationRules__c = false;
    insert vUserPM;

    vUserPM.PAD_BypassTrigger__c = 'AP412;AP52;AP1012;AP22;';
    update vUserPM;

    System.runAs(vUserPM) {
        // Create OO user
        User vUserOO = AP05_TestDataFactory.createOOUser();

        // Create the legal entity (aka billing entity) account
        vAccount = AP05_TestDataFactory.createLegalEntityAccount(vUserPM);

        // Create the entity account
        vEAccount = AP05_TestDataFactory.createEntityAccount(vUserPM);

        // Create the couple Entity - Billing Entity on Parent Entity
        vAccount = AP05_TestDataFactory.linkLEgalEntityToEntity(vEAccount, vAccount);

        // Create the entity contact related to the account
        vEntityContact = AP05_TestDataFactory.createEntityContact(vAccount);
        
        //Product
        vProduct = AP05_TestDataFactory.createProduct( vUserOO);

        //Invoicing parameter 
        invParam = new invoicing_parameter__c(parameter_type__c = 'Invoicing Date', invoicing_date__c = Date.today(), name = String.valueOf(Date.today()));
        insert invParam;

        //Master WBS
        //Master_WBS_Structure__c vMasterWBS = AP05_TestDataFactory.createMasterWBSStructure('MOSS SAS', 'MOSS SAS', System.Label.Ctr_AXA_LE_SAS, 'CSS', 'Digital', '2016', true);
        vMasterWBS_2 = AP05_TestDataFactory.createMasterWBSStructure('MOSS SAS', 'MOSS SAS', System.Label.Ctr_AXA_LE_SAS, 'CSS', 'Digital', '2016', true);

        //Contract
        //vContract = AP05_TestDataFactory.createContract(vProduct, vAccount, vUserPM, vEntityContact, AP_Constant.CONTRACT_STATUS_DRAFT); 
        vContract =  AP05_TestDataFactory.createContract(vProduct, vAccount, vUserOO, vEntityContact);
        vContract.PDFStatus_lgt__c ='Updated';
        vContract.TacitRenewal__c = 'No';
        update vContract;       


        //recordtype contract
        //recordTypeAGSSpainEditId=Schema.SObjectType.Contract__c.getRecordTypeInfosByName().get('AXA GS Spain').getRecordTypeId();
        
        lstPIL.add(AP05_TestDataFactory.createIL(vContract, 100,'Description 1', '01', System.Today(), System.Today().addMonths(4), vEntityContact.Id));
        lstPIL.add(AP05_TestDataFactory.createIL(vContract, 100,'Description 2', '01', System.Today(), System.Today().addMonths(4), vEntityContact.Id));
    
        
        system.debug('##Invoicing parameters datatest created'   + ParmLineList);

        pdfContractAttached = new PDFContractAttached__c();
        insert pdfContractAttached;

        vContract.PDFContrAtt__c = pdfContractAttached.Id;
        update vContract;

    }

} // generate Data test
    
    @isTest static void updatePlannedInvoicingLinesCurrentValuePDF() {
        System.runAs(vUserPM){
            Test.startTest();
                insert lstPIL;
            Test.stopTest();

            for (Planned_Invoicing_Line__c updatedPIL : [SELECT id, Master_WBS_Structure__c FROM Planned_Invoicing_Line__c WHERE Id in :lstPIL]){
                system.assertEquals(vContract.Master_WBS_2__c, updatedPIL.Master_WBS_Structure__c);
            }
        }
    }
    
    @isTest static void updatePDFContractsAttachedTest() {
        System.runAs(vUserPM){
            Test.startTest();
                insert lstPIL;
            Test.stopTest();

            List<PDFContractAttached__c> lstPDFContractAttachedGOT = [SELECT id,PDFStatus__c FROM PDFContractAttached__c WHERE Id = :pdfContractAttached.Id];
            system.assertEquals('Not Updated!', lstPDFContractAttachedGOT[0].PDFStatus__c); 
            
        }
    }

    @isTest static void createPIL() {
        System.runAs(vUserPM){

            Test.startTest();
                insert lstPIL;
            Test.stopTest();
        }
    }
    @isTest static void updateILWBS() {
        System.runAs(vUserPM){

            Test.startTest();
                insert lstPIL;

                lstPIL[0].Master_WBS_Structure__c = vMasterWBS_2.Id;
                update lstPIL[0];
            Test.stopTest();


            for (Planned_Invoicing_Line__c updatedPIL : [SELECT id, Master_WBS_Structure__c FROM Planned_Invoicing_Line__c WHERE Id = :lstPIL[0].Id]){
                //system.assertEquals(Date.Today(), updatedPIL.Invoicing_Date__c);
            }
        }
    }
    @isTest static void updateStatusTEST() {
        System.runAs(vUserPM){

            Test.startTest();
                lstPIL[0].Type__c = 'Invoicing Line';
                lstPIL[0].SO__c = '00';
                lstPIL[0].ITEM__c = '99';
                insert lstPIL;

                lstPIL[0].N_Invoice__c = 'INV';
                lstPIL[0].Paid_Not_Paid__c = true;
                lstPIL[0].SO__c = '01';
                lstPIL[0].ITEM__c = '99';
                update lstPIL[0];
            Test.stopTest();


            for (Planned_Invoicing_Line__c updatedPIL : [SELECT id, SO_ITEM__c,Status__c FROM Planned_Invoicing_Line__c WHERE Id = :lstPIL[0].Id]){
                system.assertEquals( '01-99',updatedPIL.SO_ITEM__c);
                system.assertEquals( '04', updatedPIL.Status__c);
            }
        }
    }

    //@isTest static void updateInvoicingDate() {
    //    System.runAs(vUserPM){
    //        insert lstPIL;

    //        lstPIL[0].ADV_GoNoGo__c = 'GO';
    //        lstPIL[0].Invoicing_Date__c = Date.today().addDays(-3);

    //        Test.startTest();
    //            update lstPIL[0];
    //        Test.stopTest();


    //        for (Planned_Invoicing_Line__c updatedPIL : [SELECT id, Invoicing_Date__c FROM Planned_Invoicing_Line__c WHERE Id = :lstPIL[0].Id]){
    //            system.assertEquals(Date.Today(), updatedPIL.Invoicing_Date__c);
    //        }
    //    }
    //}

    //@isTest static void updateILPO() {
    //    System.runAs(vUserPM){
            
    //        vAccount.Purchase_Order__c = true;
    //        update vAccount;

    //        insert lstPILs;

    //        lstPILs[7].N_Purchase_Order__c  = '1234';

    //        Test.startTest();
    //            update lstPILs[7];
    //        Test.stopTest();

    //        for (Planned_Invoicing_Line__c updatedPIL : [SELECT id, Status_Description__c FROM Planned_Invoicing_Line__c WHERE Id = :lstPILs[7].Id]){
    //            system.assertEquals(System.Label.InvoicingLine_StatusDescription_WaitingPMOGO, updatedPIL.Status_Description__c);
    //        }
    //    } 
    //}

    @isTest static void updatePOAcc() {
        vUserPM.PAD_BypassValidationRules__c = true;
    update vUserPM;
        System.runAs(vUserPM){
            
            vAccount.Purchase_Order__c = true;

            Test.startTest();
            update vAccount;
                insert lstPIL;

                // lstPIL[0].name  = '1234';
                update lstPIL[0];
            Test.stopTest();

            /*for (Planned_Invoicing_Line__c updatedPIL : [SELECT id,Purchase_Order__c,PurchaseOrder__c, N_Purchase_Order__c,  Status_Description__c FROM Planned_Invoicing_Line__c WHERE Id = :lstPIL[0].Id]){
                system.debug('**** '+updatedPIL.Purchase_Order__c +' *** '+ updatedPIL.PurchaseOrder__c+' *** '+updatedPIL.N_Purchase_Order__c);
                system.assertEquals(updatedPIL.Purchase_Order__c +' *** '+ updatedPIL.PurchaseOrder__c+' *** '+updatedPIL.N_Purchase_Order__c, updatedPIL.Status_Description__c);
            }*/
            for (Planned_Invoicing_Line__c updatedPIL : [SELECT id, Status_Description__c FROM Planned_Invoicing_Line__c WHERE Id = :lstPIL[0].Id]){
                system.assertEquals(System.Label.InvoicingLine_StatusDescription_SignatureMissing, updatedPIL.Status_Description__c);
            }
        }
    }

    @isTest static void missingSignature() {
        System.runAs(vUserPM){
            
            vAccount.Purchase_Order__c = false;
            update vAccount;

            Test.startTest();
                insert lstPIL;

                // lstPIL[0].name  = '1234';
                update lstPIL[0];
            Test.stopTest();

            for (Planned_Invoicing_Line__c updatedPIL : [SELECT id, Status_Description__c FROM Planned_Invoicing_Line__c WHERE Id = :lstPIL[0].Id]){
                system.assertEquals(System.Label.InvoicingLine_StatusDescription_SignatureMissing, updatedPIL.Status_Description__c);
            }
        }
    }

/*    @isTest static void missingSignatureCtrInternalVal() {
        System.runAs(vUserPM){
            
            Test.startTest();
            vAccount.Purchase_Order__c = false;
            update vAccount;

            insert lstPIL;
            vContract.Status__c = System.Label.ContractStatus_InternalValidation;
            update vContract;


                // lstPIL[0].name  = '1234';
                update lstPIL[0];
            Test.stopTest();

            for (Planned_Invoicing_Line__c updatedPIL : [SELECT id, Status_Description__c FROM Planned_Invoicing_Line__c WHERE Id = :lstPIL[0].Id]){
                system.assertEquals(System.Label.InvoicingLine_StatusDescription_SignatureMissing, updatedPIL.Status_Description__c);
            }
        }
    }*/

    @isTest static void missingSignatureCtrVal() {
        System.runAs(vUserPM){
            
            vAccount.Purchase_Order__c = false;
            update vAccount;

            vContract.Status__c = System.Label.ContractStatus_Validated;
            update vContract;

            Test.startTest();
                insert lstPIL;

                // lstPIL[0].name  = '1234';
                update lstPIL[0];
            Test.stopTest();

            for (Planned_Invoicing_Line__c updatedPIL : [SELECT id, Status_Description__c FROM Planned_Invoicing_Line__c WHERE Id = :lstPIL[0].Id]){
                system.assertEquals(System.Label.InvoicingLine_StatusDescription_PendingBillingRequesterGO, updatedPIL.Status_Description__c);
            }
        }
    }

    @isTest static void missingSignatureCtrCustVal() {
        System.runAs(vUserPM){
            
            vAccount.Purchase_Order__c = false;
            update vAccount;
            insert AP05_TestDataFactory.createCtrProdItems(vContract, vProduct, 'description test');
            vContract.Status__c = System.Label.ContractStatus_CustomerValidation;
            update vContract;

            Test.startTest();
                insert lstPIL;

                // lstPIL[0].name  = '1234';
                update lstPIL[0];
            Test.stopTest();

            for (Planned_Invoicing_Line__c updatedPIL : [SELECT id, Status_Description__c FROM Planned_Invoicing_Line__c WHERE Id = :lstPIL[0].Id]){
                system.assertEquals(System.Label.InvoicingLine_StatusDescription_SignatureMissing, updatedPIL.Status_Description__c);
            }
        }
    }

    @isTest static void missingSignatureReadySig() {
        System.runAs(vUserPM){
            
            vAccount.Purchase_Order__c = false;
            update vAccount;
            vContract.Status__c = System.Label.ContractStatus_ReadyForSignature;
            update vContract;

            Test.startTest();
                insert lstPIL;

                // lstPIL[0].name  = '1234';
                update lstPIL[0];
            Test.stopTest();

            for (Planned_Invoicing_Line__c updatedPIL : [SELECT id, Status_Description__c FROM Planned_Invoicing_Line__c WHERE Id = :lstPIL[0].Id]){
                system.assertEquals(System.Label.InvoicingLine_StatusDescription_SignatureMissing, updatedPIL.Status_Description__c);
            }
        }
    }

    @isTest static void missingSignatureSentSig() {
        System.runAs(vUserPM){
            
            vAccount.Purchase_Order__c = false;
            update vAccount;

            vContract.Status__c = System.Label.ContractStatus_SentForSignature;
            update vContract;

            Test.startTest();
                insert lstPIL;

                // lstPIL[0].name  = '1234';
                update lstPIL[0];
            Test.stopTest();

            for (Planned_Invoicing_Line__c updatedPIL : [SELECT id, Status_Description__c FROM Planned_Invoicing_Line__c WHERE Id = :lstPIL[0].Id]){
                system.assertEquals(System.Label.InvoicingLine_StatusDescription_SignatureMissing, updatedPIL.Status_Description__c);
            }
        }
    }

    @isTest static void pendingBillingRequesterGO() {
        System.runAs(vUserPM){
            
            vAccount.Purchase_Order__c = false;
            update vAccount;

            vContract.Contract_Signed_Date__c = System.Today();
            vContract.Status__c = System.Label.ContractStatus_Signed;
            update vContract;

            Test.startTest();
                insert lstPIL;

                // lstPIL[0].name  = '1234';
                update lstPIL[0];
            Test.stopTest();

            for (Planned_Invoicing_Line__c updatedPIL : [SELECT id, Status_Description__c FROM Planned_Invoicing_Line__c WHERE Id = :lstPIL[0].Id]){
                system.assertEquals(System.Label.InvoicingLine_StatusDescription_PendingBillingRequesterGO, updatedPIL.Status_Description__c);
            }
        }
    }

    @isTest static void pendingBillingTeamGO() {
        System.runAs(vUserPM){
            
            vAccount.Purchase_Order__c = false;
            update vAccount;

            vContract.Contract_Signed_Date__c = System.Today();
            vContract.Status__c = System.Label.ContractStatus_Signed;
            update vContract;

            Test.startTest();
                insert lstPIL;

                lstPIL[0].GoNoGo__c = 'GO';
                update lstPIL[0];
            Test.stopTest();

            for (Planned_Invoicing_Line__c updatedPIL : [SELECT id, Status_Description__c FROM Planned_Invoicing_Line__c WHERE Id = :lstPIL[0].Id]){
                system.assertEquals(System.Label.InvoicingLine_StatusDescription_PendingBillingTeamGO, updatedPIL.Status_Description__c);
            }
        }
    }

    @isTest static void toBeInvoiced() {
        System.runAs(vUserPM){
            
            vAccount.Purchase_Order__c = false;
            update vAccount;

            vContract.Contract_Signed_Date__c = System.Today();
            vContract.Status__c = System.Label.ContractStatus_Signed;
            update vContract;

            Test.startTest();
                insert lstPIL;

                lstPIL[0].GoNoGo__c = 'GO';
                lstPIL[0].ADV_GoNoGo__c = 'GO';
                update lstPIL[0];
            Test.stopTest();

            for (Planned_Invoicing_Line__c updatedPIL : [SELECT id, Status_Description__c FROM Planned_Invoicing_Line__c WHERE Id = :lstPIL[0].Id]){
                system.assertEquals(System.Label.InvoicingLine_StatusDescription_ToBeInvoiced, updatedPIL.Status_Description__c);
            }
        }
    }

    @isTest static void noStatusDescription() {
        System.runAs(vUserPM){
            
            vAccount.Purchase_Order__c = false;
            update vAccount;

            vContract.Contract_Signed_Date__c = System.Today();
            vContract.Status__c = System.Label.ContractStatus_Signed;
            update vContract;

            Test.startTest();
                insert lstPIL;

                lstPIL[0].GoNoGo__c = 'GO';
                lstPIL[0].ADV_GoNoGo__c = 'GO';
                lstPIL[0].Status__c = '03';
                update lstPIL[0];
            Test.stopTest();

            for (Planned_Invoicing_Line__c updatedPIL : [SELECT id, Status_Description__c FROM Planned_Invoicing_Line__c WHERE Id = :lstPIL[0].Id]){
                system.assertEquals(null, updatedPIL.Status_Description__c);
            }
        }
    }

    @isTest static void updateStatusContactInactive() {
        //vUserPM.PAD_BypassValidationRules__c = false;
        //update vUserPM;
        System.runAs(vUserPM){
            vContract.CustomerSignedBy2__c = vEntityContact.Id;
            vContract.RecordTypeId = ContractTriggerHandler.idRecOpCoSingleEdit;
            update vContract;

            vEntityContact.Active__c = false;
            update  vEntityContact;

            Test.startTest();
                try{
                    insert lstPIL;
                    lstPIL[0].Status__c = '01';
                    update lstPIL[0];
                }catch(Exception e){
                    //system.assert(e.getMessage().contains('Please select an active and valid contact.'));
                }
            Test.stopTest();
        }
    }


    @isTest static void checkDeleteRight() {
        System.runAs(vUserPM){
            Test.startTest();
                Map<Id, Planned_Invoicing_Line__c> mapPil= new Map<Id, Planned_Invoicing_Line__c>();
                insert lstPIL;
                for(Planned_Invoicing_Line__c pil : lstPIL)
                    mapPil.put(pil.Id, pil);
                AP12_PlannedInvoicingLines.checkDeleteRight(mapPil);
            Test.stopTest();
        }
    }

    //@isTest static void updatePMO() {
    //    System.runAs(vUserPM){
            
    //        vAccount.Purchase_Order__c = true;
    //        update vAccount;

    //        insert lstPILs;

    //        lstPILs[7].PMO_Ready_for_Invoice__c  = 'GO';
    //        lstPILs[7].PMO_Comments__c = 'test';
    //        lstPILs[7].SO__c = 'test';
    //        lstPILs[7].item__c = '60';
    //        lstPILs[7].N_Purchase_Order__c = '1234';


    //        Test.startTest();
    //            update lstPILs[7];
    //        Test.stopTest();

    ////system.debug('@>' + [SELECT id, Status_Description__c, AXA_GS_Legal_Entity__c, SAP_Account_Number__c, Customer_Operational_Contact__c,
    ////          Customer_Operational_Contact__comer_Operational_Contact_Email__c, Solution__c, Service_Type__c, Contract_Start_Date__c, Contract_End_Date__c,
    ////          SAP_ID__c, Activity_Type__c, Master_WBS_Structure__c, Man_days__c, Rate__c, Amount__c, Invoicing_Date__c, N_Invoice__c
    ////            FROM Planned_Invoicing_Line__c 
    ////            WHERE Id = :lstPILs[7].Id]);

    //        for (Planned_Invoicing_Line__c updatedPIL : [SELECT id, Status_Description__c FROM Planned_Invoicing_Line__c WHERE Id = :lstPILs[7].Id]){
    //            system.assertEquals(System.Label.InvoicingLine_StatusDescription_WaitingADVCheck, updatedPIL.Status_Description__c);
    //        }
    //    }
    //}

    //@isTest static void updateIL_1() {
    //    System.runAs(vUserPM){
            
    //        vAccount.Purchase_Order__c = true;
    //        update vAccount;

    //        insert lstPILs;

    //        lstPILs[7].N_Purchase_Order__c  = '1234';
    //        lstPILs[7].PMO_Ready_for_Invoice__c  = 'GO';
    //        lstPILs[7].status__c = '02 - INVOICING VALIDATION';
    //        lstPILs[7].ADV_GoNoGo__c = 'GO';

    //        Test.startTest();
    //            update lstPILs[7];
    //        Test.stopTest();

    //        for (Planned_Invoicing_Line__c updatedPIL : [SELECT id, Status_Description__c FROM Planned_Invoicing_Line__c WHERE Id = :lstPILs[7].Id]){
    //            system.assertEquals(System.Label.InvoicingLine_StatusDescription_WaitingInvoicingDate, updatedPIL.Status_Description__c);
    //        }
    //    } 
    //}

    //@isTest static void updateIL_2() {
    //    System.runAs(vUserPM){
            
    //        insert lstPILs;

    //        lstPILs[7].N_Purchase_Order__c  = '1234';
    //        lstPILs[7].PMO_Ready_for_Invoice__c = 'GO';
    //        lstPILs[7].status__c = '03-READY FOR INVOICE';
    //        lstPILs[7].ADV_GoNoGo__c = 'NO GO';

    //        Test.startTest();
    //            update lstPILs[7];
    //        Test.stopTest();

    //        for (Planned_Invoicing_Line__c updatedPIL : [SELECT id, Status_Description__c FROM Planned_Invoicing_Line__c WHERE Id = :lstPILs[7].Id]){
    //            system.assertEquals(System.Label.InvoicingLine_StatusDescription_WaitingADVCheck, updatedPIL.Status_Description__c);
    //        }
    //    } 
    //}

    //@isTest static void updateIL_3() {
    //    System.runAs(vUserPM){
            
    //        insert lstPILs;

    //        lstPILs[7].N_Purchase_Order__c  = '1234';
    //        lstPILs[7].PMO_Ready_for_Invoice__c = 'GO';
    //        lstPILs[7].status__c = '03-READY FOR INVOICE';
    //        lstPILs[7].ADV_GoNoGo__c = 'GO';
    //        lstPILs[7].SAP_ID__c = '4568';
    //        lstPILs[7].Activity_Type__c = 'test';


    //        Test.startTest();
    //            update lstPILs[7];
    //        Test.stopTest();

    //        for (Planned_Invoicing_Line__c updatedPIL : [SELECT id, Status_Description__c FROM Planned_Invoicing_Line__c WHERE Id = :lstPILs[7].Id]){
    //            system.assertEquals(System.Label.InvoicingLine_StatusDescription_WaitingInvoicingDate, updatedPIL.Status_Description__c);
    //        }
    //    } 
    //}

    //@isTest static void updateIL_4() {
    //    System.runAs(vUserPM){
            
    //        insert lstPILs;

    //        lstPILs[7].N_Purchase_Order__c  = '1234';
    //        lstPILs[7].PMO_Ready_for_Invoice__c = 'GO';
    //        lstPILs[7].status__c = '03-READY FOR INVOICE';
    //        lstPILs[7].ADV_GoNoGo__c = 'GO';
    //        lstPILs[7].SAP_ID__c = '4568';
    //        lstPILs[7].Activity_Type__c = 'test';
    //        lstPILs[7].Master_WBS_Structure__c = vMasterWBS_2.Id;

    //        Test.startTest();
    //            update lstPILs[7];
    //        Test.stopTest();

    //        for (Planned_Invoicing_Line__c updatedPIL : [SELECT id, Status_Description__c FROM Planned_Invoicing_Line__c WHERE Id = :lstPILs[7].Id]){
    //            system.assertEquals(System.Label.InvoicingLine_StatusDescription_WaitingInvoicingDate, updatedPIL.Status_Description__c);
    //        }
    //    } 
    //}
}