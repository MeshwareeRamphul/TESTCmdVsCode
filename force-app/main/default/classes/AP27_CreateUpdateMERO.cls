/**
 * <b>Class v </b>: class to update create/update MEROs
 * @author Urvashi Sadasing, ...
 * @version 0.1
 */
public with sharing class AP27_CreateUpdateMERO {

    public static void createUpdateMero(Map<String, ProductEntityLink__c> mapEROs, Set<Id> setProd, Map<Id,Id> mapEntMasterEnt){
        system.debug('##AP27 >>START<< ');
        Map<String,Integer> mapStatusOrder = AP_Constant.getOrderStatus();
        Map<String, ProductEntityLink__c> mapMERO = new Map<String,ProductEntityLink__c>();
        Id idRecMERO = Schema.SObjectType.ProductEntityLink__c.getRecordTypeInfosByName().get(AP_Constant.strMERORecType).getRecordTypeId();
        list<ProductEntityLink__c> updatedEROList = new list<ProductEntityLink__c>();

        // get all existing MERO for related EROs (filter by entity, product and record type)
        for (ProductEntityLink__c mero:[SELECT id, name, RecordTypeId, First_Release_Date__c, POS_Status__c, Entity__c, Product__c, offer_txt__c, TECH_Anti_Duplicate_Value__c
                                        FROM ProductEntityLink__c
                                        WHERE recordTypeId = :idRecMERO
                                        AND Entity__c in :mapEntMasterEnt.values()
                                        AND Product__c in :setProd]){
            mapMERO.put(mero.Entity__c + '-' + mero.offer_txt__c + '-' + mero.Product__c, mero);

            System.debug(LoggingLevel.INFO, '##AP27 mero key' + mero.Entity__c + '-' + mero.offer_txt__c + '-' + mero.Product__c);
            //System.debug(LoggingLevel.INFO, '##AP27 mero ' + mero);

        }
       System.debug(LoggingLevel.INFO, '##AP27 mapMERO ' + mapMERO);

        for (String strEro :mapEROs.keySet()){
            //system.debug(LoggingLevel.INFO,'##AP27 mapEROs : ' + mapEROs.get(strEro));
            ProductEntityLink__c updatedERO;
            //build key for mapMERO
            String strMero = mapEROs.get(strEro).Entity__r.parentid + '-' + mapEROs.get(strEro).offer_txt__c + '-' + mapEROs.get(strEro).Product__c;
             // if MERO does not exist create
            if (!mapMERO.containsKey(strMero)){
                system.debug(LoggingLevel.INFO,'##AP27 if mero does not exist : ' + mapEROs.get(strEro));
                ProductEntityLink__c newMero = new ProductEntityLink__c(recordTypeId = idRecMERO,
                                                                        Entity__c = mapEntMasterEnt.get(mapEROs.get(strEro).Entity__c),
                                                                        Product__c = mapEROs.get(strEro).Product__c,
                                                                        /*offer_txt__c = mapEROs.get(strEro).offer_txt__c,*/
                                                                        First_Release_Date__c = mapEROs.get(strEro).First_Release_Date__c,
                                                                        POS_Status__c = mapEROs.get(strEro).POS_Status__c);
                mapMERO.put(mapEntMasterEnt.get(mapEROs.get(strEro).Entity__c) + '-' + mapEROs.get(strEro).offer_txt__c + '-' + mapEROs.get(strEro).Product__c, newMero);

                ProductEntityLink__c eroExternal = new ProductEntityLink__c(TECH_Anti_Duplicate_Value__c = setTECHAntiDuplicateValue((Id)newMero.Product__c, newMero.offer_txt__c, (Id)newMero.Entity__c));
                updatedERO = new ProductEntityLink__c(Id = mapEROs.get(strEro).Id, MasterEntityRolledOut__r = eroExternal);
            }
            //if MERO exists
            else{
                System.debug(LoggingLevel.INFO,'##AP27 else MERO exist, ero : ' + mapEROs.get(strEro));
                ProductEntityLink__c curMero = mapMERO.get(strMero);
                System.debug(LoggingLevel.INFO, '##AP27 else MERO exist, curMero : ' + curMero);

                // if status inferior update status
                if (mapStatusOrder.get(mapEROs.get(strEro).POS_Status__c) > mapStatusOrder.get(curMero.POS_Status__c)){ curMero.POS_Status__c = mapEROs.get(strEro).POS_Status__c;curMero.First_Release_Date__c = mapEROs.get(strEro).First_Release_Date__c;
                    //curMero.offer_txt__c = mapEROs.get(strEro).offer_txt__c;
                }
                //if go live date greater update go live date
                if ((mapStatusOrder.get(mapEROs.get(strEro).POS_Status__c) == mapStatusOrder.get(curMero.POS_Status__c))
                    // ALLINFIN-513 : USA 20170814
                    //&& ((mapEROs.get(strEro).POS_Status__c == AP_Constant.strPosStatus_Live)
                    //    || (mapEROs.get(strEro).POS_Status__c == AP_Constant.strPosStatus_NewLive))
                    ){
                    if ((curMero.First_Release_Date__c > mapEROs.get(strEro).First_Release_Date__c) || (curMero.First_Release_Date__c ==  null)){curMero.First_Release_Date__c = mapEROs.get(strEro).First_Release_Date__c;
                        //curMero.offer_txt__c = mapEROs.get(strEro).offer_txt__c;
                    }
                }
                ProductEntityLink__c eroExternal = new ProductEntityLink__c(TECH_Anti_Duplicate_Value__c = setTECHAntiDuplicateValue((Id)curMero.Product__c, (Id)curMero.offer_txt__c, (Id)curMero.Entity__c));
                    updatedERO = new ProductEntityLink__c(Id = mapEROs.get(strEro).Id, MasterEntityRolledOut__r = eroExternal);
                    //System.debug(LoggingLevel.INFO,'##AP27 else2 updatedERO : ' + updatedERO + '==' + eroExternal);
            }
            if(updatedERO != null){
                updatedEROList.add(updatedERO);
            }
        }
        
        if(mapMERO.size()> 0){
            upsert mapMERO.values();
        }
        // link ERO to corresponding MERO
        if(updatedEROList.size()> 0){
            update updatedEROList;
        }

        system.debug('##AP27 >>END<< ');
    }

    private static String setTECHAntiDuplicateValue(Id productId, String offer, Id accountId) {
        //system.debug(LoggingLevel.INFO,'##AP27 setTECHAntiDuplicateValue : ' + productId + ' - ' + offer + ' - ' + accountId) ;
        return productId + '_' + offer + '_' + accountId;
    }
}