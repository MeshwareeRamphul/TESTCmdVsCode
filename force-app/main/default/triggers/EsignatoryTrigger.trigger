trigger EsignatoryTrigger on eSignatory__c (before insert, after insert, before update, after update, after delete) {
    /* 
--------------------------------------------------------------------------------------
-- - Name          : EsignatureTrigger
-- - Author        : Team Kerensen (Initial author of AXA Contract-In trigger EsignatoryAfterUpdate)
-- - Description   : Trigger on Esignatory 
--
-- Maintenance History: 
--
-- Date         Name  Version  Remarks 
-- -----------  ----  -------  -------------------------------------------------------
-- 18-APR-2017  MRA    1.0     Initial version (feed the sign Url From the Signature
*                             with the appropriate Link from the signatory so the client can
*                             sign from Ipad clickable link on the Signature)
-- 01-OCT-2021  ARA     1.1     SP-01773 (update SignedDate field when Signed or Validated)
-- 05-JUL-2021  ARA     1.2     SP-01893 (Upgrade - Migrate Edit eSignature screen to LWC)
*************************************************************************************/
    
    List<eSignatory__c> lstEsignatoryCntrtTeam = new List<eSignatory__c>(); 
	set<id>esignatureSet=new set<id>();

    // 05-JUL-2021  ARA    SP-01893 : Populate new email field
    if (Trigger.isBefore && Trigger.isInsert){
        for(eSignatory__c signato : Trigger.new){
            signato.OpCo_SignatoryEmail__c = signato.EmailTxt__c;
        }
    }

    // HVA 23-11-2017 : All-In Merge ContractIn <<START>>
    if (Trigger.isAfter && Trigger.isInsert){
        Set<Id> setEsignId = new Set<Id>();
        for(eSignatory__c signato : Trigger.new){
            System.debug('isInsert signato.cTin_Role__c => '+signato.cTin_Role__c);
            System.debug('isInsert signato.Contact__c => '+signato.Contact__c);
            System.debug('isInsert signato.eSignature__c => '+signato.eSignature__c);
            System.debug('isInsert signato.eSignature__r.cTin_TECH_IsContractIn__c => '+signato.eSignature__r.cTin_TECH_IsContractIn__c);

            if(PAD.CanTRigger('AP42')){
                if(signato.cTin_Role__c == 'AXA Representative' && signato.Contact__c != null && signato.eSignature__c != null){
                    lstEsignatoryCntrtTeam.add(signato); 
                }
            }
            if(PAD.CanTRigger('AP62')){
                if(signato.ctin_Role__c == AP_Constant.esignRoleValidator){
                    setEsignId.add(signato.Esignature__c);
                }
            }
        }

        if(PAD.CanTRigger('AP42')){
            if (lstEsignatoryCntrtTeam.size() > 0){
                AP42_AddSignatoryToTeam.AddaTeamContact(lstEsignatoryCntrtTeam);
            }
        }
        if(PAD.CanTRigger('AP64')){
            if (setEsignId.size() > 0){
                AP64_ContractFieldsUpdate.updateCtrValidators(setEsignId);
            }
        }
    }

    if (Trigger.isBefore && Trigger.isUpdate){
        List<eSignatory__c> listSignatorySigned = new List<eSignatory__c>();
        for(eSignatory__c signato : Trigger.new){
            if(Trigger.oldMap.get(signato.ID).status__c != signato.status__c && (signato.status__c == AP_Constant.esignatoryStatusValidated || signato.status__c == AP_Constant.esignatoryStatusSigned)){
                signato.SignedDate__c = System.now();
            }
            if(signato.status__c == AP_Constant.esignatoryStatusCancelled){
                signato.Tech_BypassFilter__c = true;
            }else{
                signato.Tech_BypassFilter__c = false;
            }
            
            // 05-JUL-2021  ARA    SP-01893 : Populate new email field
            if(Trigger.oldMap.get(signato.ID).EmailTxt__c != signato.EmailTxt__c){
                signato.OpCo_SignatoryEmail__c = signato.EmailTxt__c;
            }
        }
    }

    if (Trigger.isAfter && Trigger.isUpdate){
        List<eSignatory__c> listSignato = new List<eSignatory__c>();
        Map<Id,List<eSignatory__c>> mapNextSignato = new Map<Id,List<eSignatory__c>>();
        Set<Id> setEsignId = new Set<Id>();

        for(eSignatory__c signato : Trigger.new){
            if(PAD.CanTRigger('AP22')){
                if((Trigger.oldMap.get(signato.ID).status__c == AP_Constant.esignatoryStatusNotStarted || 
                    Trigger.oldMap.get(signato.ID).status__c ==AP_Constant.esignatoryStatusWaiting) && 
                    Trigger.newMap.get(signato.ID).status__c ==AP_Constant.esignatoryStatusReady){
                    listSignato.add(signato) ; 
                }    
            }

            // HVA 23-11-2017 : All-In Merge ContractIn <<START>>
            if(PAD.CanTRigger('AP42')){
                System.debug('isUpdate signato.cTin_Role__c => '+signato.cTin_Role__c);
                System.debug('isUpdate signato.Contact__c => '+signato.Contact__c);
                System.debug('isUpdate signato.eSignature__c => '+signato.eSignature__c);
                System.debug('isUpdate signato.eSignature__r.cTin_TECH_IsContractIn__c => '+signato.eSignature__r.cTin_TECH_IsContractIn__c);
                if(signato.cTin_Role__c == 'AXA Representative' && signato.Contact__c != null && signato.eSignature__c !=null){
                    lstEsignatoryCntrtTeam.add(signato); 
                }
            }   
            // HVA 23-11-2017 : All-In Merge ContractIn <<END>>  

            // ARA 25-08-2021   SP-01823
            if(PAD.CanTRigger('AP62')){
                // for Opco
                if(!signato.esignature__r.cTin_TECH_IsContractIn__c){
                    if(Trigger.oldMap.get(signato.ID).status__c != signato.status__c || signato.Tech_isEsignatureFollowUp__c){
                        if(!mapNextSignato.containsKey(signato.Contract__c)){
                            mapNextSignato.put(signato.Contract__c, new List<eSignatory__c>{signato});
                        }else{
                            List<eSignatory__c> lstEsign = mapNextSignato.get(signato.Contract__c);
                            lstEsign.add(signato);
                            mapNextSignato.put(signato.Contract__c, lstEsign);
                        }
                    }
                }
            }
        }
        
        if(PAD.CanTRigger('AP22')){
            if(listSignato.size() > 0 && !AP22_IpadPurpose.hasExecuted){           
                AP22_IpadPurpose.UpdateSignLink(listSignato);          
            }
            
           // if(esignatureSet.size()>0){
               // AP22_CallUniversign.getSignatories(esignatureSet);
           // }
            
           
        } 

        if(PAD.CanTRigger('AP42')){
            if (lstEsignatoryCntrtTeam.size() > 0){
                AP42_AddSignatoryToTeam.AddaTeamContact(lstEsignatoryCntrtTeam);
            }
        }

        if(PAD.CanTRigger('AP64')){
            if (mapNextSignato.size() > 0){
                AP64_ContractFieldsUpdate.updateCtrNextEsignatory(mapNextSignato);
            }
        }
    }
    // HVA 23-11-2017 : All-In Merge ContractIn <<END>>  

    // ARA 27-08-2022   SP-01823
    if (Trigger.isAfter && Trigger.isDelete){
        Set<Id> setEsignId = new Set<Id>();
        for(eSignatory__c signato : Trigger.old){
            if(signato.ctin_Role__c == AP_Constant.esignRoleValidator){
                setEsignId.add(signato.Esignature__c);
            }
        }
        if(PAD.CanTRigger('AP64')){
            if (setEsignId.size() > 0){
                AP64_ContractFieldsUpdate.updateCtrValidators(setEsignId);
            }
        }
    }
}