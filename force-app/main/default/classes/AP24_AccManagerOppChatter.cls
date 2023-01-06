/**
 * <b>Class v </b>: class to update chatter subscriptions on entity manager updates on opportunities
 * @author Urvashi Sadasing, ...
 * @version 0.1
 */

public without sharing class AP24_AccManagerOppChatter {

    public static void updateEntitySubscritptions(Map<Id, Id> mapAccManagerChanges, Map<Id, Account> mapNewAcc){
        System.debug('Starting method AP24_AccManagerOppChatter.updateEntitySubscritptions');
        // get IDs of opportunities related to the products updated
        Map<Id, Opportunity> mapOpp = new Map<Id, Opportunity> ([ SELECT id, Product__r.Product_Owner__r.Id, OwnerId, Product__c, Assigned_to__c, Account.Account_Manager__c
                                                                  FROM Opportunity
                                                                  WHERE Account.Account_Manager__c IN :mapAccManagerChanges.keyset()
                                                                  AND accountId IN :mapNewAcc.keyset()
                                                                  AND StageName IN ('Collect','Qualify/Align')
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
                //(mapOpp.get(oppId).Account.Account_Manager__c == mapOpp.get(oppId).OwnerId) ||
                (mapOpp.get(oppId).Account.Account_Manager__c == mapOpp.get(oppId).Assigned_to__c) ||
                (mapOpp.get(oppId).Account.Account_Manager__c == mapOpp.get(oppId).Product__r.Product_Owner__r.Id)){
                //follower exist for other fields, do nothing
                if (mapSubs.containsKey(oppId + '-' + mapOpp.get(oppId).Account.Account_Manager__c)){
                    system.debug('#### new user exist, do not create');
                }
                else{
                    lstCreateFollowers.add(new EntitySubscription(ParentId= oppId, SubscriberId = mapOpp.get(oppId).Account.Account_Manager__c));
                }
            }
            //new product owner not equal to another follower field
            else{
                if (mapSubs.containsKey(oppId + '-' + mapOpp.get(oppId).Account.Account_Manager__c)){
                    system.debug('#### new user exist, do not create');
                }
                else{
                    lstCreateFollowers.add(new EntitySubscription(ParentId= oppId, SubscriberId = mapOpp.get(oppId).Account.Account_Manager__c));
                }
            }


            if (mapAccManagerChanges.containsKey(mapOpp.get(oppId).Account.Account_Manager__c)){
                if (
                    //(mapAccManagerChanges.get(mapOpp.get(oppId).Account.Account_Manager__c) == mapOpp.get(oppId).OwnerId) ||
                    (mapAccManagerChanges.get(mapOpp.get(oppId).Account.Account_Manager__c) == mapOpp.get(oppId).Assigned_to__c) ||
                    ((mapAccManagerChanges.get(mapOpp.get(oppId).Account.Account_Manager__c) == mapOpp.get(oppId).Product__r.Product_Owner__r.Id))){
                    //follower exist for other fields, do nothing
                    if (mapSubs.containsKey(oppId+ '-' + mapAccManagerChanges.get(mapOpp.get(oppId).Account.Account_Manager__c))){
                        system.debug('#### old user exist for other records, do not delete');
                    }
                }
                //old product owner not equal to another follower field
                else{
                    if (mapSubs.containsKey(oppId+ '-' + mapAccManagerChanges.get(mapOpp.get(oppId).Account.Account_Manager__c))){
                        lstDeleteFollowers.add(mapSubs.get(oppId + '-' + mapAccManagerChanges.get(mapOpp.get(oppId).Account.Account_Manager__c)));
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