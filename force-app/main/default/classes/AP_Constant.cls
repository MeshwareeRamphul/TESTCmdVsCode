/**
 * @description       : 
 * @author            : JPI
 * @group             : 
 * @last modified on  : 09-03-2022
 * @last modified by  : ARA
 * Modifications Log 
 * Ver   Date         Author   Modification
 -- 1.0   20-10-2020   JPI   Initial Version
 -- 1.1   26-10-2021   UBE   Added Customer Community ProfileId => CustomerCommunityProfileId
 -- 1.2   15-12-2021   ARA   Added E-Sourcing Vendor Profile => esourcingVendorProfile
 -- 1.3   31-01-2022   ARA   Added Documment type
**/
public class AP_Constant {
     public static User currentUser = [SELECT id, cTin_Universign__c, profileId, profile.name FROM user WHERE Id = :UserInfo.getUserId()];
    /* Admin profile */
    private static Profile mAdminProfile { get; set; }
    
    /*profile AXA*/
    public static string axaInterface = 'AXA Interface';
    
    /*profile OpCo360*/
    public static string functionalAdmin = 'OpCo360 - Functional Admin';
    public static string billingTeam = 'OpCo360 - Billing Team';
    public static string contractManager = 'OpCo360 - Contract Manager';
    public static string accountManager = 'OpCo360 - Account Manager';
    public static string productOwner = 'OpCo360 - Product Owner';
    public static string dpLegal = 'OpCo360 - DP / Legal';
    public static string contractReviewer = 'OpCo360 - Contract Reviewer';

    /*profile Admin*/
    public static string userAdmin = 'User Administrator';
    public static string systemAdmin = 'System Administrator';
    public static string cTinAdmin = 'cTin - Super Admin';
    
    /*profile Community*/
    public static string userCommunity = 'Customer Community User';

    /*profile Esourcing Vendor*/
    public static string esourcingVendorProfile = 'E-Sourcing Vendor Profile';
    
    /* User */
    public final static String entityLocalCodeACH = 'ACH';
    public final static String entityLocalCodeCORE = 'CORE';

    /** Record type names */
    public final static String ACCOUNT_MANAGER = System.Label.Profile_AMO;
    public final static String PRODUCT_OWNER = System.Label.Profile_OO;
    public final static String OPTY_OWNER = System.Label.Profile_OptyOwner;
    public final static String MARKETING_OFFICER = System.Label.Profile_MO;
    public final static String PROJECT_MANAGER = System.Label.Profile_PM;
    public final static String PMOADV = System.Label.Profile_PMOADV;

    public final static String RT_AXAATS = 'AXA_ATS';
    public final static String RT_AXAATSReadOnly = 'AXA_ATS_ReadOnly';

