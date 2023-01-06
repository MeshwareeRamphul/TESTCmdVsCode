@isTest
private class LC03_GenerateInvoicingLines_Test {
/*
----------------------------------------------------------------------
-- - Name          : LC03_GenerateInvoicingLines_Test
-- - Author        : Spoon Consulting 
-- - Description   : Test class of LC03_GenerateInvoicingLines
--                   
-- Maintenance History:
--
-- Date         Name  Version  Remarks
-- -----------  ----  -------  ---------------------------------------
-- 26-APRIL-2019   ZHE    1.0    Intitial version
----------------------------------------------------------------------
**********************************************************************
*/
	static user testUser;
    static ContentWorkspace workspace;
    static User vUserOO;
    static Account vAccount;
    static Account vEAccount;
    static Contact vEntityContact;
    static Product__c vProduct;
    static Contract__c vContract;
    static Master_WBS_Structure__c vActivityCode1, vActivityCode2, vActivityCode3;
    static Id InvDateRecordTypeId;
    static Id InvLinRecordTypeId;
    static Id InvCondRecordTypeId;
    static String lines;
    static List <Invoicing_Parameter__c> ParmLineList;  
    static LC03_GenerateInvoicingLines.WrapperLine line1 = new LC03_GenerateInvoicingLines.WrapperLine();
    static LC03_GenerateInvoicingLines.WrapperLine line2 = new LC03_GenerateInvoicingLines.WrapperLine();
    static List<LC03_GenerateInvoicingLines.WrapperLine> lstLines = new List<LC03_GenerateInvoicingLines.WrapperLine>();
    static Map<String, Object> mapResult;

