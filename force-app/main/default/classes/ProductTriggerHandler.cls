/**
 * <b>Class ProductTriggerHandler </b>: that class contains static method call by the product trigger
 * @author Urvashi Sadasing, ...
 * @version 0.1
 */
public class ProductTriggerHandler
{
    public static void handleAfterUpdate(Map<Id, Product__c> mapOldProd, Map<Id, Product__c> mapNewProd){
        //map of product owner changes => Key: new owner; value: old owner
        Map<Id, Id> mapProdOwnerChanges = new Map<Id, Id>();
        Map<Id, Product__c> mapProduct = new Map<Id, Product__c>();
        Map<Id, Product__c> mapProductLevel3 = new Map<Id, Product__c>();
        for (Id prodId : mapOldProd.keyset()){
            if (mapOldProd.get(prodId).Product_owner__c != mapNewProd.get(prodId).Product_owner__c){
                mapProdOwnerChanges.put(mapNewProd.get(prodId).Product_owner__c, mapOldProd.get(prodId).Product_owner__c);
            }
            if (mapOldProd.get(prodId).Status__c != mapNewProd.get(prodId).Status__c || mapOldProd.get(prodId).Product_description__c != mapNewProd.get(prodId).Product_description__c){
                mapProduct.put(prodId, mapNewProd.get(prodId));
            }
            
            if (mapOldProd.get(prodId).Product_Level_3__c != mapNewProd.get(prodId).Product_Level_3__c){
                mapProductLevel3.put(prodId, mapNewProd.get(prodId));
            }
        }

        AP23_OpportunityChatter.updateEntitySubscritptions(mapProdOwnerChanges, mapNewProd);

        if(mapProduct.size()>0){
            AP61_Product.updateProductItems(mapProduct);
        }
        if(mapProductLevel3.size()>0){
            AP61_Product.updateContractAndOpportunity(mapProductLevel3);
        }
    }
}