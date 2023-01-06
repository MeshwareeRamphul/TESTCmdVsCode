public without sharing class AP64_ContractFieldsUpdate {
    /* 
    --------------------------------------------------------------------------------------
    -- - Name          : AP64_ContractFieldsUpdate
    -- - Author        : ARA
    -- - Description   : used for update contract fields
    --
    -- Maintenance History: 
    --
    -- Date         Name  Version  Remarks 
    -- -----------  ----  -------  -------------------------------------------------------
    -- 23-AUG-2021  ARA    1.0     Initial version (SP-01823: eSignature follow up)
    -- 03-MAY-2022  ARA    2.0     SP-03718 (add Tech_Esignatory_Changed__c to skip VR)
    --------------------------------------------------------------------------------------*/
        public static void updateCtrNextEsignatory(Map<Id,List<eSignatory__c>> mapEsignatory){
            List<Contract__c> lstCtr = new List<Contract__c>();
            Map<Id, Contract__c> mapContract = new Map<Id, Contract__c>([SELECT Id, AXA_GS_Signed_By__r.Name,AXA_GO_Signed_By_2__r.Name, CustomerSignedBy__r.Name, CustomerSignedBy2__r.Name, Tech_Esignatory_Changed__c  FROM Contract__c WHERE id IN :mapEsignatory.keySet()]);
            String role = '';
               
            for(Id ctrId: mapEsignatory.keySet()){
                Contract__c ctr = new Contract__c(Id=ctrId, NextEsignatory__c=null, Tech_NextEsignatory__c=null, CurrentEsignatureStep__c = '');
                for(eSignatory__c esign: mapEsignatory.get(ctrId)){
                    if(esign.Status__c == AP_Constant.esignatoryStatusReady){
                        if(esign.cTin_Role__c == AP_Constant.esignRoleValidator){
                            role = 'Validator ' + esign.Order__c;
                        }else if(esign.Name == mapContract.get(ctrId).AXA_GS_Signed_By__r.Name){
                            role = 'AXA GO Signed By 1';
                        }else if(esign.Name == mapContract.get(ctrId).AXA_GO_Signed_By_2__r.Name){
                            role = 'AXA GO Signed By 2';
                        }else if(esign.Name == mapContract.get(ctrId).CustomerSignedBy__r.Name){
                            role = 'Customer Signed By 1';
                        }else if(esign.Name == mapContract.get(ctrId).CustomerSignedBy2__r.Name){
                            role = 'Customer Signed By 2';
                        }
    
                        ctr.PendingSince__c = System.now();
                        ctr.Tech_NextEsignatory__c = esign.Id;
                        ctr.CurrentEsignatureStep__c = role;
                        ctr.NextEsignatory__c = '<a target="_self" href="'+System.URL.getSalesforceBaseURL().toExternalForm()+'/'+esign.Id+'">'+esign.Name +' - '+role+'</a>';
                        break;
                    }
                }
                ctr.Tech_Esignatory_Changed__c = mapContract.get(ctrId).Tech_Esignatory_Changed__c ? false : true;
                lstCtr.add(ctr);
            }
    
            if(lstCtr.size() > 0){
                update lstCtr;
            }
        }
        
        /*public static void updateCtrPendingSince(Map<Id,eSignature__c> mapEsignature){
            List<Contract__c> lstCtr = new List<Contract__c>();
            Set<Id> setCtrId = new Set<Id>();
            for(Id ctrId: mapEsignature.keySet()){
                setCtrId.add(ctrId);
            }
            if(setCtrId.size() > 0){
                Map<Id, Contract__c> mapContract = new Map<Id, Contract__c>([SELECT Id, Tech_Esignatory_Changed__c  FROM Contract__c WHERE id IN :setCtrId]);
                for(Id ctrId: mapEsignature.keySet()){
                    Contract__c ctr = new Contract__c(Id=ctrId, PendingSince__c = null, Tech_Esignatory_Changed__c = mapContract.get(ctrId).Tech_Esignatory_Changed__c ? false : true);
                    lstCtr.add(ctr);
                }
        
                if(lstCtr.size() > 0){
                    update lstCtr;
                }
            }
        }*/
        
        public static void updateCtrValidators(Set<Id> setEsignId){
            Map<Id, Contract__c> mapContract = new Map<Id, Contract__c>();
    
            for(eSignature__c esign: [SELECT id, Contract__c, Contract__r.Tech_Esignatory_Changed__c FROM eSignature__c WHERE Id IN :setEsignId]){
                Contract__c ctr = new Contract__c(Id = esign.Contract__c, Validator1__c = null, Validator2__c = null, Validator3__c = null, Validator4__c = null);
                ctr.Tech_Esignatory_Changed__c = esign.Contract__r.Tech_Esignatory_Changed__c ? false : true;
                mapContract.put(esign.Contract__c, ctr);
            }
            List<eSignatory__c> lstEsignatory = [SELECT id, Order__c, Contact__c, Contract__c, Contract__r.Tech_Esignatory_Changed__c 
                                                FROM eSignatory__c 
                                                WHERE eSignature__c IN :setEsignId 
                                                AND (eSignature__r.Status__c = :AP_Constant.eSignatureCreatedStatus 
                                                OR eSignature__r.Status__c = :AP_Constant.eSignatureSentStatus)
                                                AND cTin_Role__c = :AP_Constant.esignRoleValidator 
                                                ORDER BY Order__c ASC];
            if(lstEsignatory.size() > 0){
                for(eSignatory__c signato: lstEsignatory){
                    if(mapContract.containsKey(signato.Contract__c)){
                        Contract__c ctr = mapContract.get(signato.Contract__c);
                        if(signato.Order__c == 1){
                            ctr.Validator1__c = signato.Contact__c;
                        }else if(signato.Order__c == 2){
                            ctr.Validator2__c = signato.Contact__c;
                        }else if(signato.Order__c == 3){
                            ctr.Validator3__c = signato.Contact__c;
                        }else if(signato.Order__c == 4){
                            ctr.Validator4__c = signato.Contact__c;
                        }
                        mapContract.put(signato.Contract__c, ctr);
                    }
                }
            }
    
            if(mapContract.size() > 0){
                try{
                    update mapContract.values();
                }catch(DmlException e){System.debug('***Error message: '+e.getMessage());}
            }
        }
    }