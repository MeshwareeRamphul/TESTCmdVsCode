@isTest
private class WS01_UpdateContractsTest
{
	/* 
--------------------------------------------------------------------------------------
-- - Name          : WS01_UpdateContractsTest
-- - Author        : SC 
-- - Description   : Test class for WS01_UpdateContracts
--
-- Maintenance History: 
--
-- Date         Name  Version  Remarks 
-- -----------  ----  -------  -------------------------------------------------------
-- 27-JAN-2017  RLA    1.0     Initial version
--------------------------------------------------------------------------------------
*/	
	static List<Planned_Invoicing_Line__c> lstInvoi = new List<Planned_Invoicing_Line__c>();
	static Contract__c vContract;
	static User testUser;
	static {
		
		//Create datas for the tests methods
		Profile vProfileAdmin = [SELECT Id From Profile WHERE Name = :'System Administrator'];
		testUser = new User();
        testUser.Alias = 'useradm';
        testUser.FirstName = 'user_adm';
        testUser.LastName = 'test';
        testUser.Username = 'user_adm@User.com';
        testUser.Email = 'user_adm@User.com';
        testUser.EmailEncodingKey = 'ISO-8859-1';
        testUser.TimeZoneSidKey = 'Europe/Paris';
        testUser.LanguageLocaleKey = 'en_US';
        testUser.LocaleSidKey = 'fr_FR_EURO';
        testUser.ProfileId = vProfileAdmin.id;
        testUser.PAD_BypassValidationRules__c=true;
        insert testUser;
		
        testUser.PAD_BypassTrigger__c = 'AP12';
		update testUser;

		system.RunAs(testUser){
			// Create OO user
			User vUserOO = AP05_TestDataFactory.createOOUser();

			// Create PM user
			User vUserPM = AP05_TestDataFactory.createPMUser(true);

			
			// Create the customer (aka entity) account
			Account vAccount = AP05_TestDataFactory.createLegalEntityAccount(vUserPM);

			// Create the entity account
			Account vEAccount = AP05_TestDataFactory.createEntityAccount(vUserPM);

			// Create the entity contact related to the account
			Contact vEntityContact = AP05_TestDataFactory.createEntityContact(vAccount);
			
			//Product
			Product__c vProduct = AP05_TestDataFactory.createProduct(vUserOO);
			
			//Contract
			vContract = AP05_TestDataFactory.createContract(vProduct, vAccount, vUserOO, vEntityContact);
			
			lstInvoi.add(AP05_TestDataFactory.createIL(vContract, 50,'Description 1', '01', System.Today(), System.Today().addMonths(4), vEntityContact.Id));
			lstInvoi.add(AP05_TestDataFactory.createIL(vContract, 50,'Description 1', '01', System.Today(), System.Today().addMonths(4), vEntityContact.Id));

			insert lstInvoi;

			vContract.Status__c = 'Sent for Signature';
			update vContract;
		}    	
	}

	@isTest
	static void WS02_CallSAPWSTest()
	{
		system.RunAs(testUser){
			Test.setMock(WebServiceMock.class, new WS01_UpdateContractsMock());
			//WS02_CallSAPWS.testcaseId = lstInvoi[0].id;
			
			Test.startTest();
				lstInvoi[0].Status__c = System.Label.InvLineStatus_InvoicingValidation;
				update lstInvoi;
			Test.stopTest();
		}
		
	}

