@isTest
public class ContractTriggerHandler_TEST {
    static List<Contract__c> lstContract =  new List<Contract__c>();
        static List<User> lstUser = new list<User>();
    
        static {
            for(integer i=1;i<=3;i++){
                lstUser.add(TestFactory.createUser('Testuser'+ i , UserInfo.getProfileId(), true));           
            }
            
            insert lstUser;

            lstUser[0].Bypass_FieldFilter__c=true;
            lstUser[0].PAD_BypassValidationRules__c = true;
            lstUser[0].PAD_BypassTrigger__c = 'AP40';
            lstUser[0].PAD_BypassTrigger__c = 'AP46';
            lstUser[0].PAD_BypassTrigger__c = 'AP37';
            lstUser[0].cTin_Entity__c='430 - AXA Belgium Corporate Legal';
            lstUser[0].cTin_EntityLocalCode__c='AIM';

            lstUser[1].Bypass_FieldFilter__c=true;
            lstUser[1].PAD_BypassValidationRules__c = true;
            lstUser[0].PAD_BypassTrigger__c = 'AP40';
            lstUser[0].PAD_BypassTrigger__c = 'AP46';
            lstUser[0].PAD_BypassTrigger__c = 'AP37';
            lstUser[1].cTin_Entity__c='600 - AXA XL';
            lstUser[1].cTin_EntityLocalCode__c='AXL';
            
            lstUser[2].Bypass_FieldFilter__c=true;
            lstUser[2].PAD_BypassValidationRules__c = true;
            lstUser[0].PAD_BypassTrigger__c = 'AP40';
            lstUser[0].PAD_BypassTrigger__c = 'AP46';
            lstUser[0].PAD_BypassTrigger__c = 'AP37';
            lstUser[2].cTin_Entity__c=' 1320 - AXA Switzerland';
            lstUser[2].cTin_EntityLocalCode__c='AIM';
            update lstUser;
    
            System.runAs(lstUser[0]){
    
                Account supplier = TestFactory.createSupplier('TestSupplier' , 'BillingCity', 'France');
                insert supplier;
    
                lstContract.add(TestFactory.createContract(supplier.Id, 'TestContract', 'Draft'));
                
                AP44_BlockNewContractTeam.bypassSpecial=true;
                
    
            }
    
        }

    @isTest
    Public static void  AddGroupDefaultAndSharingTest() {
        system.runAs(lstUser[0]){               
            test.startTest();
                 insert lstContract;
            test.stopTest();
        }
    }

    @isTest
    Public static void  OwnerEntityLocalCodeNotAimTest() {
        system.runAs(lstUser[0]){  
            insert lstContract;             
            test.startTest();                 
                 lstContract[0].ownerId = lstUser[1].id;
                 update lstContract;
            test.stopTest();
        }
    }

    @isTest
    Public static void  OwnerEntityLocalCodeAimTest() {
        system.runAs(lstUser[0]){  
            insert lstContract;             
            test.startTest();                 
                 lstContract[0].ownerId = lstUser[2].id;
                 update lstContract;
            test.stopTest();
            ContractTriggerHandler.dummmyTest();
        }
    }
}