    static{

        testUser = TestFactory.createUser('UsrAdmin',TestFactory.getProfileAdminId(),true);
        insert testUser;
        system.runAs(testUser){

            // Create OO user
            vUserOO = AP05_TestDataFactory.createOOUser();

            vActivityCode1 = AP05_TestDataFactory.createActivityCode('L21FS_FM_000023', 'AXA Group Operations SAS - Sucursal em Portugal');
            vActivityCode2 = AP05_TestDataFactory.createActivityCode('L21FS_FM_000024', 'AXA Group Operations SAS');
            vActivityCode3 = AP05_TestDataFactory.createActivityCode('L21FS_FM_000025', 'AXA Group Operations Morocco');

            // Create the legal entity (aka billing entity) account
            vAccount = AP05_TestDataFactory.createLegalEntityAccount(testUser);

            workspace=TestFactory.createWorkspace('Workspace_test','Workspace_test',true);
            insert workspace;   

            // Create the entity account
            vEAccount = AP05_TestDataFactory.createEntityAccount(testUser);

            // Create the couple Entity - Billing Entity on Parent Entity
            //vAccount = AP05_TestDataFactory.linkLEgalEntityToEntity(vEAccount, vAccount);

            // Create the entity contact related to the account
            vEntityContact = AP05_TestDataFactory.createEntityContact(vAccount);
            
            //Product
            vProduct = AP05_TestDataFactory.createProduct(vUserOO);

            //Contract
            vContract = AP05_TestDataFactory.createContract(vProduct, vAccount, testUser, vEntityContact);  

            // create invoicing parameters
            InvDateRecordTypeId = Schema.SObjectType.Invoicing_Parameter__c.getRecordTypeInfosByName().get('Invoicing Date').getRecordTypeId();
            InvLinRecordTypeId = Schema.SObjectType.Invoicing_Parameter__c.getRecordTypeInfosByName().get('Invoicing Line').getRecordTypeId();
            InvCondRecordTypeId = Schema.SObjectType.Invoicing_Parameter__c.getRecordTypeInfosByName().get('Invoicing Condition').getRecordTypeId();

            ParmLineList = New List <Invoicing_Parameter__c> {
                new Invoicing_Parameter__c (Invoicing_Date__c = System.Today(), RecordTypeId = InvDateRecordTypeId, Parameter_type__c = 'Invoicing Date'),
                new Invoicing_Parameter__c (Name = System.Label.InvoicingCondition_100BeginningOfService, RecordTypeId = InvCondRecordTypeId, Parameter_type__c = 'Invoicing Condition'), 
                new Invoicing_Parameter__c (Name = System.Label.InvoicingCondition_QuarterlyBeginning, RecordTypeId = InvCondRecordTypeId, Parameter_type__c = 'Invoicing Condition'),
                new Invoicing_Parameter__c (Name = System.Label.InvoicingCondition_QuarterlyEnd, RecordTypeId = InvCondRecordTypeId, Parameter_type__c = 'Invoicing Condition'),
                new Invoicing_Parameter__c (Invoicing_Date__c = System.Today().addMonths(-4), RecordTypeId = InvDateRecordTypeId, Parameter_type__c = 'Invoicing Date'),
                new Invoicing_Parameter__c (Invoicing_Date__c = System.Today().addMonths(-3), RecordTypeId = InvDateRecordTypeId, Parameter_type__c = 'Invoicing Date'),
                new Invoicing_Parameter__c (Invoicing_Date__c = System.Today().addMonths(-2), RecordTypeId = InvDateRecordTypeId, Parameter_type__c = 'Invoicing Date'),
                new Invoicing_Parameter__c (Invoicing_Date__c = System.Today().addMonths(-1), RecordTypeId = InvDateRecordTypeId, Parameter_type__c = 'Invoicing Date'),
                new Invoicing_Parameter__c (Invoicing_Date__c = System.Today().addMonths(1), RecordTypeId = InvDateRecordTypeId, Parameter_type__c = 'Invoicing Date'),
                new Invoicing_Parameter__c (Invoicing_Date__c = System.Today().addMonths(2), RecordTypeId = InvDateRecordTypeId, Parameter_type__c = 'Invoicing Date'),
                new Invoicing_Parameter__c (Invoicing_Date__c = System.Today().addMonths(3), RecordTypeId = InvDateRecordTypeId, Parameter_type__c = 'Invoicing Date')
            };
            insert ParmLineList;

            List <Invoicing_Parameter__c> ParmLineList1 = New List <Invoicing_Parameter__c> {
                new Invoicing_Parameter__c (Name = System.Label.InvoicingCondition_100BeginningOfService, Invoicing_Description__c = System.Label.InvoicingCondition_100BeginningOfService, Parent_For_Invoicing_Line__c = ParmLineList[1].id, RecordTypeId = InvLinRecordTypeId, Parameter_type__c = 'Invoicing Line', Invoicing_Date_Type__c = 'Start Date', Percent__c = 100.00),
                new Invoicing_Parameter__c (Name = System.Label.InvoicingCondition_QuarterlyBeginning, Invoicing_Description__c = System.Label.InvoicingCondition_QuarterlyBeginning, Invoicing_Predefined_Date__c = ParmLineList[0].id, Parent_For_Invoicing_Line__c = ParmLineList[2].id, RecordTypeId = InvLinRecordTypeId, Parameter_type__c = 'Invoicing Line', Invoicing_Date_Type__c = 'Fixed Date', Percent__c = 100.00),
                new Invoicing_Parameter__c (Name = System.Label.InvoicingCondition_QuarterlyEnd, Invoicing_Description__c = '50% half of service', Parent_For_Invoicing_Line__c = ParmLineList[3].id, RecordTypeId = InvLinRecordTypeId, Parameter_type__c = 'Invoicing Line', Invoicing_Date_Type__c = 'Percent', Percent__c = 50.00),
                new Invoicing_Parameter__c (Name = System.Label.InvoicingCondition_QuarterlyEnd, Invoicing_Description__c = System.Label.InvoicingCondition_QuarterlyEnd, Parent_For_Invoicing_Line__c = ParmLineList[3].id, RecordTypeId = InvLinRecordTypeId, Parameter_type__c = 'Invoicing Line', Invoicing_Date_Type__c = 'End Date', Percent__c = 50.00),
                new Invoicing_Parameter__c (Name = System.Label.InvoicingCondition_QuarterlyEnd, Invoicing_Description__c = System.Label.InvoicingCondition_QuarterlyEnd, Parent_For_Invoicing_Line__c = ParmLineList[3].id, RecordTypeId = InvLinRecordTypeId, Parameter_type__c = 'Invoicing Line', Invoicing_Date_Type__c = 'Percent', Percent__c = 50.00)
            };
            insert ParmLineList1;

            line1.ContractId = vContract.Id;
            line1.ActivityCode = vActivityCode1;
            line1.Amount = 25000;
            lstLines.add(line1);
            line2.ContractId = vContract.Id;
            line2.ActivityCode = vActivityCode2;
            line2.Amount = 25000;
            lstLines.add(line2);
            lines = Json.serialize(lstLines);
        }
    }
    
