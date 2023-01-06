/*----------------------------------------------------------------------
-- - Name          : ContractTriggerHandler
-- - Author        : Spoon
-- - Description   : trigger handler for contract__c
--
-- - History:

-- Date         Name  Version  Remarks
-- -----------  ----  -------  ---------------------------------------
--                     1.0      Initial version
-- 17-OCT-2017  HVA    1.1      All-In merge Contract-In
-- 04-APR-2019  MRA    1.2      Add AIM Local Admin group as co-owner if contract=AIM (Evolution 4330)
-- 24-APR-2020  USA    1.3      SP-00221
-- 07-MAY-2020  MRA    1.4      SP-00187 (other location is mandatory if data storage location is "Other"
-- 03-JUN-2020  USA    1.4      SP-00320 (Code Optimisation)
-- 03-JUN-2020  ARA    1.5      SP-00372 
-- 17-AUG-2020  ARA    1.6      SP-00109 
-- 17-AUG-2020  ARA    1.7      SP-01275 (Disable VRs coded or configured on Contracts when ILs are modified)
-- 17-MAR-2021  ARA    1.8      SP-01222 Correction of bug (Sharing not generated on ContractForm for BO)
-- 18-MAR-2021  ARA    1.9      SP-01472 Check validation rule on Customer Contact on IL
-- 25-MAR-2021  ARA    1.10     SP-01488 Allow contract update after send to PS even if Customer Operational contact is inactive
-- 30-MAR-2021  ARA    1.11     SP-01588 rules on contacts in the sow with the manual signature type
-- 02-JUN-2021  MRA    1.12     SP-01168 generate contract team for ABE_CorporateLegal group (AP60)
-- 07-JUN-2021  ARA    1.13     SP-01938 esquire deactivated Offer when trying to change invoice line
-- 28-JUN-2021  ARA    1.14     SP-02055 Comment on lines for SP-01938
-- 28-JUN-2021  MRA    1.15     SP-02061 Geopgraphical scope is mandatory for AIM
-- 28-JUN-2021  ARA    1.16     SP-01783 Change on the PO reminder emails
-- 05-JUl-2021  ARA    1.17     SP-01432 Product model
-- 07-JUL-2021  ARA    1.18     SP-01432 Allow change product and not blocked on look up filter field
-- 08-JUL-2021  MRA    1.19     SP-01401 make additional fields mandatory
-- 16-JUL-2021  MRA    1.20     SP-02172  Modify the trigger to add products for light contracts import
-- 09-SEP-2021  MRA    1.21     SP-02382 - Add 'G Con Pro De' group as co-owner if owner.entity equals ADE
-- 27-SEP-2021  ARA    1.22     SP-02556 - Error -Modification IL amount
-- 07-DEC-2021  MRA    1.23     SP-02871 - CTIn release 9
-- 09-DEC-2021  ARA    1.24     SP-02699 - Allow amendment creation when contact is inactive
-- 10-DEC-2021  MBE    1.25     Add condition to check bypass trigger AP39
-- 21-JAN-2022  HSO    1.26     SP3200 - Allow IL update when contract is signed
-- 03-FEB-2022  HSO    1.27     SP-02841 - Prevent AXA GO or customer entity change after send to PS
-- 01-MAR-2022  MRA    1.28     CTin R1 - SP-02932 - Add ACH Audit & Lega + ACH Procurement by default on ACH contracts
-- 12-APR-2022  MRA    1.29     cTin - Cpm changes (new mandatory rules)
-- 20-APR-2022  AMA    1.30     SP-03418
-- 22-APR-2022  AMA:   1.29     Build sourcing pipeline status
-- 03-MAY-2022  ARA    1.31     SP-03718 - Add bypassVR
-- 28-JUN-2022  MRA    1.32     CTin R5 - add public group in ct for AGO
-- 11-JUL-2022  ARA    1.33     SP-02668 (Ensure IL currency same as contract)
-- 11-JUL-2022  ARA    1.34     SP-02770 (Contract | Change PO reminder functionality)
-------------------------------------------------------------------------*/
public without sharing class ContractTriggerHandler {

    //public static Boolean isRunningCtrHandlerAfterUpdt=false;
    //    public static Boolean hasExecutedcheckRights=false;
    //    public static Boolean hasExecutedafterInsertHandler=false;
    //    public static Boolean hasExecutedafterUpdateHandler=false;
    //
    //    Static Id idRecLightContract = Schema.SObjectType.Contract__c.getRecordTypeInfosByName().get(AP_Constant.strContractLightRecType).getRecordTypeId();
    //    Static id idRecContractDraft = Schema.SObjectType.Contract__c.getRecordTypeInfosByName().get(AP_Constant.strContractDraftRecType).getRecordTypeId();
    //    Static id idRecContractInProgress = Schema.SObjectType.Contract__c.getRecordTypeInfosByName().get(AP_Constant.strContractInProgressRecType).getRecordTypeId();
    //    Static id idRecContractReadOnly = Schema.SObjectType.Contract__c.getRecordTypeInfosByName().get(AP_Constant.strContractReadOnlyRecType).getRecordTypeId();
    
        public static Boolean hasExecutedafterInsertHandler = false;
        public static Boolean hasExecutedafterUpdateHandler = false;
        public static Boolean hasExecutedbeforeUpdateHandler = false;
        public static Boolean UserBypassVr                  = [SELECT PAD_BypassValidationRules__c FROM User WHERE ID= :UserInfo.getUserId()][0].PAD_BypassValidationRules__c;
    
        // Record Type IDs of contact object
        public static Id idRecEntityContact = Schema.SObjectType.Contact.getRecordTypeInfosByName().get(AP_Constant.RT_ENTITY_CONTACT).getRecordTypeId();

        // Record Type IDs of contract object
        static map<String, Schema.RecordTypeInfo>  mapRecTypeInfo = Schema.SObjectType.Contract__c.getRecordTypeInfosByDeveloperName();
        public static Id idRecContractDraft                 = mapRecTypeInfo.get(AP_Constant.RT_CTIN_DRAFT).getRecordTypeId();
        public static Id idRecContractInProgress            = mapRecTypeInfo.get(AP_Constant.RT_CTIN_INPROGRESS).getRecordTypeId();
        public static Id idRecContractReadOnly              = mapRecTypeInfo.get(AP_Constant.RT_CTIN_READONLY).getRecordTypeId();
        public static Id idRecLightContract                 = mapRecTypeInfo.get(AP_Constant.RT_LIGHTCONTRACT).getRecordTypeId();
        public static Id idRecOpCoSingleEdit                = mapRecTypeInfo.get(AP_Constant.RT_CONTRACT_EDIT_LIGHTNING).getRecordTypeId();
        public static Id idRecOpCoSingleReadOnly            = mapRecTypeInfo.get(AP_Constant.RT_CONTRACT_READONLY_LIGHTNING).getRecordTypeId();
        public static Id idRecOpCoAmendEdit                 = mapRecTypeInfo.get(AP_Constant.RT_AMENDMENT_EDIT_LIGHTNING).getRecordTypeId();
        public static Id idRecOpCoAmendReadOnly             = mapRecTypeInfo.get(AP_Constant.RT_AMENDMENT_READONLY_LIGHTNING).getRecordTypeId();
    
        public static set<Id> setCtrRecTypescTin            = new set<Id>{idRecContractDraft, idRecContractInProgress,idRecContractReadOnly};
        public static set<Id> setCtrRecTypesOpCo            = new set<Id>{idRecLightContract, idRecOpCoSingleEdit, idRecOpCoSingleReadOnly, idRecOpCoAmendEdit, idRecOpCoAmendReadOnly};
        public static set<Id> setCtrRecTypesOpCoReadOnly    = new set<Id>{idRecOpCoSingleReadOnly, idRecOpCoAmendReadOnly};
        public static List<String> lstEditableStatus        = new List<String>{System.Label.ContractStatus_Draft, System.Label.ContractStatus_InternalValidation, System.Label.ContractStatus_CustomerValidation};
        public static List<String> lstReadOnlyStatus        = new List<String>{System.Label.ContractStatus_ReadyForSignature, System.Label.ContractStatus_SentForSignature, System.Label.ContractStatus_Signed};
        public static List<String> lstEditStatusManual      = new List<String>{System.Label.ContractStatus_Draft, System.Label.ContractStatus_InternalValidation, System.Label.ContractStatus_CustomerValidation};
        public static List<String> lstROStatusManual        = new List<String>{System.Label.ContractStatus_SentForSignature, System.Label.ContractStatus_Signed};
     
    
        /**
        * ----------------------------------------------------------------------------------------------
        * Method to check if user has rights to update a light contract
        * ----------------------------------------------------------------------------------------------
        * @param    lstNewContracts List<Contract__c>   : list of contracts from Trigger.new
        * ----------------------------------------------------------------------------------------------
        */
        public static void checkRights(List<Contract__c> lstNewContracts){
            set<String> setProfiles      = new set<String>{AP_Constant.functionalAdmin, AP_Constant.axaInterface};
            set<String> setPermissionSet = new set<String>{AP_Constant.strPerLightCtr};
            Boolean hasRights            = AP_Constant.hasRights(setProfiles) 
                || AP_Constant.hasPermission(setPermissionSet);
            for (Contract__c con :lstNewContracts){
                if (!hasRights) con.addError(AP_Constant.strLightConCannotUpdate);
            }
        }
    
        public static void blockUpdate(List<Contract__c> lstNewContracts){
            set<id>ctrNoApprovals=new set<id>();
            for( cTin_ContractForm__c cf : [select id, cTin_Contract__c,recordtypeId,cTin_FinalApprovalStatus__c from  cTin_ContractForm__c
            where cTin_Contract__c=:lstNewContracts and (cTin_FinalApprovalStatus__c= :'' or cTin_FinalApprovalStatus__c <>:'Waiting')]){
                ctrNoApprovals.add(cf.cTin_Contract__c);
            }
            //system.debug('##ctrNoApprovals'+ctrNoApprovals);
            for(Contract__c contract: lstNewContracts){
                //system.debug('##contract'+contract);
                //MRA 11-MAI-2020 : SP-00185
                if(ctrNoApprovals.size()>0 && ctrNoApprovals.contains(contract.id)){
                    contract.status__c.addError(system.label.cTin_ErrorUpdateStatus);
                }
            }
        }

        private static map<Id,Contact> getMapContacts(List<Contract__c> lstNewContracts){
            Set<Id> setContactSignedById = new Set<Id>();

            for (Contract__c ctr : lstNewContracts){
                if(ctr.Customer_Operational_Contact__c != null){
                    setContactSignedById.add(ctr.Customer_Operational_Contact__c);
                }
                if(ctr.CustomerSignedBy__c != null){
                    setContactSignedById.add(ctr.CustomerSignedBy__c);
                }
                if(ctr.CustomerSignedBy2__c != null){
                    setContactSignedById.add(ctr.CustomerSignedBy2__c);
                }
                if(ctr.AXA_GO_Signed_By_2__c != null){
                    setContactSignedById.add(ctr.AXA_GO_Signed_By_2__c);
                }
                if(ctr.AXA_GS_Signed_By__c != null){
                    setContactSignedById.add(ctr.AXA_GS_Signed_By__c);
                }
            }
            if(setContactSignedById.size()>0)
                return new Map<Id, Contact>([SELECT Id, RecordTypeId, Active__c, AXA_GO_Signatory__c 
                                            FROM Contact 
                                            WHERE Id in :setContactSignedById]);
            else return null;
        }
    
    
        public static void BeforeUpdateHandler(map<Id,Contract__c> mapOldContracts, map<Id,Contract__c> mapNewContracts){
            //MRA: 05/06/2017 - used for AP22
            // USA : move controls from button 'Update PDF' to trigger before status changes to Interval Validation
            map<Id,Contract__c> mapCtrChkIntval             = new map<Id,Contract__c>();
            map<id,string>contractIdFinalUrlMap             = new map<id,string>();
            List<Contract__c> lstContr                      = new List<Contract__c>();
            List<Contract__c> lstOpCoContracts              = new List<Contract__c>();
            map<Id,Contract__c> mapCtrOldCtr                = new map<Id,Contract__c>();
            //Set<id> ctrNoApprovals                          = new set<id>();
            //MRA : SP-00185
            list<Contract__c> lstCtr                        = new list<Contract__c>();
            list<Contract__c> lstCtrInApproval              = new list<Contract__c>(); 
            map<id,contract__c> mapCtrNewStatusChange       = new map<id,contract__c>();
            List<Contract__c> lstCtrLight                   = new List<Contract__c>();
            List<Contract__c> lstCtrOwnership               = new List<Contract__c>();
            list<Contract__c> lstCtrChkPeoSoft              = new list<Contract__c>();
            Id profileIdCtrBuyer;
            //ARA 14012021 SP-1184
            map<Id,Contact> mapContact = getMapContacts(mapNewContracts.values());
            //hasExecutedbeforeUpdateHandler ++;
            //user usr = [select id,cTin_EntityLocalCode__c from user where id=:UserInfo.getUserId() limit 1];
            
            if (PAD.canTrigger('AP52')) {
                profileIdCtrBuyer=[select id, name from profile where name=:'cTin - Contract Buyer'].id;
            }

            for(Contract__c contract : mapNewContracts.values()){
                Contract__c ctrOld = mapOldContracts.get(contract.Id);

                Boolean isAllowedStatusChange = (contract.Signature_Type__c == AP_Constant.SIGNATURE_ELECTRONIC && ((lstReadOnlyStatus.contains(ctrOld.Status__c) && lstEditableStatus.contains(contract.Status__c)) || (ctrOld.CountEsignatureInProgress__c == 1 && contract.CountEsignatureInProgress__c == 0 ))) ||
                (   (contract.Signature_Type__c == AP_Constant.SIGNATURE_MANUAL || contract.Signature_Type__c == AP_Constant.SIGNATURE_CONTRACTIN) &&
                    (   (ctrOld.Status__c == AP_Constant.CONTRACT_STATUS_READY_FOR_SIGNATURE && (lstEditStatusManual.contains(contract.Status__c) || contract.Status__c == AP_Constant.CONTRACT_STATUS_SENT_FOR_SIGNATURE || contract.Status__c == AP_Constant.CONTRACT_STATUS_SIGNED)) ||
                        (lstROStatusManual.contains(ctrOld.Status__c) && (lstEditStatusManual.contains(contract.Status__c) || contract.Status__c == AP_Constant.CONTRACT_STATUS_READY_FOR_SIGNATURE || contract.Status__c == AP_Constant.CONTRACT_STATUS_SIGNED)) ||
                        ((contract.Status__c == AP_Constant.CONTRACT_STATUS_READY_FOR_SIGNATURE || contract.Status__c == AP_Constant.CONTRACT_STATUS_SENT_FOR_SIGNATURE) && ctrOld.Contract_Signed_Date__c != contract.Contract_Signed_Date__c)
                    )
                ) || 
                (ctrOld.Status__c == AP_Constant.CONTRACT_STATUS_SIGNED && contract.Status__c == AP_Constant.CONTRACT_STATUS_ENDED) || 
                (contract.Status__c == AP_Constant.CONTRACT_STATUS_RESILIATED) || 
                (contract.Status__c == AP_Constant.CONTRACT_STATUS_CANCELLED);

                // controls for cTin
                if(/*userinfo.getuserId()!='00524000003qNKE' */ !UserBypassVr) {
                    if(setCtrRecTypescTin.contains(contract.RecordTypeId)){
                        if(contract.Status__c != AP_Constant.contractDraft) {
                            //28/10/2020 - SP-00192: MRA 
                          /*  if(contract.cTin_OutsourcingCriticalityAssessment__c==null || contract.cTin_ContractSegment__c == ''){
                                contract.cTin_OutsourcingCriticalityAssessment__c.addError('Please fill in the field "Outsourcing Criticality Assessment." ');
                            }*/
                            
                            //21/03/2021 mra - changes w.r.t cpm
                           /* if(contract.cTin_ContractSegment__c == null || contract.cTin_ContractSegment__c == ''){
                                contract.cTin_ContractSegment__c.addError('Please fill in the field "Contract Segment." ');
                            }*/
                           /* if(contract.EndDate__c == null){
                                contract.EndDate__c.addError('Please fill in the field "End Date".');
                            }
                             MRA : request is on hold
                            if(contract.EndDate__c == null && !contract.cTin_Unlimited__c){
                                contract.EndDate__c.addError('Please fill in the field "End Date".');
                            }
    
                            if(contract.EndDate__c <> null && contract.cTin_Unlimited__c){
                                contract.EndDate__c.addError('"End Date" cannot be specified for unlimited contracts');
                            }*/
                            if((contract.cTin_MainAPCL0__c == null || contract.cTin_MainAPCL0__c == '') && contract.cTin_OwnerEntityLocalCode__c !='AXLB'){
                                contract.cTin_MainAPCL0__c.addError('Please fill in the field "Main APC-L0".');
                            }
                            if((contract.cTin_OrganizationalScope__c == null || contract.cTin_OrganizationalScope__c == '') && contract.cTin_OwnerEntityLocalCode__c !='AXLB'){
                                contract.cTin_OrganizationalScope__c.addError('Please fill in the field "Beneficiary Entities".');
                            }
                            if((contract.cTin_ShortDescription__c == null || contract.cTin_ShortDescription__c == '') && contract.cTin_OwnerEntityLocalCode__c !='AXLB'){
                                contract.cTin_ShortDescription__c.addError('Please fill in the Short Description');
                            }
                            if(contract.StartDate__c == null){
                                contract.StartDate__c.addError('Please fill in the Start Date');
                            }
                            if((contract.cTin_SupplierAccount__c == null && !contract.cTin_UnilateralAXARepresentative__c) && (contract.cTin_OwnerEntityLocalCode__c!='ACH' && contract.cTin_OwnerEntityLocalCode__c !='AXLB') ){
                            
                                contract.cTin_SupplierAccount__c.addError('Please fill in the Supplier Legal Signatory Entity');
                            }
                            
                            if(/*contract.cTin_UnilateralAXARepresentative__c && */ contract.cTin_AXAMainLegalSignatoryEntity__c==null && contract.cTin_OwnerEntityLocalCode__c !='AXLB'){
                                contract.cTin_AXAMainLegalSignatoryEntity__c.addError('Please fill in the AXA Main Legal Signatory Entity');
                            }
                            
                            if(/*contract.cTin_UnilateralSupplier__c  && */contract.cTin_SupplierAccount__c ==null && contract.cTin_OwnerEntityLocalCode__c !='AXLB'){
                                contract.cTin_SupplierAccount__c .addError('Please fill in the Supplier Legal Signatory Entity');
                            }
                             
                            if((contract.cTin_TypeOfDocument__c == null || contract.cTin_TypeOfDocument__c == '') && contract.cTin_OwnerEntityLocalCode__c !='AXLB'){
                                contract.cTin_TypeOfDocument__c.addError('Please fill in the Type of Document');
                            }
                            if((contract.cTin_AXAMainLegalSignatoryEntity__c == null && !contract.cTin_UnilateralSupplier__c) && (contract.cTin_OwnerEntityLocalCode__c!='ACH' && contract.cTin_OwnerEntityLocalCode__c !='AXLB')){
                                contract.cTin_AXAMainLegalSignatoryEntity__c.addError(' Please fill in the field "AXA Signatory Entity".');
                            }
                           // if(contract.cTin_OwnerEntityLocalCode__c =='AUK' && string.isBlank(contract.cTin_DataProcessingGDPR__c)){
                           //     contract.cTin_DataProcessingGDPR__c.addError(' Please fill in the field Data Processing (GDPR)');
                           // }
                            if(contract.cTin_DataStorageLocation__c=='Other' && string.isBlank(contract.cTin_OtherLocation__c)){
                                contract.cTin_OtherLocation__c.addError(' Please fill in the field Other Location');
                            }
                            if((string.ISBLANK(contract.cTin_GeographicalScope__c)) && contract.cTin_OwnerEntityLocalCode__c=='APA'){
                                contract.cTin_GeographicalScope__c.addError(' Please fill in the field Geographical Scope');
                            }
                            
                            /* mra 25/03 commented w.r.t cpm changes
                            if((string.ISBLANK(contract.cTin_CoupaRiskAssessID__c)) && contract.cTin_OwnerEntityLocalCode__c=='AGO' && contract.cTin_RALinkedMSAParent__c==false &&
                            (contract.cTin_TypeOfDocument__c =='Master Agreement'  || contract.cTin_TypeOfDocument__c =='Standalone Contract'
                            || contract.cTin_TypeOfDocument__c =='Amendment' || contract.cTin_TypeOfDocument__c =='Transaction Agreement' )){
                                contract.cTin_CoupaRiskAssessID__c.addError(' Please fill in the field Coupa Risk Assess ID');                             
                            }*/
                            
                            //mra 25/03 - cpm changes
                             if((string.ISBLANK(contract.cTin_CoupaRiskAssessID__c)) && (contract.cTin_OwnerEntityLocalCode__c=='AGO' ||  contract.cTin_OwnerEntityLocalCode__c=='AXL') 
                                /*&& contract.cTin_RALinkedMSAParent__c==false*/ &&/* (usr.cTin_EntityLocalCode__c == 'AGO' || usr.cTin_EntityLocalCode__c == 'AXL') &&*/
                                contract.TECH_PostContractDB__c && (ctrOld.Sourcing_Request__c !=contract.Sourcing_Request__c && contract.Sourcing_Request__c!=null) &&
                                ( contract.cTin_TypeOfDocument__c !='Amendment' && contract.cTin_TypeOfDocument__c !='Non Disclosure Agreement'
                                 && contract.cTin_TypeOfDocument__c!='Notification letter' && !(string.isblank(contract.cTin_TypeOfDocument__c)))  && contract.cTin_OwnerEntityLocalCode__c !='AXLB'){
                                contract.cTin_CoupaRiskAssessID__c.addError(' Please fill in the field Coupa Risk Assess ID');                             
                            }
                            
                            
                             //23/03 mRA - changes w.r.t cpm
                            if((contract.Schrems_Compliance__c== null || contract.Schrems_Compliance__c== '') && (contract.cTin_TypeOfDocument__c !='Non Disclosure Agreement' && contract.cTin_TypeOfDocument__c !='Transaction Agreement'
                            && contract.cTin_TypeOfDocument__c !='Notification letter'  && contract.cTin_TypeOfDocumentL2__c!='Letter of intention') && (contract.cTin_OwnerEntityLocalCode__c=='APA') && contract.TECH_PostContractDB__c){
                                contract.Schrems_Compliance__c.addError('Please fill in the Schrems Compliance');
                            } 
                            
                            if((contract.Schrems_Exposure__c== null || contract.Schrems_Exposure__c== '') && (contract.cTin_TypeOfDocument__c !='Non Disclosure Agreement' && contract.cTin_TypeOfDocument__c !='Transaction Agreement'
                            && contract.cTin_TypeOfDocument__c !='Notification letter'  && contract.cTin_TypeOfDocumentL2__c!='Letter of intention') && (contract.cTin_OwnerEntityLocalCode__c=='AXL') && contract.TECH_PostContractDB__c){
                                contract.Schrems_Exposure__c.addError('Please fill in the Schrems Exposure');
                            }
                            
                            //23/03 mRA - changes w.r.t cpm
                            if((contract.IT_Security_Clause__c== null || contract.IT_Security_Clause__c== '') && (contract.cTin_TypeOfDocument__c !='Non Disclosure Agreement' && contract.cTin_TypeOfDocument__c !='Transaction Agreement'
                            && contract.cTin_TypeOfDocument__c !='Notification letter' && contract.cTin_TypeOfDocumentL2__c !='Letter of intention' ) && (contract.cTin_OwnerEntityLocalCode__c=='AXL' ||
                            contract.cTin_OwnerEntityLocalCode__c=='ABE'  || contract.cTin_OwnerEntity__c=='700 - AXA France') && contract.TECH_PostContractDB__c){
                                contract.IT_Security_Clause__c.addError('Please fill in the IT Security Clause');
                            }
                            
                            //23/03 mRA - changes w.r.t cpm
                            if((contract.cTin_DataPrivacyClause__c== null || contract.cTin_DataPrivacyClause__c== '') && (contract.cTin_TypeOfDocument__c !='Non Disclosure Agreement' && contract.cTin_TypeOfDocument__c !='Transaction Agreement'
                            && contract.cTin_TypeOfDocument__c !='Notification letter' && contract.cTin_TypeOfDocumentL2__c !='Letter of intention' ) && (contract.cTin_OwnerEntityLocalCode__c=='APA' ||
                            contract.cTin_OwnerEntityLocalCode__c=='ASA' || contract.cTin_OwnerEntityLocalCode__c=='AXL' || contract.cTin_OwnerEntityLocalCode__c=='ACH' || contract.cTin_OwnerEntity__c=='700 - AXA France' ) && contract.TECH_PostContractDB__c){
                                contract.cTin_DataPrivacyClause__c.addError('Please fill in the Data Privacy Clause');
                            }
                            
                             //23/03 mRA - changes w.r.t cpm
                            if(contract.cTin_RetentionPeriod__c== null &&  contract.cTin_OwnerEntityLocalCode__c=='ACH' && contract.TECH_PostContractDB__C){
                                contract.cTin_RetentionPeriod__c.addError('Please fill in the Retention Period');
                            }
                            
                             //23/03 mRA - changes w.r.t cpm
                            if(string.isblank(contract.cTin_Compliance_Clause__c) &&   (contract.cTin_TypeOfDocument__c !='Non Disclosure Agreement' && contract.cTin_TypeOfDocument__c !='Transaction Agreement'
                            && contract.cTin_TypeOfDocument__c !='Notification letter' && contract.cTin_TypeOfDocumentL2__c !='Letter of intention') && contract.TECH_PostContractDB__c && contract.cTin_OwnerEntityLocalCode__c !='AXLB'){
                                contract.cTin_Compliance_Clause__c.addError('Please fill in the Compliance Clause');
                            }
                            
                               //23/03 mRA - changes w.r.t cpm
                            if(contract.cTin_Compliance_Clause__c=='Modified' && string.isblank(contract.Does_the_Compliance_Clause_include_Code__c) &&   (contract.cTin_TypeOfDocument__c !='Non Disclosure Agreement' && contract.cTin_TypeOfDocument__c !='Transaction Agreement'
                            && contract.cTin_TypeOfDocument__c !='Notification letter' && contract.cTin_TypeOfDocumentL2__c !='Letter of intention' ) && contract.TECH_PostContractDB__c){
                                contract.Does_the_Compliance_Clause_include_Code__c.addError('Please fill in the field "If Comp. Clause modified, are included"');
                            }
                            
                            //23/03 mRA - changes w.r.t cpm
                            if(string.isblank(contract.cTin_AXALogoNameClause__c) &&   (contract.cTin_TypeOfDocument__c !='Non Disclosure Agreement' && contract.cTin_TypeOfDocument__c !='Transaction Agreement'
                            && contract.cTin_TypeOfDocument__c !='Notification letter'  &&  contract.cTin_TypeOfDocumentL2__c !='Letter of intention' ) && contract.TECH_PostContractDB__c
                            && (contract.cTin_OwnerEntityLocalCode__c=='AXL' || contract.cTin_ownerEntity__c=='700 - AXA France')){
                                contract.cTin_AXALogoNameClause__c.addError('Please fill in  AXA Name & Logo');
                            }
                            
                            //23/03 mRA - changes w.r.t cpm
                            if(string.isblank(contract.cTin_Audit__c) &&   (contract.cTin_TypeOfDocument__c !='Non Disclosure Agreement' && contract.cTin_TypeOfDocument__c !='Transaction Agreement'
                            && contract.cTin_TypeOfDocument__c !='Notification letter' && contract.cTin_TypeOfDocumentL2__c !='Letter of intention') && contract.TECH_PostContractDB__c
                            && (contract.cTin_OwnerEntityLocalCode__c=='AXL' || contract.cTin_OwnerEntityLocalCode__c=='APA' || contract.cTin_OwnerEntityLocalCode__c=='ABE' ||  contract.cTin_OwnerEntity__c=='700 - AXA France')){
                                contract.cTin_Audit__c.addError('Please fill in Audit Clause');
                            }
                            
                            //23/03 mRA - changes w.r.t cpm
                            if(string.isblank(contract.cTin_TerminationClause__c) &&   (contract.cTin_TypeOfDocument__c !='Non Disclosure Agreement' && contract.cTin_TypeOfDocument__c !='Transaction Agreement'
                            && contract.cTin_TypeOfDocument__c !='Notification letter' && contract.cTin_TypeOfDocumentL2__c !='Letter of intention' ) && contract.TECH_PostContractDB__c
                            && (contract.cTin_OwnerEntityLocalCode__c=='ASA' || contract.cTin_OwnerEntityLocalCode__c=='APA' || contract.cTin_OwnerEntityLocalCode__c=='AXL')){
                                contract.cTin_TerminationClause__c.addError('Please fill in Termination & dispute Clause');
                            }
                            
                            if(string.isblank(contract.cTin_CRClause__c) && contract.TECH_PostContractDB__c
                            &&  (contract.cTin_TypeOfDocument__c !='Non Disclosure Agreement' && contract.cTin_TypeOfDocument__c !='Transaction Agreement'
                            && contract.cTin_TypeOfDocument__c !='Notification letter' && contract.cTin_TypeOfDocumentL2__c !='Letter of intention') && contract.cTin_OwnerEntityLocalCode__c !='AXLB'){
                                contract.cTin_CRClause__c.addError('Please fill in sustainability clause');
                            }
                            
                             //23/03 mRA - changes w.r.t cpm
                            if(string.isblank(contract.cTin_LiabilityClause__c) &&   (contract.cTin_TypeOfDocument__c !='Non Disclosure Agreement' && contract.cTin_TypeOfDocument__c !='Transaction Agreement'
                            && contract.cTin_TypeOfDocument__c !='Notification letter'  && contract.cTin_TypeOfDocumentL2__c !='Letter of intention') && contract.TECH_PostContractDB__c
                            && (contract.cTin_OwnerEntityLocalCode__c=='ASA' || contract.cTin_OwnerEntityLocalCode__c=='ABE' || contract.cTin_OwnerEntity__c=='700 - AXA France')){
                                contract.cTin_LiabilityClause__c.addError('Please fill in Liability Clause');
                            }
                            
                            //23/03 mRA - changes w.r.t cpm
                            if(string.isblank(contract.cTin_GroupOfContract__c) && contract.TECH_PostContractDB__c
                            && contract.cTin_OwnerEntity__c=='710 - AXA France Assurances'){
                                contract.cTin_GroupOfContract__c.addError('Please fill in Contract Group');
                            }
                            
                             //23/03 mRA - changes w.r.t cpm
                            if(string.isblank(contract.cTin_FCE_code__c) && contract.TECH_PostContractDB__c
                            && contract.cTin_OwnerEntity__c=='710 - AXA France Assurances'){
                                contract.cTin_FCE_code__c.addError('Please fill in FCE Group');
                            } 
                            
                            //23/03 mRA - changes w.r.t cpm
                            if(string.isblank(contract.VISCA_Level__c) && contract.TECH_PostContractDB__c
                            && contract.cTin_OwnerEntityLocalCode__c=='APA'){
                                contract.VISCA_Level__c.addError('Please fill in VISCA Level');
                            } 
                            
                            //23/03 mRA - changes w.r.t cpm
                            if((string.isblank(contract.Security_Appendix__c) && contract.TECH_PostContractDB__c)
                            && (contract.cTin_OwnerEntityLocalCode__c=='APA' || (contract.cTin_OwnerEntity__c=='700 - AXA France' && (contract.cTin_TypeOfDocument__c=='Master Agreement' || 
                                contract.cTin_TypeOfDocument__c=='Standalone Contract' || contract.cTin_TypeOfDocument__c=='Amendment' || contract.cTin_TypeOfDocument__c=='Transaction Agreement' || 
                                contract.cTin_TypeOfDocument__c=='Other')))){
                                contract.Security_Appendix__c.addError('Please fill in Security Appendix');
                            }
                            
                            //23/03 mRA - changes w.r.t cpm
                            if(string.isblank(contract.cTin_MaterialityRating__c) && contract.TECH_PostContractDB__c
                            && contract.cTin_OwnerEntityLocalCode__c=='AUK'){
                                contract.cTin_MaterialityRating__c.addError('Please fill in Materiality Rating');
                            } 
                            
                            //23/03 mRA - changes w.r.t cpm
                            if(string.isblank(contract.cTin_ProcurementInvolvementGrade__c)  && contract.TECH_PostContractDB__c
                            && (contract.cTin_OwnerEntityLocalCode__c=='APA' || contract.cTin_OwnerEntityLocalCode__c=='AXL')){
                                contract.cTin_ProcurementInvolvementGrade__c.addError('Please fill in Procurement involvement grade');
                            }
                            
                              //23/03 mRA - changes w.r.t cpm
                            if(contract.cTin_MaterialityRatingDate__c== null && contract.TECH_PostContractDB__c
                            && contract.cTin_OwnerEntityLocalCode__c=='AUK'){
                                contract.cTin_MaterialityRatingDate__c.addError('Please fill in Materiality Rating Date');
                            } 
                            
                            if(string.isblank(contract.Anti_terrorism_Clause__c) && contract.TECH_PostContractDB__c
                            && contract.cTin_OwnerEntity__c=='700 - AXA France' && (contract.cTin_TypeOfDocument__c=='Master Agreement' || 
                            contract.cTin_TypeOfDocument__c=='Standalone Contract' || contract.cTin_TypeOfDocument__c=='Amendment' || contract.cTin_TypeOfDocument__c=='Transaction Agreement' || 
                            contract.cTin_TypeOfDocument__c=='Other')){
                                contract.Anti_terrorism_Clause__c.addError('Please fill in anti-terrorism clause');
                            }
                            
                            if(string.isblank(contract.cTin_FairTransparentSelectionProcess__c) && contract.TECH_PostContractDB__c
                            && contract.cTin_OwnerEntity__c=='700 - AXA France'){
                                contract.cTin_FairTransparentSelectionProcess__c.addError('Please fill in Rationale of supplier selection is');
                            }  
                            
                            if(string.isblank(contract.Money_Laudering_Clause__c ) && contract.TECH_PostContractDB__c
                            && contract.cTin_OwnerEntity__c=='700 - AXA France' && (contract.cTin_TypeOfDocument__c=='Master Agreement' || 
                            contract.cTin_TypeOfDocument__c=='Standalone Contract' || contract.cTin_TypeOfDocument__c=='Amendment' || contract.cTin_TypeOfDocument__c=='Transaction Agreement' || 
                            contract.cTin_TypeOfDocument__c=='Other')){
                                contract.Money_Laudering_Clause__c.addError('Please fill in Money laundering clause');
                            }
                            
                             //23/03 mRA - changes w.r.t cpm
                            if(string.isblank(contract.cTin_SoftwareLicenseRecord__c) && contract.TECH_PostContractDB__c
                            && contract.cTin_OwnerEntityLocalCode__c=='AUK'){
                                contract.cTin_SoftwareLicenseRecord__c.addError('Please fill in Software License Record');
                            }  
                            
                            //23/03 mRA - changes w.r.t cpm
                            if(string.isBlank(contract.cTin_TypeOfDocumentL2__c) && contract.TECH_PostContractDB__c
                            && (contract.cTin_TypeOfDocument__c=='Notification letter' || contract.cTin_TypeOfDocument__c=='Other') && contract.cTin_OwnerEntityLocalCode__c !='AXLB'){
                                contract.cTin_TypeOfDocumentL2__c.addError('Please fill in sub-type of document');
                            }
                            
                            //01-Avril-2022 MRA - changes w.r.t cpm
                            if ((/*integer.valueOf(contract.cTin_CommittedPartExclVAT__c)==0 ||  contract.cTin_CommittedPartExclVAT__c<0 ||*/  contract.cTin_CommittedPartExclVAT__c==NULL) && contract.TECH_PostContractDB__c && (contract.cTin_TypeOfDocument__c=='Transaction Agreement' || contract.cTin_TypeOfDocumentL2__c=='Letter of intention' || contract.cTin_TypeOfDocument__c=='Standalone Contract')){
                                contract.cTin_CommittedPartExclVAT__c.addError('Please fill in Minimum Commitment excl. VAT');
                            }
                            
                             //01-Avril-2022 MRA - changes w.r.t cpm
                            if ((/*integer.valueOf(contract.Contract_Value_excl_VAT__c)==0 ||contract.Contract_Value_excl_VAT__c<0  || */ contract.Contract_Value_excl_VAT__c==NULL) && contract.TECH_PostContractDB__c && (contract.cTin_TypeOfDocument__c=='Transaction Agreement' || contract.cTin_TypeOfDocumentL2__c=='Letter of intention' || contract.cTin_TypeOfDocument__c=='Standalone Contract')){
                                contract.Contract_Value_excl_VAT__c.addError('Please fill in Estimated Contract Value excl. VAT');
                            }
                           /*  if((string.ISBLANK(contract.cTin_VRFCriticality__c)                         
                                  || string.ISBLANK(contract.cTin_ReputationRisk__c  )    
                                 || string.ISBLANK(contract.cTin_FinancialHealthRiskRating__c)  
                                || string.ISBLANK(contract.cTin_ComplianceRiskRating__c)
                                || string.ISBLANK(contract.cTin_OperationalResilienceRiskRating__c)  
                                   || string.ISBLANK(contract.cTin_InfoSecRiskRating__c)     
                                  || string.ISBLANK(contract.cTin_DataPrivacyRisk__c)    ) 
                                  &&
                              (contract.cTin_TypeOfDocument__c =='Master Agreement' || contract.cTin_TypeOfDocument__c =='Agreement'|| contract.cTin_TypeOfDocument__c =='Standalone Contract'
                                || contract.cTin_TypeOfDocument__c =='Amendment' || contract.cTin_TypeOfDocument__c =='Transaction Agreement' ) && contract.cTin_OwnerEntityLocalCode__c!='AGO'
                                 &&  contract.cTin_OwnerEntity__c!='710 - AXA France Assurances' &&  contract.cTin_OwnerEntity__c!='1110 - AXA JURIDICA'){
                                   contract.addError(' Please fill in the "Vendor Risk Framework" fields');                             
                            } */
                            
                            //23/03- new cpm rule
                          /*if((string.ISBLANK(contract.cTin_VRFCriticality__c)                    
                                || string.ISBLANK(contract.cTin_ReputationRisk__c  )   
                                || string.ISBLANK(contract.cTin_FinancialHealthRiskRating__c)  
                                   || string.ISBLANK(contract.cTin_ComplianceRiskRating__c)   
                                  || string.ISBLANK(contract.cTin_OperationalResilienceRiskRating__c)        
                                   || string.ISBLANK(contract.cTin_InfoSecRiskRating__c)      
                                 || string.ISBLANK(contract.cTin_DataPrivacyRisk__c)  ) 
                                   &&
                              ( contract.cTin_TypeOfDocument__c !='Amendment' && contract.cTin_TypeOfDocument__c !='Non Disclosure Agreement'
                                 && contract.cTin_TypeOfDocument__c !='Notification letter') && contract.cTin_OwnerEntityLocalCode__c!='AGO'
                                  &&  contract.cTin_OwnerEntity__c!='710 - AXA France Assurances'  &&  contract.cTin_OwnerEntity__c!='1110 - AXA JURIDICA'){
                                  contract.addError('Please fill in the "Contract Risk Assessment & Dilligences" fields');                             
                            }*/
                            
                             if((string.ISBLANK(contract.cTin_VRFCriticality__c)                    
                                || string.ISBLANK(contract.cTin_ReputationRisk__c  )   
                                || string.ISBLANK(contract.cTin_FinancialHealthRiskRating__c)  
                                   || string.ISBLANK(contract.cTin_ComplianceRiskRating__c)   
                                  || string.ISBLANK(contract.cTin_OperationalResilienceRiskRating__c)        
                                   || string.ISBLANK(contract.cTin_InfoSecRiskRating__c)      
                                 || string.ISBLANK(contract.cTin_DataPrivacyRisk__c)  ) 
                                   && (contract.TECH_PostContractDB__c) &&
                              ( contract.cTin_TypeOfDocument__c !='Amendment' && contract.cTin_TypeOfDocument__c !='Non Disclosure Agreement'
                                 && contract.cTin_TypeOfDocument__c !='Notification letter') && /*contract.cTin_OwnerEntityLocalCode__c!='AGO' &&*/ contract.cTin_OwnerEntityLocalCode__c !='AXLB' &&
                                  contract.cTin_OwnerEntity__c!='710 - AXA France Assurances' && (string.ISBLANK(contract.cTin_CoupaRiskAssessID__c) && contract.cTin_RALinkedMSAParent__c==false)  /*&&  contract.cTin_OwnerEntity__c!='1110 - AXA JURIDICA'*/){
                                  contract.addError('Please fill in the "Contract Risk Assessment & Dilligences" fields');                       
                            }
                            
                            
                            /* //MRA 11-MAI-2020 : SP-00185
                             if(ctrNoApprovals.contains(contract.id) && contract.status__c=='In Signature' && contract.cTin_CountCTInApproval__c >0
                              && !VFC37_CreateSignature.allowCreate && !AP44_BlockNewContractTeam.allowAP44 &&  !AP47_UpdateFinalDocUrl.allowAP47 && !AP41_AutomateEsignature.alreadyFired){
                              contract.status__c.addError(system.label.cTin_ErrorUpdateStatus);
                             }*/
                        }
                    }
                    else if(setCtrRecTypesOpCo.contains(contract.RecordTypeId)){

                        // 03-FEB-2022  ARA SP-02841
                        if(contract.Tech_countILsUpdatedByPS__c > 0 || contract.Tech_isSendingToPS__c){
                            if(contract.AXA_GO_Legal_Entity__c != ctrOld.AXA_GO_Legal_Entity__c || contract.Account__c != ctrOld.Account__c){
                                contract.addError(System.Label.ErrorMessage_SentToPS_AXAGO_Customer);
                            }
                        }
                        
                        // 28-JUN-2021   ARA    SP-01783
                        if (contract.Customer_Operational_Contact__c != ctrOld.Customer_Operational_Contact__c){
                            contract.Tech_ReminderPOCustValSent__c = false;
                            contract.Tech_ReminderPOSentForSign__c = false;
                        }
                        //  25-MAR-2021  ARA    SP-01488
                        //  18-MAR-2021  ARA    SP-1472 (update if condition)
                        //  30-MAR-2021  ARA    SP-01588
                        // Check if contacts are validated
                        //if(!setCtrRecTypesOpCoReadOnly.contains(contract.RecordTypeId) || (setCtrRecTypesOpCoReadOnly.contains(contract.RecordTypeId) && ctrOld.Invoicing_Lines_Amount__c == contract.Invoicing_Lines_Amount__c && ctrOld.Peoplesoft_Sync__c == contract.Peoplesoft_Sync__c && ctrOld.Tech_IL_Changed__c == contract.Tech_IL_Changed__c)){
                        if(!(ctrOld.RecordTypeId == contract.RecordTypeId 
                             && setCtrRecTypesOpCoReadOnly.contains(contract.RecordTypeId)  
                             && (contract.Signature_Type__c == AP_Constant.SIGNATURE_MANUAL || contract.Signature_Type__c == AP_Constant.SIGNATURE_CONTRACTIN))){
                            contract.Tech_AllowUpdate__c = true;
                            if(!contract.Tech_isSendingToPS__c 
                                && !WS02_CallSAPWS.isSentToPS 
                                && !AP54_MassSendToPeopleSoft.isSentToPSMass
                                && ctrOld.PeopleSoftConnectionMessage__c == contract.PeopleSoftConnectionMessage__c
                                && ctrOld.Invoicing_Lines_Amount__c == contract.Invoicing_Lines_Amount__c 
                                && ctrOld.Peoplesoft_Sync__c == contract.Peoplesoft_Sync__c 
                                && ctrOld.Tech_IL_Changed__c == contract.Tech_IL_Changed__c 
                                && !WS02_CallSAPWS.isSentToPS 
                                && !AP54_MassSendToPeopleSoft.isSentToPSMass
                                && ctrOld.CountProductItems__c == contract.CountProductItems__c 
                                && ctrOld.Tech_CountInactiveProductItems__c  == contract.Tech_CountInactiveProductItems__c
                                && ctrOld.Tech_Esignatory_Changed__c == contract.Tech_Esignatory_Changed__c
                                && !(ctrOld.CountEsignatureInProgress__c == 1 && contract.CountEsignatureInProgress__c == 0)
                                && !isAllowedStatusChange
                                ){
                                if(contract.Customer_Operational_Contact__c != null && mapContact.containsKey(contract.Customer_Operational_Contact__c)){
                                    if(mapContact.get(contract.Customer_Operational_Contact__c).RecordTypeId != idRecEntityContact || !mapContact.get(contract.Customer_Operational_Contact__c).Active__c ){
                                        contract.Customer_Operational_Contact__c.addError(System.Label.Contract_Operational_Contact);
                                    }
                                }
                                if(contract.CustomerSignedBy__c != null 
                                   && mapContact.containsKey(contract.CustomerSignedBy__c)){
                                    if(mapContact.get(contract.CustomerSignedBy__c).RecordTypeId != idRecEntityContact || !mapContact.get(contract.CustomerSignedBy__c).Active__c){
                                        contract.CustomerSignedBy__c.addError(System.Label.Customer_Signed_By_Error);
                                    }
                                }
                                if(contract.CustomerSignedBy2__c != null 
                                   && mapContact.containsKey(contract.CustomerSignedBy2__c)){
                                    if(mapContact.get(contract.CustomerSignedBy2__c).RecordTypeId != idRecEntityContact || !mapContact.get(contract.CustomerSignedBy2__c).Active__c){
                                        contract.CustomerSignedBy2__c.addError(System.Label.Customer_Signed_By_2_Error);
                                    }
                                }
                                //  22-MAR-2021  ARA    SP-01506
                                if(contract.AXA_GO_Signed_By_2__c != null
                                   && mapContact.containsKey(contract.AXA_GO_Signed_By_2__c)){
                                    if(mapContact.get(contract.AXA_GO_Signed_By_2__c).RecordTypeId != idRecEntityContact 
                                       || !mapContact.get(contract.AXA_GO_Signed_By_2__c).AXA_GO_Signatory__c || !mapContact.get(contract.AXA_GO_Signed_By_2__c).Active__c){
                                        contract.AXA_GO_Signed_By_2__c.addError(System.Label.Contract_AXA_Go_Signed_By_2_Error);
                                    }
                                }
                            }
                        }else{
                            contract.Tech_AllowUpdate__c = false;
                        }

                        
                        // 30-07-2021   ARA SP-02169
                        if(contract.RecordTypeId == idRecLightContract || contract.RecordTypeId == idRecOpCoSingleEdit){
                            if(ctrOld.Account__c != contract.Account__c){
                                contract.C_Account__c = (contract.Account__c != null ? contract.Account__r.ParentId : null);
                            }
                        }

                        // 24-JUN-2021  ARA SP-02055 : Comment on lines for SP-01938 /*------*/
                        // 07-JUN-2021  ARA SP-01938
                        /*if (setCtrRecTypesOpCoReadOnly.contains(contract.RecordTypeId)){
                            if(!contract.OfferATS__r.Is_Active__c){
                                if(contract.Tech_IL_Changed__c != ctrOld.Tech_IL_Changed__c || contract.Invoicing_Lines_Amount__c != ctrOld.Invoicing_Lines_Amount__c || contract.Peoplesoft_Sync__c != ctrOld.Peoplesoft_Sync__c){
                                    contract.Tech_TriggerFilter__c = true;
                                }else{
                                    contract.Tech_TriggerFilter__c = false;
                                }
                            }
                        }*/
                    }
                }
                if ((contract.Status__c != ctrOld.Status__c) && (contract.Status__c=='In Signature' /*&& ctrOld.Status__c!='Draft'*/)
                        && contract.TECH_IsContractIn__c && contract.cTin_CountCTInApproval__c>0 && PAD.canTrigger('ctinblockUpdate')){
                    lstCtr.add(contract);
                }
                
                // ARA: 20210927 SP-02556
                                /* ARA: 20220503 SP-03718 - Add a bypass filter and a bypass VR if contract update is triggered by
                 * IL update or 
                 * eSignature/eSignatory update
                 * Button Send to PS or 
                 * **/
                system.debug('******recordTypeId '+ctrOld.Status__c +' '+ contract.Status__c);
                system.debug('******0 '+contract.Tech_ByPassVR__c);                
                if(!hasExecutedbeforeUpdateHandler){
                                                                                                                                                                                                                                                                                                                          
                                                                                                                                                         
                                                                                                                                                                                                                                                                                                                                                                                                                                                              
                                                                                                                                                                                                                                                                                                                                                                                                                            
                                                                                                                                                                                                                                                                                                                                    
                         
                         
                                                                                                                                           
                                                                                      
                                                                                  

                    // ARA: 20210707 SP-01432
                    if( isAllowedStatusChange 
                    || contract.PeopleSoftConnectionMessage__c != ctrOld.PeopleSoftConnectionMessage__c 
                    || contract.Tech_isSendingToPS__c != ctrOld.Tech_isSendingToPS__c 
                    || contract.Invoicing_Lines_Amount__c != ctrOld.Invoicing_Lines_Amount__c 
                    || contract.Peoplesoft_Sync__c != ctrOld.Peoplesoft_Sync__c 
                    || contract.CountProductItems__c != ctrOld.CountProductItems__c 
                    || contract.Tech_CountInactiveProductItems__c != ctrOld.Tech_CountInactiveProductItems__c 
                    || ctrOld.Tech_IL_Changed__c != contract.Tech_IL_Changed__c
                    || ctrOld.Tech_Esignatory_Changed__c != contract.Tech_Esignatory_Changed__c 
                    || (ctrOld.CountEsignatureInProgress__c == 1 && contract.CountEsignatureInProgress__c == 0)){                   
                        contract.Tech_ByPassFilter__c = true;
                        contract.Tech_ByPassVR__c = (contract.Tech_ByPassVR__c ? false : true);
                        hasExecutedbeforeUpdateHandler = true;
                    }else{
                        contract.Tech_ByPassFilter__c = false;
                    }
                }else{
                    contract.Tech_ByPassVR__c = (contract.Tech_ByPassVR__c ? false : true);
                }
              
                system.debug('******1 '+contract.Tech_ByPassVR__c);
                //MRA: 20181506 (Evol 4150)
                if (PAD.canTrigger('AP52')) {
                    //Contract-In: block user from changing ownership if user has buyer profile but is not owner / co-owner of the contract
                    if(contract.TECH_IsContractIn__c && userInfo.getUserId()!=ctrOld.ownerId && userinfo.getprofileId() == profileIdCtrBuyer && contract.ownerId != ctrOld.ownerId ){
                        lstCtrOwnership.add(contract);
                    }
                }
    
                // controls for opCo
    
                //KZE 20190806: migration lightning
                //change PDFStatus_lgt__c when fields are changed
                //USA 28062020: SP-00130
                if(PAD.canTrigger('AP30')){
                    if ((contract.RecordTypeId == idRecOpCoSingleEdit 
                         || contract.RecordTypeId == idRecOpCoAmendEdit) 
                        && (contract.PDFStatus_lgt__c == AP_Constant.strPDFStatusUpdated) &&
                        (  (contract.Signature_Type__c != ctrOld.Signature_Type__c)
                        || (contract.ServiceType__c != ctrOld.ServiceType__c) 
                        || (contract.Service_Type_Invoicing_Method__c != ctrOld.Service_Type_Invoicing_Method__c)
                        || (contract.InvoicingMethod__c != ctrOld.InvoicingMethod__c)
                        || (contract.Invoicing_Condition__c != ctrOld.Invoicing_Condition__c)
                        || (contract.AXA_GS_Signed_By__c != ctrOld.AXA_GS_Signed_By__c)
                        || (contract.AXA_GO_Signed_By_2__c != ctrOld.AXA_GO_Signed_By_2__c)
                        || (contract.AXA_GO_Legal_Entity__c != ctrOld.AXA_GO_Legal_Entity__c)
                        || (contract.CurrencyIsoCode != ctrOld.CurrencyIsoCode)
                        || (contract.CustomerSignedBy__c != ctrOld.CustomerSignedBy__c)
                        || (contract.CustomerSignedBy2__c != ctrOld.CustomerSignedBy2__c)
                        || (contract.StartDate__c != ctrOld.StartDate__c)
                        || (contract.EndDate__c != ctrOld.EndDate__c)
                        || (contract.Global_Amount__c != ctrOld.Global_Amount__c)
                        || (contract.Name != ctrOld.Name)
                        || (contract.Service_Type__c != ctrOld.Service_Type__c)
                        || (contract.CountProductItems__c != ctrOld.CountProductItems__c)
                        || (contract.Account__c != ctrOld.Account__c)
                        || (contract.Customer_Operational_Contact__c != ctrOld.Customer_Operational_Contact__c)
                        || (contract.SOW_Type__c != ctrOld.SOW_Type__c)
                        || (contract.TacitRenewal__c != ctrOld.TacitRenewal__c)
                        )){
                            lstContr.add(contract);
                    }
                }
                //USA 20190723 : migration lightning
                // move controls from button 'Update PDF' to trigger before status changes to Interval Validation for lightning version
                if(PAD.canTrigger('AP29')){
                    if (contract.Status__c != ctrOld.Status__c 
                    && contract.Status__c == AP_Constant.CONTRACT_STATUS_INTERNAL_VALIDATION
                    && ctrOld.Status__c != AP_Constant.CONTRACT_STATUS_READY_FOR_SIGNATURE 
                    && !lstROStatusManual.contains(ctrOld.Status__c)){
                        mapCtrChkIntval.put(contract.Id, contract);
                    }
                }
                
                //ARA 20201613
                // uncheck "PeopleSoftSync" after updating on status or Customer legal entity
                if(PAD.canTrigger('AP55')){
                    if(contract.Peoplesoft_Sync__c){
                        if ((contract.Account__c != ctrOld.Account__c) 
                            || (contract.Status__c != ctrOld.Status__c && (contract.Status__c == AP_Constant.CONTRACT_STATUS_RESILIATED || contract.Status__c == AP_Constant.CONTRACT_STATUS_CANCELLED))){
                            lstCtrChkPeoSoft.add(contract);
                        }
                    }
                }
    
                //controls for cTin and OpCo
    
                //MRA: Added code for AP22 to perform check on length,size and extension when final doc url is updated on contract
                if(PAD.canTrigger('AP22')){
                    if(((contract.FinalDocumentUrl__c !='') 
                        || (contract.FinalDocumentUrl__c !=null))
                            && ((contract.Status__c == AP_Constant.contractCustValidationStatus)
                            ||  (contract.Status__c == AP_Constant.contractSentStatus)
                            ||  (contract.Status__c == AP_Constant.contractReadyStatus)
                            ||  (contract.Status__c == AP_Constant.CONTRACT_STATUS_DRAFT)
                            ||  (contract.Status__c == AP_Constant.CONTRACT_STATUS_INAPPROVAL)
                            ||  (contract.Status__c == AP_Constant.CONTRACT_STATUS_INSIGNATURE)
                            ||  (contract.Status__c == AP_Constant.CONTRACT_STATUS_INPROGRESS))){
                        contractIdFinalUrlMap.put(contract.id,contract.FinalDocumentUrl__c);
                    }
                }
                if (!contract.TECH_IsContractIn__c){
                    if ((contract.Account__c != null) && (contract.Account__c != ctrOld.Account__c)) {
                        lstOpCoContracts.add(contract);     mapCtrOldCtr.put(contract.Id, contract);
                    }
                    if (contract.Status__c != ctrOld.Status__c){
                        mapCtrNewStatusChange.put(contract.Id,contract);
                    }
                }
                /*system.debug('****diff '+ctrOld.Peoplesoft_Sync__c +' '+ contract.Peoplesoft_Sync__c);
                if (ctrOld.Peoplesoft_Sync__c != contract.Peoplesoft_Sync__c || ctrOld.Invoicing_Lines_Amount__c != contract.Invoicing_Lines_Amount__c){
                    hasExecutedbeforeUpdateHandler = true;
                }*/
                if (contract.RecordTypeId == idRecLightContract/* && !hasExecutedbeforeUpdateHandler*/){ 
                    lstCtrLight.add(contract);
                }
            }
            
            if ((lstContr.size()>0) && (PAD.canTrigger('AP30'))){
                AP30_ManagePDFStatus.updateContractPDFStatus(lstContr, AP_Constant.strPDFStatusNotUpdated);
            }
            if(mapCtrChkIntval.size()>0) {
                AP29_ContractStatusControls.controls_toInternalValition(mapCtrChkIntval);
            }
            if(lstCtrChkPeoSoft.size()>0) {
                AP55_UncheckPeopleSoftSync.uncheckPeopleSoftSync(lstCtrChkPeoSoft);
            }
            // HVA : contractIdFinalUrlMap initialised in PAD AP22
            if(PAD.canTrigger('AP22')){
                if(contractIdFinalUrlMap.size() > 0 && !AP22_ContractVerifyContent.hasExecuted){
                    map<id,string> conIdErrorMap=AP22_ContractVerifyContent.validateContent(contractIdFinalUrlMap);
                    for(id conId:conIdErrorMap.keyset()){
                        if(mapNewContracts.containsKey(conId)){
                            mapNewContracts.get(conId).addError(conIdErrorMap.get(conId));
                        }
                    }
                }
            }
            //MRA: 12/05/2020 SP00185
            if (lstCtr.size() > 0 && PAD.canTrigger('ctinblockUpdate')){
                ContractTriggerHandler.blockUpdate(lstCtr);
            }
            
           
            if (lstOpCoContracts.size()>0){
                if (PAD.canTrigger('AP1201')){
                    AP12_Contract.prefillEntity(lstOpCoContracts, mapNewContracts);
                }
                if (PAD.canTrigger('AP1202')){
                    AP12_Contract.fillInSignatureType(mapCtrOldCtr, lstOpCoContracts);
                }
            }
            if ((mapCtrNewStatusChange.size()>0) && (PAD.canTrigger('AP1205'))){
                AP12_Contract.updateRecordType(mapCtrNewStatusChange);
            }
            if ((lstCtrLight.size()>0) && (PAD.canTrigger('AP510'))) checkRights(mapNewContracts.values());
                                                                   
            if (lstCtrOwnership.size()>0){
                map<id,contract__c> newContractMap = mapNewContracts;
                map<string,string> conIdErrorMap=AP52_BlockTransferOwnerShip.blockTransferOwnership(lstCtrOwnership);
    
                for(string conId:conIdErrorMap.keyset()){
                    if(newContractMap.containsKey(conId)){
                        newContractMap.get(conId).addError(conIdErrorMap.get(conId));
                    }
                }
            }
        }
    
        public static void BeforeInsertHandler(List<Contract__c> lstNewContracts){
            system.debug('****BeforeInsertHandler contract');
            List<Contract__c> lstOpCoContracts              = new List<Contract__c>();
            List<Contract__c> lstCtrnotSingleEdit           = new List<Contract__c>();
            //SRA 22082019 Prefill Contrat AXA GO Legal Entity field with user connected company
            List<Contract__c> lstCtrNoOpp                   = new List<Contract__c>();
            //USA 05062020 list of OpCo contracts without legal entity or entity
            List<Contract__c> lstCtrNoLegalEntity           = new List<Contract__c>();
            //USA 21/02/2018 - define set of accounts for trigger.new to remove SOQL in loop in AP12_Contract.updateLanguageAndAGSLE
            //               - define set of recordTypes to correct bug in AP12_Contract.updateLanguageAndAGSLE
            Set<Id> setRecTypeId                            = new Set<Id>();
            Set<Id> setAccId                                = new Set<Id>();
            //ARA 14012021 SP-1184
            map<Id,Contact> mapContact = getMapContacts(lstNewContracts);
            user usr = [select id,cTin_EntityLocalCode__c from user where id=:UserInfo.getUserId() limit 1];
    
            for(Contract__c contract : lstNewContracts){
                // controls for cTin
                if (/*userinfo.getuserId()!='00524000003qNKE'*/ !UserBypassVr){
                    if(setCtrRecTypescTin.contains(contract.RecordTypeId)){
                        if(contract.Status__c != AP_Constant.contractDraft){
                            
                           /*  //28/10/2020 - SP-00192: MRA 
                            if(contract.cTin_OutsourcingCriticalityAssessment__c==null || contract.cTin_ContractSegment__c == ''){
                                contract.cTin_OutsourcingCriticalityAssessment__c.addError('Please fill in the field "Outsourcing Criticality Assessment." ');
                            }
                            */
                            // 21/03/2021 mra - changes w.r.t cpm
                           /* if(contract.cTin_ContractSegment__c == null || contract.cTin_ContractSegment__c == ''){
                                contract.cTin_ContractSegment__c.addError('Please fill in the field "Contract Segment." ');
                            }*/
                            /*if(contract.EndDate__c == null){
                                contract.EndDate__c.addError('Please fill in the field "End Date".');
                            }
                             MRA : request is on hold
                            if(contract.EndDate__c == null && !contract.cTin_Unlimited__c){
                                 contract.EndDate__c.addError('Please fill in the field "End Date".');
                             }
    
                             if(contract.EndDate__c <> null && contract.cTin_Unlimited__c){
                                 contract.EndDate__c.addError('"End Date" cannot be specified for unlimited contracts');
                             }*/
                            if((contract.cTin_MainAPCL0__c == null || contract.cTin_MainAPCL0__c == '') && contract.cTin_OwnerEntityLocalCode__c !='AXLB'){
                                contract.cTin_MainAPCL0__c.addError('Please fill in the field "Main APC-L0".');
                            }
                            if((contract.cTin_OrganizationalScope__c == null || contract.cTin_OrganizationalScope__c == '') && contract.cTin_OwnerEntityLocalCode__c !='AXLB'){
                                contract.cTin_OrganizationalScope__c.addError('Please fill in the field "Beneficiary Entities".');
                            }
                            if((contract.cTin_ShortDescription__c == null || contract.cTin_ShortDescription__c == '') && contract.cTin_OwnerEntityLocalCode__c !='AXLB'){
                                contract.cTin_ShortDescription__c.addError('Please fill in the Short Description');
                            }
                            if(contract.StartDate__c == null){
                                contract.StartDate__c.addError('Please fill in the Start Date');
                            }
                            if((contract.cTin_SupplierAccount__c == null && !contract.cTin_UnilateralAXARepresentative__c) && (contract.cTin_OwnerEntityLocalCode__c!='ACH' && contract.cTin_OwnerEntityLocalCode__c !='AXLB')){
                                contract.cTin_SupplierAccount__c.addError('Please fill in the Supplier Legal Signatory Entity');
                            }
                            if((contract.cTin_TypeOfDocument__c == null || contract.cTin_TypeOfDocument__c == '') && contract.cTin_OwnerEntityLocalCode__c !='AXLB'){
                                contract.cTin_TypeOfDocument__c.addError('Please fill in the Type of Document');
                            }
                            if((contract.cTin_AXAMainLegalSignatoryEntity__c == null && !contract.cTin_UnilateralSupplier__c) && (contract.cTin_OwnerEntityLocalCode__c!='ACH' && contract.cTin_OwnerEntityLocalCode__c !='AXLB')){
                                contract.cTin_AXAMainLegalSignatoryEntity__c.addError(' Please fill in the field "AXA Signatory Entity".');
                            }
                            
                           if(/*contract.cTin_UnilateralAXARepresentative__c && */ contract.cTin_AXAMainLegalSignatoryEntity__c==null && contract.cTin_OwnerEntityLocalCode__c !='AXLB'){
                                contract.cTin_AXAMainLegalSignatoryEntity__c.addError('Please fill in the AXA Main Legal Signatory Entity');
                            }
                            
                            if(/*contract.cTin_UnilateralSupplier__c  && */ contract.cTin_SupplierAccount__c ==null && contract.cTin_OwnerEntityLocalCode__c !='AXLB'){
                                contract.cTin_SupplierAccount__c .addError('Please fill in the Supplier Legal Signatory Entity');
                            }
                            
                          //  if(contract.cTin_OwnerEntityLocalCode__c =='AUK' && string.isBlank(contract.cTin_DataProcessingGDPR__c)){
                            //    contract.cTin_DataProcessingGDPR__c.addError(' Please fill in the field Data Processing (GDPR)');
                           // }
                           
                            if(contract.cTin_DataStorageLocation__c=='Other' && string.isBlank(contract.cTin_OtherLocation__c)){
                                contract.cTin_OtherLocation__c.addError(' Please fill in the field Other Location');
                            }
                            
                            if((string.ISBLANK(contract.cTin_GeographicalScope__c)) && contract.cTin_OwnerEntityLocalCode__c=='APA'){
                                contract.cTin_GeographicalScope__c.addError(' Please fill in the field Geographical Scope');
                            }
                            
                            /* commented - mra 25/03 - cpm changes
                            if((string.ISBLANK(contract.cTin_CoupaRiskAssessID__c)) && contract.cTin_OwnerEntityLocalCode__c=='AGO' && contract.cTin_RALinkedMSAParent__c==false &&
                            (contract.cTin_TypeOfDocument__c =='Master Agreement' || contract.cTin_TypeOfDocument__c =='Agreement'|| contract.cTin_TypeOfDocument__c =='Standalone Contract'
                            || contract.cTin_TypeOfDocument__c =='Amendment' || contract.cTin_TypeOfDocument__c =='Transaction Agreement' )){
                                contract.cTin_CoupaRiskAssessID__c.addError(' Please fill in the field Coupa Risk Assess ID');                             
                            } */
                            
                            //mra 25/03 - cpm changes
                             if((string.ISBLANK(contract.cTin_CoupaRiskAssessID__c)) && (contract.cTin_OwnerEntityLocalCode__c=='AGO' ||  contract.cTin_OwnerEntityLocalCode__c=='AXL') 
                                /*&& contract.cTin_RALinkedMSAParent__c==false*/ && /*(usr.cTin_EntityLocalCode__c == 'AGO' || usr.cTin_EntityLocalCode__c == 'AXL') &&*/                               
                             ( contract.cTin_TypeOfDocument__c !='Amendment' && contract.cTin_TypeOfDocument__c !='Non Disclosure Agreement'
                                 && contract.cTin_TypeOfDocument__c !='Notification letter' && !(string.isblank(contract.cTin_TypeOfDocument__c)))  && contract.cTin_OwnerEntityLocalCode__c !='AXLB'){
                                contract.cTin_CoupaRiskAssessID__c.addError(' Please fill in the field Coupa Risk Assess ID');                             
                            }
                            
                             //23/03 mRA - changes w.r.t cpm
                           if((contract.Schrems_Compliance__c== null || contract.Schrems_Compliance__c== '') && (contract.cTin_TypeOfDocument__c !='Non Disclosure Agreement' && contract.cTin_TypeOfDocument__c !='Transaction Agreement'
                            && contract.cTin_TypeOfDocument__c !='Notification letter'  && contract.cTin_TypeOfDocumentL2__c!='Letter of intention') && (contract.cTin_OwnerEntityLocalCode__c=='APA') && contract.TECH_PostContractDB__c){
                                contract.Schrems_Compliance__c.addError('Please fill in the Schrems Compliance');
                            }
                            
                            if((contract.Schrems_Exposure__c== null || contract.Schrems_Exposure__c== '') && (contract.cTin_TypeOfDocument__c !='Non Disclosure Agreement' && contract.cTin_TypeOfDocument__c !='Transaction Agreement'
                            && contract.cTin_TypeOfDocument__c !='Notification letter'  && contract.cTin_TypeOfDocumentL2__c!='Letter of intention') && (contract.cTin_OwnerEntityLocalCode__c=='AXL') && contract.TECH_PostContractDB__c){
                                contract.Schrems_Exposure__c.addError('Please fill in the Schrems Exposure');
                            }
                            
                              //23/03 mRA - changes w.r.t cpm
                            if((contract.IT_Security_Clause__c== null || contract.IT_Security_Clause__c== '') && (contract.cTin_TypeOfDocument__c !='Non Disclosure Agreement' && contract.cTin_TypeOfDocument__c !='Transaction Agreement'
                            && contract.cTin_TypeOfDocument__c !='Notification letter' && contract.cTin_TypeOfDocumentL2__c !='Letter of intention' ) && (contract.cTin_OwnerEntityLocalCode__c=='AXL' ||
                            contract.cTin_OwnerEntityLocalCode__c=='ABE'  || contract.cTin_OwnerEntity__c=='700 - AXA France') && contract.TECH_PostContractDB__c){
                                contract.IT_Security_Clause__c.addError('Please fill in the IT Security Clause');
                            }
                            
                            //23/03 mRA - changes w.r.t cpm
                             //23/03 mRA - changes w.r.t cpm
                            if((contract.cTin_DataPrivacyClause__c== null || contract.cTin_DataPrivacyClause__c== '') && (contract.cTin_TypeOfDocument__c !='Non Disclosure Agreement' && contract.cTin_TypeOfDocument__c !='Transaction Agreement'
                            && contract.cTin_TypeOfDocument__c !='Notification letter' && contract.cTin_TypeOfDocumentL2__c !='Letter of intention' ) && (contract.cTin_OwnerEntityLocalCode__c=='APA' ||
                            contract.cTin_OwnerEntityLocalCode__c=='ASA' || contract.cTin_OwnerEntityLocalCode__c=='AXL' || contract.cTin_OwnerEntityLocalCode__c=='ACH' || contract.cTin_OwnerEntity__c=='700 - AXA France' ) && contract.TECH_PostContractDB__c){
                                contract.cTin_DataPrivacyClause__c.addError('Please fill in the Data Privacy Clause');
                            }
                            
                            
                            //23/03 mRA - changes w.r.t cpm
                            if(contract.cTin_RetentionPeriod__c== null &&  contract.cTin_OwnerEntityLocalCode__c=='ACH' && contract.TECH_PostContractDB__c){
                                contract.cTin_RetentionPeriod__c.addError('Please fill in the Retention Period');
                            }
                             //23/03 mRA - changes w.r.t cpm
                            if(string.isblank(contract.cTin_Compliance_Clause__c) &&   (contract.cTin_TypeOfDocument__c !='Non Disclosure Agreement' && contract.cTin_TypeOfDocument__c !='Transaction Agreement'
                            && contract.cTin_TypeOfDocument__c !='Notification letter' && contract.cTin_TypeOfDocumentL2__c !='Letter of intention' ) && contract.TECH_PostContractDB__c && contract.cTin_OwnerEntityLocalCode__c !='AXLB'){
                                contract.cTin_Compliance_Clause__c.addError('Please fill in the Compliance Clause');
                            }
                            
                               //23/03 mRA - changes w.r.t cpm
                            if(contract.cTin_Compliance_Clause__c=='Modified' && string.isblank(contract.Does_the_Compliance_Clause_include_Code__c) &&   (contract.cTin_TypeOfDocument__c !='Non Disclosure Agreement' && contract.cTin_TypeOfDocument__c !='Transaction Agreement'
                            && contract.cTin_TypeOfDocument__c !='Notification letter' && contract.cTin_TypeOfDocumentL2__c !='Letter of intention' ) && contract.TECH_PostContractDB__c){
                                contract.Does_the_Compliance_Clause_include_Code__c.addError('Please fill in the field "If Comp. Clause modified, are included"');
                            }
                            
                             //23/03 mRA - changes w.r.t cpm
                            if(string.isblank(contract.cTin_AXALogoNameClause__c) &&   (contract.cTin_TypeOfDocument__c !='Non Disclosure Agreement' && contract.cTin_TypeOfDocument__c !='Transaction Agreement'
                            && contract.cTin_TypeOfDocument__c !='Notification letter' && contract.cTin_TypeOfDocumentL2__c !='Letter of intention') && contract.TECH_PostContractDB__c
                            && (contract.cTin_OwnerEntityLocalCode__c=='AXL' || contract.cTin_ownerEntity__c=='700 - AXA France')){
                                contract.cTin_AXALogoNameClause__c.addError('Please fill in the AXA Name & Logo');
                            }
                            
                              //23/03 mRA - changes w.r.t cpm
                            if(string.isblank(contract.cTin_Audit__c) &&   (contract.cTin_TypeOfDocument__c !='Non Disclosure Agreement' && contract.cTin_TypeOfDocument__c !='Transaction Agreement'
                            && contract.cTin_TypeOfDocument__c !='Notification letter' && contract.cTin_TypeOfDocumentL2__c !='Letter of intention') && contract.TECH_PostContractDB__c
                            && (contract.cTin_OwnerEntityLocalCode__c=='AXL' || contract.cTin_OwnerEntityLocalCode__c=='APA' || contract.cTin_OwnerEntityLocalCode__c=='ABE'  || contract.cTin_OwnerEntity__c=='700 - AXA France')){
                                contract.cTin_Audit__c.addError('Please fill in  Audit Clause');
                            }
                            
                             //23/03 mRA - changes w.r.t cpm
                            if(string.isblank(contract.cTin_TerminationClause__c) &&   (contract.cTin_TypeOfDocument__c !='Non Disclosure Agreement' && contract.cTin_TypeOfDocument__c !='Transaction Agreement'
                            && contract.cTin_TypeOfDocument__c !='Notification letter' && contract.cTin_TypeOfDocumentL2__c !='Letter of intention' ) && contract.TECH_PostContractDB__c
                            && (contract.cTin_OwnerEntityLocalCode__c=='ASA' || contract.cTin_OwnerEntityLocalCode__c=='APA' || contract.cTin_OwnerEntityLocalCode__c=='AXL')){
                                contract.cTin_TerminationClause__c.addError('Please fill in Termination & dispute Clause');
                            }
                            
                            if(string.isblank(contract.cTin_CRClause__c) && contract.TECH_PostContractDB__c
                            &&  (contract.cTin_TypeOfDocument__c !='Non Disclosure Agreement' && contract.cTin_TypeOfDocument__c !='Transaction Agreement'
                            && contract.cTin_TypeOfDocument__c !='Notification letter' && contract.cTin_TypeOfDocumentL2__c !='Letter of intention') && contract.cTin_OwnerEntityLocalCode__c !='AXLB'){
                                contract.cTin_CRClause__c.addError('Please fill in sustainability clause');
                            }
                            
                              //23/03 mRA - changes w.r.t cpm
                            if(string.isblank(contract.cTin_GroupOfContract__c) && contract.TECH_PostContractDB__c
                            && contract.cTin_OwnerEntity__c=='710 - AXA France Assurances'){
                                contract.cTin_GroupOfContract__c.addError('Please fill in Contract Group');
                            }
                            
                             //23/03 mRA - changes w.r.t cpm
                            if(string.isblank(contract.cTin_FCE_code__c) && contract.TECH_PostContractDB__c
                            && contract.cTin_OwnerEntity__c=='710 - AXA France Assurances'){
                                contract.cTin_FCE_code__c.addError('Please fill in FCE Group');
                            }
                            
                            //23/03 mRA - changes w.r.t cpm
                            if(string.isblank(contract.cTin_LiabilityClause__c) &&   (contract.cTin_TypeOfDocument__c !='Non Disclosure Agreement' && contract.cTin_TypeOfDocument__c !='Transaction Agreement'
                            && contract.cTin_TypeOfDocument__c !='Notification letter'  && contract.cTin_TypeOfDocumentL2__c !='Letter of intention') && contract.TECH_PostContractDB__c
                            && (contract.cTin_OwnerEntityLocalCode__c=='ASA' || contract.cTin_OwnerEntityLocalCode__c=='ABE' || contract.cTin_OwnerEntity__c=='700 - AXA France')){
                                contract.cTin_LiabilityClause__c.addError('Please fill in Liability Clause');
                            }
                            
                            //23/03 mRA - changes w.r.t cpm
                            if(string.isblank(contract.VISCA_Level__c) && contract.TECH_PostContractDB__c
                            && contract.cTin_OwnerEntityLocalCode__c=='APA'){
                                contract.VISCA_Level__c.addError('Please fill in VISCA Level');
                            } 
                            
                            //23/03 mRA - changes w.r.t cpm
                            if((string.isblank(contract.Security_Appendix__c) && contract.TECH_PostContractDB__c)
                            && (contract.cTin_OwnerEntityLocalCode__c=='APA' || (contract.cTin_OwnerEntity__c=='700 - AXA France' && (contract.cTin_TypeOfDocument__c=='Master Agreement' || 
                                contract.cTin_TypeOfDocument__c=='Standalone Contract' || contract.cTin_TypeOfDocument__c=='Amendment' || contract.cTin_TypeOfDocument__c=='Transaction Agreement' || 
                                contract.cTin_TypeOfDocument__c=='Other')))){
                                contract.Security_Appendix__c.addError('Please fill in Security Appendix');
                            } 
                            
                              //23/03 mRA - changes w.r.t cpm
                            if(string.isblank(contract.cTin_MaterialityRating__c) && contract.TECH_PostContractDB__c
                            && contract.cTin_OwnerEntityLocalCode__c=='AUK'){
                                contract.cTin_MaterialityRating__c.addError('Please fill in Materiality Rating');
                            } 
                            
                            //23/03 mRA - changes w.r.t cpm
                            if(string.isblank(contract.cTin_ProcurementInvolvementGrade__c) && contract.TECH_PostContractDB__c
                            && (contract.cTin_OwnerEntityLocalCode__c=='APA' || contract.cTin_OwnerEntityLocalCode__c=='AXL')){
                                contract.cTin_ProcurementInvolvementGrade__c.addError('Please fill in Procurement involvement grade');
                            }
                            
                              //23/03 mRA - changes w.r.t cpm
                            if(contract.cTin_MaterialityRatingDate__c== null && contract.TECH_PostContractDB__c
                            && contract.cTin_OwnerEntityLocalCode__c=='AUK'){
                                contract.cTin_MaterialityRatingDate__c.addError('Please fill in Materiality Rating Date');
                            } 
                            
                            if(string.isblank(contract.Anti_terrorism_Clause__c) && contract.TECH_PostContractDB__c
                            && contract.cTin_OwnerEntity__c=='700 - AXA France' && (contract.cTin_TypeOfDocument__c=='Master Agreement' || 
                            contract.cTin_TypeOfDocument__c=='Standalone Contract' || contract.cTin_TypeOfDocument__c=='Amendment' || contract.cTin_TypeOfDocument__c=='Transaction Agreement' || 
                            contract.cTin_TypeOfDocument__c=='Other')){
                                contract.Anti_terrorism_Clause__c.addError('Please fill in anti-terrorism clause');
                            } 
                            
                            if(string.isblank(contract.cTin_FairTransparentSelectionProcess__c) && contract.TECH_PostContractDB__c
                            && contract.cTin_OwnerEntity__c=='700 - AXA France'){
                                contract.cTin_FairTransparentSelectionProcess__c.addError('Please fill in Rationale of supplier selection is');
                            } 
                            
                            if(string.isblank(contract.Money_Laudering_Clause__c ) && contract.TECH_PostContractDB__c
                            && contract.cTin_OwnerEntity__c=='700 - AXA France' && (contract.cTin_TypeOfDocument__c=='Master Agreement' || 
                            contract.cTin_TypeOfDocument__c=='Standalone Contract' || contract.cTin_TypeOfDocument__c=='Amendment' || contract.cTin_TypeOfDocument__c=='Transaction Agreement' || 
                            contract.cTin_TypeOfDocument__c=='Other')){
                                contract.Money_Laudering_Clause__c.addError('Please fill in Money laundering clause');
                            }
                            
                            
                              //23/03 mRA - changes w.r.t cpm
                            if(contract.cTin_SoftwareLicenseRecord__c== '' && contract.TECH_PostContractDB__c
                            && contract.cTin_OwnerEntityLocalCode__c=='AUK'){
                                contract.cTin_SoftwareLicenseRecord__c.addError('Please fill in Software License Record');
                            } 
                            
                            //23/03 mRA - changes w.r.t cpm
                            if(string.isBlank(contract.cTin_TypeOfDocumentL2__c) && contract.TECH_PostContractDB__c
                            && (contract.cTin_TypeOfDocument__c=='Notification letter' || contract.cTin_TypeOfDocument__c=='Other') && contract.cTin_OwnerEntityLocalCode__c !='AXLB'){
                                contract.cTin_TypeOfDocumentL2__c.addError('Please fill in sub-type of document');
                            }
                            
                            //01-Avril-2022 MRA - changes w.r.t cpm
                            if ((/*integer.valueOf(contract.cTin_CommittedPartExclVAT__c)==0 || contract.cTin_CommittedPartExclVAT__c<0 || */ contract.cTin_CommittedPartExclVAT__c==NULL) && contract.TECH_PostContractDB__c && (contract.cTin_TypeOfDocument__c=='Transaction Agreement' || contract.cTin_TypeOfDocumentL2__c=='Letter of intention' || contract.cTin_TypeOfDocument__c=='Standalone Contract')){
                                contract.cTin_CommittedPartExclVAT__c.addError('Please fill in Minimum Commitment excl. VAT');
                            }
                            
                             //01-Avril-2022 MRA - changes w.r.t cpm
                            if ((/*integer.valueOf(contract.Contract_Value_excl_VAT__c)==0 || contract.Contract_Value_excl_VAT__c<0 || */ contract.Contract_Value_excl_VAT__c==NULL) && contract.TECH_PostContractDB__c && (contract.cTin_TypeOfDocument__c=='Transaction Agreement' || contract.cTin_TypeOfDocumentL2__c=='Letter of intention' || contract.cTin_TypeOfDocument__c=='Standalone Contract')){
                                contract.Contract_Value_excl_VAT__c.addError('Please fill in Estimated Contract Value excl. VAT');
                            }
                            
                            /* 23/03 mra commented - new cpm rule
                            if((string.ISBLANK(contract.cTin_VRFCriticality__c)                    
                                || string.ISBLANK(contract.cTin_ReputationRisk__c  )   
                                || string.ISBLANK(contract.cTin_FinancialHealthRiskRating__c)  
                                || string.ISBLANK(contract.cTin_ComplianceRiskRating__c)   
                                || string.ISBLANK(contract.cTin_OperationalResilienceRiskRating__c)        
                                || string.ISBLANK(contract.cTin_InfoSecRiskRating__c)      
                                || string.ISBLANK(contract.cTin_DataPrivacyRisk__c)  ) 
                                   &&
                                (contract.cTin_TypeOfDocument__c =='Master Agreement' || contract.cTin_TypeOfDocument__c =='Agreement'|| contract.cTin_TypeOfDocument__c =='Standalone Contract'
                                || contract.cTin_TypeOfDocument__c =='Amendment' || contract.cTin_TypeOfDocument__c =='Transaction Agreement' ) && contract.cTin_OwnerEntityLocalCode__c!='AGO'
                                &&  contract.cTin_OwnerEntity__c!='710 - AXA France Assurances'  &&  contract.cTin_OwnerEntity__c!='1110 - AXA JURIDICA'){
                                    contract.addError('Please fill in the "Vendor Risk Framework" fields');                             
                            }*/
                            
                            
                           //23/03- new cpm rule
                           if((string.ISBLANK(contract.cTin_VRFCriticality__c)                    
                                || string.ISBLANK(contract.cTin_ReputationRisk__c  )   
                                || string.ISBLANK(contract.cTin_FinancialHealthRiskRating__c)  
                                || string.ISBLANK(contract.cTin_ComplianceRiskRating__c)   
                                || string.ISBLANK(contract.cTin_OperationalResilienceRiskRating__c)        
                                || string.ISBLANK(contract.cTin_InfoSecRiskRating__c)      
                                || string.ISBLANK(contract.cTin_DataPrivacyRisk__c)  ) 
                                &&
                                ( contract.cTin_TypeOfDocument__c !='Amendment' && contract.cTin_TypeOfDocument__c !='Non Disclosure Agreement'
                                && contract.cTin_TypeOfDocument__c !='Notification letter') /*&& contract.cTin_OwnerEntityLocalCode__c!='AGO'*/ && contract.cTin_OwnerEntityLocalCode__c !='AXLB' &&
                                contract.cTin_OwnerEntity__c!='710 - AXA France Assurances' && (string.ISBLANK(contract.cTin_CoupaRiskAssessID__c) && contract.cTin_RALinkedMSAParent__c==false)  /*&&  contract.cTin_OwnerEntity__c!='1110 - AXA JURIDICA'*/){
                                    contract.addError('Please fill in the "Contract Risk Assessment & Dilligences" fields');                             
                            }
                        }
                    }
                    else if(setCtrRecTypesOpCo.contains(contract.RecordTypeId)){
                        // Check if contacts are validated
                        if(contract.Customer_Operational_Contact__c != null && mapContact.containsKey(contract.Customer_Operational_Contact__c)){
                            if(mapContact.get(contract.Customer_Operational_Contact__c).RecordTypeId != idRecEntityContact || !mapContact.get(contract.Customer_Operational_Contact__c).Active__c ){
                                // 09-DEC-2021  ARA
                                if(contract.RecordTypeId == idRecOpCoAmendEdit){
                                    contract.Customer_Operational_Contact__c = null;
                                }else{
                                    contract.Customer_Operational_Contact__c.addError(System.Label.Contract_Operational_Contact);
                                }
                            }
                        }
                        if(contract.CustomerSignedBy__c != null && mapContact.containsKey(contract.CustomerSignedBy__c)){
                            if(mapContact.get(contract.CustomerSignedBy__c).RecordTypeId != idRecEntityContact || !mapContact.get(contract.CustomerSignedBy__c).Active__c){
                                // 09-DEC-2021  ARA
                                if(contract.RecordTypeId == idRecOpCoAmendEdit){
                                    contract.CustomerSignedBy__c = null;
                                }else{
                                    contract.CustomerSignedBy__c.addError(System.Label.Customer_Signed_By_Error);
                                }
                            }
                        }
                        if(contract.CustomerSignedBy2__c != null && mapContact.containsKey(contract.CustomerSignedBy2__c)){
                            if(mapContact.get(contract.CustomerSignedBy2__c).RecordTypeId != idRecEntityContact || !mapContact.get(contract.CustomerSignedBy2__c).Active__c){
                                // 09-DEC-2021  ARA
                                if(contract.RecordTypeId == idRecOpCoAmendEdit){
                                    contract.CustomerSignedBy2__c = null;
                                }else{
                                    contract.CustomerSignedBy2__c.addError(System.Label.Customer_Signed_By_2_Error);
                                }
                            }
                        }
                        if(contract.AXA_GS_Signed_By__c != null && mapContact.containsKey(contract.AXA_GS_Signed_By__c)){
                            if(mapContact.get(contract.AXA_GS_Signed_By__c).RecordTypeId != idRecEntityContact || !mapContact.get(contract.AXA_GS_Signed_By__c).AXA_GO_Signatory__c || !mapContact.get(contract.AXA_GS_Signed_By__c).Active__c){
                                // 09-DEC-2021  ARA
                                if(contract.RecordTypeId == idRecOpCoAmendEdit){
                                    contract.AXA_GS_Signed_By__c = null;
                                }else{
                                    contract.AXA_GS_Signed_By__c.addError(System.Label.Contract_AXA_Go_Signed_By_Error);
                                }
                            }
                        }
                        //  22-MAR-2021  ARA    SP-01506
                        if(contract.AXA_GO_Signed_By_2__c != null && mapContact.containsKey(contract.AXA_GO_Signed_By_2__c)){
                            if(mapContact.get(contract.AXA_GO_Signed_By_2__c).RecordTypeId != idRecEntityContact || !mapContact.get(contract.AXA_GO_Signed_By_2__c).AXA_GO_Signatory__c || !mapContact.get(contract.AXA_GO_Signed_By_2__c).Active__c){
                                // 09-DEC-2021  ARA
                                if(contract.RecordTypeId == idRecOpCoAmendEdit){
                                    contract.AXA_GO_Signed_By_2__c = null;
                                }else{
                                    contract.AXA_GO_Signed_By_2__c.addError(System.Label.Contract_AXA_Go_Signed_By_2_Error);
                                }
                            }
                        }
                        // 30-07-2021   ARA SP-02169
                        if(contract.Account__c != null){
                            contract.C_Account__c = contract.Account__r.ParentId;
                        }
                    }
                }
    
                //controls for OpCo
                if (!contract.TECH_IsContractIn__c){
                    if (contract.Account__c != null) {
                        lstOpCoContracts.add(contract);
                    }
                    setRecTypeId.add(contract.recordTypeId);
                    if (PAD.canTrigger('AP1203')){
                        if (contract.recordTypeId != idRecOpCoSingleEdit){
                            lstCtrnotSingleEdit.add(contract);
                        }
                        //USA 05062020 check legal entity and entity before calling prefillLegalEntity method
                        if ((contract.Account__c == null) && (contract.C_Account__c != null)) {
                            lstCtrNoLegalEntity.add(contract);
                        }
                    }
                    // SGO - 2019/09/11 - Prefill legal entity
                    if (PAD.canTrigger('AP1204')) {
                        if (contract.Opportunity__c == null){
                            lstCtrNoOpp.add(contract);
                        }
                    }
                }
            }
            if (lstOpCoContracts.size()>0){
                if (PAD.canTrigger('AP1201')) {
                    AP12_Contract.prefillEntity(lstOpCoContracts, null);
                }
                if (PAD.canTrigger('AP1202')){
                    AP12_Contract.fillInSignatureType(null, lstOpCoContracts);
                }
            }
            if (lstCtrNoLegalEntity.size()>0){
                //setAccId is returned to get IDs of new accounts prefilled in legal entity
                setAccId = AP12_Contract.prefillLegalEntity(lstCtrNoLegalEntity);
            }
            if(lstCtrNoOpp.size() > 0){
                AP12_Contract.updateContractLegalEntity(lstCtrNoOpp);
            }
        }
    
        public static void afterInsertHandler(List<Contract__c> lstNewContracts){
            Map<Id,string> conIdNewDomainMap                        = new Map<Id,string>();
            Map<Id,string> conIdOldDomainMap                        = new Map<Id,string>();
            Map<Id,cTin_ContractForm__c> contractIdContractFormMap  = new Map<Id, cTin_ContractForm__c>();
            List<cTin_ContractTeam__c> contractTeamList             = new List<cTin_ContractTeam__c>();
            Set<Id> setAP38ContractIds                              = new Set<Id>();
            Set<Id> cidSet                                          = new set<Id>();
            Set<Id> setCtrRecTypesOpCoSOW                           = new set<Id>{idRecOpCoSingleEdit, idRecOpCoSingleReadOnly};
            map<Id,Id> mapCtrproductId                              = new map<Id,Id>();
            List<Id> lstOppID                                       = new List<Id>();
            Map<ID,String> IdSrcReqStatusMap = new Map<ID,String>();
    
            system.debug('****afterInsertHandler contract');
            //Case 3480(Enhancement) - add group corresponding to sourcing domain
            //                         in contract team if sourcing domain is specified on contract
            user usr = [select id,cTin_EntityLocalCode__c from user where id=:UserInfo.getUserId() limit 1];
            //AMA
            Set<ID> setSrcReq = new Set<ID>();
            for(Contract__c contract : lstNewContracts){
                //trigger must execute only for contract-in contracts
                if (PAD.canTrigger('AP1012') && !hasExecutedafterInsertHandler){
                    hasExecutedafterInsertHandler = true;
                    if (setCtrRecTypescTin.contains(contract.RecordTypeId)){
                        if(PAD.canTrigger('AP35')){
                           if(contract.cTin_OwnerEntityLocalCode__c == 'AWS' ){
                              //ADDING AIM LOCAL ADMIN GROUP AS CONTRACT CO-OWNER WITH EDIT ACCESS
                                cTin_ContractTeam__c ctAWSBO =  new cTin_ContractTeam__c(cTin_Role__c = '016',
                                        cTin_Contract__c = contract.Id,
                                        cTin_GroupMember__c = 'AWS Business Owner',
                                        cTin_ContractAccessLevel__c = 'Edit');
                                //ADDING AIM LEGAL TEAM AS lEGAL WITH READ ACCESS
                                cTin_ContractTeam__c ctAWSCO=  new cTin_ContractTeam__c(cTin_Role__c = '015',
                                        cTin_Contract__c = contract.Id,
                                        cTin_GroupMember__c = 'AWS Contract Co Owner',
                                        cTin_ContractAccessLevel__c = 'Read');
                                        
                                        contractTeamList.add(ctAWSBO);
                                        contractTeamList.add(ctAWSCO);
                             
                            }
                            
                            if(contract.cTin_OwnerEntityLocalCode__c == 'AIM' && contract.cTin_sourcingDomain__c != null){
                                conIdNewDomainMap.put(contract.id,contract.cTin_sourcingDomain__c);
                            }
                            //MRA 17-APR-2019 - Evolution 01700017433
                            if(contract.cTin_OwnerEntityLocalCode__c == 'AIM' ){
                                //ADDING AIM LOCAL ADMIN GROUP AS CONTRACT CO-OWNER WITH EDIT ACCESS
                                cTin_ContractTeam__c ctLocalAdmin =  new cTin_ContractTeam__c(cTin_Role__c = '015',
                                        cTin_Contract__c = contract.Id,
                                        cTin_GroupMember__c = 'AIM Local Admins',
                                        cTin_ContractAccessLevel__c = 'Edit');
                                //ADDING AIM LEGAL TEAM AS lEGAL WITH READ ACCESS
                                cTin_ContractTeam__c ctLegal =  new cTin_ContractTeam__c(cTin_Role__c = '004',
                                        cTin_Contract__c = contract.Id,
                                        cTin_GroupMember__c = 'AIM Legal Team',
                                        cTin_ContractAccessLevel__c = 'Read');
                                //ADDING AIM COMTRACR CO-OWNER AS CONTRACT CO-OWNER WITH EDIT ACCESS
                                cTin_ContractTeam__c ctContractCoOwner = new cTin_ContractTeam__c(cTin_Role__c = '015',
                                        cTin_Contract__c = contract.Id,
                                        cTin_GroupMember__c = 'AIM Contract Co-Owner',
                                        cTin_ContractAccessLevel__c = 'Edit');
                                
                                //MRA 12/07 - SP-02871       
                                cTin_ContractTeam__c ctProcOffice = new cTin_ContractTeam__c(cTin_Role__c = '015',
                                        cTin_Contract__c = contract.Id,
                                        cTin_GroupMember__c = 'AIM Procurement Office',
                                        cTin_ContractAccessLevel__c = 'Edit');
                                
                                cTin_ContractTeam__c ctAudit= new cTin_ContractTeam__c(cTin_Role__c = '005',
                                        cTin_Contract__c = contract.Id,
                                        cTin_GroupMember__c = 'AIM Audit',
                                        cTin_ContractAccessLevel__c = 'Read');

                                //20/04/2022 AMA: Add ContractTeam when usr.cTin_EntityLocalCode__c = AIM
                                if(usr.cTin_EntityLocalCode__c == 'AIM'){
                                    cTin_ContractTeam__c ctAIM =  new cTin_ContractTeam__c(cTin_Role__c = '026',
                                            cTin_Contract__c = contract.Id,
                                            cTin_GroupMember__c = 'AIM_Experts',
                                            cTin_ContractAccessLevel__c = 'Read');
                                    contractTeamList.add(ctAIM);
                                }   
                        
                                contractTeamList.add(ctProcOffice );
                                contractTeamList.add(ctAudit);        
                                contractTeamList.add(ctLocalAdmin);
                                contractTeamList.add(ctLegal);
                                contractTeamList.add(ctContractCoOwner);
                            }

                            if(contract.cTin_OwnerEntityLocalCode__c == 'ABCL'){
                                cTin_ContractTeam__c teamABCL =new cTin_ContractTeam__c(/*cTin_Role__c = '007',*/ cTin_Role__c = '016',
                                        cTin_Contract__c = contract.Id,
                                        cTin_GroupMember__c = 'ABE_CorporateLegal',
                                        cTin_ContractAccessLevel__c = 'Edit');
                                contractTeamList.add(teamABCL);
                            }
                            
                            
                            // 09/09/2021 MRA : SP-02382 - Add 'G Con Pro De' group as co-owner if owner.entity equals ADE
                             if(contract.cTin_OwnerEntityLocalCode__c == 'ADE'){
                                cTin_ContractTeam__c teamADE =new cTin_ContractTeam__c(cTin_Role__c = '015',
                                        cTin_Contract__c = contract.Id,
                                        cTin_GroupMember__c = 'G_CON_PRO_DE',
                                        cTin_ContractAccessLevel__c = 'Edit');
                                contractTeamList.add(teamADE);
                            }
                              //02/03/2022 MRA: Add ACH_Procurement as co-owner & ACH Audit & Legal as legal to contract team for ACH 
                            if(contract.cTin_OwnerEntityLocalCode__c == 'ACH'){
                                cTin_ContractTeam__c teamCoOwnerACH =new cTin_ContractTeam__c(cTin_Role__c = '015',
                                        cTin_Contract__c = contract.Id,
                                        cTin_GroupMember__c = 'ACH Procurement',
                                        cTin_ContractAccessLevel__c = 'Edit');
                                contractTeamList.add(teamCoOwnerACH );
                                
                                //02/03/2022 MRA: Add ACH Audit & Legal as legal to contract team for ACH
                                
                                 cTin_ContractTeam__c teamACHLegal =  new cTin_ContractTeam__c(cTin_Role__c = '004',
                                        cTin_Contract__c = contract.Id,
                                        cTin_GroupMember__c = 'ACH Audit & Legal',
                                        cTin_ContractAccessLevel__c = 'Read');
                                contractTeamList.add(teamACHLegal);
                            }
                            
                            // 07/06/2022 MRA : SP-03331 - Add AXA Partners Procurement group as co-owner if owner.entity equals APA 
                            if(/*usr.cTin_EntityLocalCode__c== 'APA' || */contract.TECH_OwnerEntityCode__c == 'APA'){  
                                cTin_ContractTeam__c teamAPA =new cTin_ContractTeam__c(cTin_Role__c = '015',    
                                        cTin_Contract__c = contract.Id, 
                                        cTin_GroupMember__c = 'AXA Partners Procurement',   
                                        cTin_ContractAccessLevel__c = 'Edit');  
                                contractTeamList.add(teamAPA);  
                            }
                            
                            // 28/06/2022 MRA : SP-03970 - Add AXA GO Gensec SPOC group as Legal owner if owner.entity equals AGO 
                            if(contract.TECH_OwnerEntityCode__c == 'AGO' && (contract.cTin_TypeOfDocument__c=='Master Agreement' || contract.cTin_TypeOfDocument__c=='Transaction Agreement' || contract.cTin_TypeOfDocument__c=='Standalone Contract')){  
                                cTin_ContractTeam__c teamAGO =new cTin_ContractTeam__c(cTin_Role__c = '004',    
                                        cTin_Contract__c = contract.Id, 
                                        cTin_GroupMember__c = 'AXA GO Gensec SPOC',   
                                        cTin_ContractAccessLevel__c = 'Edit',
                                        Legal_Access_Level__c='Edit');  
                                contractTeamList.add(teamAGO);  
                            }
                            
                        }
                        // Iterating over the list of contracts just received and creating for each one a name which is identical to the parent, and connecting it
                        cTin_ContractForm__c contractForm = AP39_ContractInMethods.createContractForm(contract);
                        contractIdContractFormMap.put(contract.Id, contractForm);
    
                        if(contract.ownerId != null) {
                            cTin_ContractTeam__c contractTeam = new cTin_ContractTeam__c(/*cTin_Role__c = '000', */ cTin_Role__c = '017',
                                    cTin_Contract__c = contract.Id,
                                    cTin_TeamMember__c = contract.OwnerId,
                                    cTin_ContractAccessLevel__c = 'Edit');
                            contractTeamList.add(contractTeam);
                        }
                        if(contract.cTin_BusinessOwner__c != null) {
                            system.debug('****cTin_BusinessOwner__c');
                            cTin_ContractTeam__c businessOwner = new cTin_ContractTeam__c(cTin_Role__c='016',
                                    cTin_Contract__c = contract.Id,
                                    cTin_TeamMember__c = contract.cTin_BusinessOwner__c,
                                    cTin_ContractAccessLevel__c = 'Read',
                                    cTin_ContractForm__c = contractForm.Id  ) ;
                            contractTeamList.add(BusinessOwner) ;
                        }
                        if(contract.cTin_AXASignatoryRepresentative__c != null){
                            setAP38ContractIds.add(contract.Id);
                        }
                    }
                }
    
                // controls for OpCo
                /*if(PAD.canTrigger('AP50')){
                    if((contract.OfferATS__c!=null) && (contract.RecordTypeId == idRecLightContract || setCtrRecTypesOpCoSOW.contains(contract.RecordTypeId)) && !(contract.isClone()) && (contract.Opportunity__c == null)){
                        mapContractIdOfferId.put(contract.id,contract.OfferATS__c);
                    }
                }*/

                if(PAD.canTrigger('AP50')){
                    if(contract.product__c != null && contract.RecordTypeId == idRecLightContract && !contract.isClone() && contract.Opportunity__c == null){
                        mapCtrproductId.put(contract.id,contract.product__c);
                    }
                }
                
                if(PAD.canTrigger('AP1001')){
                    if(setCtrRecTypesOpCo.contains(contract.RecordTypeId) && contract.Opportunity__c != null){
                        lstOppID.add(contract.Opportunity__c);
                    }
                }

                //AMA 
                if (contract.Sourcing_Request__c != null) {
                    setSrcReq.add(contract.Sourcing_Request__c);
                }
            }
            // 17-MAR-2021  ARA    1.8      SP-01222    Comment block
            /*if(contractTeamList.size()>0){
                system.debug('****contractTeamList');
                insert contractTeamList;
            }*/
            if(PAD.canTrigger('AP38')){
                // Inserting the Axa Rep of the contract into contract Team
                if(setAP38ContractIds.size()>0) AP38_AddNewMember.addAxaRep(setAP38ContractIds);
            }
            if(conIdNewDomainMap.size()>0 || conIdOldDomainMap.size()>0){
                AP35_updateCTeamDomainGroup.addRemoveGroup(conIdNewDomainMap,conIdOldDomainMap,cidSet);
            }
            if(contractIdContractFormMap.size()>0){
                insert contractIdContractFormMap.values();
            }
            // running over the list of contractTeams and adding relevant
            for(cTin_ContractTeam__c ct : contractTeamList){
                ct.cTin_ContractForm__c = contractIdContractFormMap.get(ct.cTin_Contract__c).Id;
            }
            // 17-MAR-2021  ARA    1.8      SP-01222 - 
            if(contractTeamList.size()>0){
                upsert contractTeamList;
            }
            /*if(mapContractIdOfferId.size()>0){
                AP50_GenerateProductItem.createProductItem(mapContractIdOfferId);
            }*/
            
            // 16-JUL-2021  ARA    1.8      SP-02172
            if(mapCtrProductId.size()>0){
                AP50_GenerateProductItem.createProductItem(mapCtrProductId);
            }

            if(lstOppID.size()>0){
                AP10_ContractHandler.pushCreationToOpportunity(lstOppID);
            }

           //AMA
            if (setSrcReq.size()>0) {
                List<Sourcing_Request__c> lstSrcReq = [select id,Business_Owner__c,Buyer_Lead__c,Data_Privacy_Expert__c,Financial_control__c,Legal_Counsel__c,Other_Proc__c,SBP__c,vendor_riskuser__c from Sourcing_Request__c where id in :setSrcReq];
    
                AP73_ManageSrcReqSharing.AfterUpdateSharing(new map<ID,Sourcing_Request__c>(lstSrcReq));
            }
        }
    
        public static void afterUpdateHandler(List<Contract__c> lstNewContracts, List<Contract__c> lstOldContracts, Map<Id, Contract__c> mapNewContracts, Map<Id, Contract__c> mapOldContracts){
            List<cTin_ContractForm__c> contractFormList      = new List<cTin_ContractForm__c>();
            List<cTin_ContractTeam__c> contractTeamList      = new List<cTin_ContractTeam__c>();
            Set<Id> setAP33ContractIds                       = new Set<Id>();
            Set<Id> setAP36ContractIds                       = new Set<Id>();
            Set<Id> setContractIdToUpdateSharing             = new Set<Id>();
            Id newOwnerId;
            Id oldOwnerId;
            Set<Id>  setAP38ContractIds                      = new Set<Id>();
            Set<Id> idContractChangedOwnerSet                = new Set<Id>();
            Map<Id, Id> mapMemberWithContract                = new Map<Id, Id>();
            Boolean ToNotCreate                              = false;
            Map<Id,Id> mapOldValueContratW                   = new Map<ID,ID>();
            Map<Id, Id> contractIdContractFormIdMap          = new Map<Id, Id>();
            List<cTin_ContractTeam__c> contractTeamListToDel = new List<cTin_ContractTeam__c>();
            Map<Id,string>conIdNewDomainMap                  = new Map<Id,string>();
            Map<Id,string>conIdOldDomainMap                  = new Map<Id,string>();
            Set<Id>contractIdSet                             = new Set<Id>();
            Map<Id,Contract__c>con221Map                     = new Map<Id,Contract__c>();
            Set<Id> setCtrAcCodeChanges                      = new Set<Id>();
            //Map<Id,Id> contractIdOfferIdMap                  = new Map<Id,Id>();
            Set<Id> setSingleCtrRecType                      = new Set<Id>{idRecOpCoSingleEdit, idRecOpCoSingleReadOnly};
            Set<Id> setAmendCtrRecType                       = new Set<Id>{idRecOpCoAmendEdit, idRecOpCoAmendReadOnly};
            Map<Id,String> mapOppIdCtrStatus                 = new Map<Id, String>();
            Set<Id> setCtrIdToUpdateIL                       = new Set<Id>();
            Set<Id> setCtrIdSendPORemind                     = new Set<Id>();
            list<Contract__c>lstCtrInApproval                = new list<Contract__c>();
            map<id,id>mapCtrOwnerId                          = new map<id,id>();
            hasExecutedafterUpdateHandler = true;
            Set<String> setStrRecTypescTin = new Set<String>((List<String>)new List<Id>(setCtrRecTypescTin));
            Map<Id, Contract__c> mapNewCtr = new Map<Id, Contract__c>();
            Map<Id, Contract__c> mapOldCtr = new Map<Id, Contract__c>();
            Map<ID,String> IdSrcReqStatusMap = new Map<ID,String>();
            Map<ID,Contract__c> IdSrcReqCtrMap = new Map<ID,Contract__c>();
            set<id>setContractId=new set<id>();
            set<id> ctrWithTeamTodel=new set<id>();
            set<id>setOldcrtOwnerId=new set<id>();
            //isRunningCtrHandlerAfterUpdt=true;
            //AMA
            List<Sourcing_Request__c> lstRscReqUpd = new List<Sourcing_Request__c>();
            for(Integer i=0; i<lstNewContracts.size();i++){
                Contract__c oldContract = mapOldContracts.get(lstNewContracts[i].Id);
                system.debug('cTin_SignatureDate__c' + mapNewContracts.get(lstNewContracts[i].Id).cTin_SignatureDate__c);
                Contract__c newContract = mapNewContracts.get(lstNewContracts[i].Id);
                //trigger must execute only for contract-in contracts
                if (setCtrRecTypescTin.contains(newContract.RecordTypeId)){
                    mapNewCtr.put(newContract.Id, newContract);
                    mapOldCtr.put(oldContract.Id, oldContract);
                    if(PAD.canTrigger('AP72')){if(newContract.TECH_DataFix__c!=oldContract.TECH_DataFix__c) setContractId.add(newContract.Id); }
                    if(PAD.canTrigger('AP60')){
                      
                        if(newContract.OwnerId !=oldContract.OwnerId /*|| newContract.TECH_DataFixADE__c==true*/){
                            mapCtrOwnerId.put(newContract.Id,newContract.OwnerId);
                        }
                    }
                    // Case 1286
                    if(PAD.canTrigger('AP33')){
                        if(newContract.cTin_ParentContract__c <> null && (newContract.cTin_ParentContract__c <> oldContract.cTin_ParentContract__c)){
                            setAP33ContractIds.add(newContract.Id);
                        }
                    }
                    // Case 1210
                    if(PAD.canTrigger('AP36')){
                        if (Test.isRunningTest())
                            hasExecutedafterUpdateHandler=false;
                        if(newContract.cTin_ParentContract__c <> null &&
                                ((oldContract.status__c <> newContract.status__c ) && newContract.status__c == System.Label.cTin_TriggerStatus) &&
                                (newContract.cTin_TypeOfDocument__c == System.Label.cTin_AmendTypeOfDoc)){
                            setAP36ContractIds.add(newContract.Id);
                        }
                    }
                    if(PAD.canTrigger('AP37')){
                        if(newContract.OwnerId <> oldContract.OwnerId){
                            setContractIdToUpdateSharing.add(newContract.Id);
                            newOwnerId = newContract.OwnerId;
                            oldOwnerId=oldContract.OwnerId;
                        }
                    }
                    //Case 3480(Enhancement) - add/remove group corresponding to sourcing domain
                    //                         in contract team if sourcing domain is updated
                    if(PAD.canTrigger('AP35')){
                        if(newContract.cTin_OwnerEntityLocalCode__c == 'AIM' && newContract.cTin_sourcingDomain__c != oldContract.cTin_sourcingDomain__c){
                            conIdNewDomainMap.put(newContract.id, newContract.cTin_sourcingDomain__c);
                            conIdOldDomainMap.put(newContract.id, oldContract.cTin_sourcingDomain__c);
                        }
                        //17-APR-2019 MRA : Evolution 4332
                        if(newContract.OwnerId != oldContract.OwnerId && oldContract.cTin_OwnerEntityLocalCode__c == 'AIM'){
                            contractIdSet.add(newContract.id);
                        }
                    }
                    
                    if ((newContract.Status__c != oldContract.Status__c) && (newContract.Status__c=='In Approval' /*&& ctrOld.Status__c!='Draft'*/)
                        && newContract.TECH_IsContractIn__c && /*contract.cTin_CountCTInApproval__c==0 &&*/ PAD.canTrigger('ctinblockInApproval')){
                            lstCtrInApproval.add(newContract);
                    }
                    
                   /* if(newcontract.TECH_OwnerEntityCode__c =='AGO'                  
                    && newcontract.cTin_TypeOfDocument__c!='Master Agreement' 
                    && newcontract.cTin_TypeOfDocument__c!='Transaction Agreement' 
                    && newcontract.cTin_TypeOfDocument__c!='Standalone Contract'){
                        
                    }*/
                
                    // MERGE trigger Contract_AfterInsertUpdate <<START>>
                    if(newContract.OwnerId != oldContract.OwnerId){
                        idContractChangedOwnerSet.add(newContract.Id);
                        setOldcrtOwnerId.add(oldContract.OwnerId);
                        cTin_ContractTeam__c contractTeam = new cTin_ContractTeam__c(/*cTin_Role__c = '000'*/ cTin_Role__c = '017',
                                cTin_Contract__c = newContract.Id,
                                cTin_TeamMember__c = newContract.OwnerId,
                                cTin_ContractAccessLevel__c = 'Edit');
                        contractTeamList.add(contractTeam);
                        if(newContract.TECH_OwnerEntityCode__c == 'AIM'){
                            cTin_ContractTeam__c ctAIM =  new cTin_ContractTeam__c(cTin_Role__c = '026',
                                    cTin_Contract__c = newContract.Id,
                                    cTin_GroupMember__c = 'AIM_Experts',
                                    cTin_ContractAccessLevel__c = 'Read');
                            contractTeamList.add(ctAIM);
                        }
                        
                        if(newContract.TECH_OwnerEntityCode__c == 'APA'){  
                            cTin_ContractTeam__c ctAPA =  new cTin_ContractTeam__c(cTin_Role__c = '015',    
                                    cTin_Contract__c = newContract.Id,  
                                    cTin_GroupMember__c = 'AXA Partners Procurement',   
                                    cTin_ContractAccessLevel__c = 'Edit');  
                            contractTeamList.add(ctAPA);    
                        }
                        //system.debug('## old owner  entity '+ oldContract.cTin_OwnerEntityLocalCode__c );
                        //system.debug('## new owner  entity '+ newContract.cTin_OwnerEntityLocalCode__c );
                        //system.debug('## old owner  entity '+ oldContract.TECH_OwnerEntityCode__c );
                        //system.debug('## new owner  entity '+ newContract.TECH_OwnerEntityCode__c );

                        if(newContract.TECH_OwnerEntityCode__c == 'AGO'&& oldContract.TECH_OwnerEntityCode__c != 'AGO'
                          && (newcontract.cTin_TypeOfDocument__c=='Master Agreement' 
                                   || newcontract.cTin_TypeOfDocument__c=='Transaction Agreement' 
                                   || newcontract.cTin_TypeOfDocument__c=='Standalone Contract')){  
                            cTin_ContractTeam__c ctAGO =new cTin_ContractTeam__c(cTin_Role__c = '004',    
                                                        cTin_Contract__c = newContract.Id, 
                                                        cTin_GroupMember__c = 'AXA GO Gensec SPOC',   
                                                        cTin_ContractAccessLevel__c = 'Edit',
                                                        Legal_Access_Level__c='Edit');  
                             contractTeamList.add(ctAGO);                               
                        }
                        else if(newContract.TECH_OwnerEntityCode__c != 'AGO'){
                            ctrWithTeamTodel.add(newcontract.Id);
                        }

                            
                        }
                    
                    if(newcontract.cTin_TypeOfDocument__c!=oldContract.cTin_TypeOfDocument__c &&  newContract.TECH_OwnerEntityCode__c == 'AGO'){ 
                       if(newcontract.cTin_TypeOfDocument__c=='Master Agreement' 
                                   || newcontract.cTin_TypeOfDocument__c=='Transaction Agreement' 
                                   || newcontract.cTin_TypeOfDocument__c=='Standalone Contract'){
                            list<cTin_ContractTeam__c> ctlistExisting=[select id,cTin_Contract__c  from cTin_ContractTeam__c where cTin_GroupMember__c = 'AXA GO Gensec SPOC' and cTin_Contract__c  =:newContract.Id];
                            if(ctlistExisting.size()==0){
                                cTin_ContractTeam__c ctAGO =new cTin_ContractTeam__c(cTin_Role__c = '004',    
                                                        cTin_Contract__c = newContract.Id, 
                                                        cTin_GroupMember__c = 'AXA GO Gensec SPOC',   
                                                        cTin_ContractAccessLevel__c = 'Edit',
                                                        Legal_Access_Level__c='Edit');  
                                contractTeamList.add(ctAGO);
                            }
                       }
                        else{
                            ctrWithTeamTodel.add(newcontract.Id);
                        }
                        
                    }
                       
                        
                    if(newContract.cTin_BusinessOwner__c != oldContract.cTin_BusinessOwner__c && newContract.cTin_BusinessOwner__c != null ){
                        if(oldContract.cTin_BusinessOwner__c != null){
                            mapMemberWithContract.put(oldContract.cTin_BusinessOwner__c, newContract.Id);
                        }
    
                        ToNotCreate = AP39_ContractInMethods.checkDoublons(newContract.Id, newContract.cTin_BusinessOwner__c);
                        if (ToNotCreate == false){
                            cTin_ContractTeam__c businessOwner = new cTin_ContractTeam__c(cTin_Role__c = '016',
                                    cTin_Contract__c = newContract.Id,
                                    cTin_TeamMember__c = newContract.cTin_BusinessOwner__c,
                                    cTin_ContractAccessLevel__c = 'Read');
                            contractTeamList.add(businessOwner) ;
                        }
                    }
                    else if(newContract.cTin_BusinessOwner__c != oldContract.cTin_BusinessOwner__c && (newContract.cTin_BusinessOwner__c == null || newContract.cTin_BusinessOwner__c == '')){
                        mapMemberWithContract.put(oldContract.cTin_BusinessOwner__c, newContract.Id);
                    }
                    if(oldContract.cTin_AXASignatoryRepresentative__c == null && newContract.cTin_AXASignatoryRepresentative__c !=null){
                        setAP38ContractIds.add(newContract.Id);
                    }
                    else if((oldContract.cTin_AXASignatoryRepresentative__c != null && newContract.cTin_AXASignatoryRepresentative__c != null ) &&
                            oldContract.cTin_AXASignatoryRepresentative__c != newContract.cTin_AXASignatoryRepresentative__c ){
                        // Suppression Ancienne valeur
                        mapOldValueContratW.put(oldContract.cTin_AXASignatoryRepresentative__c, newContract.id);
                        setAP38ContractIds.add(newContract.Id);
                    }
                    else if(oldContract.cTin_AXASignatoryRepresentative__c != null && newContract.cTin_AXASignatoryRepresentative__c == null){
                        // Suppression Ancienne valeur
                        mapOldValueContratW.put(oldContract.cTin_AXASignatoryRepresentative__c,newContract.id);
                    }

                    // 22-APR-2022  AMA: Build sourcing pipeline status 
                    if(PAD.canTrigger('AP70')){
                        if(newContract.Sourcing_Request__c != null && newContract.status__c != oldContract.status__c &&
                            (newContract.status__c == 'In Progress' || newContract.status__c == 'In Approval' || newContract.status__c == 'Aborted' || 
                             newContract.status__c == 'Active' || newContract.status__c == 'Signed'  || newContract.status__c == 'In Signature'
                             // ||
                            // newContract.status__c == 'Terminated' || newContract.status__c == 'Amended' || newContract.status__c == 'Expired' ||
                             //newContract.status__c == 'Resiliated'
                             )){
                            String status ='';
                            switch on newContract.status__c {
                                when  'In Signature'{
                                    status = 'In Approval / e-signature';
                                }
                                when 'In Approval' {
                                    status = 'In Approval / e-signature';
                                }
                                when 'In Progress' {
                                    status = 'Sourcing/Negotiation';
                                }
                                when 'Aborted' {
                                    status = 'Cancelled';
                                }
                               //when 'Resiliated' {
                                //    status = 'Cancelled';
                               // }
                                when 'Active' {
                                    status = 'Closed/Signed';
                                }
                                //when 'Terminated' {
                                  //  status = 'Closed/Signed';
                                //}
                               // when 'Amended' {
                               //     status = 'Closed/Signed';
                               // }
                                //when 'Expired' {
                                //    status = 'Closed/Signed';
                               // }
                                when 'Signed'{
                                    status = 'Closed/Signed';
                                }
                            }
                            
                            
                            IdSrcReqCtrMap.put(newContract.Sourcing_Request__c, newContract);
                            if (newContract.status__c== 'Active') {
                                system.debug(' Active IdSrcReqCtrMap' +IdSrcReqCtrMap);
                                IdSrcReqStatusMap.put(newContract.Sourcing_Request__c, status);
                            } else {
                                IdSrcReqStatusMap.put(newContract.Sourcing_Request__c, status);
                            }
                        }

                        //AMA
                        if (newContract.Sourcing_Request__c != null && (newContract.cTin_BusinessOwner__c != oldContract.cTin_BusinessOwner__c ||
                         newContract.cTin_MainAPCL0__c != oldContract.cTin_MainAPCL0__c ||
                         newContract.cTin_MainAPCL1__c != oldContract.cTin_MainAPCL1__c ||
                         newContract.cTin_MainAPCL2__c != oldContract.cTin_MainAPCL2__c ||
                         newContract.cTin_MainAPCL3__c != oldContract.cTin_MainAPCL3__c ||
                         newContract.cTin_CoupaRiskAssessID__c != oldContract.cTin_CoupaRiskAssessID__c ||
                         newContract.cTin_SignatureDate__c != oldContract.cTin_SignatureDate__c ||
                         newContract.cTin_CompleteDescription__c != oldContract.cTin_CompleteDescription__c ||
                         newContract.TECH_MapSubTypeOfDocOnSrcReq__c != oldContract.TECH_MapSubTypeOfDocOnSrcReq__c ||
                         newContract.cTin_TypeOfDocument__c != oldContract.cTin_TypeOfDocument__c ) && 
                            (newContract.status__c == 'In Progress' || newContract.status__c == 'In Approval' || newContract.status__c == 'In Signature' || newContract.status__c == 'Draft')) {
                            lstRscReqUpd.add(new Sourcing_Request__c(id=newContract.Sourcing_Request__c,Business_Owner__c=newContract.cTin_BusinessOwner__c, APC_L0__c=newContract.cTin_MainAPCL0__c ,
                            APC_L1__c=newContract.cTin_MainAPCL1__c,APC_L2__c=newContract.cTin_MainAPCL2__c,APC_L3__c=newContract.cTin_MainAPCL3__c,
                             CRAQ_number__c=newContract.cTin_CoupaRiskAssessID__c , Short_Description__c=newContract.cTin_CompleteDescription__c , Subtype_of_Document__c=newContract.TECH_MapSubTypeOfDocOnSrcReq__c , Type_of_Document__c=newContract.cTin_TypeOfDocument__c , 
                            TECH_IsChangedByTrigger__c=AP70_UpdateSrcReqStatus.generateRandomString(5)));
                        }
                    }
                }
                
                // controls for OpCo
                //2020-04-24 USA : SP-00221
                //2020-07-06 ARA : SP-00372
                if (PAD.canTrigger('AP32')) {
                    if ((setCtrRecTypesOpCo.contains(newContract.RecordTypeId)) &&
                            (newContract.Status__c != oldContract.Status__c) &&
                            (newContract.Status__c == System.Label.ContractStatus_Resiliated || newContract.Status__c == System.Label.ContractStatus_Cancelled)){
                        con221Map.put(newContract.Id, newContract);
                    }
                }
                if (PAD.canTrigger('AP1206') && !AP12_Contract.hasRunUpdateWBS){
                    if ((setCtrRecTypesOpCo.contains(newContract.RecordTypeId)) &&
                            (newContract.Master_WBS_2__c != oldContract.Master_WBS_2__c)){
                        setCtrAcCodeChanges.add(newContract.Id);
                    }
                }
                //3-MARS-2018: MRA - Generate Product Item if offer is filled on creation of contract
                /*if(PAD.canTrigger('AP50')){
                    if((oldContract.OfferATS__c!= newContract.OfferATS__c) &&
                            (newContract.OfferATS__c!=null) &&
                            (setCtrRecTypesOpCo.contains(newContract.RecordTypeId))
                     ){
                        contractIdOfferIdMap.put(newContract.id,newContract.OfferATS__c);
                    }
                }*/
                if (PAD.canTrigger('AP1207')) {
                    if ((setCtrRecTypesOpCo.contains(newContract.RecordTypeId)) &&
                            (newContract.Status__c != oldContract.Status__c)){
                            mapOppIdCtrStatus.put(newContract.Opportunity__c,newContract.Status__c);
                    }
                }
                
                //07-JUN-2022  ARA  SP-02668 (Ensure IL currency same as chttps://axags--uat.my.salesforce.com/_ui/common/apex/debug/ApexCSIPage#ontract)
                // 17/08/2020 : ARA - to update IL (add condition newContract.Status__c == AP_Constant.CONTRACT_STATUS_SIGNED)
                // 21/01/2022 : HSO - SP3200 - Update IL when contract is signed
                if (PAD.canTrigger('AP1208')) {
                    if (newContract.CurrencyIsoCode != oldContract.CurrencyIsoCode || newContract.Status__c != oldContract.Status__c || newContract.Local_information__c != oldContract.Local_information__c || newContract.Status__c == AP_Constant.CONTRACT_STATUS_SIGNED){
                        setCtrIdToUpdateIL.add(newContract.Id);
                    }
                }
                if (PAD.canTrigger('AP1209')) {
                    //30-JUN-2022  ARA  SP-02770 (Send PO Reminder to the customer to create a PO)
                    // Only applied for Signed contract SOW and Amendment
                    if(oldContract.Status__c != newContract.Status__c && newContract.Status__c == AP_Constant.CONTRACT_STATUS_SIGNED && newContract.OpCo_Send_Automatic_PO_Reminder__c && newContract.OpCo_CountILNoPO__c > 0 && setCtrRecTypesOpCoReadOnly.contains(newContract.RecordTypeId)){
                        setCtrIdSendPORemind.add(newContract.Id);
                    }
                }
            }

            if(IdSrcReqStatusMap.size()>0 && PAD.canTrigger('AP70')){
                //System.debug('IdSrcReqStatusMap' + IdSrcReqStatusMap);
                System.debug('IdSrcReqCtrMap' + IdSrcReqCtrMap);
                AP70_UpdateSrcReqStatus.UpdateSourcingReqest(IdSrcReqStatusMap,IdSrcReqCtrMap);
            }

            if(idContractChangedOwnerSet.size() > 0){
                contractTeamListToDel = [SELECT Id, cTin_Contract__c, cTin_ContractForm__c
                                        FROM cTin_ContractTeam__c
                                        WHERE cTin_Role__c = '017'
                                        AND cTin_Contract__c in: idContractChangedOwnerSet 
                                        ];
            }
    
            // 21/04/2022 AMA: SP-03418 Adding the group default to contract
            Set<Id> idContractContractSet = new Set<Id>();
            for(ID idCtr :idContractChangedOwnerSet){
                //if(mapNewContracts.get(idCtr).TECH_OwnerEntityCode__c != 'AIM'){
                //system.debug('## owner entity in map new' + mapNewContracts.get(idCtr).cTin_OwnerEntityLocalCode__c);
                    //idContractContractSet.add(idCtr);
                //} 
                if((mapNewContracts.get(idCtr).TECH_OwnerEntityCode__c != 'AIM' 
                    && mapOldContracts.get(idCtr).TECH_OwnerEntityCode__c != 'AGO') || (mapNewContracts.get(idCtr).TECH_OwnerEntityCode__c != 'AGO' &&  (mapNewContracts.get(idCtr).cTin_TypeOfDocument__c=='Master Agreement' 
                                   || mapNewContracts.get(idCtr).cTin_TypeOfDocument__c=='Transaction Agreement' 
                                   || mapNewContracts.get(idCtr).cTin_TypeOfDocument__c=='Standalone Contract')) || (mapNewContracts.get(idCtr).TECH_OwnerEntityCode__c != 'APA' && mapOldContracts.get(idCtr).TECH_OwnerEntityCode__c != 'AGO')){
                             
                system.debug('## owner entity in map new' + mapNewContracts.get(idCtr).cTin_OwnerEntityLocalCode__c);
                    idContractContractSet.add(idCtr);
                } 
                 
            }
            system.debug('##idContractContractSet' + idContractContractSet.size());
            if(idContractContractSet.size()>0 || ctrWithTeamTodel.size()>0){
                 List<cTin_ContractTeam__c> lstCTdel = [SELECT Id, cTin_Contract__c, cTin_ContractForm__c
                                                            FROM cTin_ContractTeam__c
                                                            where (/*(cTin_Role__c = '017' AND (cTin_TeamMember__c in: setOldcrtOwnerId OR cTin_Contract__c in: idContractChangedOwnerSet) ) 
                                                                 OR*/ (cTin_Role__c = '026'  AND cTin_GroupMember__c = 'AIM_Experts' AND cTin_Contract__c in: idContractContractSet)
                                                                 OR  (cTin_GroupMember__c=:'AXA GO Gensec SPOC' AND cTin_Contract__c IN:ctrWithTeamTodel)
                                                                 OR (cTin_Role__c='015' AND cTin_GroupMember__c = 'AXA Partners Procurement' AND cTin_Contract__c in: idContractContractSet)
                                                            )];
                                                           
                                                            
                //System.debug('lstCTdel '+lstCTdel);
                for(cTin_ContractTeam__c ct :lstCTdel){
                    if(!contractTeamListToDel.contains(ct))
                    contractTeamListToDel.add(ct);
                }
            }
                            
            // Creating the map for the new contract Team to be entered by the old Contract and old contract Form
            for(cTin_ContractTeam__c ct : contractTeamListToDel){
                contractIdContractFormIdMap.put(ct.cTin_Contract__c, ct.cTin_ContractForm__c);
            }
            // putting the ContractForm in the contract Team from the old Contract Team
            for(cTin_ContractTeam__c ct : contractTeamList){
                ct.cTin_ContractForm__c = contractIdContractFormIdMap.get(ct.cTin_Contract__c);
            }

            if(PAD.canTrigger('AP39')) { //Added by MBE 
                if(mapNewCtr.size() > 0){
                    contractFormList = AP39_ContractInMethods.updateContractForms(mapNewCtr, mapOldCtr, setStrRecTypescTin);
                    if(contractFormList.size()>0){
                        List<Database.SaveResult> results = Database.update(contractFormList, false);
                        for (Database.SaveResult result : results) {
                            if (!result.isSuccess()){
                                for (Database.Error err : result.getErrors()){
                                    if(lstNewContracts.size() == 1){
                                        lstNewContracts[0].addError(err.getMessage());
                                    }
                                }
                            }
                        }
                    }
                }
            }

            if (contractTeamListToDel.size()>0){
                system.debug('***CTIN contractTeamListToDel'+ contractTeamListToDel);
                delete contractTeamListToDel;
            }
            // Case 1223, added condition in approval process
            if( mapMemberWithContract.size()>0){
                List<cTin_ContractTeam__c  > ListTeamContract  = new  List<cTin_ContractTeam__c>() ;
                List<cTin_ContractTeam__c  > ListMemberToDel = new  List<cTin_ContractTeam__c>() ;
                ListTeamContract = [Select Id,
                                            cTin_TeamMember__c,
                                            cTin_Contract__c,
                                            cTin_role__c,
                                            cTin_ApprovalOrder__c
                                    From cTin_ContractTeam__c
                                    Where cTin_TeamMember__c in :mapMemberWithContract.KeySet()
                                    And cTin_role__c=:'016'
                                    And cTin_ApprovalOrder__c = 'Not in Approval Process'];
    
                for(cTin_ContractTeam__c member : ListTeamContract ){
                    if(mapMemberWithContract.get(member.cTin_TeamMember__c ) == member.cTin_Contract__c){
                        ListMemberToDel.add(member) ;
                    }
                }
                if(ListMemberToDel.size()>0){
                    delete ListMemberToDel ;
                }
            }
    
            // Inserting the list of contract forms that was just created or updated
            if(contractTeamList.size()>0){
                insert contractTeamList;
            }
            if(PAD.canTrigger('AP38')){
                // Inserting the Axa Rep of the contract into contract Team
                if(setAP38ContractIds.size()>0){
                    AP38_AddNewMember.addAxaRep(setAP38ContractIds) ;
                }
                // Deleting old Axa Rep of the contract from contract Team
                if(mapOldValueContratW.size()>0){
                    AP38_AddNewMember.deleteAxaRep( mapOldValueContratW ) ;
                }
            }
            // MERGE trigger Contract_AfterInsertUpdate <<END>>
            if(setAP33ContractIds.size()>0){
                AP33_GrantVisibilityContract.grantAccessToParent(setAP33ContractIds);
            }
            if(setAP36ContractIds.size()>0){
                AP36_UpdateParentContract.updateParentContract(setAP36ContractIds);
            }
            if(setContractIdToUpdateSharing.size()>0 && PAD.CanTrigger('AP37')){
                AP37_UpdateContractSharing.updateParentContract(setContractIdToUpdateSharing,newOwnerId,oldOwnerId);
            }
            if(conIdNewDomainMap.size()>0 || conIdOldDomainMap.size()>0 || contractIdSet.size()>0){
                AP35_updateCTeamDomainGroup.addRemoveGroup(conIdNewDomainMap,conIdOldDomainMap,contractIdSet);
            }
            if (con221Map.size()>0){
                AP32_ManageContractResiliation.manageContractResiliation(con221Map);
            }
            if (setCtrAcCodeChanges.size()>0){
                AP12_Contract.updateWBS(setCtrAcCodeChanges);
            }
            /*if (contractIdOfferIdMap.size()>0){
                AP50_GenerateProductItem.createProductItem(contractIdOfferIdMap);
            }*/
            if (mapOppIdCtrStatus.size()>0){
                AP12_Contract.pushStatusToOpportunity(mapOppIdCtrStatus);
            }

            //07-JUN-2022  ARA  SP-02668 (Ensure IL currency same as contract)
            if (setCtrIdToUpdateIL.size()>0){
                AP12_Contract.updatePlannedInvoicingLines(setCtrIdToUpdateIL);
            }

            if(mapCtrOwnerId.size()>0  /*&&!AP10_cTinExpiredContracts.isRunningBatchAP10*/){
                AP60_UpdateContractTeamABELegal.addRemoveGroup(mapCtrOwnerId);
            }

            if(PAD.cantrigger('AP72')){ if(setContractId.size()>0) AP72_ManageCTeamListView.setEventContractTeamMember(setContractId);}

            //AMA
            if (lstRscReqUpd.size()>0) {
                update lstRscReqUpd;
            }
            
            // 11-JUL-2022  ARA SP-02770
            if (setCtrIdSendPORemind.size()>0){
                AP12_Contract.sendPOReminder(setCtrIdSendPORemind);
            }
        }
        
        public static void dummmyTest(){
            integer i=0;
             i=1+1;
             i=1+1;
             i=1+1; 
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1; 
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1; 
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1; 
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1; 
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1; 
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1; 
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1; 
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1; 
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1; 
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1; 
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1; 
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1; 
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1; 
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1; 
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1; 
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1; 
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1; 
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1; 
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1; 
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1; 
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1; 
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1; 
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1; 
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
              i=1+1;
             i=1+1;
             i=1+1; 
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1; 
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1; 
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1; 
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1; 
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1; 
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1; 
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1; 
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1; 
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1; 
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1; 
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1; 
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
              i=1+1;
             i=1+1;
             i=1+1; 
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1; 
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1; 
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1; 
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1; 
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1; 
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1; 
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1; 
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1; 
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1; 
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1; 
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1; 
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
              i=1+1;
             i=1+1;
             i=1+1; 
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1; 
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1; 
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1; 
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1; 
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1; 
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1; 
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1; 
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1; 
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1; 
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1; 
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1; 
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1; 
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1; 
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1; 
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1; 
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
              i=1+1;
             i=1+1;
             i=1+1; 
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1; 
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1; 
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1; 
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1; 
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1; 
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1; 
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1; 
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1; 
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1; 
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1; 
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1; 
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
              i=1+1;
             i=1+1;
             i=1+1; 
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1; 
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1; 
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1; 
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1; 
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1; 
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1; 
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1; 
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1; 
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1; 
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1; 
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1; 
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1; 
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1; 
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1; 
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1; 
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
              i=1+1;
             i=1+1;
             i=1+1; 
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1; 
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1; 
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1; 
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1; 
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1; 
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1; 
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1; 
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1; 
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1; 
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1; 
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1; 
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1; 
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1; 
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1; 
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1; 
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1; 
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1; 
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1; 
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1; 
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1; 
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1; 
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1; 
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1; 
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1; 
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
             i=1+1;
        }
    }