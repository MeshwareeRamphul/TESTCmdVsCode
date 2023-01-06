@isTest
private class AP53_UncheckExpirePreference_TEST{
/* 
--------------------------------------------------------------------------------------
-- - Name          : AP53_UncheckExpirePreference_TEST
-- - Author        : Spoon Consulting 
-- - Description   : test class for AP53_UncheckExpirePreference
--
-- Maintenance History: 
--
-- Date         Name  Version  Remarks 
-- -----------  ----  -------  -------------------------------------------------------
-- 30-APR-2019  MRA    1.0     Initial version
--------------------------------------------------------------------------------------*/
	static User testUser;
  	static list<ContentVersion> contentVersionLst=new list<ContentVersion>();
  	static list<ContentVersion> cvLst=new list<ContentVersion>();
  	static Account supplier;
  	static Contract__c contract;
  	static esignature__c esign;
    static Map<String, RecordType> mapContractDevNamRt=new map<String, RecordType>();
    static Map<String, RecordType> mapsignatureDevNamRt=new map<String, RecordType>();


    static{

    	testUser = TestFactory.createUser('TestUser' , UserInfo.getProfileId(), true);
        testUser.PAD_BypassValidationRules__c = true;
        insert testUser;       

        mapContractDevNamRt=AP_Constant.getRecordTypes('contract__c');    
        mapsignatureDevNamRt=AP_Constant.getRecordTypes('eSignature__c');    
    	
    	system.runAs(testUser){
	        //new supplier
	    	supplier = TestFactory.createSupplier('Test Supplier', 'Florange', 'France');
	        insert supplier; 

	        //new contract
	        contract = TestFactory.createContract(supplier.Id,'Contract1',AP_Constant.contractCustValidationStatus);      
	        contract.cTin_AutoPopulateFinalDocumentURL__c=true;
	        contract.RecordTypeId=mapContractDevNamRt.get('cTin_Contract_Draft').id;
	        insert contract;      
	        
	        //new esignature            
	        esign = TestFactory.createEsignature(contract,contract.name,'Signed');
	        esign.recordtypeId=mapsignatureDevNamRt.get('cTin_ReadOnly').id;
	        insert esign;

	        //new contentversions
	        contentVersionLst=new list<ContentVersion>{ 
	        				  new ContentVersion(Title ='testabdhshdgshdg',
												versiondata=blob.valueOf('test.pdf'),
												PathOnClient='test.pdf'),
	        				  new ContentVersion(Title ='testabdhshdgshdg2',
												versiondata=blob.valueOf('test2.pdf'),
												PathOnClient='test2.pdf'),
	        				  new ContentVersion(Title ='testabdhshdgshdg3',
												versiondata=blob.valueOf('test3.pdf'),
												PathOnClient='test3.pdf'),
	        				  new ContentVersion(Title ='testabdhshdgshdg4',
												versiondata=blob.valueOf('test4.pdf'),
												PathOnClient='test4.pdf')

	        				};
			insert contentVersionLst;	
		}	
	}											    
    
    //method checks if the option "Remove access to content" is removed after uploading content deliveries on contracts ans esignatures
    static testmethod void uncheckExpirePref(){
        system.runAs(testUser){

        	//creating content deliveries with expiry date
	    	list<ContentDistribution> lstcd = new list<ContentDistribution>{
								    		 new ContentDistribution(
								    		 name = 'TstContentDistribution1',
								    		 ContentVersionId = contentVersionLst[0].Id,
								    		 PreferencesAllowOriginalDownload = true,
								    		 PreferencesAllowPDFDownload = true,
								    		 PreferencesAllowViewInBrowser = true,
								    		 RelatedRecordId = esign.Id,
								    		 preferencesExpires=true,
								    		 expiryDate=date.today() +30),

								    		 new ContentDistribution(
								    		 name = 'TstContentDistribution2',
								    		 ContentVersionId = contentVersionLst[1].Id,
								    		 PreferencesAllowOriginalDownload = true,
								    		 PreferencesAllowPDFDownload = true,
								    		 PreferencesAllowViewInBrowser = true,
								    		 RelatedRecordId = esign.Id,
								    		 preferencesExpires=true,
								    		 expiryDate=date.today() +30),

								    		 new ContentDistribution(
								    		 name = 'TstContentDistribution3',
								    		 ContentVersionId = contentVersionLst[2].Id,
								    		 PreferencesAllowOriginalDownload = true,
								    		 PreferencesAllowPDFDownload = true,
								    		 PreferencesAllowViewInBrowser = true,
								    		 RelatedRecordId = contract.Id,
								    		 preferencesExpires=true,
								    		 expiryDate=date.today() +30),

								    		  new ContentDistribution(
								    		 name = 'TstContentDistribution4',
								    		 ContentVersionId = contentVersionLst[3].Id,
								    		 PreferencesAllowOriginalDownload = true,
								    		 PreferencesAllowPDFDownload = true,
								    		 PreferencesAllowViewInBrowser = true,
								    		 RelatedRecordId = contract.Id,
								    		 preferencesExpires=true,
								    		 expiryDate=date.today() +30)
								    		
								    		};

	             


	        test.startTest();
	            insert lstcd;
	        test.stopTest();

	        // assert - check if content deliveries created with expiry date are updated with expiry date set to null

	        list<ContentDistribution> lstconDist =[select id from ContentDistribution where id IN:lstcd and preferencesExpires=false];
	        system.assertEquals (4,lstconDist.size());
   	    }
    }

}