    @IsTest
    public static void testGenerateIL_AmountZero(){
        System.runAs(testUser) {
            test.StartTest();
            	vContract.Global_Amount__c = 0;
	            vContract.StartDate__c = date.newinstance(2021, 01, 01);
	            vContract.EndDate__c = date.newinstance(2021, 12, 31);
                vContract.Invoicing_Condition__c = System.Label.InvoicingCondition_100BeginningOfService;
            	update vContract;

                mapResult = LC03_GenerateInvoicingLines.getAllData(vContract.Id);
            test.StopTest();

            System.assertEquals(system.label.LC03_AmountZero, mapResult.get('error'));
        }
    }

    @IsTest
    public static void testGenerateILBeginningOfService_yearBegin(){
        System.runAs(testUser) {
            test.StartTest();
            	vContract.Global_Amount__c = 50000;
	            vContract.StartDate__c = date.newinstance(2021, 01, 01);
	            vContract.EndDate__c = date.newinstance(2021, 12, 31);
                vContract.Invoicing_Condition__c = System.Label.InvoicingCondition_100BeginningOfService;
            	update vContract;

                mapResult = LC03_GenerateInvoicingLines.generateInvoicingLines(lines);
                List<Planned_Invoicing_Line__c> listPil = [select Inv_Predefined_Date__c from Planned_Invoicing_Line__c];
            test.StopTest();

            System.assert(mapResult.containsKey('success'));
            System.assertEquals(date.newinstance(2021, 01, 05), listPil[0].Inv_Predefined_Date__c);
        }
    }

    @IsTest
    public static void testGenerateILBeginningOfService_yearEnd(){
        System.runAs(testUser) {
            test.StartTest();
            	vContract.Global_Amount__c = 50000;
	            vContract.StartDate__c = date.newinstance(2020, 12, 01);
	            vContract.EndDate__c = date.newinstance(2021, 12, 31);
                vContract.Invoicing_Condition__c = System.Label.InvoicingCondition_100BeginningOfService;
            	update vContract;
                
                mapResult = LC03_GenerateInvoicingLines.generateInvoicingLines(lines);
                List<Planned_Invoicing_Line__c> listPil = [select Inv_Predefined_Date__c from Planned_Invoicing_Line__c];
            test.StopTest();

            System.assert(mapResult.containsKey('success'));
            System.assertEquals(date.newinstance(2020, 12, 31), listPil[0].Inv_Predefined_Date__c);
        }
    }

    @IsTest
    public static void testGenerateILBeginningOfService_DayAfter5(){
        System.runAs(testUser) {
            test.StartTest();
            	vContract.Global_Amount__c = 50000;
	            vContract.StartDate__c = date.newinstance(2021, 02, 07);
	            vContract.EndDate__c = date.newinstance(2021, 12, 31);
                vContract.Invoicing_Condition__c = System.Label.InvoicingCondition_100BeginningOfService;
            	update vContract;

                mapResult = LC03_GenerateInvoicingLines.generateInvoicingLines(lines);
                List<Planned_Invoicing_Line__c> listPil = [select Inv_Predefined_Date__c from Planned_Invoicing_Line__c];
            test.StopTest();

            System.assert(mapResult.containsKey('success'));
            System.assertEquals(date.newinstance(2021, 04, 05), listPil[0].Inv_Predefined_Date__c);
        }
    }

    @IsTest
    public static void testGenerateILBeginningOfService_DayAfter5_Month10(){
        System.runAs(testUser) {
            test.StartTest();
            	vContract.Global_Amount__c = 50000;
	            vContract.StartDate__c = date.newinstance(2020, 10, 10);
	            vContract.EndDate__c = date.newinstance(2021, 05, 28);
                vContract.Invoicing_Condition__c = System.Label.InvoicingCondition_100BeginningOfService;
            	update vContract;

                mapResult = LC03_GenerateInvoicingLines.generateInvoicingLines(lines);
                List<Planned_Invoicing_Line__c> listPil = [select Inv_Predefined_Date__c from Planned_Invoicing_Line__c];
            test.StopTest();

            System.assert(mapResult.containsKey('success'));
            System.assertEquals(date.newinstance(2020, 12, 31), listPil[0].Inv_Predefined_Date__c);
        }
    }

