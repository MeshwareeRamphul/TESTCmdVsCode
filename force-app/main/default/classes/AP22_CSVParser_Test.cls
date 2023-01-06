@isTest
private class AP22_CSVParser_Test {
/* 
--------------------------------------------------------------------------------------
-- - Name          : AP22_CSVParser_Test
-- - Author        : Spoon Consulting 
-- - Description   : test class for AP22_CSVParser
--
-- Maintenance History: 
--
-- Date         Name  Version  Remarks 
-- -----------  ----  -------  -------------------------------------------------------
-- 02-JUN-2017  MRA    1.0     Initial version
--------------------------------------------------------------------------------------*/
  static User testUser;
  static AP22_CSVParser csv1,csv2;
  static{
    testUser = TestFactory.createUser('UsrAdmin',TestFactory.getProfileAdminId(),true);
    insert testUser;  
  }


  static testMethod void parseCSV_test(){
  	 system.runAs(testUser){

  	 	test.startTest();
  	 	csv1=new AP22_CSVParser();
  	 	csv2=new AP22_CSVParser();
  	 	test.stopTest();

 		if(!csv1.hasHeader){ 
            csv1.writeHeader(new list<String>{'Id','Operation','Error'});
            csv1.addToLine('Id of record');
            csv1.addToLine('Deleting attachments');
            csv1.addToLine('Error');
            csv1.createLine();
            csv1.getBlobBody();      
        }

        system.assert(csv1.hasHeader,true);

        csv2.writeHeader(new list<String>());
        csv2.formatData(null);    
  	 }
  }


}