    /** RT Names */
    public final static String RT_LEGAL_ENTITY_ACCOUNT = System.Label.RT_Legal_Entity;
    public final static String RT_MASTER_ENTITY_ACCOUNT = System.Label.RT_Master_Entity;
    public final static String RT_ENTITY_ACCOUNT = System.Label.RT_Entity;
    public final static String RT_ENTITY_CONTACT = System.Label.RT_EntityContact;
    public final static String RT_CONTRACT_EDIT = System.Label.RT_ContractEdit;
    public final static String RT_CONTRACT_READONLY = System.Label.RT_ContractReadOnly;
    public final static String RT_AMENDMENT_EDIT = System.Label.RT_AmendmentEdit;
    public final static String RT_AMENDMENT_READONLY = System.Label.RT_AmendmentReadOnly;
    public final static String RT_AGSASIA_EDIT = System.Label.RT_AGSAsiaEdit;
    public final static String RT_AGSASIA_READONLY = System.Label.RT_AGSAsiaReadOnly;
    public final static String RT_AGSSPAIN_EDIT = System.Label.RT_AGSSpainEdit;
    public final static String RT_AGSSPAIN_READONLY = System.Label.RT_AGSSpainReadOnly;
    public final static String RT_ATS_EDIT = System.Label.RT_Ats_Edit;
    public final static String RT_ATS_READONLY = System.Label.RT_Ats_Readonly;
    public final static String RT_DN_LEGAL_ENTITY = 'Legal_Entity'; // developer name
    public final static String RT_DN_ENTITY = 'Entity'; // developer name
    public final static String RT_AXATP_EDIT = 'AXA_ATS'; // developer name
    public final static String RT_AXATP_READONLY = 'AXA_ATS_ReadOnly'; // developer name
    public final static String RT_OPP_LIGHTNING_FULL = System.Label.RT_OppLgtFull; // developer name
    public final static String RT_OPP_LIGHTNING_FULL_LABEL= 'Full Opportunity Contract process OpCo360'; //label
    public final static String RT_OPP_LIGHTNING_FULL_RO = System.Label.RT_OppLgtFullRO; // developer name
    public final static String RT_OPP_LIGHTNING_SINGLE= System.Label.RT_OppLgtSingle; //dev name
    public final static String RT_OPP_LIGHTNING_SINGLE_LABEL= 'Single Opportunity process OpCo360'; //label
    public final static String RT_OPP_LIGHTNING_SINGLE_RO= System.Label.RT_OppLgtSingleRO; //dev name
    public final static String RT_CONTRACT_EDIT_LIGHTNING = System.Label.RT_ContractEditLightning;
    public final static String RT_CONTRACT_READONLY_LIGHTNING = System.Label.RT_ContractReadOnlyLightning;
    public final static String RT_CONTRACT_READONLY_LIGHTNING_LABEL = 'OpCo360 - Single Contract process Read Only';
    public final static String RT_CONTRACT_EDIT_LIGHTNING_LABEL = 'OpCo360 - Single Contract process Edit';
    public final static String RT_AMENDMENT_EDIT_LIGHTNING_LABEL = 'OpCo360 - Amendment Edit';
    public final static String RT_AMENDMENT_READONLY_LIGHTNING_LABEL = 'OpCo360 - Amendment Read Only';
    public final static String RT_AMENDMENT_EDIT_LIGHTNING = System.Label.RT_AmendmentEditLightning;
    public final static String RT_AMENDMENT_READONLY_LIGHTNING = System.Label.RT_AmendmentReadOnlyLightning;
    public final static string RT_LIGHTCONTRACT = 'Light_Contract';
    public final static string RT_CTIN_DRAFT = 'cTin_Contract_Draft';
    public final static string RT_CTIN_INPROGRESS = 'cTin_Contract_In_Progress';
    public final static string RT_CTIN_READONLY = 'cTin_Contract_Read_Only';
    public final static string contractActive='Active';
    public final static string contractExpired='Expired';
    public final static string contractSignedStatus='Signed';

    /*Opty Stages*/
    public final static String STAGE_LEADS_GATHERING = System.Label.OptyStage_LeadsGathering;
    public final static String STAGE_COLLECT = System.Label.OptyStage_Collect;
    public final static String STAGE_QUALIFY_ALIGN = System.Label.OptyStage_QualifyAlign; // V2
    public final static String STAGE_CONTRACTING = System.Label.OptyStage_Contracting; // V2
    public final static String STAGE_WON = System.Label.OptyStage_Won;
    public final static String STAGE_LOST = System.Label.OptyStage_Lost;
    public final static String STAGE_CANCEL = System.Label.OptyStage_Cancel;

    /*Opty Entity*/
    public final static String GS_ENTITY_AXA_GR_OP_FR='AXA Group Operations France';
    public final static String GS_ENTITY_AXA_GR_OP_HK='AXA Group Operations Hong Kong Limited';
    public final static String GS_ENTITY_AXA_GR_OP_BG='AXA Group Operations Belgium';

    /*Opty Answer cinematic */
    public final static String ANS_CINE_BUS_CASE= 'Business Case';

    // TODO TO REMOVE
    public final static String STAGE_ANSWER_IN_PROGRESS = System.Label.OptyStage_AnswerInProgress;

    /*Product stages*/
    public final static String PRODUCT_STATUS_STOPPED = System.Label.Product_status_stopped;
    public final static String PRODUCT_STATUS_RETIRED = System.Label.Product_status_retired;
    public final static String PRODUCT_STATUS_IDEA = System.Label.Product_status_idea;