    @IsTest
    public static void testGenerateAndDeleteExistingIL(){
        System.runAs(testUser) {
            vContract.Global_Amount__c = 50000;
            vContract.StartDate__c = date.newinstance(2021, 01, 01);
            vContract.EndDate__c = date.newinstance(2021, 12, 31);
            vContract.Invoicing_Condition__c = System.Label.InvoicingCondition_QuarterlyBeginning;
            update vContract;

            mapResult = LC03_GenerateInvoicingLines.generateInvoicingLines(lines);
            Id existingId = [select Id from Planned_Invoicing_Line__c limit 1].Id;
            test.StartTest();
                mapResult = LC03_GenerateInvoicingLines.generateInvoicingLines(lines);
                List<Planned_Invoicing_Line__c> listPil = [select Id from Planned_Invoicing_Line__c WHERE Id = :existingId];
            test.StopTest();

            System.assertEquals(0, listPil.size());
        }
    }

    @IsTest
    public static void testGenerateILQuarterlyBegin(){
        System.runAs(testUser) {
            test.StartTest();
            	vContract.Global_Amount__c = 50000;
	            vContract.StartDate__c = date.newinstance(2021, 01, 01);
	            vContract.EndDate__c = date.newinstance(2021, 12, 31);
                vContract.Invoicing_Condition__c = System.Label.InvoicingCondition_QuarterlyBeginning;
            	update vContract;

                mapResult = LC03_GenerateInvoicingLines.generateInvoicingLines(lines);
                List<Planned_Invoicing_Line__c> lstPil = [select Id, Inv_Predefined_Date__c from Planned_Invoicing_Line__c];
            test.StopTest();

            System.assert(mapResult.containsKey('success'));
            System.assertEquals(8, lstPil.size());
            System.assertEquals(date.newinstance(2021, 01, 05), lstPil[0].Inv_Predefined_Date__c);
            System.assertEquals(date.newinstance(2021, 04, 05), lstPil[1].Inv_Predefined_Date__c);
        }
    }

    @IsTest
    public static void testGenerateILQuarterlyBegin_StartDayAfter5(){
        System.runAs(testUser) {
            test.StartTest();
            	vContract.Global_Amount__c = 50000;
	            vContract.StartDate__c = date.newinstance(2021, 02, 09);
	            vContract.EndDate__c = date.newinstance(2021, 12, 31);
                vContract.Invoicing_Condition__c = System.Label.InvoicingCondition_QuarterlyBeginning;
            	update vContract;

                mapResult = LC03_GenerateInvoicingLines.generateInvoicingLines(lines);
                List<Planned_Invoicing_Line__c> lstPil = [select Id, Inv_Predefined_Date__c from Planned_Invoicing_Line__c];
            test.StopTest();

            System.assert(mapResult.containsKey('success'));
            System.assertEquals(8, lstPil.size());
            System.assertEquals(date.newinstance(2021, 02, 09), lstPil[0].Inv_Predefined_Date__c);
            System.assertEquals(date.newinstance(2021, 04, 05), lstPil[1].Inv_Predefined_Date__c);
        }
    }

    @IsTest
    public static void testGenerateILQuarterlyBegin_notQuarterly(){
        System.runAs(testUser) {
            test.StartTest();
            	vContract.Global_Amount__c = 50000;
	            vContract.StartDate__c = date.newinstance(2021, 03, 09);
	            vContract.EndDate__c = date.newinstance(2021, 12, 31);
                vContract.Invoicing_Condition__c = System.Label.InvoicingCondition_QuarterlyBeginning;
            	update vContract;

                mapResult = LC03_GenerateInvoicingLines.generateInvoicingLines(lines);
                List<Planned_Invoicing_Line__c> lstPil = [select Id, Inv_Predefined_Date__c from Planned_Invoicing_Line__c];
            test.StopTest();

            System.assert(mapResult.containsKey('success'));
            System.assertEquals(8, lstPil.size());
            System.assertEquals(date.newinstance(2021, 03, 09), lstPil[0].Inv_Predefined_Date__c);
            System.assertEquals(date.newinstance(2021, 04, 05), lstPil[1].Inv_Predefined_Date__c);
        }
    }

