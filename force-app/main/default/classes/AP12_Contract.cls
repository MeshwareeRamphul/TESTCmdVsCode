public without sharing class AP12_Contract {
/*----------------------------------------------------------------------
    -- - Name          : AP12_Contract
    -- - Author        : Eric Wartelle
    -- - Description   : Methods to be used for the ContractTrigger
    --
    -- - History:
    -- Date         Name  Version  Remarks
    -- -----------  ----  -------  ---------------------------------------
    --              Eric   1.0      Initial version
    --              Eric   1.1      Ajout des appels system.debug pour suivre les fonctions appelés
    --              USA    1.2      Ajout du mapping champ Signature_Type__c specifique
    -- 19-FEB-2018  USA    1.3      Restrict language update (no asia or spain)
    -- 27-APR-2018  USA    1.4      update set values: moved status Ready for Signature to set Read only
    --    JUN-2019  USA    1.5      SP-00072
    -- 10-JUN-2020  USA    1.6      SP-00320 (Code Optimisation)
    -- 17-AUG-2020  ARA    1.7      SP-00109
    -- 07-JUN-2022  ARA    1.3      SP-02668
    -- 05-JUL-2022  ARA    1.4      SP-02770 (Contract | Change PO reminder functionality)
-------------------------------------------------------------------------*/

    // 21/09/2017 :set boolean to prevent recursive calls
    public static boolean hasRunUpdateWBS         = false;
    static Map<Id, Account> vAccountsWithSignature;
    //Statics attributs
    public static List<String> contractStatusList =
            new List<String>{System.label.ContractStatus_Cancelled, System.label.ContractStatus_Draft,
                    System.label.ContractStatus_RejectedByCustomer, System.label.ContractStatus_InternalValidation,
                    System.label.ContractStatus_Validated, System.label.ContractStatus_CustomerValidation,
                    System.label.ContractStatus_ReadyForSignature, System.label.ContractStatus_SentForSignature,
                    System.label.ContractStatus_Signed, System.label.ContractStatus_Terminated};

    /**
    * ----------------------------------------------------------------------------------------------
    * Updates Record Type when transitioning between Status of the group ReadyOnly and Status of the group Edit
    * ----------------------------------------------------------------------------------------------
    * @param    pContractMap Map<Id,Contract__c>    : map of contracts from Trigger.newMap
    * ----------------------------------------------------------------------------------------------
    */
    public static void updateRecordType(Map<Id,Contract__c> pContractMap) {
        //USA 2018/04/27 : update set values: moved status Ready for Signature to set Read only
        Set<String> ReadOnlyValues      = new Set<String>{System.Label.ContractStatus_Signed,System.Label.ContractStatus_Ended,System.Label.ContractStatus_Terminated,System.Label.ContractStatus_SentForSignature,System.Label.ContractStatus_Cancelled,System.Label.ContractStatus_ReadyForSignature};
        Set<String> EditValues          = new Set<String>{System.Label.ContractStatus_Draft,System.Label.ContractStatus_InternalValidation,System.Label.ContractStatus_CustomerValidation};
        Set<Id> setCtrRecTypesOpCoSOW   = new set<Id>{ContractTriggerHandler.idRecOpCoSingleEdit, ContractTriggerHandler.idRecOpCoSingleReadOnly};
        Set<Id> setCtrRecTypesOpCoAmend = new set<Id>{ContractTriggerHandler.idRecOpCoAmendEdit, ContractTriggerHandler.idRecOpCoAmendReadOnly};

        for (Contract__c vContract : pContractMap.values()) {
            //check contract is OpCo
            if (ContractTriggerHandler.setCtrRecTypesOpCo.contains(vContract.RecordTypeId)){
                //contract status whereby the recordtype should be of type edit
                if (EditValues.contains(vContract.Status__c)) {
                    if (setCtrRecTypesOpCoSOW.contains(vContract.RecordTypeId)) {
                        vContract.RecordTypeId = ContractTriggerHandler.idRecOpCoSingleEdit;
                    }
                    else if (setCtrRecTypesOpCoAmend.contains(vContract.RecordTypeId)) {
                        vContract.RecordTypeId = ContractTriggerHandler.idRecOpCoAmendEdit;
                    } // ALLINFIN-510 USA 21/08/2017
                    else if (vContract.RecordTypeId != ContractTriggerHandler.idRecLightContract){
                        pContractMap.get(vContract.Id).addError(Label.AP12_ErrLightCtrRecTypeAssignment);
                    }
                }
                //contract status whereby the recordtype should be of type read only
                if (ReadOnlyValues.contains(vContract.Status__c)) {
                    if (setCtrRecTypesOpCoSOW.contains(vContract.RecordTypeId)) {
                        vContract.RecordTypeId = ContractTriggerHandler.idRecOpCoSingleReadOnly;
                    }
                    else if (setCtrRecTypesOpCoAmend.contains(vContract.RecordTypeId)) {
                        vContract.RecordTypeId = ContractTriggerHandler.idRecOpCoAmendReadOnly;
                    } // ALLINFIN-510 USA 21/08/2017
                    else if (vContract.RecordTypeId != ContractTriggerHandler.idRecLightContract){
                        pContractMap.get(vContract.Id).addError(Label.AP12_ErrLightCtrRecTypeAssignment);
                    }
                }
            }
        }
    }


    /**
    * ----------------------------------------------------------------------------------------------
    * Method to Prefill Legal entity from commercial entity
    * ----------------------------------------------------------------------------------------------
    * @param    pContractList List<Contract__c> : the contract sent from the trigger
    * @return   set<Id> : IDs of new accounts prefilled in legal entity
    * ----------------------------------------------------------------------------------------------
    */
    public static set<Id> prefillLegalEntity(List<Contract__c> pContractList) {
        List<Id> vAllEntitiesId       = new List<Id>();
        List<Id> vAllMasterEntitiesId = new List<Id>();
        set<Id> setLEId = new set<Id>();
        for (Contract__c vContract : pContractList) {
            // HVA 10-2017 : method must execute only for All-In Contracts
            if ((vContract.C_Account__c != null) && ContractTriggerHandler.setCtrRecTypesOpCo.contains(vContract.RecordTypeId)) {
                vAllEntitiesId.add(vContract.C_Account__c);
            }
        }

        Map<Id, Account> vEntities = new Map<Id, Account>([SELECT ID, parentId, (SELECT Id FROM ChildAccounts) FROM Account WHERE Id IN :vAllEntitiesId]);
        for (Account vEntity : vEntities.values()) {
            vAllMasterEntitiesId.add(vEntity.parentId);
        }

        // Create Master Entity List
        Map<Id, Account> vMasterEntities = new Map<Id, Account>([SELECT Id, (SELECT Id FROM ChildAccounts WHERE recordType.developerName = :AP_Constant.RT_DN_LEGAL_ENTITY) FROM Account WHERE Id IN :vAllMasterEntitiesId]);

        // Possibilities :
        // Entity is linked with one LE only and ME is not linked to a legal entity ==> prefill
        // Entity is linked with one LE only and ME is linked to a legal entity ==> do nothing
        // Entity is linked to 0 LE but ME is linked to a legal entity ==> prefill
        for (Contract__c vContract : pContractList) {
            // HVA 10-2017 : method must execute only for All-In Contracts
            if ((vContract.C_Account__c != null) && (vContract.Account__c == null) && ContractTriggerHandler.setCtrRecTypesOpCo.contains(vContract.RecordTypeId)) {
                Account vEntityRetrieved = vEntities.get(vContract.C_Account__c);
                // First check if the entity has a master entity with legal entities related directly
                if (vEntityRetrieved != null) {
                    Boolean masterEntitiesHasChilds = false;
                    if (vEntityRetrieved.ParentId != null) {
                        Account vMasterEntityRetrieved = vMasterEntities.get(vEntityRetrieved.ParentId);
                        // Check if master entity has at least one child  ==> means no prefill direct from entity
                        if (vMasterEntityRetrieved != null && vMasterEntityRetrieved.childAccounts != null && vMasterEntityRetrieved.childAccounts.size() > 0) {
                            masterEntitiesHasChilds = true;
                            // Set the potential prefill Legal entity (if ME has a legal entity and if entity has no Legal entity)
                            if (((vEntityRetrieved.childAccounts == null) || (vEntityRetrieved.childAccounts.size() < 1)) && (vMasterEntityRetrieved.childAccounts.size() == 1)) {
                                vContract.Account__c = vMasterEntityRetrieved.childAccounts[0].Id;
                            }
                        }
                    }
                    // Case there is only one direct link between entity and legal entity (and no link from master entity)
                    if (vEntityRetrieved.childAccounts != null && vEntityRetrieved.childAccounts.size() == 1 && !masterEntitiesHasChilds) {
                        vContract.Account__c = vEntityRetrieved.childAccounts[0].Id;
                    }
                }
            }
            setLEId.add(vContract.account__c);
        }
        return setLEId;
    }


    /**
    * ----------------------------------------------------------------------------------------------
    * Method to Prefill entity from legal entity
    * ----------------------------------------------------------------------------------------------
    * @param    pContractList List<Contract__c> : list of contracts from Trigger.new
    * @param    pOldContracts List<Contract__c> : list of contracts from Trigger.old
    * ----------------------------------------------------------------------------------------------
    */
    public static void prefillEntity(List<Contract__c> pContractList, Map<Id, Contract__c> pOldContracts) {
        List<Id> vAllLegalEntitiesId = new List<Id>();
        for (Contract__c vContract : pContractList) {
            // HVA 10-2017 : method must execute only for All-In Contracts
            // USA 2018-04 : update to exclude cTin and ATS
            //!setCtinRecTypeId.contains(vContract.RecordTypeId)
            //setAGSRecTypeId.contains(vContract.RecordTypeId)
            if ((vContract.Account__c != null) && (ContractTriggerHandler.setCtrRecTypesOpCo.contains(vContract.RecordTypeId))) {
                vAllLegalEntitiesId.add(vContract.Account__c);
            }
        }

        Map<Id, Account> vLegalEntities = new Map<Id, Account>([SELECT ID, parentId, parent.recordType.Name FROM Account WHERE Id IN :vAllLegalEntitiesId]);

        // If Entity is filled and has only one child, prefill with legal entity
        for (Contract__c vContract : pContractList) {
            // HVA 10-2017 : method must execute only for All-In Contracts
            // USA 2018-04 : update to exclude cTin and ATS
            if (ContractTriggerHandler.setCtrRecTypesOpCo.contains(vContract.RecordTypeId)){
                //!setCtinRecTypeId.contains(vContract.RecordTypeId)){
                if (pOldContracts != null && pOldContracts.get(vContract.Id) != null) {
                    Id vOldEntityValue = pOldContracts.get(vContract.Id).Account__c;
                    // First remove selected Commercial entity if LE changed
                    if (vOldEntityValue != vContract.Account__c) {
                        vContract.C_Account__c = null;
                    }
                }
                if (vContract.Account__c != null && vContract.C_Account__c == null) {
                    if (vLegalEntities.containsKey(vContract.Account__c)){
                        Account vLegalEntityRetrieved = vLegalEntities.get(vContract.Account__c);
                        if (vLegalEntityRetrieved.parentId != null && vLegalEntityRetrieved.parent.recordType.Name == AP_Constant.RT_DN_ENTITY)  {
                            vContract.C_Account__c = vLegalEntityRetrieved.parentId;
                        }
                    }
                }
            }
        }
    }


    /**
    * ----------------------------------------------------------------------------------------------
    * Method to fill in the signature type in case entity Changed or in case of new contract
    * ----------------------------------------------------------------------------------------------
    * @param    pOldContracts List<Contract__c> : list of contracts from Trigger.old
    * @param    pNewContracts List<Contract__c> : list of contracts from Trigger.new
    * ----------------------------------------------------------------------------------------------
    */
    public static void fillInSignatureType(Map<Id, Contract__c> pOldContracts, List<Contract__c> pNewContracts) {
        List<Id> vNewSelectedAccounts = new List<Id>();
        for (Contract__c vContract : pNewContracts) {
            if (vContract.Account__c != null) {
                vNewSelectedAccounts.add(vContract.Account__c);
            }
        }
        // Retrieve new Accounts selected signature types values
        vAccountsWithSignature = new Map<Id, Account>([SELECT Id, Signature_Type__c FROM Account WHERE Id IN :vNewSelectedAccounts]);

        if(vAccountsWithSignature != null){
            for (Contract__c vContract : pNewContracts) {
                Id vOldAccountId = (pOldContracts == null ? null : pOldContracts.get(vContract.Id).Account__c);
                // 2018-04-10 USA : filter AGS record types
                if(!vContract.TECH_IsClonedContract__c && ContractTriggerHandler.setCtrRecTypesOpCo.contains(vContract.RecordTypeId)){
                    if (vAccountsWithSignature.containsKey(vContract.Account__c) && vContract.Account__c != vOldAccountId || (vContract.Account__c != null && vContract.Signature_Type__c == null)) {
                        if (vAccountsWithSignature.get(vContract.Account__c).Signature_Type__c == AP_Constant.SIGNATURE_MANUAL) {
                            vContract.Signature_Type__c = AP_Constant.SIGNATURE_MANUAL;
                        }
                        //02/06/2017-MRA : added check for esignature type Contract-In
                        else if(vAccountsWithSignature.get(vContract.Account__c).Signature_Type__c ==AP_Constant.SIGNATURE_CONTRACTIN){
                            vContract.Signature_Type__c = AP_Constant.SIGNATURE_CONTRACTIN;
                        }
                        //23/10/2017-USA : added check for signature type specific
                        else if(vAccountsWithSignature.get(vContract.Account__c).Signature_Type__c == Label.Contract_Signature_Type_Specific){
                            vContract.Signature_Type__c = Label.Contract_Signature_Type_Specific;
                        }
                        else {
                            vContract.Signature_Type__c = AP_Constant.SIGNATURE_ELECTRONIC;
                        }
                    }
                }
            }
        }
    }


    /**
    * ----------------------------------------------------------------------------------------------
    * Method to update WBS from contracts on invoicing lines
    * ----------------------------------------------------------------------------------------------
    * @param    pNewContracts List<Contract__c> : list of contracts from Trigger.new
    * @param    pOldContracts List<Contract__c> : list of contracts from Trigger.old
    * ----------------------------------------------------------------------------------------------
    */
    public static void updateWBS(Set<Id> setCtrId){
        // 21/09/2017 :set boolean to prevent recursive calls
        if(test.isRunningTest())
            hasRunUpdateWBS=true;
        
        Id invLineEditRT =  Schema.SObjectType.Planned_Invoicing_Line__c.getRecordTypeInfosByName().get('InvLine Edit').getRecordTypeId();
        List<Contract__c> vContractList = [SELECT Id, Master_WBS_2__c, RecordTypeId, (SELECT Id, Master_WBS_Structure__c, Tech_UpdatedByPS__c, Master_WBS_Structure__r.name FROM Planned_Invoicing_Lines2__r WHERE Status__c =: AP_Constant.INVLINE_STATUS_DRAFT AND RecordTypeId =: invLineEditRT)
                                           FROM Contract__c
                                           WHERE Id IN :setCtrId];

        if (setCtrId.size() > 0){
            for (Contract__c vContract : vContractList){
                List<Planned_Invoicing_Line__c> vPinvLinesToUpdate = new List<Planned_Invoicing_Line__c>();
                 if (vContract.Master_WBS_2__c != null) {
                     if (vContract.Planned_Invoicing_Lines2__r != null && vContract.Planned_Invoicing_Lines2__r.size() > 0) {
                        for (Planned_Invoicing_Line__c vPInvLine : vContract.Planned_Invoicing_Lines2__r) {
                            if (vPInvLine.Master_WBS_Structure__c == null || String.isEmpty(vPInvLine.Master_WBS_Structure__c) || vPInvLine.Master_WBS_Structure__r.name.startsWithIgnoreCase('TBD')) {
                                vPInvLine.Master_WBS_Structure__c = vContract.Master_WBS_2__c;
                                vPinvLinesToUpdate.add(vPInvLine);
                            }
                        }
                     }
                }
                if (vPinvLinesToUpdate != null && vPinvLinesToUpdate.size() > 0) {
                    update vPinvLinesToUpdate;
                }
            }
        }
    }


    /**
    * ----------------------------------------------------------------------------------------------
    * when the status of a contract is modified, the new status is pushed to the opportunity
    * ----------------------------------------------------------------------------------------------
    * @param    oldContracts List<Contract__c> : the contracts before the update
    * @param    newContracts List<Contract__c> : the contracts after the update
    * ----------------------------------------------------------------------------------------------
    */
    public static void pushStatusToOpportunity(Map<Id,String> mapOppIdCtrStatus){
        List<Opportunity> opptiesToBeUpdated = new List<Opportunity>();

        // We're going to get each concerns oppties
        List<Opportunity> oppties = [SELECT Id, TECH_ContractStatus__c, StageName FROM Opportunity WHERE Id in :mapOppIdCtrStatus.keySet()];
        for(Opportunity oppty : oppties){
            String oldStatus = oppty.TECH_ContractStatus__c;
            String newStatus = mapOppIdCtrStatus.get(oppty.Id);
            System.debug(LoggingLevel.INFO, '## AP12_Contract.pushStatusToOpportunity Old Status : ' + oppty.TECH_ContractStatus__c);
            System.debug(LoggingLevel.INFO, '## AP12_Contract.pushStatusToOpportunity New Status : ' + mapOppIdCtrStatus.get(oppty.Id));
            if(oppty.StageName != 'Opportunity Won' && oppty.StageName != 'Opportunity Lost' && oppty.StageName != 'Opportunity Cancelled'){
                if(oldStatus != newStatus){
                    oppty.TECH_ContractStatus__c = AP12_Contract.getHighestStatus(oldStatus, newStatus);
                    opptiesToBeUpdated.add(oppty);
                }
            }
        }
        System.debug(LoggingLevel.INFO, '## AP12_Contract.pushStatusToOpportunity no oppty : ' + opptiesToBeUpdated.size());
        if (opptiesToBeUpdated.size()>0){
            update opptiesToBeUpdated;
        }
    }


    /**
    * ----------------------------------------------------------------------------------------------
    * return the index of the contract status
    * ----------------------------------------------------------------------------------------------
    * @param    contractStatus String : the status of the contract
    * @return (Integer)               : return the index of the contract status
    * ----------------------------------------------------------------------------------------------
    */
    private static Integer getStatusNumber(String contractStatus){
        //Local variable declaration
        Integer result = 0;
        Integer index = 0;

        System.debug(LoggingLevel.INFO, '## AP12_Contract ## getStatusNumber start');
        //Checking the index for the contractStatus
        for(String contractStatusItem : AP12_Contract.contractStatusList){
            if(contractStatusItem == contractStatus){
                result = index;
            }
            index++;
        }

        //System.debug call for debug log purpose
        System.debug(LoggingLevel.DEBUG, '## AP12_Contract getStatusNumber - Contract Status : ' + contractStatus);
        System.debug(LoggingLevel.DEBUG, '## AP12_Contract getStatusNumber - result : ' + result);
        System.debug(LoggingLevel.INFO, '## AP12_Contract ## getStatusNumber End');

        //Returning the result
        return result;
    }


    /**
    * ----------------------------------------------------------------------------------------------
    * return the status with the highest index
    * ----------------------------------------------------------------------------------------------
    * @param    contractStatusA String : the first status to be compared
    * @param    contractStatusB String : the second status to be compared
    * @return (String)                 : return the status with the highest index
    * ----------------------------------------------------------------------------------------------
    */
    private static String getHighestStatus(String contractStatusA, String contractStatusB){
        //Local variable declaration
        Integer indexContractStatusA = AP12_Contract.getStatusNumber(contractStatusA);
        Integer indexContractStatusB = AP12_Contract.getStatusNumber(contractStatusB);

        //System.debug call for debug log purpose
        System.debug(LoggingLevel.INFO, '## AP12_Contract ## getHighestStatus start');
        System.debug(LoggingLevel.DEBUG, '## AP12_Contract getHighestStatus - Status A : ' + contractStatusA);
        System.debug(LoggingLevel.DEBUG, '## AP12_Contract getHighestStatus - Status B : ' + contractStatusB);

        //Check which status has the highest index and return the highest one
        if(indexContractStatusA >= indexContractStatusB){
            //System.debug call for debug log purpose
            System.debug(LoggingLevel.DEBUG, '## AP12_Contract getHighestStatus - Select Status : ' + contractStatusA);
            System.debug(LoggingLevel.INFO, '## AP12_Contract ## getHighestStatus end');
            return contractStatusA;
        }
        else{
            //System.debug call for debug log purpose
            System.debug(LoggingLevel.DEBUG, '## AP12_Contract getHighestStatus - Select Status : ' + contractStatusB);
            System.debug(LoggingLevel.INFO, '## AP12_Contract ## getHighestStatus end');
            return contractStatusB;
        }
    }


    /**
    * ----------------------------------------------------------------------------------------------
    * Method to prefill contract AXA GO Legal Entity field with user connected company
    * ----------------------------------------------------------------------------------------------
    * @param    lstContrats List<Contract__c>   : list of contracts from Trigger.new
    * ----------------------------------------------------------------------------------------------
    */
    public static void updateContractLegalEntity(List<Contract__c> lstContrats) {
        User currUser = [SELECT Name, Company__c FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
        for(Contract__c contract : lstContrats) {
            if((contract.RecordTypeId == ContractTriggerHandler.idRecOpCoSingleEdit) || (contract.RecordTypeId == ContractTriggerHandler.idRecOpCoSingleReadOnly)) {
                //SGO - 2019/08/30 - Single lightning Ctr, prefill if user company != france and legal entity not filled by user
                if(currUser.Company__c != null && currUser.Company__c != AP_Constant.GS_ENTITY_AXA_GR_OP_FR && (String.isBlank(contract.AXA_GO_Legal_Entity__c) || contract.AXA_GO_Legal_Entity__c == '')) {
                    contract.AXA_GO_Legal_Entity__c = currUser.Company__c;
                }
            }
        }
    }
    
    /**
    * ----------------------------------------------------------------------------------------------
    * Update status description on IL
    * ----------------------------------------------------------------------------------------------
    * @param    setCtrId Set<Id>    : set of contract id from Trigger.newMap
    * ----------------------------------------------------------------------------------------------
    */
    public static void updatePlannedInvoicingLines(Set<Id> setCtrId) {
        //07-JUN-2022  ARA  SP-02668 (Ensure IL currency same as contract)
        //17/08/2020-ARA : update status description on planned invoicing line
        Set<String> setStatus = new Set<String>{'01', '02'};
        List<Planned_Invoicing_Line__c> lstPIL = new List<Planned_Invoicing_Line__c>();

        for(Planned_Invoicing_Line__c pil : [SELECT id, Name, Master_WBS_Structure__c, Tech_UpdatedByPS__c, Contract2__c, Contract2__r.CurrencyIsoCode, Purchase_Order__c, N_Purchase_Order__c, Contract_Status__c, Status_Description__c
        FROM Planned_Invoicing_Line__c 
        WHERE Contract2__c IN :setCtrId
        AND Status__c IN :setStatus 
        AND Type__c = 'Invoicing Line']){
            pil.CurrencyIsoCode = pil.Contract2__r.CurrencyIsoCode;
            lstPIL.add(pil);
        }

        if(lstPIL.size() > 0){
            try{
                update lstPIL;
            }catch(DmlException e){
                system.debug('## AP12_Contract:'+ e.getMessage());
            }
        }
    }
    
    /**
    * ----------------------------------------------------------------------------------------------
    * Send a PO Reminder when the contrat is signed
    * ----------------------------------------------------------------------------------------------
    * @param    setCtrId Set<Id>    : set of contract id from Trigger.newMap
    * ----------------------------------------------------------------------------------------------
    */
    public static void sendPOReminder(Set<Id> setCtrId) {
        OrgWideEmailAddress[] owea = [select Id from OrgWideEmailAddress where Address =:System.label.AP30_adminOpCo360_Email];
        List<Contract__c> lstCtr = [SELECT Id, OpCo_Send_Automatic_PO_Reminder__c, OpCo_CountILNoPO__c, TECH_ContactEmail__c, Local_Information__c, Customer_Operational_Contact__c, Local_Information__r.OpCo_POReminderContact__c, C_Account__c, C_Account__r.Account_Manager__c, C_Account__r.Account_Manager__r.Email, Owner.Email FROM Contract__c WHERE Id IN : setCtrId];
        List<String> lstToAdress = new List<String>();
        List<String> lstCCEmail;
        for(Contract__c ctr: lstCtr){
            if(ctr.OpCo_Send_Automatic_PO_Reminder__c && ctr.OpCo_CountILNoPO__c > 0){
                lstCCEmail = new List<String>();
                if(ctr.Local_Information__c != null && ctr.Local_Information__r.OpCo_POReminderContact__c != null){
                    lstToAdress = ctr.Local_Information__r.OpCo_POReminderContact__c.trim().split(';');
                }else if(ctr.TECH_ContactEmail__c != null){
                    lstToAdress.add(ctr.TECH_ContactEmail__c);
                }
                
                if(ctr.Owner != null && ctr.Owner.Email != null){
                    lstCCEmail.add(ctr.Owner.Email);
                }
                if(ctr.C_Account__c != null && ctr.C_Account__r.Account_Manager__c != null && ctr.C_Account__r.Account_Manager__r.Email != null){
                    lstCCEmail.add(ctr.C_Account__r.Account_Manager__r.Email);
                }
                if(lstToAdress.size() > 0){
                    Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
                    email.setToAddresses(lstToAdress);
                    email.setTargetObjectId(ctr.Customer_Operational_Contact__c);
                    email.setTreatTargetObjectAsRecipient(false);
                    email.setWhatId(ctr.Id);
                    email.setTemplateID(System.label.EmailTemplateId_SignedPOReminder);
                    email.setSaveAsActivity(false);
                    email.setUseSignature(false);
                    email.setBccSender(false);
                    if(lstCCEmail.size() > 0){
                        email.setCcAddresses(lstCCEmail);
                    }
                    if (owea.size() > 0) {
                        email.setOrgWideEmailAddressId(owea.get(0).Id);
                    }
                    
                    if(!test.isRunningTest()){
                        Messaging.sendEmail(new Messaging.SingleEmailMessage[]{email});
                    }
                }
            }
        }
    }
}