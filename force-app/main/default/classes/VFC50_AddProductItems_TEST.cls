@isTest
private class VFC50_AddProductItems_TEST {
/*
----------------------------------------------------------------------
-- - Author        : SC
-- - Description   : Test class for VFC50_AddProductItems_TEST
-- - Maintenance History:
--
-- Date         Name  Version  Remarks
-- -----------  ----  -------  ---------------------------------------
-- 20-APR-2018  USA    1.0      Initial version
----------------------------------------------------------------------
**********************************************************************
*/
	static User vUserPM;
	static Account acc;
	static Contact con; 
	/*static Quartile__c businessArea;
	static Petal__c domain;
	static Offer__c offer;*/
	static List<Product__c> lstProds = new List<Product__c>();
	static Contract__c ctr; 
	static User vUserAdmin;

	static{
		
		//vUserPM          = AP05_TestDataFactory.createPMUser(true);
		vUserAdmin   = [SELECT id FROM user WHERE profile.name = 'System Administrator' AND IsActive =  true LIMIT 1];
		System.runAs(vUserAdmin){
			//vUserAdmin   = [SELECT id FROM user WHERE profile.name = 'System Administrator' LIMIT 1];

			acc          = AP05_TestDataFactory.createLegalEntityAccount(vUserAdmin);
			con          = AP05_TestDataFactory.createEntityContact(acc);
			/*businessArea = AP05_TestDataFactory.createBusinessArea(vUserAdmin);
			domain       = AP05_TestDataFactory.createDomain(businessArea, vUserAdmin);
			offer        = AP05_TestDataFactory.createOffer(domain, vUserAdmin);*/
			lstProds     = new List<Product__c>{AP05_TestDataFactory.createProduct(/*offer,*/ vUserAdmin, 'Live !', 'test prod 1'),
												AP05_TestDataFactory.createProduct(/*offer,*/ vUserAdmin, 'Live !', 'test prod 2'),
												AP05_TestDataFactory.createProduct(/*offer,*/ vUserAdmin, 'Live !', 'test prod 3'),
												AP05_TestDataFactory.createProduct(/*offer,*/ vUserAdmin, 'Live !', 'test prod 4'),
												AP05_TestDataFactory.createProduct(/*offer,*/ vUserAdmin, 'Live !', 'test prod 5')};
			ctr          = new Contract__c(OwnerId                          = vUserAdmin.Id,
									       Name                             = 'ATS Test COntract',
									       AXA_GS_Signed_By__c              = con.Id,
									       CustomerSignedBy__c              = con.Id,
									       Customer_Operational_Contact__c  = con.Id,
									       Account__c                       = acc.Id,
									       ATS_Notify_Validation__c         = vUserAdmin.Id,
									       Status__c                        = AP_Constant.CONTRACT_STATUS_DRAFT,
									       StartDate__c                     = System.Today().addMonths(-5),
									       EndDate__c                       = System.Today().addMonths(-1),
									       AXA_GO_Legal_Entity__c           = 'AXA Group Operations SAS',
										   ServiceType__c                  	= AP05_TestDataFactory.CONTRACT_STYPE_PROJECT,
										   InvoicingMethod__c              	= AP05_TestDataFactory.CONTRACT_INVMETHOD_FIXEDPRICE,
									       Invoicing_Condition__c           = System.Label.InvoicingCondition_100BeginningOfService,
									       Global_Amount__c                 = 10000,
									       SOW_Operational__c               = '123',								       
									       RecordTYpeId                     = Schema.SObjectType.Contract__c.getRecordTypeInfosByName().get(AP_Constant.RT_CONTRACT_EDIT_LIGHTNING_LABEL).getRecordTypeId(),
									       //OfferATS__c                      = offer.Id,
									       Signature_Type__c    			= AP_Constant.SIGNATURE_MANUAL);
			insert ctr;
		}
	}
	
	@isTest static void clickAaddProdButton() {
		System.runAs(vUserAdmin){				
			Test.startTest();
				PageReference addProdPage = Page.VFP50_AddProductItems;
				addProdPage.getParameters().put('contractId', ctr.Id);
				//addProdPage.getParameters().put('offerId', offer.Id);
				Test.setCurrentPage(addProdPage);
				ApexPages.StandardController sc  = new ApexPages.StandardController(ctr);
				VFC50_AddProductItems controller = new VFC50_AddProductItems(sc);
			Test.stopTest();
			//System.assertEquals(5, controller.lstProds.size());
		}
	}	

	@isTest static void addProdToCtr(){
		List<ProductItem__c> lstProdItem         = new List<ProductItem__c>{ new ProductItem__c(Contract__c = ctr.Id, Product__c = lstProds[0].Id),
																		     new ProductItem__c(Contract__c = ctr.Id, Product__c = lstProds[1].Id)};
		System.runAs(vUserAdmin){
			insert lstProdItem;

			Test.startTest();
				PageReference addProdPage        = Page.VFP50_AddProductItems;				
				addProdPage.getParameters().put('contractId', ctr.Id);
				//addProdPage.getParameters().put('offerId', offer.Id);
				Test.setCurrentPage(addProdPage);
				ApexPages.StandardController sc  = new ApexPages.StandardController(ctr);
				VFC50_AddProductItems controller = new VFC50_AddProductItems(sc);			
			Test.stopTest();
			//System.assertEquals(3, controller.lstProds.size());

			for (VFC50_AddProductItems.ProdWrapper pi :controller.lstProds){
				System.assertNotEquals('test prod 1', pi.product.Name);
				System.assertNotEquals('test prod 2', pi.product.Name);
			}
		}
	}

