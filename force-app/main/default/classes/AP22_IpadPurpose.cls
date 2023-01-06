public without sharing class AP22_IpadPurpose {
/* 
--------------------------------------------------------------------------------------
-- - Name          : AP22_IpadPurpose
-- - Author        : Team Kerensen (Initial author of AXA Contract-In class TR007IpadPurpose)
-- - Description   : Update sign link when esignatory status changes to Ready (Trigger EsignatoryAfterUpdate)
--
-- Maintenance History: 
--
-- Date         Name  Version  Remarks 
-- -----------  ----  -------  -------------------------------------------------------
-- 17-APR-2017  MRA    1.0     Copied and renamed to AP22_IpadPurpose
*************************************************************************************/
  public static boolean hasExecuted=false;

	public static void UpdateSignLink(List<eSignatory__c> listSignato ){
        hasExecuted=true;
        system.debug('## START TR007IpadPurpose.UpdateSignLink');
        Map<ID, List<eSignatory__c>> MapSignatureAndKids = new Map<ID,List<eSignatory__c>>() ;
        List<eSignature__c> ListSignatures = new List<eSignature__c>() ; 
        List<eSignature__c> ListEsiToUodate = new List<eSignature__c>() ; 
        set<id>uniqueEsignatureSet=new set<id>();

        for(eSignatory__c sign : listSignato){
           if( sign.eSignature__c != null){
              if(!MapSignatureAndKids.containsKey(sign.eSignature__c)){
                          MapSignatureAndKids.put(sign.eSignature__c , new List<eSignatory__c>()) ;          
              }
              MapSignatureAndKids.get(sign.eSignature__c).add(sign) ; 
           }  
        }
        
        ListSignatures = [Select ID, SignURL__c from esignature__c where ID in : MapSignatureAndKids.KeySet()] ; 
        
        for(esignature__c signature : ListSignatures){
            if(MapSignatureAndKids.get(signature.ID) != null){
                for(eSignatory__c esi : MapSignatureAndKids.get(signature.ID)){
                            if(esi.signUrl__c != null){
                                signature.SignURL__c = esi.signUrl__c ; 
                                uniqueEsignatureSet.add(signature.id);
                                if(uniqueEsignatureSet.contains(signature.id))
                                    ListEsiToUodate.Add(signature) ;    
                            }
                }
             }     
        }
        
        if(ListEsiToUodate.size()>0){ 
            update ListEsiToUodate ; 
        }
        system.debug('## END TR007IpadPurpose.UpdateSignLink');
    }
}