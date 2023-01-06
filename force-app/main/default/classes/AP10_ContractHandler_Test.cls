@isTest
public class AP10_ContractHandler_Test {

    //14-September-2017 - MRA : Updated & optimised all test methods to fix error 'Too many SOQL'
                              
    static user testUser;
    static ContentWorkspace workspace;
    static User vUserPM;
    static User vUserOO;
    static User vUserPMOADV; 
    static Account vAccount;
    static Account vEAccount;
    static Contact vEntityContact;
    static Product__c vProduct;
    static Contract__c vContract;
    static Planned_Invoicing_Line__c vPInvLine1;
    static Planned_Invoicing_Line__c vPInvLine2;
    static List<Planned_Invoicing_Line__c> lstPIL = new List<Planned_Invoicing_Line__c>();
    static Id InvDateRecordTypeId;
    static Id InvLinRecordTypeId;
    static Id InvCondRecordTypeId;
    static Invoicing_Parameter__c a1ParmInvLin,a1ParmInvCond,a2ParmInvCond,a2ParmInvLin,a3ParmInvCond,a3ParmInvLin,a4ParmInvLin,aParmInvDate,a5ParmInvLin;  
    static List <Invoicing_Parameter__c> ParmLineList;  
   // static id recordTypeAGSSpainEditId;
    static List<Id> lstOppId;
    static Opportunity vOpp1;
    static Opportunity vOpp2;
    static Opportunity vOpp3;
    //static Contract__c c; 
    static User adminUser;

