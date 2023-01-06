public without sharing class OpportunityHandler {
    /*Modification Log :
    -----------------------------------------------------------------------------
    * Developer                 Date          Description
    * ----------                ----------    -------------------------
    * Urvashi Sadasing          08/06/2017    ALLINFIN-493 Opportunity :suivi du flux chatter des opportunités
    * Shagoofah Golamgous       02/09/2019    Modification: handleAfterInsert method
    * Anthony Rakotondrabe		31/08/2020	  Code optimization (SP-00321)
    -- 07/07/2021  ARA     1.1     SP-01432     Allow change product and not blocked on look up filter field
    *************************************************************************************/

    // Record Type IDs of opportunity object
    static map<String, Schema.RecordTypeInfo>  mapRecTypeInfo = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName();
    public static Id idRecOppFullEdit                         = mapRecTypeInfo.get(AP_Constant.RT_OPP_LIGHTNING_FULL).getRecordTypeId();
    public static Id idRecOppFullReadonly                     = mapRecTypeInfo.get(AP_Constant.RT_OPP_LIGHTNING_FULL_RO).getRecordTypeId();
    public static Id idRecOppSingleEdit                       = mapRecTypeInfo.get(AP_Constant.RT_OPP_LIGHTNING_SINGLE).getRecordTypeId();
    public static Id idRecOppSingleReadOnly                   = mapRecTypeInfo.get(AP_Constant.RT_OPP_LIGHTNING_SINGLE_RO).getRecordTypeId();

    public static set<Id> setOppRecTypesOpCo                  = new set<Id>{idRecOppFullEdit, idRecOppFullReadonly,idRecOppSingleEdit,idRecOppSingleReadOnly};
    public static set<Id> setOppRecTypesOpCoEdit              = new set<Id>{idRecOppFullEdit, idRecOppSingleEdit};

    public static void handleBeforeInsert(List<Opportunity> lstOpportunity){
        User currUser = [SELECT Name, Company__c FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
		Set<String> setOppPickListValues = AP_Constant.getPickListValuesIntoListOpp();

		for (Opportunity opp : lstOpportunity) {
			// Verify the stage
			if (!AP_Constant.STAGE_LEADS_GATHERING.equals(opp.StageName)) {
				opp.StageName.addError(System.Label.Opty_Err_Status_Creation);
			}

			// Add the user assinged to
			opp.Assigned_to__c = opp.OwnerId;

			//SRA 22082019 Prefill Opp AXA GO Entity field with user connected company
			String oppRecordType = Schema.SObjectType.Opportunity.getRecordTypeInfosById().get(opp.recordtypeid).getDeveloperName();
			if(oppRecordType.contains('360')) {
				if(currUser.Company__c != null && setOppPickListValues.contains(currUser.Company__c) && (opp.AXA_GO_Entity__c == null)) {
					opp.AXA_GO_Entity__c = currUser.Company__c;
				}
				else if (opp.AXA_GO_Entity__c == null) {
					opp.addError('Cannot find picklist value');
				}
			}
		}
    }

    public static void handleBeforeUpdate(Map<Id, Opportunity> mapOldOpp, Map<Id, Opportunity> mapNewOpp){
        // Retrieve opportunity to retrieve necessary fields
        map<Id,Opportunity> mapOppProj        = new map<Id,Opportunity>();
        map<Id,Opportunity> mapOppStageChange = new map<Id,Opportunity>();
        Set<Id> setOppLostCancel              = new Set<Id>();
        map<Id,Opportunity> mapOppToCreateCtr = new map<Id,Opportunity>();

        Map<Id, Opportunity> mapOppRetrieved = new Map<Id, Opportunity>(
            [SELECT Id,Account.Account_Manager__c, Account.Account_Manager__r.Email, LastModifiedById, StageName, Product__c, Product__r.Name, Product__r.Product_owner__r.Email, 
                    Product__r.Product_owner__c, recordTypeId, Category__c
             FROM Opportunity
             WHERE Id IN :mapNewOpp.keySet()]);

        for (Opportunity opp : mapOppRetrieved.values()){
            system.debug('#USA OPP# retrieved : ' + opp.StageName);
        }
        for (Opportunity opp : mapOldOpp.values()){
            system.debug('#USA OPP# old : ' + opp.StageName);
        }
        for (Opportunity opp : mapNewOpp.values()){
            system.debug('#USA OPP# new : ' + opp.StageName);
        }

        for (Opportunity opp : mapNewOpp.values()){
            if (PAD.canTrigger('AP03')){
                if (opp.StageName != mapOldOpp.get(opp.Id).StageName){
                    mapOppStageChange.put(opp.Id, opp);
                }
                // In Record Type "Opportunity & Contract" and 'Project' category, some documents can be mandatory (and no document for Oppty Only process)
                if ((setOppRecTypesOpCoEdit.contains(opp.recordTypeId)) && Label.OptyCategory_Project.equals(opp.Category__c)) {
                    mapOppProj.put(opp.Id, opp);
                }
            }
            if(PAD.canTrigger('AP19')){
                if((opp.StageName == 'Opportunity Lost') || (opp.StageName == 'Opportunity Cancelled')){
                    setOppLostCancel.add(opp.Id);
                }
            }

            // 07-07-2021 SP-01432
            if(opp.CountProductItems__c != mapOldOpp.get(opp.Id).CountProductItems__c || opp.Tech_CountInactiveProductItems__c != mapOldOpp.get(opp.Id).Tech_CountInactiveProductItems__c){
                opp.Tech_ByPassFilter__c = true;
            }else{
                opp.Tech_ByPassFilter__c = false;
            }
        }

        if (mapOppStageChange.size()>0){
            AP03_Opportunities.changeLastStage(mapOppStageChange, mapOldOpp);
        }
        // check all document required
        if (mapOppProj.size()>0){
            AP03_Opportunities.checkAllDocumentRequired(mapOldOpp, mapOppProj);
        }
        if (setOppLostCancel.size()>0){
            AP19_OpptiesUnfollow.unfollowOpportunities(setOppLostCancel);
        }
    }

    public static void handleAfterUpdate(Map<Id, Opportunity> mapOldOpp, Map<Id, Opportunity> mapNewOpp){
        Map<Id,List<Set<Id>>> mapOppFollowers = new map<Id,List<Set<Id>>>();
        //map<id,id> oppIdOfferIdMap            = new map<id,id>();
        map<Id,Opportunity> mapOppToCreateCtr = new map<Id,Opportunity>();

        /*Map<Id, Opportunity> vOptyRetrievedMap = new Map<Id, Opportunity>(
        [SELECT Id, Name, Product__c, Product__r.Id,
                Account.Account_Manager__c, Account.Account_Manager__r.IsActive, Assigned_to__c, Assigned_to__r.IsActive,
                OwnerId, Owner.IsActive, TECH_AccManagerId__c, StageName, TECH_ProdOwnerId__c, Go_live_date__c,
                Tech_RecordTypeName__c, recordTypeId
         FROM Opportunity
         WHERE Id IN :mapNewOpp.keySet()]);

        for (Opportunity opp : vOptyRetrievedMap.values()){*/
        for (Opportunity opp : mapNewOpp.values()){
            Set<Id> setNewFollowers = new Set<Id>();
            Set<Id> setOldFollowers = new Set<Id>();

            if (PAD.canTrigger('AP01')) {
                if ((opp.StageName !='Opportunity Lost') && (opp.StageName != 'Opportunity Cancelled')){
                    if (opp.Assigned_to__c != NULL){
                        setNewFollowers.add(opp.Assigned_to__c);
                    }
                    if (opp.TECH_AccManagerId__c != NULL){
                        setNewFollowers.add(opp.TECH_AccManagerId__c);
                    }
                    if (mapOldOpp.get(opp.Id).Assigned_to__c != NULL){
                        setOldFollowers.add(mapOldOpp.get(opp.Id).Assigned_to__c);
                    }
                    if (mapOldOpp.get(opp.Id).TECH_AccManagerId__c != NULL){
                        setOldFollowers.add(mapOldOpp.get(opp.Id).TECH_AccManagerId__c);
                    }
                    mapOppFollowers.put(opp.Id, new List<Set<Id>>{setOldFollowers, setNewFollowers});
                }
            }

            //USA: 09/08/2017 ALLINFIN-513
            /*if (PAD.canTrigger('AP17')) {
                if (opp.StageName != AP_Constant.STAGE_COLLECT && opp.Product__c != NULL
                        && (opp.StageName != mapOldOpp.get(opp.Id).StageName  || opp.Go_live_date__c != mapOldOpp.get(opp.Id).Go_live_date__c )
                        && opp.Tech_RecordTypeName__c==AP_Constant.RT_OPP_LIGHTNING_FULL && opp.Tech_RecordTypeName__c==AP_Constant.RT_OPP_LIGHTNING_SINGLE
                        ){
                    setProdId.add(opp.Product__c);
                    setAccId.add(opp.AccountId);
                    mapOppFilteredERO.put(opp.AccountId + '-' + opp.Product__c, opp);
                    System.debug('##SGO## mapOppFilteredERO ' + mapOppFilteredERO);

                }
            }*/

            //USA : 28/05/2019 Migration Lightning - Process Opportunités / Contrats (cf Evols Contrats) - create product item
            /*if(PAD.canTrigger('AP50')){
                if((opp.Offer__c != null) && (opp.Offer__c != mapOldOpp.get(opp.Id).Offer__c) && (setOppRecTypesOpCoEdit.contains(opp.recordTypeId))){
                    oppIdOfferIdMap.put(opp.id,opp.Offer__c);
                }
            }*/

            //USA : 28/05/2019 Migration Lightning - Process Opportunités / Contrats (cf Evols Contrats) - create contract
            if (PAD.canTrigger('AP28')){
                if ((opp.StageName != mapOldOpp.get(opp.Id).StageName) &&
                        (opp.StageName == AP_Constant.STAGE_CONTRACTING) &&
                        (opp.Tech_RecordTypeName__c == AP_Constant.RT_OPP_LIGHTNING_FULL)){
                    mapOppToCreateCtr.put(opp.Id, opp);
                }
            }
        }

        /*if(PAD.canTrigger('AP50') && oppIdOfferIdMap.size()>0){
            AP50_GenerateProductItem.createOppProductItem(oppIdOfferIdMap);
        }*/

        if (mapOppFollowers != null && !mapOppFollowers.isEmpty() && (PAD.canTrigger('AP01'))) {
            AP01_Opportunities.addAllFollowersUPDATE(mapOppFollowers);
        }

        /*if (PAD.canTrigger('AP17')) {
            if (mapOppFilteredERO.size() > 0){
                AP17_EROCreatedFromOpportunity.createUpdateERO(mapOppFilteredERO, setAccId, setProdId);
            }
        }*/
        if (PAD.canTrigger('AP28') && mapOppToCreateCtr.size()>0){
            System.debug('##AP28## mapOppToCreateCtr: ' + mapOppToCreateCtr);
            AP28_CreateCtrfromOpp.createCtrfromOpp(mapOppToCreateCtr);
        }
    }

    public static void handleAfterInsert(Map<Id, Opportunity> mapOpp){
        Map<Id, Opportunity> mapOppFiltered = new map<Id, Opportunity>();
        Map<Id, Id> oppIdOfferIdMap = new map<Id, Id>();
        
        for (Opportunity opp : mapOpp.values()){
            if ((opp.Assigned_to__c != NULL || opp.TECH_AccManagerId__c != NULL || opp.Owner != NULL) &&
                    (opp.StageName != 'Opportunity Lost') && (opp.StageName != 'Opportunity Cancelled')) {
                mapOppFiltered.put(opp.Id, opp);
            }

            //USA: 09/08/2017 ALLINFIN-513
            /*if (PAD.canTrigger('AP17')) {
                if (opp.StageName != AP_Constant.STAGE_COLLECT && opp.Product__c != NULL
                        && opp.RecordTypeId != IDOppRecTypeSingle && opp.RecordTypeId != IDOppRecTypeFull){
                    setProdId.add(opp.Product__c);
                    setAccId.add(opp.AccountId);
                    mapOppFilteredERO.put(opp.AccountId + '-' + opp.Product__c, opp);
                }
            }*/

            //USA : 28/05/2019 Migration Lightning - Process Opportunités / Contrats (cf Evols Contrats)
            /*if(PAD.canTrigger('AP50')){
                if(opp.Offer__c != null &&
                        (opp.Tech_RecordTypeName__c == AP_Constant.RT_OPP_LIGHTNING_FULL ||
                                opp.Tech_RecordTypeName__c == AP_Constant.RT_OPP_LIGHTNING_SINGLE) &&
                        !(opp.isClone())){
                    oppIdOfferIdMap.put(opp.id,opp.Offer__c);
                }
            }*/
        } //end for loop

        //SGO - 2019/09/02 - Condition placed outside loop
        /*if(PAD.canTrigger('AP50') && oppIdOfferIdMap.size()>0)  {
            System.debug('@@ after-insert-Triggering AP50_GenerateProductItem.createOppProductItem '+ oppIdOfferIdMap);
            AP50_GenerateProductItem.createOppProductItem(oppIdOfferIdMap);
        }*/

        // Create new followers
        if (mapOppFiltered != null && !mapOppFiltered.isEmpty() && PAD.canTrigger('AP01')) {
            AP01_Opportunities.addAllFollowersNEW(mapOppFiltered);
        }

        /*if (PAD.canTrigger('AP17')) {
            if (mapOppFilteredERO.size() > 0){
                AP17_EROCreatedFromOpportunity.createUpdateERO(mapOppFilteredERO, setAccId, setProdId);
            }
        }*/
    }
}