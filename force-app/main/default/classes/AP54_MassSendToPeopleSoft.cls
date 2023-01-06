/**
 * @description       : 
 * @author            : VMU
 * @group             : 
 * @last modified on  : 10-27-2021
 * @last modified by  : VMU
**/
public class AP54_MassSendToPeopleSoft {
    /*
    --------------------------------------------------------------------------------------
    -- - Name          : AP54_MassSendToPeopleSoft
    -- - Author        : ARA
    -- - Description   : send contracts in bulk to PeopleSoft
    --
    -- Maintenance History:
    --
    -- Date         Name  Version  Remarks
    -- -----------  ----  -------  -------------------------------------------------------
    -- 11-JUN-2020  ARA    1.0     Initial version
    -- 15-JAN-2020  ARA    2.0     SP-00356
    -- 25-MAR-2021  ARA    1.9     SP-01488 Allow contract update after send to PS even if Customer Operational contact is inactive
    -- 27-OCT-2021  VMU    2.1     Flow 1 changes callout from SOAP to REST, thus callout added to class WS02_CallRestESG with amended soql fields retrieved
    -- 09-NOV-2021  ARA    2.2     Check if contracts are already sent
    --------------------------------------------------------------------------------------
    */

    // 25-MAR-2021  ARA     SP-01488 (used in ContractTrigerHandler)
    public static boolean isSentToPSMass = false;

    public static AP00_CSVParser resultMail = new AP00_CSVParser();

    @Future(callout=true)
    public static void sendMassToPS(Set<Id> setContractId){
        isSentToPSMass = true;
        //call status values
        String errorMsg = '';
        String str_Error = 'E';
        String str_Success = 'S';
        String str_Exception = 'Exception';
        String fileHeader = 'Contract Number, Contract Name, PS LOG, Status, Error message \n';
        List<Planned_Invoicing_Line__c> lstInvoiceLinesUpdate = new List<Planned_Invoicing_Line__c>();
        List<Planned_Invoicing_Line__c> updatedIlList = new List<Planned_Invoicing_Line__c>();
        List<Contract__c> lstCtrUpdate = new List<Contract__c>();
        map<Id, Contract__c> mapIdCtr = new map<Id, Contract__c>();
        map<Id, Planned_Invoicing_Line__c> mapPIL = new map<Id, Planned_Invoicing_Line__c>();
        List<Log__c> lstLog = new List<Log__c>();

        //lstContracts
        Map<Id, Contract__c> mapContract = new Map<Id, Contract__c>([SELECT Id, Name, ContractNumber__c, byPassVREditStatus__c, Tech_isSendingToPS__c
                                            FROM Contract__c
                                            WHERE Id in :setContractId
                                    ]);

        List<Planned_Invoicing_Line__c> invoicingLineList = [SELECT Id,Contract2__c,SAP_Synchronisation_Error__c,Connexion_Error__c,
                                                            SAP_Account_Number__c,N_Purchase_Order__c,PurchaseOrder__r.PO_Client__c,Customer_contact_name__c,/*Customer_contact__c,
                                                            Customer_contact__r.Name,*/Bill_form_SAPEXP__c,Customer_Operational_Contact__c,Solution__c,Service_Type__c,
                                                            Contract_Start_Date__c,Contract_End_Date__c,Material_SAPEXP__c,Man_days__c,Activity_Type__c,
                                                            Activity_Description__c,ViewCurrency__c,Master_WBS_Structure__c,Master_WBS_Structure__r.Name,WBS_Element_SAPEXP__c,Rate__c,Invoicing_Date__c,ADV_GoNoGo__c,
                                                            Status__c,isInPS__c,RecordTypeId,SO__c,ITEM__c,TECH_SynchroSAP__c,Header_Text__c,Header_Text_2_SAPEXP__c,
                                                            Header_Text_3_SAPEXP__c,Header_Text_4_SAPEXP__c, Contract2__r.TECH_PS_SalesOrganization__c, AmountIL__c,Tech_UpdatedByPS__c,
                                                            Inv_Predefined_Date__c,Contract2__r.Peoplesoft_Sync__c,Contract2__r.Tech_isSendingToPS__c,
                                                            Contract2__r.name, Contract2__r.ContractNumber__c,Contract2__r.Status__c,Contract2__r.Tech_MSARef__c, StartDate__c, EndDate__c
                                                            FROM Planned_Invoicing_Line__c 
                                                            WHERE Contract2__c IN :mapContract.keySet()
                                                            AND Contract2__r.Peoplesoft_Sync__c = false
                                                            AND Type__c = 'Invoicing Line'
                                                            AND AmountIL__c >= 0
                                                            AND (isInPS__c = true OR Status__c !=: System.label.InvLineStatusCancelled)];

        try{
            Map<id, list<Planned_Invoicing_Line__c>> mapInvoiceLineInfo=new map<id, list<Planned_Invoicing_Line__c>>();
            for(Planned_Invoicing_Line__c inv_Line: invoicingLineList){
                if(mapInvoiceLineInfo.containsKey(inv_Line.Contract2__c)){
                    mapInvoiceLineInfo.get(inv_Line.Contract2__c).add(inv_Line);   
                }
                else{
                    mapInvoiceLineInfo.put(inv_Line.Contract2__c,new list<Planned_Invoicing_Line__c>{inv_Line});
                }
            }

            if(!Test.isRunningTest()){
                WS02_CallRestESG callWS = new WS02_CallRestESG(mapInvoiceLineInfo);
                errorMsg = callWS.getErroMessage();
                /*if(errorMsg == null || errorMsg == ''){
                    if(setContractId.size() > 1){
                        String ctrIds = '';
                        String ctrName = '';
                        MassSend2PSLog__c send2PSLog = new MassSend2PSLog__c();
                        for(Id id: setContractId){
                            if(ctrIds == ''){
                                ctrIds = id;
                            }else{
                                ctrIds += ';'+id;
                            }
                            ctrName += mapContract.get(id).ContractNumber__c + ' – ' + mapContract.get(id).Name + '/n';
                        }
                        send2PSLog.PendingContractsName__c = ctrName;
                        send2PSLog.PendingContracts__c = ctrIds;
                        send2PSLog.ContractsTotalNumber__c = setContractId.size();
                        send2PSLog.User__c = UserInfo.getUserId();

                        insert send2PSLog;
                    }
                }*/
            }

        }catch(Exception e){
            errorMsg = e.getMessage();
        }
    }
}