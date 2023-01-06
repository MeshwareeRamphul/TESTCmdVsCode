/**
 * @File Name          : AP28_CreateCtrfromOpp_TEST.cls
 * @Description        : 
 * @Author             : SGO
 * @Group              : 
 * @Last Modified By   : SGO
 * @Last Modified On   : 8/19/2019, 11:58:25 AM
 * @Modification Log   : 
 *==============================================================================
 * Ver         Date                     Author      		      Modification
 *==============================================================================
 * 1.0    15/08/2019, 15:51:18            SGO                    Initial Version
 * 2.0    26/08/2019,                     SGO                     Error coverage
 * 1.3    02/09/2019                      SGO                   Test class pour les exceptions
 * 1.4    04/09/2019                      SGO                   Exception Coverage Removed
**/
@isTest
public with sharing class AP28_CreateCtrfromOpp_TEST {
    static user testUser;
    static user testUserNoCompany;

    static User vUserOO;
    static Account vAccount;
    static  Account vEAccount;
    static Contact vEntityContact;
    static Product__c vProduct;
    static Product__c vProduct2;
    static Opp_ProductItem__c vProdItem;

    static opportunity vOpp2;
    static opportunity vOpp3;
    static opportunity vOpp4;
    static opportunity vOpp5;

    static list<Opportunity> lstOpp = new List<Opportunity>();
    static list<Opportunity> lstUpdatedOpps = new list<Opportunity>();

    static list<Opportunity> lstOpps = new List<Opportunity>();
    //static list<Opportunity> lstFailedOpps = new List<Opportunity>();
    
    static list<Contract__c> lstCtrs = new List<Contract__c>();

    static List<Opp_ProductItem__c> lstOppPrItems = new List<Opp_ProductItem__c>();
    static list<ProductItem__c> lstCtrPrItems = new List<ProductItem__c>();

    static List<Local_information__c> lstLocalInfo = new List<Local_information__c>();
    static List<Local_information__c> lstUpdLI = new List<Local_information__c>();

    static RecordType rt;

    static{
        
        testUser = TestFactory.createUserLightning('UsrAdmin',TestFactory.getProfileAdminId(),true,AP_Constant.GS_ENTITY_AXA_GR_OP_HK);
        insert testUser;
        system.runAs(testUser){
            // Create OO user
            vUserOO = AP05_TestDataFactory.createOOUser();
            //vUserPMOADV = AP05_TestDataFactory.createPMOADVUser();

            // Create the legal entity (aka billing entity) account
            vAccount = AP05_TestDataFactory.createLegalEntityAccount(testUser);
            //System.debug('@@ vAccount: ' + vAccount);

            // Create the entity account
            vEAccount = AP05_TestDataFactory.createEntityAccount(testUser);
            //System.debug('@@ vEAccount: ' + vEAccount);

            // Create the couple Entity - Billing Entity on Parent Entity
            vAccount = AP05_TestDataFactory.linkLEgalEntityToEntity(vEAccount, vAccount);
            //System.debug('@@ vAccount: ' + vAccount);

            // Create the entity contact related to the account
            vEntityContact = AP05_TestDataFactory.createEntityContact(vAccount);
            //System.debug('@@ vEntityContact: ' + vEntityContact);
            
            //Quartile (business area)
            /*vQuartile = AP05_TestDataFactory.createBusinessArea(testUser);

            //Petal (Domain)
            vDomain = AP05_TestDataFactory.createDomain(vQuartile, testUser);

            //Offer
            vOffer = AP05_TestDataFactory.createOffer(vDomain, testUser);*/
            
            //Products ''Create 2 products due to AP50 trigger
            vProduct = AP05_TestDataFactory.createProduct(/*vOffer,*/ vUserOO);
            vProduct2 = AP05_TestDataFactory.createProduct(/*vOffer,*/ vUserOO, AP_Constant.PRODUCT_STATUS_IDEA, 'TestProduct2');

            rt = [select Id,name from RecordType where SObjectType='Opportunity' and DeveloperName= :AP_Constant.RT_OPP_LIGHTNING_FULL ]; 

            //Create opportunities
            vOpp2 = new Opportunity();
            vOpp2.RecordTypeId = rt.Id;
            vOpp2.AccountId = vEAccount.Id;
            vOpp2.StageName = AP_Constant.STAGE_LEADS_GATHERING;
            vOpp2.closeDate = Datetime.now().date();
            vOpp2.Amount = 123.45;
            vOpp2.Name = 'OptyProject';
            vOpp2.Category__c = Label.OptyCategory_Project;
            vOpp2.AXA_GO_Entity__c = AP_Constant.GS_ENTITY_AXA_GR_OP_HK; //override required docs, use HK
            lstOpp.add(vOpp2);

            vOpp3 = new Opportunity();
            vOpp3.RecordTypeId = rt.Id;
            vOpp3.AccountId = vEAccount.Id;
            vOpp3.StageName = AP_Constant.STAGE_LEADS_GATHERING;
            vOpp3.closeDate = Datetime.now().date();
            vOpp3.Amount = 0;
            vOpp3.Name = 'OptyBAU';
            vOpp3.Category__c = label.OptyCategory_BAU;
            vOpp3.AXA_GO_Entity__c = AP_Constant.GS_ENTITY_AXA_GR_OP_HK;
            lstOpp.add(vOpp3);

            vOpp5 = new Opportunity();
            vOpp5.RecordTypeId = rt.Id;
            vOpp5.AccountId = vEAccount.Id;
            vOpp5.StageName = AP_Constant.STAGE_LEADS_GATHERING;
            vOpp5.closeDate = Datetime.now().date();
            //vOpp5.Amount = 0; //null amount to be set 0 in class
            vOpp5.Name = 'OptyNoAmount';
            vOpp5.Category__c = label.OptyCategory_BAU;
            vOpp5.AXA_GO_Entity__c = AP_Constant.GS_ENTITY_AXA_GR_OP_HK;
            lstOpp.add(vOpp5);

            System.debug('@@ ##AP28## before insert lstOpp: ' + lstOpp);
            insert lstOpp;
            System.debug('@@ ##AP28## before insert lstOpp: ' + lstOpp.size());

            // vOpp4 = new Opportunity();
            // vOpp4.RecordTypeId = rt.Id;
            // vOpp4.AccountId = vEAccount.Id;
            // vOpp4.StageName = AP_Constant.STAGE_LEADS_GATHERING;
            // vOpp4.closeDate = Datetime.now().date();
            // //vOpp4.Amount = 0; //amount is null so as to be set 0 by else cond in class
            // vOpp4.Name = 'OptyFailedCtrItem';
            // vOpp4.Category__c = label.OptyCategory_BAU;
            // vOpp4.AXA_GO_Entity__c = AP_Constant.GS_ENTITY_AXA_GR_OP_HK;
            // lstFailedOpps.add(vOpp4);
            
            // System.debug('@@ vOpp4 Failed one: ' + vOpp4);

            // vOpp5 = new Opportunity();
            // vOpp5.RecordTypeId = rt.Id;
            // vOpp5.AccountId = vEAccount.Id;
            // vOpp5.StageName = AP_Constant.STAGE_LEADS_GATHERING;
            // vOpp5.closeDate = Datetime.now().date();
            // vOpp5.Amount = 0; 
            // vOpp5.Name = 'OptyFailedCtr';
            // vOpp5.Category__c = label.OptyCategory_BAU;
            // vOpp5.AXA_GO_Entity__c = AP_Constant.GS_ENTITY_AXA_GR_OP_HK;
            // lstFailedOpps.add(vOpp5);

            // System.debug('@@ ##AP28## before insert lstFailedOpps: ' + lstFailedOpps);
            // insert lstFailedOpps;
            // System.debug('@@ ##AP28## before insert lstFailedOpps: ' + lstFailedOpps.size());
        }

    }

    @isTest
    public static void testCreateCtrFromOpp(){
        system.runAs(testUser){
            test.StartTest();
                Map<Id, Opportunity> mapOppToCreateCtr = new Map<Id, Opportunity>();
                for (Opportunity theOpp:lstOpp){
                    
                    theOpp.Answer_due_date__c = Datetime.now().date();
                    theOpp.Entity_contact__c=vEntityContact.Id;

                    //theOpp.StageName = AP_Constant.STAGE_QUALIFY_ALIGN;

                    theOpp.Answer_cinematic__c = AP_Constant.ANS_CINE_BUS_CASE ;
                    theOpp.Project_start_Date__c =Datetime.now().date();
                    theOpp.Answer_sent_date__c=Datetime.now().date();
                    theOpp.Go_live_date__c=Datetime.now().date();

                    //add opp product item
                    vProdItem = AP05_TestDataFactory.createProdItems(/*vOffer,*/ testUser, vProduct, theOpp);
                    
                    //theOpp.StageName = AP_Constant.STAGE_CONTRACTING;
                    lstUpdatedOpps.add(theOpp);
                }

                System.debug('@@ before update lstUpdatedOpps:' + lstUpdatedOpps);
                update lstUpdatedOpps;
                //list of opps
                lstOpps=[SELECT Id, name, amount FROM Opportunity WHERE Id in :lstUpdatedOpps];
                //System.debug('@@ lstOpps:' + lstOpps);
                for(Opportunity opp : lstOpps){
                    mapOppToCreateCtr.put(opp.Id, opp);
                }
                AP28_CreateCtrfromOpp.createCtrfromOpp(mapOppToCreateCtr);
                System.debug('@@ after update lstUpdatedOpps:' + lstUpdatedOpps);              
                

            test.StopTest();

            
            //list of contracts
            lstCtrs=[SELECT Id, name,Opportunity__c,Opportunity__r.Name,Opportunity__r.StageName, Account__c, axa_go_legal_entity__c FROM Contract__c WHERE Opportunity__c= :vOpp2.Id OR Opportunity__c= :vOpp3.Id OR Opportunity__c= :vOpp5.Id  ]; 
            //System.debug('@@ lstCtrs:' + lstCtrs);

            //list of opp prod items
            lstOppPrItems = [SELECT Id, Name, Opportunity__c, Product__c FROM Opp_ProductItem__c WHERE Opportunity__c in :lstOpps];
            //System.debug('@@ lstOppPrItems:' + lstOppPrItems);

            //list of contract prod items
            lstCtrPrItems = [SELECT Id, Name, Contract__c,Contract__r.Name, Product__c FROM ProductItem__c WHERE Contract__c in :lstCtrs];
            //System.debug('@@ lstCtrPrItems:' + lstCtrPrItems);


            for (Contract__c con:lstCtrs){

                //check if contract name = opp name 
                System.assertEquals(con.Opportunity__r.Name,con.Name);
                //System.debug('@@ con.Name:' + con.Name);

                //check if opp stage is contracting
                //System.assertEquals(AP_Constant.STAGE_CONTRACTING, con.Opportunity__r.StageName);

            }

            //check if no. of contracts generated = no. of opps 
            //System.debug('@@ lstOpps.size(), lstCtrs.size():' + lstOpps.size()+ ' ,'+ lstCtrs.size());
            System.assertEquals(lstOpps.size(), lstCtrs.size());

            //check if no. of contract prod items generated = no. of opp prod items 
            //System.debug('@@ lstOppPrItems.size(), lstCtrPrItems.size():' + lstOppPrItems.size()+ ' ,'+ lstCtrPrItems.size());
//            System.assertEquals(lstOppPrItems.size(), lstCtrPrItems.size());

        }

    }


    //@IsTest
    // public static void testCreateCtrFromOppFailedCtrItem(){
    //     //test leading to error creating ctr item
    //     system.runAs(testUser){
    //         test.StartTest();
    //             //System.debug('@@ vOpp4:' + vOpp4);
    //             for (Opportunity vOpp4: lstFailedOpps){
    //                 vOpp4.Answer_due_date__c = Datetime.now().date();
    //                 vOpp4.Entity_contact__c=vEntityContact.Id;
    //                 vOpp4.Offer__c=vOffer.Id;

    //                 //vOpp4.StageName = AP_Constant.STAGE_QUALIFY_ALIGN;

    //                 vOpp4.Answer_cinematic__c = AP_Constant.ANS_CINE_BUS_CASE ;
    //                 vOpp4.Project_start_Date__c =Datetime.now().date();
    //                 vOpp4.Answer_sent_date__c=Datetime.now().date();
    //                 vOpp4.Go_live_date__c=Datetime.now().date();

    //                 //add opp product item
    //                 vProdItem = AP05_TestDataFactory.createProdItems(vOffer, testUser, vProduct, vOpp4);
                    
    //                 vOpp4.StageName = AP_Constant.STAGE_CONTRACTING;

    //             }
                

    //             try{
    //                 AP28_CreateCtrfromOpp.ErrorCreateCtrItem = true;
    //                 update vOpp4;
    //             }
    //             catch(Exception e){
    //                 System.assert(e.getTypeName().contains('exception')); //ctr item failed
                    
    //             }

    //         test.StopTest();

    //     }

        

    // }

    // @IsTest
    // public static void testCreateCtrFromOppFailedCtr(){
    //     //test leading to error creating ctr
    //     system.runAs(testUser){
    //         test.StartTest();
    //            //System.debug('@@ vOpp5:' + vOpp5);
                
    //             vOpp5.Answer_due_date__c = Datetime.now().date();
    //             vOpp5.Entity_contact__c=vEntityContact.Id;
    //             vOpp5.Offer__c=vOffer.Id;

    //             //vOpp5.StageName = AP_Constant.STAGE_QUALIFY_ALIGN;

    //             vOpp5.Answer_cinematic__c = AP_Constant.ANS_CINE_BUS_CASE ;
    //             vOpp5.Project_start_Date__c =Datetime.now().date();
    //             vOpp5.Answer_sent_date__c=Datetime.now().date();
    //             vOpp5.Go_live_date__c=Datetime.now().date();

    //             //add opp product item
    //             vProdItem = AP05_TestDataFactory.createProdItems(vOffer, testUser, vProduct, vOpp5);
                
    //             vOpp5.StageName = AP_Constant.STAGE_CONTRACTING;

    //             try{
    //                 update vOpp5;
    //             }
    //             catch(Exception e){
    //                 System.assert(e.getTypeName().contains('DMLException')); //ctr failed
                    
    //             }

    //         test.StopTest();

    //     }
    // }


}