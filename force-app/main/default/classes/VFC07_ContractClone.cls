public with sharing class VFC07_ContractClone {
    private ApexPages.StandardController standardController;

    public VFC07_ContractClone(ApexPages.StandardController standardController)
    {
        this.standardController = standardController;
        // Fields being cloned
        if (!Test.isRunningTest()) {
            // Retrieve all contracts fields (full object to clone it)
            SObjectType vContractType = Schema.getGlobalDescribe().get('Contract__c');
            Set<String> vFields = vContractType.getDescribe().fields.getMap().keySet();List<String> vFieldsToRetrieve = new List<String>(vFields);
            vFieldsToRetrieve.add('Amendment_to__r.Name');this.standardController.addFields(vFieldsToRetrieve);
        }
    }

    /**
     * canBeCloned : true if the contract can be cloned
     *               false if not
     */
    private static boolean canBeCloned(Contract__c contract){
        // Variables declarations
        boolean result = true;

        //22-MAY-2017 -MRA : added universign field in query
        Contract__c currentContract = [SELECT ServiceType__c, InvoicingMethod__c, Opportunity__c, Status__c, Id, universign__c, Tech_RecordTypeName__c FROM Contract__c WHERE Id =: contract.Id];

        if(currentContract == null){return false;
        }

        // Testing if the contract is a project
        if (!currentContract.Tech_RecordTypeName__c.contains('ATS')){
            if(currentContract.ServiceType__c != null){
                result = result && (currentContract.ServiceType__c.startsWith('BAU'));
            }
            else{result = false;
            }
        }

        if(currentContract.Status__c != null){
            result = result && !(currentContract.Status__c == 'Cancelled');
        }
        else{ result = false;
        }

        // Return the result
        return result;
    }

    /**
     *
     */
    public PageReference cloneContract()
    {
        //System.debug call for debug log purpose
        System.debug(LoggingLevel.INFO, '## VFC07_ContractClone ## cloneContract start.');
        // Record being cloned
        Contract__c currentContract = (Contract__c) standardController.getRecord();

        // Testing if the contract is a project
        if(canBeCloned(currentContract)){

            // Custom clone logi
            Contract__c clonedContract = currentContract.clone(false, true, false, false); //Deep clone
            clonedContract.Master_WBS_2__c = null;
           // clonedContract.Master_WBS__c = '';
            clonedContract.Status__c = System.Label.ContractStatus_Draft;
            Map<String, recordType> vRecordTypes = AP_Constant.getRecordTypes('Contract__c');

            if (currentContract.RecordTypeId == vRecordTypes.get(AP_Constant.RT_AMENDMENT_EDIT_LIGHTNING).Id || currentContract.RecordTypeId == vRecordTypes.get(AP_Constant.RT_AMENDMENT_READONLY_LIGHTNING).Id) {clonedContract.Name = 'AMDn_' + currentContract.Amendment_to__r.Name; clonedContract.RecordTypeId = vRecordTypes.get(AP_Constant.RT_AMENDMENT_EDIT_LIGHTNING).Id;
                /*clonedContract.ServiceType__c = null;
                clonedContract.InvoicingMethod__c = null;
                clonedContract.Invoicing_Condition__c = null;*/
            }
            else if(currentContract.RecordTypeId == vRecordTypes.get(AP_Constant.RT_CONTRACT_EDIT_LIGHTNING).Id || currentContract.RecordTypeId == vRecordTypes.get(AP_Constant.RT_CONTRACT_READONLY_LIGHTNING).Id) {clonedContract.Name = 'NEWCONTRACT';clonedContract.RecordTypeId = vRecordTypes.get(AP_Constant.RT_CONTRACT_EDIT_LIGHTNING).Id;
               /* clonedContract.ServiceType__c = null;
                clonedContract.InvoicingMethod__c = null;
                clonedContract.Invoicing_Condition__c = null;*/
            }
            /*else if(currentContract.RecordTypeId == vRecordTypes.get(AP_Constant.RT_AGSASIA_EDIT).Id || currentContract.RecordTypeId == vRecordTypes.get(AP_Constant.RT_AGSASIA_READONLY).Id) {
                clonedContract.Name = 'NEWCONTRACT';
                clonedContract.RecordTypeId = vRecordTypes.get(AP_Constant.RT_AGSASIA_EDIT).Id;
            }
            else if(currentContract.RecordTypeId == vRecordTypes.get(AP_Constant.RT_AGSSPAIN_EDIT).Id || currentContract.RecordTypeId == vRecordTypes.get(AP_Constant.RT_AGSSPAIN_READONLY).Id) {
                clonedContract.Name = 'NEWCONTRACT';clonedContract.RecordTypeId = vRecordTypes.get(AP_Constant.RT_AGSSPAIN_EDIT).Id;
            }
            else if(currentContract.RecordTypeId == vRecordTypes.get(AP_Constant.RT_AXATP_EDIT).Id || currentContract.RecordTypeId == vRecordTypes.get(AP_Constant.RT_AXATP_READONLY).Id) {
                //MRA: 19-MARS-2018: Requirement Multiple Products - Added logic to clone ATS contract + list of product Items
                clonedContract.Name = 'NEWCONTRACT';
                clonedContract.RecordTypeId = vRecordTypes.get(AP_Constant.RT_AXATP_EDIT).Id;
            }*/

            if(currentContract.ServiceType__c.startsWith('BAU')){
                clonedContract.TECH_ClonedBAUContract__c = true;
            }
            clonedContract.SOW_Operational__c = removeBRTags(clonedContract.SOW_Operational__c);
            //clonedContract.Master_WBS_2__c = null;
            clonedContract.PDFContrAtt__c = null;
            clonedContract.Contract_Signed_Date__c = null;
            clonedContract.Opportunity__c = null;
            clonedContract.TECH_IsClonedContract__c = true;

            //22-MAY-2017 -MRA : uncheck universign checkbox when cloning contract
            clonedContract.universign__c=false;

            //07-NOV-2017 - USA : set Reminder fields blank on clone
            //clonedContract.PO_Missing_Reminder_Status__c = null;
            //clonedContract.PO_Missing_R1_sent_date__c = null;
           // clonedContract.PO_Missing_R2_sent_date__c = null;
           // clonedContract.PO_Missing_R3_sent_date__c = null;
            //clonedContract.Waiting_Signature_Reminder_Status__c = null;
            //clonedContract.Waiting_Signature_R1_sent_date__c = null;
            //clonedContract.Waiting_Signature_R2_sent_date__c = null;
            //clonedContract.Waiting_Signature_R3_sent_date__c = null;

            //08-JAN-2018 - USA : uncheck TECH_AGScontract__c on clone
             clonedContract.TECH_AGScontract__c = false;

            //29-NOV-2018 - USA : Integration PeopleSoft
            clonedContract.Peoplesoft_Sync__c = false;

            //20-JUN-2019 - USA : SP-00072 (Changement de nom)
            //04-JAN-2021 - ARA : SP-00072 (Changement de AXA_GS_Legal_Entity__c en AXA_GO_Legal_Entity__c)
            if ((currentContract.AXA_GO_Legal_Entity__c.contains('Services')) || (currentContract.AXA_GO_Legal_Entity__c == 'GIE') || (currentContract.AXA_GO_Legal_Entity__c == 'SAS')){clonedContract.AXA_GO_Legal_Entity__c = null; clonedContract.ServiceType__c = null; clonedContract.InvoicingMethod__c = null;clonedContract.Invoicing_Condition__c = null;}


            //System.debug call for debug log purpose
            System.debug(LoggingLevel.INFO, '## VFC07_ContractClone ## cloneContract - Before inserting the cloned contract into database');
            try {
                
                insert clonedContract;
                //MRA: 19-MARS-2018: Requirement Multiple Products - Added logic to clone ATS contract + list of product Items
                if (currentContract.Tech_RecordTypeName__c.contains('ATS')){list<ProductItem__c> lstClonedPItems=new list<ProductItem__c>();ProductItem__c clonedpItem;for(ProductItem__c pItemsToClone:[select Contract__c,Product__c from ProductItem__c  where Contract__c=:currentContract.id]){   clonedpItem=new ProductItem__c(Contract__c=clonedContract.id,Product__c=pItemsToClone.Product__c);lstClonedPItems.add(clonedpItem);
                    }

                    if(lstClonedPItems.size()>0) try{ insert lstClonedPItems;  } catch (Exception e){ ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Technical error occured : ' + e.getMessage()));return null;
                            }
                }
            } catch (Exception e) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Technical error occured : ' + e.getMessage()));
                return null;
            }
            //System.debug call for debug log purpose
            System.debug(LoggingLevel.INFO, '## VFC07_ContractClone ## cloneContract - After     inserting the cloned contract into database');

            //System.debug call for debug log purpose
            System.debug(LoggingLevel.INFO, '## VFC07_ContractClone ## cloneContract start.');
            // Redirect to the new cloned record
            return new PageReference('/' + clonedContract.Id);
        }else{
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'You cannot cloned the following contract : ' + currentContract.Name));
            //System.debug call for debug log purpose
            System.debug(LoggingLevel.INFO, '## VFC07_ContractClone ## cloneContract end.');
            return null;
        }
    }


    public static String removeBRTags(String pSOW) {
        if (pSow == null) {            return null;
        }
        pSOW = pSOW.ReplaceAll('<br><br><br>', '<div></div>');
        pSOW = pSOW.ReplaceAll('<br><br>', '<div></div>');
        pSOW = pSOW.ReplaceAll('<br>', '<div></div>');

        return pSOW;
    }
}