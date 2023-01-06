/**
 * <b>Class ProductEntityLinkTriggerHandler </b>: that class contains static method call by the ProductEntityLink trigger
 * @author Urvashi Sadasing
 * @version 0.1
 */
public without sharing class ProductEntityLinkTriggerHandler {
	public ProductEntityLinkTriggerHandler() {

	}

    public static void handleBeforeInsert(List<ProductEntityLink__c> lstNew){
        Set<String> setOffer = new Set<String>();
        Set<Id> setERO = new Set<Id>();
        Map<String, List<ProductEntityLink__c>> mapOfferEroNew = new map<String, List<ProductEntityLink__c>>();

        for (ProductEntityLink__c prodEnt : lstNew){
            if(prodEnt.offer_txt__c != ''){
                setOffer.add(prodEnt.offer_txt__c);
            }
            setERO.add(prodEnt.Id);
            if (!mapOfferEroNew.containsKey(prodEnt.offer_txt__c)){
                mapOfferEroNew.put(prodEnt.offer_txt__c, new List<ProductEntityLink__c>{prodEnt});
            }
            else{
                mapOfferEroNew.get(prodEnt.offer_txt__c).add(prodEnt);
            }
        }
        AP26_EROUpdatePrincipal.updatePrincipalERO(mapOfferEroNew, setOffer, setERO);
    }

    public static void handleBeforeUpdate(map<Id,ProductEntityLink__c> mapERONew, map<Id,ProductEntityLink__c> mapEROOld){
        Map<String,Integer> mapStatusOrder = AP_Constant.getOrderStatus();

        Set<String> setOffer = new Set<String>();
        Set<Id> setERO = new Set<Id>();
        Map<String, List<ProductEntityLink__c>> mapOfferEroNew = new map<String,List<ProductEntityLink__c>>();

        for (Id eroId :mapERONew.keySet()){
            if (mapERONew.get(eroId).POS_Status__c != mapEROOld.get(eroId).POS_Status__c){
                if(mapERONew.get(eroId).offer_txt__c != ''){
                    setOffer.add(mapERONew.get(eroId).offer_txt__c);
                }
                setERO.add(eroId);

                if (!mapOfferEroNew.containsKey(mapERONew.get(eroId).offer_txt__c)){
                mapOfferEroNew.put(mapERONew.get(eroId).offer_txt__c, new List<ProductEntityLink__c>{mapERONew.get(eroId)});
                }
                else{
                    mapOfferEroNew.get(mapERONew.get(eroId).offer_txt__c).add(mapERONew.get(eroId));
                }
            }
        }
        AP26_EROUpdatePrincipal.updatePrincipalERO(mapOfferEroNew, setOffer, setERO);
    }

    public static void handleAfterInsert(map<Id, ProductEntityLink__c> mapERONew){
        Set<Id> setProd = new Set<Id>();
        map<String, ProductEntityLink__c> mapERO = new map<String, ProductEntityLink__c>();
        map<Id, Id> mapEntMasterEnt = new map<Id,Id>();
        Id idRecERO = Schema.SObjectType.ProductEntityLink__c.getRecordTypeInfosByName().get(AP_Constant.strERORecType).getRecordTypeId();

        system.debug('***mapERONew '+mapERONew.size());
        for (ProductEntityLink__c ero : [SELECT id, entity__c, entity__r.parentId
                        FROM ProductEntityLink__c
                        WHERE id in :mapERONew.keySet()
                        AND entity__r.parent.Active__c = TRUE]){
            mapEntMasterEnt.put(ero.entity__c, ero.entity__r.parentId);
        }
        system.debug('***mapEntMasterEnt '+mapEntMasterEnt.size());

        for (ProductEntityLink__c pEnt :[SELECT id, name, entity__c, entity__r.parentId, RecordTypeId, First_Release_Date__c, POS_Status__c, Product__c, Offer_txt__c,TECH_Anti_Duplicate_Value__c
                                        FROM ProductEntityLink__c
                                        WHERE id in :mapERONew.keySet()]){
            if (pEnt.recordTypeId == idRecERO && mapEntMasterEnt.containsKey(pEnt.entity__c)){
                setProd.add(pEnt.product__c);
                mapERO.put(mapEntMasterEnt.get(pEnt.entity__c) + '-' + pEnt.offer_txt__c + '-' + pEnt.product__c,pEnt);
            }
        }
        system.debug('***mapERO '+mapERO.size());

        //for (ProductEntityLink__c pEnt :mapERONew.values()){
        //    if (pEnt.recordTypeId == idRecERO && mapEntMasterEnt.containsKey(pEnt.entity__c)){
        //        setProd.add(pEnt.product__c);
        //        mapERO.put(mapEntMasterEnt.get(pEnt.entity__c) + '-' + pEnt.offer__c + '-' + pEnt.product__c,pEnt);
        //    }
        //}

        if (mapERO.size() > 0){
            AP27_CreateUpdateMERO.createUpdateMero(mapERO, setProd, mapEntMasterEnt);
        }
    }

    public static void handleAfterUpdate(map<Id, ProductEntityLink__c> mapERONew,map<Id, ProductEntityLink__c> mapEROOld){
        Set<Id> setProd = new Set<Id>();
        map<String, ProductEntityLink__c> mapERO = new map<String, ProductEntityLink__c>();
        map<Id, Id> mapEntMasterEnt = new map<Id,Id>();
        Id idRecERO = Schema.SObjectType.ProductEntityLink__c.getRecordTypeInfosByName().get(AP_Constant.strERORecType).getRecordTypeId();

        for (ProductEntityLink__c ero : [SELECT id, entity__c, entity__r.parentId, Offer_txt__c
                        FROM ProductEntityLink__c
                        WHERE id in :mapERONew.keySet()]){
            mapEntMasterEnt.put(ero.entity__c, ero.entity__r.parentId);
        }

        for (ProductEntityLink__c pEnt :[SELECT id, name, entity__c, entity__r.parentId, RecordTypeId, First_Release_Date__c, POS_Status__c, Product__c, Offer_txt__c,TECH_Anti_Duplicate_Value__c
                                        FROM ProductEntityLink__c
                                        WHERE id in :mapERONew.keySet()]){
            if (pEnt.recordTypeId == idRecERO && ((pEnt.POS_Status__c != mapEROOld.get(pEnt.Id).POS_Status__c)
                // ALLINFIN-513 : USA 20170814
                ||(pEnt.First_Release_Date__c != mapEROOld.get(pEnt.Id).First_Release_Date__c))){
                setProd.add(pEnt.product__c);
                mapERO.put(mapEntMasterEnt.get(pEnt.entity__c) + '-' + pEnt.offer_txt__c + '-' + pEnt.product__c,pEnt);
            }
        }

        //for (ProductEntityLink__c pEnt :mapERONew.values()){
        //    if (pEnt.recordTypeId == idRecERO && pEnt.POS_Status__c != mapEROOld.get(pEnt.Id).POS_Status__c){
        //        setProd.add(pEnt.product__c);
        //        mapERO.put(mapEntMasterEnt.get(pEnt.entity__c) + '-' + pEnt.offer__c + '-' + pEnt.product__c,pEnt);
        //    }
        //}
        system.debug('##handleAfterUpdate## mapERO: ' + mapERO);
        if (mapERO.size() > 0){
            AP27_CreateUpdateMERO.createUpdateMero(mapERO, setProd, mapEntMasterEnt);
        }
    }
}