    @IsTest
    public static void testGenerateILQuarterlyEnd(){
        System.runAs(testUser) {
            test.StartTest();
            	vContract.Global_Amount__c = 50000;
	            vContract.StartDate__c = date.newinstance(2021, 01, 01);
	            vContract.EndDate__c = date.newinstance(2021, 12, 31);
                vContract.Invoicing_Condition__c = System.Label.InvoicingCondition_QuarterlyEnd;
            	update vContract;

                mapResult = LC03_GenerateInvoicingLines.generateInvoicingLines(lines);
                List<Planned_Invoicing_Line__c> lstPil = [select Id, Inv_Predefined_Date__c from Planned_Invoicing_Line__c];
            test.StopTest();

            System.assert(mapResult.containsKey('success'));
            System.assertEquals(8, lstPil.size());
            System.assertEquals(date.newinstance(2021, 04, 05), lstPil[0].Inv_Predefined_Date__c);
            System.assertEquals(date.newinstance(2021, 07, 05), lstPil[1].Inv_Predefined_Date__c);
        }
    }

    @IsTest
    public static void testGenerateILQuarterlyEnd_startDateAfter20(){
        System.runAs(testUser) {
            test.StartTest();
            	vContract.Global_Amount__c = 50000;
	            vContract.StartDate__c = date.newinstance(2020, 11, 22);
	            vContract.EndDate__c = date.newinstance(2021, 12, 31);
                vContract.Invoicing_Condition__c = System.Label.InvoicingCondition_QuarterlyEnd;
            	update vContract;

                mapResult = LC03_GenerateInvoicingLines.generateInvoicingLines(lines);
                List<Planned_Invoicing_Line__c> lstPil = [select Id, Inv_Predefined_Date__c from Planned_Invoicing_Line__c];
            test.StopTest();

            System.assert(mapResult.containsKey('success'));
            System.assertEquals(10, lstPil.size());
            System.assertEquals(date.newinstance(2020, 12, 31), lstPil[0].Inv_Predefined_Date__c);
            System.assertEquals(date.newinstance(2021, 04, 05), lstPil[1].Inv_Predefined_Date__c);
        }
    }

    @IsTest
    public static void testGenerateILQuarterlyEnd_endDateQuaterlyFirstMonthAfter10(){
        System.runAs(testUser) {
            test.StartTest();
            	vContract.Global_Amount__c = 50000;
	            vContract.StartDate__c = date.newinstance(2020, 11, 22);
	            vContract.EndDate__c = date.newinstance(2021, 4, 20);
                vContract.Invoicing_Condition__c = System.Label.InvoicingCondition_QuarterlyEnd;
            	update vContract;

                mapResult = LC03_GenerateInvoicingLines.generateInvoicingLines(lines);
                List<Planned_Invoicing_Line__c> lstPil = [select Id, Inv_Predefined_Date__c from Planned_Invoicing_Line__c];
            test.StopTest();

            System.assert(mapResult.containsKey('success'));
            System.assertEquals(6, lstPil.size());
            System.assertEquals(date.newinstance(2020, 12, 31), lstPil[0].Inv_Predefined_Date__c);
            System.assertEquals(date.newinstance(2021, 04, 05), lstPil[1].Inv_Predefined_Date__c);
        }
    }

    @IsTest
    public static void testGenerateILQuarterlyEnd_endDateQuaterlySecondMonth(){
        System.runAs(testUser) {
            test.StartTest();
            	vContract.Global_Amount__c = 50000;
	            vContract.StartDate__c = date.newinstance(2020, 11, 22);
	            vContract.EndDate__c = date.newinstance(2021, 5, 19);
                vContract.Invoicing_Condition__c = System.Label.InvoicingCondition_QuarterlyEnd;
            	update vContract;

                mapResult = LC03_GenerateInvoicingLines.generateInvoicingLines(lines);
                List<Planned_Invoicing_Line__c> lstPil = [select Id, Inv_Predefined_Date__c from Planned_Invoicing_Line__c];
            test.StopTest();

            System.assert(mapResult.containsKey('success'));
            System.assertEquals(6, lstPil.size());
            System.assertEquals(date.newinstance(2020, 12, 31), lstPil[0].Inv_Predefined_Date__c);
            System.assertEquals(date.newinstance(2021, 04, 05), lstPil[1].Inv_Predefined_Date__c);
        }
    }