    static{
        adminUser = new User();
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
        //adminUser.PAD_BypassValidationRules__c = true;
        //adminUser.PAD_BypassTrigger__c = 'AP52;AP1012;AP22;';
        insert adminUser;
        // Create PM user
        vUserPM = AP05_TestDataFactory.createPMUser(true);
        vUserPM.PAD_BypassValidationRules__c = true;
        vUserPM.PAD_BypassWorkflows__c = true;
        update vUserPM;
        
        System.runAs(vUserPM) {

            // Create OO user
            vUserOO = AP05_TestDataFactory.createOOUser();
            vUserPMOADV = AP05_TestDataFactory.createPMOADVUser();

            // Create the legal entity (aka billing entity) account
            vAccount = AP05_TestDataFactory.createLegalEntityAccount(vUserPM);

            workspace=TestFactory.createWorkspace('Workspace_test','Workspace_test',true);
            insert workspace;   

            // Create the entity account
            vEAccount = AP05_TestDataFactory.createEntityAccount(vUserPM);

            // Create the couple Entity - Billing Entity on Parent Entity
            vAccount = AP05_TestDataFactory.linkLEgalEntityToEntity(vEAccount, vAccount);

            // Create the entity contact related to the account
            vEntityContact = AP05_TestDataFactory.createEntityContact(vAccount);
            
            //Product
            vProduct = AP05_TestDataFactory.createProduct(vUserOO);

            //Contract
            vContract = AP05_TestDataFactory.createContract(vProduct, vAccount, vUserPM, vEntityContact);    

            //recordtype contract
            //recordTypeAGSSpainEditId=Schema.SObjectType.Contract__c.getRecordTypeInfosByName().get('AXA GS Spain').getRecordTypeId();

            vPInvLine1 = AP05_TestDataFactory.createIL(vContract, 100,'Description 1', '01', System.Today(), System.Today().addMonths(4), vEntityContact.Id);
            
              
            //Planned Invoicing Line 2
            //vPInvLine2 = AP05_TestDataFactory.createPInvoicingLine2(vContract,'Description 2'); 
            vPInvLine2 = AP05_TestDataFactory.createIL(vContract, 100,'Description 2', '01', System.Today(), System.Today().addMonths(4), vEntityContact.Id); 

            lstPIL.add(vPInvLine1);
            lstPIL.add(vPInvLine2);
            insert lstPIL;

            //
            // create invoicing parameters
            //
            InvDateRecordTypeId = Schema.SObjectType.Invoicing_Parameter__c.getRecordTypeInfosByName().get('Invoicing Date').getRecordTypeId();
            InvLinRecordTypeId = Schema.SObjectType.Invoicing_Parameter__c.getRecordTypeInfosByName().get('Invoicing Line').getRecordTypeId();
            InvCondRecordTypeId = Schema.SObjectType.Invoicing_Parameter__c.getRecordTypeInfosByName().get('Invoicing Condition').getRecordTypeId();

            ParmLineList = New List <Invoicing_Parameter__c> {
                new Invoicing_Parameter__c (Invoicing_Date__c = System.Today(), RecordTypeId = InvDateRecordTypeId, Parameter_type__c = 'Invoicing Date'),
                new Invoicing_Parameter__c (Name = '100% Beginning of service', RecordTypeId = InvCondRecordTypeId, Parameter_type__c = 'Invoicing Condition'), 
                new Invoicing_Parameter__c (Name = '100% Beginning of year', RecordTypeId = InvCondRecordTypeId, Parameter_type__c = 'Invoicing Condition'),
                new Invoicing_Parameter__c (Name = '0%,50%,50%', RecordTypeId = InvCondRecordTypeId, Parameter_type__c = 'Invoicing Condition'),
                new Invoicing_Parameter__c (Invoicing_Date__c = System.Today().addMonths(-4), RecordTypeId = InvDateRecordTypeId, Parameter_type__c = 'Invoicing Date'),
                new Invoicing_Parameter__c (Invoicing_Date__c = System.Today().addMonths(-3), RecordTypeId = InvDateRecordTypeId, Parameter_type__c = 'Invoicing Date'),
                new Invoicing_Parameter__c (Invoicing_Date__c = System.Today().addMonths(-2), RecordTypeId = InvDateRecordTypeId, Parameter_type__c = 'Invoicing Date'),
                new Invoicing_Parameter__c (Invoicing_Date__c = System.Today().addMonths(-1), RecordTypeId = InvDateRecordTypeId, Parameter_type__c = 'Invoicing Date'),
                new Invoicing_Parameter__c (Invoicing_Date__c = System.Today().addMonths(1), RecordTypeId = InvDateRecordTypeId, Parameter_type__c = 'Invoicing Date'),
                new Invoicing_Parameter__c (Invoicing_Date__c = System.Today().addMonths(2), RecordTypeId = InvDateRecordTypeId, Parameter_type__c = 'Invoicing Date'),
                new Invoicing_Parameter__c (Invoicing_Date__c = System.Today().addMonths(3), RecordTypeId = InvDateRecordTypeId, Parameter_type__c = 'Invoicing Date'),
                    new Invoicing_Parameter__c (Invoicing_Date__c = System.Today().addMonths(4), RecordTypeId = InvDateRecordTypeId, Parameter_type__c = 'Invoicing Date'),
                    new Invoicing_Parameter__c (Invoicing_Date__c = System.Today().addMonths(5), RecordTypeId = InvDateRecordTypeId, Parameter_type__c = 'Invoicing Date'),
                    new Invoicing_Parameter__c (Invoicing_Date__c = System.Today().addMonths(6), RecordTypeId = InvDateRecordTypeId, Parameter_type__c = 'Invoicing Date'),
                    new Invoicing_Parameter__c (Invoicing_Date__c = System.Today().addMonths(7), RecordTypeId = InvDateRecordTypeId, Parameter_type__c = 'Invoicing Date'),
                    new Invoicing_Parameter__c (Invoicing_Date__c = System.Today().addMonths(7), RecordTypeId = InvDateRecordTypeId, Parameter_type__c = 'Invoicing Date'),
                    new Invoicing_Parameter__c (Invoicing_Date__c = System.Today().addMonths(8), RecordTypeId = InvDateRecordTypeId, Parameter_type__c = 'Invoicing Date'),
                    new Invoicing_Parameter__c (Invoicing_Date__c = System.Today().addMonths(10), RecordTypeId = InvDateRecordTypeId, Parameter_type__c = 'Invoicing Date')

            };
            insert ParmLineList;

            List <Invoicing_Parameter__c> ParmLineList1 = New List <Invoicing_Parameter__c> {
                new Invoicing_Parameter__c (Name = '100% Beginning of service', Invoicing_Description__c = '100% Beginning of service', Parent_For_Invoicing_Line__c = ParmLineList[1].id, RecordTypeId = InvLinRecordTypeId, Parameter_type__c = 'Invoicing Line', Invoicing_Date_Type__c = 'Start Date', Percent__c = 100.00),
                new Invoicing_Parameter__c (Name = '100% Beginning of year', Invoicing_Description__c = '100% Beginning of year', Invoicing_Predefined_Date__c = ParmLineList[0].id, Parent_For_Invoicing_Line__c = ParmLineList[2].id, RecordTypeId = InvLinRecordTypeId, Parameter_type__c = 'Invoicing Line', Invoicing_Date_Type__c = 'Fixed Date', Percent__c = 100.00),
                new Invoicing_Parameter__c (Name = '50% half of service', Invoicing_Description__c = '50% half of service', Parent_For_Invoicing_Line__c = ParmLineList[3].id, RecordTypeId = InvLinRecordTypeId, Parameter_type__c = 'Invoicing Line', Invoicing_Date_Type__c = 'Percent', Percent__c = 50.00),
                new Invoicing_Parameter__c (Name = '50% end of service', Invoicing_Description__c = '50% end of service', Parent_For_Invoicing_Line__c = ParmLineList[3].id, RecordTypeId = InvLinRecordTypeId, Parameter_type__c = 'Invoicing Line', Invoicing_Date_Type__c = 'End Date', Percent__c = 50.00),
                new Invoicing_Parameter__c (Name = '50% end of service', Invoicing_Description__c = '50% end of service', Parent_For_Invoicing_Line__c = ParmLineList[3].id, RecordTypeId = InvLinRecordTypeId, Parameter_type__c = 'Invoicing Line', Invoicing_Date_Type__c = 'Percent', Percent__c = 50.00)
            };
            insert ParmLineList1;
            
            lstOppId = new List<Id>();
            vOpp1 = AP05_TestDataFactory.createOpportunity(vEAccount, vProduct, 'opportunity01', true);
            lstOppId.add(vOpp1.Id);
            vOpp2 = AP05_TestDataFactory.createOpportunity(vEAccount, vProduct, 'opportunity02', true);
            lstOppId.add(vOpp2.Id);
            vOpp3 = AP05_TestDataFactory.createOpportunity(vEAccount, vProduct, 'opportunity03', true);
            lstOppId.add(vOpp3.Id);
            
            system.debug('##Invoicing parameters datatest created'   + ParmLineList);

            //c = [SELECT Id, Account__c, C_Account__c, Global_Amount__c, Invoicing_Condition__c, EndDate__c, Language__c FROM Contract__c WHERE Name =: AP05_TestDataFactory.CONTRACT_NAME][0];
        }

    } // generate Data test

