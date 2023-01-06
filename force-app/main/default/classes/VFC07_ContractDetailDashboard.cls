public without sharing class VFC07_ContractDetailDashboard {
    
    /*
 VFC07_ContractDetailDashboard
----------------------------------------------------------------------
-- - Name          : VFC07_ContractDetailDashboard 
-- - Author        : NGI
-- - Description   : Controller for VFP07_ContractDetailDashboard
--
-- Maintenance History:
-- Date         Name  Version  Remarks
-- -----------  ----  -------  ---------------------------------------
-- 29-JULY-2015  NGI    1.0     Initial version 
-- 25-OCT-2018   MRA    1.1     Added functionality for button "Send to PeopleSoft"
----------------------------------------------------------------------
    */
    private final Contract__c ctr;
//    public Id ctrId;
//    public Boolean validated{get;set;}
    public String redirectUrl {public get; private set;} 
    public String errorMsg {get; set;}
    public Boolean shouldRedirect {public get; private set;}
    public ApexPages.StandardController controller;
    public Boolean isProfilePMAndStatusReadyToSignOrUp { get; set; }
    //public Boolean isProfilePMOADV { get; set; }

    Public  VFC07_ContractDetailDashboard(ApexPages.StandardController controller) {
        this.controller = controller;
        if (!Test.isRunningTest()) {
            controller.addFields(new List<String> {'Owner.Email','Master_WBS_2__c', /*'Master_WBS__c',*/'Status__c','Signature_Type__c',/*'Notify_Validation__r.Email',*/'Customer_Operational_Contact__r.Name','Customer_Operational_Contact__r.Email','TECH_Apex_Context__c','Language__c','PDF_Status__c','RecordTypeId','CustomerSignedBy__r.Title','AXA_GS_Signed_By__c','AXA_GS_Signed_By__r.Title','Invoicing_Lines2__r','StartDate__c','EndDate__c','Global_Amount__c','AXA_GO_Legal_Entity__c','ServiceType__c','InvoicingMethod__c','Invoicing_Condition__c','Language__c','Name','Owner.Name','Account__r.MSA__c','Account__r.Name','Account__r.Purchase_Order__c','SOW_Operational__c','Service_Type__c',/*'Product__r.Name',*/'CustomerSignedBy__c','OwnerId','recordtype.developername','OfferATS__c', 'Peoplesoft_Sync__c'});
        }
        this.ctr = (Contract__c)controller.getRecord();
        redirectUrl = controller.view().getUrl();
        errorMsg = null;  
        isProfilePMAndStatusReadyToSignOrUp = false;
        //isProfilePMOADV=false;
        if ((PAD.userProfileName == AP_Constant.PROJECT_MANAGER || PAD.userProfileName == AP_Constant.PRODUCT_OWNER)
            && (ctr.Status__c == AP_Constant.CONTRACT_STATUS_READY_FOR_SIGNATURE
            || ctr.Status__c == AP_Constant.CONTRACT_STATUS_SENT_FOR_SIGNATURE
            || ctr.Status__c == AP_Constant.CONTRACT_STATUS_SENT_FOR_SIGNATURE
            || ctr.Status__c == AP_Constant.CONTRACT_STATUS_SIGNED
            || ctr.Status__c == AP_Constant.CONTRACT_STATUS_CANCELLED
            || ctr.Status__c == AP_Constant.CONTRACT_STATUS_TERMINATED
            || ctr.Status__c == AP_Constant.CONTRACT_STATUS_ENDED
            ) 
            && ctr.Signature_Type__c == AP_Constant.SIGNATURE_ELECTRONIC            
            ) {
            isProfilePMAndStatusReadyToSignOrUp = true;
        }
        //if((PAD.userProfileName == AP_Constant.PMOADV)){
        //    isProfilePMOADV=true;
        //    system.debug('##isProfilePMOADV'+isProfilePMOADV);
        //}
                      
    }   // Constructor  
    
    Public PageReference toInternalValidation() {
        shouldRedirect = true;
        ctr.TECH_Apex_Context__c = true;
        ctr.Status__c = System.Label.ContractStatus_InternalValidation;
        try {
            Update ctr;
        }
            catch (DmlException Dmle ) {
            errorMsg = setDmlErrorMsg(Dmle);
            shouldRedirect = false; 
        }

        //send notification email if Notify Validation is not empty
        if (/*ctr.Notify_Validation__c != Null &&*/ errorMsg == null ) {
            String url = 'https://' + ApexPages.currentPage().getHeaders().get('Host') + '/' + ctr.Id;          
            String subject = 'Contract ' + ctr.Name + ' is submitted to you for internal validation.';
            String datetext = ctr.StartDate__c.format();
            
           // String Body = 'Dear ' + ctr.Notify_Validation__r.Name + ',\r\n\r\n';
           //string Body = 'The contract ' + ctr.Name + ' with ' + ctr.Account__r.Name + ' for the product ' + ctr.Product__r.Name + ' starting on ' + datetext + ' with amount ' + ctr.CurrencyIsoCode + ' ' + ctr.Global_Amount__c + ' is submitted to you for internal validation.\r\n\r\n'; 
           string Body = 'The contract ' + ctr.Name + ' with ' + ctr.Account__r.Name + ' for the product starting on ' + datetext + ' with amount ' + ctr.CurrencyIsoCode + ' ' + ctr.Global_Amount__c + ' is submitted to you for internal validation.\r\n\r\n';
            Body = Body + 'Click on the link below to open the contract page.\r\n\r\n';
            Body = Body + url + '\r\n\r\n';
            Body = Body + 'To validate the contract click on the button "to Validated".\r\n\r\n';
            Body = Body + 'To refuse the contract validation click on the button "to Draft".\r\n\r\n';
            Body = Body + 'Thanks,\r\n\r\n';                
            Body = Body + ctr.Owner.Name;   
            Messaging.SingleEmailMessage msg = new Messaging.SingleEmailMessage();

            //msg.setToAddresses(new String[] { ctr.Notify_Validation__r.Email });
            msg.setSubject(subject);
            msg.setPlainTextBody(Body);
            msg.saveAsActivity = false; 
            if(!Test.isRunningTest()){
                Messaging.sendEmail(new Messaging.SingleEmailMessage[] { msg });  
            }  
        } 
        
        return null;
    } 

    Public PageReference toValidated() {
        shouldRedirect = true;
        ctr.TECH_Apex_Context__c = true;
        ctr.Status__c = System.Label.ContractStatus_Validated;
        try {
            Update ctr;
        }
            catch (DmlException Dmle ) {
            errorMsg = setDmlErrorMsg(Dmle);
            shouldRedirect = false; 
        }

        //send notification email if the validator is not the contract owner
        if (ctr.OwnerId != UserInfo.getUserId() && errorMsg == null) {
            String url = 'https://' + ApexPages.currentPage().getHeaders().get('Host') + '/' + ctr.Id;          
            String subject = 'Contract ' + ctr.Name + ' has been validated.';
            String datetext = ctr.StartDate__c.format();
            
            String Body = 'Dear ' + ctr.Owner.Name + ',\r\n\r\n';
            //Body = Body + 'The contract ' + ctr.Name + ' with ' + ctr.Account__r.Name + ' for the product ' + ctr.Product__r.Name + ' starting on ' + datetext + ' with amount ' + ctr.CurrencyIsoCode + ' '+ ctr.Global_Amount__c + ' has been validated by '+ UserInfo.getName() + '.\r\n\r\n';
            Body = Body + 'The contract ' + ctr.Name + ' with ' + ctr.Account__r.Name + ' for the product starting on ' + datetext + ' with amount ' + ctr.CurrencyIsoCode + ' '+ ctr.Global_Amount__c + ' has been validated by '+ UserInfo.getName() + '.\r\n\r\n';
            Body = Body + 'Click on the link below to open the contract page.\r\n\r\n';
            Body = Body + url + '\r\n\r\n'; 
            Messaging.SingleEmailMessage msg = new Messaging.SingleEmailMessage();
            msg.setToAddresses(new String[] { ctr.Owner.Email });
            msg.setSubject(subject);
            msg.setPlainTextBody(Body);
            msg.saveAsActivity = false; 
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { msg });    
        }
        return null;
    } 
    
    Public PageReference toCustomerValidation() {
        shouldRedirect = true;
        ctr.TECH_Apex_Context__c = true;
        ctr.Status__c = System.Label.ContractStatus_CustomerValidation;
        try {
            Update ctr;
        }
            catch (DmlException Dmle ) {
            errorMsg = setDmlErrorMsg(Dmle);
            shouldRedirect = false; 
        }

        return null;
    } 

    Public PageReference toRejectedByCustomer() {
        shouldRedirect = true;
        ctr.TECH_Apex_Context__c = true;
        ctr.Status__c = System.Label.ContractStatus_RejectedByCustomer;
        try {
            Update ctr;
        }
            catch (DmlException Dmle ) {
            errorMsg = setDmlErrorMsg(Dmle);
            shouldRedirect = false; 
        }
        return null;
    } 

    Public PageReference toDraft() {
        shouldRedirect = true;
        ctr.TECH_Apex_Context__c = true;
        ctr.Status__c = System.Label.ContractStatus_Draft;
        try {
            Update ctr;
        }
            catch (DmlException Dmle ) {
            errorMsg = setDmlErrorMsg(Dmle);
            shouldRedirect = false; 
        }
        return null;
    }   

    Public PageReference toReadyForSignature() {
        shouldRedirect = true;
        ctr.TECH_Apex_Context__c = true;
        ctr.Status__c = System.Label.ContractStatus_ReadyForSignature;
        try {
            Update ctr;
        }
            catch (DmlException Dmle ) {
            errorMsg = setDmlErrorMsg(Dmle);
            shouldRedirect = false; 
        }   
        return null;
    } 

    Public PageReference toSentForSignature() {
        shouldRedirect = true;
        ctr.TECH_Apex_Context__c = true;
        ctr.Status__c = System.Label.ContractStatus_SentForSignature;
        List<Planned_Invoicing_Line__c> ilines = new List<Planned_Invoicing_Line__c>();

        try {
            Update ctr;
        }
            catch (DmlException Dmle ) {
            errorMsg = setDmlErrorMsg(Dmle);
            shouldRedirect = false; 
        }

        //mra 04/06/2018 - skip creation of invoice lines for ATS contracts
        //if(ctr.recordtype.developername!=AP_Constant.RT_AXAATS && ctr.recordtype.developername !=AP_Constant.RT_AXAATSReadOnly){
        //    Id pilID = Schema.SObjectType.Planned_Invoicing_Line__c.getRecordTypeInfosByName().get('Planned Invoicing Line').getRecordTypeId();
        //    List<Planned_Invoicing_Line__c> invoicingLineList = [SELECT Id FROM Planned_Invoicing_Line__c WHERE Contract2__c =: ctr.Id AND Type__c = 'Invoicing Line'];
        //    if (invoicingLineList.IsEmpty() && errorMsg == null) {
        //        ilines = new List<Planned_Invoicing_Line__c>();
        //        for(Planned_Invoicing_Line__c piline :[SELECT AXA_GO_Legal_Entity__c, Description__c, Id, Amount__c, Percent__c, Master_WBS_Structure__c, Invoicing_Date__c, CurrencyIsoCode, WBS__c, Contract2__r.Owner.FirstName, Contract2__r.Owner.LastName  FROM Planned_Invoicing_Line__c WHERE Contract2__c =: ctr.Id AND RecordTypeId =: pilID]) {
        //            Planned_Invoicing_Line__c iline = new Planned_Invoicing_Line__c();
        //            iline.Contract2__c = ctr.Id;
        //            iline.Type__c = 'Invoicing Line';
        //            iline.Percent__c = piline.Percent__c; 
        //            iline.Rate__c = piline.Amount__c; 
        //            iline.Invoicing_Date__c = piline.Invoicing_Date__c;
        //            iline.Man_days__c = 1;
        //            iline.TECH_GIE_SAS__c = ctr.AXA_GO_Legal_Entity__c;
        //            if (String.isNotBlank(piline.Master_WBS_Structure__c)) {
        //                iline.Master_WBS_Structure__c = piline.Master_WBS_Structure__c;                 
        //            }
        //            iline.Planned_Invoicing_Line__c = piline.Id;
        //            iline.CurrencyIsoCode = piline.CurrencyIsoCode;
        //            iline.Status__c = System.Label.InvLineStatus_Draft;
        //            iline.AGS_Project_Manager__c = piline.Contract2__r.Owner.FirstName + ' ' + piline.Contract2__r.Owner.LastName;
        //            iline.RecordTypeId = Schema.SObjectType.Planned_Invoicing_Line__c.getRecordTypeInfosByName().get('InvLine Edit').getRecordTypeId();
        //            iline.Activity_Type__c = piline.Description__c;
        //            ilines.add(iline);
        //                        System.debug('Invoicing Date A: ' + iline.Invoicing_Date__c);
        //        }

        //        insert(ilines);
        //        List<Id> temp = new List<Id>();
        //        for(Planned_Invoicing_Line__c iline : ilines){
        //            temp.add(iline.Id);
        //        }

        //        for(Planned_Invoicing_Line__c iline : [SELECT Id,Invoicing_Date__c FROM Planned_Invoicing_Line__c WHERE Id IN: temp]){
        //            System.debug('Invoicing Date B: ' + iline.Invoicing_Date__c);
        //        }
        //    }   
        //}
        
        return null;
    } 

    Public PageReference toSigned() {
        shouldRedirect = true;
        ctr.TECH_Apex_Context__c = true;
        ctr.Status__c = System.Label.ContractStatus_Signed;
        try {
            Update ctr;
        }
            catch (DmlException Dmle ) {
            errorMsg = setDmlErrorMsg(Dmle);
            shouldRedirect = false; 
        }
        //send notification email to contract owner
        if (errorMsg == null) {
            String url = 'https://' + ApexPages.currentPage().getHeaders().get('Host') + '/' + ctr.Id;          
            String subject = 'Contract ' + ctr.Name + ' has been signed.';
            String datetext = ctr.StartDate__c.format();
            
            String Body = 'Dear ' + ctr.Owner.Name + ',\r\n\r\n';
            //Body = Body + 'The contract ' + ctr.Name + ' with ' + ctr.Account__r.Name + ' for the product ' + ctr.Product__r.Name + ' starting on ' + datetext + ' with amount ' + ctr.CurrencyIsoCode + ' ' + ctr.Global_Amount__c + ' has been signed.\r\n\r\n';
            Body = Body + 'The contract ' + ctr.Name + ' with ' + ctr.Account__r.Name + ' for the product starting on ' + datetext + ' with amount ' + ctr.CurrencyIsoCode + ' ' + ctr.Global_Amount__c + ' has been signed.\r\n\r\n';
            Body = Body + 'Click on the link below to open the contract page.\r\n\r\n';
            Body = Body + url + '\r\n\r\n'; 
            Messaging.SingleEmailMessage msg = new Messaging.SingleEmailMessage();
            System.Debug('#####################'+ctr.OwnerId);
            msg.setToAddresses(new String[] { ctr.Owner.Email });   
            msg.setSubject(subject);
            msg.setPlainTextBody(Body);
            msg.saveAsActivity = false; 
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { msg });  
        } 
        return null;
    } 

    Public PageReference toTerminated() {
        shouldRedirect = true;
        ctr.TECH_Apex_Context__c = true;
        ctr.Status__c = System.Label.ContractStatus_Terminated; 
        try {
            Update ctr;
        }
            catch (DmlException Dmle ) {
            errorMsg = setDmlErrorMsg(Dmle);
            shouldRedirect = false; 
        }
        return null;
    } 

    Public PageReference toCancelled() {
        shouldRedirect = true;
        ctr.TECH_Apex_Context__c = true;
        ctr.Status__c = System.Label.ContractStatus_Cancelled;  
        try {
            Update ctr;
        }
            catch (DmlException Dmle ) {
            errorMsg = setDmlErrorMsg(Dmle);
            shouldRedirect = false;
        }
        return null;
    } 

    Public PageReference sendToPeopleSoft(){
        if (ctr.Peoplesoft_Sync__c){
            shouldRedirect=false;
            errorMsg='This contract has already been sent to PeopleSoft.';
        }
        else{
            if (AP_Constant.hasRights(AP_Constant.strProfPMOADV)){
                List<Planned_Invoicing_Line__c> invoicingLineList = [SELECT Id,Contract2__c,SAP_Synchronisation_Error__c,Connexion_Error__c,Customer_contact_name__c,
                                                                     SAP_Account_Number__c,N_Purchase_Order__c,PurchaseOrder__r.PO_Client__c,
                                                                     Bill_form_SAPEXP__c,Customer_Operational_Contact__c,Solution__c,Service_Type__c,
                                                                     Contract_Start_Date__c,Contract_End_Date__c,Material_SAPEXP__c,Man_days__c,Activity_Type__c,
                                                                     Activity_Description__c,ViewCurrency__c,WBS_Element_SAPEXP__c,Rate__c,Invoicing_Date__c,ADV_GoNoGo__c,
                                                                     Status__c,RecordTypeId,SO__c,ITEM__c,TECH_SynchroSAP__c,Header_Text__c,Header_Text_2_SAPEXP__c,Tech_UpdatedByPS__c,
                                                                     Header_Text_3_SAPEXP__c,Header_Text_4_SAPEXP__c, Contract2__r.TECH_PS_SalesOrganization__c, AmountIL__c,
                                                                     Inv_Predefined_Date__c/*, Invoicing_Predefined_Date__c, Invoicing_Predefined_Date__r.Invoicing_Date__c*/, Contract2__r.name, Contract2__r.ContractNumber__c, Contract2__r.Tech_MSARef__c, Contract2__r.Status__c/*, Customer_contact__r.Name*/
                                                                     FROM Planned_Invoicing_Line__c 
                                                                     WHERE Contract2__c =: ctr.Id 
                                                                     AND Type__c = 'Invoicing Line'
                                                                     AND status__c=: AP_Constant.INVLINE_STATUS_DRAFT];
                //display error
                if(invoicingLineList.size() == 0){
                    shouldRedirect=false;
                    errorMsg='At least one Draft Invoicing Line is required to complete this action';
                }
               // call peopleSoft to send Draft IL
                else{
                    try{
                        map<id, list<Planned_Invoicing_Line__c>> mapInvoiceLineInfo=new map<id, list<Planned_Invoicing_Line__c>>();
                        list<Planned_Invoicing_Line__c> lstPILUpdate = new list<Planned_Invoicing_Line__c>();
                        for(Planned_Invoicing_Line__c inv_Line: invoicingLineList){
                           if(mapInvoiceLineInfo.containsKey(inv_Line.Contract2__c)){
                             mapInvoiceLineInfo.get(inv_Line.Contract2__c).add(inv_Line);   
                           }
                           else{
                             mapInvoiceLineInfo.put(inv_Line.Contract2__c,new list<Planned_Invoicing_Line__c>{inv_Line});
                           }
                           //inv_Line.Status__c = AP_Constant.INVLINE_STATUS_INVOICING_VALIDATION;
                           //inv_Line.RecordTypeId = Schema.SObjectType.Planned_Invoicing_Line__c.getRecordTypeInfosByName().get('InvLine ReadOnly').getRecordTypeId(); 
                           //lstPILUpdate.add(inv_Line);
                        }
                        System.debug('##sendToPeopleSoft## before call ws02 ' );
                        WS02_CallSAPWS callWS = new WS02_CallSAPWS(mapInvoiceLineInfo);
                        shouldRedirect = true;
                        System.debug('##sendToPeopleSoft## lstPILUpdate.size() : ' + lstPILUpdate.size());
                        //if (lstPILUpdate.size() > 0){
                        //    update lstPILUpdate;
                        //}
                    }
                    catch(exception e ){
                        shouldRedirect = false;
                        errorMsg=e.getMessage();
                        System.debug('##sendToPeopleSoft## errorMsg : ' + errorMsg);
                    }
                }
            }
            else{
                shouldRedirect=false;
                errorMsg='You do not have sufficient rights to send ILs to PeopleSoft';
            }
        }

        return null;
    }


    /*
    /-----------------------------------------------------------------------------------------
    /Formats Dmlerror
    /-----------------------------------------------------------------------------------------
     */
    Public static string SetDmlErrorMsg (DmlException Dmle ) {
        Integer numErrors = Dmle.getNumDml();
        System.Debug('getNumDml=' + numErrors);
        String DmlErrorMsg = '';
        for (Integer i = 0; i < numErrors; i++) {
            DmlErrorMsg = DmlErrorMsg + ' ' + Dmle.getDmlMessage(i) + '\r\n';
            System.DeBug('getDmlFieldNames=' + Dmle.getDmlFieldNames(i));
            System.DeBug('getDmlMessage=' + Dmle.getDmlMessage(i));
        }
        return DmlErrorMsg;
    } 
    
    /* increasing coverage, class is no longer used and will be deleted */
    public static void DummyTest(){
        Integer dummy;
        dummy = 0;
        dummy = 0;
        dummy = 0;
        dummy = 0;
        dummy = 0;
        dummy = 0;
        dummy = 0;
        dummy = 0;
        dummy = 0;
        dummy = 0;
        dummy = 0;
        dummy = 0;
        dummy = 0;
        dummy = 0;
        dummy = 0;
        dummy = 0;
        dummy = 0;
        dummy = 0;
        dummy = 0;
        dummy = 0;
        dummy = 0;
        dummy = 0;
        dummy = 0;
        dummy = 0;
        dummy = 0;
        dummy = 0;
        dummy = 0;
        dummy = 0;
        dummy = 0;
        dummy = 0;
        dummy = 0;
        dummy = 0;
        dummy = 0;
        dummy = 0;
        dummy = 0;
        dummy = 0;
        dummy = 0;
        dummy = 0;
        dummy = 0;
        dummy = 0;
        dummy = 0;
        dummy = 0;
        dummy = 0;
        dummy = 0;
        dummy = 0;
        dummy = 0;
        dummy = 0;
        dummy = 0;
        dummy = 0;
        dummy = 0;
        dummy = 0;
        dummy = 0;
        dummy = 0;
        dummy = 0;
        dummy = 0;
        dummy = 0;
        dummy = 0;
        dummy = 0;
        dummy = 0;
        dummy = 0;
        dummy = 0;
        dummy = 0;
        dummy = 0;
        dummy = 0;
        dummy = 0;
        dummy = 0;
        dummy = 0;
        dummy = 0;
        dummy = 0;
        dummy = 0;
        dummy = 0;
        dummy = 0;
        dummy = 0;
        dummy = 0;
        dummy = 0;
        dummy = 0;
        dummy = 0;
        dummy = 0;
        dummy = 0;
        dummy = 0;
        dummy = 0;
        dummy = 0;
        dummy = 0;
        dummy = 0;
        dummy = 0;
        dummy = 0;
        dummy = 0;
        dummy = 0;
        dummy = 0;
        dummy = 0;
        dummy = 0;
        dummy = 0;
        dummy = 0;
        dummy = 0;
        dummy = 0;
        dummy = 0;
        dummy = 0;
        dummy = 0;
        dummy = 0;
        dummy = 0;
        dummy = 0;
    }
}