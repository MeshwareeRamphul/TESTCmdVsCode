@isTest
private class VFC22_SetStatus_Test
/* 
--------------------------------------------------------------------------------------
-- - Name          : VFC22_SetStatus_Test
-- - Author        : Spoon Consulting 
-- - Description   : test class for VFC22_SetStatus
--
-- Maintenance History: 
--
-- Date         Name      Version  Remarks 
-- -----------  ----      -------  -------------------------------------------------------
-- 07-JUN-2017  DMU/MRA    1.0     Initial version
-- 17-AUG-2018  USA        1.1     Universign V2
--------------------------------------------------------------------------------------*/
{   
    static User testUser;
    static list<Esignature__c> esignatureLst=new list<Esignature__c>();
    static list<Contract__c> contractLst=new list<Contract__c>();
    static list<Account>supplierLst=new list<Account>();
    static list<Esignatory__c> esignatoryLst=new list<Esignatory__c>();
    static list<Contact> contactLst=new list<Contact>();

    static {
        testUser = TestFactory.createUser('testUsr',TestFactory.getProfileAdminId(), true);
        testUser.PAD_BypassValidationRules__c = true;
        testUser.cTin_Universign__c = true;
        insert testUser;

        System.runAs(testUser){
            Account supplier1 = TestFactory.createSupplier('supplier 1','Paris','France');
            Account supplier2 = TestFactory.createSupplier('supplier 2','Paris','France');
            supplierLst.add(supplier1);
            supplierLst.add(supplier2);
            insert supplierLst;

            Contact con1=TestFactory.createContact(supplier1,'James','Brown');
            Contact con2=TestFactory.createContact(supplier1,'Jim','Brown');
            Contact con3=TestFactory.createContact(supplier1,'Kate','Brown');
            Contact con4=TestFactory.createContact(supplier1,'Kim','Brown');
            Contact con5=TestFactory.createContact(supplier1,'Tom','cat');
            Contact con6=TestFactory.createContact(supplier1,'Jerry','Mouse');
            contactLst.add(con1);
            contactLst.add(con2);
            contactLst.add(con3);
            contactLst.add(con4);
            contactLst.add(con5);
            contactLst.add(con6);
            insert contactLst;

            contract__c contract1 = TestFactory.createContract(supplier1.Id,'Contract1',AP_Constant.contractCustValidationStatus); 
            contract__c contract2 = TestFactory.createContract(supplier2.Id,'Contract2',AP_Constant.contractCustValidationStatus);
            contract__c contract3 = TestFactory.createContract(supplier2.Id,'Contract3',AP_Constant.contractCustValidationStatus);
            contract3.recordtypeId=Schema.SObjectType.Contract__c.getRecordTypeInfosByName().get('Contract In Progress').getRecordTypeId();
            contractLst.add(contract1);  
            contractLst.add(contract2);
            contractLst.add(contract3);               
            insert contractLst;

            Esignature__c esignature1=TestFactory.createEsignature(contractLst[0],'esign1', AP_Constant.eSignatureCreatedStatus);
            Esignature__c esignature2=TestFactory.createEsignature(contractLst[1],'esign2', AP_Constant.eSignatureCreatedStatus);
            Esignature__c esignature3=TestFactory.createEsignature(contractLst[2],'esign3', AP_Constant.eSignatureCreatedStatus);
            esignatureLst.add(esignature1);
            esignatureLst.add(esignature2);
            esignatureLst.add(esignature3);
            insert esignatureLst;

            esignatureLst[0].ExternalId__c = '85e49c20-446f-31e7-bd7f-005ca37beeef';
            esignatureLst[2].ExternalId__c = '85e49c20-446f-31e7-bd7f-005ca37beeed';
            //esignatureLst[2].recordtypeId = Schema.SObjectType.Esignature__c.getRecordTypeInfosByName().get('cTin_Draft').getRecordTypeId();
            update esignatureLst;

            Esignatory__c esignatory1= TestFactory.createEsignatory(contractLst[0], esignatureLst[0],'James',contactLst[0].id,AP_Constant.esignatoryStatusNotStarted);
            Esignatory__c esignatory2= TestFactory.createEsignatory(contractLst[0], esignatureLst[0],'Jim',contactLst[1].id,AP_Constant.esignatoryStatusNotStarted);
            Esignatory__c esignatory3= TestFactory.createEsignatory(contractLst[1], esignatureLst[1],'Kate',contactLst[2].id,AP_Constant.esignatoryStatusNotStarted);
            Esignatory__c esignatory4= TestFactory.createEsignatory(contractLst[1], esignatureLst[1],'Kim',contactLst[3].id,AP_Constant.esignatoryStatusNotStarted);
            Esignatory__c esignatory5= TestFactory.createEsignatory(contractLst[2], esignatureLst[2],'Kate',contactLst[4].id,AP_Constant.esignatoryStatusNotStarted);
            Esignatory__c esignatory6= TestFactory.createEsignatory(contractLst[2], esignatureLst[2],'Kim',contactLst[5].id,AP_Constant.esignatoryStatusNotStarted);
            
            esignatory1.mobileTxt__c='515655346';
            esignatory2.mobileTxt__c='512655646';
            esignatory3.mobileTxt__c='515657646';
            esignatory4.mobileTxt__c='515678646';
            esignatory5.mobileTxt__c='515657646';
            esignatory6.mobileTxt__c='515678646';
            esignatoryLst.add(esignatory1);
            esignatoryLst.add(esignatory2);
            esignatoryLst.add(esignatory3);
            esignatoryLst.add(esignatory4);
            esignatoryLst.add(esignatory5);
            esignatoryLst.add(esignatory6);
            insert esignatoryLst;   

            esignatureLst[2].recordtypeId = Schema.SObjectType.Esignature__c.getRecordTypeInfosByName().get('cTin_Draft').getRecordTypeId();
            update esignatureLst;
        }
    }

    //check if status of both esignatories is updated to signed
    static testMethod void testSetStatus() {       
        System.runAs(testUser){  
            PageReference pageRef1 = Page.VFP22_SetStatus;            
            pageRef1.getParameters().put('id', '85e49c20-446f-31e7-bd7f-005ca37beeef');
            pageRef1.getParameters().put('status', '2');
            pageRef1.getParameters().put('signer', '1');
            Test.setCurrentPage(pageRef1);
            Test.startTest();                    
                VFC22_SetStatus controller = new VFC22_SetStatus();    
                controller.processEsgt();            
            Test.stopTest(); 

            list<Esignatory__c>esignatories=[select id,status__c 
                                             from esignatory__c 
                                             where id IN:esignatoryLst and status__c=:AP_Constant.esignatoryStatusSigned];
            system.assertEquals(2,esignatories.size());
        }
    }
   //check if status of both esignatories is updated to cancelled
    static testMethod void testSetStatus1() {       
        System.runAs(testUser){  
            PageReference pageRef1 = Page.VFP22_SetStatus;            
            pageRef1.getParameters().put('id', '85e49c20-446f-31e7-bd7f-005ca37beeef');
            pageRef1.getParameters().put('status', '1');
            pageRef1.getParameters().put('signer', '1');
            Test.setCurrentPage(pageRef1);
            Test.startTest();                              
                VFC22_SetStatus controller = new VFC22_SetStatus();    
                controller.processEsgt();                            
            Test.stopTest();

            list<Esignatory__c>esignatories=[select id,status__c 
                                             from esignatory__c 
                                             where id IN:esignatoryLst and status__c=:AP_Constant.esignatoryStatusCancelled];
            //system.assertEquals(2,esignatories.size());                      
        }
    }
    
    //check if status of esignatories is updated to cancelled
    static testMethod void testSetStatus0() {      
        System.runAs(testUser){ 

            esignatoryLst[0].Order__c=1;
            esignatoryLst[1].Order__c=2;
            esignatoryLst[2].Order__c=1;
            esignatoryLst[3].Order__c=2;

            esignatoryLst[4].Order__c=1;
            esignatoryLst[5].Order__c=2;

            update esignatoryLst;
            for(Esignatory__c esign : [select id,name,status__c, Order__c from esignatory__c]){
                system.debug('##name0 : '+esign.name+'***'+ + esign.Order__c);

            }
            PageReference pageRef1 = Page.VFP22_SetStatus;            
            pageRef1.getParameters().put('id', '85e49c20-446f-31e7-bd7f-005ca37beeef');
            pageRef1.getParameters().put('status', '0');
            pageRef1.getParameters().put('signer', '1');
            Test.setCurrentPage(pageRef1);
            Test.startTest();                            
                VFC22_SetStatus controller = new VFC22_SetStatus();    
                controller.processEsgt();                            
            Test.stopTest();
            list<Esignatory__c>esignatories=[select id,status__c 
                                             from esignatory__c 
                                             where id IN:esignatoryLst and status__c=:AP_Constant.esignatoryStatusCancelled];
            system.assertEquals(0,esignatories.size());                           
        }
    }
    //check if error is generated when no param is passed in callback url
    static testMethod void testSetStatusNoParam() {       
        System.runAs(testUser){ 
            PageReference pageRef = Page.VFP22_SetStatus;                       
            Test.setCurrentPage(pageRef);
            VFC22_SetStatus controller;
            Test.startTest();                              
                controller = new VFC22_SetStatus();    
                controller.processEsgt();                            
            Test.stopTest();  
            system.assert(controller.msgDisplay.contains('ERROR'));                   
        }
    }

    //coverage for catch block
    static testMethod void testSetStatusErrorWithParams() {        
        System.runAs(testUser){  
            PageReference pageRef1 = Page.VFP22_SetStatus;            
            pageRef1.getParameters().put('id', '85e49c20-446f-31e7-bd7f-005ca37beeef');
            pageRef1.getParameters().put('status', '1');
            pageRef1.getParameters().put('signer', '1');
            Test.setCurrentPage(pageRef1);
            Test.startTest();                              
                VFC22_SetStatus controller = new VFC22_SetStatus();
                VFC22_SetStatus.testError=true;    
                controller.processEsgt();                            
            Test.stopTest();
            system.assert(controller.msgDisplay.contains('ERROR'));                                       
        }
    }

    static testMethod void testSetStatus3() {    
        System.runAs(testUser){  
            
            esignatoryLst[0].Order__c=1;
            esignatoryLst[1].Order__c=2;
            esignatoryLst[2].Order__c=1;
            esignatoryLst[3].Order__c=2;

            esignatoryLst[4].Order__c=1;
            esignatoryLst[5].Order__c=2;

            update esignatoryLst;

            PageReference pageRef1 = Page.VFP22_SetStatus;            
            pageRef1.getParameters().put('id', '85e49c20-446f-31e7-bd7f-005ca37beeef');
            pageRef1.getParameters().put('status', '3');
            pageRef1.getParameters().put('signer', '1');
            Test.setCurrentPage(pageRef1);
            Test.startTest();                              
                VFC22_SetStatus controller = new VFC22_SetStatus();
                VFC22_SetStatus.testError=true;    
                controller.processEsgt();                            
            Test.stopTest();
            system.assert(controller.msgDisplay.contains('ERROR'));                                       
        }
    }

    static testMethod void testSetStatus3a() {    
        System.runAs(testUser){  
            
            esignatoryLst[0].Order__c=1;
            esignatoryLst[0].cTin_Role__c = 'Validator';
            esignatoryLst[1].Order__c=2;
            esignatoryLst[1].cTin_Role__c = 'Validator';

            update esignatoryLst;

            PageReference pageRef1 = Page.VFP22_SetStatus;            
            pageRef1.getParameters().put('id', '85e49c20-446f-31e7-bd7f-005ca37beeef');
            pageRef1.getParameters().put('status', '3');
            pageRef1.getParameters().put('signer', '1');
            Test.setCurrentPage(pageRef1);
            Test.startTest();                              
                VFC22_SetStatus controller = new VFC22_SetStatus();
                VFC22_SetStatus.testError=true;    
                controller.processEsgt();                            
            Test.stopTest();                                      
        }
    }
    //check if status of both esignatories is updated to cancelled
     static testMethod void testSetStatus3b() {       
         System.runAs(testUser){  
             PageReference pageRef1 = Page.VFP22_SetStatus;            
             pageRef1.getParameters().put('id', '85e49c20-446f-31e7-bd7f-005ca37beeed');
             pageRef1.getParameters().put('status', '3');
             pageRef1.getParameters().put('signer', '1');
             Test.setCurrentPage(pageRef1);
             Test.startTest();                              
                 VFC22_SetStatus controller = new VFC22_SetStatus();    
                 controller.processEsgt();                            
             Test.stopTest();
 
             list<Esignatory__c>esignatories=[select id,status__c 
                                              from esignatory__c 
                                              where id IN:esignatoryLst and status__c=:AP_Constant.esignatoryStatusCancelled];
             //system.assertEquals(2,esignatories.size());                      
         }
     }
     //check if status of both esignatories is updated to cancelled
    static testMethod void testSetStatus3c() {       
        System.runAs(testUser){  
            esignatoryLst[4].Order__c=1;
            esignatoryLst[5].Order__c=2;

            update esignatoryLst;
            for(Esignatory__c esign : [select id,name,status__c, Order__c from esignatory__c]){
                system.debug('##name1 : '+esign.name+'***'+ + esign.Order__c);

            }

            PageReference pageRef1 = Page.VFP22_SetStatus;            
            pageRef1.getParameters().put('id', '85e49c20-446f-31e7-bd7f-005ca37beeed');
            pageRef1.getParameters().put('status', '3');
            pageRef1.getParameters().put('signer', '1');
            Test.setCurrentPage(pageRef1);
            Test.startTest();                              
                VFC22_SetStatus controller = new VFC22_SetStatus();    
                controller.processEsgt();                            
            Test.stopTest();

            list<Esignatory__c>esignatories=[select id,status__c 
                                            from esignatory__c 
                                            where id IN:esignatoryLst and status__c=:AP_Constant.esignatoryStatusCancelled];
                //system.assertEquals(2,esignatories.size());                      
        }
    }
}