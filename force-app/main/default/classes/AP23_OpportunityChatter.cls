/**
 * <b>Class AP23_OpportunityChatter </b>: class to update chatter subscriptions on product owner updates on opportunities
 * @author Urvashi Sadasing, ...
 * @version 0.1
 */
public without sharing class AP23_OpportunityChatter {

    public static void updateEntitySubscritptions(Map<Id, Id> mapProdOwnerChanges, Map<Id, Product__c> mapNewProd){

        // get IDs of opportunities related to the products updated
        Map<Id, Opportunity> mapOpp = new Map<Id, Opportunity> ([ SELECT id, Product__r.Product_Owner__r.Id, OwnerId, Product__c, Assigned_to__c, TECH_AccManagerId__c
                                                                  FROM Opportunity
                                                                  WHERE Product__r.Product_Owner__r.Id = :mapProdOwnerChanges.keyset()
                                                                  AND Product__c in :mapNewProd.keyset()
                                                                  AND StageName !='Opportunity Lost' AND StageName !='Opportunity Cancelled'
                                                                  LIMIT 1000]);

        Map<Id, Set<Id>> mapEntSubsFollowers = new map<Id, Set<Id>>();
        Map<String, EntitySubscription> mapSubs= new map<String, EntitySubscription>();

        for (EntitySubscription subs: [SELECT id, ParentId, SubscriberId
                                        FROM EntitySubscription
                                        WHERE ParentId in :mapOpp.keyset()
                                        LIMIT 1000]){
            if (mapEntSubsFollowers.containsKey(subs.ParentId)){
                mapEntSubsFollowers.get(subs.ParentId).add(subs.SubscriberId) ;
            }
            else{
                Set<Id> setCurrentNew = new Set<Id>();
                setCurrentNew.add(subs.SubscriberId);
                mapEntSubsFollowers.put(subs.ParentId, setCurrentNew);
            }
            mapSubs.put(subs.ParentId + '-' + subs.SubscriberId, subs);
        }

        List<EntitySubscription> lstCreateFollowers = new List<EntitySubscription>();
        List<EntitySubscription> lstDeleteFollowers = new List<EntitySubscription>();

        for (Id oppId : mapOpp.keySet()){
            if (
                //(mapOpp.get(oppId).Product__r.Product_Owner__r.Id == mapOpp.get(oppId).OwnerId) ||
                (mapOpp.get(oppId).Product__r.Product_Owner__r.Id == mapOpp.get(oppId).Assigned_to__c) ||
                (mapOpp.get(oppId).Product__r.Product_Owner__r.Id == mapOpp.get(oppId).TECH_AccManagerId__c)){
                //follower exist for other fields, do nothing
                if (mapSubs.containsKey(oppId + '-' + mapOpp.get(oppId).Product__r.Product_Owner__r.Id)){
                    system.debug('#### new user exist, do not create');
                }
                else{
                    lstCreateFollowers.add(new EntitySubscription(ParentId= oppId, SubscriberId = mapOpp.get(oppId).Product__r.Product_Owner__r.Id));
                }
            }
            //new product owner not equal to another follower field
            else{
                if (mapSubs.containsKey(oppId + '-' + mapOpp.get(oppId).Product__r.Product_Owner__r.Id)){
                    system.debug('#### new user exist, do not create');
                }
                else{
                    lstCreateFollowers.add(new EntitySubscription(ParentId= oppId, SubscriberId = mapOpp.get(oppId).Product__r.Product_Owner__r.Id));
                }
            }


            if (mapProdOwnerChanges.containsKey(mapOpp.get(oppId).Product__r.Product_Owner__r.Id)){
                if (
                    //(mapProdOwnerChanges.get(mapOpp.get(oppId).Product__r.Product_Owner__r.Id) == mapOpp.get(oppId).OwnerId) ||
                    (mapProdOwnerChanges.get(mapOpp.get(oppId).Product__r.Product_Owner__r.Id) == mapOpp.get(oppId).Assigned_to__c) ||
                    ((mapProdOwnerChanges.get(mapOpp.get(oppId).Product__r.Product_Owner__r.Id) == mapOpp.get(oppId).TECH_AccManagerId__c))){
                    //follower exist for other fields, do nothing
                    if (mapSubs.containsKey(oppId+ '-' + mapProdOwnerChanges.get(mapOpp.get(oppId).Product__r.Product_Owner__r.Id))){
                        system.debug('#### old user exist for other records, do not delete');
                    }
                }
                //old product owner not equal to another follower field
                else{
                    if (mapSubs.containsKey(oppId+ '-' + mapProdOwnerChanges.get(mapOpp.get(oppId).Product__r.Product_Owner__r.Id))){
                        lstDeleteFollowers.add(mapSubs.get(oppId + '-' + mapProdOwnerChanges.get(mapOpp.get(oppId).Product__r.Product_Owner__r.Id)));
                    }
                }
            }
        }

        if (lstDeleteFollowers.size()>0){
            delete lstDeleteFollowers;
        }
        if (lstCreateFollowers.size()>0){
            insert lstCreateFollowers;
        }
    }
}