    /*Contract stages*/
    public final static String CONTRACT_STATUS_DRAFT = System.Label.ContractStatus_Draft;
    public final static String CONTRACT_STATUS_INTERNAL_VALIDATION = System.Label.ContractStatus_InternalValidation;
    public final static String CONTRACT_STATUS_VALIDATED = System.Label.ContractStatus_Validated;
    public final static String CONTRACT_STATUS_CUSTOMER_VALIDATION = System.Label.ContractStatus_CustomerValidation;
    public final static String CONTRACT_STATUS_REJECTED_BY_CUSTOMER = System.Label.ContractStatus_RejectedByCustomer;
    public final static String CONTRACT_STATUS_READY_FOR_SIGNATURE = System.Label.ContractStatus_ReadyForSignature;
    public final static String CONTRACT_STATUS_SENT_FOR_SIGNATURE = System.Label.ContractStatus_SentForSignature;
    public final static String CONTRACT_STATUS_SIGNED = System.Label.ContractStatus_Signed;
    public final static String CONTRACT_STATUS_CANCELLED = System.Label.ContractStatus_Cancelled;
    public final static String CONTRACT_STATUS_TERMINATED = System.Label.ContractStatus_Terminated;
    public final static String CONTRACT_STATUS_ENDED = System.Label.ContractStatus_Ended;
    public final static String CONTRACT_STATUS_RESILIATED = System.Label.ContractStatus_Resiliated;
    // HVA 10-2017 : AXA All In - Merge ContractIn <<START>>
    public final static String CONTRACT_STATUS_INAPPROVAL = System.Label.cTin_ContractStatus_InApproval;
    public final static String CONTRACT_STATUS_INSIGNATURE = System.Label.cTin_ContractStatus_InSignature;
    public final static String CONTRACT_STATUS_INPROGRESS = System.Label.cTin_ContractStatus_InProgress;
    // HVA 10-2017 : AXA All In - Merge ContractIn <<END>>

    /*Invoicing Lines stages*/
    public final static String INVLINE_STATUS_DRAFT = System.Label.InvLineStatus_Draft;
    public final static String INVLINE_STATUS_INVOICING_VALIDATION = System.Label.InvLineStatus_InvoicingValidation;
    public final static String INVLINE_STATUS_INVOICED = System.Label.InvLineStatus_Invoiced;
    public final static String INVLINE_STATUS_PAID = System.Label.InvLineStatus_Paid;

    /* Invoicing lines RT */
    public final static String RT_INVLINE_Edit = System.Label.RT_InvLineEdit;

    /* Invoicing Lines Type */
    public final static String INVLINE_TYPE_INVLINE= 'Invoicing Line';
    
    /* SIGNATURE type */
    public final static String SIGNATURE_MANUAL = System.Label.Contract_Signature_Type_Manual;
    public final static String SIGNATURE_ELECTRONIC = System.Label.Contract_Signature_Type_Electronic;
    //15/05/2017-MRA: added constants referenced in AP22
    public final static String SIGNATURE_CONTRACTIN = 'Contract In';

    /* SOW types on ATS contracts */
    public final static String SOW_CONSULTING = 'Consulting';
    public final static String SOW_PENTEST = 'Pentest';
    public final static String SOW_CESAME = 'Cesame';
    public final static String SOW_ENVELOPPE = 'Enveloppe';
    
    public final static String SOW_PRODUCT_TEMPLATE = 'Product SOW template (recommended)';
    public final static String SOW_GETD_TEMPLATE = 'GETD Contract Template (specific)';
    public final static String SOW_CESAME_TEMPLATE = 'CESAME Template (specific)';

    //For test
    public static boolean isBypassed = false;
    /* Lightning Theme */
    static set<String> setLightningThemes = new set<String>{'Theme4d','Theme4t'};
    @TestVisible public static Boolean themeLightning = setLightningThemes.contains(UserInfo.getUiThemeDisplayed());
    
    /* ILs Invoicing Date */
    public final static Integer INT_INVDATE = 05;

    /* SourcingEvent Status */
    public final static String SOURCING_EVENT_STATUS_PREPARATION_IN_PROGRESS = 'Preparation_in_Progress';
    public final static String SOURCING_EVENT_STATUS_PUBLISHED = 'Published';
    public final static String SOURCING_EVENT_STATUS_PENDING_SELECTION = 'Pending_Selection';
    public final static String SOURCING_EVENT_STATUS_COMPLETED = 'Completed';
    public final static String SOURCING_EVENT_STATUS_CANCELLED = 'Cancelled';