    @isTest
    Public static void  ContractGeneralLineTest_V0() {

        System.runAs(vUserPM) {
            string Msg;
            string aEmptyStr;
            //Contract__c Ctr = [SELECT Id, Account__c, C_Account__c, Global_Amount__c, Invoicing_Condition__c, EndDate__c, Language__c FROM Contract__c WHERE Name =: AP05_TestDataFactory.CONTRACT_NAME][0];
            vContract.Global_Amount__c = 1000;
            vContract.Invoicing_Condition__c = System.Label.InvoicingCondition_100BeginningOfService;
            vContract.EndDate__c = null;

            Test.StartTest();
                Update vContract;
                Msg = AP10_ContractHandler.CheckContract(vContract); 
            Test.StopTest();

            System.debug('>### ContractGeneralLineTest_V0 Msg '+Msg);

            System.assert( Msg != aEmptyStr);
            System.assertEquals('The field End Date is mandatory to generate Invoicing lines.',Msg.trim());
        }

    }

    @isTest
    Public static void  ContractGeneralLineTest_V1() {

        System.runAs(vUserPM) {
            string Msg;
            string aEmptyStr;
            //Contract__c Ctr = [SELECT Id, Account__c, C_Account__c, Global_Amount__c, Invoicing_Condition__c, EndDate__c, Language__c FROM Contract__c WHERE Name =: AP05_TestDataFactory.CONTRACT_NAME][0];
            vContract.Global_Amount__c = 50000;
            vContract.Invoicing_Condition__c = 'This is a wrong Invoicing Condition';
            vContract.EndDate__c = System.Today() + 365;

            Test.StartTest();
                Update vContract;
                Msg = AP10_ContractHandler.GenerateAContractPInvoicingLine(vContract.id);
                
            Test.StopTest();

            System.debug('>### ContractGeneralLineTest_V1 Msg '+Msg);

            System.assert( Msg != aEmptyStr);
            //System.assert(Msg.contains('Invoicing Parameter Error, please contact your System Admin for Contract Id'));
        }
    }

    @isTest
    Public static void  ContractGeneralLineTest_V2() {

        System.runAs(vUserPM) {
            string Msg;
            string aEmptyStr;
            //Contract__c Ctr = [SELECT Id, Account__c, C_Account__c, Global_Amount__c, Invoicing_Condition__c, EndDate__c, Language__c FROM Contract__c WHERE Name =: AP05_TestDataFactory.CONTRACT_NAME][0];
            vContract.Global_Amount__c = 50000;
            vContract.Language__c = 'French';
            vContract.EndDate__c = System.Today() + 365;
            vContract.Invoicing_Condition__c = System.Label.InvoicingCondition_100BeginningOfService;

            test.StartTest();
                update vContract;       
                Msg = AP10_ContractHandler.GenerateAContractPInvoicingLine(vContract.id);    
            test.StopTest();

            System.debug('>### ContractGeneralLineTest_V2 Msg '+Msg);
            System.assertEquals('DmlError', Msg);
        }

    }


