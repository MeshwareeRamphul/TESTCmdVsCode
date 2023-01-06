@isTest
private class CheckPassAXAAction_Test {
    
    Static User testUser;
    
    static void checkPassAxaTest(){
        
        testUser = TestFactory.createUser('UsrAdmin',TestFactory.getProfileAdminId(),true);
        testUser.FederationIdentifier = testUser.Email;
        testUser.Allow_Internet_Access__c = false;
        testUser.No_PassAXA__c = false;
        insert testUser;
        
    	System.runAs(testUser){  
            Test.startTest();
               	List<string> lstSession = CheckPassAXAAction.isValidAccess();
            Test.stopTest();
        	//	System.assertEquals(lstSession.size(),1);
          //  	System.assertEquals('Cannot delete account with related opportunities.',result.getErrors()[0].getMessage());
		}
    }
}