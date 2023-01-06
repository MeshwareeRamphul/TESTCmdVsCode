trigger ContentDistributionTrigger on ContentDistribution (after insert,after update,before insert) {
/* 
--------------------------------------------------------------------------------------
-- - Name          : ContentDistributionTrigger 
-- - Author        : Spoon Consulting 
-- - Description   : Trigger on Content Distribution to auto populate final document url for AXA AIM
                     when uploading content if autopopulate is checked - case 3480 (enhancement)
--
-- Maintenance History: 
--
-- Date         Name  Version  Remarks 
-- -----------  ----  -------  -------------------------------------------------------
-- 29-MAY-2017  MRA     1.0     Initial version
-- 30-APR-2019  MRA     1.1     Uncheck the option PREFERENCESEXPIRES after uploading content delivery.(Applicable for cTin only)
-- 30-JAN-2020  SGO     1.2     Signed content delivery
-- 17-APR-2020  MRA     1.3     Final Doc Url Rule changed = > SP-00186
                                (for unsigned PDF, populated final document url with latest PDF uploaded if "Send for Esignature" is checked )
-- 02-SEP-2020  MRA     1.4     Copy password generated for signde copy on contract field "Password to access Final Document URL"
-- 26-MAY-2021  ARA     1.5     SP-01668 (send signed document when signature is signed) 
*************************************************************************************/
    System.debug('Starting trigger ContentDistributionTrigger');
    
    /* Note: Implemented logic in this trigger instead of ContentDocumentAfterInsert since contentDistribution 
       is not available immediately after uploading unsigned content */
    
   // String suffix_signed = '_signed';
   // set<id> signedContentIdSet=new set<id>();
    //set<id> unsignedContentIdSet=new set<id>();
    list<ContentDistribution> lstCd=new list<ContentDistribution>();
    list<ContentDistribution> lstCdWithPwd=new list<ContentDistribution>();
    list<ContentDistribution> lstCdtoSend=new list<ContentDistribution>();
    for (ContentDistribution cd : trigger.new) {
      /* if (Trigger.isAfter && Trigger.isInsert) {
            if(!cd.Name.contains(suffix_signed)){
                unsignedContentIdSet.add(cd.id);
            }          
        }
       */
        //AP53 - bundle 1 - uncheck preferences to expire  on content deliveries
        if(trigger.isbefore && trigger.isinsert){
            lstCd.add(cd);
        }
        if(trigger.isafter && trigger.isInsert){
            lstCdWithPwd.add(cd);
            lstCdtoSend.add(cd);
        }
    }
       
    
    /*if(signedContentIdSet.size()>0 || unsignedContentIdSet.size()>0){
        //AP02_ContractSignedUrl.updateFinalUrl(signedContentIdSet,unsignedContentIdSet);
        AP22_ContractSignedUrl.cTin_updateFinalUrl(signedContentIdSet,unsignedContentIdSet);
    }*/

    if(lstCd.size()>0){
        AP53_UncheckExpirePreference.uncheckExpirePref(lstCd);
    }
    if(lstCdWithPwd.size()>0){
        AP53_UncheckExpirePreference.RetrievePwd(lstCdWithPwd);
    }
    
    if(lstCdtoSend.size()>0 && PAD.canTrigger('AP22')){
        AP22_SendSignedDocument.sendToSignatories(lstCdtoSend);
    }

    system.debug('Ending trigger ContentDistributionTrigger');

}