    /* Participant Status */
    public final static String PARTICIPANT_STATUS_SELECTED = 'Selected';
    public final static String PARTICIPANT_STATUS_CONFIRMED = 'Confirmed';
    public final static String PARTICIPANT_STATUS_NDASIGNED = 'NDA Signed';
    public final static String PARTICIPANT_STATUS_PARTICIPATIONINPROGRESS = 'Participation in Progress';
    public final static String PARTICIPANT_STATUS_SHORTLISTED = 'Short-listed';
    public final static String PARTICIPANT_STATUS_AWARDEE = 'Awardee';
    public final static String PARTICIPANT_STATUS_LOST = 'Lost';
    public final static String PARTICIPANT_STATUS_DECLINED = 'Declined';

    /* Round Status */
    public final static String ROUND_STATUS_PREPARATION = 'Preparation';
    public final static String ROUND_STATUS_IN_PROGRESS = 'In Progress';
    public final static String ROUND_STATUS_COMPLETED = 'Completed';
    public final static String ROUND_STATUS_CANCELLED = 'Cancelled';

    /* Sourcing document type */
    public final static String DOCUMENT_TYPE_RFX_REQUIREMENTS = 'RFX Requirements';
    public final static String DOCUMENT_TYPE_CONTRACT_TEMPLATES = 'Contract Templates';
    public final static String DOCUMENT_TYPE_NDA_SIGNED = 'NDA Signed';
    public final static String DOCUMENT_TYPE_MANAGEMENT_SUMMARY = 'Management Summary';
    public final static String DOCUMENT_TYPE_OTHER_DOCUMENT_INTERNAL = 'Other Document Internal';
    public final static String DOCUMENT_TYPE_OTHER_DOCUMENT_EXTERNAL = 'Other Document External';
    public final static String DOCUMENT_TYPE_RFX_RESULTS = 'RFX Results';
    
    /* PS Flow */
    public static string PS_FLOW_1 = 'Flow 1';
    public static string PS_FLOW_2 = 'Flow 2';
    public static string PS_FLOW_3 = 'Flow 3';
    public static string PS_SUCCESS = 'Success!';
    
    /* Document Type Esourcing*/
    public final static String TYPE_NDA_SIGNED = 'NDA Signed';

    static {
        mAdminProfile = [SELECT Id, Name FROM Profile Where PermissionsCustomizeApplication = true ORDER BY CreatedDate ASC limit 1];
    }

    public static ID getProfileAdminId() {
        if (mAdminProfile == null) {
            return null;
        }
        return mAdminProfile.Id;
    }

    /*
    * Get Record types of sObject with a map of key developername
    */
    public static Map<String, RecordType> getRecordTypes(String pSObjectType) {
        Map<String, RecordType> vRecordTypesMap = new Map<String, RecordType>();
        List<RecordType> vRecordtypesList = [SELECT Id, developerName, Name, sObjectType FROM RecordType WHERE sObjectType = :pSObjectType];
        if (vRecordtypesList != null) {
            for (RecordType vRT : vRecordtypesList) {
                vRecordTypesMap.put(vRT.developerName, vRT);
            }
        }

        return vRecordTypesMap;
    }

