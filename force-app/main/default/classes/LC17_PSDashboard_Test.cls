@isTest
public class LC17_PSDashboard_Test {
/*
----------------------------------------------------------------------
-- - Name          : LC04_AddProduct_Test
-- - Author        : ARA
-- - Description   : Test class of LC17_PSDashboard
--                   
-- Maintenance History:
--
-- Date         Name  Version  Remarks
-- -----------  ----  -------  ---------------------------------------
-- 18-AUG-2019   ARA    1.0    Intitial version
----------------------------------------------------------------------
**********************************************************************
*/
static User vUserPM;
	static Account acc;
	static Contact con;
	static Contract__c ctr; 
	static User vUserAdmin;

	static Opportunity opp;
	static Account entity;
	static Account LeEntity;

	static List<Id> lstOppProdId = new List<Id>();
	static List<Opp_ProductItem__c> lstOppProductItem;
	static List<String> lstResult1;

	static{
		
		vUserAdmin   = [SELECT id FROM user WHERE profile.name = 'System Administrator' AND IsActive =  true LIMIT 1];
		System.runAs(vUserAdmin){

			acc          = AP05_TestDataFactory.createLegalEntityAccount(vUserAdmin);
			entity		 = AP05_TestDataFactory.createEntityAccount(vUserAdmin);
			LeEntity 	 = AP05_TestDataFactory.linkLEgalEntityToEntity(entity, acc);
			con          = AP05_TestDataFactory.createEntityContact(acc);
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
										   ServiceType__c 					= AP05_TestDataFactory.CONTRACT_STYPE_BAU,
										   InvoicingMethod__c 				= AP05_TestDataFactory.CONTRACT_INVMETHOD_FIXEDPRICE,
									       Invoicing_Condition__c           = System.Label.InvoicingCondition_100BeginningOfService,
									       Global_Amount__c                 = 10000,
									       SOW_Operational__c               = '123',								       
									       RecordTYpeId                     = Schema.SObjectType.Contract__c.getRecordTypeInfosByName().get(AP_Constant.RT_CONTRACT_EDIT_LIGHTNING_LABEL).getRecordTypeId(),
									       Signature_Type__c 				= 'Manual');
			insert ctr;
		}
	}
	@IsTest
    public static void getURL_test(){
        System.runAs(vUserAdmin) {
            String PSDashboardLink = '';
            test.StartTest();
            	//method returns a link which is related to the PS Dashboard of the contract
	            PSDashboardLink = LC17_PSDashboard.getURL(ctr.Id);
            test.StopTest();

            System.assertEquals(System.Label.PSDashboardURL + (String.valueOf(ctr.Id)).substring(0,15), PSDashboardLink);
        }
    }
}