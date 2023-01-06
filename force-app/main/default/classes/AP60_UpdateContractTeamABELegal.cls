public without sharing class AP60_UpdateContractTeamABELegal {
/* 
--------------------------------------------------------------------------------------
-- - Name          : AP60_UpdateContractTeamABELegal
-- - Author        : Spoon Consulting 
-- - Description   : add/remove group ABE_CorporateLegal from contract team when owner local entity changes
--
-- Maintenance History: 
--
-- Date         Name  Version  Remarks 
-- -----------  ----  -------  -------------------------------------------------------
-- 02-JUN-2021  MRA    1.0     Initial version
************************************************************************************/
    
    //method adds/removes group to contract team after insert/after update of owner
    @future
    public static void addRemoveGroup(map<id,id>mapCtrOwnerId){
        map<id,id>mapctrcf=new map<id,id>();
        
        for(cTin_ContractForm__c cf:[select id,ctin_contract__c 
                                     from cTin_ContractForm__c 
                                     where ctin_contract__c IN: mapCtrOwnerId.keyset()]){
            mapctrcf.put(cf.ctin_contract__c,cf.id);
        }
        
        system.debug('## starting addRemoveGroup');
        list<cTin_ContractTeam__c> newcTeamlst=new list<cTin_ContractTeam__c>();
        list<cTin_ContractTeam__c> oldcTeamlst=new list<cTin_ContractTeam__c>();
        list<cTin_ContractTeam__c>allcTeamLstADE=new list<cTin_ContractTeam__c>();
        list<cTin_ContractTeam__c>allcTeamLstABCL=new list<cTin_ContractTeam__c>();
        set<id> ctrSetABCL=new set<id>();
        set<id> ctrSetNotABCL=new set<id>();
        set<id> cfSetNotABCL=new set<id>();
        set<id>usrABClSet=new set<id>();
        
        list<cTin_ContractTeam__c> newADEcTeamlst=new list<cTin_ContractTeam__c>();
        list<cTin_ContractTeam__c> oldADEcTeamlst=new list<cTin_ContractTeam__c>();
        list<cTin_ContractTeam__c>allADEcTeamLst=new list<cTin_ContractTeam__c>();
        set<id> ctrSetADE=new set<id>();
        
        set<id> ctrSetNotADE=new set<id>();
        set<id> cfSetNotADE=new set<id>();
        set<id>usrADESet=new set<id>();
        
        //02/03/2022 mra
        set<id>usrACHSet=new set<id>();
        set<id> ctrSetACH=new set<id>();
        set<id> ctrSetNotACH=new set<id>();
        set<id> cfSetNotACH=new set<id>();
        list<cTin_ContractTeam__c>allcTeamLstACHProcurementL=new list<cTin_ContractTeam__c>();
        
        for(user usr:[select id,cTin_EntityLocalCode__c 
                      from user 
                      where id IN:mapCtrOwnerId.values() ]){
             if(usr.cTin_EntityLocalCode__c=='ABCL')   
                    usrABClSet.add(usr.Id);
             if(usr.cTin_EntityLocalCode__c=='ADE')   
                  usrADESet.add(usr.Id);
                  
              if(usr.cTin_EntityLocalCode__c=='ACH')   
                  usrACHSet.add(usr.Id);
        }
        
        system.debug('## usrABClSet'+usrABClSet);
        system.debug('## usrADESet'+usrADESet);
        
        for(Contract__c ctr : [select ownerId,
                               owner.name,
                               id,
                               cTin_OwnerEntityLocalCode__c 
                               from Contract__c 
                               where id IN:mapCtrOwnerId.keyset()]){
                system.debug('## ctr.ownerId '+ctr.ownerId);
               
               if(usrABClSet.contains(ctr.ownerId)){
                    ctrSetABCL.add(ctr.Id);
                }
                else if(usrADESet.contains(ctr.ownerId)){
                    ctrSetADE.add(ctr.Id);
                }                
                else{
                    ctrSetNotABCL.add(ctr.Id);
                    cfSetNotABCL.add(mapctrcf.get(ctr.Id));
                    
                    //02/03/2022 mra
                    if(usrACHSet.contains(ctr.ownerId)){
                        ctrSetACH.add(ctr.Id);
                    }
                    else{
                        cfSetNotACH.add(mapctrcf.get(ctr.Id));
                        ctrSetNotACH.add(ctr.Id);
                    }
                }
         }
            
            system.debug('## ctrSetABCL'+ctrSetABCL);
            system.debug('## ctrSetNotABCL'+ctrSetNotABCL);
            
            
            for(cTin_ContractTeam__c cTeam:[SELECT id, cTin_contract__c, 
                                            cTin_GroupMember__c,
                                            cTin_role__c 
                                            FROM cTin_ContractTeam__c
                                            WHERE cTin_contract__c IN: mapCtrOwnerId.keyset() 
                                            AND (cTin_GroupMember__c = :'ACH Procurement' 
                                            OR cTin_GroupMember__c = 'ACH Audit & Legal')]){
                                           
                  if(cTeam.cTin_GroupMember__c == 'ACH Procurement' || cTeam.cTin_GroupMember__c=='ACH Audit & Legal')  
                      allcTeamLstACHProcurementL.add(cTeam);    
                                              
                  if(!ctrSetACH.contains(cTeam.cTin_contract__c) && ctrSetACH.size()!=0){
                           system.debug('## 1');
                           //create team 
                            cTin_ContractTeam__c teamCoOwnerACH =new cTin_ContractTeam__c(cTin_Role__c = '015',cTin_Contract__c = cTeam.cTin_contract__c,cTin_GroupMember__c = 'ACH Procurement', cTin_ContractAccessLevel__c = 'Edit');     
                                newcTeamlst.add(teamCoOwnerACH );
                                
                                //02/03/2022 MRA: Add ACH Audit & Legal as legal to contract team for ACH
                                
                                 cTin_ContractTeam__c teamACHLegal =  new cTin_ContractTeam__c(cTin_Role__c = '004',cTin_Contract__c = cTeam.cTin_contract__c,cTin_GroupMember__c = 'ACH Audit & Legal', cTin_ContractAccessLevel__c = 'Read');     
                                newcTeamlst.add(teamACHLegal);
                            
                  }   
                   //delete team   
                                      
                  if(ctrSetNotACH.contains(cTeam.cTin_contract__c)){ oldcTeamlst.add(cTeam); }        
                             
                                     
                                           
             }                              
            
            for(cTin_ContractTeam__c cTeam:[SELECT id, cTin_contract__c, 
                                           cTin_GroupMember__c,cTin_role__c 
                                           FROM cTin_ContractTeam__c
                                           WHERE cTin_contract__c IN: mapCtrOwnerId.keyset() 
                                           AND (cTin_GroupMember__c =: 'ABE_CorporateLegal' 
                                                or cTin_GroupMember__c =: 'G_CON_PRO_DE'/*cTin_role__c = :'016' OR cTin_Role__c = '015'*/)]){
              system.debug('## cTeam.cTin_contract__c'+cTeam.cTin_contract__c);
              if(/*cTeam.cTin_role__c == '015' */ cTeam.cTin_GroupMember__c =='G_CON_PRO_DE')
                  allcTeamLstADE.add(cTeam);  
              if(/*cTeam.cTin_role__c == '016' */ cTeam.cTin_GroupMember__c =='ABE_CorporateLegal')  
                  allcTeamLstABCL.add(cTeam);    
                                              
              if(!ctrSetABCL.contains(cTeam.cTin_contract__c) && ctrSetABCL.size()!=0){
                       system.debug('## 1');
                       //create team 
                        cTin_ContractTeam__c ctABCL =  new cTin_ContractTeam__c(cTin_Role__c = '016',cTin_Contract__c = cTeam.cTin_contract__c,cTin_GroupMember__c = 'ABE_CorporateLegal', cTin_ContractAccessLevel__c = 'Edit');
                        newcTeamlst.add(ctABCL);
              }
              
               if(!ctrSetADE.contains(cTeam.cTin_contract__c) 
                  && ctrSetADE.size()!=0){
                      system.debug('## 2');
                       //create team 
                      cTin_ContractTeam__c ctABCL =  new cTin_ContractTeam__c(cTin_Role__c = '015',cTin_Contract__c = cTeam.cTin_contract__c, cTin_GroupMember__c = 'G_CON_PRO_DE',cTin_ContractAccessLevel__c = 'Edit');
                      newcTeamlst.add(ctABCL);
              }
              
              
              if(ctrSetNotABCL.contains(cTeam.cTin_contract__c)){
                       //delete team   
                  oldcTeamlst.add(cTeam);                             
              }                                    
                                                   
            }
            
            
            //02/03/2022 mra
            if(ctrSetACH.size()>0 
               && allcTeamLstACHProcurementL.size()==0){
              system.debug('## 3445');
                for(id ctrId: ctrSetACH){
                     cTin_ContractTeam__c ctACHLegal =  new cTin_ContractTeam__c(cTin_Role__c = '004',cTin_Contract__c = ctrId, cTin_GroupMember__c = 'ACH Audit & Legal',cTin_ContractAccessLevel__c = 'Read');
                     newcTeamlst.add(ctACHLegal );
                     
                      cTin_ContractTeam__c ctACHProc =  new cTin_ContractTeam__c(cTin_Role__c = '015',cTin_Contract__c = ctrId, cTin_GroupMember__c = 'ACH Procurement',cTin_ContractAccessLevel__c = 'Edit');
                      newcTeamlst.add(ctACHProc );
                }
            }

            if(ctrSetABCL.size()>0 && allcTeamLstABCL.size()==0){
              system.debug('## 11');
                for(id ctrId: ctrSetABCL ){
                     cTin_ContractTeam__c ctABCL =  new cTin_ContractTeam__c(cTin_Role__c = '016',
                                                                             cTin_Contract__c = ctrId, 
                                                                             cTin_GroupMember__c = 'ABE_CorporateLegal',
                                                                             cTin_ContractAccessLevel__c = 'Edit');
                    newcTeamlst.add(ctABCL);
                }
            }
            
            
            
            if(ctrSetABCL.size()>0 && allcTeamLstADE.size()!=0){               
                  //delete ADE team
                  oldcTeamlst.addAll(allcTeamLstADE);
                
            }
            
            if(ctrSetADE.size()>0 && allcTeamLstABCL.size()!=0){
                   //delete ABCL team
                   oldcTeamlst.addAll(allcTeamLstABCL);
               
            }
            
            if(ctrSetADE.size()>0  && allcTeamLstADE.size()==0){
             system.debug('## 12');
                for(id ctrId: ctrSetADE ){
                     cTin_ContractTeam__c ctADE =  new cTin_ContractTeam__c(cTin_Role__c = '015',cTin_Contract__c = ctrId, cTin_GroupMember__c = 'G_CON_PRO_DE',cTin_ContractAccessLevel__c = 'Edit');
                    newcTeamlst.add(ctADE);
                }
            }
            
            if(newcTeamlst.size()>0) {
                try{
                    insert newcTeamlst;
                   } 
                catch(Exception e){system.debug('## exception'+e.getMessage()); }
   
            }
            
            if(oldcTeamlst.size()>0)
                delete oldcTeamlst;
            
            
            list<group>grpABE= [select id 
                                from group 
                                where name=:'ABE_CorporateLegal' 
                                OR name=:'G_CON_PRO_DE' ];
           // list<group>grpADE= [select id from group where name=:'G_CON_PRO_DE'];
            
            
            //delete sharing if there are contract teams to be deleted 
            if(ctrSetNotABCL.size()>0){
                //delete share on contract
                list<Contract__Share> ctrSharelst=[select id 
                                                   from Contract__Share 
                                                   where ParentId IN:ctrSetNotABCL
                                                   and UserOrGroupId =:grpABE[0].Id
                                                   /*or UserOrGroupId =:grpADE[0].Id*/];
                if(ctrSharelst.size()>0)
                    delete ctrSharelst;
                
                list<cTin_Contractform__Share> cfSharelst=[select id 
                                                           from cTin_Contractform__Share 
                                                           where ParentId IN:cfSetNotABCL
                                                   and UserOrGroupId =:grpABE[0].Id
                                                  /* or UserOrGroupId =:grpADE[0].Id*/];
                if(cfSharelst.size()>0)
                    delete cfSharelst;
                //delete share on contract form
            }
            
            //delete sharing ACH
            if(ctrSetNotABCL.size()>0){
                list<group>grpACH= [select id 
                                    from group 
                                    where name=:'ACH Audit & Legal' 
                                    OR name=:'ACH Procurement' ];
                list<Contract__Share> ctrSharelst=[select id 
                                                   from Contract__Share 
                                                   where ParentId IN:ctrSetNotACH
                                                   and UserOrGroupId IN:grpACH];
                list<cTin_Contractform__Share> cfSharelst=[select id 
                                                           from cTin_Contractform__Share 
                                                           where ParentId IN:cfSetNotACH
                                                   and UserOrGroupId IN:grpACH ];
               if(ctrSharelst.size()>0)try{delete ctrSharelst;} catch(exception e){system.debug('## exception deleting ctr share' + e.getMessage());}
                if(cfSharelst.size()>0)try{ delete cfSharelst;} catch(exception e){system.debug('## exception deleting cf share' + e.getMessage());}                                                                      
                                                   
            }
        
       
    }
    
 
}