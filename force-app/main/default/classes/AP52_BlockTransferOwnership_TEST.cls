@isTest
    public  class AP52_BlockTransferOwnership_TEST {
    /* 
    --------------------------------------------------------------------------------------
    -- - Name          : AP52_BlockTransferOwnership_TEST
    -- - Author        : Spoon
    -- - Description   : Test class for AP52_BlockTransferOwnership
    --
    -- Maintenance History: 
    --
    -- Date         Name  Version  Remarks 
    -- -----------  ----  -------  -------------------------------------------------------
    -- 15-JUN-2018  MRA    1.0     Initial version   (Evolution Case 4150 - Contract In)            
    *************************************************************************************/

    static User testUser;
    static list<User> usrList;
    static list <Contract__c> contractList;
    static list <cTin_ContractTeam__c> contractTeamList;
    static Group testGroup ;
    static id rtConDraftId;
    static list<User> cTeamUsersLst;
    static map<string,id>accRtNameRtIdMap;
    static Account acc;
	static Contact con;
    static list<Contract__Share>consharelst;
    static  GroupMember gm;

    static{
        List<Profile> profileList = [SELECT id FROM profile where NAME=:'cTin - Contract Buyer'];
        usrList=new list<User>{
            TestFactory.createUser('Admin', TestFactory.getProfileAdminId(),true),
            TestFactory.createUser('Buyer', profileList[0].id,true),
            TestFactory.createUser('AssignTo', TestFactory.getProfileAdminId(),true)
        };
        insert usrList;
        system.runAs(usrList[0]){
            
            acc = AP05_TestDataFactory.createLegalEntityAccount(usrList[0]);
            con = AP05_TestDataFactory.createEntityContact(acc);
            testGroup = new Group();
            testGroup.Name = 'testGroup';
            testGroup.DeveloperName = 'ABC';
            insert testGroup;

            gm= new GroupMember(UserOrGroupId=usrList[0].id,groupId=testGroup.id);
            insert gm;

        contractList=new list<Contract__c>{
                        TestFactory.createContract(acc.id,'Contract 1','Draft'), // buyer is co-owner
                        TestFactory.createContract(acc.id,'Contract 2','Draft'), //buyer is neither owner nor co-owner
                        TestFactory.createContract(acc.id,'Contract 3','Draft'), // buyer is owner
                        TestFactory.createContract(acc.id,'Contract 4','Draft')
                        }; //buyer is not part of group added as co-owner
        contractList[0].ownerId=usrList[0].id;
        contractList[1].ownerId=usrList[0].id;
        contractList[2].ownerId=usrList[0].id;
        contractList[3].ownerId=usrList[0].id;

        insert contractList;

        contractList[2].ownerId=usrList[1].id;
        update contractList[2];

        contractTeamList= new list<cTin_ContractTeam__c>{
                            TestFactory.createContractTeam(AP_Constant.contractTeamCoOwner, contractList[0].id,usrList[1].id, '', 'Not in Approval Process', 'Edit'), // buyer is co-owner
                            TestFactory.createContractTeam('014', contractList[1].id,usrList[1].id, '', 'Not in Approval Process', 'Edit'), //buyer is not co-owner
                            TestFactory.createContractTeam(AP_Constant.contractTeamCoOwner, contractList[3].id,null, 'testGroup', 'Not in Approval Process', 'Edit')}; //buyer is not part of group added as co-owner
        insert contractTeamList;
        }
    }

    static testMethod void test_blockTransferOwnership(){

        system.runAs(usrList[1]){
            contractList[0].ownerId=usrList[2].id;
            contractList[1].ownerId=usrList[2].id;
            contractList[2].ownerId=usrList[2].id;
            contractList[3].ownerId=usrList[2].id;

            test.startTest();
                try{update contractList;}
                catch(Exception e){}
            test.stopTest();
        }
    }
}