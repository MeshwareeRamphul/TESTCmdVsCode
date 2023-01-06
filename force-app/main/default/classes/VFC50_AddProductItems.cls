public with sharing class VFC50_AddProductItems {
/*
----------------------------------------------------------------------
-- - Author        : SC
-- - Description   : Interface to add product items on contracts based on offer
-- - Maintenance History:
--
-- Date         Name  Version  Remarks
-- -----------  ----  -------  ---------------------------------------
-- 18-APR-2018  USA    1.0      Initial version
----------------------------------------------------------------------
**********************************************************************
*/
    public  Id                   contractId     {get;set;}
    public  Id                   offerId        {get;set;}
    public  List<ProdWrapper>    lstProds       {get;set;}
    public  Boolean              hasRemProducts {get;set;}
    public  Contract__c          ctr            {get;set;}

    public  List<ProductItem__c> lstProdItems   = new List<ProductItem__c>();   

    public VFC50_AddProductItems(ApexPages.StandardController controller) {
        contractId = ApexPages.currentPage().getParameters().get('contractId');  
        //offerId    = ApexPages.currentPage().getParameters().get('offerId'); 
        offerId    = ApexPages.currentPage().getParameters().get('offerId'); 
        lstProds   = new List<ProdWrapper>();

        system.debug('##VFC50_AddProductItems## contractId : ' + contractId);
        //system.debug('##VFC50_AddProductItems## offerId : ' + offerId);

        ctr = [SELECT id, name/*, OfferATS__r.name */
               FROM   Contract__c
               WHERE  id = :contractId];

        //query to get all products related to the offer 
        //that have not yet been created as product items on the contract
        for (Product__c prod: [SELECT Id, name, Product_description__c 
                               FROM   Product__c 
                               //WHERE  offer__c = :offerId 
                               WHERE  Product_Level_3__c = :offerId 
                               AND    Id NOT IN (SELECT Product__c 
                                                 FROM   ProductItem__c 
                                                 WHERE  Contract__c = :contractId)]){lstProds.add(new ProdWrapper(prod));
        }

        if (lstProds.size() > 0){hasRemProducts = true;
        }
        else{
            hasRemProducts = false;
        }
    }

    public pageReference checkHasProducts(){
        if (hasRemProducts == false){
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR,'All products have already been added or there are no products related to this offer.'));
        }
        return null;
    }

    public pageReference addProducts(){
        for (ProdWrapper pw :lstProds){
            if (pw.isSelected){lstProdItems.add(new ProductItem__c(Contract__c = contractId, Product__c  = pw.product.Id));
            }
        }
        if (lstProdItems.size() <= 0){
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR,'Please select atleast one product to add.'));
        }
        /*else{
            try{
                insert lstProdItems;
                return new pageReference('/' + contractId);
            }
            catch(Exception e){
                ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR,e.getMessage()));
            }
        }*/
        return null; 
    }

    public pageReference cancel(){
        return new pageReference('/' + contractId);
    }

    public class ProdWrapper{
        public Boolean    isSelected {get;set;}
        public Product__c product    {get;set;} 

        public ProdWrapper(Product__c prod){
            isSelected = false;
            product    = prod;
        }
    }
}