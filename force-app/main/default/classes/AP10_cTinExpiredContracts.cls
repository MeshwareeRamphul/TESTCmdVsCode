global class AP10_cTinExpiredContracts implements Database.Batchable<sobject>,Database.Stateful,schedulable {

/*
  --------------------------------------------------------------------------------------
  -- - Name          : AP10_cTinExpiredContracts 
  -- - Author        : Spoon
  -- - Description   : Class sets active or ameneded Contracts to Expired(CTIN) when end date is reached

  -- Maintenance History:
  --
  -- Date         Name  Version  Remarks
  -- -----------  ----  -------  -------------------------------------------------------
  -- 23-OCT-2020  USA    1.0     Initial Version - previously a common batch for setting opco contract status to Ended + ctin contract status to Expired
                                 sp-00250 [ctin] + sp-00113 [sp-00113]
  *************************************************************************************/   
   
    global integer numberOfRecords=0;
    global integer numberOfRecSuccess;
    global integer numberOfRecError;
    global static boolean isRunningBatchAP10=true;
   //variables for sending mail with error.csv as attachment after exceution of batch
   global boolean isheaderSet;
   global AP00_CSVParser csv;

   global AP10_cTinExpiredContracts (){
        system.debug('## AP10_cTinExpiredContracts >> Constructor method Begins');
        isRunningBatchAP10=true;
        csv = new AP00_CSVParser();
        numberOfRecError=0;
        numberOfRecSuccess=0;
    }

    global Database.Querylocator start(Database.BatchableContext BC){
        return Database.getQueryLocator([SELECT Status__c, TECH_IsContractIn__c, EndDate__c
                                        FROM Contract__c
                                        WHERE (Status__c = :AP_Constant.contractActive OR Status__c = :'Amended')
                                        AND EndDate__c < TODAY
                                        AND TECH_IsContractIn__c = :true]);
                                       

    }

    global void execute (Database.Batchablecontext BC, List <sobject> scope){

        list<contract__c> lstCtrUpdt = new list<contract__c>();
        list<contract__c> lstCtr = scope;
        
        //loop in scope => set status to Ended for Opco + status to Expired for ctin
        for(contract__c ctr : lstCtr){
            ctr.Status__c = AP_Constant.contractExpired;
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
                    csv.addToLine('Contract-In');
                   
                    //Writing column Error
                    if(!sr.isSuccess())
                        csv.addToLine(sr.getErrors().get(0).getMessage());
                    csv.createLine();
                }
                else numberOfRecsuccess++;
            }
        }
    }

    global void finish (Database.BatchableContext BC){
        // reset numberOfLines to get correct number
        numberOfRecords= numberOfRecsuccess + numberOfRecError;
        // no more contract to process, so send email for batch completion
        AP00_FormatEmailSend emailManager = new AP00_FormatEmailSend();
        emailManager.subject = 'Completion of batch for updating contract status to Expired';
        emailManager.body = String.format(System.label.AP10_cTinBatchEmailBody,
                new list<string>{
                        String.valueOf(numberOfRecords),
                        String.valueOf(numberOfRecsuccess),
                        String.valueOf(numberOfRecError)
                });
        
        emailManager.setDestination(System.label.cTin_AP10EmailAddress);

        if(numberOfRecError> 0) emailManager.generateAttachment('Errors.csv',csv.getBlobBody(),'text/csv');

        emailManager.sendFormattedEmail();
    }

    //scheduler
    global void execute(SchedulableContext scon) {
        //set smaller batch size if heap limits / cpu limits are encountered
        Database.executeBatch(new AP10_cTinExpiredContracts ());
    }
}