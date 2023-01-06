/*
--------------------------------------------------------------------------------------
-- - Name          : LWC4_SearchController
-- - Author        : XXX
-- - Description   : Controller for lwc LWC_UploadedDocument;
        public lWC_EditSignature, lWC_GenerateInvoicingLines
--
-- Maintenance History:
--
-- Date         Name  Version  Remarks
-- -----------  ----  -------  -------------------------------------------------------
-- XX-XX-XXXX  XXX    1.0     Initial version 
-- 28-10-2021  UBE    1.0     Comment filter Round lookup by status
--------------------------------------------------------------------------------------
*/
public with sharing class LWC4_SearchController {
    @AuraEnabled
    public static List<sObject> search(String objectName,String currentObject, String currentRecordId, List<String> fields, String searchTerm){
        String searchKeyword = searchTerm + '*';
        String returningQuery = '';
        String status = 'In Progress';

        //START 28-10-2021  UBE    1.0
        returningQuery = objectName + ' ( Id, '+ String.join(fields,',') + ' WHERE ' + currentObject + ' = :currentRecordId' + ')';
        String query = 'FIND :searchKeyword IN ALL FIELDS RETURNING '+returningQuery+' LIMIT 20';
        System.debug(' query '+query);
        List<List<sObject>> searchRecords = Search.Query(Query);
        System.debug('*****result '+searchRecords.get(0));
        return searchRecords.get(0);
    }

    @AuraEnabled
    public static List<sObject> searchWithCondition(String params){
        WrapperParameters wparam = parseJSONToTParamsObject(params);
        String objectName = wparam.objectName;
        String currentObject = wparam.currentObject;
        String selectedRound = wparam.selectedRound;
        String currentRecordId = wparam.currentRecordId;
        String searchTerm = wparam.searchTerm;
        String axaGoLegalEntity = wparam.axaGoLegalEntity;
        String serviceType = wparam.serviceType;
        List<String> fields = wparam.fields;
        List<String> conditions = wparam.conditions;
        List<String> rejectedEmails = wparam.rejectedEmails;
        List<String> exceptActivityCode = wparam.exceptActivityCode;

        String searchIn = '';
        if(String.isNotEmpty(searchTerm)){
            searchIn = '%'+searchTerm+'%';
        }
        List<String> participantStatus = new List<String>{'Declined', 'Lost'};
        String fieldsConditions = '';
        String searchCondition = '';
        if(currentRecordId != null){
            searchCondition += ' WHERE '+currentObject+' = :currentRecordId';
        }
        
        if(conditions != null && conditions.size() > 0){
            boolean isOtherCondition = false;
            for(String cond: conditions){
                System.debug('****cond '+cond);
                System.debug('****objectName '+objectName);
                if(objectName == 'Master_WBS_Structure__c'){// for generate Invoicing lines LWC_GenerateInvoicingLines
                    if(cond == 'Active__c'){
                        fieldsConditions += ' AND Active__c = true';
                    }else if(cond == 'Id' && exceptActivityCode != null){
                        fieldsConditions += ' AND Id NOT IN :exceptActivityCode';
                    }else if(cond == 'GIE_GO_SAS__c' && axaGoLegalEntity != null){
                        fieldsConditions += ' AND GIE_GO_SAS__c = :axaGoLegalEntity';
                        if(serviceType != '' && serviceType != null){
                            String start_L = 'L%';
                            String start_TBD = 'TBD%';
                            if(serviceType == 'BAU'){
                                fieldsConditions += ' AND (Name LIKE :start_L OR Name LIKE :start_TBD)';
                            }else if(serviceType == 'Project'){
                                fieldsConditions += ' AND (NOT Name LIKE :start_L)';
                            }
                        }
                    }else if(!isOtherCondition && (cond == 'Name' || cond == 'Activity_Level_1__c' || cond == 'Activity_Level_2__c' || cond == 'Cost_center_description__c') && String.isNotEmpty(searchIn)){
                        System.debug('****searchIn '+searchIn);
                        searchCondition += (searchCondition == '') ? ' WHERE (Name LIKE :searchIn OR Activity_Level_1__c LIKE :searchIn OR Activity_Level_2__c LIKE :searchIn OR Cost_center_description__c LIKE :searchIn' : ' AND (Name LIKE :searchIn OR Activity_Level_1__c LIKE :searchIn OR Activity_Level_2__c LIKE :searchIn';
                        isOtherCondition = true;
                    }
                }else if(objectName == 'Contact'){// for add validator LWC_EditSignature
                    if(cond == 'Active__c'){
                        fieldsConditions += ' AND Active__c = true';
                    }else if(cond == 'Email' && rejectedEmails != null){
                        fieldsConditions += ' AND Email NOT IN :rejectedEmails';
                    }else if(cond == 'RecordTypeId'){
                        Id recordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Entity contact').getRecordTypeId();
                        fieldsConditions += ' AND RecordTypeId = :recordTypeId';
                    }else if(String.isNotEmpty(searchIn)){
                        if(!isOtherCondition){
                            searchCondition += (searchCondition == '') ? ' WHERE (' + cond + ' LIKE :searchIn' : ' AND (' + cond + ' LIKE :searchIn';
                            isOtherCondition = true;
                        }else{
                            searchCondition += ' OR ' + cond + ' LIKE :searchIn';
                        }
                    }
                }else if(objectName == 'Sourcing_Event__c' || objectName == 'Bidder__c'){// for add document Sourcing_Event__c
                    System.debug('***round0 :'+selectedRound);
                    if(cond == 'Bidder_Status__c'){
                        fieldsConditions += ' AND Bidder_Status__c NOT IN :participantStatus';
                    }else if(cond == 'Negotiation_Round__c'){
                        if(selectedRound != null){
                            System.debug('***round1 :'+selectedRound);
                            fieldsConditions += ' AND Negotiation_Round__c = :selectedRound';
                        }
                    }
                }else if(String.isNotEmpty(searchIn)){
                    if(!isOtherCondition){
                        searchCondition += (searchCondition == '') ? ' WHERE (' + cond + ' LIKE :searchIn' : ' AND (' + cond + ' LIKE :searchIn';
                        isOtherCondition = true;
                    }else{
                        searchCondition += ' OR ' + cond + ' LIKE :searchIn';
                    }
                }
            }
            if(isOtherCondition){
                searchCondition += ')';
            }
            searchCondition += (searchCondition == '') ? ' WHERE ' + fieldsConditions.substring(4, fieldsConditions.length()) : fieldsConditions;
        }
        searchCondition += ' LIMIT 20';
        
        String query = 'SELECT ID' + (fields != null && fields.size()>0 ? (', '+String.join(fields,',')) : '') + ' FROM ' + objectName + searchCondition;
        System.debug('****query '+query);
        List<sObject> searchRecords = database.query(query);
        return searchRecords;
    }
    
    public static WrapperParameters parseJSONToTParamsObject(String json){
        WrapperParameters trans = new WrapperParameters();
        try{
            trans = (WrapperParameters) System.JSON.deserialize(json, WrapperParameters.class);
        }catch(Exception e){
            System.debug('##Exception deserialization '+ e.getMessage());
        }
        return trans;
    }
    
    public class WrapperParameters {
        public String objectName;
        public String currentObject;
        public String selectedRound;
        public String currentRecordId;
        public String searchTerm;
        public String axaGoLegalEntity;
        public String serviceType;
        public List<String> exceptActivityCode;
        public List<String> fields;
        public List<String> conditions;
        public List<String> rejectedEmails;
    }
}