    @isTest
    Public static void  ContractGeneralLineTest_V3() {

        System.runAs(vUserPM) {
        
            string Msg;
            string aEmptyStr;

            // generate lines   for 100% Beginning of year one line generated + French
            //Contract__c Ctr = [SELECT Id, Account__c, C_Account__c, Global_Amount__c, Invoicing_Condition__c, EndDate__c, Language__c FROM Contract__c WHERE Name =: AP05_TestDataFactory.CONTRACT_NAME][0];
            vContract.Global_Amount__c = 50000;
            vContract.Language__c = 'French';
            vContract.EndDate__c = System.Today() + 365;
            vContract.Invoicing_Condition__c = System.Label.InvoicingCondition_100BeginningOfService;

            Test.StartTest();
                Update vContract;
                Msg = AP10_ContractHandler.GenerateAContractPInvoicingLine(vContract.id);
                //List <Planned_Invoicing_Line__c> InvLin2 = New List <Planned_Invoicing_Line__c> ([select Id, Name, Invoicing_Date__c, Percent__c, Description__c From Planned_Invoicing_Line__c where Contract2__c = :vContract.id]);
                //System.debug('##List Created Lines fixed date'   + InvLin2);
                //System.assert(1 == InvLin2.size());
            Test.stopTest();

            System.debug('>### ContractGeneralLineTest_V3 Msg '+Msg);
            //System.assertEquals(null, Msg);
        }
    }

    @isTest
    Public static void  ContractGeneralLineTest_V4() {
        
        System.runAs(vUserPM) {
            string Msg;
            string aEmptyStr;

            // generate lines   for 0,50%,50% two line generated
            //Contract__c Ctr = [SELECT Id, Account__c, C_Account__c, Global_Amount__c, Invoicing_Condition__c, EndDate__c, Language__c FROM Contract__c WHERE Name =: AP05_TestDataFactory.CONTRACT_NAME][0];
            vContract.Invoicing_Condition__c = System.Label.InvoicingCondition_100BeginningOfService;
            Test.startTest();
                Update vContract;
                Msg = AP10_ContractHandler.GenerateAContractPInvoicingLine(vContract.id);
                system.debug('##Msg return 0%,50%,50%'   + Msg);
                List <Planned_Invoicing_Line__c> InvLin3 = New List <Planned_Invoicing_Line__c> ([select Id, Name, Invoicing_Date__c, Percent__c, Description__c From Planned_Invoicing_Line__c where Contract2__c = :vContract.id]);

                System.debug('>### ContractGeneralLineTest_V4 Msg '+Msg);
                System.debug('##List Created Lines Percent'   + InvLin3);
                //created 2, expect to create 3
                System.assertEquals(0,InvLin3.size());
            Test.StopTest();
        }        
    }

    @isTest
    Public static void  ContractGeneralLineTest_V5() {

        System.runAs(vUserPM) {
            string Msg;
            string aEmptyStr;
            //Contract__c Ctr = [SELECT Id, Account__c, C_Account__c, Global_Amount__c, Invoicing_Condition__c, EndDate__c, Language__c FROM Contract__c WHERE Name =: AP05_TestDataFactory.CONTRACT_NAME][0];
            vContract.Global_Amount__c = 50000;
            vContract.Language__c = 'French';
            vContract.StartDate__c = System.Today().addMonths(-1);
            vContract.EndDate__c = System.Today().addDays(1); 
            vContract.ServiceType__c = AP05_TestDataFactory.CONTRACT_STYPE_BAU;
            vContract.InvoicingMethod__c = AP05_TestDataFactory.CONTRACT_INVMETHOD_FIXEDPRICE;
            vContract.Invoicing_Condition__c = System.Label.InvoicingCondition_100BeginningOfService;

            test.StartTest();
                update vContract;       
                //Msg = AP10_ContractHandler.GenerateAContractPInvoicingLine(vContract.id);    
            test.StopTest();

            System.debug('>### ContractGeneralLineTest_V2 Msg '+Msg);
           //System.assertEquals(null, Msg);
        }
    }

