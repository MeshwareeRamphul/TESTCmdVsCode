public class LC16_AddProduct {
    /*
    ----------------------------------------------------------------------
    -- - Name          : LC16_AddProduct
    -- - Author        : ARA
    -- - Description   : Controller for lighning component LC16_AddProduct
    --                  
    --
    -- Maintenance History:
    --
    -- Date          Name      Version   Remarks
    -- -----------   ----     -------   ---------------------------------------
    -- 20-may-2020   ARA        1.0     Initial version (SP-00219)
    -- 07-SEP-2021   ARA        1.1     SP-03707: Update Product selection module to allow multiple products from diff. Lvl3
    --------------------------------------------------------------------------- */
    
        @AuraEnabled
        public static sObject getRecord(String recordId){
            String query = 'SELECT Id, Name, Product_Level_3__c FROM '+(recordId.startsWith('006') ? 'Opportunity' : 'Contract__c')+' WHERE Id = :recordId LIMIT 1';
            return database.query(query);
        }
    
        @AuraEnabled
        public static String getProductCatalog(){
            List<Report> report = [SELECT  Id,  DeveloperName FROM Report WHERE DeveloperName = :System.Label.Report_OpCo360_Live_Product LIMIT 1];
            if(report.size()>0)
                return report[0].Id;
            else 
                return null;
        }
    
        @AuraEnabled
        public static List<Product__c> getProducts(String nameSearch, String recordId, String productLevel3, List<Product__c> lstSelectedProduct){
            List<Product__c> lstProd = new List<Product__c>();
            if(nameSearch != null && !nameSearch.equals('')){
                String textSearch = '%'+nameSearch+'%';
                List<String> lstStatus = new List<String>{'Retired','Stopped'};
                String query = 'SELECT Id, Status__c, Name, Product_description__c, Product_Level_3__c, Product_Line__c, Product_Family__c '
                                +'FROM Product__c '
                                +'WHERE Is_active__c = true '
                                +'AND Status__c NOT IN :lstStatus '
                                +'AND (Name LIKE :textSearch OR Product_Level_3__c LIKE :textSearch OR Product_Line__c LIKE :textSearch OR Product_Family__c LIKE :textSearch) '
                                +'AND Id NOT IN :lstSelectedProduct '
                                /*+(productLevel3 != '' ? 'AND Product_Level_3__c = :productLevel3 ' : '') //07-SEP-2021   ARA     SP-03707*/
                                +'AND Id NOT IN (SELECT Product__c FROM ' +(recordId.startsWith('006') ? 'Opp_ProductItem__c WHERE Opportunity__c = :recordId) ' : 'ProductItem__c WHERE Contract__c = :recordId) ')
                                +'ORDER BY Name, Product_Line__c ASC';
    
                lstProd = database.query(query);
            }
            return lstProd;
            
        }
        
        @AuraEnabled
        public static List<String> saveRecords(String recordId, List<Id> lstIdProduct){
            List <String> lstErrorMsg = new List <String>();
            Database.SaveResult[] result;
            map<Id,Product__c> mapProd = new map<Id,Product__c>([SELECT Id, Product_description__c, Status__c
                                                                FROM Product__c 
                                                                WHERE Id in:lstIdProduct]);
    
            if(recordId.startsWith('006')){
                List<Opp_ProductItem__c> lstProductItem = new List<Opp_ProductItem__c>();
                for(Id prodId : lstIdProduct){
                    Opp_ProductItem__c productItem = new Opp_ProductItem__c();
                    productItem.Opportunity__c = recordId;
                    productItem.Product__c = prodId;
                    productItem.ProductDescription__c = mapProd.containsKey(prodId)? mapProd.get(prodId).Product_description__c :null;
                    productItem.Status__c = mapProd.containsKey(prodId)? mapProd.get(prodId).Status__c :null;
                    lstProductItem.add(productItem);
                }
                if (lstProductItem.size() > 0){
                    result = Database.insert(lstProductItem, false);
                }
            }else if(recordId.startsWith('a0D')){
                List<ProductItem__c> lstProductItem = new List<ProductItem__c>();
                for(Id prodId : lstIdProduct){
                    ProductItem__c productItem = new ProductItem__c();
                    productItem.Contract__c = recordId;
                    productItem.Product__c = prodId;
                    productItem.ProductDescription__c = mapProd.containsKey(prodId)? mapProd.get(prodId).Product_description__c :null;
                    productItem.Status__c = mapProd.containsKey(prodId)? mapProd.get(prodId).Status__c :null;
                    lstProductItem.add(productItem);
                }
                if (lstProductItem.size() > 0){
                    result = Database.insert(lstProductItem, false);
                }
            }
            // Iterate through each returned result
            if(result != null){
                for (Database.SaveResult sr : result) {
                    if (sr.isSuccess()){
                        lstErrorMsg = null;
                    }
                    else{
                        // Operation failed, so get all errors                
                        for(Database.Error err : sr.getErrors()) {                  
                            lstErrorMsg.add(err.getStatusCode() + ': ' + err.getMessage());
                        }
                    }
                }
            }
            return lstErrorMsg;
        }
    }