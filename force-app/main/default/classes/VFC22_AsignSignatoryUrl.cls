public without sharing class VFC22_AsignSignatoryUrl {
/* 
--------------------------------------------------------------------------------------
-- - Name          : VFC22_AsignSignatoryUrl
-- - Author        : Team Kerensen (Initial author of AXA Contract-In class Ctrl_AsignSignatoryUrl)
-- - Description   : Assign signatory url
--
-- Maintenance History: 
--
-- Date         Name  Version  Remarks 
-- -----------  ----  -------  -------------------------------------------------------
-- 19-APR-2017  MRA    1.0    Copied and renamed to VFC22_AsignSignatoryUrl
*************************************************************************************/
    public String eSignatureId{get;set;}
    public String signUrl{get;set;}
    public boolean showpageblock{get;set ;} 

    public VFC22_AsignSignatoryUrl() {
        
    }

    public PageReference asignURL(){

        eSignatureId = ApexPages.currentPage().getParameters().get('eSignatureId');
       
        List<eSignatory__c> eSignatoryList = [Select Id,Name, eSignature__c, FirstName__c, LastName__c, signURL__c  
                                              From eSignatory__c 
                                              WHERE eSignature__c = :eSignatureId
                                               AND status__c = 'Ready'];
        
        for(eSignatory__c eSignatory : eSignatoryList){
            signUrl = eSignatory.signURL__c;
        }
        
        if(signUrl!= null){
           PageReference pageRef = new PageReference( System.label.UrlSalesforceSandbox +'apex/VFP22_AxaExecSign?signUrl='+signURL+'&eSignatureId='+eSignatureId);
           return pageRef;
        }else {  ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'The current user is not a signatory of the contract') ) ; 
            showpageblock=false ;
            return null ; 
        }
         
    }

}