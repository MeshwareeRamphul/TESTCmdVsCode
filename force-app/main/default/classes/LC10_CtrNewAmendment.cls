public with sharing class LC10_CtrNewAmendment {
    /*
    --------------------------------------------------------------------------------------
    -- - Name          : LC10_CtrNewAmendment
    -- - Author        : Spoon Consulting
    -- - Description   : Create amendment from contract (Lightning version)
    -- Maintenance History:
    --
    -- Date         Name  Version  Remarks
    -- -----------  ----  -------  -------------------------------------------------------
    --                    1.0     Initial version
    -- 18/11/2019   USA   1.1     SP-00119
    -- 17/02/2020   USA   1.2     SP-00154
    -- 08/05/2020   USA   1.3     SP-00197 (empty field Tech_Reminder)
    -- 30/07/2020   ARA   1.4     SP-00378
	-- 11/07/2022   ARA   1.5      SP-02770 (Contract | Change PO reminder functionality), SP-03203 (Intraco contract | Enable contracts with no IL)

    *************************************************************************************/
    @AuraEnabled       
    public static String createAmendmentFromContract(String ctrId) {
        System.debug('## LC10_CtrNewAmendment.createAmendmentFromContract starts');
        // Contract__c currentContract = (Contract__c) standardController.getRecord();
        // Contract__c amendment = createAmendmentFromContract(currentContract);

        Contract__c pContract = [SELECT Account_Manager__c, Account__c, Amendment_to__c, ATS_Notify_Validation__c, AXA_GO_Legal_Entity__c,
                                        AXA_GS_Signed_By__c, AXA_GS_Signed_By_Title__c, AXA_GO_Signed_By_2__c, BusinessArea_ATS__c, 
                                        C_Account__c, Cancelled_details__c, Cancelled_reason__c, Contract_Signed_Date__c, Contract_Start_Date__c, 
                                        ContractNumber__c, CountEsignatureInProgress__c, CountProductItems__c, Customer_Operational_Contact__c, CustomerSignedBy__c, 
                                        CustomerSignedByTitle__c, CustomerSignedBy2__c, Decision_maker__c, Description__c, Domain_ATS__c, EndDate__c, FinalDocumentURL__c, Global_Amount__c, Invoicing_Condition__c,
                                        Invoicing_Lines_Amount__c, Invoicing_Lines_Percent__c, Invoicing_Method__c, ISR__c, OpCo_IsILNotRequired__c, OpCo_Send_Automatic_PO_Reminder__c, OpCo_IsReadySetSendAutoPORemind__c,
                                        Language__c, Last_Invoicing_Date__c, Local_information__c, Master_WBS_2__c, Opportunity__c, PDF_Status__c, PDFContrAtt__c, PDFStatus_lgt__c, Peoplesoft_Sync__c, 
                                        PeopleSoftConnectionMessage__c, Planned_Invoicing_Lines_Amount__c, Planned_Invoicing_Lines_Percent__c, Reminder_Type__c, Service_Started__c, Service_Type__c, ServiceType__c, InvoicingMethod__c, Service_Type_Picklist__c,
                                        Signature_Type__c, SOW_Operational__c, SOW_Type__c, StartDate__c, Status__c, TECH_CongaAddress__c, TECH_ContactEmail__c,TECH_ContactPhone__c, TECH_ContactTitle__c, 
                                        TECH_InvoicingMethod__c, TECH_IsClonedContract__c, TECH_ServiceType__c, Name,
                                        TECH_SOWType__c, TECH_TemplateId__c, Type__c, Universign__c, Id,RecordTypeId, Warning_MSA__c, (SELECT Id, Name from Amendments__r)
                                        FROM Contract__c WHERE Id =:ctrId];
        
        if(pContract.Status__c == System.Label.ContractStatus_Cancelled || pContract.Status__c == System.Label.ContractStatus_Resiliated){
            return System.Label.NewAmendmentError;
        }else{
             // Custom amendment creation logic
            List<String> activeSowtype = System.Label.SowType_Active_AmendmentEdit.split(',');
            List<String> activeSignaturetype = System.Label.SignatureType_Active_Amendment.split(',');
            Contract__c amendment = pContract.clone(false, true, false, false); //Deep clone
                             
            amendment.Global_Amount__c = 0;         
            amendment.Name = 'AMD' + string.valueof(pContract.amendments__r.Size() + 1) + '_' + pContract.Name; 
            amendment.RecordTypeId = Schema.SObjectType.Contract__c.getRecordTypeInfosByName().get(AP_Constant.RT_AMENDMENT_EDIT_LIGHTNING_LABEL).getRecordTypeId();             
            amendment.Status__c = System.Label.ContractStatus_Draft;
            amendment.SOW_Operational__c = null;
            amendment.Amendment_to__c = pContract.Id; 
            amendment.Master_WBS_2__c = null;
            amendment.TECH_IsClonedContract__c = true; 
            amendment.Peoplesoft_Sync__c = false;
            amendment.Universign__c = false;
            amendment.OpCo_IsILNotRequired__c = false;
            amendment.OpCo_IsReadySetSendAutoPORemind__c = false;
            amendment.PDFStatus_lgt__c = 'Not generated';
            amendment.SOW_Type__c = activeSowtype.contains(amendment.SOW_Type__c) ? amendment.SOW_Type__c : null;
            amendment.Signature_Type__c = activeSignaturetype.contains(amendment.Signature_Type__c) ? amendment.Signature_Type__c : null;
    
            /*if(pContract.RecordTypeId == vRecordTypes.get(AP_Constant.RT_CONTRACT_EDIT_LIGHTNING).Id || pContract.RecordTypeId == vRecordTypes.get(AP_Constant.RT_CONTRACT_READONLY_LIGHTNING).Id){
              Map<String, recordType> vRecordTypes = AP_Constant.getRecordTypes('Contract__c');
              amendment.ServiceType__c = null;
                amendment.InvoicingMethod__c = null;
                amendment.Invoicing_Condition__c = null;
            }*/
    
            //SP-00119
            if (pContract.AXA_GO_Legal_Entity__c != null){
                List<MappingOldNewLE__mdt> lstMapOldNewLE = [SELECT CurrentLegalEntity__c, OldLegalEntity__c
                                                            FROM MappingOldNewLE__mdt
                                                            WHERE OldLegalEntity__c = :pContract.AXA_GO_Legal_Entity__c];
                if (lstMapOldNewLE.size() > 0){ amendment.AXA_GO_Legal_Entity__c = lstMapOldNewLE[0].CurrentLegalEntity__c; }
            }
    
            try{
                insert amendment;                
            }catch(Exception e){
                if(e.getMessage().contains('InvoicingMethod__c') && e.getMessage().contains('INVALID_OR_NULL_FOR_RESTRICTED_PICKLIST')){
                    try{
                        amendment.InvoicingMethod__c = null;
                        insert amendment;                
                    }catch(Exception ex){return 'Error occured : ' + ex.getMessage();}
                }else{return 'Error occured : ' + e.getMessage();}
            }

            if(amendment.Id != null){
                //SP-00154
                list<ProductItem__c> lstClonedPItems=new list<ProductItem__c>();
                ProductItem__c clonedpItem;
                for(ProductItem__c pItemsToClone:[  SELECT Contract__c,Product__c
                                                    FROM ProductItem__c
                                                    WHERE Contract__c=:pContract.id]){
                    clonedpItem=new ProductItem__c(Contract__c=amendment.id, Product__c=pItemsToClone.Product__c);
                    lstClonedPItems.add(clonedpItem);
                }
    
                if(lstClonedPItems.size()>0){
                    try{
                        insert lstClonedPItems;
                    } catch (Exception e){return 'Technical error occured : ' + e.getMessage();}
                }
            }
            
            System.debug('## LC10_CtrNewAmendment.createAmendmentFromContract am.ID: ' + amendment.Id);
            System.debug('## LC10_CtrNewAmendment.createAmendmentFromContract ends');
    
            return amendment.Id;
        }
    }
}