    @IsTest
    public static void testGenerateILQuarterlyEnd_endDateQuaterlyThirdMonth(){
        System.runAs(testUser) {
            test.StartTest();
            	vContract.Global_Amount__c = 50000;
	            vContract.StartDate__c = date.newinstance(2020, 11, 22);
	            vContract.EndDate__c = date.newinstance(2021, 6, 15);
                vContract.Invoicing_Condition__c = System.Label.InvoicingCondition_QuarterlyEnd;
            	update vContract;

                mapResult = LC03_GenerateInvoicingLines.generateInvoicingLines(lines);
                List<Planned_Invoicing_Line__c> lstPil = [select Id, Inv_Predefined_Date__c from Planned_Invoicing_Line__c];
            test.StopTest();

            System.assert(mapResult.containsKey('success'));
            System.assertEquals(6, lstPil.size());
            System.assertEquals(date.newinstance(2020, 12, 31), lstPil[0].Inv_Predefined_Date__c);
            System.assertEquals(date.newinstance(2021, 04, 05), lstPil[1].Inv_Predefined_Date__c);
        }
    }

    @IsTest
    public static void testGenerateILMonthly_after_5th(){
        System.runAs(testUser) {
            test.StartTest();
            	vContract.Global_Amount__c = 50000;
	            vContract.StartDate__c = date.newinstance(2021, 03, 09);
	            vContract.EndDate__c = date.newinstance(2021, 12, 31);
                vContract.AXA_GO_Legal_Entity__c = 'AXA Group Operations Morocco';
                vContract.Master_WBS_2__c = vActivityCode3.Id;
                vContract.Invoicing_Condition__c = System.Label.InvoicingCondition_Monthly;
            	update vContract;

                mapResult = LC03_GenerateInvoicingLines.generateInvoicingLines(lines);
                List<Planned_Invoicing_Line__c> lstPil = [select Id, Inv_Predefined_Date__c from Planned_Invoicing_Line__c];
            test.StopTest();

            System.assert(mapResult.containsKey('success'));
            System.assertEquals(20, lstPil.size());
        }
    }

    @IsTest
    public static void testGenerateILMonthly_Before_5th(){
        System.runAs(testUser) {
            test.StartTest();
            	vContract.Global_Amount__c = 50000;
	            vContract.StartDate__c = date.newinstance(2022, 01, 02);
	            vContract.EndDate__c = date.newinstance(2022, 12, 31);
                vContract.AXA_GO_Legal_Entity__c = 'AXA Group Operations Morocco';
                vContract.Master_WBS_2__c = vActivityCode3.Id;
                vContract.Invoicing_Condition__c = System.Label.InvoicingCondition_Monthly;
            	update vContract;

                mapResult = LC03_GenerateInvoicingLines.generateInvoicingLines(lines);
                List<Planned_Invoicing_Line__c> lstPil = [select Id, Inv_Predefined_Date__c from Planned_Invoicing_Line__c];
            test.StopTest();

            System.assert(mapResult.containsKey('success'));
            System.assertEquals(24, lstPil.size());
        }
    }

    @IsTest
    public static void testGenerateILPerDeliverable(){
        System.runAs(testUser) {
            test.StartTest();
            vContract.Global_Amount__c = 50000;
            vContract.Language__c = 'French';
            vContract.EndDate__c = System.Today() + 365;
            vContract.AXA_GO_Legal_Entity__c = 'AXA Group Operations SAS - Sucursal em Portugal';
            vContract.ServiceType__c = AP05_TestDataFactory.CONTRACT_STYPE_BAU;
            vContract.InvoicingMethod__c = AP05_TestDataFactory.CONTRACT_INVMETHOD_FIXEDPRICE;
            vContract.Invoicing_Condition__c = System.Label.InvoicingCondition_PerDeliverable;
            vContract.Master_WBS_2__c = vActivityCode1.Id;
            update vContract;

            mapResult = LC03_GenerateInvoicingLines.getAllData(vContract.Id);
            Integer numPlanInv = [select count() from Planned_Invoicing_Line__c];
            test.StopTest();

            System.assertEquals(system.label.LC03_PerDeliverable, mapResult.get('error'));
            System.assertEquals(0, numPlanInv);
        }
    }