    // HVA 10-2017 : All In - Merge ContractIn <<START>>
    public static Set<String> getCTinRecordTypes(String pSObjectType) {
        Set<String> setCtinRecTypeId = new Set<String>();
        List<RecordType> lstRecordTypes = [SELECT Id, developerName, Name, sObjectType FROM RecordType WHERE sObjectType = :pSObjectType AND DeveloperName LIKE 'cTin_%'];
        if (lstRecordTypes.size() > 0) {
            for (RecordType rt : lstRecordTypes) {
                setCtinRecTypeId.add(rt.id);
            }
        }

        return setCtinRecTypeId;
    }
    // HVA 10-2017 : All In - Merge ContractIn <<END>>

//    // USA 2018-03-30
//    public static List<RecordType> getAGSRecordTypes(String pSObjectType) {
//        List<RecordType> lstRecordTypes = [SELECT id, developerName FROM recordType WHERE sObjecttype = :pSObjectType];
//        return lstRecordTypes;
//    }

//    // Method returns all record types related to object passed in parameter
//    public static map<String,RecordType> getObjectRecordTypes(String pSObjectType) {
//        map<String,RecordType> mapRecType = new map<String,RecordType>();
//        for (RecordType rec :[SELECT id, developerName FROM recordType WHERE sObjecttype = :pSObjectType]){
//            mapRecType.put(rec.developerName, rec);
//        }
//        return mapRecType;
//    }

//    /*
//    * Return currency map  by isocode
//    */
//    public static Map<String, CurrencyType> getCurrenciesMap() {
//        Map<String, CurrencyType> vCurrencyMap = new Map<String, CurrencyType>();
//        List<CurrencyType> vCurrencyTypes = [SELECT Id, IsoCode, ConversionRate FROM CurrencyType Where IsActive = true];
//        for (CurrencyType vCurrency : vCurrencyTypes) {
//            vCurrencyMap.put(vCurrency.IsoCode, vCurrency);
//        }
//
//        return vCurrencyMap;
//    }

    //15/05/2017-MRA: added constants referenced in AP22
    /* Esignature status */
    public final static string eSignatureCompletedStatus='Completed';
    public final static string eSignatureSentStatus='Sent';
    public final static string eSignatureInprogressStatus='In progress';
    public final static string eSignatureCreatedStatus='Created';
    public final static string eSignatureExpiredStatus='Expired';
    public final static string eSignatureFailedStatus='Failed';
    public final static string eSignatureCancelledStatus='Cancelled';
    public final static string eSignatureRejectedStatus='Rejected';

    /* Contract status */
    public final static string contractReadyStatus='Ready for Signature';
    public final static string contractSentStatus='Sent for Signature';
    public final static string contractCustValidationStatus='Customer Validation';
    public final static string contractInSignatureStatus='In Signature';
    public final static string contractDraft='Draft';

    /* Esignature record types */
    public final static string recordTypeInSignature='In_eSignature';
    public final static string OpCo_Draft='OpCo_Draft';
    public final static string recordTypeDraft='Draft';
    public final static string recordTypeRO='Read_Only';
    public final static string cTin_recordTypeROInSignature='cTin_InEsignature';
    public final static string cTin_recordTypeDraft='cTin_Draft';
    public final static string cTin_recordTypecTinRO='cTin_ReadOnly';

    /*Esignatory status*/
    public final static string esignatoryStatusValidated='Validated';
    public final static string esignatoryStatusSigned='Signed';
    public final static string esignatoryStatusReady='Ready';
    public final static string esignatoryStatusWaiting='Waiting';
    public final static string esignatoryStatusNotStarted='Not Started';
    public final static string esignatoryStatusCancelled='Canceled';
    public final static string esignatoryStatusRejected='Rejected';
    public final static string esignatoryStatusAwaiting='Awaiting';
    public final static string esignRoleUniversignSigner='signer';

    /*Esignatory role*/
    public final static string esignRoleSigner='Signer';
    public final static string esignRoleValidator='Validator';

    /*Products*/
    public final static String PRODUCT_LIVE = 'Live !';

    //MRA: 20181506 - Contract Team role
    public final static string contractTeamCoOwner='015';

    //USA: 20170713 - query to get POS order
    public static Map<String, Integer> getOrderStatus() {
        Map<String, Integer> orderMap = new Map<String, Integer>();

        for (POS__mdt pos : [SELECT Order__c, MasterLabel, DeveloperName FROM POS__mdt]) {
            orderMap.put(pos.MasterLabel, Integer.valueOf(pos.Order__c));
        }
        return orderMap;
    }

    //USA: 20170716 - POS Status
    public final static string strPosStatus_Live = 'Live';
    public final static string strPosStatus_NewLive = 'New live';
    public final static string strPosStatus_Plan = 'Planned';
    public final static string strPosStatus_UndrDis = 'Under discussion';

    // Entity Rolled Out record types
    public final static string strERORecType = 'Entity Rolled Out';
    public final static string strMERORecType = 'Master Entity Rolled Out';

