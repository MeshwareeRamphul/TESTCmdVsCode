public class AP46_RecalculateCTOrder{
/* 
  --------------------------------------------------------------------------------------
  -- - Name          :  AP46_RecalculateCTOrder
  -- - Author        : Spoon
  -- - Description   : Reset approval order of contract teams when the order of a member is modified
                       and update "approval section" on contract form when role/user/order changes on contract team
  --
  -- Maintenance History: 
  --
  -- Date         Name  Version  Remarks 
  -- -----------  ----  -------  -------------------------------------------------------
  -- 08-APR-2020  MRA    1.0     Initial version (Bundle 3.1 => SP-00190)
  *************************************************************************************/
    
    public static boolean hasrunOnce,hasRunResetOndel=false;
    
    public static void blockInsert(set<id>setConIds,list<cTin_ContractTeam__c>lstTeam, set<string>setOrder){
        system.debug('## blockInsert');
        list<cTin_ContractTeam__c>existingTeam=new list<cTin_ContractTeam__c>();
        
        for(cTin_ContractTeam__c cteam: [select id, cTin_Contract__c,cTin_ApprovalOrder__c,lastmodifieddate
                                              from cTin_ContractTeam__c 
                                              where cTin_Contract__c =: setConIds
                                              and cTin_ApprovalOrder__c=:setOrder
                                              ]){existingTeam.add(cteam);                            }
         
         if(existingTeam.size()>0)
         for(integer i=0;i<lstTeam.size();i++){lstTeam[i].addError('A team member is already defined with this approval order');}
    }
    
    //method automatically calculates approval order for each member when the approval order of one of the members is modified
    public static void resetOrder( id cteamid,string ctOrder,id ContractId,string oldOrder ){
        system.debug('## resetOrder');
        hasrunOnce=true;
        list<cTin_ContractTeam__c >lstcteamTbUpdt=new list<cTin_ContractTeam__c >();
        
        if(ctOrder!='Not in Approval Process'){
             for(cTin_ContractTeam__c cteam: [select id, cTin_Contract__c,cTin_ApprovalOrder__c,lastmodifieddate
                                              from cTin_ContractTeam__c 
                                              where cTin_Contract__c =: ContractId and 
                                              id <> :cteamid
                                              and cTin_ApprovalOrder__c=:ctOrder
                                              and cTin_ApprovalOrder__c <>: 'Not in Approval Process']){
               
                   cteam.cTin_ApprovalOrder__c=oldOrder;              
                   lstcteamTbUpdt.add(cteam);
               
            }
         }
         else{
             for(cTin_ContractTeam__c cteam: [select id, cTin_Contract__c,cTin_ApprovalOrder__c,lastmodifieddate
                                              from cTin_ContractTeam__c 
                                              where cTin_Contract__c =: ContractId and 
                                              id <> :cteamid
                                              and cTin_ApprovalOrder__c <>: 'Not in Approval Process'
                                              and cTin_ApprovalOrder__c >: oldOrder 
                                              order by cTin_ApprovalOrder__c asc ]){                                        
                  cteam.cTin_ApprovalOrder__c=string.valueOf(integer.valueOf(cteam.cTin_ApprovalOrder__c)-1);                              
                  lstcteamTbUpdt.add(cteam);           
            }
        
         } 
     
         if(lstcteamTbUpdt.size()>0){
            try{update lstcteamTbUpdt;  }
            catch (Exception e){ cTin_ContractTeam__c ct =new cTin_ContractTeam__c (id= cteamid);ct.addError(e.getmessage());}     
        }
        
     }
     
     //method resets order on delete of a contract team
     public static void resetOrderOnDel(id cteamId,Id conId, String teamOrder){
          system.debug('## resetOrderOnDel');
          system.debug('## teamOrder'+ teamOrder);
          hasRunResetOndel=true; //prevents after update triggers from executing resetOder method
          list<cTin_ContractTeam__c >cteamlst=new list<cTin_ContractTeam__c >();
          for(cTin_ContractTeam__c cteam: [select id, cTin_Contract__c,
                                           cTin_ApprovalOrder__c,
                                           lastmodifieddate
                                              from cTin_ContractTeam__c 
                                              where cTin_Contract__c =: conId
                                              and cTin_ApprovalOrder__c <>: 'Not in Approval Process'
                                              and cTin_ApprovalOrder__c >: teamOrder 
                                              order by cTin_ApprovalOrder__c asc ]){
                                              
                  system.debug('## cteam before loop'+cteam.cTin_ApprovalOrder__c);
                  
                 if(cteam.cTin_ApprovalOrder__c!='1')    {                                           
                     //orderSet.add(string.valueOf(integer.valueOf(cteam.cTin_ApprovalOrder__c)-1));  
                     cteam.cTin_ApprovalOrder__c= string.valueOf(integer.valueOf(cteam.cTin_ApprovalOrder__c)-1);     
                     system.debug('## cteam inside if '+cteam.cTin_ApprovalOrder__c);     
                 }                 
                 
                 cteamlst.add(cteam);
         }
         
         system.debug('## cteamlst '+ cteamlst.size());
          
         if (cteamlst.size()>0)
            update cteamlst;
     

     }
     
     public static void blockDeletion(list<cTin_ContractTeam__c > lstTeam){
         system.debug('## blockDeletion');
         list<cTin_ContractTeam__c > lstBlockDel=new list<cTin_ContractTeam__c >();
         lstBlockDel=[select id, cTin_Contract__r.status__c 
                                          from cTin_ContractTeam__c 
                                          where id IN:lstTeam
                                          and cTin_Contract__r.status__c<>'In Progress'
                                          and cTin_Contract__r.status__c<>'Draft'];
                                          
          system.debug('## lstBlockDel'+lstBlockDel);                                
          if( lstBlockDel.size()>0){
              for(integer i=0;i<lstTeam.size();i++){lstTeam[i].addError('You cannot delete a contract team involved in Contract Process after the Contract Form is Approved or pending for approval');         }
          }
                                         
     
     }
     
    @future
     public static void updateCf(set<id>conIdSet){
        system.debug('## updateCf'); 
        map<integer,cTin_ContractTeam__c  > mapOrderTeam=new map<integer,cTin_ContractTeam__c>();
        list<cTin_ContractTeam__c> cteamLst=new list<cTin_ContractTeam__c>();
        
        for(cTin_ContractTeam__c  cTeam: [select id, cTin_ApprovalOrder__c,cTin_Contract__c ,
                                          cTin_TeamMember__c,
                                          cTin_TeamMember__r.firstname,
                                          cTin_TeamMember__r.lastname,cTin_Role__c     
                                          from cTin_ContractTeam__c  
                                          where  cTin_Contract__c  IN:conIdSet
                                          and  cTin_ApprovalOrder__c <>: 'Not in Approval Process']){      
           cteamLst.add(cTeam);
           mapOrderTeam.put(integer.valueOf(cTeam.cTin_ApprovalOrder__c),cTeam);
           
       }
       
       list<cTin_ContractForm__c> cfList=[select cTin_ApproverName1__c, cTin_ApproverNameTxt1__c,cTin_ApproverRole1__c,
                                          cTin_ApproverName2__c, cTin_ApproverNameTxt2__c,cTin_ApproverRole2__c ,
                                          cTin_ApproverName3__c, cTin_ApproverNameTxt3__c,cTin_ApproverRole3__c ,
                                          cTin_ApproverName4__c, cTin_ApproverNameTxt4__c,cTin_ApproverRole4__c ,
                                          cTin_ApproverName5__c, cTin_ApproverNameTxt5__c,cTin_ApproverRole5__c ,
                                          cTin_ApproverName6__c, cTin_ApproverNameTxt6__c,cTin_ApproverRole6__c ,
                                          cTin_ApproverName7__c, cTin_ApproverNameTxt7__c,cTin_ApproverRole7__c ,
                                          cTin_ApproverName8__c, cTin_ApproverNameTxt8__c,cTin_ApproverRole8__c ,
                                          cTin_ApproverName9__c, cTin_ApproverNameTxt9__c,cTin_ApproverRole9__c ,
                                          cTin_ApproverName10__c, cTin_ApproverNameTxt10__c,cTin_ApproverRole10__c 
                                          from cTin_ContractForm__c where cTin_Contract__c IN:conIdSet];
          cfList[0].cTin_ApproverName1__c=null;
          cfList[0].cTin_ApproverName2__c=null;
          cfList[0].cTin_ApproverName3__c=null;
          cfList[0].cTin_ApproverName4__c=null;
          cfList[0].cTin_ApproverName5__c=null;
          cfList[0].cTin_ApproverName6__c=null;
          cfList[0].cTin_ApproverName7__c=null;
          cfList[0].cTin_ApproverName8__c=null;
          cfList[0].cTin_ApproverName9__c=null;
          cfList[0].cTin_ApproverName10__c=null;
          cfList[0].cTin_ApproverNameTxt1__c='';
          cfList[0].cTin_ApproverNameTxt2__c='';
          cfList[0].cTin_ApproverNameTxt3__c='';
          cfList[0].cTin_ApproverNameTxt4__c='';
          cfList[0].cTin_ApproverNameTxt5__c='';
          cfList[0].cTin_ApproverNameTxt6__c='';
          cfList[0].cTin_ApproverNameTxt7__c='';
          cfList[0].cTin_ApproverNameTxt8__c='';
          cfList[0].cTin_ApproverNameTxt9__c='';
          cfList[0].cTin_ApproverNameTxt10__c='';
          cfList[0].cTin_ApproverRole1__c='';
          cfList[0].cTin_ApproverRole2__c='';
          cfList[0].cTin_ApproverRole3__c='';
          cfList[0].cTin_ApproverRole4__c='';
          cfList[0].cTin_ApproverRole5__c='';
          cfList[0].cTin_ApproverRole6__c='';
          cfList[0].cTin_ApproverRole7__c='';
          cfList[0].cTin_ApproverRole8__c='';
          cfList[0].cTin_ApproverRole9__c='';
          cfList[0].cTin_ApproverRole10__c='';
          
         update cfList;                               
                                          
         for(integer i=1; i<=10; i++){
           if(mapOrderTeam.containsKey(i)){
               if (i==1){ 
                     cfList[0].cTin_ApproverName1__c= mapOrderTeam.get(i).cTin_TeamMember__c; 
                     cfList[0].cTin_ApproverNameTxt1__c= mapOrderTeam.get(i).cTin_TeamMember__r.FirstName + ' '+ mapOrderTeam.get(i).cTin_TeamMember__r.LastName;
                     cfList[0].cTin_ApproverRole1__c= mapOrderTeam.get(i).cTin_Role__c;
                }
                         
               if (i==2){ 
                   cfList[0].cTin_ApproverName2__c= mapOrderTeam.get(i).cTin_TeamMember__c; 
                   cfList[0].cTin_ApproverNameTxt2__c= mapOrderTeam.get(i).cTin_TeamMember__r.FirstName + ' '+ mapOrderTeam.get(i).cTin_TeamMember__r.LastName;
                   cfList[0].cTin_ApproverRole2__c= mapOrderTeam.get(i).cTin_Role__c;
               }
           
               if (i==3){
                 cfList[0].cTin_ApproverName3__c= mapOrderTeam.get(i).cTin_TeamMember__c; 
                 cfList[0].cTin_ApproverNameTxt3__c= mapOrderTeam.get(i).cTin_TeamMember__r.FirstName + ' '+ mapOrderTeam.get(i).cTin_TeamMember__r.LastName;
                 cfList[0].cTin_ApproverRole3__c= mapOrderTeam.get(i).cTin_Role__c;
               }
                         
               if (i==4) {
                   cfList[0].cTin_ApproverName4__c= mapOrderTeam.get(i).cTin_TeamMember__c; 
                   cfList[0].cTin_ApproverNameTxt4__c= mapOrderTeam.get(i).cTin_TeamMember__r.FirstName + ' '+ mapOrderTeam.get(i).cTin_TeamMember__r.LastName;
                   cfList[0].cTin_ApproverRole4__c= mapOrderTeam.get(i).cTin_Role__c;
               }
                         
               if (i==5) {
                   cfList[0].cTin_ApproverName5__c= mapOrderTeam.get(i).cTin_TeamMember__c; 
                   cfList[0].cTin_ApproverNameTxt5__c= mapOrderTeam.get(i).cTin_TeamMember__r.FirstName + ' '+ mapOrderTeam.get(i).cTin_TeamMember__r.LastName;
                   cfList[0].cTin_ApproverRole5__c= mapOrderTeam.get(i).cTin_Role__c;
               }
             
               if (i==6) {
                   cfList[0].cTin_ApproverName6__c= mapOrderTeam.get(i).cTin_TeamMember__c; 
                   cfList[0].cTin_ApproverNameTxt6__c= mapOrderTeam.get(i).cTin_TeamMember__r.FirstName + ' '+ mapOrderTeam.get(i).cTin_TeamMember__r.LastName;
                   cfList[0].cTin_ApproverRole6__c= mapOrderTeam.get(i).cTin_Role__c;
                }
                     
               if (i==7) {
                   cfList[0].cTin_ApproverName7__c= mapOrderTeam.get(i).cTin_TeamMember__c; 
                   cfList[0].cTin_ApproverNameTxt7__c= mapOrderTeam.get(i).cTin_TeamMember__r.FirstName + ' '+ mapOrderTeam.get(i).cTin_TeamMember__r.LastName;
                   cfList[0].cTin_ApproverRole7__c= mapOrderTeam.get(i).cTin_Role__c;
               }
                         
               if (i==8){ 
                       cfList[0].cTin_ApproverName8__c= mapOrderTeam.get(i).cTin_TeamMember__c; 
                       cfList[0].cTin_ApproverNameTxt8__c= mapOrderTeam.get(i).cTin_TeamMember__r.FirstName + ' '+ mapOrderTeam.get(i).cTin_TeamMember__r.LastName;
                       cfList[0].cTin_ApproverRole8__c= mapOrderTeam.get(i).cTin_Role__c;
               }
                         
               if (i==9) {
                   cfList[0].cTin_ApproverName9__c= mapOrderTeam.get(i).cTin_TeamMember__c; 
                   cfList[0].cTin_ApproverNameTxt9__c= mapOrderTeam.get(i).cTin_TeamMember__r.FirstName + ' '+ mapOrderTeam.get(i).cTin_TeamMember__r.LastName;
                   cfList[0].cTin_ApproverRole9__c= mapOrderTeam.get(i).cTin_Role__c;
               }
                         
               if (i==10){
                   cfList[0].cTin_ApproverName10__c= mapOrderTeam.get(i).cTin_TeamMember__c; 
                   cfList[0].cTin_ApproverNameTxt10__c= mapOrderTeam.get(i).cTin_TeamMember__r.FirstName + ' '+ mapOrderTeam.get(i).cTin_TeamMember__r.LastName;
                   cfList[0].cTin_ApproverRole10__c= mapOrderTeam.get(i).cTin_Role__c;
              }
           }        
         }  
         
        update cfList;                           
     
     }
     
     public static void deleteContractshare(map<id,id> mapOldUserIdCtr){
         system.debug('## deleteContractshare'); 
         List<Contract__Share> lstContractSharetbd=new   List<Contract__Share>();
          
         list<cTin_ContractTeam__c > cteamlst=[SELECT Id, Name, cTin_Active__c, cTin_Contract__c, cTin_TeamMember__c, cTin_ContractAccessLevel__c 
                                              FROM cTin_ContractTeam__c 
                                              WHERE cTin_TeamMember__c IN: mapOldUserIdCtr.keyset() 
                                              AND cTin_Contract__c IN: mapOldUserIdCtr.values()
                                              AND cTin_Active__c = true];
     
           //if no contract team exists for this user => delete contract share if any
          if(cteamlst.size()==0){
               lstContractSharetbd = [SELECT Id, ParentId, UserOrGroupId, AccessLevel FROM Contract__Share WHERE ParentId IN: mapOldUserIdCtr.values() and UserOrGroupId IN: mapOldUserIdCtr.keyset()];
               
               if(lstContractSharetbd.size()>0)delete lstContractSharetbd;
           }
    
    
    
     }
     
        
}