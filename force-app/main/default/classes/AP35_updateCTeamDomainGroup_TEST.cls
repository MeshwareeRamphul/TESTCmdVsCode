@isTest
private class AP35_updateCTeamDomainGroup_TEST {
/* 
----------------------------------------------------------------------
-- - Name          : AP35_updateCTeamDomainGroup_TEST
-- - Author        : Spoon Consulting
-- - Description   : Test Class for AP35_updateCTeamDomainGroup
-- Maintenance History:
--
-- Date         Name  Version  Remarks 
-- -----------  ----  -------  ---------------------------------------
-- 20-OCT-2017  HVA    1.0      Initial version                   
---------------------------------------------------------------------
**********************************************************************
*/

    static Profile profile;
    static User user;
    static Account acct;
    static List<Contract__c> lstContracts;

    static{

        List<Profile> profileList = [SELECT id FROM profile where NAME like '%sys%'];

        List<RecordType> lstRecordTypes = [SELECT Id,
                                                  developerName,
                                                  Name,
                                                  sObjectType
                                             FROM RecordType
                                            WHERE sObjectType = 'Contract__c'
                                              AND DeveloperName LIKE 'cTin_%'];

        if (profileList.size()>0) profile = profileList.get(0); 
        else throw new System.Nullpointerexception();

        user = TestFactory.createUser('Testing', profile.Id, true); 
        insert user;        

        System.runAs(user){

            acct = TestFactory.createSupplier('Test Supplier', 'Florange', 'France');
            insert acct;

            lstContracts = new List<Contract__c>{TestFactory.createcTinContracts('Test Contract1', acct.Id, lstRecordTypes[0].id),
                                                 TestFactory.createcTinContracts('Test Contract2', acct.Id, lstRecordTypes[0].id)};
            lstContracts[0].cTin_eSourcingReferenceId__c = 'WS111111111';
            lstContracts[0].cTin_SourcingDecision__c = 'RFx';
            lstContracts[0].cTin_sourcingDomain__c='General Expenses';
            lstContracts[0].cTin_OwnerEntityLocalCode__c='AIM';
            
            lstContracts[1].cTin_eSourcingReferenceId__c = 'WS111111111';
            lstContracts[1].cTin_SourcingDecision__c = 'RFx';
            lstContracts[1].cTin_sourcingDomain__c='IT & Contractors';
            lstContracts[1].cTin_OwnerEntityLocalCode__c='AIM';
        }
    }   

    static testmethod void test_addGroupOnInsert(){
        system.runAs(user){
            test.startTest();
                insert lstContracts;
            test.stopTest();

            list<cTin_contractTeam__c> cTeamLst=[SELECT id,
                                                   cTin_contract__c,
                                                   cTin_GroupMember__c,
                                                   cTin_contract__r.name
                                            FROM cTin_ContractTeam__c
                                            WHERE cTin_role__c=:'015'
                                              AND cTin_contract__c IN: lstContracts
                                            /*ORDER BY cTin_contract__r.name ASC*/];
            
            system.assertNotEquals(0, cTeamLst.size());
            
           /* system.assertEquals(lstContracts[0].id, cTeamLst[0].cTin_contract__c); 
            system.assertEquals('AIM Genex Procurement', cTeamLst[0].cTin_GroupMember__c); 

            system.assertEquals(lstContracts[1].id, cTeamLst[1].cTin_contract__c);  
            system.assertEquals('AIM IT Procurement', cTeamLst[1].cTin_GroupMember__c); */    
        }
    }

    static testmethod void test_addGroupOnUpdate(){
        system.runAs(user){
            insert lstContracts;
            list<contract__c> clist=[select id from contract__c where id IN:lstContracts];
            if(clist.size()>0){ 
                clist[0].cTin_sourcingDomain__c=null;
                clist[1].cTin_sourcingDomain__c='General Expenses';
            }
            test.startTest();
                update clist;
            test.stopTest();

            list<cTin_contractTeam__c> cTeamLst=[SELECT id,
                                                   cTin_contract__c,
                                                   cTin_GroupMember__c,
                                                   cTin_contract__r.name
                                            FROM cTin_ContractTeam__c
                                            WHERE cTin_role__c=:'015'
                                              AND cTin_contract__c IN: clist
                                            /*ORDER BY cTin_contract__r.name ASC*/];

            //system.assertEquals(2, cTeamLst.size());

           //system.assertEquals(lstContracts[1].id, cTeamLst[0].cTin_contract__c);  
           // system.assertNotEquals('', cTeamLst[0].cTin_GroupMember__c);  
                                            
        }
    }


}