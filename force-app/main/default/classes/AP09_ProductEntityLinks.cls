public with sharing class AP09_ProductEntityLinks {

    /**
    * Update Anti duplicate field value
    */
    public static void fillAntiDuplicateField(List<ProductEntityLink__c> pProductEntityLink) {
        System.debug('###### >>> Starting fillAntiDuplicateField');
        for (ProductEntityLink__c vLink : pProductEntityLink) {
            vLink.TECH_Anti_Duplicate_Value__c = setTECHAntiDuplicateValue(vLink.Product__c/*, vLink.Offer__c*/, vLink.Entity__c);
        }
        System.debug('###### >>> END fillAntiDuplicateField');
    }

    // upsert ProductEntity on opportunity
    /*public static void upsertProductEntityLinkOnOptyList(Map<Id, Opportunity> oldOppMap, Map<Id, Opportunity> newOppMap) {
        List<ProductEntityLink__c> pelList = new List<ProductEntityLink__c>();

        Set<Id> productIdSet = new Set<Id>();
        for (Opportunity newOpp : newOppMap.values()) {
            if (newOpp.Product__c != null) productIdSet.add(newOpp.Product__c);
        }
        System.debug('productIdSet=' + productIdSet);

        Map<Id, String> productOfferMap = new Map<Id, String>();
        for (Product__c product : [SELECT Id, Product_Level_3__c FROM Product__c WHERE Id IN :productIdSet AND Product_Level_3__c != null]) {
            productOfferMap.put(product.Id, product.Product_Level_3__c);
        }
        System.debug('productOfferMap=' + productOfferMap);

        // only for "Oppty & Contract" record types
        Set<Id> recordTypeValidSet = new Set<Id> {
            Schema.getGlobalDescribe().get('Opportunity').getDescribe().getRecordTypeInfosByName().get(Label.RT_OppContract).getRecordTypeId(),
            Schema.getGlobalDescribe().get('Opportunity').getDescribe().getRecordTypeInfosByName().get(Label.RT_OppReadOnly).getRecordTypeId()
        };

        for (Opportunity newOpp : newOppMap.values()) {
            // on opp status change with offer OR when a product with offer is chosen, update or insert (upsert) PEL
            if (newOpp.Product__c != null && recordTypeValidSet.contains(newOpp.recordTypeId) &&
                    (oldOppMap != null && oldOppMap.get(newOpp.Id).StageName != newOpp.StageName)) {// || 
                    //(oldOppMap == null || (oldOppMap != null && oldOppMap.get(newOpp.Id).Product__c == null))) { // Insert or update

                ProductEntityLink__c pel = new ProductEntityLink__c();
                pel.Product__c = newOpp.Product__c;
                pel.Offer__c = productOfferMap.get(newOpp.Product__c);
                pel.Entity__c = newOpp.AccountId;
                pel.First_Release_Date__c = newOpp.Go_live_date__c;
                pel.TECH_Anti_Duplicate_Value__c = setTECHAntiDuplicateValue(newOpp.Product__c, newOpp.Product__r.Product_Level_3__c, newOpp.AccountId);

                // change ERO status, ERO trigger will check if the old ERO is with superior status (in this case, we keep the existing ERO statut OR find all oppties with entity/product to get the right status)
                pel.POS_Status__c = getPosStatus(newOpp.StageName, newOpp.Go_live_date__c);

                if (String.isNotBlank(pel.POS_Status__c)) pelList.add(pel);//if (isStatusChanged) pelList.add(pel);//pel.Offer__c != null) pelList.add(pel);
            }

        }
       

        System.debug('pelList=' + pelList);
        if (!pelList.isEmpty()) {
           // upsert pelList ProductEntityLink__c.Fields.TECH_Anti_Duplicate_Value__c;
        }
    }*/



    // get POS status
    /*private static String getPosStatus(String stageName, Date endDate) {
        String status;

        // pas besoin de créer si Collect
        //if (Label.OptyStage_Collect.equals(stageName)) {
        //    status = Label.ProductEntityLinkStatus_Opportunity;
        //} else 
        if (Label.OptyStage_QualifyAlign.equals(stageName)) {
            status = Label.ProductEntityLinkStatus_UnderDiscussion;
        } else if (Label.OptyStage_Won.equals(stageName) && endDate != null) {
            if (endDate <= System.today()) {
                if (endDate.year() < System.today().year()) {
                    status = Label.ProductEntityLinkStatus_Live;
                } else if (endDate.year() == System.today().year()) {
                    status = Label.ProductEntityLinkStatus_NewLive;
                }
            } else {
                status = Label.ProductEntityLinkStatus_Planned;
            }
        }
        return status;
    }*/



    // before insert/update
    /*public static void checkOrderStatus(Map<Id, ProductEntityLink__c> oldPelMap, Map<Id, ProductEntityLink__c> newPelMap) {
        
        Map<String, Integer> orderStatus = getOrderStatus();

        // need to get the right status if new status if inferior to old status
        //List<EntityProduct> entityProductList = new List<EntityProduct>();
        if (newPelMap != null) {
            for (ProductEntityLink__c newPel : newPelMap.values()) {
                if (newPel.POS_Status__c != oldPelMap.get(newPel.Id).POS_Status__c) {
                    // if new POS status order is inferior to old POS status order, check the right status
                    if (orderStatus.get(newPel.POS_Status__c) < orderStatus.get(oldPelMap.get(newPel.Id).POS_Status__c)) {
                        newPel.POS_Status__c = oldPelMap.get(newPel.Id).POS_Status__c;
                        
                        newPel.First_Release_Date__c = oldPelMap.get(newPel.Id).First_Release_Date__c;
                        
                    }
                } else {
                    // keep the old date if new date is empty or before old date
                    if (newPel.First_Release_Date__c == null || (oldPelMap.get(newPel.Id).First_Release_Date__c != null && newPel.First_Release_Date__c < oldPelMap.get(newPel.Id).First_Release_Date__c)) {
                        newPel.First_Release_Date__c = oldPelMap.get(newPel.Id).First_Release_Date__c;
                    }
                }
            }
        }
    }*/

    private static Map<String, Integer> getOrderStatus() {
        Map<String, Integer> orderMap = new Map<String, Integer>();

        for (POS__mdt pos : [SELECT Order__c, MasterLabel, DeveloperName FROM POS__mdt]) {
            orderMap.put(pos.MasterLabel, Integer.valueOf(pos.Order__c));
        }
        return orderMap;
    }

    private static String setTECHAntiDuplicateValue(String productId/*, String offerId*/,String accountId) {
        return productId + '_'/* + offerId + '_'*/ + accountId;
    }
    
    //Added by Johan Hazebrouck
    //Trigger to manage the isPartial fonctionnality
    public static void checkIsPartial(List<ProductEntityLink__c> pProductEntityLink){
    	Map<String, Integer> orderStatus = getOrderStatus();
    	List<ProductEntityLink__c> listEROPartial = new List<ProductEntityLink__c>();
    	List<ProductEntityLink__c> listERONotPartial = new List<ProductEntityLink__c>();
    	List<ProductEntityLink__c> listEROToUpdate = new List<ProductEntityLink__c>();
    	
    	//Get a list with all ERO
   		List<ProductEntityLink__c> listAllERO = [SELECT Id, POS_Status__c, First_Release_Date__c,
   		Product__c, Entity__c, /*Offer__c,*/ Is_Partial__c FROM ProductEntityLink__c];
   		
   		//Init a Map to link key: Entity_Offer with values: Set of ERO
   		Map<String, Set<ProductEntityLink__c>> mapEROToCheck = new Map<String, Set<ProductEntityLink__c>>();
   		
   		//Go through listAllERO to catch ERO with the same key
   		for(ProductEntityLink__c pel : pProductEntityLink){
   			for(ProductEntityLink__c pel2 : listAllERO){
   				/*if(pel.Entity__c == pel2.Entity__c && pel.Offer__c == pel2.Offer__c){
	   				if(mapEROToCheck.containsKey(pel.Entity__c + '_' + pel.Offer__c)){
	   					mapEROToCheck.get(pel.Entity__c + '_' + pel.Offer__c).add(pel2);
	   				}
	   				else {
	   					mapEROToCheck.put(pel2.Entity__c + '_' + pel2.Offer__c, new Set<ProductEntityLink__c> {pel2});
	   				}
   				}*/
   			}
   		}
   		
   		//Go through the map
   		/*for(String s : mapEROToCheck.keySet()){
   			//Check if the Set has more than 1 record associated to the key
   			//If so, isPartial is possible
   			if(mapEROToCheck.get(s).size() > 1){
   				//Init a counter to check if all EROs have the same status or not
   				Integer cmpSameStatus = 1;
   				//Init a ERO Temp to keep the bigger ERO and assign it the isPartial flag
   				ProductEntityLink__c EROTemp = new ProductEntityLink__c();
   				//Init boolean to check if products are the same or not
   				Boolean isSameProduct = true;
   				
   				//Go through the Set of values
   				for(ProductEntityLink__c pel : mapEROToCheck.get(s)){
   					//We compare the iteration ERO with the EROTemp
   					if(EROTemp.Id != null){
   						if(EROTemp.Product__c != pel.Product__c)
   							isSameProduct = false;
   							
   						if(orderStatus.get(EROTemp.POS_Status__c) > orderStatus.get(pel.POS_Status__c)){
   							listERONotPartial.add(pel);
   						}
   						else if(orderStatus.get(EROTemp.POS_Status__c) == orderStatus.get(pel.POS_Status__c)){
   							if(EROTemp.First_Release_Date__c < pel.First_Release_Date__c){
   								listERONotPartial.add(pel);
   							}
   							else {
   								listERONotPartial.add(EROTemp);
   								EROTemp = pel;
   								cmpSameStatus += 1;
   							}
   						}
   						else {
   							listERONotPartial.add(EROTemp);
   							EROTemp = pel;
   						}
   					}
   					//First iteration we assigned the ERO to EROTemp
   					else EROTemp = pel;
   				}
   				
   				//Verify if all records have the same status or not
   				if(cmpSameStatus == mapEROToCheck.get(s).size() || isSameProduct)
   					listERONotPartial.add(EROTemp);
   				else listEROPartial.add(EROTemp);
   			}
   		}
   		
   		//go trhough ListEROPartial to check the isPartial Flag on the records
   		for(ProductEntityLink__c pel : listEROPartial){
   			if(!pel.Is_Partial__c){
   				pel.Is_Partial__c = true;
   				listEROToUpdate.add(pel);
   			}
   		}
   		
   		//go trhough ListERONotPartial to remove the isPartial Flag on the records
   		for(ProductEntityLink__c pel : listERONotPartial){
   			if(pel.Is_Partial__c){
   				pel.Is_Partial__c = false;
   				listEROToUpdate.add(pel);
   			}
   		}
   		
   		if(listEROToUpdate.size() > 0)
   			update listEROToUpdate;*/
    }
}