    @isTest
    Public static void  ContractGeneralLineTest_30DownPay() {

        System.runAs(vUserPM) {
            string Msg;
            string aEmptyStr;
            vContract.Global_Amount__c = 50000;
            vContract.StartDate__c = System.Today().addMonths(-1);
            vContract.EndDate__c = System.Today().addMonths(10);
            vContract.ServiceType__c = AP05_TestDataFactory.CONTRACT_STYPE_BAU;
            vContract.InvoicingMethod__c = AP05_TestDataFactory.CONTRACT_INVMETHOD_FIXEDPRICE;
            vContract.Invoicing_Condition__c = System.Label.InvoicingCondition_QuarterlyBeginning;

            test.StartTest();
            update vContract;
            //Msg = AP10_ContractHandler.GenerateAContractPInvoicingLine(vContract.id);
            test.StopTest();

            System.debug('>### ContractGeneralLineTest_V2 Msg '+Msg);
           // System.assertEquals(null, Msg);
        }
    }

//    @isTest
//    Public static void  AttachContractTestP3() {
//
//        System.runAs(vUserPM) {
//            string Msg;
//            string aEmptyStr;
//            //Contract__c c = [SELECT Id, Global_Amount__c, Planned_Invoicing_Lines_Amount__c FROM Contract__c WHERE Name =: AP05_TestDataFactory.CONTRACT_NAME][0];
//
//            Test.StartTest();
//                // Test Contact.trigger AP12_Contacts.cls and AP_12PDFContractsAttached
//                Msg = AP10_ContractHandler.attachContract(vContract.id);
//                //c = [SELECT PDF_Status__c, Status__c, Id, CustomerSignedBy__r.Title, AXA_GS_Signed_By__c, AXA_GS_Signed_By__r.Title, EndDate__c, Global_Amount__c, StartDate__c, AXA_GO_Legal_Entity__c, ServiceType__c, InvoicingMethod__c, Invoicing_Condition__c, Language__c, Account__r.MSA__c, SOW_Operational__c, Service_Type__c, Product__r.Name, CustomerSignedBy__c,  RecordTypeId, RecordType.Name, Amendment_to__c FROM Contract__c WHERE Name =: AP05_TestDataFactory.CONTRACT_NAME][0];
//                Contact ec = [SELECT Title from Contact WHERE Id =: vContract.CustomerSignedBy__c][0];
//                ec.Title = AP05_TestDataFactory.CONTACT_ENTITY_NEWTITLE;
//                update ec;
//
//                System.debug('>### AttachContractTestP3 01 Msg '+Msg);
//
//               //c = [SELECT PDF_Status__c, Status__c, Id, CustomerSignedBy__r.Title, AXA_GS_Signed_By__c, AXA_GS_Signed_By__r.Title, EndDate__c, Global_Amount__c, StartDate__c, AXA_GO_Legal_Entity__c, ServiceType__c, InvoicingMethod__c, Invoicing_Condition__c, Language__c, Account__r.MSA__c, SOW_Operational__c, Service_Type__c, Product__r.Name, CustomerSignedBy__c,  RecordTypeId, RecordType.Name, Amendment_to__c FROM Contract__c WHERE Name =: AP05_TestDataFactory.CONTRACT_NAME][0];
//
//                // Test PlannedInvoicingLine.trigger AP12_PlannedInvoicingLines.cls and AP_12PDFContractsAttached
//
//                Msg = AP10_ContractHandler.attachContract(vContract.id);
//
//                System.debug('>### AttachContractTestP3 02 Msg '+Msg);
//
//                //c = [SELECT Id, PDF_Status__c FROM Contract__c WHERE Name =: AP05_TestDataFactory.CONTRACT_NAME][0];
//                Planned_Invoicing_Line__c pil = [SELECT Description__c from Planned_Invoicing_Line__c WHERE Contract2__c =: vContract.id][0];
//                pil.Description__c = AP05_TestDataFactory.CONTRACT_PDFSTATUS_NOTUPDATED;
//                update pil;
//
//                //c = [SELECT PDF_Status__c FROM Contract__c WHERE Name =: AP05_TestDataFactory.CONTRACT_NAME][0];
//
//                Contract__c c = [SELECT AXA_GS_Signed_By__c, Id, StartDate__c, EndDate__c, SOW_Operational__c, Global_Amount__c FROM Contract__c WHERE Name =: AP05_TestDataFactory.CONTRACT_NAME][0];
//                c.StartDate__c = null;
//                c.EndDate__c = null;
//                c.SOW_Operational__c = null;
//                c.Global_Amount__c = 1000;
//                c.AXA_GS_Signed_By__c = null;
//                update(c);
//                Msg = AP10_ContractHandler.attachContract(c.id);
//
//
//            Test.stopTest();
//
//
//        }
//    }