	@isTest static void checkHasProducts(){
		List<ProductItem__c> lstProdItem         = new List<ProductItem__c>{ new ProductItem__c(Contract__c = ctr.Id, Product__c = lstProds[0].Id),
																		     new ProductItem__c(Contract__c = ctr.Id, Product__c = lstProds[1].Id)};
		System.runAs(vUserAdmin){
			insert lstProdItem;

			Test.startTest();
				PageReference addProdPage = Page.VFP50_AddProductItems;				
				addProdPage.getParameters().put('contractId', ctr.Id);
				//addProdPage.getParameters().put('offerId', offer.Id);
				Test.setCurrentPage(addProdPage);
				ApexPages.StandardController sc  = new ApexPages.StandardController(ctr);
				VFC50_AddProductItems controller = new VFC50_AddProductItems(sc);			

				PageReference pageChkProd        = controller.checkHasProducts();
			Test.stopTest();
			System.assertEquals(null, pageChkProd);
		}
	}

	@isTest static void addNewProdToCtr(){
		List<ProductItem__c> lstProdItem         = new List<ProductItem__c>{ new ProductItem__c(Contract__c = ctr.Id, Product__c = lstProds[0].Id),
											    							 new ProductItem__c(Contract__c = ctr.Id, Product__c = lstProds[1].Id)};
		System.runAs(vUserAdmin){
			insert lstProdItem;

			Test.startTest();
				PageReference addProdPage = Page.VFP50_AddProductItems;				
				addProdPage.getParameters().put('contractId', ctr.Id);
				//addProdPage.getParameters().put('offerId', offer.Id);
				Test.setCurrentPage(addProdPage);
				ApexPages.StandardController sc  = new ApexPages.StandardController(ctr);
				VFC50_AddProductItems controller = new VFC50_AddProductItems(sc);			
			Test.stopTest();
			//System.assertEquals(3, controller.lstProds.size());

			//controller.lstProds[0].isSelected    = true;
			controller.addProducts();

			List<ProductItem__c> lstAddedProds   = [SELECT id FROM ProductItem__c WHERE Contract__c = :ctr.Id];
			//System.assertEquals(3, lstAddedProds.size());
		}
	}

	@isTest static void addNoProdToCtr(){
		List<ProductItem__c> lstProdItem         = new List<ProductItem__c>{ new ProductItem__c(Contract__c = ctr.Id, Product__c = lstProds[0].Id),
											    							 new ProductItem__c(Contract__c = ctr.Id, Product__c = lstProds[1].Id)};
		System.runAs(vUserAdmin){
			insert lstProdItem;

			Test.startTest();
				PageReference addProdPage        = Page.VFP50_AddProductItems;				
				addProdPage.getParameters().put('contractId', ctr.Id);
				//addProdPage.getParameters().put('offerId', offer.Id);
				Test.setCurrentPage(addProdPage);
				ApexPages.StandardController sc  = new ApexPages.StandardController(ctr);
				VFC50_AddProductItems controller = new VFC50_AddProductItems(sc);			
			
				//System.assertEquals(3, controller.lstProds.size());

				try{
					controller.addProducts();
				}
				catch(Exception e){
					System.debug(e.getMessage());
					System.assert(e.getMessage().contains('Please select atleast one product to add.'));
				}
			Test.stopTest();

			List<ProductItem__c> lstAddedProds   = [SELECT id FROM ProductItem__c WHERE Contract__c = :ctr.Id];
			System.assertEquals(2, lstAddedProds.size());
		}
	}

	@isTest static void noProdToAdd(){
		List<ProductItem__c> lstProdItem         = new List<ProductItem__c>{ new ProductItem__c(Contract__c = ctr.Id, Product__c = lstProds[0].Id),
											    							 new ProductItem__c(Contract__c = ctr.Id, Product__c = lstProds[1].Id),
											    							 new ProductItem__c(Contract__c = ctr.Id, Product__c = lstProds[2].Id),
											    							 new ProductItem__c(Contract__c = ctr.Id, Product__c = lstProds[3].Id),
											    							 new ProductItem__c(Contract__c = ctr.Id, Product__c = lstProds[4].Id)};
		System.runAs(vUserAdmin){
			insert lstProdItem;

			Test.startTest();
				PageReference addProdPage        = Page.VFP50_AddProductItems;				
				addProdPage.getParameters().put('contractId', ctr.Id);
				//addProdPage.getParameters().put('offerId', offer.Id);
				Test.setCurrentPage(addProdPage);
				ApexPages.StandardController sc  = new ApexPages.StandardController(ctr);
				VFC50_AddProductItems controller = new VFC50_AddProductItems(sc);			
			
				System.assertEquals(0, controller.lstProds.size());

				PageReference pageChkProd        = controller.checkHasProducts();
			Test.stopTest();
		}
	}

	@isTest static void cancelAddProduct(){

		System.runAs(vUserAdmin){

			Test.startTest();
				PageReference addProdPage = Page.VFP50_AddProductItems;				
				addProdPage.getParameters().put('contractId', ctr.Id);
				//addProdPage.getParameters().put('offerId', offer.Id);
				Test.setCurrentPage(addProdPage);
				ApexPages.StandardController sc  = new ApexPages.StandardController(ctr);
				VFC50_AddProductItems controller = new VFC50_AddProductItems(sc);

				PageReference cancelRef = controller.cancel();
			Test.stopTest();
			
			System.assert(cancelRef.getUrl().contains('/'+ctr.Id));
		}
	}
}