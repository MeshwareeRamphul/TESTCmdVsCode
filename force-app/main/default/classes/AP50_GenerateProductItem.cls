public with sharing class AP50_GenerateProductItem {
/*----------------------------------------------------------------------
    -- - Name          : AP50_GenerateProductItem
    -- - Author        : Spoon
    -- - Description   : Class for generating product Item when offer is specified 
                         on creation / update of ATS contract
    --
    -- - History:

    -- Date         Name  Version  Remarks
    -- -----------  ----  -------  ---------------------------------------
    -- 03-MAR-2018  MRA    1.0      Initial version  
    -- 09-AVR-2018  USA    1.1      Update domain and business area  
    -- 28-MAY-2019  USA    1.2      Add method createOppProductItem
    -- 11-FEB-2020  USA    1.3      Update for referentiel produit (SP-154)
	-- 08-JUN-2020	ARA	   1.4		Optimization
-------------------------------------------------------------------------*/

    public AP50_GenerateProductItem(){}
    /**
    * ----------------------------------------------------------------------------------------------
    * methos to create contract product items
    * ----------------------------------------------------------------------------------------------
    * @param    contractIdOfferIdMap map<id,id>    : map of contract and offer id
    * ----------------------------------------------------------------------------------------------
    */
    public static void createProductItem(map<id,id> mapCtrProductId) {
        List<ProductItem__c> lstProductItem = new list<ProductItem__c>();
        map<id, Product__c> mapProduct = new map<id, Product__c>();

        for(Product__c product: [SELECT id, Status__c, Product_level_3__c, Product_line__c, Product_family__c, Product_description__c FROM Product__c WHERE Id = :mapCtrProductId.values()]){
            mapProduct.put(product.Id, product);
        }

        //Rule: generate product item only if count products = 1
        for(id contractId: mapCtrProductId.keyset()){     
            ProductItem__c pItem = new  ProductItem__c (contract__c = contractId,
                                                        product__c = mapCtrProductId.get(contractId),
                                                        Status__c = mapProduct.get(mapCtrProductId.get(contractId)).Status__c,
                                                        ProductDescription__c = mapProduct.get(mapCtrProductId.get(contractId)).Product_Description__c);
            lstProductItem.add(pItem);
     	}
        
        if(lstProductItem.size() > 0){
            insert lstProductItem;
        }
    }

    /*public static void createProductItem(map<id,id> contractIdOfferIdMap) {
        List<ProductItem__c> lstProductItem           = new list<ProductItem__c>();
        map<id, list<Product__c>> offerLstProductsMap = new map<id, list<Product__c>>();
        map<id, Product__c> mapOffers                 = new map<id, Product__c>();
        List<contract__c> lstCtrUpdated               = new List<contract__c>();

        //query products for each offer in contractIdOfferIdMap
        for(Product__c product: [SELECT
         //Offer__c, Offer__r.Domain__r.name, Offer__r.Domain__r.Business_area__r.name,
         status__c,Product_Level_3__c, Product_Line__c,Product_Family__c
                                 FROM Product__c
                                 WHERE Offer__c in:contractIdOfferIdMap.values()
                                 AND status__c = :AP_Constant.PRODUCT_LIVE]){
            mapOffers.put(product.Offer__c, product);
            if(offerLstProductsMap.containsKey(product.Offer__c)) {
                List<Product__c> lstProduct = offerLstProductsMap.get(product.Offer__c);
                lstProduct.add(product);
                offerLstProductsMap.put(product.Offer__c, lstProduct);
            }
            else{
                offerLstProductsMap.put(product.Offer__c, new List<Product__c> { product });
            }
        }

        //Rule: generate product item only if count products = 1
        for(id contractId: contractIdOfferIdMap.keyset()){     
            if(offerLstProductsMap.containsKey(contractIdOfferIdMap.get(contractId))){
                if(offerLstProductsMap.get(contractIdOfferIdMap.get(contractId)).size() == 1){
                    ProductItem__c pItem = new  ProductItem__c (contract__c = contractId,
                                                              product__c = (offerLstProductsMap.get(contractIdOfferIdMap.get(contractId)))[0].id,
                                                              status__c = (offerLstProductsMap.get(contractIdOfferIdMap.get(contractId)))[0].status__c);
                    lstProductItem.add(pItem);
                }
            }   
            // update domain and business area for ATS
            if (mapOffers.containsKey(contractIdOfferIdMap.get(contractId))){
                lstCtrUpdated.add(new contract__c(id = contractId, 
                                                  Domain_ATS__c = mapOffers.get(contractIdOfferIdMap.get(contractId)).Product_Line__c, 
                                                  BusinessArea_ATS__c = mapOffers.get(contractIdOfferIdMap.get(contractId)).Product_Family__c));    
            }
     	}
        
        if(lstProductItem.size() > 0){
            insert lstProductItem;
        }
        if(lstCtrUpdated.size() > 0){
            update lstCtrUpdated;
        }
    }*/

    /**
    * ----------------------------------------------------------------------------------------------
    * methos to create opportunity product items
    * ----------------------------------------------------------------------------------------------
    * @param    oppIdOfferIdMap map<id,id>    : map of opportunity and offer id
    * ----------------------------------------------------------------------------------------------
    */
    /*public static void createOppProductItem(map<id,id> oppIdOfferIdMap) {
        List<Opp_ProductItem__c>lstOppProdItem        = new list<Opp_ProductItem__c>();
        map<id, list<Product__c>> offerLstProductsMap = new map<id, list<Product__c>>();

        //query products for each offer in contractIdOfferIdMap
        for(Product__c product: [SELECT 
        //Offer__c, Offer__r.Domain__r.name, Offer__r.Domain__r.Business_area__r.name,
         status__c,Product_Level_3__c, Product_Line__c,Product_Family__c
                                 FROM Product__c 
                                 WHERE Offer__c in:oppIdOfferIdMap.values()
                                 AND status__c = :AP_Constant.PRODUCT_LIVE]){

            if(offerLstProductsMap.containsKey(product.Offer__c)) {
                List<Product__c> lstProduct = offerLstProductsMap.get(product.Offer__c);
                lstProduct.add(product);
                offerLstProductsMap.put(product.Offer__c, lstProduct);
            }
            else{
                offerLstProductsMap.put(product.Offer__c, new List<Product__c> { product });
            }
        }
        
        //Rule: generate product item only if count products = 1
        for(id oppId:oppIdOfferIdMap.keyset()){  
            if(offerLstProductsMap.containsKey(oppIdOfferIdMap.get(oppId))){
                if(offerLstProductsMap.get(oppIdOfferIdMap.get(oppId)).size() == 1){
                    Opp_ProductItem__c pItem = new Opp_ProductItem__c (Opportunity__c = oppId,
                                                                      product__c = (offerLstProductsMap.get(oppIdOfferIdMap.get(oppId)))[0].id,
                                                                      status__c = (offerLstProductsMap.get(oppIdOfferIdMap.get(oppId)))[0].status__c);
                    lstOppProdItem.add(pItem);
                }
            }   
        }
        
        if(lstOppProdItem.size() > 0){
            insert lstOppProdItem;
        }
    }*/
}