   /*@isTest
    Public static void  AttachContractTestP4_ServiceComplexTrue() {
        System.runAs(vUserPM) {
            string Msg;
            test.startTest();
                vAccount.MSA__c = true;
                vContract.SOW_Type__c = 'Service Complexe';
                
                update vContract;
                update vAccount;
                Msg = AP10_ContractHandler.attachContract(vContract.id);
            test.stopTest();

            System.debug('>### AttachContractTestP4 Msg '+Msg);
            //System.assertEquals('The field Start Date is mandatory', Msg.trim());
        }
    } */
    /*@isTest 
    /*Public static void  AttachContractTestP4_PentestTrue() {
        System.runAs(vUserPM) {
            string Msg;
            
            test.startTest();
                vAccount.MSA__c = true;
                vContract.SOW_Type__c = AP_Constant.SOW_PENTEST;
                
                update vContract;
                update vAccount;
                Msg = AP10_ContractHandler.attachContract(vContract.id);
            test.stopTest();

            System.debug('>### AttachContractTestP4 Msg '+Msg);
            //System.assertEquals('The field Start Date is mandatory', Msg.trim());
        }
    } */
    /*@isTest 
    Public static void  AttachContractTestP4_EnveloppeTrue() {
        System.runAs(vUserPM) {
            string Msg;
            
            test.startTest();
                vAccount.MSA__c = true;
                vContract.SOW_Type__c = AP_Constant.SOW_ENVELOPPE;
                
                update vContract;
                update vAccount;
                Msg = AP10_ContractHandler.attachContract(vContract.id);
            test.stopTest();

            System.debug('>### AttachContractTestP4 Msg '+Msg);
            //System.assertEquals('The field Start Date is mandatory', Msg.trim());
        }
    }*/
    /*@isTest 
    Public static void  AttachContractTestP4_CesameTrue() {
        System.runAs(vUserPM) {
            string Msg;
            
            test.startTest();
                vAccount.MSA__c = true;
                vContract.SOW_Type__c =  AP_Constant.SOW_CESAME;
                
                update vContract;
                update vAccount;
                Msg = AP10_ContractHandler.attachContract(vContract.id);
            test.stopTest();

            System.debug('>### AttachContractTestP4 Msg '+Msg);
            //System.assertEquals('The field Start Date is mandatory', Msg.trim());
        }
    } */
    /*@isTest 
    Public static void  AttachContractTestP4_ConsultingTrue() {
        System.runAs(vUserPM) {
            string Msg;
            
            test.startTest();
                vAccount.MSA__c = true;
                vContract.SOW_Type__c = AP_Constant.SOW_CONSULTING;
                
                update vContract;
                update vAccount;
                Msg = AP10_ContractHandler.attachContract(vContract.id);
            test.stopTest();

            System.debug('>### AttachContractTestP4 Msg '+Msg);
            //System.assertEquals('The field Start Date is mandatory', Msg.trim());
        }
    } */
    /*@isTest 
    Public static void  AttachContractTestP4_ServiceComplexFalse() {
        System.runAs(vUserPM) {
            string Msg;
            test.startTest();
                vContract.SOW_Type__c = 'Service Complexe';
                update(vContract);
                Msg = AP10_ContractHandler.attachContract(vContract.id);
            test.stopTest();

            System.debug('>### AttachContractTestP4 Msg '+Msg);
            //System.assertEquals('The field Start Date is mandatory', Msg.trim());
        }
    } */
    /*@isTest 
    Public static void  AttachContractTestP4_PentestFalse() {
        System.runAs(vUserPM) {
            string Msg;
            test.startTest();
                vContract.SOW_Type__c = 'Pentest';
                update(vContract);
                Msg = AP10_ContractHandler.attachContract(vContract.id);
            test.stopTest();

            System.debug('>### AttachContractTestP4 Msg '+Msg);
            //System.assertEquals('The field Start Date is mandatory', Msg.trim());
        }
    } */
    /*@isTest 
    Public static void  AttachContractTestP4_ConsultingFalse() {
        System.runAs(vUserPM) {
            string Msg;
            test.startTest();
                vContract.SOW_Type__c = AP_Constant.SOW_CONSULTING;
                update(vContract);
                Msg = AP10_ContractHandler.attachContract(vContract.id);
            test.stopTest();

            System.debug('>### AttachContractTestP4 Msg '+Msg);
            //System.assertEquals('The field Start Date is mandatory', Msg.trim());
        }
    }*/
    /*@isTest 
    Public static void  AttachContractTestP4_CesameFalse() {
        System.runAs(vUserPM) {
            string Msg;
            test.startTest();
                vContract.SOW_Type__c =  AP_Constant.SOW_CESAME;
                update(vContract);
                Msg = AP10_ContractHandler.attachContract(vContract.id);
            test.stopTest();

            System.debug('>### AttachContractTestP4 Msg '+Msg);
            //System.assertEquals('The field Start Date is mandatory', Msg.trim());
        }
    }   */
    /*@isTest 
    Public static void  AttachContractTestP4_EnvelopFalse() {
        System.runAs(vUserPM) {
            string Msg;
            test.startTest();
                vContract.AXA_GO_Legal_Entity__c = 'GIE AXA Group Operations France';
                vContract.SOW_Type__c = 'Enveloppe';
                vContract.recordTypeId = Schema.SObjectType.Contract__c.getRecordTypeInfosByName().get(AP_Constant.RT_CONTRACT_EDIT_LIGHTNING_LABEL).getRecordTypeId();
                update(vContract);
                Msg = AP10_ContractHandler.attachContract(vContract.id);
            test.stopTest();
        }
    }*/
    @isTest 
    Public static void  AttachContractTestP4_SASTrue() {          
        System.runAs(vUserPM) {
            string Msg;
            vAccount.MSA__c = true;
            vContract.AXA_GO_Legal_Entity__c = 'AXA Group Operations SAS';
            //vContract.recordTypeId = Schema.SObjectType.Contract__c.getRecordTypeInfosByName().get('Amendment Edit').getRecordTypeId();

            test.StartTest();
                update vAccount;
                update vContract;       
                Msg = AP10_ContractHandler.attachContract(vContract.id);  
            test.StopTest();
        }
    } 
    @isTest 
    Public static void  AttachContractTestP4_SASFalse() {
        System.runAs(vUserPM) {
            string Msg;
            vAccount.MSA__c = true;
            vContract.AXA_GO_Legal_Entity__c = 'AXA Group Operations SAS';

            test.StartTest();
                update vAccount;
                update vContract;       
                Msg = AP10_ContractHandler.attachContract(vContract.id);  
            test.StopTest();
        }
    }
    @isTest 
    Public static void  AttachContractTestP5() {

        system.runAs(vUserPM){
            string Msg;
            test.startTest();
                //Contract__c c = [SELECT AXA_GS_Signed_By__c, Id, StartDate__c, EndDate__c, SOW_Operational__c, Global_Amount__c FROM Contract__c WHERE Name =: AP05_TestDataFactory.CONTRACT_NAME][0];
                vContract.StartDate__c = null;
                vContract.EndDate__c = null;          
                vContract.Invoicing_Condition__c = null;
                vContract.Global_Amount__c = 100;
                vContract.AXA_GS_Signed_By__c = null;
                vContract.SOW_Type__c = AP_Constant.SOW_PRODUCT_TEMPLATE;
                update(vContract);
                Msg = AP10_ContractHandler.attachContract(vContract.id);
            test.stopTest();

            System.debug('>### AttachContractTestP5 Msg '+Msg);
            //System.assertEquals('The field Start Date is mandatory', Msg.trim());
        }
    }

