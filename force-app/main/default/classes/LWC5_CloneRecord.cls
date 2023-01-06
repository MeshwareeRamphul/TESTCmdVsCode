public class LWC5_CloneRecord {
    /* 
    --------------------------------------------------------------------------------------
    -- - Name          : LWC5_CloneRecord
    -- - Author        : ARA
    -- - Description   : This class implements logic to clone opco contract and cTin legal clause ( common class)
    --
    -- Maintenance History: 
    --
    -- Date         Name  Version  Remarks 
    -- -----------  ----  -------  -------------------------------------------------------
    -- 18-NOV-2022  ARA    1.0     Initial version (SP-04029: import clause information from parent)
    -- 22-NOV-2022  AMA    1.1     SP-03987 (clone clause information)
    --------------------------------------------------------------------------------------*/
    @AuraEnabled   
    public static Map<String, Object> fetchRecord(String recordId){
        Map<String, Object> mapResult = new Map<String, Object>();
        //applicable for oppco
        if(recordId.startsWith('a0D')){
            List<Contract__c> lstCtr = [SELECT  Account_Manager__c, Account__c, Amendment_to__c, ATS_Notify_Validation__c, AXA_GO_Legal_Entity__c,
            AXA_GS_Signed_By__c, AXA_GS_Signed_By_Title__c, AXA_GO_Signed_By_2__c, BusinessArea_ATS__c, 
            C_Account__c, Cancelled_details__c, Cancelled_reason__c, Contract_Signed_Date__c, Contract_Start_Date__c, 
            ContractNumber__c, CountEsignatureInProgress__c, CountProductItems__c, Customer_Operational_Contact__c, CustomerSignedBy__c, 
            CustomerSignedByTitle__c, CustomerSignedBy2__c, Decision_maker__c, Description__c,Domain_ATS__c, 
            EndDate__c, FinalDocumentURL__c, Global_Amount__c, Invoicing_Condition__c, OpCo_Send_Automatic_PO_Reminder__c, OpCo_IsReadySetSendAutoPORemind__c,
            Invoicing_Lines_Amount__c, Invoicing_Lines_Percent__c, Invoicing_Method__c, ISR__c, OpCo_IsILNotRequired__c, 
            Language__c, Last_Invoicing_Date__c, Local_information__c, Master_WBS_2__c,Opportunity__c, PDF_Status__c, PDFContrAtt__c, PDFStatus_lgt__c, Peoplesoft_Sync__c, 
            PeopleSoftConnectionMessage__c, Planned_Invoicing_Lines_Amount__c, Planned_Invoicing_Lines_Percent__c, Reminder_Type__c, Service_Started__c, Service_Type__c, ServiceType__c, InvoicingMethod__c, Service_Type_Picklist__c,
            Signature_Type__c,SOW_Operational__c,  SOW_Type__c, StartDate__c, Status__c, TECH_AGScontract__c, TECH_ClonedBAUContract__c, 
            TECH_CongaAddress__c, TECH_ContactEmail__c,TECH_ContactPhone__c, TECH_ContactTitle__c, TECH_InvoicingMethod__c, TECH_IsClonedContract__c, TECH_ServiceType__c, Name,
            TECH_SOWType__c, TECH_TemplateId__c, Type__c, Universign__c, Id,RecordTypeId, Warning_MSA__c, Amendment_to__r.Name,Tech_RecordTypeName__c
            FROM Contract__c WHERE Id = :recordId];

            if(lstCtr.size()>0){
                Contract__c currentCtr = lstCtr[0];
                if(currentCtr.Status__c != Label.ContractStatus_Cancelled){
                    Map<String, recordType> mapContractRT = AP_Constant.getRecordTypes('Contract__c');
                    List<String> activeSowtype = new List<String>();
                    List<String> activeSignaturetype = new List<String>();

                    Contract__c ctr = currentCtr.clone(false, true, false, false); //Deep clone

                    ctr.Master_WBS_2__c = null;
                    ctr.Status__c = System.Label.ContractStatus_Draft;            
                    ctr.Global_Amount__c = currentCtr.Global_Amount__c;   

                    /*if (currentCtr.RecordTypeId == mapContractRT.get(AP_Constant.RT_AMENDMENT_EDIT_LIGHTNING).Id || 
                        currentCtr.RecordTypeId == mapContractRT.get(AP_Constant.RT_AMENDMENT_READONLY_LIGHTNING).Id) {
                        ctr.Name = 'AMD_' + currentCtr.Amendment_to__r.Name;
                        ctr.RecordTypeId = mapContractRT.get(AP_Constant.RT_AMENDMENT_EDIT_LIGHTNING).Id;
                        activeSowtype = System.Label.SowType_Active_AmendmentEdit.split(',');
                        activeSignaturetype = System.Label.SignatureType_Active_Amendment.split(',');
                    }
                    else */
                    if(currentCtr.RecordTypeId == mapContractRT.get(AP_Constant.RT_CONTRACT_EDIT_LIGHTNING).Id || 
                        currentCtr.RecordTypeId == mapContractRT.get(AP_Constant.RT_CONTRACT_READONLY_LIGHTNING).Id) {
                        ctr.Name = 'NEWCONTRACT';
                        ctr.RecordTypeId = mapContractRT.get(AP_Constant.RT_CONTRACT_EDIT_LIGHTNING).Id;
                        activeSowtype = System.Label.SowType_Active_SOWEdit.split(',');
                        activeSignaturetype = System.Label.SignatureType_Active_SOW.split(',');
                    }else if(currentCtr.RecordTypeId == mapContractRT.get(AP_Constant.RT_LIGHTCONTRACT).Id) {
                        ctr.Name = 'NEWCONTRACT';
                        ctr.RecordTypeId = mapContractRT.get(AP_Constant.RT_LIGHTCONTRACT).Id;
                        activeSowtype = System.Label.SowType_Active_Light.split(',');
                        activeSignaturetype = System.Label.SignatureType_Active_Light.split(',');
                    }

                    if((currentCtr.ServiceType__c != null) && currentCtr.ServiceType__c == 'BAU'){
                        ctr.TECH_ClonedBAUContract__c = true;
                    }
                    
                    if(!activeSowtype.contains(ctr.SOW_Type__c)){
                        ctr.SOW_Type__c = null;
                    }
                    if(!activeSignaturetype.contains(ctr.Signature_Type__c)){
                        ctr.Signature_Type__c = null;
                    }
                    ctr.SOW_Operational__c = removeBRTags(ctr.SOW_Operational__c);
                    ctr.PDFContrAtt__c = null;
                    ctr.Contract_Signed_Date__c = null;
                    ctr.Opportunity__c = null;
                    ctr.TECH_IsClonedContract__c = true;
                    ctr.universign__c=false;
                    ctr.FinalDocumentURL__c = null;
                    ctr.linkToDocument__c = null;
                    ctr.PDFStatus_lgt__c = 'Not generated';
                    ctr.TECH_AGScontract__c = false;
                    ctr.Peoplesoft_Sync__c = false;
                    ctr.OpCo_IsILNotRequired__c = false;
                    ctr.OpCo_IsReadySetSendAutoPORemind__c = false;
                    ctr.Decision_maker__c = null;
                    ctr.Cancelled_reason__c = null;
                    ctr.Cancelled_details__c = null;

                    if(currentCtr.AXA_GO_Legal_Entity__c != null){
                        if ((currentCtr.AXA_GO_Legal_Entity__c.contains('Services')) || (currentCtr.AXA_GO_Legal_Entity__c == 'GIE') || (currentCtr.AXA_GO_Legal_Entity__c == 'SAS')){
                            ctr.AXA_GO_Legal_Entity__c = null;
                            ctr.ServiceType__c = null;
                            ctr.InvoicingMethod__c = null;
                            ctr.Invoicing_Condition__c = null;
                        }
                    }
                    System.debug('****clone '+ ctr.RecordTypeId);
                    mapResult.put('record', ctr);
                    mapResult.put('objectAPI', 'Contract__c');
                }else{
                    mapResult.put('error', 'A cancelled contract cannot be cloned.');
                }
            }else{
                mapResult.put('error', 'This contract does not exist and cannot be cloned.');
            }
        }else if(recordId.startsWith('006')){
            Map<String, recordType> mapOppRT = AP_Constant.getRecordTypes('Opportunity');
            Set<String> setAXAGsEntity = AP_Constant.getPickListValuesIntoListOpp();

            List<Opportunity> lstOpp = [SELECT AccountId, AXA_GO_Entity__c, Name, Amount, Probability, StageName, Assigned_to__c, CloseDate, OwnerId, CurrencyIsoCode, Opportunity_Context__c,
                Business_Value__c, Category__c, Answer_due_date__c, Funding__c, Entity_contact__c, Answer_sent_date__c, Entity_sponsor__c,Answer_cinematic__c,
                PM_works_on_the_answer__c, Project_start_Date__c, End_users_type__c, Go_live_date__c, Pre_Sales_Effort_M_d__c, Close_decision_maker__c, Lost_comment__c,
                Closed_lost_reason__c, Lost_in_Stage__c,RecordTypeId,TECH_HaveContract__c,TECH_Assignment_done__c,TECH_ContractStatus__c
                FROM Opportunity WHERE Id =:recordId
                LIMIT 1];

            if(lstOpp.size()>0){
                Opportunity currentOpp = lstOpp[0];
                if (canBeCloned(currentOpp)){
                    Opportunity opp = currentOpp.clone(false, true, false, false); //Deep clone

                    //Full
                    if (currentOpp.RecordTypeId == mapOppRT.get(AP_Constant.RT_OPP_LIGHTNING_FULL).Id ||
                            currentOpp.RecordTypeId == mapOppRT.get(AP_Constant.RT_OPP_LIGHTNING_FULL_RO).Id) {
                        opp.RecordTypeId = mapOppRT.get(AP_Constant.RT_OPP_LIGHTNING_FULL).Id;
                    }
                    //Single
                    if (currentOpp.RecordTypeId == mapOppRT.get(AP_Constant.RT_OPP_LIGHTNING_SINGLE).Id ||
                            currentOpp.RecordTypeId == mapOppRT.get(AP_Constant.RT_OPP_LIGHTNING_SINGLE_RO).Id) {
                        opp.RecordTypeId = mapOppRT.get(AP_Constant.RT_OPP_LIGHTNING_SINGLE).Id;
                    }

                    if (setAXAGsEntity.contains(currentOpp.AXA_GO_Entity__c)){
                        if (currentOpp.AXA_GO_Entity__c == 'AXA GS France' || currentOpp.AXA_GO_Entity__c == 'AXA Services France' ){
                            opp.AXA_GO_Entity__c = 'AXA Group Operations France';
                        }else if (currentOpp.AXA_GO_Entity__c == 'AXA GS Asia' || currentOpp.AXA_GO_Entity__c == 'AXA Services Asia' ){
                            opp.AXA_GO_Entity__c = 'AXA Group Operations Hong Kong Limited';
                        }else if (currentOpp.AXA_GO_Entity__c == 'AXA GS UK' || currentOpp.AXA_GO_Entity__c == 'AXA Services UK' ){
                            opp.AXA_GO_Entity__c = 'AXA Group Operations UK';
                        }else if (currentOpp.AXA_GO_Entity__c == 'AXA GS Spain' || currentOpp.AXA_GO_Entity__c == 'AXA Services Spain' ){
                            opp.AXA_GO_Entity__c = 'AXA Group Operations Spain';
                        }else if (currentOpp.AXA_GO_Entity__c == 'AXA GS Portugal' || currentOpp.AXA_GO_Entity__c == 'AXA Services Portugal' ){
                            opp.AXA_GO_Entity__c = 'AXA Group Operations Portugal';
                        }else if (currentOpp.AXA_GO_Entity__c == 'AXA GS Switzerland' || currentOpp.AXA_GO_Entity__c == 'AXA Services Switzerland' ){
                            opp.AXA_GO_Entity__c = 'AXA Group Operations Switzerland';
                        }else{
                            System.debug('##lc06 currentOpp.AXA_GO_Entity__c: ' + currentOpp.AXA_GO_Entity__c);
                            opp.AXA_GO_Entity__c = currentOpp.AXA_GO_Entity__c;
                        }
                    }
                    else{
                        System.debug('##lc06 currentOpp.AXA_GO_Entity__c: ' + currentOpp.AXA_GO_Entity__c + ' does not exist.');
                        currentOpp.AXA_GO_Entity__c = null;
                    }

                    opp.stageName = AP_Constant.STAGE_LEADS_GATHERING;
                    opp.Name = 'NEW_OPPORTUNITY';
                    opp.TECH_HaveContract__c = false;
                    opp.TECH_Assignment_done__c = false;
                    opp.TECH_ContractStatus__c = '';
                    opp.Probability = 25.0;
                    opp.OwnerId = UserInfo.getUserId();

                    mapResult.put('record', opp);
                    mapResult.put('objectAPI', 'Opportunity');
                }else{
                    mapResult.put('error', 'This opportunity cannot be cloned.');
                }
            }else{
                mapResult.put('error', 'This opportunity does not exist and cannot be cloned.');
            }
        }
        //applicable for ctin
        else if(recordId.startsWith('a03')){
            Map<String, recordType> mapLegInfRT = AP_Constant.getRecordTypes('Legal_Information__c');

            List<Legal_Information__c> lstLegInf = [SELECT Legal_Status__c,Name,AXA_Company_definition__c,Based_on_Axa_template_YES_NO__c,Critical_outsourcing__c,Score_Compliance_critical_Outsourci__c,
                Compliance_critical_Outsourcing__c,Standard_clause_Intellectual_Property__c,Score_Intellectual_Property__c,Intellectual_Property__c,Score_Sub_licensing__c,
                Sub_licensing__c,Standard_clause_Confidentiality__c,Score_Confidentiality__c,Confidentiality__c,Standard_clause_SLA_Penalty__c,Score_sla_penalty__c,SLA_Penalty__c,
                Standard_clause_Liability__c,Score_Liability__c,Liability__c,Standard_clause_Divestiture__c,Score_Divestiture__c,Divestiture__c,Standard_clause_Audit__c,Score_Audit__c,
                Audit_of_the_Customer__c,Standard_clause_Termination__c,Score_Termination__c,Termination__c,Standard_clause_Reversibility__c,Score_Reversibility__c,Reversibility__c,
                Standard_clause_Assignment__c,Score_Assignment__c,Assignment_Clause__c,Standard_clause_Sub_contracting__c,Score_Sub_contracting__c,Sub_contracting__c,Score_Governing_Law__c,
                Governing_Law__c,clause_sustainability__c,Score_Sustainability__c,Sustainability__c,Comments_on_documents__c,InfoSec_Status__c,Standard_clause_Background_Check__c,Score_Background_Check__c,
                Background_Check__c,Standard_clause_Info_Sec__c,Score_Info_Sec__c,Info_Sec__c,Operational_Resilience_Status__c,Standard_clause_Operational_Resilience__c,Score_Operational_Resilience__c,
                Operational_resilience__c,Compliance_Status__c,Standard_clause_Anti_Bribery__c,Score_Anti_Bribery__c,Anti_Bribery__c,Standard_clause_Sanctions__c,Score_Sanctions__c,Sanctions__c,
                Standard_clause_Anti_Fraud_RPT__c,Score_Anti_Fraud_RPT__c,Anti_Fraud_and_Record_of_Personal_Trans__c,Standard_clause_Whistleblowing__c,Score_Whistleblowing__c,Whistleblowing__c,
                Standard_clause_Ethics_and_Compliance__c,Score_Ethics_and_Compliance_Program__c,Ethics_and_Compliance_Program__c,Standard_clause_Conflict_of_Interest__c,Score_Conflict_of_Interest__c,
                Conflict_of_Interest__c,Data_Privacy_Status__c,Score_Qualification_of_the_Parties__c,Data_Privacy_Qualification_of_the_Parti__c,Standard_clause_Data_Privacy_Mutual_As__c,
                Score_Data_Privacy_Mutual_Assistance__c,Data_Privacy_Mutual_Assistance__c,Standard_clause_Sub_Processors__c,Score_Data_Privacy_sub_processors__c,Data_Privacy_sub_processors__c,
                Return_Deletion__c,Standard_clause_Return_Deletion__c,Score_Return_Deletion__c,Standard_clause_DP_Security_Measures__c,Score_Data_Privacy_Security_Measures__c,Data_Privacy_Security_Measures__c,
                Standard_clause_Personal_Data_Breaches__c,Score_Data_Privacy_Personal_Data_Brea__c,Data_Privacy_Personal_Data_Breaches__c,Standard_clause_Intern_Data_Transfer__c,Score_Data_Privacy_International_Data__c,
                Data_Privacy_International_Data_Transfe__c,Standard_clause_DP_Laws_Regulations__c,Score_Data_Privacy_Laws_Regulation__c,Data_Privacy_Laws_Regulations__c,Status_compliance__c,Status_data_privacy__c,
                Status_infosec__c,Status_legal__c,Status_opresilience__c,Contract__c
                FROM Legal_Information__c WHERE Id =:recordId
                LIMIT 1];

            if(lstLegInf.size()>0){
                Legal_Information__c currentLegInf = lstLegInf[0];
                
                Legal_Information__c LegInf = currentLegInf.clone(false, true, false, false); //Deep clone

                //Default
                //if (currentLegInf.RecordTypeId == mapLegInfRT.get('Default').Id) {
                    LegInf.RecordTypeId = mapLegInfRT.get('Default').Id;
                //}

                LegInf.OwnerId = UserInfo.getUserId();

                mapResult.put('record', LegInf);
                mapResult.put('objectAPI', 'Legal_Information__c');
                
            }else{
                mapResult.put('error', 'This Legal Information does not exist and cannot be cloned.');
            }
        }

        return mapResult;
    }

    public static String removeBRTags(String pSOW){
        if (pSOW == null) {
            return null;
        }
        pSOW = pSOW.ReplaceAll('<br><br><br>', '<div></div>');
        pSOW = pSOW.ReplaceAll('<br><br>', '<div></div>');
        pSOW = pSOW.ReplaceAll('<br>', '<div></div>');

        return pSOW;
    }
    
    private static boolean canBeCloned(Opportunity currentOpp){
        Set<Id> setAppRecTypesId = new Set<Id>();
        for (RecordType recType: [SELECT Id, Name FROM RecordType WHERE SObjectType ='Opportunity'
        AND (DeveloperName= :AP_Constant.RT_OPP_LIGHTNING_FULL OR
        DeveloperName= :AP_Constant.RT_OPP_LIGHTNING_FULL_RO OR
        DeveloperName= :AP_Constant.RT_OPP_LIGHTNING_SINGLE OR
        DeveloperName= :AP_Constant.RT_OPP_LIGHTNING_SINGLE_RO)
        ]){
            setAppRecTypesId.add(recType.Id);
        }
        System.debug('##lc06 setAppRecTypesId ' + setAppRecTypesId);

        if (setAppRecTypesId.contains(currentOpp.RecordTypeId) ){
            return true;
        }
        else{
            return false;
        }
    }
}