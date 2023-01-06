public without sharing class AP40_GenerateContractShare {
/* 
--------------------------------------------------------------------------------------
-- - Name          : AP40_GenerateContractShare 
-- - Author        : Spoon
-- - Description   : generate contract share for previous owner if user is still in contract team
--
-- Maintenance History: 
--
-- Date         Name  Version  Remarks 
-- -----------  ----  -------  -------------------------------------------------------
-- 30-MAR-2020  SGO   1.0     UAT Ticket : SP-00213
*************************************************************************************/

    @future
    public static void generateContractShare(/*Map<Id, Contract__c> mapofContracts*/ set<id> setCtrId){
    
        Map<String, String> mapUserParentIdAccessLevel = new Map<String, String>();
        Map<Id, List<cTin_ContractTeam__c>> mapofContractIdContractTeam = new Map<Id, List<cTin_ContractTeam__c>>();
        Map<Id, List<Contract__Share>> mapofContractIdContractShare = new Map<Id, List<Contract__Share>>();
        List<Contract__Share> lstNewCtrShare = new List<Contract__Share>();

        //List<cTin_ContractTeam__c> lstContractTeam = new List<cTin_ContractTeam__c>([SELECT Id, Name, cTin_Active__c, cTin_Contract__c, cTin_TeamMember__c, cTin_ContractAccessLevel__c FROM cTin_ContractTeam__c WHERE cTin_Contract__c IN: mapofContracts.keyset() AND cTin_Active__c = true]);
       // List<Contract__Share> lstContractShare = new List<Contract__Share>([SELECT Id, ParentId, UserOrGroupId, AccessLevel FROM Contract__Share WHERE ParentId IN: mapofContracts.keyset()]);
       // List<cTin_ContractTeam__c> lstContractTeam = [SELECT Id, Name, cTin_Active__c, cTin_Contract__c, cTin_TeamMember__c, cTin_ContractAccessLevel__c FROM cTin_ContractTeam__c WHERE cTin_Contract__c IN: mapofContracts.keyset() AND cTin_Active__c = true];
        //List<Contract__Share> lstContractShare = [SELECT Id, ParentId, UserOrGroupId, AccessLevel FROM Contract__Share WHERE ParentId IN: mapofContracts.keyset()];


        // Get ContractId - contract team
        //for (Integer i=0;i<lstContractTeam.size(); i++){
        for(cTin_ContractTeam__c  cteam: [SELECT Id, Name, cTin_Active__c, cTin_Contract__c, cTin_TeamMember__c, cTin_ContractAccessLevel__c FROM cTin_ContractTeam__c WHERE cTin_Contract__c IN: setCtrId /*mapofContracts.keyset()*/ AND cTin_Active__c = true]){
            //build map <contract id, list<contract team>> 
            if (mapofContractIdContractTeam.containsKey(cteam.cTin_Contract__c)){
                mapofContractIdContractTeam.get(cteam.cTin_Contract__c).add(cteam);
            }
            else{
                mapofContractIdContractTeam.put(cteam.cTin_Contract__c, new List<cTin_ContractTeam__c>{cteam});
            }
         }
       // }
        
        // Get ContractId - contract share
        //for (Integer i=0;i<lstContractShare.size(); i++){
        for(Contract__Share ctrShare : [SELECT Id, ParentId, UserOrGroupId, AccessLevel FROM Contract__Share WHERE ParentId IN: setCtrId /*mapofContracts.keyset()*/]){
            //build Map <contract id, list<contract share>>
            if (mapofContractIdContractShare.containsKey(ctrShare.ParentId)){
                mapofContractIdContractShare.get(ctrShare.ParentId).add(ctrShare);
            }
            else{
                mapofContractIdContractShare.put(ctrShare.ParentId, new List<Contract__Share>{ctrShare});
            }
         }
        //}

        // Compare two maps
        for (Id contractId:mapofContractIdContractShare.keyset()){          
            for(Contract__Share ctrShare : mapofContractIdContractShare.get(contractId)){
                mapUserParentIdAccessLevel.put(ctrShare.UserOrGroupId + ' ' + ctrShare.ParentId, ctrShare.AccessLevel);
               
            }
        }
        
        system.debug('***CTIN mapofContractIdContractTeam'+ mapofContractIdContractTeam);
        
        for (Id contractId:mapofContractIdContractTeam.keyset()){
            //loop in list lstcontractTeam, check if user has a contract share
            for(cTin_ContractTeam__c cteam: mapofContractIdContractTeam.get(contractId)){
                system.debug('***CTIN cteam'+ cteam);
                //if key is not avaialble in map, means no sharing exists for the teammember on the current contract
                String keyId = cteam.cTin_TeamMember__c + ' ' + cteam.cTin_Contract__c;
                system.debug('***CTIN keyId '+ keyId );
                if (!mapUserParentIdAccessLevel.containsKey(keyId) ){
                    //create new contract share for the user in mapUserParentIdAccessLevel
                    system.debug('***CTIN cteam.cTin_TeamMember__c '+ cteam.cTin_TeamMember__c);
                    if(cteam.cTin_TeamMember__c!=null){
                    Contract__Share newCtrShare = new Contract__Share(ParentId = cteam.cTin_Contract__c, UserOrGroupId = cteam.cTin_TeamMember__c, AccessLevel = cteam.cTin_ContractAccessLevel__c);
                    lstNewCtrShare.add(newCtrShare);
                    }
                }       
            }
            
        }

        if (lstNewCtrShare.size() > 0){
            system.debug('***CTIN lstNewCtrShare'+ lstNewCtrShare);
           try{ insert lstNewCtrShare;} catch(Exception e){system.debug('***CTIN Exception' +e); }
        }

    }

}