public class LC04_AddProduct {
	/*
	----------------------------------------------------------------------
	-- - Name          : LC04_AddProduct
	-- - Author        : USA
	-- - Description   : Controller for lighning component LC04_AddProduct
	--
	-- Maintenance History:
	--
	-- Date          Name   Version   Remarks
	-- -----------   ----   -------   ---------------------------------------
	--               USA    1.0      Initial version
	-- 11/02/2020    USA    1.1      Update for referentiel produit (SP-154)
	--------------------------------------------------------------------------- */
	@AuraEnabled
	public static List<Product__c> getAllProducts(Id objID) {
		String offerId;
		List<Product__c> lstProd = new List<Product__c>();
		
		// check if opportunity product item or contract product item is being added 
		/*if (String.valueOf(objID).startsWith('006')){
			// opportunity product item 
			Opportunity opp = [Select id, name, Offer__c from Opportunity where Id = :objID];
			offerId         = opp.Offer__c;
			lstProd         = [SELECT Id, name, Product_description__c, status__c
                                 FROM Product__c 
                                WHERE offer__c = :offerId
								  AND status__c = 'Live !'
                                  AND Id NOT IN (SELECT Product__c 
                                                   FROM Opp_ProductItem__c 
                                                  WHERE Opportunity__c = :objID)];
		}
		else{
			// contract product item
			Contract__c con = [Select id, name, OfferATS__c from Contract__c where Id = :objID];
			offerId         = con.OfferATS__c;
			lstProd         = [SELECT Id, name, Product_description__c 
                                 FROM Product__c 
                                WHERE offer__c = :offerId
								  AND status__c = 'Live !'
                                  AND Id NOT IN (SELECT Product__c 
                                                   FROM ProductItem__c 
                                                  WHERE Contract__c = :objID)];
		}*/
        return lstProd;
    }

    @AuraEnabled
    public static List <String> saveRecords(List<Id> lstProdId, Id objID) {
	    // for store Error Messages
	    List <String> oErrorMsg = new List <String>();
	    List<ProductItem__c> lstNewCtrProductItem = new List<ProductItem__c>();
	    List<Opp_ProductItem__c> lstNewOppProductItem = new List<Opp_ProductItem__c>();
		map<Id,Product__c> mapProd = new map<Id,Product__c>([SELECT Id, name, Product_description__c, status__c
															   FROM Product__c 
															  WHERE Id in:lstProdId]);
	    for(Id prodId : lstProdId){
	    	if (String.valueOf(objID).startsWith('006')){
	    		Opp_ProductItem__c newOppProductItem = new Opp_ProductItem__c();
		  		newOppProductItem.Opportunity__c = objID;
		  		newOppProductItem.Product__c = prodId;
				newOppProductItem.ProductDescription__c = mapProd.containsKey(prodId)? mapProd.get(prodId).Product_description__c :null;
				newOppProductItem.Status__c = mapProd.containsKey(prodId)? mapProd.get(prodId).status__c :null;
				lstNewOppProductItem.add(newOppProductItem);
	    	}
	    	else{
				ProductItem__c newProductItem = new ProductItem__c();
		  		newProductItem.Contract__c = objID;
		  		newProductItem.Product__c = prodId;
				newProductItem.ProductDescription__c = mapProd.containsKey(prodId)? mapProd.get(prodId).Product_description__c :null;
				newProductItem.Status__c = mapProd.containsKey(prodId)? mapProd.get(prodId).status__c :null;
		  		lstNewCtrProductItem.add(newProductItem);
	    	}
	  	}

	  	if (lstNewCtrProductItem.size() > 0){
			Database.SaveResult[] srList = Database.insert(lstNewCtrProductItem, false);
			// Iterate through each returned result
			for (Database.SaveResult sr : srList) {
				if (sr.isSuccess()){
					System.debug('Successfully inserted ');
		        	oErrorMsg = null;
		    	}
		    	else{
		        	// Operation failed, so get all errors                
		        	for(Database.Error err : sr.getErrors()) {
		        		System.debug('The following error has occurred.');                    
		            	System.debug(err.getStatusCode() + ': ' + err.getMessage());
		            	System.debug('Account fields that affected this error: ' + err.getFields());
		            	oErrorMsg.add(err.getStatusCode() + ': ' + err.getMessage());
		        	}
		    	}
			}
		}
		if (lstNewOppProductItem.size() > 0){
			Database.SaveResult[] srList = Database.insert(lstNewOppProductItem, false);
			// Iterate through each returned result
			for (Database.SaveResult sr : srList) {
				if (sr.isSuccess()){
					System.debug('Successfully inserted ');
		        	oErrorMsg = null;
		    	}
		    	else{
		        	// Operation failed, so get all errors                
		        	for(Database.Error err : sr.getErrors()) {
		        		System.debug('The following error has occurred.');                    
		            	System.debug(err.getStatusCode() + ': ' + err.getMessage());
		            	System.debug('Account fields that affected this error: ' + err.getFields());
		            	oErrorMsg.add(err.getStatusCode() + ': ' + err.getMessage());
		        	}
		    	}
			}
		}
		return oErrorMsg;
	}
}