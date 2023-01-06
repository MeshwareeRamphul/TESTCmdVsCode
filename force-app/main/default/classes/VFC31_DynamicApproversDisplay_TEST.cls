@isTest
/** 
 * This test class tests Controller VF_DynamicApproversDisplay
 * Created by: Zohar Sinay
 * Date: 6/11/2014
 */
public class VFC31_DynamicApproversDisplay_TEST {
/* 
--------------------------------------------------------------------------------------
-- - Name          : VFC31_DynamicApproversDisplay_TEST
-- - Author        : Zohar Sinay
-- - Description   : Test class for VFC31_DynamicApproversDisplay
--
-- Maintenance History: 
--
-- Date         Name  Version  Remarks 
-- -----------  ----  -------  -------------------------------------------------------
-- 6/11/2014    ZSI    1.0     Initial version
-- 23-OCT-2017  HVA    1.1     Reworked - All In merge contract In
*************************************************************************************/

    static Profile profile;
    static User user;
    static Account supplier;
    static Contract__c contract;
    static Group grp; 
    static cTin_ContractTeam__c contractTeam;

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
        user.PAD_BypassWorkflows__c =true;
        insert user;    

        System.runAs(user){
            supplier = TestFactory.createSupplier('Test Supplier', 'Florange', 'France');
            insert supplier;

            contract = TestFactory.createcTinContracts('Test Contract', supplier.Id, lstRecordTypes[0].id);
            insert contract;
            contract.OwnerId = UserInfo.getUserId();
            update contract;

            grp = new Group(Name = 'grp', DeveloperName = 'ABC');
            Insert grp;
            
            AP44_BlockNewContractTeam.bypassSpecial=true;
            
            contractTeam = TestFactory.createContractTeamMember('Buyer/Sourcing Expert', contract.Id, user.Id, '1', 'Read');
            insert contractTeam;
        }
    }

    static testMethod void test_VFC31_DynamicApproversDisplay(){

        System.runAs(user){
            cTin_ContractForm__c cf = [SELECT Id FROM cTin_ContractForm__c WHERE cTin_Contract__c = :contract.Id];
            PageReference pageRef = Page.VFP31_DynamicApproversDisplay;
            Test.setCurrentPage(PageRef);
            ApexPages.currentPage().getParameters().put('id', cf.Id);
            VFC31_DynamicApproversDisplay mr_Ctrl = new VFC31_DynamicApproversDisplay(new ApexPages.StandardController(cf));
        }
    }
}