    @isTest 
    Public static void  AttachContractTestP6() {

        System.runAs(vUserPM) {
            string Msg;
            test.startTest();
                //Contract__c c = [SELECT AXA_GS_Signed_By__c, Id, StartDate__c, EndDate__c, SOW_Operational__c, Global_Amount__c FROM Contract__c WHERE Name =: AP05_TestDataFactory.CONTRACT_NAME][0];
                vContract.Amendment_to__c=null;
                vContract.StartDate__c = null;
                vContract.EndDate__c = null;          
                vContract.Invoicing_Condition__c = null;
                vContract.Global_Amount__c = 100;
                vContract.AXA_GS_Signed_By__c = null;
                vContract.SOW_Type__c = AP_Constant.SOW_PRODUCT_TEMPLATE;
                update(vContract);
                Msg = AP10_ContractHandler.attachContract(vContract.id);
            test.stopTest();

            System.debug('>### AttachContractTestP6 Msg '+Msg);
            //System.assertEquals('The field Start Date is mandatory', Msg.trim());
        }
    }  

    @isTest
    Public static void  ContractGeneralLineTest_V6() {

        System.runAs(vUserPM) {
            string Msg;
            string aEmptyStr;
            //Contract__c Ctr = [SELECT Id, Account__c, C_Account__c, Global_Amount__c, Invoicing_Condition__c, EndDate__c, Language__c FROM Contract__c WHERE Name =: AP05_TestDataFactory.CONTRACT_NAME][0];
            vContract.Global_Amount__c = 0;
            vContract.Invoicing_Condition__c = '';
            vContract.EndDate__c = null;

            Test.StartTest();
                Update vContract;
                Msg = AP10_ContractHandler.CheckContract(vContract); 
            Test.StopTest();

            System.debug('>### ContractGeneralLineTest_V0 Msg '+Msg);

            System.assert( Msg != aEmptyStr);
            System.assert(Msg.contains('The field End Date is mandatory'));
        }
    }

    @isTest
    Public static void  ContractGeneralLineTest_V7() {

        System.runAs(vUserPM) {
            string Msg;
            string aEmptyStr;

            vAccount.MSA_ATS_Reference__c = 'test msa';
            vAccount.MSA_ATS_Date__c = Date.today();

            vContract.Global_Amount__c = 50000;
            vContract.Language__c = 'French';
            vContract.EndDate__c = System.Today() + 365;
            vContract.Invoicing_Condition__c = System.Label.InvoicingCondition_100BeginningOfService;
            vContract.recordTypeId = Schema.SObjectType.Contract__c.getRecordTypeInfosByName().get(AP_Constant.RT_CONTRACT_EDIT_LIGHTNING_LABEL).getRecordTypeId();
            vContract.SOW_Type__c = AP_Constant.SOW_PRODUCT_TEMPLATE;

            test.StartTest();
                update vAccount;
                update vContract;       
                Msg = AP10_ContractHandler.GenerateAContractPInvoicingLine(vContract.id);    
            test.StopTest();

            Contract__c ctrChk = [SELECT account__r.MSA_ATS_Reference__c, recordTypeId, SOW_Type__c from Contract__c where id = :vContract.Id];

            System.debug('>### ctrChk '+ ctrChk);
            System.debug('>### ContractGeneralLineTest_V2 Msg '+ Msg);
            System.assertEquals('DmlError', Msg);
        }
    }

