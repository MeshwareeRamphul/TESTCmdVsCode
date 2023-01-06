public without sharing class AP38_AddNewMember{
 /* 
----------------------------------------------------------------------
-- - Name          : AP38_AddNewMember
-- - Author        : Spoon Consulting
-- - Description   : AP38_AddNewMember (Taken from contract In : original author-Kerensen Team)
-- Maintenance History:
--
-- Date         Name    Version  Remarks 
-- -----------  ----    -------  ---------------------------------------
-- 7-NOV-2017  HVA/MRA    1.0      Initial version (Reworked)                  
---------------------------------------------------------------------
**********************************************************************
*/   
   	static Set<String> setapexclass = new Set<String>() ; 
    
	public static void addAxaRep(Set<ID> SetContractID){
		setapexclass.add('AP38_AddNewMember') ; 
		List<Contract__c> ListContract = new List<Contract__c>() ; 
		Map<Id,Id> MapContractUser = new Map<Id,Id>() ;
		List<cTin_ContractTeam__c> ListMember  = new List<cTin_ContractTeam__c>() ; 
    
		system.debug('******* SetContractID '+SetContractID);
       	if(SetContractID.size()>0){
           	ListContract = [Select Id, 
							cTin_AXASignatoryRepresentative__r.cTin_relatedUser__c 
							From Contract__c 
			                Where Id in: SetContractID] ; 
       	}
		   system.debug('******* ListContract '+ListContract);
       
		for(Contract__c con : ListContract){
		    if(con.cTin_AXASignatoryRepresentative__r.cTin_relatedUser__c != null)
		    	MapContractUser.put(con.Id, con.cTin_AXASignatoryRepresentative__r.cTin_relatedUser__c); 
		}
		system.debug('******* MapContractUser '+MapContractUser);

		if(MapContractUser.size()>0){
			for(Contract__c  con : ListContract){
				if(MapContractUser.get(con.Id) != null){
					cTin_ContractTeam__c  member = new cTin_ContractTeam__c () ; 
					member.cTin_Contract__c = con.Id; 
					member.cTin_Role__c = '009' ; 
					member.cTin_ContractAccessLevel__c = 'Edit' ; 
					member.cTin_ApprovalOrder__c = 'Not in Approval Process' ; 
					member.cTin_TeamMember__c = MapContractUser.get(con.Id) ; 
					ListMember.add(member) ;  
				}
			}
		}
       
		PAD.doNotExecuteAfterMe(setapexclass) ; 
		system.debug('******* ListMember '+ListMember);
		if(ListMember.size()>0) insert ListMember ; 
    }
    
    // Map un contrat / un contact 
    public static void deleteAxaRep(Map<Id, Id> MapOldAxarepWContract){
        setapexclass.add('AP38_AddNewMember') ; 
        List<Contact> ListContact = new List<Contact>() ;
        List<cTin_ContractTeam__c> ListTeam = new List<cTin_ContractTeam__c>() ; 
        List<cTin_ContractTeam__c > ListMemberToDel= new List<cTin_ContractTeam__c >() ; 
        Map<Id,List<cTin_ContractTeam__c>> MapContractwMembers = new  Map<Id,List<cTin_ContractTeam__c>>() ;  
        Map<Id,Id> MapIdContactWUser = new Map<Id,Id>() ; 
        Map<Id,Id> MapContractWUser = new Map<Id,Id>() ; 
        
        ListContact = [Select Id, cTin_relatedUser__c 
        				 From Contact 
        				Where Id in :MapOldAxarepWContract.keySet()]; 
        
        for(Contact cont : ListContact){
            MapIdContactWUser.put(cont.Id, cont.cTin_relatedUser__c) ; 
        }
        
        for(Id Idcontact : MapOldAxarepWContract.keyset() ){
            // Creation de la map avec comme clef un contrat et comme valeur un contact
            MapContractWUser.put(MapOldAxarepWContract.get(Idcontact) , MapIdContactWUser.get(IdContact)) ; 
        }
        
        //SC - MRA : added condition where role ="Legal rep" and in approval process  (Case 00001223)
        ListTeam = [Select Id,
				           cTin_TeamMember__c,
				           cTin_Contract__c,
				           cTin_role__c, 
				           cTin_ApprovalOrder__c 
				      From cTin_ContractTeam__c 
				     Where cTin_Contract__c in :MapOldAxarepWContract.values() 
				       And cTin_role__c='009' 
				       And cTin_ApprovalOrder__c='Not in Approval Process'] ;
        
        if(ListTeam.size()>0){
			for(cTin_ContractTeam__c member : ListTeam){
				if(!MapContractwMembers.containskey(member.cTin_contract__c)){
					MapContractwMembers.put(member.cTin_contract__c, new List<cTin_ContractTeam__c >() ) ; 
				}
				MapContractwMembers.get(member.cTin_contract__c).add(member) ; 
			}
        }
            
		for(Id IdContrat : MapContractWUser.keySet()){
			if(MapContractwMembers.containsKey(IdContrat)){
				for(cTin_ContractTeam__c meb : MapContractwMembers.get(IdContrat)){
					if(MapContractWUser.get(IdContrat) == meb.cTin_TeamMember__c) 
						ListMemberToDel.Add(meb) ; 
				} 
			}   
		}
          
        
        PAD.doNotExecuteAfterMe(setapexclass) ; 
		if(ListMemberToDel.size()>0){
			Delete ListMemberToDel; 
		} 
    }
}