    @IsTest
    public static void testGenerateIL_GETDQuarterlyBAU(){
        System.runAs(testUser) {
            test.StartTest();
            vContract.Global_Amount__c = 100;
            vContract.Language__c = 'French';
            vContract.EndDate__c = System.Today() + 365;
            vContract.AXA_GO_Legal_Entity__c = 'AXA Group Operations SAS';
            vContract.ServiceType__c = AP05_TestDataFactory.CONTRACT_STYPE_BAU;
            vContract.InvoicingMethod__c = AP05_TestDataFactory.CONTRACT_INVMETHOD_FIXEDPRICE;
            vContract.Invoicing_Condition__c = System.Label.InvoicingCondition_GETDQuarterlyBAUBegin;
            update vContract;

            mapResult = LC03_GenerateInvoicingLines.getAllData(vContract.Id);
            Integer numPlanInv = [select count() from Planned_Invoicing_Line__c];
            test.StopTest();

            System.assertEquals(system.label.LC03_GETDQuarterlyBAU, mapResult.get('error'));
            System.assertEquals(0, numPlanInv);
        }
    }

    @IsTest
    public static void testGenerateIL_ContractAlreadySentToPS(){
        System.runAs(testUser) {
            test.StartTest();
            List<Planned_Invoicing_Line__c> lstPIL = new List<Planned_Invoicing_Line__c>();
            vContract.Global_Amount__c = 1200;
            vContract.Language__c = 'French';
            vContract.EndDate__c = System.Today() + 365;
            vContract.AXA_GO_Legal_Entity__c = 'AXA Group Operations SAS';
            vContract.ServiceType__c = AP05_TestDataFactory.CONTRACT_STYPE_BAU;
            vContract.InvoicingMethod__c = AP05_TestDataFactory.CONTRACT_INVMETHOD_FIXEDPRICE;
            vContract.Invoicing_Condition__c = System.Label.InvoicingCondition_QuarterlyEnd;
            update vContract;

            LC03_GenerateInvoicingLines.generateInvoicingLines(lines);

            for(Planned_Invoicing_Line__c pil : [SELECT Id FROM Planned_Invoicing_Line__c WHERE Contract2__c = :vContract.Id]){
                pil.Tech_UpdatedByPS__c = true;
                lstPIL.add(pil);
            }
            update lstPIL;
            mapResult = LC03_GenerateInvoicingLines.getAllData(vContract.Id);
            test.StopTest();

            System.assertEquals(system.label.LC03_ContractAlreadySentToPS, mapResult.get('error'));
        }
    }

    @IsTest
    public static void testGenerateIL_ContractSignatureTypeSpecific(){
        System.runAs(testUser) {
            test.StartTest();
            List<Planned_Invoicing_Line__c> lstPIL = new List<Planned_Invoicing_Line__c>();
            vContract.Global_Amount__c = 1200;
            vContract.Language__c = 'French';
            vContract.EndDate__c = System.Today() + 365;
            vContract.AXA_GO_Legal_Entity__c = 'AXA Group Operations SAS';
            vContract.ServiceType__c = AP05_TestDataFactory.CONTRACT_STYPE_BAU;
            vContract.InvoicingMethod__c = AP05_TestDataFactory.CONTRACT_INVMETHOD_FIXEDPRICE;
            vContract.Invoicing_Condition__c = System.Label.InvoicingCondition_QuarterlyEnd;
            vContract.Signature_Type__c = System.Label.Contract_Signature_Type_Specific;
            update vContract;
            mapResult = LC03_GenerateInvoicingLines.getAllData(vContract.Id);
            test.StopTest();

            System.assertEquals(system.label.Error_Signature_Type_Specific, mapResult.get('error'));
        }
    }
}