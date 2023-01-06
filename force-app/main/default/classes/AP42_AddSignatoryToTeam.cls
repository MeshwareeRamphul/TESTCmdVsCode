public without sharing class AP42_AddSignatoryToTeam{
/**************************************************************************************
    -- - Author        : Spoon Consulting
    -- - Description   : AccountTriggerHandler
    --
    -- Maintenance History: 
    --
    -- Date         Name  Version  Remarks 
    -- -----------  ----  -------  -------------------------------------------------------
    -- 13-MAY-2021  MRA    1.0     SP-01675 - Correction Bug:sharing not generated for additional axa signatory       
    --------------------------------------------------------------------------------------
**************************************************************************************/
    public static void AddaTeamContact(List<eSignatory__c> ListSignato){
    
        //List<Contract__c> ListContract = new List<Contract__c>() ; 
        List<cTin_ContractTeam__c> listteam = new List<cTin_ContractTeam__c>() ; 
        List<cTin_ContractTeam__c > ListMemberToAdd = new  List<cTin_ContractTeam__c > () ; 
    
        Set<String> SetExisting = new Set<String>();
        
        Set<Id> setIdContract = new Set<iD>(); 
        
        List<eSignatory__c > lstSignatory = [select id, contact__r.cTin_RelatedUser__c, eSignature__r.cTin_TECH_IsContractIn__c,TECH_SignerRole__c, Contract__c from eSignatory__c where id in : ListSignato];
    
        for(eSignatory__c signato : lstSignatory){
               if (signato.eSignature__r.cTin_TECH_IsContractIn__c){
                   setIdContract.add(signato.Contract__c) ; 
                   System.Debug('### relatedUser :' + signato.contact__r.cTin_RelatedUser__c) ;     
                }
        }
       
        
       // Members of the team
       if(setIdContract.size()>0){
           listteam = [Select id,cTin_Role__c,cTin_TeamMember__c from cTin_ContractTeam__c where cTin_Contract__c in : setIdContract] ; 
       }
       System.Debug('### listteam  :' + listteam ) ; 
       
       // construct a set of already created users id in team
       
       for(cTin_ContractTeam__c participant :  listteam){    
           /*MRA 13-MAY-2021 : build set of id + role
            * if(!SetExisting.contains(participant.cTin_TeamMember__c) )
               SetExisting.add(participant.cTin_TeamMember__c) ; 
            */
           if(!SetExisting.contains(participant.cTin_TeamMember__c +''+participant.cTin_Role__c) )
               SetExisting.add(participant.cTin_TeamMember__c+''+participant.cTin_Role__c) ;
       }
       
       System.Debug('### SetExisting: ' + SetExisting) ; 
     
   // Compare id User of signatory contact with team member user ID
   
      if(SetExisting.size()>0){
           for(eSignatory__c sig : lstSignatory){
              if(!SetExisting.contains(sig.contact__r.cTin_RelatedUser__c+'009')){
        
                   cTin_ContractTeam__c  member = new cTin_ContractTeam__c () ; 
                   member.cTin_Contract__c = sig.Contract__c ; 
                   member.cTin_Role__c = '009' ; 
                   member.cTin_ContractAccessLevel__c = 'Edit' ; 
                   member.cTin_ApprovalOrder__c='Not in Approval Process' ; 
                   // Pour ne plus avoir le message d'erreur, le signataire ne sera pas inserer tant que son contact n'a pas de related User
                   if(sig.contact__r.cTin_RelatedUser__c != null){
                       member.cTin_TeamMember__c = sig.contact__r.cTin_RelatedUser__c ; 
                       ListMemberToAdd.add(member) ;
                   }     
               }
           
           }
       } 
    System.Debug('#### ListMemberToAdd : ' + ListMemberToAdd ) ; 
           if(ListMemberToAdd.size()>0){
           
               try{insert ListMemberToAdd ;} catch(exception e) {} 
           }
          
    }


}