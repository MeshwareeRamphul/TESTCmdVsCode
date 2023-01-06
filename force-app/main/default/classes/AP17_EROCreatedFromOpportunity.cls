/**
 * Class AP17_EROCreatedFromOpportunity : the methods of the class will be called by the corresponding
 * trigger
 * @Version 1.0
 * @Author Eric Wartelle
 * @VersionHistory
 * 1.0 : Initial version
 */

/*Modification Log :
-----------------------------------------------------------------------------
* Developer                 Date          Description
* ----------                ----------    -------------------------
* Urvashi Sadasing          09/08/2017    ALLINFIN-515 POS : Modification EROs impossible
*************************************************************************************/
public with sharing class AP17_EROCreatedFromOpportunity {
	//Attributs for AP17_EROCreatedFromOpportunity

	//Constructors for AP17_EROCreatedFromOpportunity
	public AP17_EROCreatedFromOpportunity() {

	}

	//pass map of opp with key Entity-Product, set of entities and set of products
	/*public static void createUpdateERO(Map<String,Opportunity> mapOppNew, set<Id> setAccId, set<Id> setProdId){
        system.debug('##AP17## start: ' + mapOppNew + ' - ' + setAccId + ' - ' + setProdId);
		//define maps for comparing opp stages and ero status
		Map<String,Integer> mapOppStages = new Map<String,Integer>();
		Map<String,Integer> mapEROStatus = new Map<String,Integer>();
		Map<String,String> mapOppEro = new Map<String,String>();
		mapOppStages.put(AP_Constant.STAGE_QUALIFY_ALIGN, 1);
		mapOppStages.put(AP_Constant.STAGE_CONTRACTING, 2);
		mapOppStages.put(AP_Constant.STAGE_WON, 3);
		mapEROStatus.put(AP_Constant.strPosStatus_UndrDis, 1);
		mapEROStatus.put(AP_Constant.strPosStatus_Plan, 2);
		mapEROStatus.put(AP_Constant.strPosStatus_NewLive, 3);
		mapEROStatus.put(AP_Constant.strPosStatus_Live, 3);
		mapOppEro.put(AP_Constant.STAGE_QUALIFY_ALIGN, AP_Constant.strPosStatus_UndrDis);
		mapOppEro.put(AP_Constant.STAGE_CONTRACTING, AP_Constant.strPosStatus_Plan);
		//mapOppEro.put(AP_Constant.STAGE_WON, AP_Constant.strPosStatus_NewLive);

        //Map of ERO with Entity-Product as key
        Map<String,ProductEntityLink__c> mapEroExist = new map<String,ProductEntityLink__c>();
        //record type ERO
        Id eroRecType = Schema.SObjectType.ProductEntityLink__c.getRecordTypeInfosByName().get(AP_Constant.strERORecType).getRecordTypeId();
        //build map of existing EROs
        for (ProductEntityLink__c ero :[SELECT id, name, RecordTypeId, First_Release_Date__c, POS_Status__c, Entity__c, Product__c, TECH_Anti_Duplicate_Value__c
                                        FROM ProductEntityLink__c
                                        WHERE RecordTypeId = :eroRecType
                                        AND Entity__c in :setAccId
                                        AND Product__c in :setProdId]){
            mapEroExist.put(ero.Entity__c + '-' + ero.Product__c, ero);
        }
        system.debug('##AP17## mapEroExist: ' + mapEroExist );

        List<ProductEntityLink__c> lstEroToCreate = new List<ProductEntityLink__c>();
        List<ProductEntityLink__c> lstEroToUpdate = new List<ProductEntityLink__c>();
        //Map<String,Integer> mapStatusOrder = AP_Constant.getOrderStatus(); ?????

        for (String eroKey :mapOppNew.keySet()){
            //get current opportunity
            Opportunity oppCurrent = mapOppNew.get(eroKey);
            // if ero does not exist -> create
            if (!mapEroExist.containsKey(eroKey)){
                system.debug('##AP17## ero not exists ');
                lstEroToCreate.add(new ProductEntityLink__c(RecordTypeId = eroRecType
                                                           ,Entity__c = oppCurrent.accountId
                                                           ,Product__c = oppCurrent.Product__c
                                                           ,First_Release_Date__c = oppCurrent.Go_live_date__c
                                                           ,POS_Status__c = AP_Constant.strPosStatus_UndrDis // ??????
                                                            ));
            }
            // else if ero exists -> check status and date
            else{
                system.debug('##AP17## ero exists ');
                Boolean isUpdated = FALSE;
                //get concerned ERO
                ProductEntityLink__c eroCurrent = mapEroExist.get(oppCurrent.accountId + '-' + oppCurrent.Product__c);
                //check stage
                if ((mapEROStatus.get(eroCurrent.POS_Status__c) < mapOppStages.get(oppCurrent.StageName))
                    || (eroCurrent.POS_Status__c == NULL)
                    ){
                    system.debug('##AP17## if no 1 ');
                	if ((oppCurrent.StageName == AP_Constant.STAGE_WON) && oppCurrent.Go_live_date__c.year() >= Date.today().year()){
                		eroCurrent.POS_Status__c = AP_Constant.strPosStatus_NewLive;
                        system.debug('##AP17## if ');
                	}
                	else if ((oppCurrent.StageName == AP_Constant.STAGE_WON) && oppCurrent.Go_live_date__c.year() < Date.today().year()){
                		eroCurrent.POS_Status__c = AP_Constant.strPosStatus_Live;
                        system.debug('##AP17## else if ');
                	}
                	else{
                		eroCurrent.POS_Status__c = mapOppEro.get(oppCurrent.StageName);
                        system.debug('##AP17## else ' + eroCurrent.POS_Status__c);
                	}
                	isUpdated = TRUE;
                }
                //check date
                if ((eroCurrent.First_Release_Date__c > oppCurrent.Go_live_date__c )
                    || eroCurrent.First_Release_Date__c == NULL){
                    system.debug('##AP17## check date 1 ' + eroCurrent.First_Release_Date__c);
                    eroCurrent.First_Release_Date__c = oppCurrent.Go_live_date__c;
                    system.debug('##AP17## check date 2 ' + eroCurrent.First_Release_Date__c);
                    isUpdated = TRUE;
                }
                if (isUpdated){
                    lstEroToUpdate.add(eroCurrent);
                }
            }
        }
        system.debug('##AP17## lstEroToUpdate: ' + lstEroToUpdate );
        system.debug('##AP17## lstEroToCreate: ' + lstEroToCreate );
        if (lstEroToUpdate.size() > 0){
            update lstEroToUpdate;
        }
        if (lstEroToCreate.size() > 0){
            insert lstEroToCreate;
        }
    }*/

	////Methods for AP17_EROCreatedFromOpportunity
	///**
	// * Method opportunitiesFilter : will filter the opportunities to keep only the oppty who will generate
	// * a new ERO
	// * @param opptiesToBeFiltered List<Opportunity>: the oppties send by the trigger
	// * @return List<Opportunity> : the oppties that will generate new ERO
	// */
	//private static List<Opportunity> opportunitiesFilter(List<Opportunity> opptiesToBeFiltered){
	//	//System.debug call for the debug log
	//	System.debug(LoggingLevel.INFO, '##AP17## opportunitiesFilter Start');

	//	//Local variable declaration
	//	List<Opportunity> filteredOppties = new List<Opportunity>();

	//	//System.debug call for the debug log
	//	System.debug(LoggingLevel.INFO, '##AP17## opportunitiesFilter - opptiesToBeFiltered.size : ' + opptiesToBeFiltered.size());
	//	System.debug(LoggingLevel.INFO, '##AP17## opportunitiesFilter - filterOppties.size : ' + filteredOppties.size());

	//	//For each opportunity in the given map, will get the product and the entity Id
	//	Set<String> concernedProducts = new Set<String>();
	//	Set<Id> concernedEntitiesId = new Set<Id>();
	//	for(Opportunity currentOppty : opptiesToBeFiltered){
	//		if(currentOppty.Product__c != null){
	//			concernedProducts.add(currentOppty.Product__c);
	//		}
	//		//if(currentOppty.Account != null){
	//			System.debug(LoggingLevel.INFO, '##AP17## opportunitiesFilter currentOppty.AccountId : ' + currentOppty.AccountId);
	//			concernedEntitiesId.add(currentOppty.AccountId);
	//		//}
	//	}

	//	//System.debug call for the debug log
	//	System.debug(LoggingLevel.INFO, '##AP17## opportunitiesFilter - concernedProducts.size : ' + concernedProducts.size());
	//	System.debug(LoggingLevel.INFO, '##AP17## opportunitiesFilter - concernedEntitiesId.size : ' + concernedEntitiesId.size());

	//	//Will get the list of existing ERO for the concerned entities and product
	//	Map<Id, ProductEntityLink__c> concernedEROs = new Map<Id, ProductEntityLink__c>([SELECT Entity__c,Id,Product__c FROM ProductEntityLink__c WHERE
	//													Product__c IN :concernedProducts AND Entity__c IN :concernedEntitiesId]);
	//	Set<Id> concernedEROsKeySet = concernedEROs.keySet();

	//	//System.debug call for the debug log
	//	System.debug(LoggingLevel.INFO, '##AP17## opportunitiesFilter - concernedEROs.size : ' + concernedEROs.size());
	//	System.debug(LoggingLevel.INFO, '##AP17## opportunitiesFilter - concernedEROsKeySet.size : ' + concernedEROsKeySet.size());

	//	//Now, will fill the filterOppties map
	//	for(Opportunity currentOppty : opptiesToBeFiltered){
	//		//Opportunity currentOppty = opptiesToBeFiltered.get(opptyToBeFilterdKey);
	//		Boolean filterFlag = true;
	//		for(Id concernedEROKey : concernedEROsKeySet){
	//			ProductEntityLink__c currentERO = concernedEROs.get(concernedEROKey);
	//			if((currentOppty.Product__c == currentERO.Product__c) &&
	//				(currentOppty.AccountId == currentERO.Entity__c) ){
	//				filterFlag = false;
	//			}
	//		}
	//		//The opportunity will generate an ERO
	//		if(filterFlag && (currentOppty.StageName == 'Qualify/Align')){
	//			filteredOppties.add(currentOppty);
	//		}
	//	}

	//	//System.debug call for the debug log
	//	System.debug(LoggingLevel.INFO, '##AP17## filteredOppties.size ' + filteredOppties.size());
	//	System.debug(LoggingLevel.INFO, '##AP17## opportunitiesFilter End');

	//	//Return the filtered opportunities
	//	return filteredOppties;
	//}

	///**
	// * Methode generateConcernedOfferMap : will generate a map that will link a product to an offer
	// * @param concernOppties List<Opportunity> : oppties send by the trigger
	// * @return Map<Product__c, Offer__c>
	// */
	//public static Map<Id, Offer__c> generateConcernedOfferMap(List<Opportunity> concernOppties){
	//	//System.debug call for the debug log
	//	System.debug(LoggingLevel.INFO, '##AP17## generateConcernedOfferMap Start');

	//	//Variables declaration
	//	set<Product__c> concernedProductsSet = new set<Product__c>();
	//	List<Id> listProductsId = new List<Id>();
	//	List<Id> listOffersId = new List<Id>();
	//	Map<Id, Offer__c> concernedOffersMap = new Map<Id, Offer__c>();

	//	//For each oppty in the list, will add the corresponding prod
	//	for(Opportunity currentOppty : concernOppties){
	//		System.debug(LoggingLevel.INFO, '##AP17## generateConcernedOfferMap - currentOppty.Product__r : ' + currentOppty.Product__c);
	//		listProductsId.add(currentOppty.Product__c);
	//	}
	//	concernedProductsSet = new set<Product__c>([SELECT Id, Offer__c FROM Product__c WHERE Id IN: listProductsId ]);

	//	//System.debug call for the debug log
	//	System.debug(LoggingLevel.INFO, '##AP17## generateConcernedOfferMap - concernedProductsSet.size() : ' + concernedProductsSet.size());

	//	for(Product__c concernedProduct : concernedProductsSet){
	//		listOffersId.add(concernedProduct.Offer__c);
	//	}
	//	Map<Id, Offer__c> offerTempMap = new Map<Id, Offer__c>([SELECT Id FROM Offer__c WHERE Id in: listOffersId]);

	//	//For each product in the list concernedProductLists
	//	for(Product__c product : concernedProductsSet){
	//		if(product != null){
	//			System.debug(LoggingLevel.INFO, '##AP17## generateConcernedOfferMap - product : ' + product);

	//			concernedOffersMap.put(product.Id, offerTempMap.get(product.Offer__c));
	//		}
	//	}

	//	//System.debug call for the debug log
	//	System.debug(LoggingLevel.INFO, '##AP17## generateConcernedOfferMap - concernedOffersMap.size() : ' + concernedOffersMap.size());
	//	System.debug(LoggingLevel.INFO, '##AP17## generateConcernedOfferMap End');

	//	//Return the list of concerned product
	//	return concernedOffersMap;
	//}

	///**
	// * Method createEROFromOpportunity : will create (not insert) an ero
	// * @param oppty Opportunity : the opportunity from which you need to create an ERO
	// * @param productsToOffersMapping :
	// */
	//private static ProductEntityLink__c createEROFromOpportunity(Opportunity oppty, Map<Id, Offer__c> productsToOffersMapping){
	//	//System.debug call for the debug logs
	//	System.debug(LoggingLevel.INFO, '##AP17## createEROFromOpportunity Start');

	//	//Variables declaration
	//	ProductEntityLink__c newERO = new ProductEntityLink__c();

	//	//Instanciation of the newERO
	//	newERO.Offer__c = productsToOffersMapping.get(oppty.Product__c).Id;
	//	newERO.Product__c = oppty.Product__c;
	//	newERO.Entity__c = oppty.AccountId;
	//	newERO.POS_Status__c = 'Under discussion';

	//	//System.debug call for the debug logs
	//	System.debug(LoggingLevel.INFO, '##AP17## createEROFromOpportunity - newERO.Offer__c : ' + newERO.Offer__c);
	//	System.debug(LoggingLevel.INFO, '##AP17## createEROFromOpportunity - newERO.Product__c : ' + newERO.Product__c);
	//	System.debug(LoggingLevel.INFO, '##AP17## createEROFromOpportunity - newERO.Entity__c : ' + newERO.Entity__c);
	//	System.debug(LoggingLevel.INFO, '##AP17## createEROFromOpportunity End');

	//	//Return the newly created ERO
	//	return newERO;
	//}

	///**
	// * Method generateERO : will generate the EROs corresponding to the opportunities
	// * @param oppties Map<Id, Opportunity> : Oppties send by the trigger
	// */
	//public static void generateERO(List<Opportunity> oppties){
	//	//System.debug call for the debug logs
	//	System.debug(LoggingLevel.INFO, '##AP17## generateERO Start');

	//	//Variables declarations
	//	List<Opportunity> filteredOppties = opportunitiesFilter(oppties);
	//	Map<Id, Offer__c> productsToOffersMapping = generateConcernedOfferMap(filteredOppties);
	//	List<ProductEntityLink__c> toBeInsertedERO = new List<ProductEntityLink__c>();

	//	//System.debug call for the debug logs
	//	System.debug(LoggingLevel.INFO, '##AP17## generateERO - filteredOppties.size : ' + filteredOppties.size());
	//	System.debug(LoggingLevel.INFO, '##AP17## generateERO - productsToOffersMapping.size : ' + productsToOffersMapping.size());

	//	//Now that we have the filtered oppties we need to create the correponding Ero

	//	//System.debug call for the debug logs
	//	if(productsToOffersMapping.size() != 0){
	//		//For each filtered oppties, will generate a corresponding ERO
	//		for(Opportunity currentOppty : filteredOppties){
	//			toBeInsertedERO.add(createEROFromOpportunity(currentOppty, productsToOffersMapping));
	//		}
	//	}

	//	//Insertion of the newly created EROs
	//	try{
	//		insert toBeInsertedERO;
	//	}
	//	catch(System.DmlException e){
	//		for(Integer i = 0; i < e.getNumDml(); i++){
	//			//System.debug in case of error.
	//			System.debug(LoggingLevel.ERROR, '##AP17## generateERO : ' + e.getDmlMessage(i));
	//		}
	//	}

	//	//System.debug call for the debug logs
	//	System.debug(LoggingLevel.INFO, '##AP17## generateERO End');
	//}
}