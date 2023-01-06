public with sharing class VFC07_ContractPdfManageAttachExt {

/*
 OTC_VF_GenerateContractExtension
----------------------------------------------------------------------
-- - Name          : ContractPdfManageAttachExt (VFC07_ContractPdfManageAttachExt)
-- - Author        : JFF
-- - Description   : Controller for VF07 Pages
--
-- Maintenance History:
-- Date         Name  Version  Remarks
-- -----------  ----  -------  ---------------------------------------
-- 12-JUNE-2015  JFF    1.0     Initial version 
-- 30-JUNE-2015  NGI    1.1     Revised version with attachment of pdf 
-- 3-JULY-2015   NGI    1.2     Introduced variables to manage validation feedback
-- 6-JULY-2015   NGI    1.3     Renamed class into VFC01_ContractPdfManageAttachExt
---8-JULY-2015   JFF    1.4     Renamed class into VFC07 ContractPdfManageAttachExt
                                Adding test for Page GIE/SAS in attach method
                                Adding field aBlankspace
-- 9-NOV-2015    NGI    2.0     Removed method attachContract (added to AP10_ContractHandler.cls as webservice)
-- 13-MAR-2018   USA    2.1     ATS contracts      
-- 21-SEP-2018   USA    2.2     Temporarily add error message for contrats with MSA and SOW Type = Enveloppe   
-- 25-OCT-2018   MRA    2.3     Rework VF templates  (replace reference of planned invoicing lines with invoicing lines) 
-- 26-NOV-2018   USA    2.4     Convergence Template AGS FRANCE
-- 10-JUN-2019   USA    2.5     SP-00072                                                        
----------------------------------------------------------------------
*/
    @TestVisible
    private final Contract__c ctr;
    public List<Planned_Invoicing_Line__c> contrInvLines {get; set;}
    public List<ILWrapper> lstIlWrapper {get;set;}
//    public Id ctrId;
    public Boolean validated{get;set;}
    public String errorMsg{get;set;}
    public ApexPages.StandardController controller;
    public string aBlankSpace {get;set;}
    public Integer nbDaysContractPeriod { get; set; } // Difference between start date and end date
    public Boolean isAsia { get; set; }
    public List<ProductItem__c> lstProdItems {get;set;}
    public String strFormattedStartDate {get;set;}
    public String strFormattedEndDate {get;set;}
    public String strFormattedMSADate {get;set;}
    public Map<String,Contract_Financial_Info__mdt> mapCtrFinancialInfo {get;set;}
    public String strFormattedAmount {get;set;}
    public Map<String, LegalEntityAddress__mdt> mapLegalAdd {get;set;}
    public String strOffer {get;set;}
    public String strMSAReference {get;set;}
    public Boolean booIsATS {get;set;}
    public List<product__c> lstProd {get;set;} 
    public map<String,String> mapLegalEntities {get;set;}
   
    /*    
    ----------------------------------------------------------------------
    / Standard Controller
    ----------------------------------------------------------------------
    */ 
    public string getaBlankSpace (){
        return ' ';
    }

    Public  VFC07_ContractPdfManageAttachExt(ApexPages.StandardController controller) {
        lstIlWrapper = new List<ILWrapper>();

        mapLegalEntities = new map<String,String>();
        mapLegalEntities = getLegalEntities(); 

        if (!Test.isRunningTest()) {
            controller.addFields(new List<String> {'Planned_Invoicing_Lines_Amount__c','CustomerSignedBy__r.Title','AXA_GS_Signed_By__c',
                'AXA_GS_Signed_By__r.Title','EndDate__c','Global_Amount__c','AXA_GO_Legal_Entity__c','ServiceType__c','InvoicingMethod__c',
                'Invoicing_Condition__c','InvoicingMethod__c','Language__c','Account__r.MSA__c','Account__r.MSA_Reference__c',
                'Account__r.MSA_Date__c','RecordType.Name','Account__r.Legal_Statute__c', 'Account__r.Recitals__c','SOW_Operational__c',
                'Service_Type__c','CustomerSignedBy__c','PDFContrAtt__c','StartDate__c','Amendment_to__c', 'Signature_Type__c',
                'RecordType.developerName', 
                //'Customer_Operational_Contact__r.MailingStreet', 'Customer_Operational_Contact__r.MailingCity',
                //'Customer_Operational_Contact__r.MailingState', 'Customer_Operational_Contact__r.MailingPostalCode', 'Customer_Operational_Contact__r.MailingCountry',
                'Account__r.BillingStreet', 'Account__r.BillingCity', 'Account__r.BillingState', 'Account__r.BillingPostalCode', 'Account__r.BillingCountry',
                'Account__r.MSA_ATS_Reference__c', 'Account__r.MSA_ATS_Date__c', 'SOW_Type__c', 'owner.name', 'owner.Title', 'owner.phone', 'owner.email'});
        }
        this.ctr = (Contract__c)controller.getRecord();
        //SP-00072
        if ((ctr.AXA_GO_Legal_Entity__c == System.Label.Ctr_AXA_LE_SAS || ctr.AXA_GO_Legal_Entity__c == System.Label.Ctr_AXA_LE_Spain) && (ctr.RecordType.developerName != AP_Constant.RT_ATS_EDIT) && (ctr.RecordType.developerName != AP_Constant.RT_ATS_READONLY)){
            booIsATS = false;
            //strOffer = ctr.Offer_ff__c;
            //lstProd = new List<product__c>{new product__c(id = ctr.Product__c, name = ctr.Product__r.name, product_description__c = ctr.Product__r.Product_description__c)};
        }
        else{
            booIsATS = true;
        }

//      ctrId = ctr.id;
        contrInvLines = [SELECT AmountIL__c, CurrencyIsoCode, Description__c /*, Invoicing_Predefined_Date__r.Invoicing_Date__c*/, Percent__c, Activity_Type__c  
                         FROM Planned_Invoicing_Line__c 
                         WHERE Contract2__c =: ctr.id AND Type__c = 'Invoicing Line' ORDER BY Invoicing_Date__c ];
        validated = True;
        errorMsg = '    The PDF cannot be previewed because: ' + '\r\n \r\n';
        if (ctr.Account__c == null){
            validated = False;
            errorMsg += '          The field Legal Entity is mandatory' + '\r\n';                
        }
        if (ctr.StartDate__c == null){
            validated = False;
            errorMsg += '          The field Start Date is mandatory' + '\r\n';                
        }
        if (ctr.EndDate__c == null){
            validated = False;
            errorMsg += '          The field End Date is mandatory' + '\r\n';                
        }
        // set the number of days between start date and end date
        if (ctr.StartDate__c != null && ctr.EndDate__c != null) {
            nbDaysContractPeriod = ctr.startDate__c.daysBetween(ctr.EndDate__c);
        }
        if (ctr.SOW_Operational__c == null){
            validated = False;
            errorMsg += '          The field SOW Operational is mandatory' + '\r\n';                
        }   
        if (ctr.InvoicingMethod__c == null){
            validated = False;
            errorMsg += '          The field Invoicing Method is mandatory' + '\r\n';                
        }
        if (ctr.Invoicing_Condition__c == null){
            validated = False;
            errorMsg += '          The field Invoicing Condition is mandatory' + '\r\n';                
        }         
        if (ctr.AXA_GS_Signed_By__c == null){
            validated = False;
            errorMsg += '          The field AXA GS Signed By is mandatory' + '\r\n';              
        }
        if (ctr.AXA_GS_Signed_By__r.Title == null){
            validated = False;
            errorMsg += '          The field AXA GS Signed By Title (to be changed into the Contact filled in AXA GS Signed By) is mandatory' + '\r\n';               
        }                    
        if (contrInvLines.size() == 0){
            validated = False;
            errorMsg += '          At least one Invoicing Line is mandatory' + '\r\n';             
        }       
        if (ctr.SOW_Type__c == null){
            validated = False;
            errorMsg += '          The field SOW Type is mandatory' + '\r\n';
        } 
        if (contrInvLines != null && contrInvLines.size() > 0) {            
            Decimal vPlannedInvSum = 0.0;
            for (Planned_Invoicing_Line__c vPlannedInvLine : contrInvLines) {
                vPlannedInvSum += vPlannedInvLine.AmountIL__c;
                lstIlWrapper.add(new ILWrapper(vPlannedInvLine, vPlannedInvLine.AmountIL__c));
            }               
            if (ctr.Global_Amount__c != vPlannedInvSum){
                validated = False;
                errorMsg += '          The value of Global Amount cannot be different from the value of Invoicing Lines Total Amount ' + '\r\n';                
            }    
        }    

        //USA : 20180921 : Display error message for contract with MSA and SOW Type = Enveloppe
        //if ((ctr.Account__r.MSA_ATS_Reference__c != null) && (ctr.SOW_Type__c == AP_Constant.SOW_ENVELOPPE)){
        //    validated = False;
        //    errorMsg += '          The template for contrats with MSA is currently not available. Please upload the contrat document manually.' + '\r\n';
        //}
        
        isAsia = (ctr.RecordType.developerName == AP_Constant.RT_AGSASIA_EDIT || ctr.RecordType.developerName == AP_Constant.RT_AGSASIA_READONLY);               

        if (ctr.RecordType.developerName == AP_Constant.RT_ATS_EDIT || ctr.RecordType.developerName == AP_Constant.RT_ATS_READONLY){
            lstProdItems = [SELECT Product__r.name, Product__r.Product_description__c 
                            FROM ProductItem__c
                            WHERE Contract__c = :ctr.Id];
        }

        strFormattedStartDate = ctr.startDate__c != null ? ctr.startDate__c.format() : null;
        strFormattedEndDate = ctr.EndDate__c != null ? ctr.EndDate__c.format() : null;
        strFormattedAmount = formatCurrency(ctr.Global_Amount__c);

        if (!booIsATS){
            mapCtrFinancialInfo = getContractWordings('English', ctr.ServiceType__c, ctr.InvoicingMethod__c, ctr.Invoicing_Condition__c);
            strMSAReference = ctr.Account__r.MSA_Reference__c; 
            strFormattedMSADate = ctr.Account__r.MSA_Date__c != null ? ctr.Account__r.MSA_Date__c.format() : null;
        }
        else{
            mapCtrFinancialInfo = getContractWordings(ctr.Language__c, ctr.ServiceType__c, ctr.InvoicingMethod__c, ctr.Invoicing_Condition__c);
            strMSAReference = ctr.Account__r.MSA_ATS_Reference__c; 
            strFormattedMSADate = ctr.Account__r.MSA_ATS_Date__c != null ? ctr.Account__r.MSA_ATS_Date__c.format() : null;
        }

        mapLegalAdd = getLegalEntityAddress(ctr.AXA_GO_Legal_Entity__c);

    }   // Constructor 

    public Map<String,Contract_Financial_Info__mdt> getContractWordings(String strlang, String strServiceType, String strInvMethod, String strInvCondition){
        Map<String,Contract_Financial_Info__mdt> mapCtrFinancialInfo = new Map<String,Contract_Financial_Info__mdt>();

        for (Contract_Financial_Info__mdt cfi :[SELECT Type__c, Contract_Wording__c 
                                                FROM Contract_Financial_Info__mdt
                                                WHERE Type__c IN ('Invoicing Method', 'Service Type')
                                                AND Language__c = :strlang 
                                                AND (Field_Value__c = :strServiceType OR Field_Value__c = :strInvMethod OR Field_Value__c = :strInvCondition)]){
            mapCtrFinancialInfo.put(cfi.Type__c, cfi);
        }
        System.debug('mapCtrFinancialInfo : ' + mapCtrFinancialInfo.size()); 
        return mapCtrFinancialInfo;
    }

    public Map<String,LegalEntityAddress__mdt> getLegalEntityAddress(String strLegalEnt){
        Map<String,LegalEntityAddress__mdt> mapEntAddr = new Map<String,LegalEntityAddress__mdt>();

        for (LegalEntityAddress__mdt entAddr :[SELECT Legal_Entity__c, Address__c 
                                                FROM LegalEntityAddress__mdt
                                                WHERE Legal_Entity__c = :strLegalEnt]){
            mapEntAddr.put(entAddr.Legal_Entity__c, entAddr);
        }
        System.debug('mapEntAddr : ' + mapEntAddr.size()); 
        return mapEntAddr;
    }  

    public static String formatCurrency(Decimal curAmount){
        List<String> amounts = curAmount.toPlainString().split('\\.');
        String reversed = amounts[0].reverse();
        List<String> values = new List<String>();
        while(reversed.length()>3){
         values.add(reversed.substring(0,3));
         reversed = reversed.substring(3);
         if(reversed.length() <=3){
          values.add(reversed);
          break;
            }
        }
        String newAmount = values.size() > 0 ? String.join(values, ' ') : amounts[0].reverse();
        newAmount = newAmount.reverse();
        if(amounts.size() > 1){
         newAmount = newAmount+'.'+amounts[1];
        }
        else{
            newAmount = newAmount+'.00';
        }
        return newAmount;
    }

    public static map<String,String> getLegalEntities(){
        map<String, String> mapPicklistValues = new map<String, String>();
        Schema.DescribeFieldResult fieldResult = contract__c.AXA_GO_Legal_Entity__c.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        for( Schema.PicklistEntry pickListVal : ple){
            mapPicklistValues.put(pickListVal.getValue(),pickListVal.getLabel());
        } 
        return mapPicklistValues; 
    }

    public class ILWrapper{
        public Planned_Invoicing_Line__c pil;
        public String strILAmtFormatted; 

        public ILWrapper(Planned_Invoicing_Line__c currentpil, Decimal curAmount){
            pil = currentpil;
            strILAmtFormatted = VFC07_ContractPdfManageAttachExt.formatCurrency(curAmount);
        }

        public Planned_Invoicing_Line__c getPIL(){
            return pil;
        }

        public String getstrILAmtFormatted(){
            return strILAmtFormatted;
        }
    }
}