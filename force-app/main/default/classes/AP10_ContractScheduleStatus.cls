/**
 * @description       : 
 * @author            : JPI
 * @group             : 
 * @last modified on  : 20/10/2020
 * @last modified by  : JPI
 * Modifications Log 
 * Ver   Date         Author   Modification
 * 1.0   20/10/2020   JPI   Initial Version
**/
global class AP10_ContractScheduleStatus implements Database.Batchable<sobject>,Database.Stateful,schedulable {
/*
  --------------------------------------------------------------------------------------
  -- - Name          : AP10_ContractScheduleStatus
  -- - Author        : Spoon
  -- - Description   : Class sets OpCo contractc to Ended when end date is reached

  -- Maintenance History:
  --
  -- Date         Name  Version  Remarks
  -- -----------  ----  -------  -------------------------------------------------------
  -- 16-APR-2020  USA    1.0     Initial Version
  -- 16-APR-2020  MRA    1.1     Updated batch (as per BAU Request sp-00259 [ctin] + sp-00113 [sp-00113])
  -- 27-APR-2020  MRA    1.2     Commented functionality for opCo since business rules are not clear
  -- 23-OCT-2020  MRA    1.3     Moved ctin logic in a separate class. (Due to conflicts)
  *************************************************************************************/
    
    // Record Type IDs of contract object
    public static map<String, Schema.RecordTypeInfo> mapRecTypeInfo = Schema.SObjectType.Contract__c.getRecordTypeInfosByDeveloperName();
    public static Id idRecLightContract       = mapRecTypeInfo.get(AP_Constant.RT_LIGHTCONTRACT).getRecordTypeId();
    public static Id idRecOpCoSingleEdit      = mapRecTypeInfo.get(AP_Constant.RT_CONTRACT_EDIT_LIGHTNING).getRecordTypeId();
    public static Id idRecOpCoSingleReadOnly  = mapRecTypeInfo.get(AP_Constant.RT_CONTRACT_READONLY_LIGHTNING).getRecordTypeId();
    public static Id idRecOpCoAmendEdit       = mapRecTypeInfo.get(AP_Constant.RT_AMENDMENT_EDIT_LIGHTNING).getRecordTypeId();
    public static Id idRecOpCoAmendReadOnly   = mapRecTypeInfo.get(AP_Constant.RT_AMENDMENT_READONLY_LIGHTNING).getRecordTypeId();

    public static set<Id> setCtrRecTypesOpCo  = new set<Id>{idRecLightContract, idRecOpCoSingleEdit, idRecOpCoSingleReadOnly, idRecOpCoAmendEdit, idRecOpCoAmendReadOnly};
        
    global integer numberOfRecords=0;
    global integer numberOfRecSuccess;
    global integer numberOfRecError;

    //variables for sending mail with error.csv as attachment after exceution of batch
    global boolean isheaderSet;
    global AP00_CSVParser csv;

    global AP10_ContractScheduleStatus (){
        system.debug('## AP10_ContractScheduleStatus >> Constructor method Begins');

        csv = new AP00_CSVParser();
        numberOfRecError=0;
        numberOfRecSuccess=0;
    }


    //start method returns query result
    global Database.Querylocator start(Database.BatchableContext BC){
        system.debug('## AP10_ContractScheduleStatus >> Start method Begins');
        
       
        return Database.getQueryLocator([SELECT Status__c, TECH_IsContractIn__c, EndDate__c
                                        FROM Contract__c
                                        WHERE Status__c = :System.Label.ContractStatus_Signed 
                                        AND EndDate__c < TODAY
                                        AND ((recordtypeId IN :setCtrRecTypesOpCo OR TECH_IsContractIn__c = :false) AND TacitRenewal__c != 'Yes')]);
    }

    //scheduler
    global void execute(SchedulableContext scon) {
        //set smaller batch size if heap limits / cpu limits are encountered
        Database.executeBatch(new AP10_ContractScheduleStatus (),50);
    }

    //updates contract status for opco and ctin
    global void execute (Database.Batchablecontext BC, List <sobject> scope){
        list<contract__c> lstCtrUpdt = new list<contract__c>();
        list<contract__c> lstCtr = scope;
        
        //loop in scope => set status to Ended for Opco + status to Expired for ctin
        for(contract__c ctr : lstCtr){
            if(ctr.Status__c == System.Label.ContractStatus_Signed){
                ctr.Status__c = System.Label.ContractStatus_Ended;
            }
            

            lstCtrUpdt.add(ctr);
        }

        system.debug('##lstCtrUpdt'+lstCtrUpdt.size());

        //partial update
        if(lstCtrUpdt.size()>0){
            list<Database.SaveResult> results = Database.update(lstCtrUpdt,false);
            numberOfRecords += lstCtrUpdt.size(); //total number of lines to update

            for (Integer i = 0; i < lstCtrUpdt.size(); i++) {
                Database.SaveResult sr = results[i];

                if(!sr.isSuccess()){
                    numberOfRecError++;
                    //create a CSV from the errors to be sent via email
                    if(!csv.hasHeader) csv.writeHeader(new list<String>{'Id','Operation','Contract Type','Error'});
                    //Writing column Id
                    csv.addToLine(lstCtrUpdt[i].Id);
                    //Writing column Operation
                    csv.addToLine('Updating contract status');
                    //Writing column Contract Type
                    //if (lstCtrUpdt[i].TECH_IsContractIn__c){
                       // csv.addToLine('Contract-In');
                   // }else{
                        csv.addToLine('OpCo');
                   // }
                    //Writing column Error
                    csv.addToLine(sr.getErrors().get(0).getMessage());
                    csv.createLine();
                }
                else numberOfRecsuccess++;
            }
        }
    }

    //sends mail with error.csv in case of failures
    global void finish (Database.BatchableContext BC){
        // reset numberOfLines to get correct number
        numberOfRecords= numberOfRecsuccess + numberOfRecError;
        // no more contract to process, so send email for batch completion
        AP00_FormatEmailSend emailManager = new AP00_FormatEmailSend();
        emailManager.subject = 'Completion of batch for updating contract status to Ended';
        emailManager.body = String.format(System.label.AP10_BatchEmailBody,
                new list<string>{
                        String.valueOf(numberOfRecords),
                        String.valueOf(numberOfRecsuccess),
                        String.valueOf(numberOfRecError)
                });

        emailManager.setDestination(System.label.GLO_BatchEmailAddress);

        if(numberOfRecError> 0) emailManager.generateAttachment('Errors.csv',csv.getBlobBody(),'text/csv');

        emailManager.sendFormattedEmail();
    }


    /*

     global void execute(SchedulableContext sc)
     {
         setToEnded();
     }

    public void setToEnded()
     {
         List<Contract__c> listContracts = new List<Contract__c>();
         listContracts = [SELECT Status__c FROM Contract__c
         WHERE Status__c =: System.Label.ContractStatus_Signed AND EndDate__c < TODAY LIMIT 100];

         for(Contract__c contr : listContracts)
         {
             contr.Status__c = System.Label.ContractStatus_Ended;
         }

         update listContracts;
     }*/

}