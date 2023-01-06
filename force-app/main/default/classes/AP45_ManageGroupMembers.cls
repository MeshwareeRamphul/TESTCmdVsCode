public class AP45_ManageGroupMembers{
/* 
--------------------------------------------------------------------------------------
-- - Name          : AP45_ManageGroupMembers
-- - Author        : Spoon
-- - Description   : Add users to the chatter group when users are activated or created
--
-- Maintenance History: 
--
-- Date         Name  Version  Remarks 
-- -----------  ----  -------  -------------------------------------------------------
-- 07-APR-2020  MRA    1.0     Bundle 3.1 Ticket : SP-00188
                               User is deleted from chatter group "USER GUIDE SHARING GROUP" when deactivated or deleted => standard functionality
---------------------------------------------------------*/
    public static boolean bypassSpecial=false;
    @future
    public static void AddMembers(set<id> usrIdSet){
        system.debug('## starting AddMembers');
           CollaborationGroup newGroup;
             
           list<collaborationgroup> grp= new list<collaborationgroup>();
           list<collaborationgroup > testgrp= new list<collaborationgroup>();
           grp=[select id,name from collaborationgroup where name='USER GUIDE SHARING GROUP'];
           
           if (test.isRunningTest()){
               testgrp=[select id,name from collaborationgroup where name='USER GUIDE SHARING GROUP cTin'];
               if(testgrp.size()==0){
                   newGroup = new CollaborationGroup(Name='USER GUIDE SHARING GROUP cTin', CollaborationType='Public');
                   insert newGroup;
                   testgrp.add(newGroup);
               }
           }
           
          /* if (grp.size()==0) {
            CollaborationGroup newGroup = new CollaborationGroup(Name='USER GUIDE SHARING GROUP', CollaborationType='Public');
            insert newGroup;
            grp.add(newGroup );
           }
           */
        
        List<CollaborationGroupMember> GMlist = new List<CollaborationGroupMember>();
         
        for(Id usr : usrIdSet) {                 
                CollaborationGroupMember groupMember = new CollaborationGroupMember();
                groupMember.memberId =usr;
                if (!test.isRunningTest()) groupMember.CollaborationGroupId = grp[0].Id;
                else groupMember.CollaborationGroupId = testgrp[0].id;
                
                
                GMList.add(groupMember);                
        }
       
        
        if(GMList.size()>0)          
          database.insert(GMList,false);
    }

}