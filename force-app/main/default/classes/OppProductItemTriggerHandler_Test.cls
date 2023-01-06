@isTest
public class OppProductItemTriggerHandler_Test {
/*
----------------------------------------------------------------------
-- - Name          : OpportunityProductItemTrigger_Test
-- - Author        : Spoon Consulting 
-- - Description   : Test class of OpportunityProductItemTrigger
--                   
-- Maintenance History:
--
-- Date         Name  Version  Remarks
-- -----------  ----  -------  ---------------------------------------
-- 02-09-2021   ARA    1.0    Intitial version
----------------------------------------------------------------------
**********************************************************************
*/
static User vUserPM;
	static Account acc;
	static Contact con;
	static List<Product__c> lstProds = new List<Product__c>();
	static Contract__c ctr; 
	static User vUserAdmin;

	static Opportunity opp;
	static Account entity;
	static Account LeEntity;

	static List<Id> lstOppProdId = new List<Id>();
	static List<Opp_ProductItem__c> lstOppProductItem;



	static{
		
		vUserAdmin   = [SELECT id FROM user WHERE profile.name = 'System Administrator' AND IsActive =  true LIMIT 1];
        vUserAdmin.PAD_BypassValidationRules__c = true;
        update vUserAdmin;  
		System.runAs(vUserAdmin){

			acc          = AP05_TestDataFactory.createLegalEntityAccount(vUserAdmin);
			entity		 = AP05_TestDataFactory.createEntityAccount(vUserAdmin);
			LeEntity 	 = AP05_TestDataFactory.linkLEgalEntityToEntity(entity, acc);
			con          = AP05_TestDataFactory.createEntityContact(acc);
			lstProds     = new List<Product__c>{AP05_TestDataFactory.createProduct(vUserAdmin, 'Live !', 'test prod 1'),
												AP05_TestDataFactory.createProduct(vUserAdmin, 'Live !', 'test prod 2'),
												AP05_TestDataFactory.createProduct(vUserAdmin, 'Live !', 'test prod 3'),
												AP05_TestDataFactory.createProduct(vUserAdmin, 'Live !', 'test prod 4'),
												AP05_TestDataFactory.createProduct(vUserAdmin, 'Live !', 'test prod 5')};

			opp 		= new Opportunity(	OwnerId                         = vUserAdmin.Id,
											Name 							= 'Test Opp',
											AccountId 						= entity.Id,
											StageName 						= AP_Constant.STAGE_LEADS_GATHERING,
											CloseDate						= System.Today().addMonths(-5),
											//Project_start_Date__c = System.Today().addMonths(-5),
											//Go_live_date__c = System.Today().addMonths(-1),
											AXA_GO_Entity__c = 'AXA Group Operations Hong Kong Limited',
											RecordTYpeId                     = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Full Opportunity Contract process OpCo360').getRecordTypeId()
			);
			insert opp;
		}
	}
	
   	@IsTest
    public static void testDeleteOppProductItem(){
        System.runAs(vUserAdmin) {
			
			List<Id> lstProdId = new List<Id>();
			lstProdId.add(lstProds[0].Id);
			lstProdId.add(lstProds[1].Id);
			lstProdId.add(lstProds[2].Id);
			LC16_AddProduct.saveRecords(opp.Id, lstProdId);
            opp.StageName = AP_Constant.STAGE_CONTRACTING;
            update opp;
            test.StartTest();
            	List<Opp_ProductItem__c> lstOppPI = [SELECT Id FROM Opp_ProductItem__c WHERE Opportunity__c = :opp.Id limit 2];
                try{
                    delete lstOppPI[0];
                }catch(DMLException e){
                    System.assert(e.getMessage().contains('Related product cannot be deleted at this opportunity stage'));
                }
				lstOppPI[1].Product__c = lstProds[3].Id;
				update lstOppPI[1];
            test.StopTest();
        }
    }
}