    // Contract Record Type
    public final static string strContractLightRecType = 'OpCo360 - Light Contract';
    public final static string strATSRecType = 'AXA Technical Products';

    //Permission Set Name
    public final static string strPerLightCtr = 'PS_Light_Contract';

    //Error messages
    public final static string strCRCannotCreate = 'You do not have sufficient rights to create a Credit Note.';
    public final static string strCRCannotUpdate = 'You do not have sufficient rights to update a Credit Note.';
    public final static string strLightConCannotUpdate = 'You do not have sufficient rights to update a Light Contract.';

    //Profile name
    public final static String strProfPMOADV = 'PMO - ADV';

    //IL Status
    public final static String strInvoiced = '03';
    public final static String strPaid = '04';

    //Credit Note Type
    public final static String INVLINE_TYPE_CreditNote = 'Credit Note';

    //PDF Status
    public final static String strPDFStatusUpdated = 'Updated';
    public final static String strPDFStatusNotUpdated = 'Not updated!';

    // get system admin profile id
    public static String getProfileIdAdmin(){
        return [Select Id From Profile
                            Where name = 'Administrateur système'
                                OR name = 'System Administrator'
                                OR name = 'Amministratore del sistema'
                                OR name = 'Systemadministrator'
                                OR name = 'Systemadministratör'
                                OR name = 'Administrador do sistema'
                                OR name = 'Systeembeheerder'
                                OR name = 'Systemadministrator'].Id;
    }
    // get system admin profile id
    public static String getProfileIdFunctionalAdmin(){
        return [Select Id From Profile Where name = 'OpCo360 - Functional Admin'].Id;
    }

    //check if user profile matches profile with permission
    public static Boolean hasRights(String strProfile){
        Id IdCurProfile = UserInfo.getProfileId();

        Set<Id> setIdProfile = new set<Id>();
        for (Profile prof :[SELECT id FROM profile WHERE name = :strProfile
                            OR name = 'Administrateur système'
                            OR name = 'System Administrator'
                            OR name = 'Amministratore del sistema'
                            OR name = 'Systemadministrator'
                            OR name = 'Systemadministratör'
                            OR name = 'Administrador do sistema'
                            OR name = 'Systeembeheerder'
                            OR name = 'Systemadministrator']){
            setIdProfile.add(prof.Id);
        }

        if (setIdProfile.contains(IdCurProfile)){
            return true;
        } else{
            return false;
        }
    }

    //check if user profile matches profiles with permission
    public static Boolean hasRights(Set<String> setProfName){
        Id IdCurProfile = UserInfo.getProfileId();

        Set<Id> setIdProfile = new set<Id>();
        for (Profile prof :[SELECT id FROM profile WHERE name IN :setProfName
                            OR name = 'Administrateur système'
                            OR name = 'System Administrator'
                            OR name = 'Amministratore del sistema'
                            OR name = 'Systemadministrator'
                            OR name = 'Systemadministratör'
                            OR name = 'Administrador do sistema'
                            OR name = 'Systeembeheerder'
                            OR name = 'Systemadministrator']){
            setIdProfile.add(prof.Id);
        }

        if (setIdProfile.contains(IdCurProfile)){
            return true;
        } else{
            return false;
        }
    }

    //check if user is assigned specific permission sets
    public static Boolean hasPermission(set<String> setPerName){
        Id IdCurUser = UserInfo.getUserId();
        Set<Id> setPermissionSetId = new set<Id>();
        for(PermissionSetAssignment persetAss :[SELECT PermissionSetId
                                                FROM PermissionSetAssignment
                                                WHERE AssigneeId= :IdCurUser
                                                AND PermissionSet.Name IN :setPerName]){
        setPermissionSetId.add(persetAss.PermissionSetId);
        }

        if (setPermissionSetId.size()>0){
            return true;
        } else{
            return false;
        }
    }

    public static Set<String> getPickListValuesIntoListOpp() {
       Set<String> pickListValuesList= new Set<String>();
        Schema.DescribeFieldResult fieldResult = Opportunity.AXA_GO_Entity__c.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        for( Schema.PicklistEntry pickListVal : ple){
            pickListValuesList.add(pickListVal.getLabel());
        }     
        return pickListValuesList;
    }
}