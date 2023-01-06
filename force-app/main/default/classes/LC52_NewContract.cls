public class LC52_NewContract {
    
	@AuraEnabled
    public static Map<String,String> getRecordType(String recordTypeId){
        Map<String,String> mapResult = new Map<String,String>();
        Boolean isContractInUser;
        String strRecTypeId = '';
        integer countAssignedPs;
        set<id> contractInProfSet=new set<id>();
        List<String> LstAllProfiles = System.Label.cTin_AllProfiles.split(';');
        
        for(Profile prof:[SELECT id
                          FROM profile
                          WHERE name IN :LstAllProfiles]){
            contractInProfSet.add(prof.id);
        }
        strRecTypeId = recordTypeId;
        
        // SGO - 2019/09/19 - In case strRecTypeId is null
        if (strRecTypeId == null) {
            List<String> recordTypeNameList = new List<String>();
            Schema.DescribeSObjectResult describeCtr = Schema.SObjectType.Contract__c;
            List<Schema.RecordTypeInfo> rtInfos = describeCtr.getRecordTypeInfos();
            
            // ARA - 2020/06/02 - Used for all user's language
            for(Schema.RecordTypeInfo rtInfo : rtInfos) {
                if(!rtInfo.isMaster() && rtInfo.isAvailable()) {
                    strRecTypeId = rtInfo.getRecordTypeId();
                }
            }
        }
        
        isContractInUser = [SELECT cTin_Universign__c FROM User WHERE Id = :UserInfo.getUserId()][0].cTin_Universign__c;
        Map<String, RecordType>rtIdMap = AP_Constant.getRecordTypes('Contract__c');
        
        //MRA 10/09/2019 - Added check on profile 360 functional admin
        if(!isContractInUser &&
           (strRecTypeId == Schema.SObjectType.Contract__c.getRecordTypeInfosByName().get(AP_Constant.strContractLightRecType).getRecordTypeId() &&
            (AP_Constant.hasRights(AP_Constant.strProfPMOADV) || AP_Constant.hasRights(AP_Constant.functionalAdmin)) ) ||
           (strRecTypeId == Schema.SObjectType.Contract__c.getRecordTypeInfosByName().get('Contract Draft').getRecordTypeId() ||
            strRecTypeId == Schema.SObjectType.Contract__c.getRecordTypeInfosByName().get('Contract In Progress').getRecordTypeId() ||
            strRecTypeId == Schema.SObjectType.Contract__c.getRecordTypeInfosByName().get('Contract Read Only').getRecordTypeId()) ){
                mapResult.put('recordType', strRecTypeId);
        }
        // Contract-In users
        else if(isContractInUser && contractInProfSet.contains(UserInfo.getProfileId())){
            strRecTypeId = rtIdMap.get('cTin_Contract_Draft').id;
            mapResult.put('recordType', strRecTypeId);
        }
        
        // All-n --> If contract light + sys admin 
        else if (strRecTypeId == Schema.SObjectType.Contract__c.getRecordTypeInfosByName().get(AP_Constant.strContractLightRecType).getRecordTypeId()
                 //USA 20180905: commented condition to allow creation of light contrats for users with PS - Light Contract
                 //&& AP_Constant.hasRights(AP_Constant.strProfPMOADV)
                ){
                    mapResult.put('recordType', strRecTypeId);
                }
        // lightning contracts
        else if (strRecTypeId == Schema.SObjectType.Contract__c.getRecordTypeInfosByName().get(AP_Constant.RT_CONTRACT_EDIT_LIGHTNING_LABEL).getRecordTypeId()){
            mapResult.put('recordType', strRecTypeId);
        }
        //lightning amendments
        else if (strRecTypeId == Schema.SObjectType.Contract__c.getRecordTypeInfosByName().get(AP_Constant.RT_AMENDMENT_EDIT_LIGHTNING_LABEL).getRecordTypeId()){
            mapResult.put('recordType', strRecTypeId);
        }
        // all other contracts should create opportunity first
        else{
            mapResult.put('error', 'You have to create an opportunity.');
        }

        if(strRecTypeId != ''){
            mapResult.put('recordType', strRecTypeId);
        }
        return mapResult;
    }  
}