    /*@isTest 
    Public static void sendToPeopleSoftInsRights() {
        System.runAs(vUserPM) {
            string Msg;
            
            test.startTest();
                Msg = AP10_ContractHandler.sendCtrlightoPeopleSoft(vContract.id);
            test.stopTest();
            System.assertEquals('You do not have sufficient rights to send ILs to PeopleSoft', Msg.trim());
        }
    }*/

    // 06-JUL-20 - ARA 
    /*@isTest 
    Public static void sendToPeopleSoftHasRights() {
        
        Test.setMock(WebServiceMock.class, new WS02_CallSAPWSMock('S', vPInvLine1.Id, vPInvLine1.Contract2__c));
        System.runAs(adminUser) {
            string Msg;
            
            test.startTest();
                Msg = AP10_ContractHandler.sendCtrlightoPeopleSoft(vContract.id);
            test.stopTest();
            System.assertEquals('', Msg.trim());
        }
    }*/
    
    // 01-JUL-20 - ARA 
    @isTest
    public static void pushCreationToOpportunityTest(){
        System.runAs(vUserPM) {           
            test.startTest();
                AP10_ContractHandler.pushCreationToOpportunity(lstOppId);
            test.stopTest();

            System.assertEquals(3, [SELECT count() FROM Opportunity WHERE TECH_ContractStatus__c = 'Draft']);
        }
    }
    
    //@isTest 
    //Public static void  sendToPeopleSoftILReq() {
    //    System.runAs(vUserPMOADV) {
    //        string Msg;
            
    //        test.startTest();
    //            PDFContractAttached__c pdfContractAttached = new PDFContractAttached__c();
    //            pdfContractAttached.PDFStatus__c = 'Updated';
    //            insert pdfContractAttached;

    //            //Getting back the Contract and attached it to the controller
    //            Contract__c c = [SELECT Owner.Name, Owner.Email, Notify_Validation__r.Name, Notify_Validation__r.Email, Status__c, Id, CustomerSignedBy__r.Title, AXA_GS_Signed_By__c, AXA_GS_Signed_By__r.Title, 
    //                             EndDate__c, Global_Amount__c, StartDate__c , AXA_GO_Legal_Entity__c, ServiceType__c, InvoicingMethod__c, Invoicing_Condition__c, Invoicing_Parameter__c, Language__c, Account__r.MSA__c, 
    //                             SOW_Operational__c, Service_Type__c, Product__r.Name, CustomerSignedBy__c, PDF_Status__c, PDFContrAtt__c, PDFContrAtt__r.PDFStatus__c, RecordType.Name, RecordTypeId, Amendment_to__c, 
    //                             Notify_Validation__c, Account__r.Name, Account__r.Purchase_Order__c, Peoplesoft_Sync__c
    //                             FROM Contract__c 
    //                             WHERE id = :vContract.id];
    //            VFC07_ContractDetailDashboard controller = new VFC07_ContractDetailDashboard(new ApexPages.StandardController(c));

    //            c.PDFContrAtt__c = pdfContractAttached.Id;
    //            c.Peoplesoft_Sync__c = false;
    //            update c; 

    //            List<Planned_Invoicing_Line__c> lstnewPIL = new List<Planned_Invoicing_Line__c>();

    //            lstnewPIL.add(AP05_TestDataFactory.createIL(c, 'descri1', '02'));
    //            lstnewPIL.add(AP05_TestDataFactory.createIL(c, 'descri2', '02'));

    //            insert lstnewPIL;

    //            Contract__c ctr_updated = [SELECT Owner.Name, Owner.Email, Notify_Validation__r.Name, Notify_Validation__r.Email, Status__c, Id, CustomerSignedBy__r.Title, AXA_GS_Signed_By__c, AXA_GS_Signed_By__r.Title, 
    //                                       EndDate__c, Global_Amount__c, StartDate__c , AXA_GO_Legal_Entity__c, ServiceType__c, InvoicingMethod__c, Invoicing_Condition__c, Invoicing_Parameter__c, Language__c, 
    //                                       Account__r.MSA__c, SOW_Operational__c, Service_Type__c, Product__r.Name, CustomerSignedBy__c, PDF_Status__c, PDFContrAtt__c, PDFContrAtt__r.PDFStatus__c, RecordType.Name, 
    //                                       RecordTypeId, Amendment_to__c, Notify_Validation__c, Account__r.Name, Account__r.Purchase_Order__c, Peoplesoft_Sync__c
    //                                       FROM Contract__c 
    //                                       WHERE id = :vContract.id];
    //            Msg = AP10_ContractHandler.sendCtrlightoPeopleSoft(vContract.id);
    //        test.stopTest();
    //        System.assertEquals('At least one Draft Invoicing Line is required to complete this action', Msg.trim());
    //    }
    //}
} // Class