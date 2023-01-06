public class AP61_Product {
	
    /*----------------------------------------------------------------------
-- - Name          : ProductItemTriggerHandler
-- - Author        : Spoon
-- - Description   : trigger handler for ProductItem__c
--
-- - History:

-- Date         Name  Version  Remarks
-- -----------  ----  -------  ---------------------------------------
-- 					   1.0      Initial version 
-- 07-SEP-2021  ARA    1.1    SP-03707: Update Product selection module to allow multiple products from diff. Lvl3

-------------------------------------------------------------------------*/
    public static void updateProductItems(Map<Id, Product__c> mapProduct){
        List<sObject> lstProductItem = new List<sObject>();
        for(Opp_ProductItem__c prodItem : [SELECT Id, Status__c, Product__c FROM Opp_ProductItem__c WHERE Product__c IN :mapProduct.keySet()]){
            prodItem.Status__c = mapProduct.get(prodItem.Product__c).Status__c;
            prodItem.ProductDescription__c = mapProduct.get(prodItem.Product__c).Product_description__c;
            lstProductItem.add(prodItem);
        }
        for(ProductItem__c prodItem : [SELECT Id, Status__c, Product__c FROM ProductItem__c WHERE Product__c IN :mapProduct.keySet()]){
            prodItem.Status__c = mapProduct.get(prodItem.Product__c).Status__c;
            prodItem.ProductDescription__c = mapProduct.get(prodItem.Product__c).Product_description__c;
            lstProductItem.add(prodItem);
        }
        
        update lstProductItem;
    }
    
    public static void updateContractAndOpportunity(Map<Id, Product__c> mapProductLevel3){
        /*
        Map<Id, sObject> mapObjects = new Map<Id, sObject>();
        for(Opp_ProductItem__c prodItem : [SELECT Id, Opportunity__c, Opportunity__r.Product_Level_3__c, Product__c FROM Opp_ProductItem__c WHERE Product__c IN :mapProductLevel3.keySet()]){
            if(!mapObjects.containsKey(prodItem.Opportunity__c) && prodItem.Opportunity__r.Product_Level_3__c != mapProductLevel3.get(prodItem.Product__c).Product_Level_3__c){
                mapObjects.put(prodItem.Opportunity__c, new Opportunity(Id = prodItem.Opportunity__c, Product_Level_3__c = mapProductLevel3.get(prodItem.Product__c).Product_Level_3__c));
            }
        }
        for(ProductItem__c prodItem : [SELECT Id, Contract__c, Contract__r.Product_Level_3__c, Product__c FROM ProductItem__c WHERE Product__c IN :mapProductLevel3.keySet()]){
            if(!mapObjects.containsKey(prodItem.Contract__c) && prodItem.Contract__r.Product_Level_3__c != mapProductLevel3.get(prodItem.Product__c).Product_Level_3__c){
                mapObjects.put(prodItem.Contract__c, new Contract__c(Id = prodItem.Contract__c, Product_Level_3__c = mapProductLevel3.get(prodItem.Product__c).Product_Level_3__c));
            }
        }
        
        update mapObjects.values();
        */

        // 07-SEP-2022  ARA    SP-03707
        List<ProductItem__c> lstCtrPI = [SELECT Id, Contract__c, Contract__r.Product_Level_3__c, Product__c FROM ProductItem__c WHERE Product__c IN :mapProductLevel3.keySet()];
        if(lstCtrPI.size() > 0){
            ProductItemTriggerHandler handler = new ProductItemTriggerHandler();
            handler.updateContractProductLevel3(lstCtrPI);
        }

        List<Opp_ProductItem__c> lstOppPI = [SELECT Id, Opportunity__c, Opportunity__r.Product_Level_3__c, Product__c FROM Opp_ProductItem__c WHERE Product__c IN :mapProductLevel3.keySet()];
        if(lstOppPI.size() > 0){
            OppProductItemTriggerHandler handler = new OppProductItemTriggerHandler();
            handler.updateOppoProductLevel3(lstOppPI);
        }
    }
}