	@isTest
	static void WS01_UpdateContractsError()
	{
		system.RunAs(testUser){
		list<WS01_UpdateContracts.wrapperParams> lstparams = new list<WS01_UpdateContracts.wrapperParams>();

		WS01_UpdateContracts.wrapperParams var = new WS01_UpdateContracts.wrapperParams();
		/*
		var.PONUMBER = '158';
		var.TARGETQUANTITY = 971;
		var.TEXTS = 'text';
		var.EMPLOYERESPONS = 258;
		var.CURENCY = 'mur';
		var.WBSELEMENT = 'ele';
		var.AMOUNTMANUALPRICE = 12.0;
		var.BILLINGDATE = Date.newInstance(2012, 1, 2);
		var.ITEM = 'item';
		var.INVOICENO = 789;
		var.DATEDEFACTURE = Date.newInstance(2012, 1, 2);
		var.PAYMENTFLAG = 'ok';
		*/
		var.Contract_Id = vContract.id;
		var.Invoicing_Line_Id = lstInvoi[0].id;
		
		/*
		var.Sales_Order_Number;
		var.String Sales_Order_Item;
		var.String Billing_Document_Number;
		var.Date Billing_Document_Date;
		var.String Payment_Document;
		var.Date Payment_Document_Date;*/
		lstparams.add(var);

		List <WS01_UpdateContracts.wrapperResponse> lstwrapperResponse = new list <WS01_UpdateContracts.wrapperResponse> ();
		lstInvoi[0].N_Purchase_Order__c = '158';
		update lstInvoi;

		Test.startTest();
			lstwrapperResponse = WS01_UpdateContracts.updateInvoiceLine(lstparams);
		Test.stopTest();
		}
		
		
		
	}
	@isTest
	static void WS01_UpdateContractsSuccess()
	{
		system.RunAs(testUser){
			list<WS01_UpdateContracts.wrapperParams> lstparams = new list<WS01_UpdateContracts.wrapperParams>();

			WS01_UpdateContracts.wrapperParams wp1 = new WS01_UpdateContracts.wrapperParams();
			WS01_UpdateContracts.wrapperParams wp2 = new WS01_UpdateContracts.wrapperParams();
			WS01_UpdateContracts.wrapperParams wp3 = new WS01_UpdateContracts.wrapperParams();
			WS01_UpdateContracts.wrapperParams wp4 = new WS01_UpdateContracts.wrapperParams();
			WS01_UpdateContracts.wrapperParams wp5 = new WS01_UpdateContracts.wrapperParams();
			WS01_UpdateContracts.wrapperParams wp6 = new WS01_UpdateContracts.wrapperParams();
			WS01_UpdateContracts.wrapperParams wp7 = new WS01_UpdateContracts.wrapperParams();
			WS01_UpdateContracts.wrapperParams wp8 = new WS01_UpdateContracts.wrapperParams();
			WS01_UpdateContracts.wrapperParams wp9 = new WS01_UpdateContracts.wrapperParams();

			wp1.Invoicing_Line_Id = lstInvoi[0].id;
			wp1.Contract_Id = vContract.id;
			wp1.Billing_Document_Number = 'ATSFR00017240';
			wp1.Billing_Document_Date = Date.valueOf('2022-01-13');
			wp1.Sales_Order_Item = '1';
			wp1.Sales_Order_Number = 'CFR0007965';
			wp1.Payment_Document = 'CLEARED';
			lstParams.add(wp1);

			wp2.Invoicing_Line_Id = lstInvoi[0].id;
			wp2.Contract_Id = vContract.id;
			wp2.Billing_Document_Number = 'ATSFR00017352';
			wp2.Billing_Document_Date = Date.valueOf('2022-01-13');
			wp2.Sales_Order_Item = '1';
			wp2.Sales_Order_Number = 'CFR0007965';
			wp2.Payment_Document = 'CLEARED';
			lstParams.add(wp2);

			wp3.Invoicing_Line_Id = lstInvoi[0].id;
			wp3.Contract_Id = vContract.id;
			wp3.Billing_Document_Number = 'ATSFR00017351';
			wp3.Billing_Document_Date = Date.valueOf('2022-02-04');
			wp3.Sales_Order_Item = '1';
			wp3.Sales_Order_Number = 'CFR0007965';
			wp3.Payment_Document = 'CLEARED';
			lstParams.add(wp3);

			wp4.Invoicing_Line_Id = lstInvoi[1].id;
			wp4.Contract_Id = vContract.id;
			wp4.Billing_Document_Number = 'ATSFR00017240';
			wp4.Billing_Document_Date = Date.valueOf('2022-01-13');
			wp4.Sales_Order_Item = '2';
			wp4.Sales_Order_Number = 'CFR0007965';
			wp4.Payment_Document = 'INVOICED';
			lstParams.add(wp4);

			wp5.Invoicing_Line_Id = lstInvoi[1].id;
			wp5.Contract_Id = vContract.id;
			wp5.Billing_Document_Number = 'ATSFR00017345';
			wp5.Billing_Document_Date = Date.valueOf('2022-01-13');
			wp5.Sales_Order_Item = '2';
			wp5.Sales_Order_Number = 'CFR0007965';
			wp5.Payment_Document = 'INVOICED';
			lstParams.add(wp5);

			wp6.Invoicing_Line_Id = lstInvoi[1].id;
			wp6.Contract_Id = vContract.id;
			wp6.Billing_Document_Number = 'ATSFR00017350';
			wp6.Billing_Document_Date = Date.valueOf('2022-02-04');
			wp6.Sales_Order_Item = '2';
			wp6.Sales_Order_Number = 'CFR0007965';
			wp6.Payment_Document = 'INVOICED';

			// Invoicing_Line_Id not exist
			wp7.Invoicing_Line_Id = 'a0708000022uXXtAAM';
			wp7.Contract_Id = vContract.id;
			wp7.Billing_Document_Date = Date.valueOf('2022-01-13');
			wp7.Sales_Order_Item = '3';
			wp7.Sales_Order_Number = 'CFR0007965';
			wp7.Payment_Document = 'INVOICED';
			lstParams.add(wp7);

			// Invoicing_Line_Id not exist
			wp8.Invoicing_Line_Id = 'a0708000022uXXtAAM';
			wp8.Contract_Id = vContract.id;
			wp8.Billing_Document_Number = 'ATSFR00017350';
			wp8.Billing_Document_Date = Date.valueOf('2022-01-13');
			wp8.Sales_Order_Item = '3';
			wp8.Sales_Order_Number = 'CFR0007965';
			wp8.Payment_Document = 'INVOICED';
			lstParams.add(wp8);

			// Invoicing_Line_Id not exist
			wp9.Invoicing_Line_Id = 'a0708000022uXXtAAM';
			wp9.Contract_Id = vContract.id;
			wp9.Billing_Document_Date = Date.valueOf('2022-02-04');
			wp9.Sales_Order_Item = '3';
			wp9.Sales_Order_Number = 'CFR0007965';
			wp9.Payment_Document = 'INVOICED';
			lstParams.add(wp9);

			List <WS01_UpdateContracts.wrapperResponse> lstwrapperResponse = new list <WS01_UpdateContracts.wrapperResponse> ();
			update lstInvoi;

			Test.startTest();
				lstwrapperResponse = WS01_UpdateContracts.updateInvoiceLine(lstparams);
			Test.stopTest();

			lstInvoi = [SELECT Id, Status__c FROM Planned_Invoicing_Line__c WHERE Id IN :lstInvoi];
			List<Log__c> lstLog = [SELECT Error_Message__c, Request__c FROM Log__c WHERE Contract__c = :vContract.id];
			System.debug('******* lstLog '+lstLog);
			/*System.assertEquals(AP_Constant.INVLINE_STATUS_PAID, lstInvoi[0].Status__c);
			System.assertEquals(AP_Constant.INVLINE_STATUS_INVOICED, lstInvoi[1].Status__c);
			for(Integer i=0; i<3; i++){
				System.assertEquals('OK', lstwrapperResponse[i].Notification_processing_Status);
			}*/
    	}
	}
}