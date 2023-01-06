/**
 * <b>Class AP01_Opportunities </b>: that class contains static method call by the opportunity trigger
 * @author Eric Wartelle, ...
 * @version 0.1
 */
/*Modification Log :
-----------------------------------------------------------------------------
* Developer                 Date          Description
* ----------                ----------    -------------------------
* Urvashi Sadasing          08/06/2017    ALLINFIN-493 Opportunity :suivi du flux chatter des opportunités
* Anthony Rakotondrabe		31/08/2020	  Code optimization (SP-00321)
*************************************************************************************/
public without sharing class AP01_Opportunities {
    public static Set<Id> setExistingUser = new Set<Id>();

    /**
    * ----------------------------------------------------------------------------------------------
    * method to check if the user is already a follower
    * ----------------------------------------------------------------------------------------------
    * @param pEntitySubscriptionList Map<Id, EntitySubscription>  : map of subscriptions
    * @param pUserId Id : subscriber id
    * @param pParentId Id : parent (opportunity) Id
    * ----------------------------------------------------------------------------------------------
    */
    public static EntitySubscription getSubscriptionAlreadyExist(Map<Id, EntitySubscription> pEntitySubscriptionList, Id pUserId, Id pParentId) {
        for (EntitySubscription vEntitySub : pEntitySubscriptionList.values()) {
            if ((vEntitySub.subscriberId + '' == pUserId + '') && (vEntitySub.parentId + ''  == pParentId + '')) {
                return vEntitySub;
            }
        }
        return NULL;
    }

    // USA : 08/06/2017 : method to create new followers on creation of new opportunity
    public static void addAllFollowersNEW(map<Id, Opportunity> mapOpp){
        List<EntitySubscription> vEntitySubsList = new List<EntitySubscription>();
        Map<Id, Set<Id>> mapOppUserIds = new map<Id, Set<Id>>();
        // Get back the opportunities with the main products
        Map<Id, Opportunity> vOptyRetrievedMap = new Map<Id, Opportunity>(
        [SELECT Id, Account.Account_Manager__c, Account.Account_Manager__r.IsActive, Assigned_to__c, Assigned_to__r.IsActive,
                    OwnerId, Owner.IsActive, TECH_AccManagerId__c
                FROM Opportunity
                WHERE Id IN :mapOpp.keySet()]);

        for (Opportunity opp : vOptyRetrievedMap.values()){
            //1. Assigned to
            if (opp.Assigned_to__c != NULL && opp.Assigned_to__r.IsActive){
                if (!mapOppUserIds.containsKey(opp.Id)){
                    mapOppUserIds.put(opp.Id, new Set<Id>{opp.Assigned_to__c});
                }
                else{
                    mapOppUserIds.get(opp.Id).add(opp.Assigned_to__c);
                }
            }
            //2. Opp Owner
            if (opp.owner != NULL && opp.Owner.IsActive){
                if (!mapOppUserIds.containsKey(opp.Id)){
                    mapOppUserIds.put(opp.Id, new Set<Id>{opp.OwnerId});
                }
                else{
                    mapOppUserIds.get(opp.Id).add(opp.OwnerId);
                }
            }
            //3. Account Manager
            if (opp.account != NULL && opp.TECH_AccManagerId__c != NULL && opp.Account.Account_Manager__r.IsActive){
                if (!mapOppUserIds.containsKey(opp.Id)){
                    mapOppUserIds.put(opp.Id, new Set<Id>{opp.TECH_AccManagerId__c});
                }
                else{
                    mapOppUserIds.get(opp.Id).add(opp.TECH_AccManagerId__c);
                }
            }
        }
        if (mapOppUserIds != null && !mapOppUserIds.isEmpty()){
            addToSubscriptionToCreate(mapOppUserIds);
        }
    }

    public static void addToSubscriptionToCreate(Map<Id, Set<Id>> mapOppUsers) {
        List<EntitySubscription> LstEntitySubs = new List<EntitySubscription>();
        for (Id oppId : mapOppUsers.keySet()){
            for (Id userId :mapOppUsers.get(oppId)){
                LstEntitySubs.add(new EntitySubscription(parentId = oppId, subscriberId = userId));
            }
        }
        if (LstEntitySubs.size() > 0){
            insert LstEntitySubs;
        }
    }


    /**
    * ----------------------------------------------------------------------------------------------
    * method to update followers on creation of new opportunity
    * ----------------------------------------------------------------------------------------------
    * @param    mapCheckFollowers map<Id, List<Set<Id>>>    : map of Subscriptions with list of set of opportunity followers
    * ----------------------------------------------------------------------------------------------
    */
    public static void addAllFollowersUPDATE(map<Id, List<Set<Id>>> mapCheckFollowers){
        List<EntitySubscription> lstCreEntSubs             = new List<EntitySubscription>();
        List<EntitySubscription> lstDelEntSubs             = new List<EntitySubscription>();
        Set<EntitySubscription> setDelEntSubs              = new Set<EntitySubscription>();
        Set<EntitySubscription> setCreEntSubs              = new Set<EntitySubscription>();
        Map<Id, EntitySubscription> vExistingSubscriptions = new Map<Id, EntitySubscription>();

        for (EntitySubscription currentSubs:[SELECT ID, subscriberId, parentId 
                                             FROM EntitySubscription
                                             WHERE parentID IN :mapCheckFollowers.keySet()
                                             LIMIT 1000]){
            setExistingUser.add(currentSubs.subscriberId);
            vExistingSubscriptions.put(currentSubs.Id, currentSubs);
        }

        for (Id oppId :mapCheckFollowers.keySet()){
            EntitySubscriptionWrapper entSubs = new EntitySubscriptionWrapper(oppId, mapCheckFollowers.get(oppId)[0], mapCheckFollowers.get(oppId)[1], vExistingSubscriptions);

            if (entSubs.setFollowersDel.size() > 0){
                setDelEntSubs.addAll(entSubs.setFollowersDel);
            }
            if (entSubs.setFollowersCreate.size() > 0){
                setCreEntSubs.addAll(entSubs.setFollowersCreate);
            }
        }
        if (setDelEntSubs.size() > 0){
            for (EntitySubscription entSubsDel : setDelEntSubs){
                EntitySubscription entToDel = getSubscriptionAlreadyExist(vExistingSubscriptions, entSubsDel.subscriberId, entSubsDel.parentId);
                if (entToDel != NULL){
                    lstDelEntSubs.add(entToDel);
                }
            }
            if (lstDelEntSubs.size() > 0){
                delete lstDelEntSubs;
            }
        }

        if (setCreEntSubs.size() > 0 ){
            lstCreEntSubs.addAll(setCreEntSubs);
            insert lstCreEntSubs;
        }
    }

    public class EntitySubscriptionWrapper {
        Id IdOpp;
        Set<EntitySubscription> setFollowersDel;
        Set<EntitySubscription> setFollowersCreate;

        public EntitySubscriptionWrapper(Id oppId, Set<Id> setOldDetails, Set<Id> setNewDetails, map<Id,EntitySubscription> mapFollowers){
            IdOpp = oppId;
            setFollowersCreate = new Set<EntitySubscription>();
            setFollowersDel = new Set<EntitySubscription>();
            for (Id userIdNew :setNewDetails){
                if (!setOldDetails.contains(userIdNew) && (!setExistingUser.contains(userIdNew))) {
                    EntitySubscription test = new EntitySubscription(parentId = oppId, subscriberId = userIdNew) ;
                    setFollowersCreate.add(test);
                }
            }
            for (Id userIdOld :setOldDetails){
                if (!setNewDetails.contains(userIdOld)) {
                    setFollowersDel.add(new EntitySubscription(parentId = oppId, subscriberId = userIdOld));
                }
            }
        }
    }
}