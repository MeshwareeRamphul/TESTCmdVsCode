@isTest
private class AP45_ManageGroupMembers_TEST{
/* 
--------------------------------------------------------------------------------------
-- - Name          : AP45_ManageGroupMembers_TEST
-- - Author        : Spoon
-- - Description   : Test class for AP45_ManageGroupMembers
--
-- Maintenance History: 
--
-- Date         Name  Version  Remarks 
-- -----------  ----  -------  -------------------------------------------------------
-- 20-APR-2020  MRA    1.0     SP-00188 - Test class
---------------------------------------------------------*/
   static List<User> lstUser = new list<User>();
   static User testUser;
   
   static{
    testUser =TestFactory.createUser('Testuser1', UserInfo.getProfileId(), true);
    insert testUser;
    
    system.RunAs(testUser){
        lstUser.add(TestFactory.createUser('Testuser1', UserInfo.getProfileId(), true));
        lstUser.add(TestFactory.createUser('Testuser2', UserInfo.getProfileId(), true));
    }
   }

    @isTest
    static void addToGrp_Test(){
         system.RunAs(testUser){
             lstUser[0].cTin_Universign__c=true;
             lstUser[1].cTin_Universign__c=true;
             test.startTest();
                 insert lstUser;            
             test.stopTest();  
 
            // list<collaborationgroup> grp=[select id,name from collaborationgroup where name='USER GUIDE SHARING GROUP'];
             //List<CollaborationGroupMember> GMlist = [select id from CollaborationGroupMember 
                                                     //where CollaborationGroupId =: grp[0].Id
                                                    // and memberId IN: lstUser];
                                                    
         
          // system.assertEquals(2,GMlist.size());
        } 
         
    }


}