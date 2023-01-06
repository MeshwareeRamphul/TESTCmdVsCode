public with sharing class AP26_EROUpdatePrincipal {

    public static void updatePrincipalERO(Map<String, List<ProductEntityLink__c>> mapERONew, set<String> setOffer, set<Id> setERO){
        Map<String,Integer> mapStatusOrder = AP_Constant.getOrderStatus();

        Map<String, ProductEntityLink__c> mapOfferEROExisting = new Map<String, ProductEntityLink__c>();
        Map<String, ProductEntityLink__c> mapOfferEROHighest = new Map<String, ProductEntityLink__c>();

        for (ProductEntityLink__c prodEnt :[SELECT Id, name, Offer_txt__c,Principal__c, POS_Status__c, RecordTypeId, First_Release_Date__c
                                            FROM ProductEntityLink__c
                                            WHERE Offer_txt__c in :setOffer
                                            AND Principal__c = TRUE
                                            AND id not in :setERO]){mapOfferEROExisting.put(prodEnt.Offer_txt__c + '-' + prodEnt.RecordTypeId, prodEnt); mapOfferEROHighest.put(prodEnt.Offer_txt__c + '-' + prodEnt.RecordTypeId, prodEnt);
        }

        for (String Offer :mapERONew.keySet()){
            for (ProductEntityLink__c ero : mapERONew.get(Offer)){
                if (mapOfferEROHighest.containsKey(ero.Offer_txt__c + '-' + ero.RecordTypeId)){
                    if (mapStatusOrder.get(ero.POS_Status__c) > mapStatusOrder.get(mapOfferEROHighest.get(ero.Offer_txt__c + '-' + ero.RecordTypeId).POS_Status__c)){ero.Principal__c = true;mapOfferEROHighest.get(ero.Offer_txt__c + '-' + ero.RecordTypeId).Principal__c = false; // by reference corresponding record in mapExisting is updatedmapOfferEROHighest.put(ero.Offer_txt__c + '-' + ero.RecordTypeId, ero);
                    }
                    else if (mapStatusOrder.get(ero.POS_Status__c) == mapStatusOrder.get(mapOfferEROHighest.get(ero.Offer_txt__c + '-' + ero.RecordTypeId).POS_Status__c)){if (ero.First_Release_Date__c < mapOfferEROHighest.get(ero.Offer_txt__c + '-' + ero.RecordTypeId).First_Release_Date__c){ero.Principal__c = true;mapOfferEROHighest.get(ero.Offer_txt__c + '-' + ero.RecordTypeId).Principal__c = false; // by reference corresponding record in mapExisting is updatedmapOfferEROHighest.put(ero.Offer_txt__c + '-' + ero.RecordTypeId, ero);
                        }
                    }
                }
                else{
                    ero.Principal__c = true;
                }
            }
        }
        update mapOfferEROExisting.values();
    }
}