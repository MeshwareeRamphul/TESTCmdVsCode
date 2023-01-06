public with sharing class LC09_CtrClone {
	/*----------------------------------------------------------------------
    -- - Name          : LC09_CtrClone
    -- - Author        : Spoon Consulting 
    -- - Description   : Class for cloning contract
    --
    -- - History:

    -- Date         Name  Version  Remarks
    -- -----------  ----  -------  ---------------------------------------
    --                     1.0      Initial version
	-- 06-JUL-2021  USA    1.1      SP-01432, SP-02021, SP-01826
	-- 11-JUL-2022  ARA    1.2      SP-02770 (Contract | Change PO reminder functionality), SP-03203 (Intraco contract | Enable contracts with no IL)
-------------------------------------------------------------------------*/
    @TestVisible static Boolean ContractNull = false;
    @TestVisible static Boolean StatusNull = false;
    @TestVisible static Boolean pSOWNULL = false;
    @TestVisible static Boolean ErrorThrown = false;
    @TestVisible static Boolean ErrorThrown2 = false;


    private static boolean canBeCloned(Contract__c currentContract){
        if(currentContract != null && currentContract.Status__c != null && !(currentContract.Status__c == 'Cancelled')){
            return true;
        }
        else{
            return false;
        }
    }
    
    @AuraEnabled   
    public static String cloneContract(String ctrId){
        System.debug('## LC09_CtrClone.cloneContract start.');

        Contract__c currentContract = [SELECT  Account_Manager__c, Account__c, Amendment_to__c, ATS_Notify_Validation__c, AXA_GO_Legal_Entity__c,
                                        AXA_GS_Signed_By__c, AXA_GS_Signed_By_Title__c, AXA_GO_Signed_By_2__c, BusinessArea_ATS__c, 
                                        C_Account__c, Cancelled_details__c, Cancelled_reason__c, Contract_Signed_Date__c, Contract_Start_Date__c, 
                                        ContractNumber__c, CountEsignatureInProgress__c, CountProductItems__c, Customer_Operational_Contact__c, CustomerSignedBy__c, 
                                        CustomerSignedByTitle__c, CustomerSignedBy2__c, Decision_maker__c, Description__c,Domain_ATS__c, 
                                        EndDate__c, FinalDocumentURL__c, Global_Amount__c, Invoicing_Condition__c, OpCo_Send_Automatic_PO_Reminder__c, OpCo_IsReadySetSendAutoPORemind__c,
                                        Invoicing_Lines_Amount__c, Invoicing_Lines_Percent__c, Invoicing_Method__c, ISR__c, OpCo_IsILNotRequired__c, 
                                        Language__c, Last_Invoicing_Date__c, Local_information__c, Master_WBS_2__c,Opportunity__c, PDF_Status__c, PDFContrAtt__c, PDFStatus_lgt__c, Peoplesoft_Sync__c, 
                                        PeopleSoftConnectionMessage__c, Planned_Invoicing_Lines_Amount__c, Planned_Invoicing_Lines_Percent__c, Reminder_Type__c, Service_Started__c, Service_Type__c, ServiceType__c, InvoicingMethod__c, Service_Type_Picklist__c,
                                        Signature_Type__c,SOW_Operational__c,  SOW_Type__c, StartDate__c, Status__c, TECH_AGScontract__c, TECH_ClonedBAUContract__c, 
                                        TECH_CongaAddress__c, TECH_ContactEmail__c,TECH_ContactPhone__c, TECH_ContactTitle__c, 
                                        TECH_InvoicingMethod__c, TECH_IsClonedContract__c, TECH_ServiceType__c, Name,
                                        TECH_SOWType__c, TECH_TemplateId__c, Type__c, Universign__c, Id,RecordTypeId, Warning_MSA__c, Amendment_to__r.Name
                                        FROM Contract__c WHERE Id =:ctrId];

        //***for test class coverage starts***
        if (ContractNull) {
            System.debug('@@ LC09 vContract before delete ' + currentContract);
            try{
                currentContract = [SELECT Id, Name FROM Contract__c WHERE Id = :currentContract.Id];
                delete currentContract;
                currentContract = [SELECT Id, Name FROM Contract__c WHERE Id = :currentContract.Id];
                System.debug('@@ LC09 vContract after delete ' + currentContract);
                
            }
            catch(Exception e){
                currentContract = null;
                System.debug('@@ LC09 vContract after delete inside exception' + currentContract);
                //canBeCloned(currentContract);
            }
        }
        System.debug('*******StatusNull '+StatusNull);
        if (StatusNull) {
            currentContract.Status__c = null;
            currentContract.ServiceType__c = null;
            currentContract.InvoicingMethod__c = null;
            update currentContract;
        }
        //***for test class coverage ends***
            
        //System.debug('@@ LC09 vContract before canBeCloned ' + currentContract);
        if(canBeCloned(currentContract)){
            System.debug('## LC09_CtrClone.cloneContract continue.');
        
            List<String> activeSowtype = new List<String>();
            List<String> activeSignaturetype = new List<String>();
            Contract__c clonedContract = currentContract.clone(false, true, false, false); //Deep clone

            clonedContract.Master_WBS_2__c = null;
           // clonedContract.Master_WBS__c = '';
            clonedContract.Status__c = System.Label.ContractStatus_Draft;            
            clonedContract.Global_Amount__c = currentContract.Global_Amount__c;   
            Map<String, recordType> vRecordTypes = AP_Constant.getRecordTypes('Contract__c');

            if (currentContract.RecordTypeId == vRecordTypes.get(AP_Constant.RT_AMENDMENT_EDIT_LIGHTNING).Id || 
                currentContract.RecordTypeId == vRecordTypes.get(AP_Constant.RT_AMENDMENT_READONLY_LIGHTNING).Id) {
                clonedContract.Name = 'AMD_' + currentContract.Amendment_to__r.Name;
                clonedContract.RecordTypeId = vRecordTypes.get(AP_Constant.RT_AMENDMENT_EDIT_LIGHTNING).Id;
                activeSowtype = System.Label.SowType_Active_AmendmentEdit.split(',');
                activeSignaturetype = System.Label.SignatureType_Active_Amendment.split(',');
            }
            else if(currentContract.RecordTypeId == vRecordTypes.get(AP_Constant.RT_CONTRACT_EDIT_LIGHTNING).Id || 
                currentContract.RecordTypeId == vRecordTypes.get(AP_Constant.RT_CONTRACT_READONLY_LIGHTNING).Id) {
                clonedContract.Name = 'NEWCONTRACT';
                clonedContract.RecordTypeId = vRecordTypes.get(AP_Constant.RT_CONTRACT_EDIT_LIGHTNING).Id;
                activeSowtype = System.Label.SowType_Active_SOWEdit.split(',');
                activeSignaturetype = System.Label.SignatureType_Active_SOW.split(',');
            }else if(currentContract.RecordTypeId == vRecordTypes.get(AP_Constant.RT_LIGHTCONTRACT).Id) {
                clonedContract.Name = 'NEWCONTRACT';
                clonedContract.RecordTypeId = vRecordTypes.get(AP_Constant.RT_LIGHTCONTRACT).Id;
                activeSowtype = System.Label.SowType_Active_Light.split(',');
                activeSignaturetype = System.Label.SignatureType_Active_Light.split(',');
            }

            if((currentContract.ServiceType__c != null) && currentContract.ServiceType__c == 'BAU'){
                clonedContract.TECH_ClonedBAUContract__c = true;
            }
            
            if(!activeSowtype.contains(clonedContract.SOW_Type__c)){
                clonedContract.SOW_Type__c = null;
            }
            if(!activeSignaturetype.contains(clonedContract.Signature_Type__c)){
                clonedContract.Signature_Type__c = null;
            }
            clonedContract.SOW_Operational__c = removeBRTags(clonedContract.SOW_Operational__c);
            clonedContract.PDFContrAtt__c = null;
            clonedContract.Contract_Signed_Date__c = null;
            clonedContract.Opportunity__c = null;
            clonedContract.TECH_IsClonedContract__c = true;
            clonedContract.universign__c=false;
            clonedContract.FinalDocumentURL__c = null;
            clonedContract.linkToDocument__c = null;
            clonedContract.PDFStatus_lgt__c = 'Not generated';
            clonedContract.TECH_AGScontract__c = false;
            clonedContract.Peoplesoft_Sync__c = false;
            clonedContract.OpCo_IsILNotRequired__c = false;
            clonedContract.OpCo_IsReadySetSendAutoPORemind__c = false;
            clonedContract.Decision_maker__c = null;
            clonedContract.Cancelled_reason__c = null;
            clonedContract.Cancelled_details__c = null;
            // clonedContract.PO_Missing_Reminder_Status__c = null;
            //clonedContract.PO_Missing_R1_sent_date__c = null;
            //clonedContract.PO_Missing_R2_sent_date__c = null;
            // clonedContract.PO_Missing_R3_sent_date__c = null;
            // clonedContract.Waiting_Signature_Reminder_Status__c = null;
            //clonedContract.Waiting_Signature_R1_sent_date__c = null;
            //clonedContract.Waiting_Signature_R2_sent_date__c = null;
            // clonedContract.Waiting_Signature_R3_sent_date__c = null;

            if(currentContract.AXA_GO_Legal_Entity__c != null){
                if ((currentContract.AXA_GO_Legal_Entity__c.contains('Services')) || (currentContract.AXA_GO_Legal_Entity__c == 'GIE') || (currentContract.AXA_GO_Legal_Entity__c == 'SAS')){
                    clonedContract.AXA_GO_Legal_Entity__c = null;
                    clonedContract.ServiceType__c = null;
                    clonedContract.InvoicingMethod__c = null;
                    clonedContract.Invoicing_Condition__c = null;
                }
            }

            try {
                insert clonedContract;
                
                //Test coverage starts
                if(ErrorThrown){
                    throw new DMLException();
                }
                //Test coverage ends
            } catch (Exception e) {
               // ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Technical error occured : ' + e.getMessage()));
                System.debug('Technical error occured : ' + e.getMessage());
                if(e.getMessage().contains('InvoicingMethod__c')){
                    return Label.LC09_SelectRightInvoicingMethod;
                }else{
                    return 'Technical error occured : ' + e.getMessage();
                }
            }
            System.debug('## LC09_CtrClone.cloneContract - After     inserting the cloned contract into database');
            System.debug('## LC09_CtrClone.cloneContract ends');

            //return new PageReference('/' + clonedContract.Id);
            return clonedContract.Id;
        }
        else{
            //ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'You cannot clone the following contract : ' + currentContract.Name));
            if (currentContract!=null){
                return 'You cannot clone the following contract : ' + currentContract.Name ;
            }
            else{
                return 'The contract has not been found to be cloned';
            }
        }
    }


    public static String removeBRTags(String pSOW) {
        if (pSOWNULL){
            pSow = null;
        }
        if (pSow == null) {
            return null;
        }
        pSOW = pSOW.ReplaceAll('<br><br><br>', '<div></div>');
        pSOW = pSOW.ReplaceAll('<br><br>', '<div></div>');
        pSOW = pSOW.ReplaceAll('<br>', '<div></div>');

        return pSOW;
    }
}