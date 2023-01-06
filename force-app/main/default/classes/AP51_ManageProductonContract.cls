public with sharing class AP51_ManageProductonContract {
    /*----------------------------------------------------------------------
    -- - Name          : AP51_ManageProductonContract
    -- - Author        : Spoon
    -- - Description   : Class for blocking creation, update and deletion of product Item 
                         when contract status is above Ready for Esignature. 

    --
    -- - History:

    -- Date         Name  Version  Remarks
    -- -----------  ----  -------  ---------------------------------------
    -- 03-MAR-2018  MRA    1.0      Initial version    
    -- 07-SEP-2020  ARA    1.1      Mass upload Light Contract at any status (SP-00439)
-------------------------------------------------------------------------*/
    
    public AP51_ManageProductonContract() {
        
    }

    

    public static void blockProductItem(List<ProductItem__c> lstProdItem,map<id,id> pItemIdContractIdMap){
        list<PDFContractAttached__c> lstPDFContrAtt=new list<PDFContractAttached__c>();
        Set<String> setCtrStatus = new Set<String>{AP_Constant.CONTRACT_STATUS_READY_FOR_SIGNATURE,
                                                   AP_Constant.CONTRACT_STATUS_SENT_FOR_SIGNATURE,
                                                   AP_Constant.CONTRACT_STATUS_SIGNED,
                                                   AP_Constant.CONTRACT_STATUS_CANCELLED,
                                                   AP_Constant.CONTRACT_STATUS_TERMINATED,
                                                   AP_Constant.CONTRACT_STATUS_ENDED};
        
        set<id>setRestrictedContractId=new set<id>();
        set<id>setPDFContrAtt=new set<id>();

        //add contracts with status above Ready for esignature in set -> to block Product items for these contracts
        for(contract__c contract:[select id,status__c,PDFContrAtt__r.PDFStatus__c, Tech_RecordTypeName__c
                                  from contract__c 
                                  where id IN:pItemIdContractIdMap.values()]){
            /*if (setCtrStatus.contains(contract.Status__c)){
                if(contract.Tech_RecordTypeName__c != AP_Constant.RT_LIGHTCONTRACT){
                    setRestrictedContractId.add(contract.id);   
                }
            }
            else{
                setPDFContrAtt.add(contract.PDFContrAtt__c);         
            }*/
            if(!setCtrStatus.contains(contract.Status__c)){ setPDFContrAtt.add(contract.PDFContrAtt__c);}
        }

        //block creation of product item if contract is in setRestrictedContractId
        /*for (ProductItem__c prdItem : lstProdItem){
            if (setRestrictedContractId.contains(prdItem.contract__c)){             
                prdItem.addError('New Products cannot be added at this stage of the contract');
            }
        }*/

        for(PDFContractAttached__c pdfAtt: [select id,PDFStatus__c from PDFContractAttached__c where id IN : setPDFContrAtt]){         
            pdfAtt.PDFStatus__c='Not Updated';
            lstPDFContrAtt.add(pdfAtt);
        }

        if(lstPDFContrAtt.size()>0) update lstPDFContrAtt;
    }
}