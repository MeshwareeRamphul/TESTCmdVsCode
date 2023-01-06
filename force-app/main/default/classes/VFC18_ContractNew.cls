public without sharing class VFC18_ContractNew {
    /*MRA 08-DEC-2017:
    All-In does not allow contracts to be created directly.
    Updated logic implemented for new button to bypass All-In rule when creating of contract-In contracts for Common users and cTin profiles 
    
    USA 06-MAR-2018:
    Allow ATS contracts to be created without opportunity
    
    USA 05-SEP-2018:
    Allow all users (PMO-ADV, Sys Admin and those having permission set PS - Light contract) to create light contracts without opportunity
    
    USA 24-JUL-2019:
    Allow contracts to be created without opportunity in lightning (Lightning Contract RT)
    
    SGO 22-08-2019:
    Allow amendments to be created without opportunity in lightning (Lightning Contract Amendment Edit RT)
    
    ARA 02-06-2020:
    Adapt for all user's language
    */
    
    private final sObject mysObject;
    String strRecTypeId;
    integer countAssignedPs;
    Boolean isContractInUser;
    // The extension constructor initializes the private member
    // variable mysObject by using the getRecord method from the standard
    // controller
    public VFC18_ContractNew(ApexPages.StandardController stdController) {
        strRecTypeId = ApexPages.currentPage().getParameters().get('RecordType');
        
        // SGO - 2019/09/19 - In case strRecTypeId is null
        if (strRecTypeId == null) {
            List<String> recordTypeNameList = new List<String>();
            Schema.DescribeSObjectResult describeCtr = Schema.SObjectType.Contract__c;
            List<Schema.RecordTypeInfo> rtInfos = describeCtr.getRecordTypeInfos();
            
            // ARA - 2020/06/02 - Used for all user's language
            for(Schema.RecordTypeInfo rtInfo : rtInfos) {
                if(!rtInfo.isMaster() && rtInfo.isAvailable()) {
                    ApexPages.currentPage().getParameters().put('RecordType', rtInfo.getRecordTypeId());
                    strRecTypeId = rtInfo.getRecordTypeId();
                }
            }
        }
        
        countAssignedPs=0;
    }
    
    
    public PageReference newContract(){
        set<id> contractInProfSet=new set<id>();
        List<String> LstAllProfiles = System.Label.cTin_AllProfiles.split(';');
        
        for(Profile prof:[SELECT id
                          FROM profile
                          WHERE name IN :LstAllProfiles]){
                              contractInProfSet.add(prof.id);
                          }
        /*countAssignedPs=[SELECT count()
FROM PermissionSetAssignment 
WHERE AssigneeId= :UserInfo.getUserId() 
AND PermissionSet.Name =: system.label.cTin_CommonPermissionSet];*/
        
        isContractInUser = [SELECT cTin_Universign__c FROM User WHERE Id = :UserInfo.getUserId()][0].cTin_Universign__c;
        Map<String, RecordType>rtIdMap = AP_Constant.getRecordTypes('Contract__c');
        
        //MRA 10/09/2019 - Added check on profile 360 functional admin
        if(!isContractInUser &&
           (strRecTypeId == Schema.SObjectType.Contract__c.getRecordTypeInfosByName().get(AP_Constant.strContractLightRecType).getRecordTypeId() &&
            (AP_Constant.hasRights(AP_Constant.strProfPMOADV) || AP_Constant.hasRights(AP_Constant.functionalAdmin)) ) ||
           (strRecTypeId == Schema.SObjectType.Contract__c.getRecordTypeInfosByName().get('Contract Draft').getRecordTypeId() ||
            strRecTypeId == Schema.SObjectType.Contract__c.getRecordTypeInfosByName().get('Contract In Progress').getRecordTypeId() ||
            strRecTypeId == Schema.SObjectType.Contract__c.getRecordTypeInfosByName().get('Contract Read Only').getRecordTypeId()) ){
                return new PageReference ('/a0D/e?retURL=%2Fa0D%2Fo&RecordType='+strRecTypeId+'&nooverride=1');
                
            }
        // Contract-In users
        else if(isContractInUser &&
                contractInProfSet.contains(UserInfo.getProfileId())){
                    strRecTypeId=rtIdMap.get('cTin_Contract_Draft').id;
                    return new PageReference ('/a0D/e?retURL=%2Fa0D%2Fo&RecordType='+strRecTypeId+'&nooverride=1');
                }
        /*// ATS contracts
        else if (strRecTypeId == Schema.SObjectType.Contract__c.getRecordTypeInfosByName().get(AP_Constant.strATSRecType).getRecordTypeId()){
            return new PageReference ('/a0D/e?retURL=%2Fa0D%2Fo&RecordType='+strRecTypeId+'&nooverride=1');
        }*/
        // All-n --> If contract light + sys admin 
        else if (strRecTypeId == Schema.SObjectType.Contract__c.getRecordTypeInfosByName().get(AP_Constant.strContractLightRecType).getRecordTypeId()
                 //USA 20180905: commented condition to allow creation of light contrats for users with PS - Light Contract
                 //&& AP_Constant.hasRights(AP_Constant.strProfPMOADV)
                ){
                    return new PageReference ('/a0D/e?retURL=%2Fa0D%2Fo&RecordType='+strRecTypeId+'&nooverride=1');
                }
        // lightning contracts
        else if (strRecTypeId == Schema.SObjectType.Contract__c.getRecordTypeInfosByName().get(AP_Constant.RT_CONTRACT_EDIT_LIGHTNING_LABEL).getRecordTypeId()){
            return new PageReference ('/a0D/e?retURL=%2Fa0D%2Fo&RecordType='+strRecTypeId+'&nooverride=1');
        }
        //lightning amendments
        else if (strRecTypeId == Schema.SObjectType.Contract__c.getRecordTypeInfosByName().get(AP_Constant.RT_AMENDMENT_EDIT_LIGHTNING_LABEL).getRecordTypeId()){
            return new PageReference ('/a0D/e?retURL=%2Fa0D%2Fo&RecordType='+strRecTypeId+'&nooverride=1');
        }
        // all other contracts should create opportunity first
        else{
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'You have to create an opportunity.'));
        }
        
        return null;
    }
}