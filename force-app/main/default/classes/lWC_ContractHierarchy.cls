public with sharing class lWC_ContractHierarchy {
    static Map<Id, List<Contract__c>> mapChild = new Map<Id, List<Contract__c>>();
    static Contract__c contract;
    static Set<Id> setChildId = new Set<Id>();

    private static Contract__c getTopParent(Id ctrId) {
        contract = [SELECT Id,Name,cTin_ParentContract__c,cTin_Reference__c,cTin_TypeOfDocument__c,EndDate__c,cTin_OwnerEntity__c,cTin_SupplierAccount__r.name,Status__c FROM Contract__c WHERE Id =:ctrId];
        if (contract.cTin_ParentContract__c != null) {
            return getTopParent(contract.cTin_ParentContract__c);
        }else{
            return contract;
        }
    }

    private static Map<Id, List<Contract__c>> getAllChild(List<Contract__c> lstParent) {
        List<Contract__c> lstChild = [SELECT Id,Name,cTin_ParentContract__c,cTin_Reference__c,cTin_TypeOfDocument__c,EndDate__c,cTin_OwnerEntity__c,cTin_SupplierAccount__r.name,Status__c FROM Contract__c WHERE cTin_ParentContract__c IN :lstParent];
        if(lstChild.size()>0){
            for(Contract__c child: lstChild){
                for(Contract__c parent: lstParent){
                    if(child.cTin_ParentContract__c == parent.Id){
                        if(!mapChild.containsKey(parent.Id)){
                            mapChild.put(parent.Id, new List<Contract__c>());
                        }
                        mapChild.get(parent.Id).add(child);
                    }
                }
                setChildId.add(child.Id);
            }
            return getAllChild(lstChild);
        }else{
            return mapChild;
        }
    }

    @AuraEnabled
    public static Map <String,Object> getContractHierarchy (ID ctrID) {
        Map <String,Object> result = new Map <String,Object>();
        List <ContractWrapper> lstContractWrapper = new List <ContractWrapper> ();

        Contract__c ctrParent = getTopParent(ctrID);
        mapChild = getAllChild(new List<Contract__c>{ctrParent});

        ContractWrapper cw = new ContractWrapper();
        cw.id=ctrParent.id; 
        cw.contractName=ctrParent.name;
        cw.contractUrl= URL.getSalesforceBaseUrl().toExternalForm()+'/'+ctrParent.id;
        cw.ContractReference=ctrParent.cTin_Reference__c;
        cw.Status=ctrParent.Status__c;
        cw.TypeDocuemnt=ctrParent.cTin_TypeOfDocument__c;
        cw.ContractEnddate=ctrParent.EndDate__c;
        cw.OwnerEntity=ctrParent.cTin_OwnerEntity__c; 
        cw.SupplierLegalSignatoryEntity=ctrParent.cTin_SupplierAccount__r.name; 
        populateChildren(cw,mapChild);
        lstContractWrapper.add(cw);
        result.put('hierarchy',lstContractWrapper);
        setChildId.add(cw.id);
        result.put('lstIdCtr',setChildId);

        return result;
    }

    public static void populateChildren (ContractWrapper cw, Map<ID,List<Contract__c>> mapChild) {
        if (mapChild.get(cw.id) != null && mapChild.get(cw.id).size() > 0) {
            cw.children = new List<ContractWrapper>();
            for (Contract__c ctr : mapChild.get(cw.id)) {
                ContractWrapper ctrWrap = new ContractWrapper();
                ctrWrap.id=ctr.id; 
                ctrWrap.contractName=ctr.name; 
                ctrWrap.contractUrl= URL.getSalesforceBaseUrl().toExternalForm()+'/'+ctr.id;
                ctrWrap.ContractReference=ctr.cTin_Reference__c; 
                ctrWrap.Status=ctr.Status__c; 
                ctrWrap.TypeDocuemnt=ctr.cTin_TypeOfDocument__c; 
                ctrWrap.ContractEnddate=ctr.EndDate__c; 
                ctrWrap.OwnerEntity=ctr.cTin_OwnerEntity__c;
                ctrWrap.SupplierLegalSignatoryEntity=ctr.cTin_SupplierAccount__r.name;

                cw.children.add(ctrWrap);
            }

            for (ContractWrapper ctrWrap : cw.children) {
                populateChildren(ctrWrap,mapChild);
            }
        }
    }

    // wrapper class
    public class ContractWrapper{
        @AuraEnabled public ID id {get; set;}
        @AuraEnabled public String contractName {get; set;}
        @AuraEnabled public String contractUrl {get; set;}
        @AuraEnabled public String ContractReference {get; set;}
        @AuraEnabled public String Status {get; set;}
        @AuraEnabled public String TypeDocuemnt {get; set;}
        @AuraEnabled public Date ContractEnddate {get; set;}
        @AuraEnabled public String OwnerEntity {get; set;}
        @AuraEnabled public String SupplierLegalSignatoryEntity {get; set;}
        @AuraEnabled public List<ContractWrapper> children {get; set;}
    }
}