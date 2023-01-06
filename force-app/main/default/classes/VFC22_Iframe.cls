public with sharing class VFC22_Iframe {
/* 
--------------------------------------------------------------------------------------
-- - Name          : VFC22_Iframe
-- - Author        : Team Kerensen (Initial author of AXA Contract-In class Ctrl_Iframe)
-- - Description   : controller for page VFP22_AxaExecSign
--
-- Maintenance History: 
--
-- Date         Name  Version  Remarks 
-- -----------  ----  -------  -------------------------------------------------------
-- 19-APR-2017  MRA    1.0     Copied and renamed to VFC22_Iframe
*************************************************************************************/
    public String eSignatureIdFromLC{get;set;}
    public string signUrlfromLC{get;set;}
    //public String id;  
    
    public VFC22_Iframe (){
        eSignatureIdFromLC = ApexPages.currentPage().getParameters().get('eSignatureId');      
        signUrlFromLC= ApexPages.currentPage().getParameters().get('signUrl');  
        system.debug('##signUrl'+ signUrlFromLC);
        system.debug('##eSignatureId'+ eSignatureIdFromLC);
        //https://sign.test.universign.eu/sig/?id=eaf03786-1e59-4e36-8a83-ec04c4214a96
    }
    
    
    public PageReference redirect(){
        eSignatureIdFromLC = ApexPages.currentPage().getParameters().get('eSignatureId');        
        System.debug('$$$viii: ' + eSignatureIdFromLC);
        System.debug('$$$viii: ' + ApexPages.currentPage());
        PageReference pageRef = new PageReference('/'+eSignatureIdFromLC );
                return pageRef;
        
     }


}