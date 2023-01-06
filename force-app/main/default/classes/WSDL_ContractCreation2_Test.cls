@isTest
public class WSDL_ContractCreation2_Test {
    static user testUser;
    static{
        testUser = TestFactory.createUser('UsrAdmin',TestFactory.getProfileAdminId(),true);
        insert testUser;
    }
	@isTest
    public static void test(){
        System.runAs(testUser) {
            test.StartTest();
            	WSDL_ContractCreation2 wsdl = new WSDL_ContractCreation2();
            test.StopTest();
        }
    }
}